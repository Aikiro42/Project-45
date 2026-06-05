# TODO:
- [x] increase and diversify trigger times of all weapons.
- [x] I'll make some mods increase or decrease trigger time.
  - [ ] energy muzzle mods
- [x] add mod slots to weapons
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
- Diversified trigger times of the following weapons (from 0.01s, unless specified otherwise):
  - Accelerator: 0.3s
  - AMR: 0.2s
  - Assault Rifle: 0.3s (from 0.25s)
  - Autocannon: 1s
  - Beam gun: 0.3s
  - Beamsplitter: 0.1s
  - Carbine: 0.1s
  - Combat Rifle: 0.1s
  - Covalence: 0.1s
  - Cyclo: 0.1s
  - Hand Cannon: 0.25s
  - Flamethrower: 1s
  - Gauss Rifle: 0.3s
  - Gazer: 0.15s
  - Grenade Launcher: 0.1s
  - Handmade Rifle: 0.1s
  - Hand Mortar: 0.05s
  - Hunting Rifle: 0.1s
  - Machine Gun: 0.3s
  - Rocket Launcher: 0.2s
  - Sawblader: 0.2s
  - Service Rifle: 0.05s
  - Shotgun: 0.05s
  - Smart Gun: 0.1s
  - Submachine Gun: 0.1s
  - Sniper: 0.1s
  - TMP: 0.05s
  - Wristgun: 0.05s,
  - Boltgun: 0.1s
  - Auto-9: 0.2s
  - MAXX Assault Rifle: 0.05s
  - Bone Shooter: 0.2
  - Marco's HMG: 0.001s
  - The Protector: 0.05s
  - Typhon P45: 0.3s
- Changed cycle time of Marco's HMG from 0.005s to 0.05s.
- Changed cycle time of the Ultrakill Revolver from 0.24s to 0.2s.
- Added trigger time affects on the following mods:
  - Multithreader
  - Fire time stat mods
  - Beginner mod

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