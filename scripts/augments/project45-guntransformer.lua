require "/scripts/augments/item.lua"
require "/scripts/project45/project45disassemble.lua"
require "/scripts/set.lua"

function apply(input)

  local applicableWeapons = set.new(config.getParameter("applicableWeapons", {nil}))

  if applicableWeapons[input.name] then
    return disassemble(
      input,
      config.getParameter("itemName", nil),  -- should never be nil
      config.getParameter("transformItemId", "project45-neo-pistol")
    ), 1  -- transformer is always consumed
  end

end