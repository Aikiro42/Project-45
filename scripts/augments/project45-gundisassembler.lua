require "/scripts/augments/item.lua"
require "/scripts/project45/project45disassemble.lua"

function apply(input)

  return disassemble(input), config.getParameter("consume") == false and 0 or 1
  
end