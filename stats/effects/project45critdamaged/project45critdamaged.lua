function init()

  self.critvfxtime = 0.1
  
  -- guarantee that this status effect always lasts 0.1s
  if effect.duration() > self.critvfxtime then
    effect.modifyDuration(-effect.duration() + self.critvfxtime)
  end

  animator.setParticleEmitterOffsetRegion("damagedParticle", mcontroller.boundBox())
  animator.burstParticleEmitter("damagedParticle")
  animator.burstParticleEmitter("criticalParticle")
  animator.playSound("damagedSound")
  self.critvfxtimer = self.critvfxtime
end

function update(dt)

  self.critvfxtimer = math.max(0, self.critvfxtimer - dt)
  if self.critvfxtimer == 0 then
    animator.burstParticleEmitter("damagedParticle")
    animator.burstParticleEmitter("criticalParticle")
    animator.playSound("damagedSound")
    self.critvfxtimer = self.critvfxtime 
  end

  animator.burstParticleEmitter("damagedParticle")
end

function uninit()

end
