require "/objects/crafting/upgradeablecraftingobjects/upgradeablecraftingobject.lua"

local oldCurrentStageData = currentStageData or function() return {} end

function currentStageData()
  
  local res = oldCurrentStageData()

  -- this is stupid
  if res.magicNumber == "@aikiro42/project45" then
    res.interactData.filter = {
      "project45craftable-guns",
      "project45craftable-mods",
      "project45craftable-ammo",
      "project45craftable-stat",
    }
  end
  return res

end