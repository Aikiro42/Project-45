require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"

function init()
  
  self.ownerEntityId = config.getParameter("ownerEntityId")
  self.ownerDamageTeam = config.getParameter("ownerDamageTeam")
  self.ownerPowerMultiplier = config.getParameter("ownerPowerMultiplier", 1)
  
  self.maxChainDistance = config.getParameter("maxChainDistance", 75)

  self.baseDamage = 1
  self.score = 0

  self.timeToLive = config.getParameter("timeToLive", 10)

  self.angularVelocity = config.getParameter("angularVelocity", -util.toRadians(180))

  self.freeze = nil
  self.freezeDuration = 0.1
  self.freezeTimer = 0
  
  self.splitShotChance = config.getParameter("splitShotChance", 0.25)

  self.chainDepth = 1

  monster.setAnimationParameter("tracerSegmentTickLifetime", config.getParameter("tracerSegmentTickLifetime", 10))
  monster.setAnimationParameter("tracerSegmentTickFrequency", config.getParameter("tracerSegmentTickFrequency", 10))

  monster.setDamageBar("none")

  -- give momentum
  local initialMomentum = config.getParameter("initialMomentum", {5,5})
  mcontroller.addMomentum(initialMomentum)
  self.currentVelocity = mcontroller.velocity()

  --monster.setAnimationParameter("collisionPoly", mcontroller.collisionPoly())
    
  animator.rotateTransformationGroup("body", sb.nrand(math.pi, 0))  

  -- set handlers
  message.setHandler("project45-ultracoin-freeze", function()
    self.freeze = true
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    status.setPersistentEffects("invulnerable", {{stat = "invulnerable", amount = 1}})
    mcontroller.setVelocity({0, 0})
    self.freezeTimer = self.freezeDuration
    self.timeToLive = math.max(self.timeToLive, 3)
  end)

  message.setHandler("project45-ultracoin-die", function(_, _, origin, depth, baseDamage, distanceBonus, isSource)
    if origin then
      renderShot(origin, mcontroller.position())
    end
    self.baseDamage = (self.baseDamage or 0) + baseDamage
    self.chainDepth = (depth or 0) + 1
    self.distanceBonus = (distanceBonus or 0) + math.abs(world.magnitude(origin, mcontroller.position()))
    status.addEphemeralEffect("project45death")
  end)
  
  message.setHandler("project45-ultracoin-chain", function(_, _, rootDamageRequest, damageMultiplier, originPos)
    if originPos then
      sb.logInfo("Chain: " .. damageMultiplier-1)
      renderShot(originPos, mcontroller.position())
    else
      sb.logInfo("Starting chain: 1")
    end
    self.rootDamageRequest = rootDamageRequest
    self.damageMultiplier = damageMultiplier + 1
    self.baseDamage = self.rootDamageRequest.damage * self.damageMultiplier
    sb.logInfo(string.format("Current damage: %.2f", self.baseDamage))
    status.modifyResource("health", -status.resource("health"))
  end)

end

function update(dt)
  
  --[[
  if mcontroller.isColliding() or self.timeToLive <= 0 then
    self.expired = true
    status.addEphemeralEffect("project45death")
  end
  --]]
  self.score = self.score + 1
  self.timeToLive = self.timeToLive - dt
  animator.rotateTransformationGroup("body", self.angularVelocity)  
  
end

function die()
  --[[
  sb.logInfo("Damage Taken Since: " .. sb.printJson(
    status.damageTakenSince()
  ,1))
  --]]
  
  -- hit
  if self.rootDamageRequest then

    animator.playSound("hit")
    animator.burstParticleEmitter("hitPoof")

    -- initialize damage team
    local finalDamageTeam
    if self.ownerDamageTeam then
      finalDamageTeam = self.ownerDamageTeam
    elseif world.entityExists(self.rootDamageRequest.sourceEntityId) then
      finalDamageTeam = world.entityDamageTeam(self.rootDamageRequest.sourceEntityId)
    else
      finalDamageTeam = {
        type = "indiscriminate",
        team = 0
      }
    end
    monster.setDamageTeam(finalDamageTeam)

    -- scan surroundings for nearest coin/target entity;
    -- freeze each coin it detects
    local finalTarget, coinTarget
    local entityIds = world.entityQuery(
      mcontroller.position(),
      self.maxChainDistance,
      {
        order = "nearest",
        boundMode = "position",
        includedTypes = {"player", "monster", "npc"},
        withoutEntityId = self.ownerEntityId
      }
    )
    for _, entityId in ipairs(entityIds) do
      if world.entityExists(entityId) and entityId ~= entity.id() then
        if world.entityTypeName(entityId) ==  "project45-ultracoin" then
          world.sendEntityMessage(entityId, "project45-ultracoin-freeze")
          coinTarget = coinTarget or entityId
        else
          finalTarget = finalTarget or entityId
        end
      end
    end

    -- activate next coin if they exist
    local isFinal
    if coinTarget and world.entityExists(coinTarget) then
      world.sendEntityMessage(
        coinTarget,
        "project45-ultracoin-chain",
        self.rootDamageRequest,
        self.damageMultiplier,
        mcontroller.position()
      )
    else
      isFinal = true
    end

    -- hit target if split shot process
    -- or if there are no more coins
    local splitShot = math.random() <= self.splitShotChance
    sb.logInfo("split shot? " .. (splitShot and "yes" or "no"))
    if isFinal or splitShot then
      sb.logInfo("Final Damage: " .. self.baseDamage)
      local finalDestination = mcontroller.position()
      if finalTarget and world.entityExists(finalTarget) then
        finalDestination = world.entityPosition(finalTarget)
      end
      local statfx = self.rootDamageRequest.statusEffects
      renderShot(mcontroller.position(), finalDestination, {
        power = self.baseDamage,
        damageType = "IgnoresDef",
        statusEffects = #statfx > 0 and statfx or nil
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
  return util.clamp(
    self.baseDamage
      -- * math.max(1, distanceBonus)
      * self.ownerPowerMultiplier
      * self.chainDepth
      * self.damageCalcParameters.finalDamageMultiplier,
    self.damageCalcParameters.finalDamageRange[1],
    self.damageCalcParameters.finalDamageRange[2]
  )
end

function renderShot(origin, destination, projectileParams)
      
  local vector = vec2.norm(world.distance(destination, origin))
  local len = world.magnitude(destination, origin)

  local defaultParams = {
    power=0,
    speed=0,
    timeToLive=0.1,
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
    self.ownerEntityId,
    vector,
    false,
    finalParams
  )
end