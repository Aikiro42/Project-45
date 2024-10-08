require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/poly.lua"

flashLaser_oldUpdate = update or function() end

function update()

    localAnimator.clearDrawables()
    localAnimator.clearLightSources()
    
    flashLaser_oldUpdate()

    -- laser
    --[[
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
    --]]

    renderLaser()
end

function drawTrajectory(muzzlePos, angle, speed, steps, renderTime, color, gravMult)
    local lineColor = color or {255, 255, 255, 128}
    local gravity = world.gravity(activeItemAnimation.ownerPosition()) * (gravMult or 1)
    local renderTime = renderTime or 3
    local stepTime = renderTime / (steps or 50)
    local vorig = muzzlePos
    local vo = muzzlePos
    local timeElapsed = 0
    while timeElapsed < renderTime do
      
      timeElapsed  = timeElapsed + stepTime
  
      local vi = {
        vorig[1] + (speed * math.cos(angle) * timeElapsed),
        vorig[2] + (speed * math.sin(angle) * timeElapsed) - (gravity * timeElapsed ^ 2) / 2
      }
  
      local collision = world.lineTileCollisionPoint(vo, vi)
      
      if collision then
        vi = collision[1]
      end
  
      local arcSegment = worldify(vo, vi)
      localAnimator.addDrawable({
        line = arcSegment,
        width = 0.2,
        fullbright = true,
        color = lineColor
      }, "ForegroundEntity+1")
  
      if collision then break end
  
      vo = vi
      
    end
  end
  

function drawSummonArea()

    local circlePoly = poly.translate(
      animationConfig.animationParameter("primarySummonArea") or {{0, 0}},
      activeItemAnimation.ownerAimPosition()
    )
    table.insert(circlePoly, circlePoly[1])
    local obstructed = animationConfig.animationParameter("muzzleObstructed")
    local circleColor = obstructed and {128, 128, 128, 128} or animationConfig.animationParameter("primaryLaserColor") or {0, 255, 255, 128}
    local circleWidth = animationConfig.animationParameter("primaryLaserWidth") or 0.5
    local i = 1
    while i < #circlePoly do
      local segment = {circlePoly[i], circlePoly[i+1]}
      localAnimator.addDrawable({
        line = segment,
        width = circleWidth,
        fullbright = true,
        color = circleColor
      }, "ForegroundEntity+1")
      i = i + 1
    end
  end

function renderLaser()

    if
    not (animationConfig.animationParameter("altLaserEnabled")
    or animationConfig.animationParameter("primaryLaserEnabled"))
    then return end
  
    if animationConfig.animationParameter("isSummonedProjectile") then
      drawSummonArea()
      return
    end
  
    local laserStart = animationConfig.animationParameter("altLaserStart")
      or animationConfig.animationParameter("primaryLaserStart")
    
    local laserEnd = animationConfig.animationParameter("altLaserEnd")
      or animationConfig.animationParameter("primaryLaserEnd")
    
    if not laserStart
    or not laserEnd
    then return end
    
    local laserColor = animationConfig.animationParameter("altLaserColor")
      or animationConfig.animationParameter("primaryLaserColor")
      or {255, 50, 50, 128}
  
    local laserWidth = animationConfig.animationParameter("altLaserWidth")
      or animationConfig.animationParameter("primaryLaserWidth")
      or 0.5
  
  
    if animationConfig.animationParameter("primaryLaserArcGravMult") then
      drawTrajectory(
        laserStart,
        math.atan(laserEnd[2] - laserStart[2], laserEnd[1] - laserStart[1]),
        animationConfig.animationParameter("primaryLaserArcSpeed") or 10,
        animationConfig.animationParameter("primaryLaserArcSteps") or 50,
        animationConfig.animationParameter("primaryLaserArcRenderTime") or 3,
        laserColor,
        animationConfig.animationParameter("primaryLaserArcGravMult") or 1
      )
      return
    end
  
    local laserLine = worldify(laserStart, laserEnd)
    localAnimator.addDrawable({
      line = laserLine,
      width = laserWidth,
      fullbright = true,
      color = laserColor
    }, "Player-2")
  
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