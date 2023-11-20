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

This Starbound mod is in no way designed to be balanced; this game modification was done with fun and firepower in mind.

This mod also serves as a framework for modders that intend to use the same system with their guns.

# Background & Motivations

Some mechanics, guns and other features implemented in this mod were inspired by many games.

## Synthetik: Legion Rising

Synthetik: Legion Rising is a roguelike top-down shooter whose main appeal lies in its tactical gunplay. The gameplay involves traversing through levels whlie dealing with gun overheating, active reloading, inopportune jamming and inaccuracy incurred by moving.

Active reloading involves ejecting the mag and manually reloading it with a quick-time event; these two actions are separate. Hitting the reload key while there is ammo ejects the mag; ejecting the mag discards remaining ammo, punishing the habit of frequent reloading developed from playing generic shooters, in line with its theme of tactical gameplay.

Reloading makes a bar with two colored segments appear; the player must hit the reload key to stop the progress such that it is within either colored segment of the bar; stopping at the lighter-colored region executes a "perfect reload", providing a damage bonus for that magazine. Failing to stop within the colored region forces the player to wait the entire remaining duration of the reload.

Synthetik also features a jamming mechanic: guns have a chance to jam, forcing you to hit the reload button multiple times to unjam the weapon in order for it to shoot again.

When the player character in synthetik moves, the inaccuracy of their weapon increases, indicated by a large circle around their cursor crosshair. This mechanic incentivizes standing still when shooting to make the most out of the gun's ammunition.

Project 45 is largely motivated by the mechanics presented by Synthetic, taking the idea of active reloading and implementing it into Starbound, which normally does not have any reload nor any ammo-related mechanic. To punish ill-timed reloads (and to incentivize well-timed ones), Project 45 guns are made to have an increased chance of jamming when reloaded with ill timing, and all guns currently available within the mod completely eliminate the odds of jamming when perfectly reloaded. Additionally, to promote tactical gameplay, a movement-based recoil mechanic was also implemented among the guns of Project 45.

It is understood that some users may find it difficult to adapt to the Synthetik-inspired mechanics introduced by the mod, so a gun modding feature is implemented so that users can mitigate (or outright remove) downsides introduced by the discussed mechanics, allowing them to further customize their experience with this game mod.

## Warframe

Warframe's ranged weapons feature a stat called ["Punch Through"](https://warframe.fandom.com/wiki/Punch_Through); it determines the distance through any material that a weapon's projectile can go (measured in meters). This is a form of area-of-effect damage in the game, in which the area is limited to the trajectory of the projectile.

Starbound has a similar mechanic, but is limited to projectiles either penetrating through all enemies, everything, or nothing at all. Project 45 took the concept of Punch through and implemented it in its projectiles, albeit instead of being measured in units of distance, it is measured in the number of enemies it can penetrate before despawning. (This was well-implemented in hitscan projectiles, but due to the limitations of the game, being a 2D platformer sandbox, regular projectiles can still damage more than the expected number of enemies if the enemis overlap each other)

[Critical Hits](https://en.wikipedia.org/wiki/Critical_hit) across many games involve a chance, commonly between 0% and 100%, to deal increased damage (typically, non-critical damage multiplied by a critical factor). Warframe puts an additional [twist](https://warframe.fandom.com/wiki/Critical_Hit#Crit_Tiers) on this mechanic by allowing for >100% critical chance, with the critical damage scaling accordingly.

As Starbound only has skeletal features that seem to support critical hits (`strongHit` fields in various damage type configs), Project 45 takes the initiative to integrate Warframe's critical hit mechanics, albeit calculated in a simpler way.

The ranged weapons of Warframe have a stat called ["Multishot"](https://warframe.fandom.com/wiki/Multishot), which multiplies the number of projectiles the weapon fires. This is a non-discrete value, essentially functioning like critical hits - the decimal part of Multishot is treated as a chance for one more set of projectiles to be fired. Starbound also implemented this feature, albeit limitedly in certain cases due to the game's limitation on the optimal number of damage instances that should be present.

# Project 45: User Features
## Mechanics

## Firing
### Fire Mode Settings
Guns can have multiple fire mode configurations.
#### Semi-fire/Auto-fire Guns
#### Manual-feed guns
#### Charge & Overcharge
### Projectiles
The weapons of Project 45 can fire four different kinds of projectiles:
- Regular projectiles,
- Hitscan projectiles,
- Beams, and
- Summoned projectiles.

#### Regular & Summoned Projectiles

Regular projectiles deal damage over a distance; the main difference these projectiles have with the other kinds of projectiles is that they take time to reach their targets. Besides that, nothing much can be said about regular projectiles as they otherwise behave like vanilla projectiles, except for the fact that some mods can display the trajectory of projectiles affected by gravity.

As for Summoned Projectiles, instead of being fired from the weapon's muzzle, these projectiles are spawned around the player's cursor. Summoned projectiles are typically explosions, and they provide a benefit similar to Hitscan projectiles in that the damage they deal is instantaneous, but with the added requirement of having to aim the cursor over the targets.

#### Hitscan Projectiles

Hitscan projectiles aren't projectiles, per se; they are essentially short-lived beams that deal instantaneous damage within an arbitrary range, functioning akin to hitscans in other shooters.

This kind of projectiles can have the unique effect of penetrating a certain number of enemies, unlike regular projectiles which can only either penetrate all enemies or not.

Hitscan projectiles can multishot but they are capped at 7 projectiles; the loss of projectiles are compensated with proportionally increased damage.

#### Beams

Beams are similar to those fired by vanilla beam weapons like the [Lazercaster](https://starbounder.org/Lazercaster), except, like Hitscan projectiles, they can penetrate a certain number of enemies without stopping.

Unlike the other three projectiles, Beams do not have an obvious "multishot"; it is instead treated as a separate multiplier to damage akin to critical damage. Beams' rate of fire also affects the frequency of their damage ticks, as well as the frequency at which they consume ammo.

Beams also have a special interaction with semi-fire charge weapons: such weapons only fire when they are charged and the fire weapon button is let go, and it continues firing on its own until either
- the charge is depleted,
- the fire button is held down again, or
- the gun runs out of ammo.

### Recoil

There are two aspects to gun recoil: Randomness and Muzzle Rise.
- **Randomness**: The longer the player shoots, the less accurate their next shot will be. This aspect is separate from a gun's \[projectile\] Spread, 
- **Muzzle Rise**: The more the player shoots, the higher their muzzle will rise. This can be counteracted by aiming lower.

Recoil is affected by the player character's movement; the less you move, the more accurate you are. Crouching drastically reduces recoil; some guns completely remove it.

### Ammo and Active Reload

The weapons of Project 45 take ammo from the player character's energy pool, and only consume energy when reloaded.

Reloading essentially functions similarly to that of Synthetik, but guns cannot be reloaded manually under normal circumstances; they must first be out of ammo before their magazines could be ejected.

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