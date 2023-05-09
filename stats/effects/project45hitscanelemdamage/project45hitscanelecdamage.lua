function init()
  
  message.setHandler("applyStatusEffect", function(messageType, b, effectConfig, duration, sourceEntityId)
    
    if effectConfig == "project45hitscanelecdamage" then

      local hType = not status.statPositive("shieldHealth") and world.entityType(entity.id()) == "player" and "Hit" or "ShieldHit"
    
      status.applySelfDamageRequest({
        damageType="IgnoresDef",
        damageSourceKind="electric",
        damage=duration,
        sourceEntityId=sourceEntityId,
        hitType=hType
      })
    
    else
      status.addEphemeralEffect(effectConfig, duration, sourceEntityId)
    end
  end)

  effect.expire()
end

function update(dt)
  effect.expire()
end