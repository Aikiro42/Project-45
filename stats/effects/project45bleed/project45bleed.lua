require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.bleedTimer = 1
  self.healthDamagePercentage = 0.03
  animator.playSound("wound")
end

function update(dt)
  self.bleedTimer = self.bleedTimer - dt
  if self.bleedTimer <= 0 then
    self.bleedTimer = 1
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = status.resourceMax("health") * self.healthDamagePercentage,
      damageSourceKind = "default",
      sourceEntityId = entity.id()
    })
    animator.playSound("bleed")
    animator.burstParticleEmitter("bleed")
  end
end

function uninit()
end