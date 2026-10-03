---@diagnostic disable: duplicate-set-field
require "/scripts/set.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()
  if player then
    if (player.equippedItem("head") or {}).name == "headbandhead" then
      self.ammoPerShot = 0
    end
  end
end

function Passive:update(dt, fireMode, shiftheld)
end
