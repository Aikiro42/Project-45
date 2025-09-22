# New
- Added distinct chamber indicator sprites for ballistic, energy and experimental weapons. Some weapons are also given their own chamber indicators.
- Added the Pyroclast, a weapon that deals substantial fire damage but explodes and jams when you overcharge it.
- Added the Bullet Cutter, a barrel mod for ballistic weapons that increases multishot. Incompatible with ballistic shotguns and other certain ballistic weapons.

# Changes
- Changed name of Neo-Compound Bow to 'Neo-Penobscot Bow'.
- Improved Electric Ammo VFX
- Improved Energy Weapon SFX
- Demoted Magma Spitter into an SSR experimental weapon, and changed its item ID. Old Magma Spitters are marked with a red '(!)'; it is recommended you replace them with the changed Magma Spitter.
- The following projectiles have been given arming distances of 10 blocks:
  - The default projectiles of the Hand Mortar, Grenade Launcher and Rocket Launcher
  - Thermite Grenades
  - Cluster Grenades

# New (modders)
- added a way for passives to act on load and save state
- added a way for passives to force-jam a weapon
- added a crude way for passives to prevent a weapon from reloading.
- added a way for passives to determine the weapon's position
- added new projectiles
- added new macros:
  - /project45-guns-unique
  - /project45-guns-ballistic
  - /project45-guns-energy
  - /project45-guns-experimental
- added the 'print()' function to project45util
- added a projectile script that causes projectiles to execute different actionOnReaps depending on whether it surpassed the arming distance or not.
- added a new format for configuring quick reload timeframes beyond the array format, e.g.:
```
"quickReloadParameters": {
  "goodTime": 0.5,  // duration of good reload timeframe in seconds, will never be longer than reload time
  "perfectTime": 0.25,  // duration of perfect reload timeframe in seconds, will never be longer than goodTime
  "reloadOffsetRatio": 0.5,  // where along reload time should the quick reload bar center be
  "perfectOffsetRatio": 0.6  // where along reload time should the perfect offset ratio be
}
```

# Changes (modders)
- Passive init function is now called further down the main init function.

# Comments
- Kuva Bramma arrows were not given an arming distance; I've yet to decide how to balance this weapon -- for now, self-damage will be the tradeoff for using this unique weapon.