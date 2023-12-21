require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)
  local output = Item.new(root.createItem(input.name))
  sb.logInfo(sb.printJson(input))
  sb.logInfo(sb.printJson(output:descriptor()))
  sb.logInfo(sb.printJson(output.config.primaryAbility))
end
