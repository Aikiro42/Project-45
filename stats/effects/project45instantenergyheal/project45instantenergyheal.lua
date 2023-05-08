function init()
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
  animator.burstParticleEmitter("energy")
  animator.playSound("stim")
  animator.playSound("powerup")
  status.giveResource("energy", status.resourceMax("energy"))
end

function update(dt)

end

function uninit()

end
