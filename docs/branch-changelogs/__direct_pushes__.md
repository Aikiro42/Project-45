# New
- Added distinct chamber indicator sprites for ballistic, energy and experimental weapons
- Added the Pyroclast, a weapon that deals substantial fire damage but explodes and jams when you overcharge it.
- Added the Bullet Cutter, a barrel mod for ballistic weapons that increases multishot. Incompatible with ballistic shotguns and other certain ballistic weapons.

# Changes
- Improved Electric Ammo VFX
- Improved Energy Weapon SFX

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

# Changes (modders)
- Passive init function is now called further down the main init function.