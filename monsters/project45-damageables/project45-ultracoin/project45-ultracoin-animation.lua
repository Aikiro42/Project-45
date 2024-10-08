
require "/scripts/poly.lua"
require "/scripts/vec2.lua"

function init()
  self.lineStack = {nil}
  self.segmentTicks = animationConfig.animationParameter("tracerSegmentTickFrequency", 2)
  self.segmentTicker = self.segmentTicks
  self.segmentTicksToLive = animationConfig.animationParameter("tracerSegmentTickLifetime", 10)
  self.tracerParameters = {
    color = {255, 255, 200, 128},
    destructionTime = 0.5,
    size = 2
  }
end

function update(dt)
  localAnimator.clearDrawables()

  -- add segment to stack
  self.segmentTicker = self.segmentTicker - 1
  if self.segmentTicker <= 0 then
    drawStreak(self.previousPosition or entity.position(), entity.position(), self.tracerParameters)
    self.previousPosition = entity.position()
    self.segmentTicker = self.segmentTicks
  end

end

function drawStreak(origin, destination, particleParameters)
  local length = world.magnitude(destination, origin)
  local vector = world.distance(destination, origin)
  local primaryParameters = {
    length = length*8,
    initialVelocity = vec2.mul(vec2.norm(vector), 0.01),
    position = destination,
  }

  particleParameters = sb.jsonMerge({
    type = "streak",
    color = {255, 255, 200},
    light = {25, 25, 20},
    approach = {0, 0},
    timeToLive = 0,
    layer = "back",
    destructionAction = "shrink",
    destructionTime = 1,
    fade=0.1,
    size = 1,
    rotate = true,
    fullbright = true,
    collidesForeground = false,
    variance = {
      length = 0
    }
  }, particleParameters)
  particleParameters = sb.jsonMerge(particleParameters, primaryParameters)
  localAnimator.spawnParticle(particleParameters)
end

--[[
Renders a streak using a scaled-up image of a pixel. Cannot render beyond 100px
--]]
function drawStreakImage(origin, destination, particleParameters, primaryParameters)
  local length = world.magnitude(destination, origin)
  local vector = vec2.norm(world.distance(destination, origin))
  
  local size = 1
  local image = "/particles/project45/pixel.png"

  local directive = string.format("?scalenearest=%.2f;1", length*8/size)
  directive = directive
  
  local midpoint = vec2.add(origin, vec2.mul(vector, length/2))
  local deathTime = (primaryParameters or {}).destructionTime
    or (particleParameters or {}).destructionTime
    or 0.5
  
  primaryParameters = sb.jsonMerge({
    type = "textured",  
    image = image .. directive,
    initialVelocity = vec2.mul(vector, length/(2*deathTime)),
    position = midpoint,
    size = size,
    destructionTime = deathTime,
    timeToLive = 0
  }, primaryParameters)

  particleParameters = sb.jsonMerge({
    timeToLive = 0,
    color = {255, 0, 0},
    layer = "front",
    destructionAction = "shrink",
    fade = deathTime,
    rotate = true,
    rotation = util.toDegrees(vec2.angle(vector)),
    fullbright = true,
    collidesForeground = false,
  }, particleParameters)

  particleParameters = sb.jsonMerge(particleParameters, primaryParameters)
  localAnimator.spawnParticle(particleParameters)
end

function drawStaggeredStreakImage(origin, destination, particleParameters)
  -- sb.logInfo(sb.printJson(destination))
  local length = world.magnitude(destination, origin)
  local vector = vec2.norm(world.distance(destination, origin))
  local segments = math.max(1, math.floor(length/5))

  if segments == 1 then
    drawStreakImage(origin, destination, particleParameters)
  end

  local segmentLength = length / segments
  local segmentVector = vec2.mul(vector, segmentLength)
  local a, b = origin, vec2.add(origin, segmentVector)
  while segments > 0 do
    drawStreakImage(a, b, particleParameters)
    a = b
    b = vec2.add(a, segmentVector)
    segments = segments - 1
  end
end