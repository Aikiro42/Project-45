require "/scripts/vec2.lua"

Project45EnemyRadar = WeaponAbility:new()

function Project45EnemyRadar:init()
  self:reset()
  activeItem.setScriptedAnimationParameter("radius", self.radius)
end

function Project45EnemyRadar:update(dt, fireMode, shiftHeld)
  self:queryEnemies()
end

function Project45EnemyRadar:queryEnemies()
  -- self.radius
  local detectedEntities = world.entityQuery(mcontroller.position(), self.radius, {
    withoutEntityId = entity.id(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })

  local enemyEntities = {}

  if #detectedEntities > 0 then
    for i, id in ipairs(detectedEntities) do
      if world.entityCanDamage(entity.id(), id) -- if player can damage enemy
      -- and world.entityCanDamage(id, activeItem.ownerEntityId())
      then

        local entityAngle = vec2.angle(world.distance(world.entityPosition(id), mcontroller.position()))
        local entityDistance = world.magnitude(world.entityPosition(id), mcontroller.position())
        table.insert(enemyEntities, {
          id=id,
          angle=entityAngle,
          distance=entityDistance,
          canDamageOwner=world.entityCanDamage(id, activeItem.ownerEntityId()),
          aggressive=world.entityAggressive(id)
        })
      end
    end
  end

  activeItem.setScriptedAnimationParameter("enemyEntities", enemyEntities)

end

function Project45EnemyRadar:reset()
end

function Project45EnemyRadar:uninit()

end
