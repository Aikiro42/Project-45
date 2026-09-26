function init()
  
  message.setHandler("applyStatusEffect", function(messageType, b, effectConfig, duration, sourceEntityId)

    local hType = not status.statPositive("shieldHealth") and world.entityType(entity.id()) == "player" and "Hit" or "ShieldHit"

    -- sb.logInfo(world.entityType(entity.id()))
    if effectConfig == "project45zoltraakdamage" then
      status.applySelfDamageRequest({
          damageType="IgnoresDef",
          damageSourceKind="project45holy",
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