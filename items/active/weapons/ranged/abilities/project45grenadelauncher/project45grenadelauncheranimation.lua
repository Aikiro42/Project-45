require "/scripts/vec2.lua"
require "/scripts/util.lua"

grenadeLauncher_oldUpdate = update or function() end

function update()
    
    localAnimator.clearDrawables()
    localAnimator.clearLightSources()

    grenadeLauncher_oldUpdate()

    local aimPos = activeItemAnimation.ownerAimPosition()
    local grenadeIndicatorOffset = animationConfig.animationParameter("grenadeIndicatorOffset")
    local trajectoryIndicatorColor = animationConfig.animationParameter("trajectoryIndicatorColor")
    local grenadeLauncherState = animationConfig.animationParameter("grenadeLauncherState")
    local warning = animationConfig.animationParameter("grenadeLauncherChargeWarning")

    local aimAngle = animationConfig.animationParameter("altAimAngle") or 0
    local muzzlePos = animationConfig.animationParameter("altMuzzlePos") or {0, 0}
    local worldGravity = animationConfig.animationParameter("altWorldGravity") or 0
    local projSpeed = animationConfig.animationParameter("altProjectileSpeed") or 1

    localAnimator.addDrawable({
        image = "/items/active/weapons/ranged/abilities/project45grenadelauncher/project45grenadelauncherindicator.png:" .. grenadeLauncherState,
        position = vec2.add(aimPos, grenadeIndicatorOffset),
        color = {255,255,255},
        fullbright = true,
      }, "ForegroundEntity+1")

    if warning then
      localAnimator.addDrawable({
        image = "/items/active/weapons/ranged/abilities/project45grenadelauncher/project45grenadelauncherwarning.png",
        position = vec2.add(aimPos, grenadeIndicatorOffset),
        color = {255,255,255},
        fullbright = true,
      }, "ForegroundEntity+2")
      drawTrajectory(muzzlePos, aimAngle, projSpeed*1.3, 10, 1, trajectoryIndicatorColor)
    end


end


-- test
function drawTrajectory(muzzlePos, angle, speed, steps, renderTime, color)
  local lineColor = color or {255, 255, 255, 128}
  muzzlePos = muzzlePos or activeItemAnimation.ownerAimPosition()
  local gravity = world.gravity(activeItemAnimation.ownerPosition())
  speed = speed or 25
  local stepTime = renderTime / steps
  renderTime = renderTime or 10
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
      width = 0.5,
      fullbright = true,
      color = lineColor
    }, "ForegroundEntity+1")

    if collision then break end

    vo = vi
    
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
