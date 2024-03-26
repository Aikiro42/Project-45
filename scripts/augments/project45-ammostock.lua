require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)
  
  local output = Item.new(input)
  local modInfo = sb.jsonMerge(output.config.project45GunModInfo, input.parameters.project45GunModInfo)
  if not modInfo then return end
  
  local gunState = input.parameters.savedGunState or {
    chamber = "empty",
    bolt = "closed",
    gunAnimation = "idle",
    ammo = 0,
    stockAmmo = 0,
    reloadRating = 2,
    unejectedCasings = 0,
    jamAmount = 0,
    loadSuccess = false
  }
  local ammoAdd = config.getParameter("ammo", 0)
  
  local maxAmmo = (input.parameters.primaryAbility or {}).maxAmmo or (output.config.primaryAbility or {maxAmmo = ammoAdd}).maxAmmo or ammoAdd
  if gunState.stockAmmo >= maxAmmo * 3 then return end
  
  gunState.stockAmmo = math.min(maxAmmo * 3, gunState.stockAmmo + ammoAdd)
  output:setInstanceValue("savedGunState", gunState)

  return output

end
