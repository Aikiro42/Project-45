require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/weapon.lua"

Project45GunFire = WeaponAbility:new()

function Project45GunFire:init()

  self.fireTime = 1 / self.fireRate  -- set fire rate
  
  self.semi = false
  self.manualFeed = true
  
  -- separate cock time and reload time
  self.cockTime = self.reloadTime * 0.2
  self.reloadTime = self.reloadTime * 0.8

  -- validate quick reload timeframe; perfect reload must be within bounds of good reload
  if self.quickReloadTimeframe[4] < self.quickReloadTimeframe[1] then
    -- swap if latter is bigger than former
    local temp = self.quickReloadTimeframe[1]
    self.quickReloadTimeframe[1] = self.quickReloadTimeframe[4]
    self.quickReloadTimeframe[4] = temp
  end
  self.quickReloadTimeframe[2] = math.max(self.quickReloadTimeframe[1], self.quickReloadTimeframe[2])
  self.quickReloadTimeframe[3] = math.min(self.quickReloadTimeframe[3], self.quickReloadTimeframe[4])

  -- grab stored data
  storage.ammo = storage.ammo or config.getParameter("currentAmmo", self.maxAmmo)
  storage.stanceProgress = 0 -- stance progres is stored in storage so that other weapons may recoil the gun
  self.jamAmount = config.getParameter("currentJamAmount", 0)

  -- initialize timers
  self.chargeTimer = 0
  self.cooldownTimer = self.fireTime

  -- initialize animation stuff
  activeItem.setScriptedAnimationParameter("reloadTimer", -1)
  activeItem.setScriptedAnimationParameter("chargeTimer", 0)
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
  activeItem.setScriptedAnimationParameter("reloadTime", self.reloadTime)
  activeItem.setScriptedAnimationParameter("chargeTime", self.chargeTime)
  activeItem.setScriptedAnimationParameter("overchargeTime", self.overchargeTime)
  activeItem.setScriptedAnimationParameter("perfectReload", {self.quickReloadTimeframe[2], self.quickReloadTimeframe[3]})
  activeItem.setScriptedAnimationParameter("goodReload", {self.quickReloadTimeframe[1], self.quickReloadTimeframe[4]})

  
  self.stances = {}
  self.stances.aimStance = {
    weaponRotation = 0,
    armRotation = 0,
    twoHanded = config.getParameter("twoHanded", false),
    allowRotate = true,
    allowFlip = true
  }

  self.weapon:setStance(self.stances.aimStance)
  self:recoil(true, 4)

end

function Project45GunFire:update(dt, fireMode, shiftHeld)

  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  self:updateCharge()
  self:updateStance()

  if self:triggering()
  and not self.triggered
  and not self.weapon.currentAbility
  and self.cooldownTimer == 0
  and self.chargeTimer >= self.chargeTime
  then

    if storage.ammo > 0 then
      self:setState(self.firing)
      self.triggered = self.semi or storage.ammo == 0

    else
      
      if storage.ammo == 0 then
        self:ejectMag()
      else
        self:setState(self.reloading)
      end
      self.triggered = true

    end

      
    self.cooldownTimer = self.fireTime

  elseif not self:triggering() then
    self.triggered = false
  end

end

function Project45GunFire:uninit()
  activeItem.setInstanceValue("currentAmmo", self.ammo)
  activeItem.setInstanceValue("currentJamAmount", self.jamAmount)
end

-- STATE FUNCTIONS

function Project45GunFire:jammed()
end

function Project45GunFire:firing()
  self:fireProjectile()
  animator.playSound("fire")
  self:recoil()
  self:updateAmmo(-self.ammoPerShot)
end

function Project45GunFire:cocking()
end

function Project45GunFire:reloading()
  
  animator.playSound("getmag")

  self.reloadTimer = 0
  self.triggered = true
  local attemptedReload = false

  local reloadRating = ""
  activeItem.setScriptedAnimationParameter("reloadRating", reloadRating)

  while self.reloadTimer <= self.reloadTime do
    activeItem.setScriptedAnimationParameter("reloadTimer", self.reloadTimer)
    
    if self:triggering() and not self.triggered and not attemptedReload then
      attemptedReload = true
      reloadRating = self:reloadRating()
      activeItem.setScriptedAnimationParameter("reloadRating", reloadRating)
      if reloadRating ~= "BAD" then
        self.triggered = true
        break
      end
    end   

    self.reloadTimer = self.reloadTimer + self.dt
    coroutine.yield()
  end

  animator.playSound("reload")
  util.wait(self.cockTime)
  
  self.reloadTimer = -1
  activeItem.setScriptedAnimationParameter("reloadTimer", -1)
  self:updateAmmo(self.maxAmmo, true)
end

-- HELPER FUNCTIONS

-- Updates the charge of the gun
-- This is supposed to be called every tick in `Project45GunFire:update()`
function Project45GunFire:updateCharge()
  if self:triggering() then
    -- charge up if triggered
    self.chargeTimer = math.min(self.chargeTime + self.overchargeTime, self.chargeTimer + self.dt)
  else
    -- charge down otherwise
    self.chargeTimer = math.max(0, self.chargeTimer - self.dt * self.dischargeTimeMult)
  end

  activeItem.setScriptedAnimationParameter("chargeTimer", self.chargeTimer)

end

-- Returns the reload rating
-- only called from the reloading state
function Project45GunFire:reloadRating()
  -- perfect reload can be in a region outside good reload
  if self.reloadTime * self.quickReloadTimeframe[2] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.quickReloadTimeframe[3] then
    return "PERFECT"
  elseif self.reloadTime * self.quickReloadTimeframe[1] <= self.reloadTimer and self.reloadTimer <= self.reloadTime * self.quickReloadTimeframe[4] then
    return "GOOD"
  else
    return "BAD"
  end
end

function Project45GunFire:updateAmmo(delta, set)
  storage.ammo = set and delta or storage.ammo + delta
  activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
end

-- updates the weapon's stance
-- interpolates the weapon's stance to the stance set via self.weapon:setStance()
function Project45GunFire:updateStance()

  local offset_i = self.weapon.weaponOffset
  local offset_o = config.getParameter("baseOffset", self.weapon.stance.weaponOffset or {0, 0})

  self.weapon.weaponOffset = {
    interp.sin(storage.stanceProgress, offset_i[1], offset_o[1]),
    interp.sin(storage.stanceProgress, offset_i[2], offset_o[2])
  }
  self.weapon.aimAngle, self.weapon.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())    
  self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(storage.stanceProgress, math.deg(self.weapon.relativeWeaponRotation), self.weapon.stance.weaponRotation))
  self.weapon.relativeArmRotation = util.toRadians(interp.sin(storage.stanceProgress, math.deg(self.weapon.relativeArmRotation), self.weapon.stance.armRotation))
  
  -- update stance progress
  storage.stanceProgress = math.min(1, storage.stanceProgress + self.dt / self.recoverTime)

end

function Project45GunFire:recoil(down, mult)
  local mult = mult or self.recoilMult
  mult = down and -mult or mult
  self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(self.recoilAmount * mult)
  self.weapon.relativeArmRotation = self.weapon.relativeArmRotation + util.toRadians(self.recoilAmount * mult)
  self.weapon.weaponOffset = {-0.1, 0}
  storage.stanceProgress = 0
end

function Project45GunFire:damagePerShot(isHitscan)
  return 45
end

function Project45GunFire:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function Project45GunFire:fireProjectile(projectileType)
      
  self.projectileParameters.power = self:damagePerShot()
  
  local projectileId = world.spawnProjectile(
    projectileType or self.projectileType,
    self:firePosition(),
    activeItem.ownerEntityId(),
    self:aimVector(0),
    false,
    self.projectileParameters
  )
  
end

function Project45GunFire:ejectMag()
  self:recoil(true, 45)
  animator.playSound("eject")
  self:updateAmmo(-1, true)
end

function Project45GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(vec2.add(self.weapon.muzzleOffset, self.weapon.weaponOffset), self.weapon.relativeWeaponRotation)))
end

function Project45GunFire:aimVector(spread)
  local firePos = self:firePosition()
  local basePos =  vec2.add(mcontroller.position(), activeItem.handPosition(vec2.rotate(vec2.add({self.weapon.muzzleOffset[1] - 1, self.weapon.muzzleOffset[2]}, self.weapon.weaponOffset), self.weapon.relativeWeaponRotation)))
  world.debugPoint(firePos, "cyan")
  world.debugPoint(basePos, "cyan")
  local aimVector = vec2.norm(world.distance(firePos, basePos))
  aimVector = vec2.rotate(aimVector, sb.nrand((spread or 0), 0))
  return aimVector
end