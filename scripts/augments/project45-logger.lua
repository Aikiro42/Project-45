require "/scripts/augments/item.lua"
require "/scripts/project45/project45util.lua"

function apply(input)
  local output = Item.new(input)
  sb.logInfo(project45util.sanitize(sb.printJson(output.config, 1)))
  sb.logInfo(project45util.sanitize(sb.printJson(input.parameters, 1)))
end