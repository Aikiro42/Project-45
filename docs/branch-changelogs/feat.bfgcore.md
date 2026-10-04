# New
- Added the **Argent Core**, an energy projectile ammo mod that allows your gun to fire a BFG projectile, which damages and inflicts Doomed on nearby enemies. Firing a BFG projectile costs 30% of your max health.
  - Every 0.25 seconds, the projectile scans for entities to damage and adds them to a target queue.
  - Every 0.1 seconds, the projectile dequeues 1-3 entities from the target queue and damages them if they are still within range.
  - Bolts deal half the projectile's damage at maximum; this damage is further decreased based on the number of enemies the projectile has last scanned.
  - This ammo mod is craftable via the Replicator Gunsmith Addon.