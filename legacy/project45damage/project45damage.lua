function init()
  
  message.setHandler("applyStatusEffect", function(messageType, b, effectConfig, duration, sourceEntityId)
    --[[
    sb.logInfo("=====================================================")
    sb.logInfo("[PROJECT 45] a: " .. messageType)
    sb.logInfo("[PROJECT 45] b: " .. sb.printJson(b))
    sb.logInfo("[PROJECT 45] effectConfig: " .. effectConfig)
    sb.logInfo("=====================================================")
    --]]

    local hType = not status.statPositive("shieldHealth") and world.entityType(entity.id()) == "player" and "Hit" or "ShieldHit"

    -- sb.logInfo(world.entityType(entity.id()))
    if effectConfig == "project45damage" or effectConfig == "project45critdamage" then
      if effectConfig == "project45critdamage" then
        status.applySelfDamageRequest({
          damageType="IgnoresDef",
          damageSourceKind="synthetikmechanics-hitscancrit",
          damage=duration,
          sourceEntityId=sourceEntityId,
          -- hitType="ShieldHit"
          hitType=hType
        })
      else
        status.applySelfDamageRequest({
          damageType="IgnoresDef",
          damageSourceKind="synthetikmechanics-hitscan",
          damage=duration,
          sourceEntityId=sourceEntityId,
          -- hitType="ShieldHit"
          hitType =hType
        })
        -- sb.logInfo("[PROJECT 45] Damage Dealt: " .. duration)
      end
    else
      status.addEphemeralEffect(effectConfig, duration, sourceEntityId)
    end
  end)

  effect.expire()
end

function update(dt)
  effect.expire()
end