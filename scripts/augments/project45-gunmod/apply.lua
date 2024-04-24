require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"
require "/scripts/augments/project45-gunmod/check.lua"

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

  if checker.augment.ability and checker.checked then
    checker:checkAbility()
    sb.logInfo("abilityChecked")
  end
  if checker.augment.conversion and checker.checked then
    checker:checkConversion()
    sb.logInfo("conversion")

  end
  if checker.augment.ammo and checker.checked then
    checker:checkAmmo()
    sb.logInfo("ammo")

  end
  if checker.augment.passive and checker.checked then
    checker:checkPassive()
    sb.logInfo("passive")

  end

  if checker.augment.stat and checker.checked then
    checker:checkStat()
    sb.logInfo("stat")

  end

  if not checker.checked then
    return checker:getErrorOutputItem(), 0
  end
  -- SECTION: APPLICATION

  --[[
  "augment": {
    "modName": string (optional),
    "incompatibleWeapons": string[] (optional),
    "compatibleWeapons": string[] (optional),
    "exclusiveCompatibility": bool (optional),
    "category": "universal" | "ballistic" | "energy" | "experimental"
    "slot": string,
    "cost": int,
    "pureStatMod": bool (optional), // dictates how the mod is logged; invalidates all mod fields but "stat" if true


    // all fields optional
    "ability": {json},
    "gun": {json},
    "conversion": string,
    "ammo": {json},
    "passive": {json}
    "stat": {json}
  }
  --]]
  local pureStatMod = checker.augment.pureStatMod or config.getParameter("modCategory") == "statMod"
  if pureStatMod then
    checker.augment.ability = nil
    checker.augment.gun = nil
    checker.augment.conversion = nil
    checker.augment.ammo = nil
    checker.augment.passive = nil
  end
  local newModSlots = sb.jsonMerge({}, checker.modSlots) -- deep copy
  local passiveSlot = checker.augment.slot or "passive"
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
    checker.output = applyAbilitymod(checker.output, checker.augment.ability)
    newModSlots.ability = {checker.augment.modName, config.getParameter("itemName")}
    passiveSlot = checker.augment.slot
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
    checker.augment.gun.slot = checker.augment.slot -- needed for sprite
    checker.output = applyGunmod(checker.output, checker.augment.gun)
    passiveSlot = checker.augment.slot
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
    passiveSlot = checker.augment.slot
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

      // WARNING: THESE CAN BE MODIFIED IN THE STAT APPLICATION
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
    newModSlots.ammoType = {
      checker.augment.modName,
      config.getParameter("itemName"),
      config.getParameter("tooltipFields", {}).objectImage or config.getParameter("inventoryIcon")
    }
    passiveSlot = checker.augment.slot
  end

  if checker.augment.passive then
    --[[
    "passive": {
      "passiveScript": absolute_path<string>,
      "passiveParameters": {json}
      "overrideShiftAction": bool,
      "passiveDescription": string,
      "animationCustom": {json},
    }
    --]]
    checker.output = applyPassivemod(checker.output, checker.augment.passive)
    if not newModSlots[passiveSlot] then
      newModSlots[passiveSlot] = {checker.augment.modName, config.getParameter("itemName")}
    end
  end

  if checker.augment.stat then
    --[[
    "stat": {
      "randomStats": bool,
      
      stat<string>: {
        "rebase": number
        "additive": float,
        "multiplicative": float
      }
      ...
    }
    --]]
    
    checker.output = applyStatmod(checker.output, checker.augment.stat)

    -- count stat if not wildcard
    if pureStatMod then
      if not checker.augment.stat.randomStats then
        checker.statList[config.getParameter("itemName")] = (checker.statList[config.getParameter("itemName")] or 0) + 1
      else
        local retrievedSeed = config.getParameter("seed")
        table.insert(checker.statList.wildcards, retrievedSeed)
      end
      checker.output:setInstanceValue("statList", checker.statList)
    end
  end

  -- MODIFICATION POST-MORTEM
  -- add mod info to list of installed mods

  -- if modslot is occupied then somewhere along the line it's already been tracked
  if not newModSlots[checker.augment.slot] and not pureStatMod then
    newModSlots[checker.augment.slot] = {checker.augment.modName, config.getParameter("itemName")}
  end

  local needImage = set.new({"rail", "sights", "underbarrel", "muzzle", "stock"})
  if needImage[checker.augment.slot] then
    table.insert(newModSlots[checker.augment.slot], config.getParameter("inventoryIcon"))
  end

  checker.output:setInstanceValue("modSlots", newModSlots)
  checker.output:setInstanceValue("upgradeCount", checker.output:instanceValue("upgradeCount", 0) + checker.augment.cost)
  checker.output:setInstanceValue("isModded", true)

  return checker.output:descriptor(), 1

end
