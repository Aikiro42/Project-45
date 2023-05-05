function init()
  
  message.setHandler("applyStatusEffect", function(messageType, b, effectConfig, duration, sourceEntityId)
    
    if effectConfig == "project45hitscanicedamage" then
    
      status.applySelfDamageRequest({
        damageType="IgnoresDef",
        damageSourceKind="ice",
        damage=duration,
        sourceEntityId=sourceEntityId,
        hitType="ShieldHit"
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