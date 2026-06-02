require "/scripts/util.lua"
require "/scripts/augments/item.lua"
require "/scripts/augments/dye.lua"

function apply(input)

  local output = Item.new(input)

  local modInfo = output:instanceValue("project45GunModInfo")

  if not modInfo then 
    -- sb.logInfo("Not Project 45 gun!")
    return
  end

  local dyeColorIndex = config.getParameter("dyeColorIndex")
  local ecoDye = output:instanceValue("ecoDye") and 0 or 1
  
  if dyeColorIndex and not output:instanceValue("disallowDyeing") then
    output:setInstanceValue("colorIndex", dyeColorIndex)
    output:setInstanceValue("project45GunModInfo", modInfo or {})
    output:setInstanceValue("isModded", true)
    return output:descriptor(), ecoDye
  else
    -- sb.logInfo("No dye color index or dyeing disallowed!")
  end
end
