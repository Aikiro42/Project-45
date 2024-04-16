require "/scripts/set.lua"
require "/scripts/util.lua"
require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"

-- Generic Mod Application. All of the stuff in augment will be applied on the weapon.
function apply(input)

  local output = Item.new(input)
  local modInfo = output:instanceValue("project45GunModInfo")
  if not modInfo then return end

  local augment = config.getParameter("augment")
  if augment then
    
    -- apply augment stuff verbatim
    for k, v in pairs(augment) do
      output:setInstanceValue(k, sb.jsonMerge(input.parameters[k] or {}, v))
    end

    return output, 1


  end
end