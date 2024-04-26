require "/scripts/vec2.lua"

function init()
    self.deathHeight = config.getParameter("deathHeight")
    self.collisionActions = config.getParameter("actionOnCollision", {})
    self.collisionCount = config.getParameter("maxCollisions", 10)
end

function update(dt)
    if not self.deathHeight or mcontroller.position()[2] <= self.deathHeight or self.collisionCount == 0 then
        projectile.die()
    elseif world.pointCollision(mcontroller.position(), {"Block", "Dynamic"}) then
        self.collisionCount = self.collisionCount - 1
        for _, action in ipairs(self.collisionActions) do
            projectile.processAction(action)
        end
        
    end
end