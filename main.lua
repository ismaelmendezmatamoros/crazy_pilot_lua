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

local init
local function screen_change_mode()
	local globals = require("globals")
    --display.currentStage:removeEventListener( "tap", impulse )
    --display.currentStage:removeEventListener( "tap", impulse)
    --Runtime:removeEventListener("enterFrame")
    --transition.cancel()
    --physics.stop()

	--globals.bg = nil
	--globals.bg = {}

	--[[while display.currentStage.numChildren > 0 do
        local child = display.currentStage[1]
        if child then 
        	child:removeSelf() 
       	end
        print("middleGroup.numChildren" , display.currentStage.numChildren )
    end--]]

	print("transition")
	if(globals.status == "game_over") then
		--transition.to()
		--init()
	end

end

local function gameOver() 
	local globals = require("globals")

	local function showText() 
		globals.status = "game_over"
		local text = display.newText( "You are dead", display.contentWidth * 0.5, display.contentHeight * 0.5, native.systemFont, 200 )
		text.alpha = 0
		text:setFillColor( 1, 0, 0 )
		transition.to(text, {time = 1000 , alpha = 1})
	end
	timer.cancel(globals.timer)
	globals.gameover_group = display.newGroup()
	local veil = display.newRect(display.contentWidth * 0.5, display.contentHeight * 0.5, display.contentWidth, display.contentHeight)
	veil.alpha = 0.1
	veil.fill = {0, 0, 0}
	veil:toFront()
	globals.gameover_group:insert(veil)
	transition.to(veil, {time = 1000 , alpha = 1, onComplete = showText})
	showText()
	display.currentStage:addEventListener( "tap", screen_change_mode )


end

local function onCrash(event)
	local globals = require("globals")
		if(event.phase ~= "ended") then
		return
	end
	print("creassed")
	globals.plane.live_points = globals.plane.live_points - 1
	globals.fire_emitter.maxParticles = 10 *  (3 - globals.plane.live_points)
	globals.fire_emitter.isVisible = true 
end

local function onPass(event)
	if(event.phase ~= "ended") then
		return
	end
	--print("passed")
end

local function bakclineTouched(event) 
------------------------------------------------	
if(event.phase ~= "ended") then
		return
	end
	print(event.other.myName)
	gameOver()
end



local function createLineSensor(position_x, name, listener)
	local globals = require("globals")

	local line = display.newLine(position_x, display.contentHeight, position_x, 0)
	line.myName = name
	physics.addBody(line, "kinematic", {isSensor = true})
	line:addEventListener("collision", listener)
	line.isVisible = false
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
	wall.myName = "wall"
	wall:addEventListener("collision", onCrash)
	return wall
end

local function moveLines()
	local globals = require("globals")
	for i = 1, #globals.walls do 
		local wall = globals.walls[i]
			wall[3].x = wall[1].x
	end
end

local function removeOldWall()
	local globals = require("globals")
	if (#globals.walls) > 0 then
		if (#globals.walls[1])  == 3 then 
			local wall = globals.walls[1]
			if (wall[1].x < -globals.wall_width * 2) then				
				for j = 1, #wall do
					wall[j]:removeSelf()
				end
			table.remove(globals.walls, 1)
			end
		end	
	end
end

local function onEnterFrame(event)
	local globals = require("globals")
	removeOldWall()
	globals.fire_emitter.x = globals.plane.x
	globals.fire_emitter.y = globals.plane.y
	globals.fire_emitter.rotation =  globals.plane.rotation

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
	local line = createLineSensor(upper.x, "wall_line", listener_pass)

	local group = {}
	group[#group + 1] = lower
	group[#group + 1] = upper
	group[#group + 1] = line
	return group
end


local function animateWalls(time, center, height )
	local globals = require("globals")

	local tile_index = math.random(#globals.tiles)

	local wall = createPass(globals.tiles[tile_index], globals.wall_width, center, height, onCrash, onPass)	
	local k
	for k = 1, #wall do
		physics.addBody(wall[k], "kinematic")
		wall[k]:setLinearVelocity(-time,0)
	end
	globals.walls[#globals.walls + 1] = wall
	local function removeWall()
		table.remove(globals.walls, 1)
		wall:removeSelf()
	end
end

local function createBgLayers(names, basespeed)
	local globals = require("globals") 

	for k,i in pairs(globals.bg_names) do
					
			local bg = display.newRect(display.contentWidth * 0.5 ,display.contentHeight * 0.5, display.contentWidth, display.contentHeight)
			bg.fill = {type = "image", filename = i}
			local function repeatAnim() 
				bg.fill.x = 0
				transition.to(bg.fill, {time = (1/k) * basespeed, x = 1, onComplete = repeatAnim})				
			end
		if k ~= 1 then
			repeatAnim()
		end	
			globals.bg[#globals.bg + 1] = bg		
		
	end
end

local function createPlane(filename, width, position_x, position_y, impulse_force)
	local globals = require("globals") 

	local aux = display.newImage(filename, {isVisible = false})
	aux.isVisible = false
	local scale = width / aux.width
	globals.plane = nil
	globals.plane = display.newRect( position_x, position_y, aux.width  *scale, aux.height * scale)
	globals.plane.fill = { type = "image", filename = filename }
	globals.plane.myName = "plane"
	globals.plane.live_points = 3
	physics.addBody(globals.plane, {density = 1})
	local function impulse(event)
		globals.plane:applyLinearImpulse(0, impulse_force, globals.plane.x, globals.plane.y)
		print("imppulsessss")
		return true
	end
	--display.currentStage:removeEventListener( "tap")
	display.currentStage:addEventListener( "tap", impulse )
end



local function setup()
	local globals = require("globals")
	globals.status = "playing"
		physics.start()
--physics.setDrawMode( "hybrid" )
	math.randomseed(os.time())
	display.setStatusBar(display.HiddenStatusBar) 
	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "repeat" )
	createBgLayers(globals.bg_names, 30000)
	createPlane("plane2.png", globals.wall_width,  globals.wall_width * 3, display.contentHeight * 0.25, -30)
	globals.back_line = createLineSensor(20,"back_line", bakclineTouched)
	globals.fire_emitter = display.newEmitter( globals.emitterParams )
	globals.fire_emitter.isVisible = false
	Runtime:addEventListener("enterFrame", onEnterFrame)
	-----------------------
	local lineup = display.newLine(0, 0, display.contentWidth,0)
	lineup.myName = "upline"
	physics.addBody(lineup, "kinematic", {isSensor = true})
	lineup:addEventListener("collision", bakclineTouched)
	lineup.isVisible = false
	------------------------
	local lineup = display.newLine(0, display.contentHeight, display.contentWidth, display.contentHeight)
	lineup.myName = "bottomline"
	physics.addBody(lineup, "kinematic", {isSensor = true})
	lineup:addEventListener("collision", bakclineTouched)
	lineup.isVisible = false
end

init =  function()

	local center, height = 0.5, 0.2
	lambda = function() 
		center, height = getNextPass(center, height)
		removeOldWall()
		animateWalls(300, center, height, onCrash, onCrash) 
		--globals.plane:applyLinearImpulse(0,-1, globals.plane.x, globals.plane.y)
	end
	globals.timer = timer.performWithDelay(1000, lambda, -1)
end

--globals_bak = globals
	setup()
init()
  



