require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)
  
  local output = Item.new(input)

  if output:instanceValue("itemName") == "project45-ammostock" then
    if input.count > 1 then return end  -- do not stack on a stack of stock ammo

    local ammoStockLimit = root.assetJson("/configs/project45/project45_generalconfig.config:ammoStockLimit", 300)
    local oldAmmo = output:instanceValue("ammo")
    local addAmmo = config.getParameter("ammo", 0)
    
    -- do not stack if subject is at limit
    if oldAmmo >= ammoStockLimit then return end
    -- do not apply if stacking results to 300 and more, and added is more than old
    if addAmmo + oldAmmo > ammoStockLimit and addAmmo > oldAmmo then return end


    local newAmmo = oldAmmo + addAmmo
    newAmmo = math.min(ammoStockLimit, newAmmo)
    output:setInstanceValue("ammo", newAmmo)
    return output:descriptor(), 1
  end

  local modInfo = sb.jsonMerge(output.config.project45GunModInfo, input.parameters.project45GunModInfo)
  if not modInfo then return end
  
  local maxStockAmmoMult = root.assetJson("/configs/project45/project45_generalconfig.config:maxStockAmmoMult")

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
  if gunState.stockAmmo >= maxAmmo * maxStockAmmoMult then return end
  
  gunState.stockAmmo = math.min(maxAmmo * maxStockAmmoMult, gunState.stockAmmo + ammoAdd)
  output:setInstanceValue("savedGunState", gunState)

  return output:descriptor(), 1

end
