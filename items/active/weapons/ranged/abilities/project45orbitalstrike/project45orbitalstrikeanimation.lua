require "/scripts/vec2.lua"
require "/scripts/util.lua"

altInit = init or function()
end
altUpdate = update or function()
end

function init()
  altInit()
end

function update()

  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  altUpdate()

  local strikeHeight = animationConfig.animationParameter("strikeHeight")

  local drawStrikeLaser = animationConfig.animationParameter("drawStrikeLaser")

  local strikeCoordY = animationConfig.animationParameter("strikeCoordY")
  local laserWidth = animationConfig.animationParameter("strikeLaserWidth")
  local laserTick = animationConfig.animationParameter("strikeLaserTick")
  local laserColor = animationConfig.animationParameter("strikeLaserColor") or {0, 200, 255, 225}

  local laserStart, laserEnd

  if animationConfig.animationParameter("drawStrikeLaser") then

    if laserTick then
      laserStart = vec2.add(activeItemAnimation.ownerAimPosition(), {0, strikeHeight})
      laserEnd = vec2.add(activeItemAnimation.ownerAimPosition(), {0, -strikeHeight})
      if strikeCoordY then
        laserEnd[2] = strikeCoordY
      end
      local laserLine = worldify(laserStart, laserEnd)
      localAnimator.addDrawable({
        line = laserLine,
        width = laserWidth,
        fullbright = true,
        color = laserColor
      }, "Player-2")
    end

  end

  if animationConfig.animationParameter("drawOrbitalLaser") then

    local orbitalOffsets = animationConfig.animationParameter("orbitalOffsets") or {}
    local orbitalColor = animationConfig.animationParameter("orbitalColor") or {255, 128, 0}
    local orbitalLaserWidth = animationConfig.animationParameter("orbitalLaserWidth") or 0.5

    for _, offset in ipairs(orbitalOffsets) do
      local orbitalLaserPos = vec2.add(activeItemAnimation.ownerAimPosition(), offset)
      local orbitalLaserStart = vec2.add(orbitalLaserPos, {0, strikeHeight})
      local orbitalLaserEnd = vec2.add(orbitalLaserPos, {0, -strikeHeight})
      if strikeCoordY then
        orbitalLaserEnd[2] = strikeCoordY
      end

      local orbitalLine = worldify(orbitalLaserStart, orbitalLaserEnd)

      localAnimator.addDrawable({
        line = orbitalLine,
        width = orbitalLaserWidth,
        fullbright = true,
        color = orbitalColor
      }, "overlay")
      localAnimator.addDrawable({
        line = orbitalLine,
        width = orbitalLaserWidth / 4,
        fullbright = true,
        color = {255, 255, 255, orbitalColor[4]}
      }, "overlay")

    end

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
  local pos1Quadrant = math.ceil(4 * pos1[1] / worldLength)
  local playerPosQuadrant = math.ceil(4 * playerPos[1] / worldLength)

  local ducky = fucky[pos1Quadrant] and fucky[playerPosQuadrant]
  local distance = world.distance(pos2, pos1)

  local sameWorldSide = (pos1Quadrant > 2) == (playerPosQuadrant > 2)

  if ducky then
    if ((sameWorldSide and (pos1Quadrant > 2)) or (pos1Quadrant < playerPosQuadrant)) then
      pos1[1] = pos1[1] - worldLength
    end
  else
    if pos1[1] > worldLength / 2 then
      pos1[1] = pos1[1] - worldLength
    end
  end

  pos2 = vec2.add(pos1, distance)

  return {pos1, pos2}
end
