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
  self.hardPity = self.hardPity or 5

  self.pullEssenceCost = self.pullEssenceCost or 450

  self.pity = math.min(config.getParameter("pity", 0), self.hardPity)
  self.pulls = config.getParameter("pulls", 10)
  self.guarantee = config.getParameter("guarantee", 1)
  
  self.nextDrop = config.getParameter("nextDrop")
  if not self.nextDrop then
    self.nextDrop = self:rollDrop()
  end

  self.laserColors = {}
  self.laserColors["project45supplydropproj-xssr"] = {255, 255, 255}
  self.laserColors["project45supplydropproj-ssr"] = {226, 195, 68}
  self.laserColors["project45supplydropproj-sr"] = {164, 81, 196}
  self.laserColors["project45supplydropproj-r"] = {85, 136, 212}
  
  self.gradientColors = {}
  self.gradientColors["project45supplydropproj-xssr"] = {217, 58, 58, 64}
  self.gradientColors["project45supplydropproj-ssr"] = {226, 195, 68, 64}
  self.gradientColors["project45supplydropproj-sr"] = {164, 81, 196, 64}
  self.gradientColors["project45supplydropproj-r"] = {85, 136, 212, 64}

  self.groundParticles = {}
  self.groundParticles["project45supplydropproj-xssr"] = {"project45gacharisexssr-1", "project45gacharisexssr-2"}
  self.groundParticles["project45supplydropproj-ssr"] = {"project45gacharisessr"}
  self.groundParticles["project45supplydropproj-sr"] = {"project45gacharisesr"}
  self.groundParticles["project45supplydropproj-r"] = {"project45gachariser"}

  self.infoSide = activeItem.hand() == "primary" and "L" or "R"

  self.tagTimer = 0

  self.soundMode = 0

  self.laserFlashTime = self.laserFlashTime or 0.01
  self.laserFlashTimer = self.laserFlashTime
  
  self:setStance({
    armRotation = util.toRadians(-90),
    allowFlip = true,
    allowRotate = false
  })

end

function Project45SupplyDrop:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function Project45SupplyDrop:canPull()
  return self.pulls > 0 or player.currency("essence") > self.pullEssenceCost
end

function Project45SupplyDrop:consumePull()
  if self.pulls > 0 then
    self.pulls = self.pulls - 1
  elseif player.currency("essence") > self.pullEssenceCost then
    player.consumeCurrency("essence", self.pullEssenceCost)
  end
end

function Project45SupplyDrop:updateUI()
  world.sendEntityMessage(activeItem.ownerEntityId(), "initProject45UI" .. self.infoSide, {
    modSettings = {},
    uiElementOffset = activeItem.hand() == "primary" and {-2, 0} or {2, 0},
  })

  local aimPosition = world.distance(activeItem.ownerAimPosition(), mcontroller.position())
  world.sendEntityMessage(activeItem.ownerEntityId(), "updateProject45UI" .. self.infoSide, {
    aimPosition = aimPosition,
    uiPosition = aimPosition,
    currentAmmo = ((self.hardPity - self.pity + 1) % (self.hardPity + 1)),
    stockAmmo = self.pulls > 0 and self.pulls or math.floor(player.currency("essence") / self.pullEssenceCost),
    reloadRating = not self:canPull() and "BAD" or (self.guarantee == 1 and "PERFECT" or "GOOD"),
    chamberState = "pity"
  })
end

function Project45SupplyDrop:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self:updateStance()
  self:updateUI()

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
    and self:canPull()
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
  -- sb.logInfo("is guarantee? " .. self.guarantee)  
  local dice = math.random()
  if self.pity >= self.hardPity then
    self.pity = 0
    if self.guarantee == 1 then
      self.guarantee = 0
      -- sb.logInfo("Get guaranteed XSSR")
      return "project45supplydropproj-xssr"
    else
      if dice <= 0.5 then
        -- sb.logInfo("Won 50/50 @ pity!")
        return "project45supplydropproj-xssr"
      else
        self.guarantee = 1
        -- sb.logInfo("Lost 50/50 @ pity...")
        return "project45supplydropproj-ssr"
      end
    end
  end
  
  local odds = 0
  self.pity = self.pity + 1
  for _, rarity in ipairs({"xssr", "ssr", "sr", "r"}) do
    if dice <= odds + self.dropChances[rarity] then
      if rarity == "xssr" or rarity == "ssr" then
        if self.guarantee == 1 then
          self.guarantee = 0
          -- sb.logInfo("Got guaranteed pre-pity!")
          rarity = "xssr"
        elseif rarity == "ssr" then
          -- sb.logInfo("Lost 50/50 pre-pity...")
          self.guarantee = 1
        end
        self.pity = 0
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
  self:setStance({
    armRotation = 0,
    allowFlip = true,
    allowRotate = true
  })
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
      self.groundParticles[self.nextDrop],
      tagProgress * 16
    )
    
    coroutine.yield()
  end
  self:setStance({
    armRotation = util.toRadians(-90),
    allowFlip = true,
    allowRotate = false
  })

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

function Project45SupplyDrop:updateStance()
  self.stance = self.stance or {}
  self.stance.armRotation = self.stance.armRotation or 0
  self.stance.weaponRotation = self.stance.weaponRotation or 0
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())

  activeItem.setArmAngle(self.stance.allowRotate and aimAngle or 0 + self.stance.armRotation)
  activeItem.setFacingDirection(self.stance.allowFlip and aimDirection or 1)

end
function Project45SupplyDrop:setStance(stance)
  self.stance = stance
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
  activeItem.setInstanceValue("guarantee", self.guarantee)
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

function Project45SupplyDrop:drawLaser(coords, color, gradientColor, groundParticles, gradientWidth)
  if not coords
  or not self.renderLaser
  then self:clearLaser() return end
  activeItem.setScriptedAnimationParameter("dropLaserStart", vec2.add(coords, {0, self.strikeHeight}))
  activeItem.setScriptedAnimationParameter("dropLaserEnd", coords)
  activeItem.setScriptedAnimationParameter("dropLaserColor", color or {255, 0, 0})
  activeItem.setScriptedAnimationParameter("dropGroundParticles", groundParticles)
  activeItem.setScriptedAnimationParameter("dropGradientColor", gradientColor or {255, 128, 0, 64})
  activeItem.setScriptedAnimationParameter("dropGradientWidth", gradientWidth or 16)
end