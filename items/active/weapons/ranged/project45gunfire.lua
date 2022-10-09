require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
Project45GunFire = WeaponAbility:new()

local projectileStack = {}
local fireModeHeld = false

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

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function Project45GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  self.weapon:updateAim()
  -- update projectile stack
  for i, projectile in ipairs(projectileStack) do
    projectileStack[i].lifetime = projectileStack[i].lifetime - dt
    if projectileStack[i].lifetime <= 0 then
      table.remove(projectileStack, i)
    end
  end
  
  local laserOrig = self:firePosition()
  local laserDest = vec2.add(laserOrig, vec2.mul(vec2.rotate(self:aimVector(0),(self.weapon.relativeArmRotation + self.weapon.relativeWeaponRotation) * mcontroller.facingDirection()), self.range))
  laserDest = world.lineCollision(laserOrig, laserDest, {"Block", "Dynamic"}) or laserDest
  activeItem.setScriptedAnimationParameter("laserOrig", laserOrig)
  activeItem.setScriptedAnimationParameter("laserDest", laserDest)
  
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
  else
    activeItem.setCursor("/cursors/project45reticlerun.cursor")
    self.inaccuracy = self.runInaccuracy
    self.critChance = self.runCritChance
    self.critMult = self.runCritMult
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0 then
    -- and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.jamScore == 0 then
      if self.ammo > 0 then
        self.jamScore = self:calculateJam(self.jamChance)
        if self.jamScore > 0 then
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
        status.overConsumeResource("energy", self.magEnergyCostRate*status.resourceMax("energy"))
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
  
  self:muzzleFlash()
  self.weapon:setStance(self.stances.fire)
  self:fireProjectile()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function Project45GunFire:burst()

  local shots = self.burstCount
  while shots > 0 do
    self:muzzleFlash()
    self.weapon:setStance(self.stances.fire)
    self:fireProjectile()
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

    util.wait(self.burstTime)
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function Project45GunFire:cooldown()
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
end

function Project45GunFire:reload()

  self.cooldownTimer = self.fireTime

  self.weapon:setStance(self.stances.reload)
  self.weapon:updateAim()
  animator.burstParticleEmitter("magazine")
  activeItem.setScriptedAnimationParameter("reloading", true)
  playSound("reload", 0.05)

  local reloadTimer = 0
  local perfectReload = false
  local reloadAttempt = 0
  local fireGracePeriod = self.reloadGracePeriod
  activeItem.setScriptedAnimationParameter("barColor", {225,225,225})
  while reloadTimer <= self.stances.reload.duration do

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
  playSound("perfectReload", 0.05)
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
    self:screenShake(self.unjamShakeAmount)
    playSound("perfectReload")
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

function Project45GunFire:muzzleFlash()
  playSound("fire")
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.burstParticleEmitter("ejectionPort")

  animator.setLightActive("muzzleFlash", true)
end

function Project45GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  self.ammo = self.ammo - 1
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0  
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    local projOrigin = firePosition or self:firePosition()
    local projVector = self:aimVector(inaccuracy or self.inaccuracy)
    
    local projDestination = vec2.add(projOrigin, vec2.mul(projVector, self.range))
    projDestination = world.lineCollision(projOrigin, projDestination, {"Block", "Dynamic"}) or projDestination
    
    world.debugLine(projOrigin, projDestination, {255,0,255})
    
    local targetIDs = world.entityLineQuery(projOrigin, projDestination, {
      withoutEntityId = entity.id(),
      includedTypes = {"monster", "npc", "player"},
      order = "nearest"
    })

    if #targetIDs > 0 then
      for _, id in ipairs(targetIDs) do
        -- damage
        if world.entityCanDamage(entity.id(), id) then
          local explosionPos = getIntersection(projOrigin, projDestination, world.entityPosition(id)[1])
          projectileId = world.spawnProjectile(
              projectileType,
              -- world.entityPosition(id),
              explosionPos,
              activeItem.ownerEntityId(),
              projVector,
              false,
              params
          )
          
          -- world.sendEntityMessage(id, "applyStatusEffect", "project45damage", self:damagePerShot(), entity.id())

        end
        coroutine.yield()
      end
    end

    -- vfx
    self:screenShake(self.shotShakeAmount)
    self.shotShakeAmount = math.min(self.maxShotShakeAmount, self.shotShakeAmount+self.shotShakePerShot)
    local life = 0.5
    table.insert(projectileStack, {
      origin = projOrigin,
      destination = projDestination,
      lifetime = life,
      maxLifetime = life
    })
  end
  animator.setSoundVolume("hollow", 1 - self.ammo/self.maxAmmo, 0)
  playSound("hollow")
  if self.ammo <= 0 then
    playSound("click")
    self.inputCooldownTimer = self.fireTime + 2*self.dt
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

function Project45GunFire:calculateJam(jamChance)
  math.randomseed(os.time())
  local diceroll = math.random()
  if diceroll < jamChance then
    playSound("jammed")
    return 1
  end
  return 0
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

function getIntersection(a, b, x)
  local m = (b[2] - a[2])/(b[1] - a[1])
  local b = a[2] - m*a[1]
  local y = m*x + b
  return {x, y}
end

function playSound(soundName, pitchRange)
  local pitchRange = pitchRange or 0.1
  math.randomseed(os.time())
  animator.setSoundPitch(soundName, 1 - (pitchRange / 2) + pitchRange*math.random(), 0)
  animator.playSound(soundName);
end