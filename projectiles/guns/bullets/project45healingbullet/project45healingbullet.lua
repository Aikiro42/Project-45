require "/scripts/vec2.lua"
require "/scripts/util.lua"

function hit(entityId)
	if world.entityExists(entityId) then
		local actions = projectile.getParameter("entityHitActions")
		for _, action in ipairs(actions) do
			projectile.processAction(action)
			projectile.die()
		end
	end
end