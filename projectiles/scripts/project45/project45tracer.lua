---@diagnostic disable: lowercase-global
require '/scripts/vec2.lua'
require '/scripts/project45/project45util.lua'

local oldInit = init or function() end
local oldUpdate = update or function(dt) end
local oldHit = hit or function(entityId) end
local oldUninit = uninit or function() end

--[[

For best results, use me with the projectile's physics set to "project45projectile"

See '/projectiles/physics.config.patch' for more info.

--]]

function init()
  oldInit()
  self.tracerParameters = sb.jsonMerge({
    color={255,255,255},
    -- light={25,25,0},
    -- fullbright=true,
    timeToLive=0.2,
    width=1
  },
  config.getParameter("tracerParameters", {}))
  self.prevPosition = mcontroller.position()
  self.punchThrough = config.getParameter("punchThrough", 0)
  -- project45util.printObject(_ENV)
  -- chat.addMessage("bitch")
end

function update(dt)
  oldUpdate(dt)
  renderStreak(self.prevPosition, mcontroller.position(), self.tracerParameters.useProjectile)
  self.prevPosition = mcontroller.position()
  
  if projectile.collision() or mcontroller.isCollisionStuck() or mcontroller.isColliding() then
	  projectile.die()
  end

end

function hit(entityId)
  oldHit(entityId)
  self.punchThrough = self.punchThrough - 1
  -- if self.punchThrough < 0 then
  if false then
    projectile.die()
  end
end

function uninit()
  renderStreak(self.prevPosition, mcontroller.position(), true)
  oldUninit()
end

function renderStreak(origin, destination, useProjectile)
  origin = origin or {0, 0}
  destination = destination or {0, 0}

  local length = world.magnitude(destination, origin)
  local vector = world.distance(origin, destination)
  local primaryParameters = {
    length = length*8,
    initialVelocity = {0.001, 0}
  }

  local particleParameters = {
    type = "streak",
    color = self.tracerParameters.color,
    light = self.tracerParameters.light,
    approach = {0, 0},
    timeToLive = 0,
    layer = "back",
    destructionAction = "shrink",
    destructionTime = self.tracerParameters.timeToLive,
    fade=0.1,
    size = self.tracerParameters.width,
    rotate = true,
    fullbright = self.tracerParameters.fullbright,
    collidesForeground = false,
    variance = {
      length = 0,
    }
  }

  particleParameters = sb.jsonMerge(particleParameters, primaryParameters)

  if useProjectile then
    local projectileParams = {
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

    world.spawnProjectile(
      "project45_invisiblesummon",
      origin,
      nil,
      vector,
      false,
      projectileParams
    )
  else
    projectile.processAction({
      time = 0,
      ["repeat"] = false,
      rotate=true,
      action = "particle",
      specification = particleParameters
    })  
  end
  --]]
end