---@diagnostic disable: duplicate-set-field
require "/scripts/set.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/constants.lua"

Passive = Project45Passive:new()

function Passive:init()

  self.countMLGReload = function(reloadRating)
    -- do not count if invincible
    local statEffects = status.activeUniqueStatusEffectSummary()
    for _, fx in ipairs(statEffects) do
      if fx[1] == "project45mlgstyle" then return end
    end

    -- count if perfect
    if reloadRating >= PERFECT then
      self.perfectReloadCount = self.perfectReloadCount + 1
      if self.perfectReloadCount >= 6 then
        status.addEphemeralEffect("project45mlgstyle", 20)
        self.perfectReloadCount = 0
      else
        animator.playSound("mlgReload" .. self.perfectReloadCount)
      end
    else
      animator.playSound("mlgReloadFail")
      self.perfectReloadCount = 0
    end
  end

  self.perfectReloadCount = 0
end

function Passive:onLoadRound(reloadRating)
  self.mlgRoundLoaded = true
  self.countMLGReload(reloadRating)
end

function Passive:onReloadEnd()
  if self.mlgRoundLoaded then return end
  local reloadRating = storage.project45GunState.reloadRating
  self.countMLGReload(reloadRating)
end
