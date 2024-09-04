function init()
  -- invulnerability
  animator.setParticleEmitterOffsetRegion("explosion", mcontroller.boundBox())
  effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})
  effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = 0}})
  self.maxDuration = effect.duration()
  animator.burstParticleEmitter("explosion")
  animator.setParticleEmitterActive("phased", true)
  -- turn BLUE and become transparent
  -- self.direk = "?fade=FFFFFF=1?multiply=000000FA?outline=1;BE00FFCC;00000000"
  self.direk = "?fade=FFFFFF=0.1?multiply=54007199"
  effect.setParentDirectives(self.direk)
  
end

function update(dt)

  -- turn BLUE and become transparent
  effect.setParentDirectives(self.direk)
  
  local speedVector = mcontroller.velocity()
  local speedThreshold = {10, 10}

  -- particles
  if math.abs(speedVector[1]) > speedThreshold[1] or math.abs(speedVector[2]) > speedThreshold[2] then
    if mcontroller.facingDirection() == 1 then
      animator.burstParticleEmitter("dodgeRight", true)
      -- animator.burstParticleEmitter("dodgeLeft", false)
    else
      -- animator.burstParticleEmitter("dodgeRight", false)
      animator.burstParticleEmitter("dodgeLeft", true)
    end
  end

end

function uninit()
  animator.burstParticleEmitter("explosion")
  world.spawnProjectile(
        "invisibleprojectile",
        mcontroller.position(),
        activeItem.ownerEntityId(),
        {1, 0},
        false,
        {
            power=0,
            timeToLive=0,
            actionOnReap={
                {
                    action="particle",
                    specification="project45realityshard01"
                },
                {
                    action="particle",
                    specification="project45realityshard02"
                },
                {
                    action="particle",
                    specification="project45realityshard03"
                },
                {
                    action="particle",
                    specification="project45realityshard04"
                },
            }
        }
    )
end
