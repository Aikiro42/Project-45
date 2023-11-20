# Introduction

Project 45 is a mod for Starbound that introduces new mechanics to the game, some of which are:
- Hitscan shots
- Persistent Ammo
- Active Reload
- Gun Jamming
- Critical Damage
- On-the-fly modification
  - Variable Projectiles
  - Lasers and Trajectory Visualization
  - Scopes
  - Replacable Alt Abilities
- Stat upgrades
- Recoil Mechanic
- Charge and Cocking Mechanics
- Satisfying visual and sound effects

This mod also serves as a framework for modders that intend to use the same system with their guns.

# Background

## Inspiration

Some mechanics, guns and other features implemented in this mod was inspired by many games.

### Synthetik: Legion Rising

Synthetik: Legion Rising is a roguelike top-down shooter whose main appeal lies in its tactical gunplay. The gameplay involves traversing through levels whlie dealing with gun overheating, active reloading, inopportune jamming and inaccuracy incurred by moving.

Active reloading involves ejecting the mag and manually reloading it with a quick-time event; these two actions are separate. Hitting the reload key while there is ammo ejects the mag; ejecting the mag discards remaining ammo, punishing the habit of frequent reloading developed from playing generic shooters, in line with its theme of tactical gameplay.

Reloading makes a bar with two colored segments appear; the player must hit the reload key to stop the progress such that it is within either colored segment of the bar; stopping at the lighter-colored region executes a "perfect reload", providing a damage bonus for that magazine. Failing to stop within the colored region forces the player to wait the entire remaining duration of the reload.

Project 45 took the idea of active reloading and implemented it into Starbound, which does not normally have any reload mechanic.

### Warframe

Warframe's ranged weapons feature a stat called ["Punch Through"](https://warframe.fandom.com/wiki/Punch_Through); it determines the distance through any material that a weapon's projectile can go (measured in meters). This is a form of area-of-effect damage in the game, in which the area is limited to the trajectory of the projectile.

Starbound has a similar mechanic, but is limited to projectiles either penetrating through all enemies, everything, or nothing at all. Project 45 took the concept of Punch through and implemented it in its projectiles. (This was well-implemented in hitscan projectiles, but due to the limitations of the game, being a 2D platformer sandbox, regular projectiles can still damage more than the expected number of enemies if the enemis overlap each other)

[Critical Hits](https://en.wikipedia.org/wiki/Critical_hit) across many games involve a chance, commonly between 0% and 100%, to deal increased damage (typically, non-critical damage multiplied by a critical factor). Warframe puts an additional [twist](https://warframe.fandom.com/wiki/Critical_Hit#Crit_Tiers) on this mechanic by allowing for >100% critical chance, with the critical damage scaling accordingly.

As Starbound only has skeletal features that seem to support critical hits (`strongHit` fields in various damage type configs), Project 45 takes the initiative to integrate Warframe's critical hit mechanics, albeit calculated in a much simpler (and perhaps more unbalanced) way.

# Project 45: User Features
## Mechanics

## Firing
The weapons of Project 45 can fire four different kinds of projectiles:
- Regular projectiles,
- Hitscan projectiles,
- Beams, and
- Summoned projectiles.

### Hitscan Projectiles
These projectiles aren't projectiles, per se; they are essentially short-lived beams that deal instantaneous damage within an arbitrary range, functioning akin to hitscans in other shooters.

This kind of projectiles can have the unique effect of penetrating a certain number of enemies, unlike regular projectiles which can only either penetrate all enemies or not.

### Beams
These projectiles are similar to those fired by vanilla beam weapons like the [Lazercaster](https://starbounder.org/Lazercaster).

### Recoil

There are two aspects to gun recoil: Randomness and Muzzle Rise.
- **Randomness**: The longer you shoot, the less accurate your next shot will be. This aspect is separate from a gun's \[projectile\] Spread, 
- **Muzzle Rise**: The more you shoot, the higher your muzzle will rise. This can be counteracted by aiming lower.

Recoil is affected by your movement:
- Crouching drastically reduces recoil; some guns completely remove it.
- 



### Ammo and Active Reload
### Jamming
### Modding
## Items
### Guns
### Mods
#### Ability
#### Ammo (Projectile)
#### Attachments
#### Stats
### Others

# Project 45: Developer Features
## Primary Ability: `project45gunfire`
### Config File
#### 