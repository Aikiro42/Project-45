require "/scripts/util.lua"
require "/scripts/augments/item.lua"
require "/scripts/augments/dye.lua"

function apply(input)
  local output = Item.new(input)

  if not output:instanceValue("project45GunModInfo") then return end

  local dyeColorIndex = config.getParameter("dyeColorIndex")
  
  if dyeColorIndex and not output:instanceValue("disallowDyeing") then
    output:setInstanceValue("colorIndex", dyeColorIndex)
    output:setInstanceValue("project45GunModInfo", {})
    output:setInstanceValue("isModded", true)
    return output:descriptor(), 1
  end
end
