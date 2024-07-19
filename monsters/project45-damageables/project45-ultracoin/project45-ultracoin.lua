require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"

function init()
  
  self.parentEntityId = config.getParameter("parentEntityId")
  self.ownerPowerMultipler = config.getParameter("ownerPowerMultipler", 1)
  self.baseDamage = config.getParameter("baseDamage", 45)
  self.timeToLive = 30

  self.angularVelocity = -util.toRadians(180)

  self.freeze = nil
  self.freezeDuration = 0.1
  self.freezeTimer = 0
  
  self.splitShotChance = 0.25

  self.chainDepth = 1
  self.bounces = 3

  -- give momentum
  local initialMomentum = config.getParameter("initialMomentum", {5,5})
  mcontroller.addMomentum(initialMomentum)
  self.currentVelocity = mcontroller.velocity()

  --monster.setAnimationParameter("collisionPoly", mcontroller.collisionPoly())
    
  animator.rotateTransformationGroup("body", sb.nrand(math.pi, 0))  

  -- set handlers
  message.setHandler("project45-ultracoin-freeze", function()
    if not self.freeze then
      self.freeze = mcontroller.position()
    end
    self.freezeTimer = self.freezeDuration
    self.timeToLive = 3
  end)

  message.setHandler("project45-ultracoin-die", function(_, _, origin, depth, distanceBonus)
    renderShot(origin, mcontroller.position())
    status.addEphemeralEffect("project45death")
    self.chainDepth = depth + 1
    self.distanceBonus = (distanceBonus or 0) + math.abs(world.magnitude(origin, mcontroller.position()))
  end)

end

function update(dt)

  -- monster.setAnimationParameter("position", mcontroller.position())

  if self.bounces == 0
  or self.timeToLive <= 0 then
      self.expired = true
      status.addEphemeralEffect("project45death")
  end
  
  if willCollide(dt) then
    mcontroller.setXVelocity(self.currentVelocity[1]*0.5)
    mcontroller.controlJump()
    self.currentVelocity[2] = self.currentVelocity[2]*0.5
    self.bounces = self.bounces - 1
  end

  mcontroller.controlParameters({
    airJumpProfile = {
      jumpSpeed = self.currentVelocity[2]
    }
  })


  --[[
  if self.freeze and self.freezeTimer > 0 then
    mcontroller.controlApproachVelocity({0, 0}, 9999)
    mcontroller.controlModifiers({movementSuppressed = true})
    self.freezeTimer = self.freezeTimer - dt
  else
    if self.approachVelocity.sustainTime > 0 then
      mcontroller.controlApproachVelocity(self.approachVelocity.velocity, self.approachVelocity.force)
      if self.approachVelocity.threshold > self.approachVelocity.force then
        self.approachVelocity.force = math.min(self.approachVelocity.threshold, self.approachVelocity.force + self.approachVelocity.delta)
      else
        self.approachVelocity.sustainTime = self.approachVelocity.sustainTime - dt
      end
    end
  --]]

  self.timeToLive = self.timeToLive - dt

  -- rotate
  animator.rotateTransformationGroup("body", self.angularVelocity)  
  
end

function die()

  self.freeze = mcontroller.position()
  self.freezeTimer = self.freezeDuration

  -- hit
  if not self.expired then
    animator.playSound("hit")
    animator.burstParticleEmitter("hitPoof")

    -- scan surroundings for nearest coin entity
    local entityIds = world.entityQuery(
      mcontroller.position(),
      75,
      {
        order = "nearest",
        boundMode = "position",
        includedTypes = {"player", "monster", "npc"},
        withoutEntityId = self.parentEntityId
      }
    )
    local finalTarget, coinTarget

    for _, entityId in ipairs(entityIds) do
      if world.entityExists(entityId) and entityId ~= entity.id() then
        if world.entityTypeName(entityId) ==  "project45-ultracoin" then
          world.sendEntityMessage(entityId, "project45-ultracoin-freeze")
          coinTarget = coinTarget or entityId
        else
          finalTarget = entityId
        end
      end
    end

    local isFinal

    if coinTarget and world.entityExists(coinTarget) then
      world.sendEntityMessage(coinTarget, "project45-ultracoin-die", mcontroller.position(), self.chainDepth, self.distanceBonus or 0)
    else
      isFinal = true
    end

    if isFinal or math.random() <= self.splitShotChance then
      local finalDestination = mcontroller.position()
      if finalTarget and world.entityExists(finalTarget) then
        finalDestination = world.entityPosition(finalTarget)
      end
      local distanceBonus = math.abs(world.magnitude(finalDestination, self.initPoint or mcontroller.position()))
      renderShot(mcontroller.position(), finalDestination, {
        power = calculateDamage(distanceBonus),
        damageType = "IgnoresDef"
      })
    end

  else
    animator.playSound("drop")
    animator.burstParticleEmitter("deathPoof")
  end
end


function isColliding()
  self.previousPosition = self.previousPosition or mcontroller.position()
  local wallCollisionSet = {"Dynamic", "Block"}
  if world.lineCollision(mcontroller.position(), self.previousPosition, wallCollisionSet)
  then
    return true
  end
  self.previousPosition = mcontroller.position()
  return false
end

function willCollide(dt)
  local expectedPosition = vec2.add(mcontroller.position(), vec2.norm(mcontroller.velocity()))
  local wallCollisionSet = {"Dynamic", "Block"}
  local pos = mcontroller.position()
  
  local origin = mcontroller.position()
  local destination = expectedPosition

  world.debugLine(origin, destination, "red")
  return world.lineCollision(origin, destination, wallCollisionSet)
end

function calculateDamage(distanceBonus)
  return self.baseDamage * math.max(1, distanceBonus/8) * self.ownerPowerMultipler * self.chainDepth
end

function renderShot(origin, destination, projectileParams)
      
  local vector = vec2.norm(world.distance(destination, origin))
  local len = world.magnitude(destination, origin)

  local defaultParams = {
    power=0,
    speed=10,
    timeToLive=0.01,
    damageType="noDamage",
    piercing = true,
    periodicActions = {
      {
        time = 0,
        ["repeat"] = false,
        action = "loop",
        count = 1,
        body = {{
          action = "particle",
          specification = {
            type = "streak",
            color = {255, 255, 200},
            light = {25, 25, 20},
            length = len*8,
            initialVelocity = vec2.mul(vector, 0.01),
            position = {0, 0},
            approach = {0, 0},
            timeToLive = 0,
            layer = "back",
            destructionAction = "shrink",
            destructionTime = 0.1,
            fade=0.1,
            size = 1,
            rotate = true,
            fullbright = true,
            collidesForeground = false,
            variance = {
              length = 0
            }
          }
        }}
      }
    }
  }
  projectileParams = projectileParams or {}

  local finalParams = sb.jsonMerge(defaultParams, projectileParams)
  world.spawnProjectile(
    "invisibleprojectile",
    destination,
    entity.id(),
    vector,
    false,
    finalParams
  )
end