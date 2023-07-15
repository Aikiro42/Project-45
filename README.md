# TODO:

- Fix flamethrower sounds

# Project-45

> I have a single question:
> 
> Do you... enjoy violence?
> 
> Of course you do.
> 
> It's a... part of you~
> 
> And who are you... to deny your own nature?
> 
> So come with me
> 
> and let me show you
> 
> some real. ultra. violence.
>
> And let's dehumanize ourselves together.
> 
> Welcome... to Project 45.

## About

Project 45 is a weapons system that attempts to replicate the gun mechanics of Synthetik. This modding utility features:
- Template guns you can base your custom weapons from
- A reload mechanic extremely reminiscent of that of Synthetik's.
- 

## Credits

---

## Todo

## Todo - abilities
- Drone
    - lets a drone fly around and target nearby enemies
    - make projectile modifiable, make it able to fire hitscans
- Melee Swipe
    - projectile that looks like a melee swipe
    - high-damage melee swipe but short range.
- Cover
    - status effect that impedes movement but renders user invisible
    - generate shield

## Todo - Mods
- Multithreader (receiver)
    - Applicable for energy weapons,
    - makes gun do autofire
- Overcharged Battery (magazine)
    - Applicable for energy weapons
    - doubles gun ammo capacity
- Beam Splitter (barrel)
    - Applicable for energy weapons
    - increases projectile count and spread
- Double Slit (muzzle)
    - increases multishot
- Pneumatic Mechanism (receiver)
    - increases projectile time to live and range
## Todo - Guns
- ~~M249 SAW~~
- AA12
- Shotgun energy rifle
- Break-action shotgun
- Plasma Launcher
- Energy Grenade Launcher

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
- <span style="color: green">Fuel Air Trail</span>
- <span style="color: yellow">Grenade Launcher</span>
    - Knocks off aim by a bit.
- <span style="color: green">Guided Rocket</span>
    - Perfectly resembles synthetik mechanic.
- <span style="color: red">Homing Rocket</span>
    - Seemingly dysfunctional; it does shoot a rocket, but there aren't any indicators of it being guided.
    - Seems to only work with certain rocket launchers.
- <span style="color: green">Lance</span>
    - Requires activeItem "elementalType" field.
- <span style="color: green">Marked Shot</span>
    - ~~Functional, but missing animated elements.~~ Functional and compatible with synthetikmechanics via altering buildscripts.
- <span style="color: green">Piercing Shot</span>
- <span style="color: green">Rocket Burst</span>
- <span style="color: green">Shrapnel Bomb</span>
- <span style="color: green">Sparkles</span>
    - seems pointless
- <span style="color: green">Spray</span>
    - uses custom projectile
- <span style="color: green">Sticky Shot</span>

# Known Issues
- > by the way, here’s an odd quirk that happens with sending a vanilla “applyStatusEffect” message to entities - if the player somehow has greater than 60 frames per second, the sent message straight up doesn’t work. had it happen to something for GiC; although you’re making your own message handler, there’s still a decent chance this bug can still occur, depending on what exactly triggers this bug. be ready to acknowledge this bug should it occur.

- Bullet trails, lasers, and bars disappear when near world borders.

- Ammo resets when adding gun to hotbar, but not when removing it.


# Experiments


## Mod Tags

### Problem
We need a way to reliably filter which mods go on which

### Definition of Terms
- 

### Requirements
- 

### Possible Solution: Ammo Info System

guns and `ammoType` mods have an `ammoInfo` field:

```jsonc
// ...
"modInfo": {
    "ammoDimensions": [40, 100],
    // set either dimension to -1 if a gun accepts any length of one dimensino, or if an ammo fits either
    // the first is the girth of the bullet - for the gun to accept the ammo, both girths must be equal.
    // the second is the length of the bullet - for the gun to accept the ammo, the bullet's dimension must be less than that of the gun
    
    "type": "ballistic",
    // "ballistic", "energy", "gas"

    "acceptsModSlot": {
        // ...
    }
}
// ...
```

## Retrieving alt ability animation scripts

### Problem
I can't use more than one animation script on the gun.

### Goal
Use more than one animation script on the gun. ACHIEVED!

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
        -- sb.logInfo("[PROJECT 45] (project45abilities.lua)" .. sb.printJson(abilityConfig.animationScripts))

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

        -- sb.logInfo("[PROJECT 45] Adding stuff...")
        
        local primaryAnimationScripts = setupAbility(config, parameters, "primary")
        local altAnimationScripts = setupAbility(config, parameters, "alt")
        
        -- sb.logInfo("[PROJECT 45] (buildproject45neo.lua) retrieved altAnimationScripts: " .. sb.printJson(altAnimationScripts))
        
        -- TODO: Make sure the altAnimationScripts are passed to the config properly; copy it?
        config.altAnimationScripts = {}
        util.mergeTable(config.altAnimationScripts, altAnimationScripts or {})
        
        -- sb.logInfo("[PROJECT 45] (buildproject45neo.lua) config.altAnimationScripts = " .. sb.printJson(config.altAnimationScripts))
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

4. Patch the animation script of the primary weaponability on the animation script of the alt weaponability.

## Experiment: Alternative Hitscan Method
```lua
-- synthetikmechanics.lua

-- Utility function that scans for entities to damage.
function SynthetikMechanics:hitscan(isLaser)

  local scanOrig = self:firePosition()
  local hitscanRange = 100 -- block range of hitscan
  local ignoresTerrain = false
  
  local scanDest = vec2.add(scanOrig, vec2.mul(self:aimVector(self.inaccuracy), hitscanRange))
  local fullScanDest = not ignoresTerrain and world.lineCollision(scanOrig, scanDest, {"Block", "Dynamic"}) or scanDest

  local punchThrough = 0 -- number of entities to penetrate before hitscan line terminates

  -- query hittable entities
  local hitId = world.entityLineQuery(scanOrig, scanDest, {
    withoutEntityId = entity.id(),
    includedTypes = {"monster", "npc", "player"},
    order = "nearest"
  })

  local penetrated = 0

  -- if entities are hit,
  if #hitId > 0 then
    -- for each entity hit
    for i, id in ipairs(hitId) do
      if world.entityCanDamage(entity.id(), id)
      and world.entityDamageTeam(id) ~= "ghostly" -- prevents from hitting those annoying floaty things
      then
        -- let scan destination be location of entity and correct it
        -- by rotating the resulting vector
        local aimAngle = vec2.angle(world.distance(scanDest, scanOrig))
        local entityAngle = vec2.angle(world.distance(world.entityPosition(id), scanOrig))
        local rotation = aimAngle - entityAngle
        
        scanDest = vec2.rotate(world.distance(world.entityPosition(id), scanOrig), rotation)
        scanDest = vec2.add(scanDest, scanOrig)

        penetrated = penetrated + 1

        if penetrated > (punchThrough) then break end
      end
    end
  end

  if penetrated <= punchThrough then scanDest = fullScanDest end
  
  return {scanOrig, scanDest}
end

function SynthetikMechanics:fireHitscan(projectileType)

    -- scan hit down range
    -- hitreg[1] is where the bullet trail emanates,
    -- hitreg[2] is where the bullet trail terminates
    local hitReg = self:hitscan()
    local crit = self:crit()

    local damageConfig = {
      -- we included activeItem.ownerPowerMultiplier() in
      -- self:damagePerShot() so we cancel it
      baseDamage = self:damagePerShot() * crit / activeItem.ownerPowerMultiplier(),
      timeout = 0,
      damageSourceKind = "synthetikmechanics-hitscan" .. (crit > 1 and "crit" or "")
    }

    -- coordinates are based off mcontroller position
    self.weapon:setOwnerDamageAreas(damageConfig, {{
      vec2.sub(hitReg[1], mcontroller.position()),
      vec2.sub(hitReg[2], mcontroller.position())
    }})
    
    -- ...vfx...

end

```

## Worldify Function
```lua

-- Calculates the line from pos1 to pos2
-- that allows `localAnimator.addDrawable()`
-- to render it correctly
function worldify(pos1, pos2)

    local playerPos = activeItemAnimation.ownerPosition()
    local worldLength = world.size()[1]
    local fucky = {false, true, true, false}
    
    -- L is the x-size of the world
    -- |0|--[1]--|--[2]--|L/2|--[3]--|--[4]--|L|
    -- there is fucky behavior in quadrants 2 and 3
    local pos1Quadrant = math.ceil(4*pos1[1]/worldLength)
    local playerPosQuadrant = math.ceil(4*playerPos[1]/worldLength)

    local ducky = fucky[pos1Quadrant] and fucky[playerPosQuadrant]
    local distance = world.distance(pos2, pos1)

    local sameWorldSide = (pos1Quadrant > 2) == (playerPosQuadrant > 2)
        
    if ducky then
        if (
            (sameWorldSide and (pos1Quadrant > 2))
            or (pos1Quadrant < playerPosQuadrant)
        ) then
            pos1[1] =  pos1[1] - worldLength
        end
    else
        if pos1[1] > worldLength/2 then
            pos1[1] = pos1[1] - worldLength
        end
    end

    pos2 = vec2.add(pos1, distance)

    pos1 = vec2floor(pos1)
    pos2 = vec2floor(pos2)

    return {pos1, pos2}
end
```