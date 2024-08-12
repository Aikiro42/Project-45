require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()

  self.spawnTime = config.getParameter("spawnTime", 1.5)
  self.spawnRadius = config.getParameter("spawnRadius", 10)

  self.npcCount = config.getParameter("npcCount", 10)
  self.npcLevel = config.getParameter("npcLevel", 1)
  self.npcTypes = config.getParameter("npcTypes", {"outlawsoldier", "bandit", "cultist"})
  self.npcRaces = config.getParameter("npcRaces", {"human", "apex", "hylotl"})
  self.npcOverrides = config.getParameter("npcOverrides", {})
  
  self.npcOverrides = sb.jsonMerge(self.npcOverrides, {
    dropPools = {"project45-enemy-drop"}
  })
  self.spawnTimer = self.spawnTime
end

function update(dt)
  if mcontroller.onGround() then
    if self.spawnTimer > 0 then
      self.spawnTimer = self.spawnTimer - dt
    elseif self.npcCount > 0 then
      if not atEntityCap() then
        spawnEnemy()
        self.npcCount = self.npcCount - 1
        self.spawnTimer = self.spawnTime
      end
    end
  end
end

function atEntityCap(entityCap)
  entityCap = entityCap or 25
  local entities = world.entityQuery(mcontroller.position(), self.spawnRadius, {
    withoutEntityId = entity.id()
  })
  -- sb.logInfo("Entity count: " .. #entities)
  -- sb.logInfo(sb.printJson(entities, 1))
  return #entities >= entityCap
end

function spawnEnemy(position, spawnPointCount)
  determineSpawnPoints(position, spawnPointCount)
  -- do not spawn if no valid spawn point
  if #self.spawnPositions == 0 then return end
  local spawnPosition = util.randomFromList(self.spawnPositions)
  local chosenType = self.npcTypes[math.ceil(math.random() * #self.npcTypes)]
  local chosenRace = self.npcRaces[math.ceil(math.random() * #self.npcRaces)]
  local spawned = world.spawnNpc(spawnPosition, chosenRace, chosenType, self.npcLevel, nil, self.npcOverrides)
end

function determineSpawnPoints(position, spawnPointCount)
  
  position = position or mcontroller.position()
  if self.lastBaseSpawnPos then
    if self.lastBaseSpawnPos[1] == position[1]
    and self.lastBaseSpawnPos[2] == position[2]
    then return end
  end
  self.lastBaseSpawnPos = position
  
  local humanoidCollisionPoly = {{-0.75,-2},{-0.35,-2.5},{0.35,-2.5},{0.75,-2},{0.75,0.65},{0.35,1.22},{-0.35,1.22},{-0.75,0.65}}
  
  spawnPointCount = spawnPointCount or 3
  self.spawnPositions = {nil}
  
  for i=1, spawnPointCount do
    -- take random point within horizontal radius
    local point = vec2.add(mcontroller.position(), {sb.nrand(self.spawnRadius, 0), 0})

    -- detect collision downwards
    local ground = world.lineCollision(vec2.add(point, {0, 50}), point, {"Block", "Dynamic"})

    -- attempt to resolve poly collision
    local viable =
      world.resolvePolyCollision(
        humanoidCollisionPoly,
        ground or point,
        math.max(5, self.spawnRadius),
        {"Block", "Dynamic"}
      )
      or ground
      or point

      -- do not add point if still collides
    if not world.polyCollision(humanoidCollisionPoly, viable, {"Block", "Dynamic"}) then
      table.insert(self.spawnPositions, viable)
    end
    
  end

end
