require "/scripts/vec2.lua"

function init()
	-- grab list of targets
	self.targetList = {}
	local detected = world.entityQuery(
		mcontroller.position(),
		50,
		{
			withoutEntityId = projectile.sourceEntity(),
			includedTypes = {"monster", "npc", "player"},
			order = "random"
		}
	)
	for _, potentialTarget in ipairs(detected) do
		if world.entityCanDamage(projectile.sourceEntity(), potentialTarget) then
			table.insert(self.targetList, potentialTarget)
		end
	end
	
	if #self.targetList == 0 then return end

	local totalProjectiles = 10
	local i = 1
	while totalProjectiles > 0 do
		world.spawnProjectile(
			"project45itanominirocket",
			mcontroller.position(),
			projectile.sourceEntity(),
			vec2.rotate({1, 0}, sb.nrand(0.1, mcontroller.rotation())),
			true,
			{
				power = projectile.power(),
				targetEntityId = self.targetList[i]
			}
		)
		totalProjectiles = totalProjectiles - 1
		i = (i % #self.targetList) + 1
	end

end

function update(dt)
end