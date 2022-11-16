# Project-45
I have a single question:

Do you... enjoy violence?

Of course you do.

It's a... part of you~

And who are you... to deny your own nature?

So come with me

and let me show you

some real. ultra. violence.

And let's dehumanize ourselves together.

Welcome... to Project 45.

## Todo

- Add generic bullet hit sounds to the hitscan explosion config
- Add bullet sounds to the damage type:
    - organic (visceral)
    - stone
    - wood
    - robotic (metallic)
- add hitscan knockback
- figure out how to utilize two animation scripts
- Add no-movement requirement to firing weapons
- Add new guns:
    - Sniper Rifle (Mag-fed, Bolt-action)
        - should feature bolt-action mechanic
    - Grenade Launcher
        - should feature firing projectiles
    - AMR (Single-shot bolt-action)
        - should feature single-shot mechanic
    - Charge rifle ((Over)Charged, semi)
        - should feature chargeup and overcharge mechanic
        - Optional: auto-fire-after-charge rifle, resets charge every shot
    - Gatling Gun
        - should feature windup and whirring
    - Revolver
        - should feature kept bulletcases.
    - Garand
        - should feature clip mags (eject on empty)
    - Mosin Nagant
        - should feature strip mags (appear only on reload)

## Vanilla Altfires Compatibility List:
- <span style="color: green">Bouncing Shot</span>
- <span style="color: green">Burst Shot</span>
- <span style="color: yellow">Charge Fire</span>
    - Somewhat; you still need to add in the charge levels for chargefire to work. Haven't tested.
- <span style="color: green">Death Bomb</span>
    - I honestly don't know what this is supposed to do, but it shoots darts and it works somehow.
- <span style="color: red">Erchius Beam</span>
    - Incompatible; intended to be used on the Erchius Eye.
- <span style="color: green">Erchius Launcher</span>
- <span style="color: green">Explosive Burst</span>
    - Requires activeItem "elementalType" field.
- <span style="color: green">Explosive Shot</span>
- <span style="color: green">Flamethrower</span>
    - Added compatibility.
- <span style="color: green">Flashlight</span>
    - Note to self: base laser off this thing.
- <span style="color: green">Fuel Air Trail</span>
- <span style="color: green">Grenade Launcher</span>
- <span style="color: green">Guided Rocket</span>
    - Perfectly resembles synthetik mechanic.
- <span style="color: red">Homing Rocket</span>
    - Seemingly dysfunctional; it does shoot a rocket, but there aren't any indicators of it being guided.
- <span style="color: green">Lance</span>
    - Requires activeItem "elementalType" field.
- <span style="color: red">Marked Shot</span>
    - Functional, but missing animated elements.
- <span style="color: green">Piercing Shot</span>
- <span style="color: green">Rocket Burst</span>
- <span style="color: green">Shrapnel Bomb</span>
- <span style="color: green">Sparkles</span>
    - seems pointless
- <span style="color: green">Spray</span>
    - uses custom projectile
- <span style="color: green">Sticky Shot</span>

## Experiment

### Problem
I can't use more than one animation script on the gun.

### Goal
Use more than one animation script on the gun.

### Methodology
1. Create custom `/items/buildscripts/abilities.lua`, import that into `items/buildscripts/buildproject45neo.lua`

2. Make `addAbilities` and `setupAbilities` in the new `/items/buildscripts/abilities.lua` return the `animationScripts` of the abilities:

    ```lua

    -- Adds the new ability to the config (modifying it)
    -- abilitySlot is either "alt" or "primary"
    function addAbility(config, parameters, abilitySlot, abilitySource)
    if abilitySource then
        local abilityConfig = root.assetJson(abilitySource)
        
        -- sb.logInfo("[PROJECT 45] (project45abilities.lua) setupAbility() : " .. sb.printJson(abilityConfig.animationScripts))
        local retAnimScripts = {}
        util.mergeTable(retAnimScripts, abilityConfig.animationScripts)

        -- Stuff
        sb.logInfo("[PROJECT 45] (project45abilities.lua)" .. sb.printJson(abilityConfig.animationScripts))

        -- Rename "ability" key to primaryAbility or altAbility
        local abilityType = abilityConfig.ability.type
        abilityConfig[abilitySlot .. "Ability"] = abilityConfig.ability
        abilityConfig.ability = nil

        -- Allow parameters in the activeitem's config to override the abilityConfig
        local newConfig = util.mergeTable(abilityConfig, config)
        util.mergeTable(config, newConfig)

        parameters[abilitySlot .. "AbilityType"] = abilityType
        
        -- Return the animationScripts
        return retAnimScripts
    end
    return {}
    end

    -- Determines ability from config/parameters and then adds it.
    -- abilitySlot is either "alt" or "primary"
    -- If builderConfig is given, it will randomly choose an ability from
    -- builderConfig if the ability is not specified in the config/parameters.
    function setupAbility(config, parameters, abilitySlot, builderConfig, seed)
    seed = seed or parameters.seed or config.seed or 0

    local abilitySource = getAbilitySource(config, parameters, abilitySlot)
    if not abilitySource and builderConfig then
        local abilitiesKey = abilitySlot .. "Abilities"
        if builderConfig[abilitiesKey] and #builderConfig[abilitiesKey] > 0 then
        local abilityType = randomFromList(builderConfig[abilitiesKey], seed, abilitySlot .. "AbilityType")
        abilitySource = getAbilitySourceFromType(abilityType)
        end
    end

    if abilitySource then
        return addAbility(config, parameters, abilitySlot, abilitySource)
    end
    end
    ```

3. In `buildproject45neo.lua`, add an a`altAnimationScripts` field to the item config:
    ```lua
    function build(directory, config, parameters, level, seed)
        local configParameter = function(keyName, defaultValue)
            if parameters[keyName] ~= nil then
            return parameters[keyName]
            elseif config[keyName] ~= nil then
            return config[keyName]
            else
            return defaultValue
            end
        end

        if level and not configParameter("fixedLevel", true) then
            parameters.level = level
        end

        sb.logInfo("[PROJECT 45] Adding stuff...")
        
        local primaryAnimationScripts = setupAbility(config, parameters, "primary")
        local altAnimationScripts = setupAbility(config, parameters, "alt")
        
        sb.logInfo("[PROJECT 45] (buildproject45neo.lua) retrieved altAnimationScripts: " .. sb.printJson(altAnimationScripts))
        
        -- TODO: Make sure the altAnimationScripts are passed to the config properly; copy it?
        config.altAnimationScripts = {}
        util.mergeTable(config.altAnimationScripts, altAnimationScripts or {})
        
        sb.logInfo("[PROJECT 45] (buildproject45neo.lua) config.altAnimationScripts = " .. sb.printJson(config.altAnimationScripts))
        --]]

        -- elemental type and config (for alt ability)
        local elementalType = configParameter("elementalType", "physical")
        replacePatternInData(config, nil, "<elementalType>", elementalType)
        if config.altAbility and config.altAbility.elementalConfig then
            util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
        end

        -- calculate damage level multiplier
        config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

        -- palette swaps
        config.paletteSwaps = ""
        if config.palette then
    ```

4. In `project45gun.lua`, when the gun is initialized, make it send the value of `altAnimationScripts` into the local animator via `activeItem.setScriptedAnimationParameter()`:
    ```lua
    function init()
        activeItem.setCursor("/cursors/reticle0.cursor")
        animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

        self.weapon = Weapon:new()

        sb.logInfo("[PROJECT 45] (project45gun.lua) animationScripts:" .. sb.printJson(config.getParameter("animationScripts")))
        sb.logInfo("[PROJECT 45] (project45gun.lua) altAnimationScripts:" .. sb.printJson(config.getParameter("altAnimationScripts")))
        
        activeItem.setScriptedAnimationParameter("altAnimationScripts", config.getParameter("altAnimationScripts", {}))
        -- activeItem.setScriptedAnimationParameter("primaryAnimScripts", config.getParameter("animationScripts", {}))

        self.weapon:addTransformationGroup("weapon", {0,0}, 0)
        self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)
    ```


5. In the animation script of the primary ability, code its `init()` function so that it requires the `altAnimationScripts`:
```lua
function init()
  
  local altAnimScripts = animationConfig.animationParameter("altAnimationScripts")
  -- local primaryAnimScripts = animationConfig.animationParameter("primaryAnimScripts")

  -- oldUpdate = update
  sb.logInfo("[PROJECT 45] (syntheticmechanicsanimation.lua) REQUIRING SCRIPT: " .. altAnimScripts[1])
  require(altAnimScripts[1])

  -- sb.logInfo("[PROJECT 45] (syntheticmechanicsanimation.lua) REQUIRING SCRIPT: " .. primaryAnimScripts[1])
  -- require(primaryAnimScripts[1])
  
end
```

6. Do stuff