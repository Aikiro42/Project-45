require "/scripts/augments/item.lua"
require "/scripts/util.lua"

function apply(input)
  local output = Item.new(input)
  output:setInstanceValue("elementalType", util.randomFromList({"fire", "electric", "poison", "ice"}))
  return output
end