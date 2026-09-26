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
  self.currentRotation = mcontroller.rotation()
  self.targetRotation = self.currentRotation
  self.commitTime = config.getParameter("commitTime", 0.5)
end

function update(dt)
  oldUpdate(dt)

  self.currentRotation = self.currentRotation + ((self.targetRotation - self.currentRotation) * 0.2)
  mcontroller.setRotation(self.currentRotation)
  
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

function hitscan(vector, distance)
  
  local pos = mcontroller.position()
  --[[
  local targets = world.entityLineQuery(pos, vec2.add(pos, vec2.mul(vector, distance)), {
    order = "nearest",
    withoutEntityId=projectile.sourceEntity()
  })
  --]]
  local posIncrement = vec2.rotate({1.5, 0}, self.targetRotation)
  for _=1, 50 do
    local nextPos = vec2.add(pos, posIncrement)
    local beamEnd = world.pointCollision(nextPos)
    if beamEnd then
      world.spawnProjectile(
        "project45-stdexplosionshockwave",
        pos,
        projectile.sourceEntity(),
        posIncrement,
        false
      )
      break
    end
    world.spawnProjectile(
      "project45_zoltraaksegment",
      pos,
      projectile.sourceEntity(),
      posIncrement,
      false
    )
    pos = nextPos
  end
end


function setTargetPosition(position)
  self.targetPosition = position
end

function uninit()
  oldUninit()
  mcontroller.setRotation(self.targetRotation)
end