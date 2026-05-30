# New
- Added the **Burstfire Receiver**, which makes weapons burstfire. This cannot be installed on manual-feed weapons.

# Changes
- Separated trigger time from the actual firing rate. That is, if you have an autofire gun that has a higher trigger time than the cycle time, the time it takes to start firing the weapon is longer than the time it takes for the weapon to fire subsequent shots.
- Added a visual indicator for long trigger cooldowns.

# Balance
- Increased the stat bonus provided by the multiplicative firetime mods fivefold.

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
