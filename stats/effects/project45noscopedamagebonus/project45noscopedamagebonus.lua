function init()
  self.currentPowerMultiplier = status.stat("powerMultiplier")
  animator.setParticleEmitterOffsetRegion("mlg", mcontroller.boundBox())
  animator.setParticleEmitterBurstCount("mlg", 5)
  animator.burstParticleEmitter("mlg")
  animator.setParticleEmitterActive("mlg", true)
  effect.setParentDirectives("fade=51BD3B=0.1")
  effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.currentPowerMultiplier}})

end

function update(dt)

end

function uninit()

end
