require "/scripts/set.lua"

Passive = {}

function Passive:init()
  if player then

    if not storage.acceleratorArmor then
      storage.acceleratorArmor = set.new(self.passiveParameters.validArmor or {})
      local races = {"human", "apex", "hylotl", "floran", "glitch", "novakid", "avian"}
      for _, race in ipairs(races) do
        storage.acceleratorArmor[race .. "tier5ahead"] = true
        storage.acceleratorArmor[race .. "tier5achest"] = true
        storage.acceleratorArmor[race .. "tier5alegs"] = true
        storage.acceleratorArmor[race .. "tier6ahead"] = true
        storage.acceleratorArmor[race .. "tier6achest"] = true
        storage.acceleratorArmor[race .. "tier6alegs"] = true
      end
    end
    
    self.passiveDamageMult = 1
    
    local damageMultAdd = 0
    
    -- TODO: try using tags
    damageMultAdd = damageMultAdd + (storage.acceleratorArmor[player.equippedItem("head").name] and 0.1 or 0)
    damageMultAdd = damageMultAdd + (storage.acceleratorArmor[player.equippedItem("chest").name] and 0.1 or 0)
    damageMultAdd = damageMultAdd + (storage.acceleratorArmor[player.equippedItem("legs").name] and 0.1 or 0)
    self.passiveDamageMult = 1 + damageMultAdd

  end
end

function Passive:update(dt, fireMode, shiftheld)
end

function Passive:uninit()

end