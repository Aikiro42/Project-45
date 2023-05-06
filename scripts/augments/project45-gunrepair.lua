require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)

  local output = Item.new(input)  
  -- Restore maximum ammo
  output:setInstanceValue("currentAmmo",input.parameters.primaryAbility and input.parameters.primaryAbility.maxAmmo or output.config.primaryAbility.maxAmmo)
  output:setInstanceValue("currentReloadRating", "good")
  output:setInstanceValue("currentJamAmount", 0)

  return output
end
