---@diagnostic disable: duplicate-set-field
require "/scripts/set.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()

  if not storage.manipulatorArmor then
    storage.manipulatorArmor = set.new(self.passiveParameters.validArmor or {})
  end

  if player then
    local damageMultAdd = 0

    -- TODO: try using tags
    local isHead = storage.manipulatorArmor[(player.equippedItem("head") or {}).name or "???"]
    local isChest = storage.manipulatorArmor[(player.equippedItem("chest") or {}).name or "???"]
    local isLegs = storage.manipulatorArmor[(player.equippedItem("legs") or {}).name or "???"]
    damageMultAdd = damageMultAdd + (isHead and self.passiveParameters.pieceDamage or 0)
    damageMultAdd = damageMultAdd + (isChest and self.passiveParameters.pieceDamage or 0)
    damageMultAdd = damageMultAdd + (isLegs and self.passiveParameters.pieceDamage or 0)
    self.passiveDamageMult = 1 + damageMultAdd
  end
end

function Passive:update(dt, fireMode, shiftheld)
  status.addEphemeralEffect("energyregen", 0.1)
end
