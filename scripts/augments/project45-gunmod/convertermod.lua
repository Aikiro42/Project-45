require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"

function apply(input)

  local conversion = config.getParameter("conversion")
  local output = Item.new(input)

  local primaryAbility = sb.jsonMerge(output.config.primaryAbility or {}, input.parameters.primaryAbility or {})
  
  -- Do not proceed if conversion is to same type
  if primaryAbility.projectileKind == conversion then
    sb.logError("(converter.lua) Conversion not applied; gun already fires " .. conversion)
    return
  end

  -- Do not proceed if conversion is invalid
  if not set.new({"projectile", "hitscan", "beam", "summoned"})[conversion] then
    sb.logError("(converter.lua) Invalid projectileKind: " .. conversion)
    return
  end

  sb.logInfo("(converter.lua) " .. sb.printJson(primaryAbility.projectileKind))
  primaryAbility.projectileKind = conversion  -- conversion must be a valid projectile kind

  output:setInstanceValue("primaryAbility", primaryAbility)

  return output
end