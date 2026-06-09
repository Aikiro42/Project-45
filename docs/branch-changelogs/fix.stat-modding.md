# Change
- Rebasing the same stat now minimizes or maximizes the new base depending on whether the stat is considered "bad" or not. For example:
  - If you apply two mods that rebase the charge time (bad stat) of a weapon e.g. 5s and 10s, the base charge time of the weapon will become 5s. 
  - If you apply two mods that rebase the base damage (good stat) of a weapon e.g. 5 and 10, the base damage of the weapon will become 10.
# Fixes
- Fixed how bad negative multiplicative stat bonuses are calculated. That is, modding a stat in a way that its denominator ("d") bonus end up in the negatives used to divide the stat, potentially upgrading the actual parameter instead of downgrading; this behavior is fixed.
- Fixed issues with modding reload time.
- Fixed issues with applying ammo mods before other mods, especially those with checks.
# Changes (Modders)
- Changed how stats under the "ergonomics" group are treated by the modding system.