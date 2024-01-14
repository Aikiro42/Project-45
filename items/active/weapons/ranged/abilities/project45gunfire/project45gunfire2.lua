require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/poly.lua"
require "/items/active/weapons/project45neoweapon.lua"
require "/scripts/project45/hitscanLib.lua"
require "/scripts/project45/project45util.lua"

require "/items/active/weapons/ranged/gunfire.lua"
require "/items/active/weapons/ranged/abilities/altfire.lua"

local BAD, OK, GOOD, PERFECT = 1, 2, 3, 4
local reloadRatingList = {"BAD", "OK", "GOOD", "PERFECT"}

Project45GunFire = WeaponAbility:new()

function Project45GunFire:init()
    
  self:loadGunState()

  -- Internal Variables  
  self.triggered = true
  self.startRecoil = 0
  self.recoilProgress = 1
  self.cooldownTimer = self.fireTime
  self:reloadTimer(-1)

  -- turn self.ammoPerShot into a function
  self.consumedAmmo = self.ammoPerShot

  -- If `max` is `false`, returns the minimum possible ammo consumed per shot.
  -- If `max` is `true`, returns the maximum possible ammo consumed per shot.
  -- If `max` is otherwise unspecified, returns either the minimum or maximum
  -- ammo consumed per shot, based on `self.ammoConsumeChance`.
  -- @param max Boolean | nil
  self.ammoPerShot = function(max)
    if max == nil then
      return self.consumedAmmo * math[project45util.diceroll(self.ammoConsumeChance) and "ceil" or "floor"](self.ammoConsumeChance)      
    elseif max == true then
      return self.consumedAmmo * math.ceil(self.ammoConsumeChance)
    else
      return self.consumedAmmo * math.floor(self.ammoConsumeChance)
    end
  end

  self:setState(self.idle)
end

function Project45GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  
  self:updateRecoil()
  self:updateTimers()

  if not self:triggering() then
    self.triggered = false
  end

end

function Project45GunFire:uninit()
  self:saveGunState()
  activeItem.setScriptedAnimationParameter("beamLine", nil)
  activeItem.setScriptedAnimationParameter("projectileStack", nil)
end

-- SECTION: Persistent States

function Project45GunFire:idle()
  while true do
    if self:triggering() and not self.triggered then
      if self.manualFeed and self:chamberState() == "filled" then
        self:setState(self.cocking)
      else
        self:setState(self.firing)
      end
      return
    end
    coroutine.yield()
  end
end

function Project45GunFire:empty()
  while true do
    if self:triggering() and not self.triggered then
      self:ejectMag()
      return
    end
    coroutine.yield()
  end
end

function Project45GunFire:noMag()
  while true do
    if self:triggering() and not self.triggered then
      self:setState(self.reloading)
      return
    end
    coroutine.yield()
  end
end

function Project45GunFire:jammed()
  self.weapon:setStance(self.stances.jammed)
  while true do
    if self:triggering() and not self.triggered then
      self:unjam()
      return
    end
    coroutine.yield()
  end
end

-- SECTION: Transient States

function Project45GunFire:charging()
  
end

function Project45GunFire:firing()

end

function Project45GunFire:ejecting()
  if storage.ammo <= 0 then
    self:setState(self.empty)
    return
  end
  
  self:chamberState("empty")
  self:boltState("open")

  self:setState(self.feeding)
end

function Project45GunFire:feeding()
  self:setState(self.idle)
end

function Project45GunFire:reloading()
  
  -- reload minigame
  self:reloadTimer(0)
  while self:reloadTimer(self.dt) < self.reloadTime do

    if self:triggering() and not self.triggered then
      
      if self.bulletsPerReload and self.bulletsPerReload < self.maxAmmo then
        self:loadRound()
      else
        self:loadMag()
        break
      end
    end
  end

  storage.ammo = self.maxAmmo
end

function Project45GunFire:cocking()

  if self:boltState() == "closed" then
    self:pullBolt()
  end

  if self:ammo() < 0 then
    self:setState(self.noMag)
    return
  elseif self:ammo() == 0 then
    self:setState(self.empty)
    return
  end

  self:pushBolt()
  self:setState(self.idle)
end

-- SECTION: Actions

function Project45GunFire:loadGunState()
  
  local loadedGunState = config.getParameter("savedGunState", {
    chamber = "empty",
    bolt = "open",
    gunAnimation = self.breakAction and "open" or "ejected",
    ammo = -1,
    reloadRating = OK,
    unejectedCasings = 0,
    jamAmount = 0,
    savedProjectileIndex = 1,
    loadSuccess = false
  })

  if not loadedGunState.loadSuccess then
    sb.logInfo("[PROJECT 45] WARNING: GUN STATE NOT LOADED")
  end

  self:chamberState(loadedGunState.chamber)
  
  self:ammo(storage.ammo or loadedGunState.ammo, true)
  storage.savedProjectileIndex = storage.savedProjectileIndex or loadedGunState.savedProjectileIndex

  -- saved projectile index validation
  local projectiles = self.projectileKind == "summoned" and self.summonedProjectileType or self.projectileType
  if type(projectiles) == "table" and storage.savedProjectileIndex > #projectiles then
    storage.savedProjectileIndex = #projectiles
  end

  self:reloadRating(storage.reloadRating or loadedGunState.reloadRating)

  storage.unejectedCasings = storage.unejectedCasings or loadedGunState.unejectedCasings
  self:jamAmount(storage.jamAmount or loadedGunState.jamAmount, 1)
  self:boltState(loadedGunState.bolt)
  
  if self:boltState() == "open" then
    loadedGunState.gunAnimation = (self.breakAction and not loadedGunState.loadSuccess) and "open" or "ejected"
  end

  if self:ammo() < 0 and self.breakAction then
    loadedGunState.gunAnimation = "open"
  end

  animator.setAnimationState("gun", loadedGunState.gunAnimation)

end

function Project45GunFire:saveGunState()
  local newGunAnimState = {
    jammed="jammed",
    idle="idle",
    open="open",
    ejected="ejected",

    ejecting = "ejected",
    boltPulling = "ejected",
    
    feeding = "idle",
    boltPushing = "idle",

    firing = "idle",
    firingLoop = "idle",
    fired = "fired",
    
    unjamming = storage.jamAmount > 0 and "jammed" or "idle",
  }

  local gunState = {
    chamber = animator.animationState("chamber"),
    bolt = animator.animationState("bolt"),
    gunAnimation = newGunAnimState[animator.animationState("gun")],
    ammo = storage.ammo,
    reloadRating = storage.reloadRating,
    unejectedCasings = storage.unejectedCasings,
    jamAmount = storage.jamAmount,
    savedProjectileIndex = storage.savedProjectileIndex,
    loadSuccess = true
  }
  activeItem.setInstanceValue("savedGunState", gunState)

end

-- Sets the jam amount to 1, sets the chamber state
-- to filled, consumes ammo and finally sets the state to jammed.
function Project45GunFire:jam()
  animator.setAnimationState("chamber", "filled")
  self:jamAmount(1)
  self:ammo(-(self:ammoPerShot()))
  self:setState(self.jammed)
end

function Project45GunFire:unjam()

  if self.triggered then return end

  self.triggered = true
  self:screenShake()
  self:recoil(true, 0.5)
  animator.setAnimationState("gun", "unjamming") -- should transist back to being jammed
  animator.playSound("unjam")
  self.weapon:setStance(self.stances.unjam)
  
  if self:jamAmount(math.random() * -0.5) <= 0 then
    self:reloadRating("ok")
    self:setState(self.cocking)
  end
end

function Project45GunFire:fire()
  self:fireProjectile()
  self:muzzleFlash()
  self:recoil()
  self:setState(self.ejecting)
end

function Project45GunFire:recoil()
  self.startRecoil = 1
  self.recoilProgress = 0
end

function Project45GunFire:ejectMag()
  storage.ammo = -1
  self:setState(self.noMag)
end

function Project45GunFire:pullBolt()
  self:chamberState("empty")
  self:boltState("open")
  --[[
    animate()
    if self.chamber ~= empty then
      ejectCasings()
      self.chamber = empty
    end
    self.bolt = open
  ]]
end

function Project45GunFire:pushBolt()
  if self:ammo() > 0 then
    self:ammo(-self.ammoPerShot)
  end
  --[[
    animate()
    if storage.ammo > 0 then
      storage.ammo = storage.ammo - 1
      self.chamber = ready
    end
    self.bolt = closed
  ]]
end

function Project45GunFire:loadRound()
  storage.ammo = math.max(storage.ammo, 0)
  storage.ammo = math.min(self.maxAmmo, storage.ammo + self.bulletsPerReload)
end

function Project45GunFire:loadMag()
  storage.ammo = math.max(storage.ammo, 0)
  storage.ammo = self.maxAmmo
end

-- @return None
function Project45GunFire:discardCasings(n)
  if self.performanceMode then
    storage.unejectedCasings = 0
    return
  end

  if storage.unejectedCasings > 0 or n then
    animator.setParticleEmitterBurstCount("ejectionPort", n or storage.unejectedCasings)
    animator.burstParticleEmitter("ejectionPort")
    for casing = n or storage.unejectedCasings, 0, -1 do
      animator.setSoundPitch("ejectCasing", sb.nrand(0.075, 1))
      animator.playSound("ejectCasing")
    end
    storage.unejectedCasings = 0
  end
end

-- SECTION: Updaters

function Project45GunFire:updateRecoil()
  self.weapon.recoilAmount = interp.sin(self.recoilProgress, self.startRecoil, 0)
end

function Project45GunFire:updateTimers()
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
end

function Project45GunFire:updateAnimationScriptParameters()
  -- update chamber indicator
end

-- SECTION: Validators

-- If `delta` is specified and `replace` is `true`, sets the current ammo to `delta`.
-- If `delta` is specified and `replace` is `false`, changes the current ammo by `delta`.
-- Returns the new/current jam amount.
-- @param delta Integer
-- @param replace Boolean
-- @return Integer
function Project45GunFire:ammo(delta, replace)
  if delta then
    if replace then
      storage.ammo = delta
    else
      storage.ammo = util.clamp(storage.ammo + delta, 0, self.maxAmmo)
    end
    activeItem.setScriptedAnimationParameter("ammo", storage.ammo)
  end
  return storage.ammo
end

-- If `state` is specified, sets the chamber state to `state`.
-- Returns the new/current chamber state.
-- @param state Enum<String>("ready", "filled", "empty")
-- @return String
function Project45GunFire:chamberState(state)
  if state then
    animator.setAnimationState("chamber", state)
    activeItem.setScriptedAnimationParameter("primaryChamberState", animator.animationState("chamber"))  
  end
  return state or animator.animationState("chamber")
end

-- If `rating` is provided, sets the weapon's reload rating to `rating`
-- Returns the new/current reload rating.
-- @param rating Enum<String>("bad", "ok", "good", "perfect")
-- @retuen String
function Project45GunFire:reloadRating(rating)
  -- FIXME: make me an enum
  if rating then
    storage.reloadRating = rating
    activeItem.setScriptedAnimationParameter("reloadRating", reloadRatingList[storage.reloadRating])
  end
  return storage.reloadRating
end

-- If `state` is provided, sets the bolt state to `state`.
-- Returns the new/current bolt state.
-- @param state Enum<String>("open", "closed")
-- @return String
function Project45GunFire:boltState(state)
  if state then
    animator.setAnimationState("bolt", state)
  end
  return state or animator.animationState("bolt")
end

-- If `delta` is specified and `replace` is `true`, sets the jam amount to `delta`.
-- If `delta` is specified and `replace` is `false`, changes the jam amount by `delta`.
-- Returns the new/current jam amount.
-- @param delta Integer
-- @param replace Boolean
-- @return Float
function Project45GunFire:jamAmount(delta, replace)
  if delta then
    if replace then
      storage.jamAmount = delta
    else
      storage.jamAmount = util.clamp(storage.jamAmount + delta, 0, 1)
    end
    activeItem.setScriptedAnimationParameter("jamAmount", storage.jamAmount)
  end
  return storage.jamAmount
end

-- If `t` is provided, sets the reload timer to `t`.
-- Returns the new/current value of the reload timer.
-- @param t Float
-- @return Float
function Project45GunFire:reloadTimer(t)
  if t then
    self._reloadTimer = t
    activeItem.setScriptedAnimationParameter("reloadTimer", -1)
  end
  return self._reloadTimer
end

-- SECTION: Initial Evaluators

function Project45GunFire:evalProjectileKind()
end

-- Returns whether the left click is held or not
function Project45GunFire:triggering()
  return self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

-- SECTION: Evaluators

function Project45GunFire:crit()
end

function Project45GunFire:multishot()
end

function Project45GunFire:damagePerShot()
end

-- SECTION: Sub-actions

function Project45GunFire:fireProjectile(projectileType, projectileParameters, inaccuracy, firePosition, projectileCount, aimVector, addOffset)
  local params = sb.jsonMerge(self.projectileKind == "summoned" and self.summonedProjectileParameters or self.projectileParameters, projectileParameters or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)
  local selectedProjectileType = nil

  if not projectileType then
    projectileType = self.projectileKind == "summoned" and self.summonedProjectileType or self.projectileType
  end

  selectedProjectileType = projectileType
  
  if type(projectileType) == "table" then
    selectedProjectileType = projectileType[storage.savedProjectileIndex]
    if not self.projectileFireSettings or not self.projectileFireSettings.batchFire then
      self:rerollProjectileIndex(#projectileType)
    end
  end
  
  local projectileId = 0
  
  local nproj = (projectileCount or (self.projectileCount * self:rollMultishot()))
  if self.maxProjectileCount then
    if nproj > self.maxProjectileCount then
      params.power = params.power * nproj / self.maxProjectileCount
      nproj = math.min(nproj, self.maxProjectileCount)
    end
  end
    
  if self.critFlag and self.enableMuzzleCritParticles then
    animator.burstParticleEmitter("muzzleCrit")
  end

  -- if crit was rolled, all projectiles fired inflict a crit hit
  for i = 1, nproj do

    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
      selectedProjectileType,
      firePosition or self:firePosition(nil, addOffset),
      activeItem.ownerEntityId(),
      aimVector or self:aimVector(inaccuracy or self.spread),
      false,
      self.critFlag and sb.jsonMerge(params, {statusEffects = {"project45critdamaged"}}) or params
    )

  end

  self.critFlag = false

  return projectileId
  
end