require "/scripts/vec2.lua"

function init()
    self.deathHeight = config.getParameter("deathHeight")
    self.collisionActions = config.getParameter("actionOnCollision", {})
end

function update(dt)
    if not self.deathHeight or mcontroller.position()[2] <= self.deathHeight or self.collisionCount == 0 then
        projectile.die()
    elseif world.pointCollision(mcontroller.position(), {"Block", "Dynamic"}) then
        for _, action in ipairs(self.collisionActions) do
            projectile.processAction(action)
        end
    end
end