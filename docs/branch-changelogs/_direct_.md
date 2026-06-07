# New
- Added the **SMG-K**, a compact, more customizable version of the SMG.
# Fixes
- Made fixes to Reimburser UI

# Changes
- Improved Project 45 Configuration UI to be more informative.
- The projectile conversion mod now changes the weapon's projectile based on its category; ballistics will fire bullets, energy and experimentals fire lasers.
- Added VFX to reload and jam bars, affected by the Performance Mode setting.
- The Essential Gun Oil now causes any dye applied onto the weapon to be conserved and not consumed.
- Changed how recoil is applied onto the current weapon offset.

# Balance
- Reduced the damage multiplier provided per weapon level.
- Changed how supercrits are calculated:
  ```
  alpha = 0.4
  Scaling = BCD / (1 + alpha * (BCD - 1))
  FCD = BCD + ln(T) * Scaling
  ```
  where FCD is the Final Crit Damage, BCD is the Base Crit Damage and T is the crit Tier.

  This way, a Tier 1 crit is still consistently the BCD, and higher tiers increase the FCD with diminishing returns. The higher the BCD is, the harsher the diminishing; the damage increase from a T1 crit to a T2 crit is higher than the damage increase from a T7 crit to a T8 crit, and the damage increase from a T2 crit to a T3 crit is higher on a gun with 2x BCD than a gun with 4x BCD.

  Before this formula, a weapon with 300% CC and 5x CD can deal a minimum of 7x damage. Now, it deals ~6.6x damage.
  - Decreased reload Rating Multiplicative Damage for Good and Perfect Reloads from 1.25 to 1.125 and 1.5 to 1.25, respectively.
- Fixed how the damage multipler from stocking ammo is calculated.
- Changed how Melee Swipe damage is calculated.
  - Buffed the damage factors of the Bayonet Grip's swipes.
  - Nerfed the Underbarrel Chainsaw by removing its recoil stats and decreasing its per-tick damage from 0.5x to 0.3x.
- Nerfed the recoil recovery time and delay of Malorian Arms 3516. The low firerate of the gun allowed it to recover completely before the player can shoot again, ensuring consistent accurate fire, so I gave it a bit of recoil.
- Nerfed the God Mod by increasing its upgrade cost from 3 to 5 and decreasing its stack limit from 3 to 2.

# Fixes
- Fixed upgradeable guns still appearing in the upgrade anvil UI even after upgrading it.
- Fixed the Stasis status effect preventing entities from dying until the effect expires.

# New (Modders)
- Added a new evalFunction 'project45WeaponDamageLevelMultiplier' that linearly increases damage from1.2 to 1.8 based on weapon level.
- Added 'project45-testmod' for easily testing mods.

# Changes (Modders)
- Moved up the 'onReloadEnd' function so that it can determine the reload rating.
- Added a new 'reloadRating' parameter to the 'onLoadRound' function.