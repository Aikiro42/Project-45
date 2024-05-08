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
