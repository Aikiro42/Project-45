# Fixes
- Fixed how bad negative multiplicative stat bonuses are calculated. That is, modding a stat in a way that its denominator ("d") bonus end up in the negatives used to divide the stat, potentially upgrading the actual parameter instead of downgrading; this behavior is fixed.
- Fixed issues with modding reload time.

# Changes (Modders)
- Changed how stats under the "ergonomics" group are treated by the modding system.