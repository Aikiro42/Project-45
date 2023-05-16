function update()

    localAnimator.clearDrawables()
    localAnimator.clearLightSources()

    -- laser
    local laser = {}
    laser.origin = animationConfig.animationParameter("laserOrigin")
    laser.destination = animationConfig.animationParameter("laserDestination")
    laser.color = animationConfig.animationParameter("altLaserColor")
    laser.width = animationConfig.animationParameter("altLaserWidth") or animationConfig.animationParameter("laserWidth") or 0.2

    if laser.origin and laser.destination and laser.color then
    local laserLine = worldify(laser.origin, laser.destination)
    localAnimator.addDrawable({
        line = laserLine,
        width = laser.width,
        fullbright = true,
        color = laser.color
    }, "Player+1")
    end
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