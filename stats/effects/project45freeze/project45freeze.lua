function init()

  animator.setParticleEmitterOffsetRegion("freeze", mcontroller.boundBox())
  animator.setParticleEmitterActive("freeze", true)
  effect.setParentDirectives("fade=AAFFFF=0.4")
  animator.playSound("freeze")
  animator.setAnimationRate(0)

  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  
end

function update(dt)
  if not status.resourcePositive("health") then
    effect.expire()
  end
  mcontroller.controlModifiers({
      facingSuppressed = true,
      movementSuppressed = true
    })
end

function onExpire()
  if status.isResource("stunned") then
    status.resetResource("stunned")
  end
  animator.setAnimationRate(1)
end
