-- require "/monsters/monster.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

local oldInit = init or function() end
local oldUpdate = update or function() end
function init()

  self.parentEntityId = config.getParameter("parentEntityId")

  self.suicideDamageRequest = {
    damage = 1000,
    damageType = "damage",
    damageSourceKind = "default",
    sourceEntityId = entity.id()
  }
  self.timeToLive = 3

  self.angularVelocity = -util.toRadians(15)

  local initialMomentum = config.getParameter("initialMomentum", {0,3})
  initialMomentum[2] = initialMomentum[2] * (1 - math.random()*0.3)
  mcontroller.addMomentum(initialMomentum)
  
  self.freeze = nil
  message.setHandler("project45-ultracoin-freeze", function()
    if not self.freeze then
      self.freeze = mcontroller.position()
    end
    self.timeToLive = 3
  end)

end

function update(dt)

  if mcontroller.isColliding() or self.timeToLive <= 0 then
    self.badDeath = true
    status.applySelfDamageRequest(self.suicideDamageRequest)
  end
  
  if self.freeze then
    mcontroller.controlApproachVelocity({0, 0}, 9999)
    mcontroller.controlModifiers({movementSuppressed = true})
  else
    mcontroller.addMomentum({0, 0.3})
  end

  self.timeToLive = self.timeToLive - dt

  -- rotate
  mcontroller.controlRotation(self.angularVelocity)
  animator.rotateTransformationGroup("body", self.angularVelocity)  

  -- oldUpdate(dt)

  
end

function die()
  if not self.badDeath then
    animator.playSound("hit")
    
    -- scan surroundings for nearest coin entity
    local coins = world.entityQuery(mcontroller.position(), 75, {order = "nearest", boundMode = "position", includedTypes = {"player", "monster", "npc"}, withoutEntityId = self.parentEntityId})
    local finalTarget, coinTarget
    for _, coinId in ipairs(coins) do
      if world.entityExists(coinId) then
        world.sendEntityMessage(coinId, "project45-ultracoin-freeze")
        if world.entityTypeName(coinId) ==  "project45-ultracoin" then
          coinTarget = coinId
        end
        finalTarget = coinTarget or coinId
      end
    end

    local projectilePosition = mcontroller.position()
    local projectileVector = vec2.rotate({0, 1}, math.random()*math.pi)

    if world.entityExists(finalTarget) then
      projectilePosition = world.entityPosition(finalTarget)
      projectileVector = vec2.norm(world.distance(projectilePosition, mcontroller.position()))
      world.spawnProjectile(
        "project45stdbullet",
        projectilePosition,
        self.parentEntityId,
        projectileVector,
        true,
        {
          damageTeam={type="indiscriminate", team=0}
        }
      )
    end

  else
    animator.playSound("drop")
    animator.burstParticleEmitter("deathPoof")
  end
end
