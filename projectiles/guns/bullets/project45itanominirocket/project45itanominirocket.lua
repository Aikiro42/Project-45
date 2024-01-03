require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	mcontroller.setVelocity(vec2.mul(mcontroller.velocity(), sb.nrand(0.1, 1)))
  self.targetSpeed = config.getParameter("targetSpeed") or vec2.mag(mcontroller.velocity())
	self.controlForce = config.getParameter("baseHomingControlForce") * self.targetSpeed
	self.targetEntityId = config.getParameter("targetEntityId")
	self.homingEnabled = false
	self.countdownTimer = config.getParameter("homingStartDelay", sb.nrand(0.1, 0.25))
end

function update(dt)
	
	if not (self.markedForDeath or (self.targetEntityId and world.entityExists(self.targetEntityId))) then
		self.markedForDeath = true
		projectile.setTimeToLive(sb.nrand(0.1, 0.125))
		return
	end

	if projectile.collision() or mcontroller.isCollisionStuck() or mcontroller.isColliding() then
		projectile.die()
	end


  if self.homingEnabled == true and not self.markedForDeath then
		local targetPos = world.entityPosition(self.targetEntityId)
		local myPos = mcontroller.position()
		local dist = world.distance(targetPos, myPos)
		if world.magnitude(targetPos, myPos) < 1 then projectile.die() end
		mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
		return
  else
		self.countdownTimer = math.max(0, self.countdownTimer - dt)
		if self.countdownTimer <= 0 then
			self.homingEnabled = true
		end
  end
  
  --Code for ensuring a constant speed
  if config.getParameter("constantSpeed") == true then
		local currentVelocity = mcontroller.velocity()
		local newVelocity = vec2.mul(vec2.norm(currentVelocity), self.targetSpeed)
		mcontroller.setVelocity(newVelocity)
  end
end
