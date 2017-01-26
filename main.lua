-- Project: flappy
-- Description:
--
-- Version: 1.0
-- Managed with http://OutlawGameTools.com
--
-- Copyright 2017 . All Rights Reserved.
---- cpmgen main.lua

local physics = require( "physics" )
local globals = require("globals")


local function onCrash()
end

local function onPass()
end

local function createLineSensor(position_x, listener)
	local globals = require("globals")

	local line = display.newLine(position_x, display.contentHeight, position_x, 0)
	physics.addBody(line, "kinematic", {isSensor = true})
	return line
end

local function getNextPass(center, height)
	local globals = require("globals")

	local r1 = math.random()
	local variation = ( (r1 * height) * ((-1)^(math.random(1000))) )
	local new_center = center + variation
	if center + variation > 1 then --or center + variation < 0 then
		new_center = math.abs(1 - center + variation - 1)
	elseif center + variation < 0 then
		new_center = math.abs(center + variation)
	end 
	if new_center < 0.1 then
		new_center = new_center + 0.1
	end
	if new_center > 0.85 then
		new_center = new_center - 0.15
	end
	local r2 = math.random()
	local new_height = r2 * (globals.pass_size.max - globals.pass_size.min) + globals.pass_size.min	
	print ("CENTER: " .. new_center .. " ALT: " .. new_height)
	return new_center, new_height
end

local function createWall(type_ , tile, width, height, listener)
	local globals = require("globals")

	local wall_types = {[globals.bottom] = display.contentHeight / 2, [globals.top] = 0}
	local wall_height = {[globals.bottom] = height, [globals.top] = wall_types[globals.top]}
	local wall = display.newRect(0 , wall_types[type_] *2, width, height * 2 )	
	wall.fill = {type = "image", filename = tile}
	local tex_height = wall.contentHeight
	local tex_width = wall.contentWidth
	wall.fill.scaleY =	display.contentHeight / (tex_height  * 4) 

	return wall
end

local function moveLines()
	local globals = require("globals")
	print("walllsss:  " .. #globals.walls)
	for i = 1, #globals.walls do 
		local wall = globals.walls[i]
		wall[3].x = wall[1].x
		print(#wall)
	end
end

local function onEnterFrame(event)
	local globals = require("globals")
	moveLines()

end

local function createPass(tile, width, pass_centre, pass_height, listener_crash, listener_pass)
	local globals = require("globals")

	local group = display.newGroup()
	local centre = pass_centre * display.contentHeight
	local abs_height_up = centre - (display.contentHeight * pass_height / 2)
	local abs_height_bo = (1 - pass_centre) * display.contentHeight - (display.contentHeight * pass_height / 2) --- (display.contentHeight * pass_centre / 2)
	local lower = createWall(globals.top, tile, width,  abs_height_bo  , listener_crash)
	local upper = createWall(globals.bottom, tile, width, abs_height_up, listener_crash)
	lower.x = display.contentWidth + 0.5 * width
	upper.x = display.contentWidth + 0.5 * width
	local line = createLineSensor(upper.x, listener_pass)

	local group = {}--{["lower"] = lower, ["upper"] = upper, ["line"] = line}
	group[#group + 1] = lower
	group[#group + 1] = upper
	group[#group + 1] = line
	return group
end


local function animateWalls(time, center, height )
	local globals = require("globals")

	local tile_index = math.random(#globals.tiles)
	print("TILE: " .. globals.tiles[tile_index])
	local wall = createPass(globals.tiles[tile_index], globals.wall_width, center, height, onCrash, onPass)	

	local k
	------
	for k = 1, #wall do
		physics.addBody(wall[k], "kinematic")
		wall[k]:setLinearVelocity(-time,0)
	end
	--]]

	globals.walls[#globals.walls + 1] = wall
	local function removeWall()
		table.remove(globals.walls, 1)
		wall:removeSelf()
	end

	--transition.to(wall, {time = time, x = 0 - globals.wall_width,  onComplete = removeWall})
end

local function createBgLayers(names)
	local globals = require("globals") 

	for k,i in pairs(globals.bg_names) do
			local bg = display.newRect(0 ,0, display.contentWidth * 2, display.contentHeight * 2)
			bg.fill = {type = "image", filename = i}
			globals.bg[#globals.bg + 1] = bg			
	end
end

local function createPlane(filename, width, porition_x, position_y)
	local globals = require("globals") 

	globals.plane = display.newImage(filename)
	local scale = width / globals.plane.width
	physics.addBody(globals.plane)
	globals.plane:scale(scale, scale)
	globals.plane.x =  porition_x
	globals.plane.y =  position_y
	
end



local function setup()
	local globals = require("globals")
		physics.start()
physics.setDrawMode( "hybrid" )
	math.randomseed(os.time())
	display.setStatusBar(display.HiddenStatusBar) 
	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "repeat" )

	createBgLayers(globals.bg_names)
	createPlane("plane2.jpg", globals.wall_width,  globals.wall_width * 2, display.contentHeight * 0.25)
	globals.back_line = createLineSensor(20, 0)
	Runtime:addEventListener("enterFrame", onEnterFrame)

end

setup()
local center, height = 0.5, 0.2
lambda = function() 
		center, height = getNextPass(center, height)
		animateWalls(300, center, height, onCrash, onCrash) 
		globals.plane:applyLinearImpulse(0,-15, globals.plane.x, globals.plane.y)
end

timer.performWithDelay(800, lambda, -1)



  



