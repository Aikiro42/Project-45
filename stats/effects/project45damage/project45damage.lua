function init()
  status.applySelfDamageRequest({
    damageType="IgnoresDef",
    damage= effect.duration(),
    sourceEntityId= effect.sourceEntity()
  })
  effect.expire()
end

function update(dt)
end

function uninit()
end
