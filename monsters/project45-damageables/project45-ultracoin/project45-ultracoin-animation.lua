
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

  local hitscanRenderJob = animationConfig.animationParameter("hitscanRenderJob")
  if hitscanRenderJob and hitscanRenderJob.order ~= self.hitscanRenderJob then
    self.hitscanRenderJob = hitscanRenderJob.order
    drawStreak(hitscanRenderJob.origin, hitscanRenderJob.destination, hitscanRenderJob.particleParameters)
  end

  local finalDamageParticle = animationConfig.animationParameter("finalDamageParticle")
  if finalDamageParticle and finalDamageParticle.order ~= self.finalDamageParticleOrder then
    self.finalDamageParticleOrder = finalDamageParticle.order
    localAnimator.spawnParticle(
      {
        type = "text",
        text= "^shadow;" .. math.floor(finalDamageParticle.finalDamage),
        color = {255, 200, 0},
        initialVelocity={0.0, 15.0},
        finalVelocity={0.0, -15},
        approach={3, 30},
        angularVelocity=20,
        size = 1,
        timeToLive=0.7,
        fullbright = true,
        flippable = false,
        destructionAction="shrink",
        destructionTime=0.5,
        layer = "front",
        variance={
          initialVelocity={9.0, 3.0}
        },
    
      }, entity.position())
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