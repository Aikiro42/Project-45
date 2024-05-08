require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/project45neoweapon.lua"
require "/scripts/project45/hitscanLib.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45SupplyDrop = WeaponAbility:new()

function Project45SupplyDrop:init()
  
  self.strikeHeight = self.strikeHeight or 50
  self.gravThreshold = self.gravThreshold or 0
  
  self.dropChances = self.dropChances or {
    xssr = 0.02,
    ssr = 0.02,
    sr = 0.46,
    r = 0.5
  }

  self.lockOnTime = self.lockOnTime or 0.2

  self.pity = config.getParameter("pity", 0)
  self.hardPity = self.hardPity or 25
  
  self.tagTimer = 0

end

function Project45SupplyDrop:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function Project45SupplyDrop:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if not self:triggering() then
    self.isFiring = false
  end

  if self:triggering() and not self.isFiring then
    if not self.weapon.currentAbility
    then
      self:setState(self.tagging)
      self.isFiring = true
    else
      animator.playSound("error")
      self.isFiring = true
    end
  end

end

function Project45SupplyDrop:rollDrop()

  local dice = math.random()
  local odds = 0

  if self.pity >= self.hardPity then
    animator.playSound("lockPing")
    self.pity = 0
    odds = 0.5
    if odds <= 0.5 then 
      return "project45supplydropproj-xssr"
    else
      return "project45supplydropproj-ssr"
    end
  end

  for _, rarity in ipairs({"xssr", "ssr", "sr", "r"}) do
    if dice <= odds + self.dropChances[rarity] then
      if rarity == "xssr" or rarity == "ssr" then
        animator.playSound("lockPing")
        self.pity = 0
      else
        self.pity = self.pity + 1
      end
      return "project45supplydropproj-" .. rarity
    end
  end
  return "project45supplydropproj-r"
end

function Project45SupplyDrop:tagging()
  self.tagTimer = 0

  local tagProgress = 0
  local locked = false

  while self:triggering() do
    self.tagTimer = math.min(self.lockOnTime, self.tagTimer + self.dt)
    tagProgress = self.tagTimer / self.lockOnTime

    self.strikeCoords = self:getStrikeCoords()
    
    -- draw visuals
    
    coroutine.yield()
  end

  
  animator.playSound("locked")
  self:fire()
  
  self.tagTimer = -1
  self.isFiring = false

  return
end

function Project45SupplyDrop:fire()
  local hasGrav = world.gravity(self.strikeCoords) > self.gravThreshold
  local noGravY = activeItem.ownerAimPosition()[2]
  local ttl = 3
  local deathHeight = self.strikeCoords[2] + 5
  world.spawnProjectile(
    "project45orbitalstrikewarning",
    self.strikeCoords,
    activeItem.ownerEntityId(),
    {0, 0},
    false,
    {
      power = 0,
      timeToLive = ttl
    }
  )

  local launcherSpawnPoint = vec2.add(self.strikeCoords, {0, self.strikeHeight})
  if not hasGrav then
    launcherSpawnPoint[2] = noGravY
  end
  world.spawnProjectile(
    "project45supplydroplauncher",
    launcherSpawnPoint,
    activeItem.ownerEntityId(),
    {0, hasGrav and -1 or 1},
    false,
    {
      power = 0,
      timeToLive = ttl,
      periodicProjectile = {
        frequency = 0,
        deviation = 0,
        projectileType = self:rollDrop(),
        projectileParameters = {
          power = 0,
          deathHeight=deathHeight
        }
      }
    }
  )
    
end

function Project45SupplyDrop:uninit()
  activeItem.setInstanceValue("pity", self.pity)
end

function Project45SupplyDrop:getStrikeCoords()

  local scanOrig = activeItem.ownerAimPosition()
  local scanDest = vec2.add(scanOrig, {0, -self.strikeHeight})
  local strikeCoords = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
  
  if world.gravity(strikeCoords) <= self.gravThreshold then
    strikeCoords = activeItem.ownerAimPosition()
  end
  
  activeItem.setScriptedAnimationParameter("strikeCoordY", strikeCoords[2])
  return strikeCoords

end