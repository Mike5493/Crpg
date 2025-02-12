--[[
    =======================================================
     -- RayCasting implementation done with Love2D
     -- Author: Mikey
     -- Date: 2/8/2025
    =======================================================
]] --

---@diagnostic disable: undefined-global
--- Foundation of crpg with love2D
--- Disable the global variable squiggles for 'love'

love.graphics.setDefaultFilter("nearest", "nearest")
love.mouse.setRelativeMode(true)

local player = {
    x = 4,
    y = 4,
    angle = 0,
    pitch = 0,
    fov = math.pi / 3,
    speed = 2,
    sensitivity = 0.002,
}

local map = {
    width = 16,
    height = 16,
    data = {
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,0,1,1,1,1,0,1,1,1,1,1,1,1,0,1,
        1,0,1,0,0,1,0,0,0,0,0,0,0,1,0,1,
        1,0,1,0,0,1,1,1,1,1,1,1,0,1,0,1,
        1,0,1,0,0,0,0,0,0,0,0,1,0,1,0,1,
        1,0,1,1,1,1,1,1,1,1,0,1,0,1,0,1,
        1,0,0,0,0,0,0,0,0,1,0,1,0,1,0,1,
        1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,
        1,0,0,0,0,0,0,0,0,1,0,1,0,1,0,1,
        1,0,1,1,1,1,1,1,1,1,0,1,0,1,0,1,
        1,0,1,0,0,0,0,0,0,0,0,1,0,1,0,1,
        1,0,1,0,1,1,1,1,1,1,1,1,0,1,0,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    }
}

local textures = {
    wall = love.graphics.newImage("res/greystone.png")
}
textures.wall:setFilter("nearest", "nearest")

function map:get(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return 1
    end
    local index = math.floor(y) * self.width + math.floor(x) + 1
    return self.data[index] or 1
end

local function isColliding(x, y)
    local buffer = 0.2
    return map:get(math.floor(x - buffer), math.floor(y)) == 1
        or map:get(math.floor(x + buffer), math.floor(y)) == 1
        or map:get(math.floor(x), math.floor(y - buffer)) == 1
        or map:get(math.floor(x), math.floor(y + buffer)) == 1
end

-- Raycasting optimized with DDA to better calculate distance and
function CastRay(angle)
    local sinA                = math.sin(angle)
    local cosA                = math.cos(angle)
    local mapX, mapY          = math.floor(player.x), math.floor(player.y)
    local deltaDistX          = math.abs(1 / cosA)
    local deltaDistY          = math.abs(1 / sinA)

    local stepX               = (cosA < 0) and -1 or 1
    local stepY               = (sinA < 0) and -1 or 1
    local sideDistX           = (cosA < 0) and (player.x - mapX) * deltaDistX or (mapX + 1 - player.x) * deltaDistX
    local sideDistY           = (sinA < 0) and (player.y - mapY) * deltaDistY or (mapY + 1 - player.y) * deltaDistY

    local hit, side, distance = false, 0, 0
    while not hit and distance < 16 do
        if sideDistX < sideDistY then
            sideDistX = sideDistX + deltaDistX
            mapX = mapX + stepX
            side = 0
        else
            sideDistY = sideDistY + deltaDistY
            mapY = mapY + stepY
            side = 1
        end
        if map:get(mapX, mapY) == 1 then
            hit = true
            distance = (side == 0) and (sideDistX - deltaDistX) or (sideDistY - deltaDistY)
        end
    end

    local wallHit
    if side == 0 then
        wallHit = player.y + distance * sinA
    else
        wallHit = player.x + distance * cosA
    end
    wallHit = wallHit - math.floor(wallHit) -- Get fractional part
    local texX = math.floor(wallHit * textures.wall:getWidth() + 0.5) % textures.wall:getWidth()
    --texX = math.max(0, math.min(textures.wall:getWidth() - 1, texX))

    return distance, side, texX -- Texture X coordinate
end

function love.update(dt)
    local isRunning   = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    local moveSpeed   = (isRunning and 4 or 2) * dt -- Sprinting speed
    local strafeSpeed = moveSpeed * 0.7             -- Modify as needed

    local newX        = player.x
    local newY        = player.y


    if love.keyboard.isDown("w") then
        newX = player.x + math.cos(player.angle) * moveSpeed
        newY = player.y + math.sin(player.angle) * moveSpeed
    end
    if love.keyboard.isDown("s") then
        newX = player.x - math.cos(player.angle) * moveSpeed
        newY = player.y - math.sin(player.angle) * moveSpeed
    end
    if love.keyboard.isDown("a") then
        newX = player.x + math.sin(player.angle) * strafeSpeed
        newY = player.y - math.cos(player.angle) * strafeSpeed
    end
    if love.keyboard.isDown("d") then
        newX = player.x - math.sin(player.angle) * strafeSpeed
        newY = player.y + math.cos(player.angle) * strafeSpeed
    end

    if not isColliding(newX, player.y) then player.x = newX end
    if not isColliding(player.x, newY) then player.y = newY end

    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
end

function love.mousemoved(x, y, dx, dy)
    player.angle = (player.angle + dx * player.sensitivity) % (2 * math.pi)
end

function love.draw()
    local screenWidth  = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local columnWidth  = screenWidth / 120

    -- Drawing the floor and ceiling(Dark gray for floor, light gray for ceiling)
    print(love.timer.getFPS())
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, screenHeight / 2 - player.pitch * screenHeight, screenWidth, screenHeight / 2)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, 0 - player.pitch * screenHeight, screenWidth, screenHeight / 2)

    for i = 0, 119 do
        local rayAngle = player.angle - (player.fov / 2) + ((i / 119) * player.fov)
        local distance, side, texX = CastRay(rayAngle)

        local correctedDistance = distance * math.cos(rayAngle - player.angle) -- Fish eye fix
        correctedDistance = math.max(0.5, correctedDistance)
        local projectionPlane = (screenWidth / 2) / math.tan(player.fov / 2)
        local wallHeight = (projectionPlane / (correctedDistance + 0.1))
        wallHeight = math.min(screenHeight, wallHeight)
        local fog = math.max(0, 1 - (correctedDistance / 10))

        local brightness = (side == 1) and 0.7 or 1.0
        love.graphics.setColor(fog * brightness, fog * brightness, fog * brightness)
        love.graphics.draw(textures.wall,
            love.graphics.newQuad(texX, 0, 1, textures.wall:getHeight(), textures.wall:getDimensions()), i * columnWidth,
            (screenHeight - wallHeight) / 2, 0, columnWidth, wallHeight / textures.wall:getHeight(), scaleX, scaleY)
    end
end
