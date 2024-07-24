require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"

function init()
  -- gather owner data
  self.ownerEntityId = config.getParameter("ownerEntityId")
  self.ownerDamageTeam = config.getParameter("ownerDamageTeam")
  self.ownerPowerMultiplier = config.getParameter("ownerPowerMultiplier", 1)
  
  -- gather parameters
  self.maxChainDistance = config.getParameter("maxChainDistance", 75)
  self.timeToLive = config.getParameter("timeToLive", 10)
  self.angularVelocity = config.getParameter("angularVelocity", -util.toRadians(180))
  self.finalDamageMult = config.getParameter("finalDamageMult", 0)

  self.freezeDuration = 3

  local defaultSplitshotParameters = {
    time = 0.3,
    rand = 3,
    damageMult = 1
  }
  self.splitShotParameters = sb.jsonMerge(defaultSplitshotParameters, config.getParameter("splitShotParameters", {}))
  self.splitShotParameters.time = self.timeToLive - (self.splitShotParameters.time + math.abs(sb.nrand(self.splitShotParameters.rand, 0)))

  local defaultFallControlParameters = {
    deltas = {
      controlForce = 4,
      airFriction=0.25
    },
    maxAirFrictionRand = 0.3
  }
  self.fallControlParameters = sb.jsonMerge(defaultFallControlParameters, config.getParameter("fallControlParameters", {}))

  -- initialize variables

  self.baseDamage = 1
  self.freezeTimer = -1
  self.debugFreezeTime = 0
  self.zeroGControlForce = 0
  self.fallingAirFriction = 0
  
  local airFrictionSub = math.abs(sb.nrand(self.fallControlParameters.maxAirFrictionRand, 0))
  self.maxAirFriction = 1 - airFrictionSub

  monster.setDamageBar("none")

  -- give momentum
  local initialMomentum = config.getParameter("initialMomentum", {5,5})
  mcontroller.addMomentum(initialMomentum)
  self.currentVelocity = mcontroller.velocity()
    
  animator.rotateTransformationGroup("body", sb.nrand(math.pi, 0))  

  -- set handler for freezing
  -- this message is received if potentially targeted by a ricoshot
  message.setHandler("project45-ultracoin-freeze", function()
    status.setPersistentEffects("invulnerable", {{stat = "invulnerable", amount = 1}})
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    mcontroller.setVelocity({0, 0})
    self.freezeTimer = self.freezeDuration
  end)
  
  -- set handler for passing on the ricoshot
  message.setHandler("project45-ultracoin-chain", function(_, _, rootDamageRequest, damageMultiplier, originPos)
    if originPos then
      renderShot(originPos, mcontroller.position())
    else
      -- sb.logInfo("Starting chain on " .. entity.id())
    end
    self.rootDamageRequest = rootDamageRequest
    self.damageMultiplier = damageMultiplier + 1
    self.baseDamage = self.rootDamageRequest.damage * self.damageMultiplier
    -- sb.logInfo(string.format("(%d) Coin %d; Current damage: %.2f", entity.id(), damageMultiplier-1, self.baseDamage))
    sudoku()
  end)

end

function update(dt)
  
  -- die when hitting ground or out of TTL
  if (self.freezeTimer < 0 and mcontroller.onGround()) or self.timeToLive <= 0 then
    self.expired = true
    sudoku()
  end
  
  -- if in zero gravity, gradually stop
  if mcontroller.zeroG() and mcontroller.velocity() ~= {0, 0} then
    self.zeroGControlForce = self.zeroGControlForce + self.fallControlParameters.deltas.controlForce * dt
    mcontroller.controlApproachVelocity({0, 0}, self.zeroGControlForce)
  
    -- if under influence of gravity, slow descent
  elseif mcontroller.yVelocity() <= 0 then
    self.fallingAirFriction = self.fallingAirFriction + self.fallControlParameters.deltas.airFriction * dt
    mcontroller.controlParameters({
      airFriction = math.min(self.maxAirFriction, self.fallingAirFriction)
    })
  end

  -- deplete TTL, pause if frozen
  if self.freezeTimer < 0 then
    self.timeToLive = self.timeToLive - dt
  else
    self.freezeTimer = self.freezeTimer - dt
  end

  -- indicate split shot
  if not self.twinkled then
    if canSplitShot() then
      animator.burstParticleEmitter("twinkle")
      animator.playSound("twinkle")
      self.twinkled = true
    end
  end

  -- spin
  animator.rotateTransformationGroup("body", self.angularVelocity)  
  
end


function sudoku()
  status.modifyResource("health", -status.resource("health"))
end

function canSplitShot()
  return self.timeToLive <= self.splitShotParameters.time
end

function die()
  
  -- if hit, process ricoshot logic
  if self.rootDamageRequest then

    -- indicate success first
    animator.playSound("hit")
    animator.burstParticleEmitter("hitPoof")

    -- set own damage team to that of owner/damage source
    -- if neither exists, be indiscri
    local finalDamageTeam
    if self.ownerDamageTeam then
      finalDamageTeam = self.ownerDamageTeam
    elseif world.entityExists(self.rootDamageRequest.sourceEntityId) then
      finalDamageTeam = world.entityDamageTeam(self.rootDamageRequest.sourceEntityId)
    else
      finalDamageTeam = {
        type = "indiscriminate"
      }
    end
    monster.setDamageTeam(finalDamageTeam)

    -- scan surroundings for nearest coin/target entity;
    -- freeze each coin it detects,
    -- remember non-coin entity as potential final target if it can be damaged
    -- finalTarget can be nil
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

    --[[
    sb.logInfo(string.format("\tCan %d split shot (%.2f <= %.2f)? %s",
      entity.id(),
      self.timeToLive,
      self.splitShotParameters.time,
      canSplitShot() and "yes" or "no"))
    sb.logInfo(string.format("\tIs %d last in chain? %s", entity.id(), isFinal and "yes" or "no"))
    --]]

    -- hit target if split shot process
    -- or if there are no more coins
    local splitShot = canSplitShot()
    if isFinal or splitShot then
      -- sb.logInfo(string.format("\t(%d) -> (%s); Final Damage: %f", entity.id(), finalTarget, self.baseDamage))
      
      if finalTarget and world.entityExists(finalTarget) then
        -- sb.logInfo("Final Target: " .. world.entityTypeName(finalTarget))
        local finalDestination = world.entityPosition(finalTarget)
        local statfx = self.rootDamageRequest.statusEffects
        renderShot(mcontroller.position(), finalDestination, {
          power = calculateFinalDamage(splitShot and not isFinal),
          damageType = "IgnoresDef",
          statusEffects = #statfx > 0 and statfx or nil
        })
      
      elseif isFinal or not canSplitShot() then
        -- sb.logInfo("Failed to find a target.")
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

function calculateFinalDamage(splitShot)
  return self.baseDamage * self.finalDamageMult * (splitShot and self.splitShotParameters.damageMult or 1)
end

function renderShot(origin, destination, projectileParams)
        
  monster.setAnimationParameter("hitscanRenderJob", {
    order = sb.nrand(100, 0),
    origin = origin,
    destination = destination,
    particleParameters = {
      color = {255, 255, 200}
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