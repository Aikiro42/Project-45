require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  
  self.healthPercent = config.getParameter("healthDamagePercent") or 0.005
  
  self.bleedTimer = config.getParameter("bleedTimer") or 1
  self.stacks = 1
  self.stackLifetime = config.getParameter("stackLifetime") or 3
  self.stackTimer = self.stackLifetime

  self.prevDuration = effect.duration()
  
  animator.playSound("wound")
end

function update(dt)

  if self.prevDuration < effect.duration() then  -- reapplied
    self.stacks = self.stacks + 1
    self.stackTimer = self.stackLifetime
    effect.modifyDuration(1)
  end

  self.bleedTimer = self.bleedTimer - dt
  self.stackTimer = self.stackTimer - dt
  if self.bleedTimer <= 0 then
    dealDamage(self.healthPercent, self.stacks)
    if self.stackTimer <= 0 then
      self.stacks = math.max(1, self.stacks - 1)
      self.stackTimer = self.stackLifetime
    end
    self.bleedTimer = 1
  end

  self.prevDuration = effect.duration()


end

function dealDamage(healthPercent, stacks)
  stacks = stacks or 1
  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = status.resourceMax("health") * healthPercent * stacks,
    damageSourceKind = "default",
    sourceEntityId = entity.id()
  })
  animator.playSound("bleed")
  animator.burstParticleEmitter("bleed")
end

function uninit()
end