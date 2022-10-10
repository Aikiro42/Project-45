require "/scripts/util.lua"
require "/scripts/interp.lua"


-- Base gun fire ability
Project45GunFire = WeaponAbility:new()

local projectileStack = {}
local fireModeHeld = false
local laserPlayed = false
local isCoolingDown = false

function Project45GunFire:init()
  self.weapon:setStance(self.stances.idle)
  self.cooldownTimer = self.fireTime
  self.ammo = 0
  self.noAmmo = true
  self.shotsBeforecrit = 0
  self.jamScore = 0
  self.inaccuracy = self.runInaccuracy
  self.inputCooldownTimer = 0
  self.shotShakeAmount = self.minShotShakeAmount
  self.critChance = self.runCritChance
  activeItem.setScriptedAnimationParameter("jammed", false)
  activeItem.setScriptedAnimationParameter("reloading", false)
  animator.setAnimationState("firing", "noMag")
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function Project45GunFire:hitscan()
  local scanOrig = self:firePosition()

  -- local armInaccuracy = sb.nrand(self.inaccuracy/2, 0)
  -- local weaponInaccuracy = sb.nrand(self.inaccuracy/2, 0)
  
  -- self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + armInaccuracy
  -- self.weapon.relativeWeaponRotation = self.weapon.relativeArmRotation + weaponInaccuracy
  
  local scanDest = vec2.add(scanOrig, vec2.mul(vec2.rotate(self:aimVector(self.inaccuracy),(self.weapon.relativeArmRotation + self.weapon.relativeWeaponRotation) * mcontroller.facingDirection()), self.range))
  scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest

  -- hitreg
  local hitId = world.entityLineQuery(scanOrig, scanDest, {
    withoutEntityId = entity.id(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })
  local eid = nil
  if #hitId > 0 then
    for i, id in ipairs(hitId) do
      if world.entityCanDamage(entity.id(), id) then

        local aimAngle = vec2.angle(world.distance(scanDest, scanOrig))
        local entityAngle = vec2.angle(world.distance(world.entityPosition(id), scanOrig))
        local rotation = aimAngle - entityAngle
        
        scanDest = vec2.rotate(world.distance(world.entityPosition(id), scanOrig), rotation)
        scanDest = vec2.add(scanDest, scanOrig)

        eid = id

        break
      end      
    end
  end
  
  world.debugLine(scanOrig, scanDest, {255,0,255})

  return {scanOrig, scanDest, eid}
end

function Project45GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  -- self.weapon:updateAim()
  -- update projectile stack
  for i, projectile in ipairs(projectileStack) do
    projectileStack[i].lifetime = projectileStack[i].lifetime - dt
    if projectileStack[i].lifetime <= 0 then
      table.remove(projectileStack, i)
    end
  end
  
  local laserLine = {nil, nil}
  if not isCoolingDown and shiftHeld then
    laserLine = self:hitscan()
  end
  activeItem.setScriptedAnimationParameter("laserOrig", laserLine[1])
  activeItem.setScriptedAnimationParameter("laserDest", laserLine[2])

  self.inputCooldownTimer = math.max(0, self.inputCooldownTimer - self.dt)

  activeItem.setScriptedAnimationParameter("projectileStack", projectileStack)
  activeItem.setScriptedAnimationParameter("ammoLeft", self.ammo)
  activeItem.setScriptedAnimationParameter("jamScore", self.jamScore)
  activeItem.setScriptedAnimationParameter("jammed", self.jamScore > 0)
  activeItem.setScriptedAnimationParameter("inputCooldownTimer", self.inputCooldownTimer)
  
  self.shotShakeAmount = math.max(self.minShotShakeAmount, self.shotShakeAmount - self.dt*self.shotShakeDecayPerSecond)
  
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if shiftHeld then
    activeItem.setCursor("/cursors/project45reticle.cursor")
    self.inaccuracy = 0
    self.critChance = self.walkCritChance
    self.critMult = self.walkCritMult
    if not laserPlayed then 
      playSound("laser", 0.025)
      laserPlayed = true
    end
  else
    activeItem.setCursor("/cursors/project45reticlerun.cursor")
    self.inaccuracy = self.runInaccuracy
    self.critChance = self.runCritChance
    self.critMult = self.runCritMult
    animator.stopAllSounds("laser")
    laserPlayed = false
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0 then
    -- and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.jamScore == 0 then
      if self.ammo > 0 then
        if self:calculateJam(self.misfireChance, "misfire") then
          self:setState(self.cooldown)
        else
          if self.fireType == "auto" then
            self:setState(self.auto)
          elseif self.fireType == "burst" then
            self:setState(self.burst)
          end
        end
      elseif self.inputCooldownTimer > 0 then
        playSound("click")
        self.inputCooldownTimer = self.fireTime + 2*self.dt
        self.cooldownTimer = self.fireTime
      elseif not status.resourceLocked("energy") and self.inputCooldownTimer <= 0 then
        self:setState(self.reload)
      else
        playSound("click")
        self.cooldownTimer = self.fireTime
      end
    else
      self:setState(self.unjam)
    end
  end
end

function Project45GunFire:auto()
  
  self:fireProjectile()
  self:muzzleFlash()
  if self.autoReload then
    if self.ammo <= 0 and self.jamScore <= 0 and not status.resourceLocked("energy") then
      self:setState(self.reload)
    elseif status.resourceLocked("energy") then
      animator.setAnimationState("firing", "noMagUnracked")
    end
  else
    self.weapon:setStance(self.stances.fire)
    if self.stances.fire.duration then
      util.wait(self.stances.fire.duration)
    end

    self.cooldownTimer = self.fireTime
    self:setState(self.cooldown)
  end
end

function Project45GunFire:burst()

  local shots = self.burstCount
  while shots > 0 and self.jamScore <= 0 do
    self:fireProjectile()    
    self:muzzleFlash()
    self.weapon:setStance(self.stances.fire)
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    util.wait(self.burstTime)
    
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function Project45GunFire:cooldown()
  isCoolingDown = true
  self.stances.cooldown.duration = self.fireTime
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
  isCoolingDown = false
end

function Project45GunFire:reload()
  status.overConsumeResource("energy", self.magEnergyCostRate*status.resourceMax("energy"))

  self.cooldownTimer = self.fireTime

  self.weapon:setStance(self.stances.reload)
  self.weapon:updateAim()
  if animator.animationState("firing") == "empty" then
    animator.setAnimationState("firing", "noMagUnracked")
  else
    animator.setAnimationState("firing", "noMag")
  end
  animator.burstParticleEmitter("magazine")
  activeItem.setScriptedAnimationParameter("reloading", true)
  playSound("reloadStart", 0.05)

  local reloadTimer = 0
  local perfectReload = false
  local reloadAttempt = 0
  local fireGracePeriod = self.reloadGracePeriod
  activeItem.setScriptedAnimationParameter("barColor", {225,225,225})
  local progress = 0
  while reloadTimer <= self.stances.reload.duration do

    if self.autoReload then
      local from = self.stances.reload.weaponOffset or {0,0}
      local to = self.stances.idle.weaponOffset or {0,0}
      self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

      self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.reload.weaponRotation, self.stances.idle.weaponRotation))
      self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.reload.armRotation, self.stances.idle.armRotation))

      progress = math.min(1.0, progress + (self.dt / self.stances.reload.duration))
    end


    fireGracePeriod = math.max(0, fireGracePeriod - self.dt)

    activeItem.setScriptedAnimationParameter("reloadTimer", reloadTimer)
    activeItem.setScriptedAnimationParameter("reloadTime", self.stances.reload.duration)
    activeItem.setScriptedAnimationParameter("perfectReloadRange", self.perfectReloadRange)

    if reloadAttempt == 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) and fireGracePeriod == 0 then
      fireGracePeriod = self.fireTime
      if reloadTimer > self.perfectReloadRange[1] and reloadTimer < self.perfectReloadRange[2] then
        reloadAttempt = 1
        activeItem.setScriptedAnimationParameter("barColor", {0,255,255})
        break
      else
        reloadAttempt = -1
        playSound("click")
        activeItem.setScriptedAnimationParameter("barColor", {255,0,0})
      end
    end
    reloadTimer = reloadTimer + self.dt
    coroutine.yield()
  end

  self:refillMag()
  self.weapon:setStance(self.stances.idle)
  self.weapon:updateAim()
  animator.setAnimationState("firing", "reload")
  playSound("reloadEnd", 0.05)
  if reloadAttempt == 1 then
    self:screenShake(self.reloadShakeAmount)
    self.jamChance = self.goodReloadJamChance
    playSound("ping", 0.01)
    util.wait(self.stances.reload.duration/4)
  else
    if reloadAttempt == -1 then
      self.jamChance = self.badReloadJamChance
    else
      self.jamChance = self.regularJamChance
    end
    util.wait(self.stances.reload.duration)
  end
  activeItem.setScriptedAnimationParameter("reloading", false)
end

function Project45GunFire:refillMag()
  self.ammo = self.maxAmmo
  self.noAmmo = false
end


function Project45GunFire:unjam()

  if not self.unjamMag then
    animator.burstParticleEmitter("magazine")
    if animator.animationState("firing") == "misfire" then
      animator.setAnimationState("firing", "noMag")
    elseif animator.animationState("firing") == "jammed" then
      animator.setAnimationState("firing", "noMagJammed")
    end
    self.unjamMag = true
  end

  self.cooldownTimer = self.fireTime
  
  self.weapon:setStance(self.stances.unjam)
  self.weapon:updateAim()
  playSound("unjam")
  self.jamScore = math.max(0, self.jamScore - self.unjamPerShot)
  status.overConsumeResource("energy", self.unjamPerShot*status.resourceMax("energy"))
  if self.jamScore == 0 then
    animator.burstParticleEmitter("ejectionPort")
    animator.setAnimationState("firing", "reload")
    self:screenShake(self.unjamShakeAmount)
    playSound("reloadEnd")
    self.jamChance = self.regularJamChance
    self:refillMag()
    self.unjamMag = false
  end

  local progress = 0
  util.wait(self.stances.unjam.duration, function()
    local from = self.stances.unjam.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.unjam.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.unjam.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.unjam.duration))
  end)
  
end

function Project45GunFire:muzzleFlash(lastRound)
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  if self.ammo > 0 then
    animator.setAnimationState("firing", "fire")
  else
    animator.setAnimationState("firing", "empty")
  end
  animator.burstParticleEmitter("muzzleFlash")
  if not self:calculateJam(self.jamChance, "jammed") then
    animator.burstParticleEmitter("ejectionPort")
  end
  animator.setLightActive("muzzleFlash", true)
end

function Project45GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)

  playSound("fire")
  self.ammo = self.ammo - 1

  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0  
  for i = 1, (projectileCount or self.projectileCount) do
    
    local hitReg = self:hitscan()
    
    if hitReg[3] then
      world.sendEntityMessage(hitReg[3], "applyStatusEffect", "project45damage", self:damagePerShot() * activeItem.ownerPowerMultiplier(), entity.id())
    end

    -- vfx
    self:screenShake(self.shotShakeAmount)
    projectileId = world.spawnProjectile(
      "project45_hitexplosion",
      hitReg[2],
      activeItem.ownerEntityId(),
      self:aimVector(),
      false,
      {}
    )

    self.shotShakeAmount = math.min(self.maxShotShakeAmount, self.shotShakeAmount+self.shotShakePerShot)
    local life = 0.5
    table.insert(projectileStack, {
      origin = hitReg[1],
      destination = hitReg[2],
      lifetime = life,
      maxLifetime = life
    })
  end
  animator.setSoundVolume("hollow", 1 - self.ammo/self.maxAmmo, 0)
  playSound("hollow")
  if self.ammo <= 0 then
    playSound("click")
    if not self.autoReload then
      self.inputCooldownTimer = self.fireTime + 2*self.dt
    end
  end
  return projectileId
end

function Project45GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function Project45GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function Project45GunFire:calculateCrit(critChance, critMultiplier)
  math.randomseed(os.time())
  local diceroll = math.random()
  if diceroll <= critChance or self.shotsBeforecrit == self.guaranteedCrit then
    playSound("crit", 0.2)
    self.shotsBeforecrit = 0
    return critMultiplier
  end
  self.shotsBeforecrit = self.shotsBeforecrit + 1
  return 1
end

function Project45GunFire:calculateJam(jamChance, animState)
  local animState = animState or "empty"
  math.randomseed(os.time())
  local diceroll = math.random()
  if diceroll < jamChance then
    animator.setAnimationState("firing", animState)
    playSound("jammed")
    self.jamScore = 1
    return true
  end
  return false
end

function Project45GunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") * self:calculateCrit(self.critChance, self.critMult) / self.projectileCount
end

function Project45GunFire:uninit()
end

function Project45GunFire:screenShake(amount, shakeTime)
  local shake_dir = vec2.mul(self:aimVector(0), -1 * (amount or 0.1))
  local cam = world.spawnProjectile(
    "invisibleprojectile",
    vec2.add(mcontroller.position(), shake_dir),
    0,
    {0, 0},
    false,
    {
      power = 0,
      timeToLive = shakeTime or 0.01,
      damageType = "NoDamage"
    }
  )
  activeItem.setCameraFocusEntity(cam)
end

function playSound(soundName, pitchRange)
  local pitchRange = pitchRange or 0.1
  math.randomseed(os.time())
  animator.setSoundPitch(soundName, 1 - (pitchRange / 2) + pitchRange*math.random(), 0)
  animator.playSound(soundName);
end