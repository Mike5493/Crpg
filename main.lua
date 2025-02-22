--[[
    =======================================================
     -- RayCasting implementation done with Love2D
     -- Author: Mikey
     -- Date: 2/8/2025
    =======================================================
]]
--
love.graphics.setDefaultFilter("nearest", "nearest")
love.mouse.setRelativeMode(true)


local player = {
    x = 4,
    y = 4,
    angle = 0,
    pitch = 0,
    fov = math.pi / 3,
    speed = 3,
    sensitivity = 0.002,
}

local enemies = {
    { x = 15, y = 9,  speed = 1.5, direction = 1, color = { 1, 0, 0 } }, -- Red
    { x = 3,  y = 12, speed = 1.3, direction = 1, color = { 0, 1, 0 } }, -- Green
    { x = 8,  y = 6,  speed = 1.7, direction = 1, color = { 0, 0, 1 } }, -- Blue
    { x = 12, y = 3,  speed = 1.2, direction = 1, color = { 1, 1, 0 } }, -- Yellow
    { x = 2,  y = 2,  speed = 1.4, direction = 1, color = { 1, 0, 1 } }, -- Purple
}

local map = {
    width = 16,
    height = 16,
    data = {
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1,
        1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1,
        1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1,
        1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    }
}

local textures = {
    wall = love.graphics.newImage("res/mossy.png"),
    quads = {}
}
textures.wall:setFilter("nearest", "nearest")

for i = 0, textures.wall:getWidth() - 1 do
    textures.quads[i] = love.graphics.newQuad(i, 0, 1, textures.wall:getHeight(), textures.wall:getDimensions())
end


function IsColliding(x, y)
    local buffer = 0.2
    local tileX = math.floor(x)
    local tileY = math.floor(y)

    if tileX < 1 or tileX > map.width or tileY < 1 or tileY > map.height then
        return true
    end

    return map.data[tileY * map.width + tileX + 1] == 1 or
        map.data[tileY * map.width + math.floor(x - buffer) + 1] == 1 or
        map.data[tileY * map.width + math.floor(x + buffer) + 1] == 1 or
        map.data[math.floor(y - buffer) * map.width + tileX + 1] == 1 or
        map.data[math.floor(y + buffer) * map.width + tileX + 1] == 1
end

function IsPlayerColliding(x, y)
    local buffer = 0.3
    return math.abs(x - player.x) < buffer and math.abs(y - player.y) < buffer
end

function map:get(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return 1
    end
    local index = math.floor(y) * self.width + math.floor(x) + 1
    return self.data[index] or 1
end

local rayResults = {}

function PreComputeRays()
    for i = 0, 119 do
        local rayAngle             = player.angle - (player.fov / 2) + ((i / 119) * player.fov)
        local distance, side, texX = CastRay(rayAngle)
        rayResults[i]              = { distance, side, texX, rayAngle }
    end
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

function UpdateEnemies(dt)
    for _, enemy in ipairs(enemies) do
        local dx       = player.x - enemy.x
        local dy       = player.y - enemy.y
        local distance = math.sqrt(dx ^ 2 + dy ^ 2)

        if IsPlayerColliding(enemy.x, enemy.y) then
            print("ENEMY COLLIDED WITH PLAYER")
            return
        end

        -- Move towards player if not too close
        if distance > 0.3 then
            local approachSpeed = math.min(enemy.speed, distance * 1.5) -- Slows down near player
            local moveX         = (dx / distance) * approachSpeed * dt
            local moveY         = (dy / distance) * approachSpeed * dt

            local futureX       = enemy.x + moveX
            local futureY       = enemy.y + moveY

            local canMoveX      = not IsColliding(futureX, enemy.y) and not IsPlayerColliding(futureX, enemy.y)
            local canMoveY      = not IsColliding(enemy.x, futureY) and not IsPlayerColliding(enemy.x, futureY)

            if canMoveX then
                enemy.x = futureX
            end
            if canMoveY then
                enemy.y = futureY
            end

            if not canMoveX and not canMoveY then
                print("ENEMY STUCK: TRYING TO SLIDE")

                if math.abs(dx) > math.abs(dy) then
                    if not IsColliding(enemy.x, enemy.y + 0.3) then
                        enemy.y = enemy.y + 0.3
                    elseif not IsColliding(enemy.x, enemy.y - 0.3) then
                        enemy.y = enemy.y - 0.3
                    end
                else
                    if not IsColliding(enemy.x + 0.3, enemy.y) then
                        enemy.x = enemy.x + 0.3
                    elseif not IsColliding(enemy.x - 0.3, enemy.y) then
                        enemy.x = enemy.x - 0.3
                    end
                end
            end
        end
    end
end

function love.update(dt)
    PreComputeRays()
    UpdateEnemies(dt)

    local isRunning   = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    local moveSpeed   = (isRunning and 4 or 2) * dt -- Sprinting speed
    local strafeSpeed = moveSpeed * 0.7             -- Modify as needed
    local rotSpeed    = 1.6 * dt

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

    -- Rotation with left and right arrow keys
    if love.keyboard.isDown("left") then
        player.angle = (player.angle - rotSpeed) % (2 * math.pi)
    end
    if love.keyboard.isDown("right") then
        player.angle = (player.angle + rotSpeed) % (2 * math.pi)
    end

    if not IsColliding(newX, player.y) then player.x = newX end
    if not IsColliding(player.x, newY) then player.y = newY end

    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
end

function DrawEnemies()
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - player.x
        local dy = enemy.y - player.y
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Ensure enemy is within view
        if distance > 0.2 then
            local enemyAngle = math.atan2(dy, dx) - player.angle
            enemyAngle = (enemyAngle + math.pi) % (2 * math.pi) - math.pi

            local stepX = dx / distance * 0.1
            local stepY = dy / distance * 0.1
            local checkX = player.x
            local checkY = player.y
            local isBlocked = false

            for i = 1, math.floor(distance / 0.1) do
                checkX = checkX + stepX
                checkY = checkY + stepY
                if IsColliding(checkX, checkY) then
                    isBlocked = true
                    break
                end
            end

            -- Check if enemy is whin FOV
            if not isBlocked and math.abs(enemyAngle) < player.fov / 2 then
                local screenX = love.graphics.getWidth() / 2 + math.tan(enemyAngle) * 500 / distance
                local enemySize = math.max(20, math.min(100, 500 / distance))

                love.graphics.setColor(enemy.color[1], enemy.color[2],
                    enemy.color[3], 1)
                love.graphics.rectangle("fill", screenX - enemySize / 2, (love.graphics.getHeight() / 2) - enemySize / 2,
                    enemySize, enemySize)
                love.graphics.setColor(1, 1, 1)
            end
        end
    end
end

function love.draw()
    local screenWidth  = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local columnWidth  = screenWidth / 120

    -- Drawing the floor and ceiling(Dark gray for floor, light gray for ceiling)
    print(love.timer.getFPS())
    love.graphics.setColor(0.2, 0.2, 0.2) -- Floor(R-G-B)
    love.graphics.rectangle("fill", 0, screenHeight / 2 - player.pitch * screenHeight, screenWidth, screenHeight / 2)
    love.graphics.setColor(0.1, 0.1, 0.1) -- Ceiling(R-G-B)
    love.graphics.rectangle("fill", 0, 0 - player.pitch * screenHeight, screenWidth, screenHeight / 2)


    for i = 0, 119 do
        local rayData = rayResults[i]
        if rayData then
            local distance, side, texX, rayAngle = unpack(rayData)

            local correctedDistance              = distance *
                math.cos(i * (player.fov / 120) - player.fov / 2) -- Fish eye fix
            local projectionPlane                = (screenWidth / 2) / math.tan(player.fov / 2)
            local wallHeight                     = (projectionPlane / (correctedDistance + 0.1))

            local fog                            = math.max(0, 1 - (correctedDistance / 10))
            local brightness                     = (side == 1) and 0.7 or 1.0
            love.graphics.setColor(fog * brightness, fog * brightness, fog * brightness)

            local quad = textures.quads[texX] or textures.quads[0]

            love.graphics.draw(textures.wall, quad, i * columnWidth,
                (screenHeight - wallHeight) / 2, 0, columnWidth, wallHeight / textures.wall:getHeight())
        end
    end
    DrawEnemies()
end

function love.mousemoved(_, _, dx, _)
    player.angle = (player.angle + dx * player.sensitivity) % (2 * math.pi)
end
