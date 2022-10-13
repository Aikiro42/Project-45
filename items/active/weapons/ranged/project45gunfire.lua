require "/scripts/util.lua"
require "/scripts/interp.lua"


-- Base gun fire ability
Project45GunFire = WeaponAbility:new()

local projectileStack = {}
local fireModeHeld = false
local laserPlayed = false
local isCoolingDown = false
local reAimProgress = 0
local cammy = nil
local inputLog = {new = "none", old = "none"}

function Project45GunFire:init()
  self.weapon:setStance(self.stances.aim)
  self.cooldownTimer = self.fireTime
  self.ammo = 0
  self.noAmmo = true
  self.shotsBeforecrit = 0
  self.jamScore = 0
  self.inaccuracy = self.runInaccuracy
  self.shotShakeAmount = self.minShotShakeAmount
  self.critChance = self.runCritChance
  self.muzzleFlashTime = self.muzzleFlashTime or 0.1
  self.muzzleFlashTimer = self.muzzleFlashTime
  self.aiming = true
  self.breechReady = false
  self.punchThrough = self.punchThrough or 0
  activeItem.setScriptedAnimationParameter("jammed", false)
  activeItem.setScriptedAnimationParameter("reloading", false)
  animator.setAnimationState("firing", "noMag")
  
end


function Project45GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  inputLog.old = inputLog.new
  inputLog.new = self.fireMode

  -- sb.logInfo("[PROJECT 45] " .. self.fireMode)

  -- correct aim when not idle
  if self.aiming then
    self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(reAimProgress, math.deg(self.weapon.relativeWeaponRotation), self.stances.aim.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.sin(reAimProgress, math.deg(self.weapon.relativeArmRotation), self.stances.aim.armRotation))
    reAimProgress = math.min(1.0, reAimProgress + (self.dt / (self.acquisitionTime or 1)))
  else
    reAimProgress = 0
  end

  -- update projectile stack
  for i, projectile in ipairs(projectileStack) do
    projectileStack[i].lifetime = projectileStack[i].lifetime - dt
    if projectileStack[i].lifetime <= 0 then
      table.remove(projectileStack, i)
    end
  end
  
  -- update laser
  local laserLine = (shiftHeld and self.ammo > 0) and self:hitscan(true) or {}

  -- timer-conditional actions
  if self.muzzleFlashTimer == 0 then
    animator.setLightActive("muzzleFlash", false)
  end
  
  -- timers and increments
  self.muzzleFlashTimer = math.max(0, self.muzzleFlashTimer - self.dt)
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  self.shotShakeAmount = math.max(self.minShotShakeAmount, self.shotShakeAmount - self.dt*self.shotShakeDecayPerSecond)

  -- animation parameters
  activeItem.setScriptedAnimationParameter("laserOrig", laserLine[1])
  activeItem.setScriptedAnimationParameter("laserDest", laserLine[2])
  activeItem.setScriptedAnimationParameter("projectileStack", projectileStack)
  activeItem.setScriptedAnimationParameter("ammoLeft", self.ammo)
  activeItem.setScriptedAnimationParameter("jamScore", self.jamScore)
  activeItem.setScriptedAnimationParameter("jammed", self.jamScore > 0)
  
  -- conditional actions

  -- walking decreases acquisition time
  -- walking changes critical stats
  -- walking turns on lasers
  if shiftHeld then
    activeItem.setCursor("/cursors/project45reticle.cursor")
    self.acquisitionTime = self.walkAcquisitionTime
    self.critChance = self.walkCritChance
    self.critMult = self.walkCritMult
    if not laserPlayed and self.ammo > 0 then 
      playSound("laser", 0.025)
      laserPlayed = true
    end
  else
    activeItem.setCursor("/cursors/project45reticlerun.cursor")
    self.acquisitionTime = self.runAcquisitionTime
    self.critChance = self.runCritChance
    self.critMult = self.runCritMult
    animator.stopAllSounds("laser")
    laserPlayed = false
  end


  -- ability stuff
  if inputLog.new == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

      if self.jamScore == 0 then
        -- if gun is not jammed
        if self.ammo > 0 then
          -- if gun has ammo
          
          if not self:calculateJam(self.misfireChance, "misfire") then
            -- if the gun didn't misfire
            -- fire the gun
            self:setState(self.firing)
          end

        elseif inputLog.new ~= inputLog.old then
          -- if the gun has no ammo and the fire key has been let go of, reload
          self:setState(self.reload)
        elseif not self.noAmmo then
          -- if the gun has no ammo and the fire key is being held, click once.
          playSound("click")
          self.noAmmo = true
        end
      else
        -- if gun is jammed,
        -- unjam
        self:setState(self.unjam)
      end
  end      
  
end

-- Fires the gun.
function Project45GunFire:firing()

  local isBurst = self.burstCount > 1
  
  if ((self.fireType == "semi" or self.fireType == "boltaction") and self:isFireHeld()) then return end -- don't fire if semi and click is held

  if (self.fireType == "boltaction" and not self.breechReady) then self:setState(self.boltReload) return end

  if not isBurst then -- auto fire
    if not self:calculateJam(self.misfireChance, "misfire") then
      self:fireProjectile()
      self:muzzleFlash()
      if self.fireType ~= "boltaction" then
        self:cockGun()
      else
        self:calculateJam(self.jamChance, "jammed")
      end
      self:applyInaccuracy()
    end
  else
    local shots = self.burstCount
    while shots > 0 and self.jamScore <= 0 and self.ammo > 0 do
        if self:calculateJam(self.misfireChance, "misfire") then break end
        self:fireProjectile()
        self:muzzleFlash()
        self:cockGun()
        self:applyInaccuracy()
        shots = shots - 1
        util.wait(self.burstTime)
    end
  end

  if self.autoReload and self.ammo <= 0 and self.jamScore <= 0 then
    self:setState(self.reload)
  end

  self.cooldownTimer = (self.fireTime - (isBurst and self.burstTime or 0)) * self.burstCount
end

-- Utility function that scans for an entity to damage.
function Project45GunFire:hitscan(isLaser)

  local scanOrig = self:firePosition()

  local scanDest = vec2.add(scanOrig, vec2.mul(vec2.rotate(self:aimVector(isLaser and 0 or self.projectileSpread),(self.weapon.relativeArmRotation + self.weapon.relativeWeaponRotation) * mcontroller.facingDirection()), self.range))
  scanDest = world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest

  -- hitreg
  local hitId = world.entityLineQuery(scanOrig, scanDest, {
    withoutEntityId = entity.id(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })
  local eid = {}
  local pen = 0
  if #hitId > 0 then
    for i, id in ipairs(hitId) do
      if world.entityCanDamage(entity.id(), id) then

        local aimAngle = vec2.angle(world.distance(scanDest, scanOrig))
        local entityAngle = vec2.angle(world.distance(world.entityPosition(id), scanOrig))
        local rotation = aimAngle - entityAngle
        
        scanDest = vec2.rotate(world.distance(world.entityPosition(id), scanOrig), rotation)
        scanDest = vec2.add(scanDest, scanOrig)

        table.insert(eid, id)

        pen = pen + 1

        if pen > self.punchThrough then break end
      end      
    end
  end
  
  world.debugLine(scanOrig, scanDest, {255,0,255})

  return {scanOrig, scanDest, eid}
end

-- Utility function that applies inaccuracy
function Project45GunFire:applyInaccuracy()
  reAimProgress = 0
  local inaccuracy = math.rad(self.recoilDeg)
  self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + inaccuracy
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + inaccuracy
end

function Project45GunFire:boltReload()
  self.aiming = false
  self.weapon:setStance(self.stances.reload)
  animator.setAnimationState("firing", "boltPull")
  playSound("boltPull", 0.05)
  animator.burstParticleEmitter("ejectionPort")
  util.wait(self.fireTime/2)
  self.weapon:setStance(self.stances.reloadEnd)
  animator.setAnimationState("firing", "off")
  playSound("boltPush", 0.05)
  self.breechReady = true
  self.aiming = true
end


function Project45GunFire:reload()
  if status.overConsumeResource("energy", self.magEnergyCostRate*status.resourceMax("energy")) then

    -- begin reload
    self.aiming = self.autoReload
    self.weapon:setStance(self.stances.reload)
    
    if animator.animationState("firing") == "empty" then
      animator.setAnimationState("firing", "noMagUnracked")
    else
      animator.setAnimationState("firing", "noMag")
    end

    if self.fireType == "boltaction" then
      animator.burstParticleEmitter("ejectionPort")
    end
    if animator.animationState("firing") ~= "noMag" then
      animator.burstParticleEmitter("magazine")
    end
    activeItem.setScriptedAnimationParameter("reloading", true)
    playSound("reloadStart", 0.05)
    
    -- timing minigame
    -- |                 |            self.stances.reload.duration       |
    -- [<fireGracePeriod>|              |<perfectReloadRange>|           ]
    local reloadTimer = 0
    local reloadAttempt = 0
    local fireGracePeriod = self.fireTime
    activeItem.setScriptedAnimationParameter("barColor", {225,225,225})
    activeItem.setScriptedAnimationParameter("fireGracePeriod", fireGracePeriod)
    while reloadTimer <= self.stances.reload.duration + fireGracePeriod do

      activeItem.setScriptedAnimationParameter("reloadTimer", reloadTimer)
      activeItem.setScriptedAnimationParameter("reloadTime", self.stances.reload.duration + fireGracePeriod)
      activeItem.setScriptedAnimationParameter("perfectReloadRange", {self.perfectReloadRange[1] + fireGracePeriod, self.perfectReloadRange[2] + fireGracePeriod})

      if reloadAttempt == 0 and inputLog.new == (self.activatingFireMode or self.abilitySlot) and reloadTimer >= fireGracePeriod and inputLog.old ~= inputLog.new then
        if reloadTimer >= self.perfectReloadRange[1] + fireGracePeriod and reloadTimer <= self.perfectReloadRange[2] + fireGracePeriod then
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

    -- end of reload

    self:refillMag()
    self.weapon:setStance(self.stances.reloadEnd)
    animator.setAnimationState("firing", "reload")
    animator.stopAllSounds("reloadStart")
    playSound("reloadEnd", 0.05)
    self.aiming = true
    if reloadAttempt == 1 then
      self:screenShake(self.reloadShakeAmount)
      self.jamChance = self.goodReloadJamChance
      playSound("ping", 0.01)
    else
      self.jamChance = reloadAttempt == -1 and self.badReloadJamChance or self.regularJamChance
    end
    util.wait(self.stances.reloadEnd.duration)
    activeItem.setScriptedAnimationParameter("reloading", false)
  else
    playSound("click")
  end
end

function Project45GunFire:refillMag()
  self.ammo = self.maxAmmo
  self.noAmmo = false
  self.breechReady = true
end

-- Attempts to unjam the gun.
function Project45GunFire:unjam()
  
  if self:isFireHeld() then return end

  if not self.unjamMag then
    animator.burstParticleEmitter("magazine")
    if animator.animationState("firing") == "misfire" then
      animator.setAnimationState("firing", "noMag")
    elseif animator.animationState("firing") == "jammed" then
      animator.setAnimationState("firing", "noMagJammed")
    end
    self.unjamMag = true
  end
  
  -- unjam
  self.weapon:setStance(self.stances.unjam)
  playSound("unjam")
  self.jamScore = math.max(0, self.jamScore - self.unjamPerShot)
  status.overConsumeResource("energy", self.unjamPerShot*status.resourceMax("energy")*self.magEnergyCostRate)

  -- finished unjamming
  if self.jamScore == 0 then
    self.weapon:setStance(self.stances.unjamEnd)
    animator.burstParticleEmitter("ejectionPort")
    animator.setAnimationState("firing", "reload")
    self:screenShake(self.unjamShakeAmount)
    playSound("reloadEnd")
    self.jamChance = self.regularJamChance
    self:refillMag()
    self.unjamMag = false
  end

  reAimProgress = 0


  self.cooldownTimer = self.unjamGrace or 0.25

end

function Project45GunFire:isFireHeld()
  return inputLog.old == (self.activatingFireMode or self.abilitySlot)
end

function Project45GunFire:muzzleFlash()
  playSound("fire")
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.burstParticleEmitter("muzzleFlash")
  animator.setLightActive("muzzleFlash", true)
  animator.setAnimationState("flash", "flash")
  self.muzzleFlashTimer = self.muzzleFlashTime
end

function Project45GunFire:cockGun()
  if self.ammo > 0 or self.autoReload then
    animator.setAnimationState("firing", "fire")
  else
    animator.setAnimationState("firing", "empty")
  end

  if not (self:calculateJam(self.jamChance, "jammed") or self.autoReload) then
    animator.burstParticleEmitter("ejectionPort")
  end

  self.breechReady = true

end

function Project45GunFire:fireProjectile()
  
  reAimProgress = 0

  self.ammo = self.ammo - 1

  -- for each projectile
  for i = 1, self.projectileCount do
    
    -- scan hit down range
    -- hitreg[2] is where the bullet trail terminates,
    -- hitreg[3] is the array of hit entityIds
    local hitReg = self:hitscan()
    
    -- if damageable entity has been detected (hitreg[3] is not nil), damage it
    if #hitReg[3] > 0 then
      for _, hitId in ipairs(hitReg[3]) do
        world.sendEntityMessage(hitId, "applyStatusEffect", "project45damage", self:damagePerShot() * activeItem.ownerPowerMultiplier(), entity.id())
      end
    end

    -- vfx

    -- screen shake for that oomph
    self:screenShake(self.shotShakeAmount)
    projectileId = world.spawnProjectile(
      "project45_hitexplosion",
      hitReg[2],
      activeItem.ownerEntityId(),
      self:aimVector(),
      false,
      {}
    )

    -- increases amount of screenshake for next shot
    self.shotShakeAmount = math.min(self.maxShotShakeAmount, self.shotShakeAmount+self.shotShakePerShot)

    -- bullet trail info inserted to projectile stack that's being passed to the animation script
    -- each bullet trail in the stack is rendered, and the lifetime is updated in this very script too
    local life = 0.5
    table.insert(projectileStack, {
      origin = hitReg[1],
      destination = hitReg[2],
      lifetime = life,
      maxLifetime = life
    })

    coroutine.yield()
  end
  
  -- makes gun sound more hollow the less bullets there are
  animator.setSoundVolume("hollow", 1 - self.ammo/self.maxAmmo, 0)
  playSound("hollow")

  -- if ammo is out, click
  if self.ammo <= 0 then
    playSound("click")
  end

  self.breechReady = false

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
    sb.logInfo("[PROJECT 45] : Crit!")
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