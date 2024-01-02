require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	mcontroller.setVelocity(vec2.mul(mcontroller.velocity(), sb.nrand(0.1, 1)))
  self.targetSpeed = config.getParameter("targetSpeed") or vec2.mag(mcontroller.velocity())
  self.searchDistance = config.getParameter("searchRadius")
  --Checking which type of homing code to use
  self.homingStyle = config.getParameter("homingStyle", "controlVelocity")
  if self.homingStyle == "controlVelocity" then
		self.controlForce = config.getParameter("baseHomingControlForce") * self.targetSpeed
  elseif self.homingStyle == "rotateToTarget" then
		self.rotationRate = config.getParameter("rotationRate")
		self.trackingLimit = config.getParameter("trackingLimit")
  end

	self.homingEnabled = false
	self.countdownTimer = config.getParameter("homingStartDelay", sb.nrand(0.5, 0.5))
	-- select random target
	local targets = world.entityQuery(
		mcontroller.position(),
		self.searchDistance,
		{
			withoutEntityId = projectile.sourceEntity(),
			includedTypes = {"monster", "npc", "player"},
			order = "random"
		}
	)
	for _, target in ipairs(targets) do
		if world.entityCanDamage(projectile.sourceEntity(), target) then
			self.targetEntityId = target
			break
		end
	end

	self.deathTimer = -1
	self.markedForDeath = false

end

function update(dt)
	
	-- FIXME: am i causing lag??
	if not self.markedForDeath and (
		not (self.targetEntityId and world.entityExists(self.targetEntityId))
		or projectile.collision() or mcontroller.isCollisionStuck() or mcontroller.isColliding()
	) then
		self.markedForDeath = true
		self.deathTimer = sb.nrand(0.1, 0.1)
		return
	end

	if self.markedForDeath then
		self.deathTimer = self.deathTimer - dt
		if self.deathTimer <= 0 then
			projectile.die()
		end
	end


  if self.homingEnabled == true then
		local targetPos = world.entityPosition(self.targetEntityId)
		local myPos = mcontroller.position()
		local dist = world.distance(targetPos, myPos)
		if world.magnitude(targetPos, myPos) < 1 then projectile.die() end
		if self.homingStyle == "controlVelocity" then
			mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
		elseif self.homingStyle == "rotateToTarget" then
			local vel = mcontroller.velocity()
			local angle = vec2.angle(vel)
			local toTargetAngle = util.angleDiff(angle, vec2.angle(dist))
		
			if math.abs(toTargetAngle) > self.trackingLimit then
				return
			end

			local rotateAngle = math.max(dt * -self.rotationRate, math.min(toTargetAngle, dt * self.rotationRate))

			vel = vec2.rotate(vel, rotateAngle)
			mcontroller.setVelocity(vel)
		end
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
