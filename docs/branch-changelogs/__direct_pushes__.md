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
- add a way for passives to act on load and save state
- add a way for passives to force-jam a weapon
- add a crude way for passives to prevent a weapon from reloading.
- add a way for passives to determine the weapon's position
- add new projectiles
- add new macros:
  - /project45-guns-unique
  - /project45-guns-ballistic
  - /project45-guns-energy
  - /project45-guns-experimental
- add the 'print()' function to project45util
- add a projectile script that causes projectiles to execute different actionOnReaps depending on whether it surpassed the arming distance or not.

# Changes (modders)
- Passive init function is now called further down the main init function.

# Comments
- Kuva Bramma arrows were not given an arming distance; I've yet to decide how to balance this weapon -- for now, self-damage will be the tradeoff for using this unique weapon.