---@diagnostic disable: duplicate-set-field
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/constants.lua"

Passive = Project45Passive:new()

function Passive:init()
  self.chargeTimer = self.heat
  self.maxHeat = self.overchargeTime
  self.ignitionDelay = 0.2
  self.reloadDisabled = true
end

function Passive:update(dt, fireMode, shiftHeld)

  self:updateStockAmmo(0, true)

  local chargeProgress = self.chargeTimer / self.overchargeTime

  if storage.project45GunState.jamAmount <= 0 then

    if animator.animationState("bolt") == "jammed" then
      -- self.reloadDisabled = false
      self:setState(self.cocking)
    else

      self:updateAmmo(math.ceil((1 - chargeProgress) * self.maxAmmo), true)
      self:updateReloadRating(PERFECT)

      animator.stopAllSounds("cooldownHiss")
      -- self.reloadDisabled = false
      if self.ignitionDelay == 0 then
        animator.playSound("flameIgnition")
        self.ignitionDelay = -1
      elseif self.ignitionDelay > 0 then
        self.ignitionDelay = math.max(0, self.ignitionDelay - dt)
      end
      self.flamePosition = self:weaponPosition(self.passiveParameters.flameOffset)
      activeItem.setScriptedAnimationParameter("flamePosition", self.flamePosition)
      activeItem.setScriptedAnimationParameter("renderFlame", true)
      animator.setLightActive("pyroclastFlame", true)
      animator.setLightColor("pyroclastFlame", {
        math.floor(sb.nrand(5, 175)),
        math.floor(sb.nrand(5, 78)),
        0
      })

    end
    
  else
    
    self:updateAmmo(0, true)
    
    animator.setLightActive("pyroclastFlame", false)
    activeItem.setScriptedAnimationParameter("renderFlame", false)
    animator.setSoundVolume("cooldownHiss", storage.project45GunState.jamAmount / 1)
    animator.burstParticleEmitter("ejectionPort")
    
  end

  if self.heat >= self.maxHeat then
    self:jam(true)
  end

  self.heat = self.chargeTimer

  self:updateJamAmount(-dt*0.1)

end

function Passive:onJam()
  world.spawnProjectile(
    "project45_stdfireexplosion",
    self.flamePosition,
    activeItem.ownerEntityId(),
    {1, 0},
    false,
    {
      power = status.resourceMax("health") / 2
    }
  )
  self.heat = 0
  self.ignitionDelay = 0.1
  animator.playSound("cooldownHiss", 1)
end

function Passive:onUnjam()
  self:updateAmmo(self.maxAmmo)
  self:updateStockAmmo(-self.maxAmmo)
end

function Passive:onLoadGunState()
  local passiveState = config.getParameter("savedPassiveState", {})
  self.heat = passiveState.heat or 0
end

function Passive:onSaveGunState()
  activeItem.setInstanceValue("savedPassiveState", {
    heat = self.heat or 0
  })
end