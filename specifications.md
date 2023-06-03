# Gun Mechanics
## Ammo System and Reloading (CORE FEATURE)
- Guns consume ammo, which can be replenished via reloading.

### No ammo, Mag On (`ammo == 0`)
- If the player has enough energy to do a reload, the mag is ejected.

### No magazine (`ammo < 0`)
- If the player has enough energy to do a reload, the reload sequence begins.

### Reload Sequence
The reload sequence mimics that of Synthetik's:
1. A bar appears beside the cursor, and an indicator goes up along that bar.
    - The bar has three distinct regions: bad (white), good (dark purple) and perfect (light purple)
    - The speed at which the indicator moves up is dependent on the weapon's reload time.
2. The player triggers (left-clicks) the weapon

## Jamming
Depending on how well the gun is reloaded, there is a chance that the gun jams.
- If you reloaded it good or perfectly, it will not jam at all.

When the gun jams, an indicator appears. The player must trigger the weapon repeatedly to unjam the weapon.

The gun only jams before firing.

# Gun Properties
## Damage
- Per-shot Damage
    - If a gun shoots multiple projectiles, the damage is distributed between them
    - There is the concept of multishot: a gun can shoot n times the projectiles it shoots, but the damage isn't diluted
    - The per-shot damage is affected by how well the gun was reloaded 
        - If the gun is reloaded perfectly, 
- Shots deal 

## Projectile/Beam
- Primary Ability has three versions: projectile, hitscan and beam.

# Sprite
## Gun Sprite Sheet
The sprite sheet of a gun must contain the following:
- A row of the firing animation of the gun, including the ejection and feeding.
- A sprite of the gun being jammed
