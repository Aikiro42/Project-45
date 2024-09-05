require "/objects/crafting/upgradeablecraftingobjects/upgradeablecraftingobject.lua"

local oldCurrentStageData = currentStageData or function() return {} end

function currentStageData()
  
  local res = oldCurrentStageData()

  -- this is stupid
  if res.magicNumber == "@aikiro42/project45" then
    res.interactData.filter = {"project45craftable"}
  end
  return res

end