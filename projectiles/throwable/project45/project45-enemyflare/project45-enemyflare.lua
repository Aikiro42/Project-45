require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.spawnTime = 3
  self.spawnTimer = self.spawnTime
  self.spawnRadius = 20
  self.npcCount = 1
end

function update(dt)
  if self.spawnTimer > 0 then
    self.spawnTimer = self.spawnTimer - dt
  elseif self.npcCount > 0 then
    spawnEnemy()
    self.npcCount = self.npcCount - 1
    self.spawnTimer = self.spawnTime
  end
end

function spawnEnemy()
  local humanoidCollisionPoly = {{-0.75,-2},{-0.35,-2.5},{0.35,-2.5},{0.75,-2},{0.75,0.65},{0.35,1.22},{-0.35,1.22},{-0.75,0.65}}
  local spawnPosition = vec2.add(mcontroller.position(), {sb.nrand(self.spawnRadius, 0), 0})
  spawnPosition = world.resolvePolyCollision(humanoidCollisionPoly, spawnPosition, math.max(5, self.spawnRadius)) or spawnPosition

  local npcTypes = {"miniknogscout"}
  local chosenType = npcTypes[math.ceil(math.random() * #npcTypes)]

  local spawned = world.spawnNpc(spawnPosition, "apex", chosenType, 6, nil, {
    dropPools = {"project45-enemy-drop"}
  })

  if spawned and world.entityExists(spawned) then
    sb.logInfo("hi")
    world.sendEntityMessage(spawned, "applyStatusEffect", "blinkin")
  end
end
