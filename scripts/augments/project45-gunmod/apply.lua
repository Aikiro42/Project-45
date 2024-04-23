require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

require "/scripts/augments/project45-gunmod/gunmod.lua"
applyGunmod = apply

require "/scripts/augments/project45-gunmod/abilitymod.lua"
applyAbilitymod = apply


require "/scripts/augments/project45-gunmod/convertermod.lua"
applyConversion = apply

require "/scripts/augments/project45-gunmod/ammomod.lua"
applyAmmomod = apply

require "/scripts/augments/project45-gunmod/passivemod.lua"
applyPassivemod = apply

require "/scripts/augments/project45-gunmod/statmod.lua"
applyStatmod = apply

-- General mod application script

function apply(input)

  local checker = Checker:new(input, config)

  -- SECTION: CHECKS
  checker:check()
  if checker.augment.ability then
    checker:checkAbility()
  end
  if checker.augment.conversion then
    checker:checkConversion()
  end
  if checker.augment.ammo then
    checker:checkAmmo()
  end
  if checker.augment.stat then
    checker:checkStat()
  end
  if not checker:check() then
    return checker:getErrorOutputItem(), 0
  end

  -- SECTION: APPLICATION

  local newModSlots = sb.jsonMerge({}, checker.modSlots) -- deep copy

  if checker.augment.ability then
    --[[
        "ability": {
            "altAbilityType": string,
            "overrideTwoHanded": bool,
            "twoHanded": bool,
            "altAbility": {json},
            "hasShiftAction": bool
        }
        --]]
    checker.output = applyAbilitymod(checker.output:descriptor(), checker.augment.ability)
    newModSlots.ability = {checker.augment.modName, config.getParameter("itemName")}
  end

  if checker.augment.gun then
    --[[
        "gun": {
            "primaryAbility": {
                
                field <string>: {
                    "operation": string,
                    "value": any
                },

                field <string>: [
                    {
                        "operation": string,
                        "value": any
                    },
                    {
                        "operation": string,
                        "value": any
                    },
                    ...
                ],
                ...
                
            },
            "animationCustom": {json}
            "sprite": {
                "offset": [float, float],
                "imageFullbright": string,
                "zLevel": int,
            }
            "muzzleOffset": [float, float],
            "enableModSlots": string[],
            "enableAmmoTypes": string[],
            "enableAmmoArchetypes": string[]
        }
        --]]
    checker.output = applyGunmod(checker.output:descriptor(), checker.augment.gun)
  end

  if checker.augment.conversion and checker.conversionNecessary then
    --[[
    "conversion": string
    --]]
    checker.output = applyConversion(checker.output, checker.augment.conversion)
    if not checker.augment.ammo then
      newModSlots.ammoType = {checker.augment.modName, config.getParameter("itemName"),
      config.getParameter("tooltipFields", {}).objectImage or config.getParameter("inventoryIcon")}  
    end
  end

  if checker.augment.ammo then
    --[[
    "ammo": {
      "projectileKind": string | null,
      
      "projectileType": string,
      
      "summonedProjectileType": string,
      "summonedProjectileParameters": {json}
      
      "hitscanParameters": {json}
      
      "beamParameters": {json}

      "multishot": float,
      "projectileCount": int,
      "spread": float,

      "hideMuzzleFlash": bool,
      "hideMuzzleSmoke": bool,
      "muzzleFlashColor": [r<int>, g<int>, b<int>] | [r<int>, g<int>, b<int>, a<int>],
      "customSounds": {
        sound<string>: paths<string[]>,
        ...
      }

      
    }
    --]]
    checker.output = applyAmmomod(checker.output, checker.augment.ammo)
    newModSlots.ammoType = {checker.augment.modName, config.getParameter("itemName"),
    config.getParameter("tooltipFields", {}).objectImage or config.getParameter("inventoryIcon")}
  end

  if checker.augment.passive then
    checker.output = applyPassivemod(checker.output:descriptor(), checker.augment.passive)
    newModSlots.passive = {checker.augment.modName, config.getParameter("itemName")}
  end

  if checker.augment.stat then
    checker.output = applyStatmod(checker.output:descriptor(), checker.augment.stat)
  end

  -- MODIFICATION POST-MORTEM
  -- add mod info to list of installed mods

  newModSlots[checker.augment.slot] = {checker.augment.modName, config.getParameter("itemName")}

  local needImage = set.new({"rail", "sights", "underbarrel", "muzzle", "stock"})
  if needImage[checker.augment.slot] then
    table.insert(newModSlots[checker.augment.slot], config.getParameter("inventoryIcon"))
  end

  checker.output:setInstanceValue("modSlots", modSlots)
  checker.output:setInstanceValue("upgradeCount", upgradeCount + upgradeCost)
  checker.output:setInstanceValue("isModded", true)

  return checker.output:descriptor(), 1

end
