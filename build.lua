local lfs = require("lfs")

local loveFile    = "MyGame.love"
local exeFile     = "MyGame.exe"
local loveExePath = "love.exe"

print("Packaging MyGame into an executable")

os.remove(loveFile)

-- Create a .love file (zip of all game files)
local zip = io.open(loveFile, "wb")
if not zip then
	print("Failed to create MyGame.love")
	return
end

for file in lfs.dir(".") do
	if file ~= "." and file ~= ".." and file ~= loveFile and file ~= loveExePath then
		local f = io.open(file, "rb")
		if f then
			local data = f:read("*all")
			f:close()
			zip:write(data)
		end
	end
end

zip:close()
print("Packaged as MyGame.love")

-- Merge love.exe with MyGame.love to create MyGame.exe
local concatCommand = 'copy /b "love.exe" + "MyGame.love" "MyGame.exe"'
local concatSuccess = os.execute(concatCommand)

if concatSuccess then
	print("***Success! Your game executable is ready: MyGame.exe***")
else
	print("***Failed to generate MyGame.exe***")
end

os.remove("MyGame.love")
