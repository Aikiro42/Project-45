require "/scripts/vec2.lua"

function init()
  self.approach = config.getParameter("approach", vec2.norm(mcontroller.velocity()))

  self.maxSpeed = config.getParameter("maxSpeed")
  self.controlForce = config.getParameter("controlForce")

  self.lifeTimer = config.getParameter("timeToLive", 1)

end

function update(dt)
  projectile.setTimeToLive(1)
  if self.lifeTimer <= 0 then
    local targets = world.entityQuery(
      mcontroller.position(),
      50,
      {
        withoutEntityId = projectile.sourceEntity(),
        includedTypes = {"monster", "npc", "player"}
      }
    )
    local actions = {}
    if #targets > 0 then
      actions = config.getParameter("scriptedActionOnReap")
    else
      actions = config.getParameter("scriptedActionOnReap2")
    end
    for _, action in ipairs(actions) do
      projectile.processAction(action)
    end
    projectile.die()
  end
  self.lifeTimer = self.lifeTimer - dt
  mcontroller.approachVelocity(vec2.mul(self.approach, self.maxSpeed), self.controlForce)
end

function setApproach(approach)
  self.approach = approach
end