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

  self.freezeDuration = 3
  self.freezeTimer = -1
  
  self.splitShotChance = config.getParameter("splitShotChance", 0.25)

  self.chainDepth = 1

  self.zeroGControlForce = 0
  self.zeroGControlForceDelta = 4

  self.currentMass = mcontroller.mass()

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
    status.setPersistentEffects("invulnerable", {{stat = "invulnerable", amount = 1}})
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    mcontroller.setVelocity({0, 0})
    self.freezeTimer = self.freezeDuration
    self.timeToLive = self.timeToLive + 3
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
    suicide()
  end)

end

function update(dt)
  
  
  if (self.freezeTimer < 0 and mcontroller.onGround()) or self.timeToLive <= 0 then
    self.expired = true
    suicide()
  end
  
  if not mcontroller.zeroG() then
    self.score = self.score + 1
    self.currentMass = self.currentMass - dt
    mcontroller.controlParameters({
      mass = self.currentMass
    })
  elseif mcontroller.velocity() ~= {0, 0} then
    self.zeroGControlForce = self.zeroGControlForce + self.zeroGControlForceDelta
    mcontroller.controlApproachVelocity({0, 0}, self.zeroGControlForce)
  end

  if self.freezeTimer < 0 then
    self.timeToLive = self.timeToLive - dt
  else
    self.freezeTimer = self.freezeTimer - dt
  end
  animator.rotateTransformationGroup("body", self.angularVelocity)  
  
end

function suicide()
  status.modifyResource("health", -status.resource("health"))
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
        elseif world.entityCanDamage(entity.id(), entityId) then
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
      
      if finalTarget and world.entityExists(finalTarget) then
        sb.logInfo("Final Target: " .. world.entityTypeName(finalTarget))
        local finalDestination = world.entityPosition(finalTarget)
        local statfx = self.rootDamageRequest.statusEffects
        renderShot(mcontroller.position(), finalDestination, {
          power = calculateFinalDamage(),
          damageType = "IgnoresDef",
          statusEffects = #statfx > 0 and statfx or nil
        })
      
      elseif isFinal or not splitShot then
        sb.logInfo("Failed to find a target.")
        monster.setAnimationParameter("finalDamageParticle", {
          order = 0,
          finalDamage = calculateFinalDamage()
        })
      end
    end

  else
    animator.playSound("drop")
    animator.burstParticleEmitter("deathPoof")
  end
end

function calculateFinalDamage()
  return self.baseDamage
end

function renderShot(origin, destination, projectileParams)
        
  monster.setAnimationParameter("hitscanRenderJob", {
    order = sb.nrand(100, 0),
    origin = origin,
    destination = destination,
    particleParameters = {
      color = {255, 255, 200},
      light = {25, 25, 20},
      destructionTime = 0.3,
      size = 2
    }
  })

  local defaultParams = {
    power=0,
    speed=0,
    timeToLive=0.1,
    piercing = true
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