---@diagnostic disable: duplicate-set-field
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()
  self.bloodForBlood = 10
end

function Passive:update(dt, fireMode, shiftHeld)
  if status.resourcePercentage("health") < 0.5 then
    storage.project45GunState.damageModifiers["fleetlyFadingPassiveMult"] = {type="mult", value=1.3}
  else
    storage.project45GunState.damageModifiers["fleetlyFadingPassiveMult"] = nil
  end

end

function Passive:onFire()
  if status.resourcePercentage("health") > 0.1 then
    self.bloodForBlood = self.bloodForBlood - 1
  end
  if self.bloodForBlood <= 0 then
    self.bloodForBlood = 10
    status.modifyResourcePercentage("health", -0.05)
  end
end