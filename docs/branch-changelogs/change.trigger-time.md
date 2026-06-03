# TODO:
- [ ] fix recover time and recover delay stat mod calculation
- [ ] increase and diversify trigger times of all weapons.
- [ ] I'll make some mods increase or decrease trigger time.
  - [ ] energy muzzle mods
- [ ] add mod slots to weapons
  - project45-neo-pistol
  - project45-cbp-malorian
- [ ] I'll make new mods that decrease trigger time.
  - [x] Violium Trigger: heavyweight but responsive trigger that increases damage output
    - [ ] Titanium Electrigger
    - Decreases trigger time minimally
    - Increases crit chance
  - [x] Ferozium Trigger: mysterious trigger that assists in ammo-related concerns
    - [ ] Cerulium Electrigger
    - Decreases trigger time averagely
    - Decreases jam chance
    - Increases ammo efficiency (decreases ammo per shot, i.e. gives a chance to nnot consume bullets on fire)
  - [x] Aegisalt Trigger: lightweight trigger that assists shooter speed
    - [ ] Alloy Electrigger
    - Decreases trigger time greatly
    - Increases fire rate minimally, similar to T1
    - decreases recoil delay and recovery time
that does that.
  - [x] Ornate Hair trigger: themed after competition pistol triggers
    - Very costly
    - Eliminates trigger time (set to 1ms)
    - Increases recoil and inaccuracy when moving
  - [ ] Electromagnetic Ballistic Driver (Ballistic Barrel)
    - Mod that gives overcharge and increases substantial charge damage
    - Re-bases trigger time substantially (0.5ms)
  - [ ] Charge Stabilizer (Energy Magazine)
    - Increases trigger time
    - Increases reload rating damage
  - [ ] Internal Crystal Calibrator (Energy Receiver)
    - Increases trigger time
    - Provides charge time and increases overcharge damage above 1x
- [x] I'll cause fire time stat mods to ONLY affect the cycle time.
- [x] I'll make sure cycle time is truly separate from trigger time.
- [x] I'll make a burst fire gun mod that increases the burst count, and decreases cycle time but increases trigger time.

# New
- Added the **Burstfire Receiver**, which makes weapons burstfire. This cannot be installed on manual-feed weapons.
- Added the **Aegisalt, Ferozium, Violium and Ornate Triggers**, which decrease weapon trigger time. Can only be installed on ballistic weapons.

# Changes
- Separated trigger time from the actual firing rate. That is, if you have an autofire gun that has a higher trigger time than the cycle time, the time it takes to start firing the weapon is longer than the time it takes for the weapon to fire subsequent shots.
- Added an audiovisual indicator for trigger pressing and long trigger cooldowns

# Balance
- Increased the stat bonus provided by the multiplicative firetime mods fivefold.
- Nerfed the ergonomics (recoil recovery time and recovery delay) of the Malorian Arms 3516.

# New (Modders)
- Added a way to indicate mods with which a mod is incompatible:
    ```
    "augment": {
      ...
      "incompatibleMods": [...],
      ...
    }
    ```
  The mod checker checks each mod installed in the weapon if it is in this list; the application fails if it is.
  This list is also added to the weapon's 'project45GunModInfo.incompatibleMods' if the application succeeds.
- Added a parameter-checking feature for stat mods:
    ```
    "augment": {
      ...
      "stat": {
        "checks": [
          ...
        ],
        ...
      },
      ...
    }
    ```
  The implementation is imilar to that of gun mods, only this time the installation fails if the checks fail.