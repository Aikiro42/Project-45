---@diagnostic disable: lowercase-global
require '/scripts/vec2.lua'
require "/scripts/util.lua"
require '/scripts/project45/project45util.lua'

local oldInit = init or function() end
local oldUpdate = update or function(dt) end
local oldHit = hit or function(entityId) end
local oldUninit = uninit or function() end

function init()
  oldInit()
  local currentVelocity = mcontroller.velocity()
  
  self.initialSpeed = vec2.mag(currentVelocity)
  self.velocityVector = vec2.norm(currentVelocity)
  self.approach = 1
  self.targetSpeed = config.getParameter("targetSpeed", 13)
  
  self.range = config.getParameter("boltRange", 25)
  self.sourceEntity = projectile.sourceEntity()
  self.boltCooldown = config.getParameter("boltTime", 0.1)
  self.boltCooldownTimer = 0
  self.speedProgress = 0
end

function update(dt)
  oldUpdate(dt)

  -- update speed
  self.speedProgress = math.min(1, self.speedProgress + dt * self.approach)
  mcontroller.setVelocity(vec2.mul(
    self.velocityVector, self.initialSpeed + ((self.targetSpeed - self.initialSpeed) * self.speedProgress)
  ))

  -- damage nearby enemies
  if self.boltCooldownTimer <= 0 then
    self.boltCooldownTimer = self.boltCooldown
    local potentialTargets = world.entityQuery(mcontroller.position(), self.range, {
      order = "nearest",
      withoutEntityId=self.sourceEntity,
      includedTypes = {"creature"},
    })

    -- get targets around the projectile
    local targets = {}
    for _, potentialTargetId in ipairs(potentialTargets) do
      if world.entityExists(potentialTargetId) then
        if world.entityCanDamage(self.sourceEntity, potentialTargetId) then
          table.insert(targets, potentialTargetId)
        end
      end
    end
    
    -- hit the targets
    for _, id in ipairs(targets) do
      if world.entityExists(id) then
        damageEntity(id, #targets)
        local lightningSegments = 5
        local lightning = project45util.drawLightning(
          lightningSegments,
          mcontroller.position(),
          world.entityPosition(id),
          1
        )
        for i=1, lightningSegments do
          renderBeam(lightning[i][1], lightning[i][2])
        end
      end
    end

  else
    self.boltCooldownTimer = self.boltCooldownTimer - dt
  end

end

function damageEntity(entityId, count)
  count = count or 1
  world.sendEntityMessage(
    entityId,
    "applyStatusEffect",
    "project45bfgboltdamage",
    projectile.power() / (math.max(1, count) * 2),
    self.sourceEntity
  )
  world.sendEntityMessage(
    entityId,
    "applyStatusEffect",
    "l6doomed"
  )
  --[[
  local statEffectInherit = config.getParameter("statusEffects", {})
  if #statEffectInherit > 0 then
    for _, effect in ipairs(statEffectInherit) do
      world.sendEntityMessage(
        entityId,
        "applyStatusEffect",
        effect
      )
    end
  end
  ]]
end

function renderBeam(origin, destination)
  origin = origin or {0, 0}
  destination = destination or {0, 0}

  local length = world.magnitude(destination, origin)
  local vector = world.distance(origin, destination)
  local primaryParameters = {
    length = length*8,
    initialVelocity = {0.01, 0}
  }
  local s = 5
  local pactions = {}
  for _, color in ipairs({{81, 189, 59}, {255, 255, 255}}) do
    local particleParameters = {
      type = "streak",
      color = color,
      light = {25, 25, 25},
      approach = {0, 0},
      timeToLive = 0,
      layer = "back",
      destructionAction = "shrink",
      destructionTime = 0.25,
      fade=0.3,
      size = s,
      rotate = true,
      fullbright = true,
      collidesForeground = false,
      variance = {
        length = 0,
      }
    }
    s = s * 0.5

    particleParameters = sb.jsonMerge(particleParameters, primaryParameters)

    table.insert(pactions, {
        time = 0,
        ["repeat"] = false,
        rotate=true,
        action = "particle",
        specification = particleParameters
      })
  end
  
  local projectileParams = {
    power=0,
    speed=0,
    piercing = true,
    periodicActions = pactions
  }

  world.spawnProjectile(
    "project45_invisiblesummon",
    origin,
    nil,
    vector,
    false,
    projectileParams
  )
  
end

function uninit()
  oldUninit()
end