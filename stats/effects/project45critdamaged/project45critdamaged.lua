require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.damageListener = damageListener("damageTaken", function(notifications)
    if #notifications > 0 then
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and world.entityExists(notification.targetEntityId) then
          spawnCritVFX(notification.targetEntityId)
          effect.expire()
        end
      end
    end
  end)
end

function update(dt)
end

function uninit()
end

function onExpire()
  -- Code from Chofranc
  critAction = {
      timeToLive = 0,
      damageType = "NoDamage",
      actionOnReap = {
        {
          action = "particle",
          specification = {
            type = "text",
            text =  "^shadow;CRIT!",
            color = {255, 98, 0, 180},
            light = {69, 26, 0},
            destructionAction = "fade",
            destructionTime =  0.5,
            layer = "front",
            position = {0,0},
            size = 0.5,
            approach = {40, 40},
            initialVelocity = {0.0, 20.0},
            finalVelocity = {0.0, 0.0},
            angularVelocity = 0,
            flippable = false,
            timeToLive = 0,
            fullbright = true,
            rotation = 0,
            variance = {
              initialVelocity = {20, 5}
            }
          }
        },
        {
          action = "sound",
          options = {
            "/sfx/project45neosfx/bulletimpact/bulletimpact-organic1.ogg",
            "/sfx/project45neosfx/bulletimpact/bulletimpact-organic2.ogg",
            "/sfx/project45neosfx/bulletimpact/bulletimpact-organic3.ogg"
          }
        }
      }
    }
  world.spawnProjectile("invisibleprojectile", world.entityPosition(targetEntityId), targetEntityId, {0,0}, true,critAction)
end