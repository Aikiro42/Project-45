require "/scripts/vec2.lua"

function init()
    self.deathHeight = config.getParameter("deathHeight")
end

function update(dt)
    if not self.deathHeight or mcontroller.position()[2] <= self.deathHeight then
        projectile.die()
    end
end