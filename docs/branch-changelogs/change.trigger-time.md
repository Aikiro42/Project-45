# TODO:
- [ ] fix recover time and recover delay stat mod calculation
- [ ] increase and diversify trigger times of all weapons.
- [ ] I'll make some mods increase or decrease trigger time.
  - [ ] energy muzzle mods
- [ ] add mod slots to weapons
  - project45-neo-pistol
  - project45-cbp-malorian
- [ ] I'll make new mods that decrease trigger time.
  - [ ] Titanium Electrigger: heavyweight but responsive trigger that increases damage output
    - Decreases trigger time minimally
    - Increases crit chance
  - [ ] Cerulium Electrigger: mysterious trigger that assists in ammo-related concerns
    - Decreases trigger time averagely
    - Decreases jam chance
    - Increases ammo efficiency (decreases ammo per shot, i.e. gives a chance to nnot consume bullets on fire)
  - [ ] Alloy Electrigger: lightweight trigger that assists shooter speed
    - Decreases trigger time greatly
    - Increases fire rate minimally, similar to T1
    - decreases recoil delay and recovery time
that does that.

# New
- Added the **Burstfire Receiver**, which makes weapons burstfire. This cannot be installed on manual-feed weapons.
- Added the **Aegisalt, Ferozium, Violium and Ornate Triggers**, which decrease weapon trigger time. Can only be installed on ballistic weapons.
- Added the **Gauss Driver** and **Crystal Calibrator**, which give weapons some charge time for overcharge damage.
- Added the **Stabilizing Adapter**, an energy magwell mod that increases damage but also latency.

# Changes
- Separated trigger time from the actual firing rate. That is, if you have an autofire gun that has a higher trigger time than the cycle time, the time it takes to start firing the weapon is longer than the time it takes for the weapon to fire subsequent shots.
- Added an audiovisual indicator for trigger pressing and long trigger cooldowns

# Balance
- Increased the stat bonus provided by the multiplicative firetime mods fivefold.
- Nerfed the ergonomics (recoil recovery time and recovery delay) of the Malorian Arms 3516.

# Fixes
- Fixed script crash when attempting to install mods that affect cycle time on weapons that have windup cycle times (e.g. Minigun, Accelerator).

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