require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/project45/project45util.lua"

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

  local gravThreshold = 0.1

  local drawStrikeLaser = animationConfig.animationParameter("drawStrikeLaser")

  local strikeCoordY = animationConfig.animationParameter("strikeCoordY")
  local laserWidth = animationConfig.animationParameter("strikeLaserWidth")
  local laserTick = animationConfig.animationParameter("strikeLaserTick")
  local laserColor = animationConfig.animationParameter("strikeLaserColor") or {0, 200, 255, 225}

  local gradientSteps = 64

  local laserStart, laserEnd

  if animationConfig.animationParameter("drawStrikeLaser") then

    if laserTick then
      laserStart = activeItemAnimation.ownerAimPosition()

      if world.gravity(laserStart) > gravThreshold then
        laserStart = vec2.add(laserStart, {0, strikeHeight})
      end
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
      drawGradient(laserEnd, vec2.add(laserEnd, {0, -5}), laserWidth, gradientSteps, laserColor, true, "Player-2")
      
      drawGradient(laserEnd, vec2.add(laserEnd, {0, 5}), laserWidth, gradientSteps, {255, 0, 0, 128}, true, "overlay")
      
      drawGradient(laserEnd, vec2.add(laserEnd, {-10, 0}), 0.5, 4, {255, 128, 0, 255}, true, "overlay")
      drawGradient(laserEnd, vec2.add(laserEnd, {10, 0}), 0.5, 4, {255, 128, 0, 255}, true, "overlay")
      
      drawGradient(laserEnd, vec2.add(laserEnd, {0, -5}), laserWidth, gradientSteps, {255, 0, 0, 128}, true, "overlay")

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
      if world.gravity(orbitalLaserPos) > gravThreshold then
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
      else
        drawGradient(orbitalLaserEnd, vec2.add(orbitalLaserEnd, {0, 5}), orbitalLaserWidth, gradientSteps, orbitalColor, true, "overlay")
        drawGradient(orbitalLaserEnd, vec2.add(orbitalLaserEnd, {0, 5}), orbitalLaserWidth / 4, gradientSteps, {255, 255, 255, orbitalColor[4]}, true, "overlay")  
      end

      drawGradient(orbitalLaserEnd, vec2.add(orbitalLaserEnd, {0, -5}), orbitalLaserWidth, gradientSteps, orbitalColor, true, "overlay")
      drawGradient(orbitalLaserEnd, vec2.add(orbitalLaserEnd, {0, -5}), orbitalLaserWidth / 4, gradientSteps, {255, 255, 255, orbitalColor[4]}, true, "overlay")

      orbitalColor[4] = math.floor(orbitalColor[4] / 2)


    end

  end

end

function drawGradient(startPos, endPos, width, steps, color, fullbright, layer)
  layer = layer or "overlay"
  if #color < 3 then
    table.insert(color, 255)
  end
  local gradientLength = world.magnitude(startPos, endPos)
  local stepLength = gradientLength/steps
  local colorDec = color[4]/steps
  local normalVector = vec2.norm(world.distance(endPos, startPos))
  for i=0, steps do
    local stepEnd = vec2.add(startPos, vec2.mul(normalVector, stepLength))
    local gradientLine = worldify(startPos, stepEnd)
    local newColor = {color[1], color[2], color[3], math.max(0, color[4] - colorDec * i)}
    localAnimator.addDrawable({
      line = gradientLine,
      width = width,
      fullbright = fullbright,
      color = newColor
    }, layer)
    startPos = stepEnd
  end
end

-- Calculates the line from pos1 to pos2
-- that allows `localAnimator.addDrawable()`
-- to render it correctly
function worldify(pos1, pos2)

  return project45util.worldify(pos1, pos2)

end
