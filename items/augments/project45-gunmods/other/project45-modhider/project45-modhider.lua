require "/scripts/augments/item.lua"
require "/scripts/project45/project45util.lua"

function apply(input)
  local output = Item.new(input)
  local gunModInfo = output:instanceValue("project45GunModInfo")
  if not gunModInfo then return end
  gunModInfo.hiddenSlots = {"rail", "sights", "muzzle", "underbarrel", "stock"}
  output:setInstanceValue("project45GunModInfo", gunModInfo)
  return output
end