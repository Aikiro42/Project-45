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
  self.targetRotation = mcontroller.rotation()
  self.angleIncrement = config.getParameter("angularVelocity") or 0
end

function update(dt)
  oldUpdate(dt)

  mcontroller.setRotation(mcontroller.rotation() + util.toRadians((self.angleIncrement * dt)))
  self.angleIncrement = self.angleIncrement - (config.getParameter("angularVelocityDecay") or 0) * dt
  
  if self.targetPosition then
    local toTarget = world.distance(self.targetPosition, mcontroller.position())
    self.targetRotation = vec2.angle(toTarget)
  end

  if projectile.timeToLive() <= 0 then
    mcontroller.setRotation(self.targetRotation)
  end
end


function setTargetPosition(position)
  self.targetPosition = position
end
function uninit()
  oldUninit()
  mcontroller.setRotation(self.targetRotation)
end