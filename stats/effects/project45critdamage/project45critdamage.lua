function init()
  
  status.applySelfDamageRequest({
    damageType="IgnoresDef",
    damageSourceKind="synthetikmechanics-hitscancrit",
    damage=effect.duration(),
    sourceEntityId= effect.sourceEntity(),
    hitType="ShieldHit"
  })

  message.setHandler("applyStatusEffect", function(messageType, b, effectConfig, duration, sourceEntityId)
    --[[
    sb.logInfo("=====================================================")
    sb.logInfo("[PROJECT 45] a: " .. messageType)
    sb.logInfo("[PROJECT 45] b: " .. sb.printJson(b))
    sb.logInfo("[PROJECT 45] effectConfig: " .. effectConfig)
    sb.logInfo("=====================================================")
    --]]
    if effectConfig == "project45damage" or effectConfig == "project45critdamage" then
      if effectConfig == "project45critdamage" then
        status.applySelfDamageRequest({
          damageType="IgnoresDef",
          damageSourceKind="synthetikmechanics-hitscancrit",
          damage=duration,
          sourceEntityId=sourceEntityId,
          hitType="ShieldHit"
        })
      else
        status.applySelfDamageRequest({
          damageType="IgnoresDef",
          damageSourceKind="synthetikmechanics-hitscan",
          damage=duration,
          sourceEntityId=sourceEntityId,
          hitType="ShieldHit"
        })
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