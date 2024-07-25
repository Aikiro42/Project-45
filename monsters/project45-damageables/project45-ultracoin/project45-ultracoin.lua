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
  self.finalDamageMult = config.getParameter("finalDamageMult", 1)
  self.groundedDamageMult = config.getParameter("groundedDamageMult", 1)

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

  self.grounded = mcontroller.groundMovement()

  -- die when hitting ground or out of TTL
  -- if (self.freezeTimer < 0 and mcontroller.onGround()) or self.timeToLive <= 0 then
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
    self.fallingAirFriction = self.fallingAirFriction + self.fallControlParameters.deltas.airFriction * dt
    mcontroller.controlParameters({
      airFriction = math.min(self.maxAirFriction, self.fallingAirFriction)
    })
  end

  -- deplete TTL, pause if frozen
  if self.freezeTimer < 0 then
    self.timeToLive = self.timeToLive - (dt * (grounded and 4 or 1))
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
  if self.grounded then
    if not self.landed then
      self.landed = true
      animator.playSound("drop")
      -- status.setPersistentEffects("invulnerable", {{stat = "invulnerable", amount = 1}})
    end
    animator.resetTransformationGroup("body")
  else
    if self.landed then
      self.landed = false
      -- status.clearPersistentEffects("invulnerable")
    end
    animator.rotateTransformationGroup("body", self.angularVelocity)
  end
  
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
    if not self.grounded and coinTarget and world.entityExists(coinTarget) then
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
      local statfx = self.rootDamageRequest.statusEffects
      if finalTarget and world.entityExists(finalTarget) then
        self.finalTarget = finalTarget
        -- sb.logInfo("Final Target: " .. world.entityTypeName(finalTarget))
        local finalDestination = world.entityPosition(finalTarget)
        renderShot(mcontroller.position(), finalDestination, {
          power = calculateFinalDamage(splitShot and not isFinal),
          damageType = "IgnoresDef",
          statusEffects = #statfx > 0 and statfx or nil
        })
      
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

function calculateFinalDamage(splitShot)
  return self.baseDamage * (self.grounded and self.groundedDamageMult or self.finalDamageMult) * (splitShot and self.splitShotParameters.damageMult or 1)
end

function renderShot(origin, destination, projectileParams)

  local length = world.magnitude(destination, origin)
  local vector = world.distance(destination, origin)
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
    destination,
    self.ownerEntityId,
    vector,
    false,
    finalParams
  )

end

function renderFinalDamage(position, damage, projectileParams)
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