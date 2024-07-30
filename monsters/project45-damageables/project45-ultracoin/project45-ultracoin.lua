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
  self.damageMutiplierIncrement = config.getParameter("damageMultiplierIncrement", 1)
  self.multipliers = {
    finalDamageMult = config.getParameter("finalDamageMult", 1),
  }
  self.groundedDamageMult = config.getParameter("groundedDamageMult", 1)
  self.currentControlParameters = {}
  self.airTimeScoreMult = config.getParameter("airTimeScoreMult", 0.01)

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
  self.freezeDuration = 1
  self.groundedPenaltyMult = 1
  self.freezeTimer = -1
  self.zeroGControlForce = 0
  self.currentControlParameters.airFriction = 0
  self.airTimeScore = 0
  
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
  message.setHandler("project45-ultracoin-freeze", freeze)
  message.setHandler("project45-ultracoin-unfreeze", unfreeze)
  
  -- set handler for passing on the ricoshot
  message.setHandler("project45-ultracoin-chain", function(_, _, rootDamageRequest, damageMultiplier, originPos, targetId)
    self.volumeDivisor = damageMultiplier or 1
    damageMultiplier = damageMultiplier or self.damageMultiplier
    if self.grounded then
      refresh(rootDamageRequest, damageMultiplier, originPos, targetId)
    else
      chain(rootDamageRequest, damageMultiplier, originPos)
    end
  end)

  message.setHandler("project45-ultracoin-refresh", function(_, _, rootDamageRequest, damageMultiplier, originPos)
    self.volumeDivisor = damageMultiplier or 1
    refresh(rootDamageRequest, damageMultiplier, originPos)
  end)
  
end

function chain(rootDamageRequest, damageMultiplier, originPos)
  if originPos then
    renderShot(originPos, mcontroller.position())
  end
  self.rootDamageRequest = rootDamageRequest
  self.damageMultiplier = (self.damageMultiplier or damageMultiplier or 1) + self.damageMutiplierIncrement
  self.baseDamage = self.rootDamageRequest.damage * self.damageMultiplier
  sudoku()
end

function refresh(rootDamageRequest, damageMultiplier, originPos, targetId)
  if originPos then
    renderShot(originPos, mcontroller.position())
  end
  status.clearPersistentEffects("invulnerable")
  status.addEphemeralEffect("invulnerable", 0.05)
  animator.playSound("refreshHit")
  animator.burstParticleEmitter("hitPoof")
  mcontroller.addMomentum({
      sb.nrand(0.25, 0),
      sb.nrand(0.1, 2)
    })
  if targetId and world.entityExists(targetId) then
    -- sb.logInfo("Final Target: " .. world.entityTypeName(finalTarget))
    local statfx = rootDamageRequest.statusEffects
    local finalDestination = world.entityPosition(targetId)
    renderShot(mcontroller.position(), finalDestination, {
      power = calculateFinalDamage(false, rootDamageRequest.damage * (damageMultiplier or 1)),
      damageType = "IgnoresDef",
      statusEffects = #statfx > 0 and statfx or nil
    }, true)
  end
  self.twinkled = false
  self.timeToLive = self.splitShotParameters.time + 0.1 + math.abs(sb.nrand(self.splitShotParameters.rand, 0))
  self.currentControlParameters.airFriction = 0
  self.grounded = false
  self.currentControlParameters.gravityEnabled = true
end

function update(dt)

  self.grounded = mcontroller.groundMovement()

  -- die when out of TTL
  if self.timeToLive <= 0 then
    self.expired = true
    sudoku()
  end
  
  -- if in zero gravity, gradually stop
  if mcontroller.zeroG() and mcontroller.velocity() ~= {0, 0} then
    self.zeroGControlForce = self.zeroGControlForce + self.fallControlParameters.deltas.controlForce * dt
    mcontroller.controlApproachVelocity({0, 0}, self.zeroGControlForce)
  
  -- if under influence of gravity, slow descent
  elseif mcontroller.yVelocity() <= 0 then
    self.currentControlParameters.airFriction = math.min(
      self.maxAirFriction,
      self.currentControlParameters.airFriction + self.fallControlParameters.deltas.airFriction * dt
    )
  end

  -- deplete TTL, pause if frozen
  if self.freezeTimer < 0 then
    self.timeToLive = self.timeToLive - (dt * 1) -- (self.grounded and 8 or 1))
    self.currentControlParameters.gravityEnabled = true
    status.clearPersistentEffects("invulnerable")
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

  -- if grounded...
  if self.grounded then
    -- play sound
    if not self.landed then
      animator.playSound("drop")
      self.landed = true
    end
    -- apply damage penalty
    self.multipliers.groundedDamageMult = self.groundedDamageMult
    -- reset air time score
    self.airTimeScore = 0
    -- unfreeze
    if self.freezeTimer > 0 then
      unfreeze()
    end
    -- lay flat on ground
    animator.resetTransformationGroup("body")  

  -- else if air/waterborne...
  else
    -- reset sound flag
    self.landed = false
    -- rotate
    animator.rotateTransformationGroup("body", self.angularVelocity)
    -- increment air time score
    self.airTimeScore = self.airTimeScore + 1
  end
  
  mcontroller.controlParameters(self.currentControlParameters)

end

function freeze()
  status.setPersistentEffects("invulnerable", {{stat = "invulnerable", amount = 1}})
  mcontroller.setVelocity({0, 0})
  self.freezeTimer = self.freezeDuration
end

function unfreeze()
  status.clearPersistentEffects("invulnerable")
  self.currentControlParameters.gravityEnabled = true
  self.freezeTimer = 0
end

function sudoku()
  status.modifyResource("health", -status.resource("health"))
end

function canSplitShot()
  return not self.grounded and self.timeToLive <= self.splitShotParameters.time
end

function die()
  sb.logInfo(self.airTimeScore)
  -- if hit, process ricoshot logic
  if self.rootDamageRequest and not self.expired then

    -- indicate success first
    animator.playSound("hit")
    animator.setSoundVolume("hit", 1/(self.volumeDivisor or 1))
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
    if not self.grounded and coinTarget and world.entityExists(coinTarget) then
      world.sendEntityMessage(
        coinTarget,
        "project45-ultracoin-chain",
        self.rootDamageRequest,
        self.damageMultiplier,
        mcontroller.position(),
        finalTarget
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
      local statfx = self.rootDamageRequest.statusEffects
      if finalTarget and world.entityExists(finalTarget) then
        self.finalTarget = finalTarget
        -- sb.logInfo("Final Target: " .. world.entityTypeName(finalTarget))
        local finalDestination = world.entityPosition(finalTarget)
        renderShot(mcontroller.position(), finalDestination, {
          power = calculateFinalDamage(splitShot and not isFinal),
          damageType = "IgnoresDef",
          statusEffects = #statfx > 0 and statfx or nil
        }, true)
      
      elseif isFinal or not canSplitShot() then
        -- sb.logInfo("Failed to find a target.")
        renderFinalDamage(mcontroller.position(), calculateFinalDamage(), {
          power = calculateFinalDamage(splitShot and not isFinal),
          damageType = "IgnoresDef",
          statusEffects = #statfx > 0 and statfx or nil
        })
      end
    end

  else
    animator.playSound("drop")
    animator.burstParticleEmitter("deathPoof")
  end
end

function calculateFinalDamage(splitShot, baseDamage)
  baseDamage = baseDamage or self.baseDamage

  -- splitshot
  if splitShot then
    self.multipliers.splitShotDamageMult = self.splitShotParameters.damageMult
  end

  -- airtime score
  self.multipliers.airTimeScoreDamageMult = 1 + self.airTimeScore * self.airTimeScoreMult

  local finalMultiplier = 1
  for name, mult in pairs(self.multipliers) do
    finalMultiplier = finalMultiplier * mult
  end
  return baseDamage * finalMultiplier
end

function renderShot(origin, destination, projectileParams, damageEntity)
  
  local length = world.magnitude(destination, origin)
  local vector = damageEntity and world.distance(destination, origin) or world.distance(origin, destination)
  local primaryParameters = {
    length = length*8,
    -- initialVelocity = vec2.mul(vec2.norm(vector), 0.01),
    initialVelocity = {0.001, 0}
  }

  local particleParameters = {
    type = "streak",
    color = {255, 255, 200},
    light = {25, 25, 20},
    approach = {0, 0},
    timeToLive = 0,
    layer = "back",
    destructionAction = "shrink",
    destructionTime = 1,
    fade=0.1,
    size = 1,
    rotate = true,
    fullbright = true,
    collidesForeground = false,
    variance = {
      length = 0,
    }
  }

  particleParameters = sb.jsonMerge(particleParameters, primaryParameters)

  local defaultProjectileParams = {
    power=0,
    speed=0,
    piercing = true,
    periodicActions = {{
      time = 0,
      ["repeat"] = false,
      rotate=true,
      action = "particle",
      specification = particleParameters
    }}
  }
  local projectileParams = projectileParams or {}

  local finalParams = sb.jsonMerge(defaultProjectileParams, projectileParams)

  world.spawnProjectile(
    finalParams.power > 0 and "project45-ultracoinhit" or "project45_invisiblesummon",
    damageEntity and destination or origin,
    self.ownerEntityId,
    vector,
    false,
    finalParams
  )

end

function renderFinalDamage(position, damage, projectileParams)
  if not damage then return end
  if damage <= 0 then return end
  local finalDamageParticle = {
    type = "text",
    text= "^shadow;" .. math.floor(damage),
    color = {255, 200, 0},
    initialVelocity={0.0, 15.0},
    finalVelocity={0.0, -15},
    approach={3, 30},
    angularVelocity=20,
    size = 1,
    timeToLive=0.7,
    fullbright = true,
    flippable = false,
    destructionAction="shrink",
    destructionTime=0.5,
    layer = "front",
    variance={
      initialVelocity={9.0, 3.0}
    },
  }

  local defaultProjectileParams = {
    power=damage,
    speed=0,
    piercing = true,
    periodicActions = {{
      time = 0,
      ["repeat"] = false,
      rotate=true,
      action = "particle",
      specification = finalDamageParticle
    }}
  }
  local projectileParams = projectileParams or {}

  local finalParams = sb.jsonMerge(defaultProjectileParams, projectileParams)

  world.spawnProjectile(
    "project45-ultracoinhit",
    position,
    self.ownerEntityId,
    {1, 0},
    false,
    finalParams
  )

end