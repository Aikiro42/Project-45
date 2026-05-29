# Changes
- Improved Project 45 Configuration UI to be more informative.

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


# New (Modders)
- Added a new evalFunction 'project45WeaponDamageLevelMultiplier' that linearly increases damage from1.2 to 1.8 based on weapon level.