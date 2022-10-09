function init()
  status.applySelfDamageRequest({
    damageType="damage",
    damage= effect.duration(),
    sourceEntityId= effect.sourceEntity()
  })
  effect.expire()
end