# Gun Mechanics
## Ammo System and Reloading (CORE FEATURE)
- Guns consume ammo, which can be replenished via reloading.

### No ammo, Mag On
- If the player has enough energy to do a reload, the mag is ejected.

### No magazine
- If the player has enough energy to do a reload, the reload sequence begins.

### Reload Sequence
1. A bar appears beside the cursor, and an indicator goes up along that bar.
    - The bar has three distinct regions: bad (white), good (dark purple) and perfect ()
    

- When a gun is out of ammo, and the player attempts to fire it, The gun first ejects its mag.
- When the gun does not have a magazine and the player attempts to fire it, the reload sequence begins.
- A bar appears beside the cursor that has two distinct regions:
    - "Bad reload" region
    - "Good reload" region
    - "Perfect reload" region
- An indicator moves up the bar at a speed dependent on the gun's supposed reload time.

# Gun Properties
## Damage
- Per-shot Damage
    - If a gun shoots multiple projectiles, the damage is distributed between them
    - There is the concept of multishot: a gun can shoot n times the projectiles it shoots, but the damage isn't diluted
    - The per-shot damage is affected by how well the gun was reloaded 
        - If the gun is reloaded perfectly, 
- Shots deal 