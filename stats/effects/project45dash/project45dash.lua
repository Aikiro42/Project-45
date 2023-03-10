function init()
  -- invulnerability
  effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})

  -- turn BLUE and become transparent
  effect.setParentDirectives("?fade=FFFFFF=0.1?multiply=FFFFFF3F")

end

function update(dt)

  -- turn BLUE and become transparent
  effect.setParentDirectives("?fade=FFFFFF=0.1?multiply=FFFFFF3F")

  -- particles
  if mcontroller.xVelocity() ~= 0 or mcontroller.yVelocity() ~= 0 then
    if mcontroller.facingDirection() == 1 then
      animator.setParticleEmitterActive("dodgeRight", true)
      animator.setParticleEmitterActive("dodgeLeft", false)
    else
      animator.setParticleEmitterActive("dodgeRight", false)
      animator.setParticleEmitterActive("dodgeLeft", true)
    end
  else
    animator.setParticleEmitterActive("dodgeRight", false)
    animator.setParticleEmitterActive("dodgeLeft", false)
  end

end

function uninit()
  
end
