require "/scripts/util.lua"
require "/scripts/vec2.lua"
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

  self.lockOnTime = self.lockOnTime or 0.5

  self.pity = config.getParameter("pity", 0)
  self.pulls = config.getParameter("pulls", 10)
  self.nextDrop = config.getParameter("nextDrop", self:rollDrop())
  self.hardPity = self.hardPity or 25

  self.laserColors = {}
  self.laserColors["project45supplydropproj-xssr"] = {234, 153, 49}
  self.laserColors["project45supplydropproj-ssr"] = {226, 195, 68}
  self.laserColors["project45supplydropproj-sr"] = {164, 81, 196}
  self.laserColors["project45supplydropproj-r"] = {85, 136, 212}
  
  self.gradientColors = {}
  self.gradientColors["project45supplydropproj-xssr"] = {234, 153, 49, 64}
  self.gradientColors["project45supplydropproj-ssr"] = {226, 195, 68, 64}
  self.gradientColors["project45supplydropproj-sr"] = {164, 81, 196, 64}
  self.gradientColors["project45supplydropproj-r"] = {85, 136, 212, 64}

  self.tagTimer = 0

  self.soundMode = 0

  self.laserFlashTime = self.laserFlashTime or 0.01
  self.laserFlashTimer = self.laserFlashTime
  
  --[[
  self.weapon:setStance({
    armRotation = 0,
    weaponRotation = 0,
    allowFlip = true,
    allowRotate = true
  })
  --]]

end

function Project45SupplyDrop:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function Project45SupplyDrop:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)


  if self.soundMode == 0 then
    animator.stopAllSounds("ping")
    animator.stopAllSounds("lockPing")
  elseif self.soundMode == 1 then
    animator.stopAllSounds("lockPing")
    animator.playSound("ping", -1)
    self.soundMode = 2
  elseif self.soundMode == 3 then
    animator.stopAllSounds("ping")
    animator.playSound("lockPing", -1)
    self.soundMode = 4
  end

  if not self:triggering() then
    self.isFiring = false
  end

  if self:triggering() and not self.isFiring then
    if not self.weapon.currentAbility
    and self.pulls > 0
    and world.type() ~= "unknown"
    then
      self:setState(self.tagging)
    else
      animator.playSound("error")
    end
    self.isFiring = true
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
  
  self.soundMode = 1
  local lockedIn = false
  while self:triggering() do
    self.tagTimer = math.min(self.lockOnTime, self.tagTimer + self.dt)
    tagProgress = self.tagTimer / self.lockOnTime

    if tagProgress >= 1 then
      self.renderLaser = true
      if not lockedIn then
        self.soundMode = 3
        lockedIn = true
      end
    else
      self:updateLaserFlash()
    end

    self.strikeCoords = self:getStrikeCoords()
    
    -- draw visuals
    self:drawLaser(
      self.strikeCoords,
      self.laserColors[self.nextDrop],
      self.gradientColors[self.nextDrop],
      tagProgress * 16
    )
    
    coroutine.yield()
  end

  self:clearLaser()

  self.soundMode = 0

  if tagProgress >= 1 and self.strikeCoords then
    animator.playSound("locked")
    self:fire()
  end
  
  self.tagTimer = -1
  self.isFiring = false

  return
end

function Project45SupplyDrop:updateDrop()
  local currentDrop = self.nextDrop
  self.nextDrop = self:rollDrop()
  return currentDrop
end

function Project45SupplyDrop:updateLaserFlash()
  if self.laserFlashTimer <= 0 then
    self.laserFlashTimer = self.laserFlashTime
    self.renderLaser = not self.renderLaser
  else
    self.laserFlashTimer = self.laserFlashTimer - self.dt
  end
end

function Project45SupplyDrop:consumePull()
  self.pulls = self.pulls - 1
end

function Project45SupplyDrop:fire()
  local hasGrav = world.gravity(self.strikeCoords) > self.gravThreshold
  local noGravY = activeItem.ownerAimPosition()[2]
  local ttl = 0.5
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
        projectileType = self:updateDrop(),
        projectileParameters = {
          power = 0,
          deathHeight=deathHeight
        }
      }
    }
  )
  self:consumePull()
end

function Project45SupplyDrop:uninit()
  activeItem.setInstanceValue("pity", self.pity)
  activeItem.setInstanceValue("pulls", self.pulls)
  activeItem.setInstanceValue("nextDrop", self.nextDrop)
end

function Project45SupplyDrop:getStrikeCoords()
  if world.pointCollision(activeItem.ownerAimPosition()) then return nil end
  local scanOrig = activeItem.ownerAimPosition()
  local scanDest = vec2.add(scanOrig, {0, -self.strikeHeight})
  local strikeCoords = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
  
  if world.gravity(strikeCoords) <= self.gravThreshold then
    strikeCoords = activeItem.ownerAimPosition()
  end
  
  activeItem.setScriptedAnimationParameter("strikeCoordY", strikeCoords[2])
  return strikeCoords

end

function Project45SupplyDrop:clearLaser()
  activeItem.setScriptedAnimationParameter("dropLaserStart", nil)
  activeItem.setScriptedAnimationParameter("dropLaserEnd", nil)
end

function Project45SupplyDrop:drawLaser(coords, color, gradientColor, gradientWidth)
  if not coords
  or not self.renderLaser
  then self:clearLaser() return end
  activeItem.setScriptedAnimationParameter("dropLaserStart", vec2.add(coords, {0, self.strikeHeight}))
  activeItem.setScriptedAnimationParameter("dropLaserEnd", coords)
  activeItem.setScriptedAnimationParameter("dropLaserColor", color or {255, 0, 0})
  activeItem.setScriptedAnimationParameter("dropGradientColor", gradientColor or {255, 128, 0, 64})
  activeItem.setScriptedAnimationParameter("dropGradientWidth", gradientWidth or 16)
end