require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)

  local output = Item.new(input)  
  -- Restore maximum ammo

  local gunState = input.parameters.savedGunState or {
    chamber = "empty",
    bolt = "closed",
    gunAnimation = "idle",
    ammo = 0,
    reloadRating = 2,
    unejectedCasings = 0,
    jamAmount = 0,
    loadSuccess = false
  }

  output:setInstanceValue("currentAmmo",input.parameters.primaryAbility and input.parameters.primaryAbility.maxAmmo or output.config.primaryAbility.maxAmmo)
  output:setInstanceValue("currentReloadRating", "good")
  output:setInstanceValue("currentJamAmount", 0)

  gunState.ammo = input.parameters.primaryAbility and input.parameters.primaryAbility.maxAmmo or output.config.primaryAbility.maxAmmo
  gunState.reloadRating = 3
  gunState.jamAmount = 0

  output:setInstanceValue("savedGunState", gunState)

  return output
end
