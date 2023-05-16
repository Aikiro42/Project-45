require "/scripts/util.lua"
require "/scripts/vec2.lua"

local textSize = 0.5

function update()

    localAnimator.clearDrawables()
    localAnimator.clearLightSources()

    -- laser
    local laser = {}
    laser.origin = animationConfig.animationParameter("testLaserOrigin")
    laser.destination = animationConfig.animationParameter("testLaserDestination")
    laser.color = {255, 215, 0, 128}
    laser.width = 2

    if laser.origin and laser.destination then

        local laserLine = worldify(laser.origin, laser.destination)
        localAnimator.addDrawable({
            line = laserLine,
            width = laser.width,
            fullbright = true,
            color = laser.color
        }, "ForegroundEntity+1")
    end
    
end

function posText(pos, up, prefix)
    local offset = 2
    localAnimator.spawnParticle({
        type = "text",
        text= "^shadow;" .. (prefix or "") .. "{" .. util.round(pos[1], 1) .. ", " .. util.round(pos[2], 1) .. "}",
        color = {255,255,255},
        size = textSize,
        fullbright = true,
        flippable = false,
        layer = "front"
    }, vec2.add(pos, {0, up and offset or -offset}))
end

function drawText(t, pos, prefix)
    pos = pos or vec2.add(activeItemAnimation.ownerPosition(), {0, -1})
    localAnimator.spawnParticle({
        type = "text",
        text= "^shadow;" .. (prefix or "") .. t,
        color = {255,255,255},
        size = textSize,
        fullbright = true,
        flippable = false,
        layer = "front"
    }, pos)
end


-- Calculates the line from pos1 to pos2
-- that allows `localAnimator.addDrawable()`
-- to render it correctly
function worldify(pos1, pos2)
    
    local playerPos = activeItemAnimation.ownerPosition()
    local worldLength = world.size()[1]
    local fucky = {false, true, true, false}
    
    -- L is the x-size of the world
    -- |0|--[1]--|--[2]--|L/2|--[3]--|--[4]--|L|
    -- there is fucky behavior in quadrants 2 and 3
    local pos1Quadrant = math.ceil(4*pos1[1]/worldLength)
    local playerPosQuadrant = math.ceil(4*playerPos[1]/worldLength)

    local ducky = fucky[pos1Quadrant] and fucky[playerPosQuadrant]
    local distance = world.distance(pos2, pos1)

    local sameWorldSide = (pos1Quadrant > 2) == (playerPosQuadrant > 2)
        
    if ducky then
        if (
            (sameWorldSide and (pos1Quadrant > 2))
            or (pos1Quadrant < playerPosQuadrant)
        ) then
            pos1[1] =  pos1[1] - worldLength
        end
    else
        if pos1[1] > worldLength/2 then
            pos1[1] = pos1[1] - worldLength
        end
    end

    pos2 = vec2.add(pos1, distance)

    return {pos1, pos2}
end