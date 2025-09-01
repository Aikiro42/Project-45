# `change/firetime-rework`

## TODO
- [ ] add reload time mods to treasure pools; do this after reworking the drop system

## New
- Firetime is now divided into its constituents: charge time, cycle/cock time and trigger time. This should make it clear how fast guns can dole out damage.
- Added dedicated labels for charge and trigger time on the gun tooltip.
- Added mods that modify the gun's cocking and reload time

## Balance
- cock time and mid-cock delay stat modifications are now separated from fire time stat modification, and joined into reload time stat modification
- changed fire time stat mod numbers so that the approximate breakpoint at which multiplicative mods are more beneficial than additive mods is at 500ms (cycle/cock time).
- changed how fire time stat mods are applied; instead of divvying up the additive cycle time modifier, the modifier is directly added to all aspects of the gun's firing time (cycleTime, chargeTime and overchargeTime, and fireTime a.k.a. trigger time)

## New (Modders)
- add new macro to spawn in fire time mods for testing