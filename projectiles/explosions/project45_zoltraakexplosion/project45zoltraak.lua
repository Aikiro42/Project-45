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
  self.range = config.getParameter("beamRange", 100)
  self.sourceEntity = projectile.sourceEntity()
  self.currentRotation = mcontroller.rotation()
  self.targetRotation = self.currentRotation
  self.commitTime = config.getParameter("commitTime", 0.5)
end

function update(dt)
  oldUpdate(dt)

  self.currentRotation = self.currentRotation + ((self.targetRotation - self.currentRotation) * 0.2)
  
  mcontroller.setRotation(self.currentRotation)
  world.debugLine(mcontroller.position(), vec2.rotate({1, 0}, mcontroller.rotation()), "cyan")

  if self.targetPosition and self.commitTime > 0 then
    local toTarget = world.distance(self.targetPosition, mcontroller.position())
    self.targetRotation = vec2.angle(toTarget)
    self.commitTime = self.commitTime - dt
  end


  if projectile.timeToLive() <= 0 then
    mcontroller.setRotation(self.targetRotation)
    hitscan()
  end
end

function hitscan()

  -- hitscan until first collision
  
  local pos = mcontroller.position()
  local scanEnd = vec2.add(pos, vec2.rotate({self.range, 0}, self.targetRotation))

  scanEnd = world.lineCollision(pos, scanEnd, {"Block", "Dynamic"}) or scanEnd

  local hitEntityIds = world.entityLineQuery(pos, scanEnd, {
    order = "nearest",
    withoutEntityId=self.sourceEntity,
  })

  -- if entities are hit,
  if #hitEntityIds > 0 then
    -- for each entity hit
    for i, id in ipairs(hitEntityIds) do
      if world.entityCanDamage(self.sourceEntity, id)
      then
        world.sendEntityMessage(
          id,
          "applyStatusEffect",
          "project45zoltraakdamage",
          projectile.power(),
          self.sourceEntity
        )
      end
    end
  end

  renderBeam(pos, scanEnd)

end

function renderBeam(origin, destination)
  origin = origin or {0, 0}
  destination = destination or {0, 0}

  local length = self.range
  local vector = vec2.rotate({1, 0}, self.targetRotation)
  local primaryParameters = {
    length = length*8,
    initialVelocity = {-0.01, 0}
  }
  local s = 20
  local pactions = {}
  for _, color in ipairs({{0, 0, 0}, {133, 182, 255}, {255, 255, 255}}) do
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
    s = s * 0.75

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


function setTargetPosition(position)
  self.targetPosition = position
end

function uninit()
  oldUninit()
  mcontroller.setRotation(self.targetRotation)
end