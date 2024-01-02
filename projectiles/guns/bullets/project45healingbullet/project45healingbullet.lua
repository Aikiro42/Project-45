require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/project45/project45util.lua"

function hit(entityId)
	if world.entityExists(entityId) then
		local actions = projectile.getParameter("entityHitActions")
		local chance = projectile.getParameter("entityHitActionChance")
		if project45util.diceroll(chance) then
			for _, action in ipairs(actions) do
				projectile.processAction(action)
			end
		end
		projectile.die()
	end
end