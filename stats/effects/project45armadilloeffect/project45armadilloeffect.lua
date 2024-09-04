function init()
  animator.setAnimationState("shield", "activating")
  animator.playSound("activate")
  animator.playSound("loop", -1)
  local shieldHealth = status.resourceMax("health") + status.resource("energy")
  -- sb.logInfo(string.format("Shield health: %f", shieldHealth))
  self.lastShieldHealth = shieldHealth
  self.maxEffectDuration = effect.duration()
  status.setResource("damageAbsorption", shieldHealth)
end

function update(dt)

  if not status.resourcePositive("damageAbsorption") then
    status.giveResource("health", status.resourceMax("health") * 0.5 * effect.duration() / self.maxEffectDuration)
    animator.setAnimationState("shield", "breaking")
    animator.playSound("break")
    animator.playSound("deactivate")
    effect.expire()
  end

  if self.lastShieldHealth > status.resource("damageAbsorption") then
    animator.setAnimationState("shield", "hit" .. math.ceil(math.random() * 3))
    animator.playSound("hit")
    animator.burstParticleEmitter("hitParticles")
    self.lastShieldHealth = status.resource("damageAbsorption")
  end
  --[[
  mcontroller.controlModifiers({
    speedModifier = 0.5,
    airJumpModifier = 0.5,
    runningSuppressed = true
  })
  --]]
end

function onExpire()
  animator.playSound("deactivate")
end

function uninit()
  status.setResource("damageAbsorption", 0)
  animator.stopAllSounds("activate")
  animator.stopAllSounds("loop")
  status.addEphemeralEffect("project45armadilloeffectend")
end