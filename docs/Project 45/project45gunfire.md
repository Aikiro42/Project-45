# Weapon Ability Fields

```json
{
  "animationScripts": [
    "/items/active/weapons/ranged/abilities/project45gunfire/project45gunfireanimation.lua"
  ],
  
  "animation": "/items/active/weapons/ranged/abilities/project45gunfire/project45gunfire.animation",

  "ability" : {
    "name" : "_Project45GunFire_",
    "type" : "project45gunfire",
    "scripts" : ["/items/active/weapons/ranged/abilities/project45gunfire/project45gunfire.lua"],
    "class" : "Project45GunFire",

    /*
    Passive Script, if you want additional effects to your weapon
    */
    // "passiveScript": "/items/active/weapons/ranged/abilities/project45gunfire/samplepassive.lua",

    // ____________________________________[ SECTION: Stat Config ]____________________________________

    "baseDamage": 5,
    "reloadCost": 50,
    "reloadTime": 1,   // 80% actual reload time, 20% cocking time -- TEST: Verify!
    "critChance": 0.1,
    "critDamageMult": 1.5,

    // ____________________________________[ SECTION: Misc Config ]____________________________________

    // Laser settings.
    "laser": {
      // "enabled": false, // if true, laser is rendered
      "width": 0.25,
      "color": [255, 0, 0], // laser color
      "range": 100, // max distance to which the laser is drawn
      "trajectoryConfig": {
        "renderSteps": 50  // number of lines rendered in the laser arc when using gravity-affected projectiles
      }
      // ,"renderUntilCursor": false // if true, laser is rendered up to player's aim position only
      // ,"alwaysActive": false
    },

    /*
    Movement settings
    */
    // "movementSpeedFactor": 1,
    // "jumpHeightFactor": 1,
    // "heavyWeapon": false, // forces wielder to walk if true
    

    /*
    if true, disables the following:
    - bullet casings
    - laser
    - chamber indicator
    - magazine animation
    - screenshake
    - charge smoke
    - muzzle particles
    */
    // "performanceMode": false,
    // "debug": false,

    /*
    Hide Muzzle Flash & Smoke
    */
    // "hideMuzzleFlash": false,
    // "hideMuzzleSmoke": false,

    // Audio settings
    "hollowSoundMult": 1, // affects volume of hollow sound

    /*
    Makes gun spawn particles when firing a projectile that crits
    */
    // "enableMuzzleCritParticles": false,

    // ____________________________________[ SECTION: Projectile Config ]____________________________________
    
    /*
    Can be any of the following: projectile, hitscan, beam, summoned

    Regarding "hitscan" projectiles:
    - When the weapon fires multiple hitscan projectiles, it generates multiple damage areas dealing their
      own damage groups. It is thus advised to moderate the number of hitscan projectiles shot.
    - As mentioned before, hitscan "projectiles" are actually damage areas, so any mechanic designed around
      regular projectiles won't work against hitscan weapons. (e.g. Project 42 deflection)
    
    Regarding "beam" projectiles:
    - If the weapon is charged and semi, then the beam functions like so:
      The weapon won't fire until the trigger is released (and the weapon is fully charged), and once it starts
      firing the weapon will continually fire until it runs out of ammo, all charge is expended, or the trigger
      is pulled
    - Beam projectiles are actually damage areas, just like how vanilla beams work.

    Regarding "summoned" projectiles:
    - "summoned" means the projectile is spawned at the aim position instead of from the muzzle.
    - Summoned projectiles are not affected by recoil, but they are affected by inaccuracy and spread.
    - The spread of the projectiles are affected by their distance from the user.
    */
    "projectileKind": "projectile",
    "projectileCount": 1,
    "multishot": 1,
    "spread": 0.05, // affects direction the projectile flies to, from the muzzle, in degrees
    
    "projectileType": "project45stdbullet", // can also be a list of projectileType strings
    
    /*
    "projectileType": [
        "project45stdbullet",
        "project45explosivebullet",
        "project45stdfirebullet",
        "project45stdpoisonbullet",
        "project45dragonsbreath"
      ],
    */

    "projectileParameters": {

    },

    /*
    settings for firing multiple types of projectiles
    only matters if `projectileType` is a list
    */
    /*
    "projectileFireSettings": {
      "sequential": false,  // whether the projectiles are fired sequentially or randomly
      "resetProjectileIndexOnReload": false, // only matters if "sequential" is true
      // determines whether multiple projectiles fired are of the same projectileType
      // or different projectileTypes
      "batchFire": true
    },
    */

    /*
    You can make the muzzle shoot an additional projectile this way.
    */
    // "muzzleProjectileType": null,
    /*
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
      // "summonAnywhere": false, // if true, can summon projectiles anywhere as long as it isn't within terrain
      // "summonInTerrain": false // if true, can summon in terrain. Renders summonAnywhere true.
    },

    "hitscanParameters": {
      // hitscan params
      "range": 100,  // range of the hitscan line in blocks
      
      "punchThrough": 0,  // number of entities to register before stopping the scan
      "fullChargePunchThrough": 0,
      
      // "ignoresTerrain": false,  // pierces through terrain if true
      // "ignoresTerrainOnFullCharge": false,
      
      "hitscanFadeTime": 0.1, // how long the hitscan line fades away
      "hitscanWidth": 1, // visual width of hitscan line in pixels
      // "hitscanColor": [255,255,200], // color of hitscan projectile; also dictates muzzle flash color
      // damage configuraiton of hitscan damage line
      // baseDamage is calculated by self:damagePerShot() * crit / activeItem.ownerPowerMultiplier()
      // but can be overridden; it's recommended that it shouldn't be overridden
      // "hitscanBrightness": 0, // % width of white line inside visual hitscan line, max 1 (equal width)
      // "scanUntilCursor": false
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
      // "ignoresTerrain": false,
      // "ignoresTerrainOnFullCharge": false,
      
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
      // "scanUntilCursor": false
      
      // if true, consumes ammo over time.
      // Otherwise, will only consume ammo every time the beam starts
      // set to true if gun is not semi
      "consumeAmmoOverTime": true//,

      // determines if gun transists to ejecting state if trigger is released
      // "ejectCasingsOnBeamEnd": false


    },

    // ____________________________________[ SECTION: Ammo Config ]____________________________________
    
    "maxAmmo": 10,
    "bulletsPerReload": 15, // bullets reloaded every active reload; set to negative number to reload all bullets
    "ammoPerShot": 1,
    "ammoConsumeChance": 1,
    "quickReloadTimeframe": [0.5, 0.6, 0.7, 0.8], // [ good% [ perfect% ] good% ] of <reloadTime>

    // Reload and Magazine Config

    // "audibleEjection": false, // if true, plays bolt pulling sound when ejecting casings
    // "ejectAfterAnimation": true, // ejects casings before animationState is set to "ejecting"
    // "ejectCasingsAfterBurst": false, // ejects casings after burst is finished
    // "ejectCasingsWithMag": false, // for revolvers, etc.; casings are not ejected until magazine is ejected
    // "closeBoltOnEmpty": false, // closes bolt when magazine is empty
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
    // "ejectMagOnEmpty": "firing", // immediately eject mag when the gun hits 0 ammo
    // "reloadOnEjectMag": false, // immediately begin reload sequence upon ejecting
    
    // "ejectMagOnReload": false, // ejects mag every (active) reload, like loading a strip and discarding the metal
    
    // "internalMag": false, // whether the "magazine" is a strip or a clip (makes magazine invisible)
    
    // whether the bolt must be opened before doing the reload sequence.
    // If internalMag is falsy, this is forced to become false.
    // "loadRoundsThroughBolt": false,

    // "postReloadDelay": null, // float; time to wait before cocking in seconds, cockTime/8 by default
    
    // determines whether the gun is break-action, i.e. breaks open when ejecting the mag
    // dictates whether the gun animation accesses the "open" state
    // "breakAction": false,

    // "magVisualPercentage": false, // Whether the mag visually indicates the percentage or count of ammo remaining
    "magFrames": 1, // number of frames wherein the mag is "present" (for regular, opaque mags, set this to 1)
    "magLoopFrames": 1, // number of loop frames (doesn't matter if <magFrames = 1>)
    
    // ammo count interval at which the magazine is animated (think belt ammmo)
    // doesn't matter if <magFrames = 1>
    "magAmmoRange": [1, 1],

    // [bad, ok, good, perfect] reload damage multiplier
    "reloadRatingDamageMults": [0.8, 1, 1.25, 1.5],
    "jamChances": [0.05, 0.013, 0, 0],

    // ____________________________________[ SECTION: Accuracy and Recoil Config ] ____________________________________

    // standard deviation of random arm movement as the gun recoils (in degrees, not radians)
    "inaccuracy": 3,
    /*
    // value multiplied to inaccuracy depending on movement state
    "inaccuracyMults:" {
      "mobile": 2,
      "walking": 1,
      "stationary": 0.5,
      "crouching": 0.25
    }
    */

    // "recoilUpOnly": false, // forces inaccuracy to cause the weapon to go upwards only
    "recoilAmount": 0.5, // amount of recoil per shot, in degrees; arm and weapon will rotate by half of this
    "recoilMaxDeg": 5, // the most the arm and weapon will rotate, in degrees.
    "recoilMult": 1, // multiplies recoilAmount
    "recoilCrouchMult": 0.5, // mulitplies recoil and recoilMaxDeg when crouching
    
    "recoverTime": 1.5, // time it takes to recover aim completely, in seconds
    "recoverDelay": 0.1, // time before aim is recovered
    "recoverMult": 1, // multipler to recoverTime and recoverDelay
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
    // "manualFeed": false,
    
    // Allows you to fire your gun immediately if you hold left-click down while cocking the gun.
    // If the gun isn't manual-feed, this is set to false.
    // "slamFire": false,

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
    // "loopFiringAnimation": false,

    // ____________________________________[ SECTION: Charge Config ]____________________________________

    "chargeTime": 0,

    "overchargeTime": 0, // allows gun to deal up to 100% more damage, multiplicative to other bonuses
    
    // Damage multiplier to the gun at full overcharge.
    // Calculated via
    //    1 + overchargeProgress * (chargeDamageMult - 1)
    // Set to 1 by default if unspecified
    // Will never go below 0 (but can go below 1, causing the gun to deal less damage at full overcharge)
    "chargeDamageMult": 1.1,
    
    // Perfect Charge parameters; only matters if overchargeTime > 0
    /*
    
    // replaces current charge multiplier to damage
    // equal to chargeDamageMult by default
    // set to the greatest value between itself, chargeDamageMult and 1
    "perfectChargeDamageMult": 2,
    
    "perfectChargeRange": [0.4, 0.6] // range of perfect charge; all values between 0 and 1 (i.e. percent)
    
    */

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
    // "autoFireOnFullCharge": false,

    // Resets charge after firing.
    // Only matters if the gun semi-fire (<semi = true>).
    // if the gun is autofire (<semi = false>) then this will always be false.
    // "resetChargeOnFire": false,

    // resets charge when ejecting magazine
    // "resetChargeOnEject": false,
    // "resetChargeOnJam": false, // resets charge when jamming

    // discharges if the weapon is obstructed by terrain
    // "chargeWhenObstructed": false,

    // Spawns more smoke puffs around specified offset region the higher the charge
    // "chargeSmoke": false,
    "maxChargeSmokeEmissionRate": 25,
    
    /*
    If true, progressive weapon charge is animated based on initial charge time.
      If charge time is zero, overcharge time is used instead.
    Otherwise, progressive weapon charge is animated based on total charge time (charge + overcharge).
    This setting also affects charge smoke emission rate.
    */
    // "animateBeforeOvercharge": false,

    // ____________________________________[ SECTION: Legacy Configs ]____________________________________

    // "fireType": "auto",
    // "cooldownTime": 0.1,
    // "burstTime": 0.05,

    // ____________________________________[ SECTION: Stances ]____________________________________

    "stances" : {
      
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
        "weaponRotation" : -15,
        "twoHanded" : true,
        "allowRotate" : false,
        "aimAngle": 0,
        "allowFlip" : true
        // "frontArmFrame": "swimIdle.2",
        // "weaponOffset": [-1, 0]
      },

      // stance taken while ejecting the mag
      "ejectmag" : {
        "armRotation" : -30,
        "weaponRotation" : 5,
        "twoHanded" : true,
        "allowRotate" : false,
        "allowFlip" : false,
        "snap": true
      },

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

        "snap": false
        /*
        if true, stance snaps immediately and doesn't smoothly transist from previous stance.
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
# Core Stats
## `baseDamage: <number>`
## `reloadCost: <int energy>`
## `reloadTime: <number seconds>`
## `critChance: <number chance>`
## `critDamageMult: <number>`

# Core Mechanics: Projectiles
## `multishot: <number>`
## `spread: <number degrees>`
## `projectileKind: <"projectile" | "hitscan" | "beam" | "summoned">`
## Projectile-related Settings
### `projectileType: <String projectileID | String[] projectileIDs>`
### `projectileParameters: <json | null>`
### `projectileFireSettings: <json | null>`
#### `sequential: <bool>`
#### `resetProjectileIndexOnReload: <bool>`
#### `batchFire: <bool>`
## Hitscan-related Settings
## Beam-related Settings
## Summon-related Settings

# Misc
## `passiveScript: <String path | null>`
## `laser: <json>`
### `enabled: <bool | null>`
### `width: <number pixels>`
### `color: <int[3] color>`
### `range: <number pixels>`
### `trajectoryConfig: <json>`
#### `renderSteps: <int>`
### `renderUntilCursor: <bool | null>`
### `alwaysActive: <bool | null>`
## `muzzleProjectileType: <String projectileID | null>`
## `muzzleProjectileParameters: <String projectileID | null>`

# Movement
## `movementSpeedFactor: <number | null>`
## `jumpHeightFactor: <number | null>`
## `heavyWeapon: <bool | null>`

# Audiovisuals
## `performanceMode: <bool | null>`
## `debug: <bool | null>`
## `hideMuzzleFlash: <bool | null>`
## `hideMuzzleSmoke: <bool | null>`
## `enableMuzzleCritParticles: <bool | null>`
## `hollowSoundMult: <number>`
