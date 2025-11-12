require "/scripts/augments/item.lua"
require "/scripts/project45/project45disassemble.lua"
require "/scripts/set.lua"

function apply(input)

  local applicableWeapons = set.new(config.getParameter("applicableWeapons", {nil}))

  if applicableWeapons[input.name] then
    return disassemble(input, config.getParameter("transformItemId", "project45-neo-pistol")), config.getParameter("consume") == false and 0 or 1
  end

end