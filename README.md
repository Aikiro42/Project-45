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
- Implement scope
- add hitscan knockback
- figure out how to utilize two animation scripts
    - Create your own custom `/items/buildscripts/abilities.lua`, import that into `items/buildscripts/buildproject45neo.lua`
    - Make `addAbilities` in the new `/items/buildscripts/abilities.lua` return the `animationScripts` of the abilities
    - In `buildproject45neo.lua`, add an a`altAnimationScripts` field to the item config
    - In `project45gun.lua`, when the gun is initialized, make it send the value of `altAnimationScripts` into the local animator via `activeItem.setScriptedAnimationParameter()`
    - In the animation script of the primary ability, code its `init()` function so that it requires the `altAnimationScripts`.

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
- <span style="color: yellow">Explosive Burst</span>
    - Requires elemental configuration; not thoroughly tested.
- <span style="color: green">Explosive Shot</span>
- <span style="color: blue">Flamethrower</span>
    - Added compatibility.
- <span style="color: green">Flashlight</span>
    - Note to self: base laser off this thing.
- <span style="color: green">Fuel Air Trail</span>
- <span style="color: green">Grenade Launcher</span>
- <span style="color: green">Guided Rocket</span>
    - Perfectly resembles synthetik mechanic.
- <span style="color: yellow">Homing Rocket</span>
    - Seemingly dysfunctional; it does shoot a rocket, but there aren't any indicators of it being guided.
- <span style="color: yellow">Lance</span>
    - May require elemental config; untested
- <span style="color: yellow">Marked Shot</span>
    - Functional, but missing animated elements.
- <span style="color: green">Piercing Shot</span>
- <span style="color: green">Rocket Burst</span>
- <span style="color: green">Shrapnel Bomb</span>
- <span style="color: green">Sparkles</span>
    - seems pointless
- <span style="color: green">Spray</span>
    - uses custom projectile
- <span style="color: green">Sticky Shot</span>

