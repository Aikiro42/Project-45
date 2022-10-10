function init()
  
  status.applySelfDamageRequest({
    damageType="IgnoresDef",
    damage= effect.duration(),
    sourceEntityId= effect.sourceEntity(),
    hitType="ShieldHit"
  })

  effect.expire()
end

function update(dt)
  effect.expire()
end