
require "/scripts/poly.lua"

function init()
  self.lineStack = {nil}
  self.segmentTicks = 2
  self.segmentTicker = self.segmentTicks
  self.segmentTicksToLive = 10
end

function update(dt)
  localAnimator.clearDrawables()

  --[[
  local collisionPoly = animationConfig.animationParameter("collisionPoly", {})
  local position = animationConfig.animationParameter("position", {0, 0})
  drawHitGuide(collisionPoly, position)
  --]]

  -- add segment to stack
  self.segmentTicker = self.segmentTicker - 1
  if self.segmentTicker <= 0 then
    table.insert(self.lineStack, {
      origin = self.previousPosition or entity.position(),
      destination = entity.position(),
      ticks = self.segmentTicksToLive
    })
    self.previousPosition = entity.position()
    self.segmentTicker = self.segmentTicks
  end

  -- update stack

    --[[
    self.lineDrawable = {
      line = {origin, destination},
      width = 0.5,
      fullbright = true,
      color = {255,255,255}
    }
  --]]


  for i, line in ipairs(self.lineStack) do
    -- draw line
    localAnimator.addDrawable({
      line = {line.origin, line.destination},
      width = 2,
      fullbright = true,
      color = {255, 255, 200, math.abs(32 * self.lineStack[i].ticks/self.segmentTicksToLive)}
    }) 

    self.lineStack[i].ticks = self.lineStack[i].ticks - 1

    if self.lineStack[i].ticks <= 0 then
      table.remove(self.lineStack, i)
    end
  end
end

function drawHitGuide(circlePoly, position)
  circlePoly = poly.translate(circlePoly, position)
  table.insert(circlePoly, circlePoly[1])
  local circleColor = {255,200,0}
  local circleWidth = 2
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
