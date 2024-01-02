require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.targetSpeed = config.getParameter("targetSpeed") or vec2.mag(mcontroller.velocity())
	self.searchDistance = config.getParameter("searchRadius")
	local targets = world.entityQuery(mcontroller.position(), self.searchDistance, {
		-- withoutEntityId = projectile.sourceEntity(),
		includedTypes = {"player"},
		order = "nearest"
	})
	if #targets >= 1 then
		self.playerTarget = targets[1]
	end
	if not (self.playerTarget and world.entityExists(self.playerTarget)) then
		projectile.die()
	end
  self.controlForce = config.getParameter("baseHomingControlForce") * self.targetSpeed
end

function update(dt)
	if not (self.playerTarget and world.entityExists(self.playerTarget)) then
		projectile.die()
	end
	local targetPos = vec2.add(world.entityPosition(self.playerTarget), {0, -0.375})
	local myPos = mcontroller.position()
	local dist = world.distance(targetPos, myPos)
	if world.magnitude(targetPos, myPos) < 1 then projectile.die() end
	mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
end
