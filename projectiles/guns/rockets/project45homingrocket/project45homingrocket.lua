require "/scripts/vec2.lua"

function init()
  self.controlForce = config.getParameter("controlForce")
  self.maxSpeed = config.getParameter("maxSpeed")
  self.findTargetTimer = 60 -- ticks, 1/60 s
end

function update(dt)
  self.findTargetTimer = self.findTargetTimer - 1
  if self.target and world.entityExists(self.target) then
    self.targetPosition = world.entityPosition(self.target)
  else
    if self.findTargetTimer <= 0 then
      findTarget(nil)
      self.findTargetTimer = 60 -- query target every ~1s
    end
  end
  if self.targetPosition then
    mcontroller.applyParameters({
      gravityEnabled = false
    })
    local toTarget = world.distance(self.targetPosition, mcontroller.position())
    toTarget = vec2.norm(toTarget)
    mcontroller.approachVelocity(vec2.mul(toTarget, self.maxSpeed), self.controlForce)
  end
  mcontroller.setRotation(math.atan(mcontroller.velocity()[2], mcontroller.velocity()[1]))
end

function findTarget()

  local targetID = nil
  local targetIDs = world.entityQuery(mcontroller.position(), 100, {
    withoutEntityId=projectile.sourceEntity(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })

  if #targetIDs > 0 then
    targetID = targetIDs[1]
  end

  self.target = targetID
  if self.target then
    self.targetPosition = world.entityPosition(targetID)
  else
    self.targetPosition = nil
  end
end
