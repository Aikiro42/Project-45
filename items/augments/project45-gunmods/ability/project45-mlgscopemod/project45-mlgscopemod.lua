---@diagnostic disable: duplicate-set-field
require "/scripts/set.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/constants.lua"

Passive = Project45Passive:new()

function Passive:init()

  self.perfectReloadCount = 0
  self.mlgStyleTimer = 0
end

function Project45Passive:update(dt, fireMode, shiftHeld)
  self.mlgStyleTimer = math.max(0, self.mlgStyleTimer - dt)
end


function Passive:onLoadRound(reloadRating)
  if self.mlgStyleTimer > 0 then return end
  self.mlgRoundLoaded = true
  if reloadRating >= GOOD then
    self.perfectReloadCount = self.perfectReloadCount + 1
    if self.perfectReloadCount >= 6 then
      status.addEphemeralEffect("project45mlgstyle", 18.08)
      self.mlgStyleTimer = 18.08
      self.perfectReloadCount = 0
    else
      animator.playSound("mlgReload" .. self.perfectReloadCount)
    end
  else
    animator.playSound("mlgReloadFail")
    self.perfectReloadCount = 0
  end
end

function Passive:onReloadEnd()
  if self.mlgRoundLoaded or self.mlgStyleTimer > 0 then return end
  local reloadRating = storage.project45GunState.reloadRating
  if reloadRating >= GOOD then
    self.perfectReloadCount = self.perfectReloadCount + 1
    if self.perfectReloadCount >= 6 then
      status.addEphemeralEffect("project45mlgstyle", 18.08)
      self.mlgStyleTimer = 18.08
      self.perfectReloadCount = 0
    else
      animator.playSound("mlgReload" .. self.perfectReloadCount)
    end
  else
    animator.playSound("mlgReloadFail")
    self.perfectReloadCount = 0
  end
end