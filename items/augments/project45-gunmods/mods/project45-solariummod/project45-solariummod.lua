---@diagnostic disable: duplicate-set-field
require "/scripts/set.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()

  if not storage.allArmor then
    storage.allArmor = set.new(self.passiveParameters.validArmor or {})
  end

  if player then
    local damageMultAdd = 0

    -- TODO: try using tags
    local isHead = storage.allArmor[(player.equippedItem("head") or {}).name or "???"]
    local isChest = storage.allArmor[(player.equippedItem("chest") or {}).name or "???"]
    local isLegs = storage.allArmor[(player.equippedItem("legs") or {}).name or "???"]
    damageMultAdd = damageMultAdd + (isHead and self.passiveParameters.pieceDamage or 0)
    damageMultAdd = damageMultAdd + (isChest and self.passiveParameters.pieceDamage or 0)
    damageMultAdd = damageMultAdd + (isLegs and self.passiveParameters.pieceDamage or 0)
    self.passiveDamageMult = 1 + damageMultAdd
  end
end

function Passive:onCrit()
  if player and math.random() < self.passiveParameters.pixelChance then
      player.addCurrency("money", self.passiveParameters.pixelsPerCrit)
    end
end
