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
  if self.spawnTimer > 0 then
    self.spawnTimer = self.spawnTimer - dt
    sb.logInfo(self.npcCount)
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
  sb.logInfo(sb.printJson(spawnPosition))
  local chosenType = self.npcTypes[math.ceil(math.random() * #self.npcTypes)]
  local chosenRace = self.npcRaces[math.ceil(math.random() * #self.npcRaces)]

  local spawned = world.spawnNpc(spawnPosition, chosenRace, chosenType, self.npcLevel, nil, self.npcOverrides)

end
