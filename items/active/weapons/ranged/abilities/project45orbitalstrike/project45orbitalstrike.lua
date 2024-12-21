require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/project45neoweapon.lua"
require "/scripts/project45/hitscanLib.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45OrbitalStrike = WeaponAbility:new()

function Project45OrbitalStrike:init()
  self.strikeHeight = self.strikeHeight or 50
  self.minimumUsableWorldHeightRatio = self.minimumUsableWorldHeightRatio or (1/6)
  self.minimumUsableHeight = self.minimumUsableHeight or world.size()[2] * self.minimumUsableWorldHeightRatio

  if mcontroller.position()[2] < self.minimumUsableHeight then
    animator.playSound("error")
  end

  activeItem.setScriptedAnimationParameter("strikeHeight", self.strikeHeight)
  
  self.gravThreshold = 0

  self.cooldownTime = self.cooldownTime or 0.1
  self.projectileCount = self.projectileCount or 10
  storage.cooldownTimer = storage.cooldownTimer or self.cooldownTime
  if storage.cooldownTimer > 0 then
    animator.setSoundVolume("loading", 0.4, 0)
    animator.playSound("loading", -1)
  end

  self.spaceProjectileType = self.spaceProjectileType or "project45orbitalstrikespace"
  
  self.laserTick = false
  self.laserTickTime = self.laserTickTime or 0.05
  self.laserTickTimer = self.laserTickTime

  self.orbitalRadius = self.orbitalRadius or 20
  self.orbitalTheta = 0
  self.orbitalOffsets = {
    {0, 0},
    {0, 0},
    {0, 0},
    {0, 0}
  }
  self.orbitalPhases = {0, 0.5*math.pi, math.pi,  1.5*math.pi, 2*math.pi}
  self.orbitSpeedMult = 0.33
  self.orbitalColor = self.orbitalColor or {255, 128, 0}
  self.orbitalColorLocked = self.orbitalColorLocked or {255, 50, 50, 225}
  self.orbitalLaserWidth = self.orbitalLaserWidth or 4

  self.fireTime = self.fireTime or 0.1

  self.lockOnTime = self.lockOnTime or 1
  self.tagTimer = -1
  self.audioMode = 0

end

function Project45OrbitalStrike:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function Project45OrbitalStrike:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if not self:triggering() then
    self.isFiring = false
  end

  storage.cooldownTimer = math.max(0, storage.cooldownTimer - self.dt)

  if storage.cooldownTimer <= 0 and animator.animationState("project45orbitalstrike") ~= "ready" then
    animator.stopAllSounds("loading")
    animator.playSound("ready")
    animator.setAnimationState("project45orbitalstrike", "ready")
  elseif storage.cooldownTimer > 0 and animator.animationState("project45orbitalstrike") ~= "cooldown" then
    animator.playSound("loading", -1)
    animator.setAnimationState("project45orbitalstrike", "cooldown")
  end
  
  if self.tagTimer < 0 then
    if self.audioMode ~= 0 then
      self.audioMode = 0
      animator.stopAllSounds("ping")
      animator.stopAllSounds("lockPing")
    end
  
  elseif self.tagTimer < self.lockOnTime then
    if self.audioMode ~= 1 then
      self.audioMode = 1
      animator.stopAllSounds("lockPing")
      animator.playSound("ping", -1)
    end

  else
    if self.audioMode ~= 2 then
      self.audioMode = 2
      animator.stopAllSounds("ping")
      animator.playSound("lockPing", -1)
    end
  end

  if self:triggering() and not self.isFiring then
    if not self.weapon.currentAbility
    and storage.cooldownTimer == 0
    and status.resource("energy") > 0
    then
      self:setState(self.tagging)    
      self.isFiring = true
    else
      animator.playSound("error")
      self.isFiring = true
    end
  end

end

function Project45OrbitalStrike:validCoords(coords)
  return coords[2] >= self.minimumUsableHeight or world.gravity(coords) <= self.gravThreshold
end

function Project45OrbitalStrike:tagging()
  self.tagTimer = 0

  local tagProgress = 0
  local locked = false
  while self.fireMode == "alt" do
    self.tagTimer = math.min(self.lockOnTime, self.tagTimer + self.dt)
    tagProgress = self.tagTimer / self.lockOnTime

    --[[
    if tagProgress == 1 and not locked then
      animator.playSound("locked")
      locked = true
    end
    --]]
    self.strikeCoords = self:getStrikeCoords()
    
    -- draw visuals
    if self:validCoords(self.strikeCoords) then
      self:drawLaser(self.strikeCoords, 0.5 + tagProgress * self.orbitalRadius * 8, tagProgress >= 1, {255,128,0,64})
      self:drawOrbitalLaser(self.orbitalRadius * (1 - tagProgress), self.orbitalLaserWidth * (1 -tagProgress) + 1, tagProgress * 255)
    else
      self:clearLaser()
      self:clearOrbitalLaser()
    end
    
    coroutine.yield()
  end

  self:clearLaser()
  self:clearOrbitalLaser()
  
  if self.tagTimer >= self.lockOnTime and status.overConsumeResource("energy", self.energyCost)
  and self:validCoords(self.strikeCoords)
  then
    animator.playSound("locked")
    self:fire()
    storage.cooldownTimer = self.cooldownTime
  else
    animator.playSound("error")
  end
  
  self.tagTimer = -1
  self.isFiring = false

  return
end

function Project45OrbitalStrike:fire()
  local hasGrav = world.gravity(self.strikeCoords) > self.gravThreshold
  local noGravY = activeItem.ownerAimPosition()[2]
  local stepx = self.orbitalRadius/self.launcherCount
  for i=0, self.launcherCount do
    -- local randMagnitude = self.orbitalRadius
    -- local x = self.strikeCoords[1] + (-randMagnitude/2 + randMagnitude * math.random())
    local x = self.strikeCoords[1] - self.orbitalRadius/2 + stepx * i
    local y = self.strikeCoords[2] + self.strikeHeight + 100 * math.random()
    local deathHeight = self.strikeCoords[2] + 5
    world.spawnProjectile(
      "project45orbitalstrikewarning",
      {x, self.strikeCoords[2]},
      activeItem.ownerEntityId(),
      {0, 0},
      false,
      {
        timeToLive = self.launcherTimeToLive + 1
      }
    )

    local launcherSpawnPoint = {x, hasGrav and y or noGravY}
    world.spawnProjectile(
      "project45orbitalstrikelauncher",
      launcherSpawnPoint,
      activeItem.ownerEntityId(),
      {0, hasGrav and -1 or 1},
      false,
      {
        timeToLive = self.launcherTimeToLive,
        periodicProjectile = {
          frequency = self.launcherFireTime * (hasGrav and 1 or sb.nrand(0.1, self.launcherFireTime) * 2),
          deviation = hasGrav and self.deviation or util.toRadians(365),
          projectileType = hasGrav and self.projectileType or self.spaceProjectileType,
          projectileParameters = sb.jsonMerge(self.projectileParameters, {power=activeItem.ownerPowerMultiplier() * 120, deathHeight=deathHeight})
        }
      }
    )
    
  end
end

function Project45OrbitalStrike:uninit()
  self:clearLaser()
  self:clearOrbitalLaser()
end

function Project45OrbitalStrike:getStrikeCoords()

  local scanOrig = activeItem.ownerAimPosition()
  local scanDest = vec2.add(scanOrig, {0, -self.strikeHeight})
  local strikeCoords = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest
  
  if world.gravity(strikeCoords) <= self.gravThreshold then
    strikeCoords = activeItem.ownerAimPosition()
  end
  activeItem.setScriptedAnimationParameter("strikeCoordY", strikeCoords[2])
  return strikeCoords
end

function Project45OrbitalStrike:viableStrike(pos)
    return world.lineCollision(
      vec2.add(pos, {0, -1}),
      vec2.add(pos, {0, -8}),
      {"Block", "Dynamic"}
    )
end

function Project45OrbitalStrike:drawLaser(laserDest, laserWidth, laserTick, laserColor)
  self.laserTickTimer = math.max(0, self.laserTickTimer - self.dt)
  if self.laserTickTimer <= 0 then
    self.laserTick = not self.laserTick
    activeItem.setScriptedAnimationParameter("strikeLaserTick", laserTick or self.laserTick)
    self.laserTickTimer = self.laserTickTime
  end

  local laserOrigin = vec2.add(activeItem.ownerAimPosition(), {0, self.strikeHeight})
  local laserDestination = vec2.add(activeItem.ownerAimPosition(), {0, -self.strikeHeight})

  activeItem.setScriptedAnimationParameter("drawStrikeLaser", true)
  activeItem.setScriptedAnimationParameter("strikeLaserWidth", laserWidth or 0.5)
  activeItem.setScriptedAnimationParameter("strikeLaserColor", laserColor or {255, 0, 0})
end

function Project45OrbitalStrike:clearLaser()
  activeItem.setScriptedAnimationParameter("drawStrikeLaser", false)
end

function Project45OrbitalStrike:drawOrbitalLaser(radius, laserWidth, laserAlpha)
  self.orbitalTheta = (self.orbitalTheta + self.orbitSpeedMult/math.pi) % math.pi
  if radius > 0 then
    for i, orbitalPhase in ipairs(self.orbitalPhases) do
      self.orbitalOffsets[i] = {
        radius * math.cos(self.orbitalTheta + orbitalPhase),
        0 * radius * math.sin(self.orbitalTheta + orbitalPhase)
      }
    end
  end

  local orbitalColor = self["orbitalColor" .. (radius == 0 and "Locked" or "")]
  if #orbitalColor < 4 then
    table.insert(orbitalColor, laserAlpha or 255)
  else
    orbitalColor[4] = laserAlpha or 255
  end
  activeItem.setScriptedAnimationParameter("drawOrbitalLaser", true)
  activeItem.setScriptedAnimationParameter("orbitalColor", orbitalColor)
  activeItem.setScriptedAnimationParameter("orbitalOffsets", radius > 0 and self.orbitalOffsets or {{0, 0}})
  activeItem.setScriptedAnimationParameter("orbitalLaserWidth", laserWidth or 0.5)
end

function Project45OrbitalStrike:clearOrbitalLaser()
  activeItem.setScriptedAnimationParameter("drawOrbitalLaser", false)
  activeItem.setScriptedAnimationParameter("orbitalColor", {0, 0, 0, 0})
  activeItem.setScriptedAnimationParameter("orbitalOffsets", {})
  activeItem.setScriptedAnimationParameter("orbitalLaserWidth", 0)
end