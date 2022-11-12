function init()

  --[[
  In binary:
  effect.duration() ->[actual damage][ignores def][crit]
  Hence,
  actual_damage = effect.duration >> 2 = effect.duration() / 4
  

  ]]--

  status.applySelfDamageRequest({
    damageType="IgnoresDef",
    damageSourceKind="synthetikmechanics-hitscancrit",
    damage=effect.duration(),
    sourceEntityId= effect.sourceEntity(),
    hitType="ShieldHit"
  })

  effect.expire()
end

function update(dt)
  effect.expire()
end