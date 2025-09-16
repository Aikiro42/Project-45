---@diagnostic disable: duplicate-set-field
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()
  self.maxHeat = self.overchargeTime
end

function Passive:update(dt, fireMode, shiftHeld)

  if storage.project45GunState.jamAmount <= 0 and animator.animationState("bolt") ~= "jammed" then
    self.flamePosition = self:weaponPosition(self.passiveParameters.flameOffset)
    activeItem.setScriptedAnimationParameter("flamePosition", self.flamePosition)
    activeItem.setScriptedAnimationParameter("renderFlame", true)
    animator.setLightActive("pyroclastFlame", true)
    animator.setLightColor("pyroclastFlame", {
      math.floor(sb.nrand(5, 175)),
      math.floor(sb.nrand(5, 78)),
      0
    })
  else
    animator.setLightActive("pyroclastFlame", false)
    activeItem.setScriptedAnimationParameter("renderFlame", false)
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