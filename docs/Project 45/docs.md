<style>

  img { 
    image-rendering: optimizeSpeed;             /* STOP SMOOTHING, GIVE ME SPEED  */
    image-rendering: -moz-crisp-edges;          /* Firefox                        */
    image-rendering: -o-crisp-edges;            /* Opera                          */
    image-rendering: -webkit-optimize-contrast; /* Chrome (and eventually Safari) */
    image-rendering: pixelated;                 /* Universal support since 2021   */
    image-rendering: optimize-contrast;         /* CSS3 Proposed                  */
    -ms-interpolation-mode: nearest-neighbor;   /* IE8+                           */

    margin: 10px;
    padding: 10px;
    border: 2px solid gray;
  }

  body {
    background: #1c1c1c;
    color: #cccccc;
    width: 800px;
    margin: auto;
    margin-bottom: 100px;
  }

  .item-desc{
    display: flex;
    flex-direction: row;
  }

  .item-desc-icon{
    height: 100px;
  }

</style>

[test](#guns)

# Table of Contents
- [Introduction](#introduction)
- [Background & Motivations](#background--motivations)
  - [Synthetik: Legion Rising](#synthetik-legion-rising)
  - [Warframe](#warframe)
- [Project 45: User Features](#project-45-user-features)
  - [Mechanics](#mechanics)
- Project 45: Developer Features

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

## Quickstart

The Project 45 Gun Shop can be crafted with the Inventor's table. Guns, Mods, Ammo (Custom Projectiles) and Stat upgrades can be bought there, as well as a few miscallenous items.

## Mechanics

## Firing

### Fire Mode Settings

Guns can have multiple fire mode configurations.

#### Semi-fire/Auto-fire Guns

Semi-fire guns require the player to let go of the fire button to fire another round.

If a charged semi-fire gun is sufficiently charged, letting go of the fire button fires it. (There are exceptions to this rule, automatically firing the gun when fully (over)charged, exhausting the charge meter in the process). On the other hand, Auto-fire guns begin firing once the gun is sufficiently charged.

#### Manual-feed guns

Some guns, like the Hunting Rifle, can be manually fed. Manually-fed guns require the player to manually cock the gun before every shot, done simply via pressing the fire button after shooting. Whether the gun is charged or not does not affect this input.

Auto-fire guns cannot be cocked manually.

#### Charge & Overcharge

Some guns, like the Gauss Rifle, are charged. Charged guns require the player to hold down the fire button before the gun is able to shoot, either by letting go or continually holding down the fire button, depending on whether it is a semi- or auto-fire gun.

Some semi-fire charged guns can shoot 

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

The weapons of Project 45 are ammo-based and only consume energy when reloaded.

When the gun runs out of ammo (i.e. the ammo counter is 0), the player must eject the magazine by pressing the fire button. After which, the player may press the fire button again to initiate a reload.

When a reload is initiated, a bar appears, with three distinct regions
- a white "fail" region,
- a dark purple "good" success region, and
- a light purple "perfect" success region, typically within the dark purple region.

A red indicator will also begin moving from the bottom of the bar to the top. Pressing the fire button stops the indicator. 
- Stopping it over the white region turns the bar red, indicating a "bad" reload.
- Stopping it over the dark purple region means the reload is "good", and
- stopping the indicator over the light purple region means the reload is "perfect".
- Allowing the indicator to reach the top of the bar executes an "okay" reload.

"Bad", "Good", "Perfect" and "Okay" are what you call the Reload Rating of the executed active reload.
- "Bad" reloads typically incur an 80% multiplicative penalty to damage. and a higher chance to jam.
- "Okay" reloads have no penalty nor benefit other than a reasonable chance to jam.
- "Good" reloads provide a 125% multiplicative bonus to damage, and typically eliminates the odds of the weapon jamming.
- "Perfect" reloads provide a 150% multiplicative bonus to damage and typically eliminates the odds of the weapon jamming.

> The mod allows different jam chances and damage bonuses. TODO: Elaborate

Some guns load ammo by the bullet. With such guns, pressing the fire button to stop the indicator resets it to the bottom of the reload bar. Per-bullet loaded guns have a different reload rating system based on the final score of the reload.
- A "bad" reload gives no points.
- A "good" reload gives 1 point.
- A "perfect" reload gives 2 points.
- An "okay" reload ends the reloading process (while itself loading a \[set of\] rounds).

When the reloading process is finished (either when the gun is fully loaded or an "okay" reload was executed), the final reload score is divided by the number of [sets of] rounds loaded (i.e. the number of times the indicator was stopped).
- If the quotient is greater than 1, the reload is "perfect".
- Otherwise, if the quotient is greater than 2/3, the reload is "good".
- Otherwise, if the quotient is greater than 1/3, the reload is "okay".
- Otherwise, the reload is "bad".

### Jamming

All guns have a chance of jamming depending on how well they were reloaded. The odds of jamming depend on the weapon; details can be seen under the [Guns](#guns) section.

### Modding

Project 45 gun mods work very much like EPP augments. They are applied to any Project 45-based weapon via right-clicking on the weapon while the mod is held by the cursor.

Gun tooltips indicate the visible attachments they can accept.

TODO: add tooltip image

#### Ammo Mods

Ammo mods change the nature of the projectile a weapon fires. Some weapons only accept a specific kind of ammo mods.



## Items
### Guns
**Pipe Gun**
<div class="item-desc">

<img class="item-desc-icon" src="assets/project45-neo-pipegun-icon.png" />

|Stat|Value|
|-|-|
|Fire mode|Semi-fire, manually fed|
|Ammo Capacity|1|
|Spread|30°|

</div>


### Mods
#### Ability
#### Ammo (Projectile)
#### Attachments
#### Stats
### Others

# Project 45: Developer Features
## Primary Ability: `project45gunfire`
### Stat Config
|Field|Data Type|Description|
|-|-|-|
|`baseDamage`|`number (float)`|The base damage used in the weapon's damage calculations.|
|`reloadCost`|`number (int)`|The absolute energy consumed when loading a magazine/bullet into a weapon.|
|`reloadTime`|`number (float)`|The amount of time it takes to load a magazine/bullet into a weapon. In other words, the amount of time it takes for the indicator to reach the top of the reload bar.|
|`critChance`|`number (float)`|The chance for the projectiles of a shot to deal critical damage. Values above 1 (100%) will guarantee crits, and the decimal portion will be used to determine the chance for the projectiles of a shot to deal even more critical damage.|
|`critDamageMult`|`number (float)`|The number multiplied to the final damage of the projectiles when the shot is determined to deal a critical hit. If `critChance` is above 1 (100%), the multiplier would be `(floor(critChance) + 1) * critDamageMult`|
|`lastShotDamageMult`|`number (float)`| The number multiplied to the final damage of the projectiles of the last shot that can be made with the gun.|

### Misc Config
|Field|Data Type|Description|
|-|-|-|
|`laser.enabled`|`boolean`|Determines whether the laser is rendered (if possible) or not.|
|`laser.width`|`number (float)`|Width of the laser beam, in pixels. (1 block = 8 pixels)|
|`laser.width`|`number[] (int)`|RGB (3-element array)/RGBA (4-element array) configuration of the laser.|
|`laser.trajectoryConfig.renderSteps`|`number (int)`|Number of segments that will be used when rendering gravity-affected projectile trajectories|
|`laser.renderUntilCursor`|`boolean`|Determines whether the laser is rendered only up to the player's cursor.|

|Field|Data Type|Description|
|-|-|-|
|`movementSpeedFactor`|`number (float)`|Number multiplied to movement speed when holding the weapon.|
|`jumpHeightFactor`|`number (float)`|Number factored into jump height when holding the weapon.|
|`heavyWeapon`|`boolean`|Determines whether the player is forced to walk while holding the weapon.|

|Field|Data Type|Description|
|-|-|-|
|`performanceMode`|`boolean`|If `true`, disables various visual effects. See the `weaponAbility` file for details.|
|`debug`|`boolean`|If `true`, enables the laser, constantly spawns bullet casings and magazines, and renders `/debug` points. Helpful for adjusting offsets.|
|`debugTime`|`number (float)`|Time to wait in seconds between debug function calls. TODO: Write something about taking a look at the debug function in the lua file|

|Field|Data Type|Description|
|-|-|-|
|`hideMuzzleFlash`|`boolean`|If `true`, disables the animation and lighting effects of the muzzle flash.|
|`hideMuzzleSmoke`|`boolean`|If `true`, disables the muzzle smoke particles generated moments after firing the weapon.|
|`hollowSoundMult`|`number (float)`|Multiplier for the "chink" sound effect of the gun as it runs out of ammo.|

### Projectile Config

Regarding `"hitscan"` projectiles:
- When the weapon fires multiple `"hitscan"` projectiles, it generates multiple damage areas dealing their own damage groups. It is thus advised to moderate the number of hitscan projectiles shot.
- Any mechanic designed around regular projectiles won't work against `"hitscan"` projectiles. (e.g. Project 42 deflection)

Regarding `"beam"` projectiles:
- If `chargeTime`/`overchargeTime` is nonzero and `semi` is true, then the beam functions like so:
  - The weapon won't fire until sufficiently charged and the fire button is released; once it starts firing, the weapon will continually fire until it either
    - runs out of ammo,
    - expends all its charge, or
    - if the fire button is pressed.
- `"beam"` projectiles are actually damage areas, just like how vanilla beams work.

Regarding `"summoned"` projectiles:
- These projectiles are spawned at the aim position instead of from the muzzle.
- Summoned projectiles are not affected by recoil, but they are affected by inaccuracy and spread. TODO: Verify me
- The spread of the projectiles are affected by their distance from the user.


|Field|Data Type|Description|
|-|-|-|
|`projectileKind`|`string`|can be any of the following: `"projectile"`, `"hitscan"`, `"beam"`, `"summoned"`|
|`projectileCount`|`number (int)`|Number of projectiles spawned per shot. Damage is distributed between these projectiles.|
|`multishot`|`number (float)`|Number multiplied to the final number of projectiles spawned; the damage of the extra projectiles spawned are not affected. Decimal values are treated as a chance to spawn an extra set of projectiles.|
|`spread`|`number (float)`|The spread of the weapon's projectiles, in degrees; independent from inaccuracy and recoil. Similar to the `accuracy` field of the `gunfire` primary ability.|

|Field|Data Type|Description|
|-|-|-|
|`projectileType`|`string \| string[]`|The type of projectiles shot by the weapon. Can be a list of `projectileTypes`.|
|`projectileParameters`|`JSON`|Parameters applied to all projectiles shot by the weapon.|
|`projectileFireSettings.sequential`|`boolean`|If `true`, fires each projectile type in sequence. Only applies if `projectileType` is an array.|
|`projectileFireSettings.resetProjectileIndexOnReload`|`boolean`|If `true`, fires the first projectile in the `projectileType` list. Only applies if `projectileType` is an array and `projectileFireSettings.sequential` is true.|
|`projectileFireSettings.batchFire`|`boolean`|If `true`, all projectile types at once. Only applies if `projectileType` is an array. TODO: Clarify and verify me|

<!--

```json
{

    // You can make the muzzle shoot an additional projectile this way.
    /*
    "muzzleProjectileType": null,
    "muzzleProjectileParameters": {

    },
    // Offset when firing muzzle projectiles; sometimes the firePosition is way back into the barrel
    // like in project45-neo-gaussrifle, so you'd want to move the muzzle projectile forward
    "muzzleProjectileOffset": [0, 0],

    // List of Projectile VFX that will be spawned from the projectile tip
    "muzzleProjectiles": [{
        "type": "project45_muzzleshockwave",
        "offset": [5, 0],
        "parameters": {
          "speed": -5
        },
        "count": 1,
        "spread": 1,
        "firePerShot": true
      }
    ],
    */

    "summonedProjectileType": "project45_defaultsummon",
    "summonedProjectileParameters": {
      "summonAnywhere": false, // if true, can summon projectiles anywhere as long as it isn't within terrain
      "summonInTerrain": false // if true, can summon in terrain. Renders summonAnywhere true.
    },

    "hitscanParameters": {
      // hitscan params
      "range": 100,  // range of the hitscan line in blocks
      
      "punchThrough": 0,  // number of entities to register before stopping the scan
      "fullChargePunchThrough": 0,
      
      "ignoresTerrain": false,  // pierces through terrain if true
      "ignoresTerrainOnFullCharge": false,
      
      "hitscanFadeTime": 0.1, // how long the hitscan line fades away
      "hitscanWidth": 1, // visual width of hitscan line in pixels
      // "hitscanColor": [255,255,200], // color of hitscan projectile; also dictates muzzle flash color
      // damage configuraiton of hitscan damage line
      // baseDamage is calculated by self:damagePerShot() * crit / activeItem.ownerPowerMultiplier()
      // but can be overridden; it's recommended that it shouldn't be overridden
      "hitscanDamageConfig": {
        "damageKind": "physical",
        "statusEffects": []
      },
      // actions to be executed at the end of the hitscan line
      "hitscanActionOnHit": []
      
    },
    
    // Recommendation: set the <ejectCasingsWithMag> setting to true if the gun fires beams
    "beamParameters": {
      // Common configs
      "range": 100,  // length of beam in blocks

      // number of entities the beam passes through before it terminates
      // if the beam passes through less entities it keeps going until it hits terrain
      "punchThrough": 3,
      "fullChargePunchThrough": 3,
      
      // whether the beam fires through terrain or not
      "ignoresTerrain": false,
      "ignoresTerrainOnFullCharge": false,
      
      "beamWidth": 5, // width of beam - beams that are too wide can look weird
      "beamInnerWidth": 3, // width of inner white beam - just for vfx
      "beamJitter": 1, // how much the beam width changes as it's shot - just a vfx
      // "beamColor": [0,140,217], // color of beam
      // damage configuration of beam damage poly
      "beamDamageConfig": {
        "statusEffects" : [ ],
        "damageSourceKind" : "plasma",
        "knockback" : 2,
        "timeout": 0.1
      },
      
      // if true, consumes ammo over time.
      // Otherwise, will only consume ammo every time the beam starts
      // set to true if gun is not semi
      "consumeAmmoOverTime": true,

      // determines if gun transists to ejecting state if trigger is released
      "ejectCasingsOnBeamEnd": false


    },

    // ____________________________________[ SECTION: Ammo Config ]____________________________________
    
    "maxAmmo": 10,
    "bulletsPerReload": 15, // bullets reloaded every active reload; set to negative number to reload all bullets
    "ammoPerShot": 1,
    "ammoConsumeChance": 1,
    "quickReloadTimeframe": [0.5, 0.6, 0.7, 0.8], // [ good% [ perfect% ] good% ] of <reloadTime>

    // Reload and Magazine Config

    "audibleEjection": false, // if true, plays bolt pulling sound when ejecting casings
    "ejectAfterAnimation": true, // ejects casings before animationState is set to "ejecting"
    "ejectCasingsAfterBurst": false, // ejects casings after burst is finished
    "ejectCasingsWithMag": false, // for revolvers, etc.; casings are not ejected until magazine is ejected
    
    /*
    if both <ejectMagOnEmpty> and <reloadOnEjectMag> are true, the gun will (almost) immediately begin reloading
    upon firing the last (set of) bullet(s).

    ejectMagOnEmpty can take on two (three) values:
    - "firing": the gun ejects its mag upon firing the last shot
    - "ejecting": the gun ejects its mag upon ejecting the casings of the last shot
    - if false or nil, the gun won't eject its mag on empty
    Their difference lies in the animation state of the gun
    (as well as whether manual feed guns empty on eject)
    */
    "ejectMagOnEmpty": false, // immediately eject mag when the gun hits 0 ammo
    "reloadOnEjectMag": false, // immediately begin reload sequence upon ejecting
    
    "ejectMagOnReload": false, // ejects mag every (active) reload, like loading a strip and discarding the metal
    
    "internalMag": false, // whether the "magazine" is a strip or a clip (makes magazine invisible)
    "loadRoundsThroughBolt": false, // whether the bolt must be opened before doing the reload sequence.

    // "postReloadDelay": null, // float; time to wait before cocking in seconds, cockTime/8 by default
    
    // determines whether the gun is break-action, i.e. breaks open when ejecting the mag
    // dictates whether the gun animation accesses the "open" state
    "breakAction": false,

    "magVisualPercentage": false, // Whether the mag visually indicates the percentage or count of ammo remaining
    "magFrames": 1, // number of frames wherein the mag is "present" (for regular, opaque mags, set this to 1)
    "magLoopFrames": 1, // number of loop frames (doesn't matter if <magFrames = 1>)
    
    // ammo count interval at which the magazine is animated (think belt ammmo)
    // doesn't matter if <magFrames = 1>
    "magAmmoRange": [1, 1],

    // [bad, ok, good, perfect] reload damage multiplier
    "reloadRatingDamageMults": [0.8, 1, 1.25, 1.5],
    "jamChances": [0.5, 0.05, 0, 0],

    // ____________________________________[ SECTION: Accuracy and Recoil Config ] ____________________________________

    // standard deviation of random arm movement as the gun recoils (in degrees, not radians)
    // note that this deviation is eliminated if the player crouches
    "inaccuracy": 5, 
    "recoilUpOnly": false, // forces inaccuracy to cause the weapon to go upwards only
    "recoilAmount": 1 , // amount of recoil per shot, in degrees; arm and weapon will rotate by half of this
    "recoilMaxDeg": 7.5, // the most the arm and weapon will rotate, in degrees.
    "recoilMult": 1, // multiplies recoilAmount
    "recoilCrouchMult": 0.5, // mulitplies recoil and recoilMaxDeg when crouching
    
    "recoverTime": 1.5, // time it takes to recover aim completely, in seconds
    "recoverDelay": 0.1, // time before aim is recovered
    "recoilMomentum": 0,  // amount of momentum applied to player when firing the gun; canceled by crouching
    "screenShakeAmount": [0.5, 0.1], // amount of screenshake per shot
    // time it takes to reach the max cycle time, in seconds
    // only matters if screenShake is a 2-element array of floats
    "maxScreenShakeTime": 0.5,

    // ____________________________________[ SECTION: Fire Config ]____________________________________

    /*
    <semi> is a fundamental setting that affects how the gun works,
    especially when charging is involved:
    - If the gun is semi and charged, then firing happens on release rather than
      on press.
    - If the gun is semi, charged, and fires a beam, you'll essentially be charging the gun
      to fire continuously until the charge is depleted (i.e. below charge time if there's overcharge
      or zero otherwise)
    */
    "semi": true,


    // Makes your gun not automatically eject right after firing,
    // requiring you to cock the gun to fire again.
    // if the gun is autofire (<semi = false>) then this will always be false
    "manualFeed": false,
    
    // Allows you to fire your gun immediately if you hold left-click down while cocking the gun.
    // If the gun isn't manual-feed, this is set to false.
    "slamFire": false,

    // time it takes to cock the gun, cycle rounds, etc.
    // can also be a 2-element array of floats i.e.
    // [<initial cycle time>, <final cycle time>]
    // e.g. if initial cycle time > final cycle time, weapon RoF decreases the longer it's fired
    // vice versa if initial < final
    // cycleTime=0.1 is equal to cycleTime=[0.1, 0.1]
    "cycleTime": 0.1,
  
    "burstCount": 1,

    // time it takes to reach the final cycle time in seconds
    // only matters if cycleTime is a 2-element array of floats
    // by default, gun reaches final RoF when fired for 3s straight
    // if gun is fired for 1.5s straight, it will take 1.5s to decay to initial cycle time
    "cycleTimeMaxTime": 3,

    // midCockDelay: null, // float; time to wait before pushing bolt in seconds

    // multipliers for cycle time growth and decay
    // only matters if cycleTime is a 2-element array of floats
    /*
    e.g. if cycleTimeMaxTime=3, cycleTimeGrowthRate=2, cycleTimeDecayRate=1
    gun reaches final RoF in 1.5s
    but RoF reaches initial in 3s
    */
    "cycleTimeGrowthRate": 1,
    "cycleTimeDecayRate": 1,
    
    "fireTime": 0.01, // time before another input can be registered
    "cockTime": 0.5, // time it takes to cock weapon

    // if true, animates firing animation as a loop 
    // the firing process is thus treated as a burst;
    // casings are ejected after bursting
    // if <ejectCasingsAfterBurst = true>
    "loopFiringAnimation": false,

    // ____________________________________[ SECTION: Charge Config ]____________________________________

    "chargeTime": 0,

    "overchargeTime": 0, // allows gun to deal up to 100% more damage, multiplicative to other bonuses
    
    // time it takes for gun to hold charge before discharging
    // helps for consistent behavior
    "dischargeDelayTime": 0.025,

    "dischargeTimeMult": 1, // how fast the gun discharges
    
    "progressiveCharge": true, // whether the charge animation loops or is dependent on charge progress
    "chargeFrames": 1, // only matters if progressiveCharge is true

    // makes the gun fire once the charge timer hits/passes chargeTime
    // "fireBeforeOvercharge": false,
    
    // fires gun after charging, given that there's ammo
    // if the gun is autofire (<semi = false>) then this will always be false
    "autoFireOnFullCharge": false,

    // Resets charge after firing.
    // Only matters if the gun semi-fire (<semi = true>).
    // if the gun is autofire (<semi = false>) then this will always be false.
    "resetChargeOnFire": false,

    // resets charge when ejecting magazine
    "resetChargeOnEject": false,
    "resetChargeOnJam": false, // resets charge when jamming

    // discharges if the weapon is obstructed by terrain
    "chargeWhenObstructed": false,

    // Spawns more smoke puffs around specified offset region the higher the charge
    "chargeSmoke": false,
    "maxChargeSmokeEmissionRate": 25,
    
    /*
    If true, progressive weapon charge is animated based on initial charge time.
      If charge time is zero, overcharge time is used instead.
    Otherwise, progressive weapon charge is animated based on total charge time (charge + overcharge).
    This setting also affects charge smoke emission rate.
    */
    "animateBeforeOvercharge": false,

    // ____________________________________[ SECTION: Legacy Configs ]____________________________________

    // "fireType": "auto",
    // "cooldownTime": 0.1,
    // "burstTime": 0.05,

    // ____________________________________[ SECTION: Stances ]____________________________________

    "stances" : {

      // SUSTAINED STANCES - These stances are constantly interpolated to
      
      // initial stance when re-equipping the weapon
      // OBSOLETE: Weapon is "recoiled" downwards first thing
      /*
      "idleneo" : {
        "armRotation" : -45,
        "weaponRotation" : 0,
        "twoHanded" : true,
        "allowRotate" : true,
        "allowFlip" : true

      },
      */

      // stance while the gun is aimed
      "aimStance" : {
        "armRotation" : 0,
        "weaponRotation" : 0,
        // "twoHanded" : true, // twoHanded is set by the script if unspecified
        "allowRotate" : true,
        "allowFlip" : true
        // "frontArmFrame": "run.3"
        // "weaponOffset": [-1, 0]
      },

      // stance while the gun is jammed
      "jammed" : {
        "armRotation" : 0,
        "weaponRotation" : -15,
        "twoHanded" : true,
        "allowRotate" : false,
        "aimAngle": 0,
        "allowFlip" : true
      },

      // stance while the gun has no mag
      "empty" : {
        "armRotation" : -15,
        "weaponRotation" : 0,
        "twoHanded" : true,
        "allowRotate" : false,
        "aimAngle": 0,
        "allowFlip" : true
        // "frontArmFrame": "swimIdle.2",
        // "weaponOffset": [-1, 0]
      },

      // stance taken while ejecting the mag
      // this stance is also snapped to
      "ejectmag" : {
        "armRotation" : -30,
        "weaponRotation" : 5,
        "twoHanded" : true,
        "allowRotate" : false,
        "allowFlip" : false
      },

      // SNAP STANCES - These stances will be snapped to briefly
      // only arm and weapon rotations matter

      // stance snaps to this when unjamming
      "unjam" : {
        "armRotation" : 5,
        "weaponRotation" : -20,
        "twoHanded" : true,
        "allowRotate" : false,
        "aimAngle": 0,
        "allowFlip" : true,
        "frontArmFrame" : "run.2"
      },

      "boltPull": {
        "armRotation" : 5,
        "weaponRotation" : 5,
        "twoHanded" : true,
        "allowRotate" : false,
        "allowFlip" : true,
        "frontArmFrame" : "run.2",

        // New Stance Parameters

        "disabled": false,
        /*
        if true, stance isn't applied at all.
        */
        
        "lock": false,
        /*
        if true, disables weapon/arm rotation updates entirely.
        In essence, stance functions normally.
        Certain stances are (technically) always locked: the "reloading" and "loadRound" stances.
        */

        "snap": false,
        /*
        if true, stance snaps immediately and doesn't smoothly transist from previous stance.
        Certain stances always snap: the "unjam", "reloading" and "loadRound" stances.
        Certain stances snap depending on certain conditions: "reloaded" snaps if "reloadOnEjectMag" is false.
        */

        "lite": false
        /*
        if true, does not use `self.weapon:setStance()`. Specifically:
        - * Disallows self.weapon.stance to be set.
        - Disallows rotations, angular velocities and the rotation center to be set.
        - Disallows weapon offset to be set.
        - Allows the front and back arm frames to be set.
        - Allows sounds to be played
        - Allows animation states to be set
        - Allows particle emitters to burst
        You can still specify animationStates, played sounds and bursted particle emitters.

        * This weapon ability uses the stance saved on the weapon to allow for smooth interpolating
        transitions between stances, thus necessitating a custom setStance() function. Despite that,
        self.weapon:updateAim() is still used, so unexpected behavior can arise depending on how the stance
        is designed.
        Hence, creating a "lite" stance can allow correct recoil behavior, with some drawbacks:
        see project45-neo-leveraction.
        */

        
      },

      "boltPush": {
        "armRotation" : 5,
        "weaponRotation" : 0,
        "twoHanded" : true,
        "allowRotate" : false,
        "allowFlip" : true,
        "frontArmFrame" : "rotation"
        // "weaponOffset": [-1, 0]
      },

      // Stance taken right before slam-firing.
      // If this stance is absent, it uses boltPush instead.
      /*
      "slamFire": {
        "twoHanded" : true,
        "allowRotate" : false,
        "allowFlip" : false,
        "frontArmFrame" : "rotation"
      },
      */

      // RELOAD STANCES

      "loadRound": {
        "armRotation" : -45,
        "weaponRotation" : 45,
        "twoHanded" : true,
        "allowRotate" : false,
        "allowFlip" : true,
        "duration": 0.25
      },

      // stance taken while reloading
      "reloading" : {
        "armRotation" : -15,
        "weaponRotation" : 0,
        "twoHanded" : true,
        "frontArmFrame": "run.5",
        "allowRotate" : false,
        "aimAngle": 0,
        "allowFlip" : true
      },

      // stance taken upon finishing reload
      "reloaded" : {
        "armRotation" : 5,
        "weaponRotation" : 5,
        "twoHanded" : true,
        "allowRotate" : false,
        "aimAngle": 0,
        "allowFlip" : false,
        "frontArmFrame": "swim.3"
      },

      // Legacy Stances for altfire compatibility
      "fire": {
        "armRotation": 0,
        "weaponRotation": 0,
        "twoHanded": false,
        "allowRotate": true,
        "allowFlip": true
      },

      "cooldown": {
        "armRotation": 0,
        "weaponRotation": 0,
        "twoHanded": false,
        "allowRotate": true,
        "allowFlip": true
      },

      "idle" : {
        "armRotation" : 0,
        "weaponRotation" : 0,
        "twoHanded" : false,

        "allowRotate" : true,
        "allowFlip" : true
      }


    }
    
  }
}
```
#### 
-->