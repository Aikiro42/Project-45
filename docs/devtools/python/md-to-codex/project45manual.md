<!-- this is a comment -->
<!--
this is
a block comment
-->
# <span style="color: #E2C344">Contents</span>
- Introduction
- Weapon Stats
- Firing & Recoil
- Charged Weapons
- Misc Stats
- Ammo & Reloading
- Reload Rating
#
- Per-Bullet Reload
- Stock Ammo
- Jamming
- Gun Modding
- Stat Bonuses
- The Supply Transponder
- (Quickbar) Mod Settings

# ^#E2C344;Introduction^reset;
Project 45 guns are different from vanilla guns in the following aspects:

1. They have the ability to ^#D93A3A;crit^reset; (and ^#f4988c;supercrit beyond 100% chance^reset;).
2. They are more ^#51BD3B;energy-efficient^reset; due to being ammo-based.
3. They are ^#d29ce7;modifiable and upgradable^reset; on the fly.
4. Some fire different kinds of projectiles.
5. Most can be converted to fire other kinds of projectiles.

# ^#E2C344;Weapon Stats^reset;
- ^#95d1f3;Upgrade Capacity^reset;: The number of Stat Mods you can install on the weapon.
- ^#EA9931;Damage per Shot^reset;: The range of damage a gun's (initial) projectiles will deal at 100% power multiplier, disregarding the target's defense.
- ^#E2C344;Fire Time^reset;: the overall time it takes for the gun to fire: ^#f4988c;Charge Time^reset;, ^#E2C344;Cycle Time^reset; and ^#9da8af;Trigger Time^reset;.
#

- ^#51BD3B;Reload Cost^reset;: the total percentage of energy required to reload a gun to its full capacity.
- ^#cccccc;Reload Time^reset;: the maximum possible amount of time it takes to reload a gun to its full capacity. This also includes the <span style="color: #E2C344">Cock Time</span> of the weapon.
#

- ^#D93A3A;Crit Chance^reset;: the chance of the gun dealing increased damage. Odds beyond 100% give shots a chance to deal even more damage (i.e. a <span style="color: #f4988c">\"Supercrit\"</span>).
- ^#D93A3A;Crit Damage^reset;: the number multiplied to the projectile's damage when it deals a super/crit.


# ^#E2C344;Firing & Recoil^reset;
Project 45 guns fire like any other gun, except they have a relatively predictable recoil.

When firing, your gun's muzzle will kick up, and you will have to adjust your aim downward to counteract the recoil.

Take a moment to steady your aim; ^#D93A3A;projectile direction is based on the angle of your gun^reset;.

#
The amount of recoil is also affected by how much you're moving, whether you're walking, running or standing still.

To drastically reduce recoil, it is recommended to shoot while crouched. You could also modify your weapon with mods that reduce recoil.

# ^#E2C344;Charged Weapons^reset;
Some weapons require to be charged before being able to fire them, and some continue ^#96cbe7;overcharging^reset; to deal bonus damage.

The charge level of the weapon is indicated below the chamber indicator:

- If the bar is ^#838383;gray^reset;, the weapon is charging and ^#D93A3A;cannot be triggered to fire^reset;.

#
- If the bar is ^#E2C344;yellow^reset; turning ^#D93A3A;red^reset;, the weapon is ^#96cbe7;overcharging^reset;. Projectiles fired by the weapon while the charge level is in this ^#96cbe7;deals up to 2x bonus damage^reset; at ^#D93A3A;full overcharge^reset;.
- If the bar is lit up, the charge is ^#E2C344;perfect^reset;; Projectiles fired by the weapon during perfect charge ^#E2C344;deals at least 2x bonus damage^reset;.

# ^#E2C344;Misc Stats^reset;
These stats are not necessarily shown in the weapon's tooltip, but affect the weapon's performance nonetheless.
- ^#96cbe7;Multishot^reset;: Multiplier to the number of projectiles a weapon fires. Decimals are treated as odds that the gun fires an additional set of projectiles.
- ^#f4988c;Heavy^reset;: Forces the wielder to walk while holding the weapon.
- ^#f4988c;Recoil^reset;: Multiplier to the kick-up angle (and maximum recoil angle) of the gun when firing.

#
- ^#f4988c;Inaccuracy^reset;: Random movement of the arm as the weapon fires.
- ^#f4988c;Spread^reset;: Natural deviation of bullets from their trajectory.
- ^#9da8af;Trigger Time^reset;: Amount of time it takes before registering the next click. A factor of overall ^#E2C344;fire time^reset;.


# ^#E2C344;Ammo & Reloading^reset;
You will have an indicator next to your crosshair showing the amount of ammo your weapon has.
- If the indicator is ^#D93A3A;\"0\"^reset;, you will need to eject the magazine to reload. In this case, ^#EA9931;fire the gun to eject the magazine^reset;.
- If the indicator is ^#D93A3A;\"E\"^reset;, the weapon has no magazine - you are ready to reload. ^#EA9931;Fire the gun to consume energy and begin reloading.^reset;

#
When you begin reloading, a vertical bar with a colored section will appear in place of the ammo indicator, and a red line will move up along it.

^#EA9931;Fire the weapon when the red line is over the colored region to execute an Active Reload, finishing the reloading process early.^reset;

Take a moment to ready your aim after reloading; firing immediately can shoot projectiles off-target.

# ^#E2C344;Reload Rating^reset;
Your weapon's performance will change depending on whether you executed an Active Reload and whether you hit the colored regions:

^#E2C344;PERFECT^reset; - Hitting the lighter-colored region gives your gun a ^#E2C344;1.3x damage bonus^reset; and ^#E2C344;completely prevents jamming^reset;

#
^#60B8EA;GOOD^reset; - Hitting the darker-colored region gives your gun a ^#60B8EA;1.1x damage bonus^reset; and ^#60B8EA;completely prevents jamming^reset;.

OK - Allowing the red line to reach the end of the bar will simply reload your gun.

^#D93A3A;BAD^reset; - Hitting the white region will ^#D93A3A;increase the chance of a gun jam happening^reset;

# ^#E2C344;Per-bullet Reload^reset;
Some guns allow you to reload them on a per-bullet or per-clip basis. The \"reload rating\" of your gun (discussed in the previous section) depends on your \"reload score\" from reloading each (set of) bullets:

- ^#E2C344;Perfect reloads are worth 2 points.^reset;
- ^#60B8EA;Good reloads are worth 1 point.^reset;
- ^#D93A3A;Bad reloads are worth 0 points.^reset;

#
Allowing the red line to reach the end of the bar will end the reload sequence, leaving your gun with the amount of ammo you ended up with.

Your <span style="color: #EA9931">reload score</span> will be evaluated at the end of the reload sequence: This is the <span style="color: #EA9931">total reload rating points divided by the number of bullets/clips you loaded</span>.

#
Your per-bullet reload rating is evaluated as thus:

- ^#E2C344;>1 (i.e. more points than reloads): PERFECT RATING^reset;
- ^#60B8EA;>0.66 (i.e. two-thirds of reloads): GOOD RATING^reset;
- >0.33 (i.e. one-thirds of reloads): OK RATING
- ^#D93A3A;Worse: BAD RATING^reset;.

# ^#E2C344;Stock Ammo^reset;
You can stock ammo on your gun to ^#ea9931;increase its damage (up to 2x)^reset; based on the amount of ammo stocked.

Ammo Stock can be bought from the Gun Shop, or can be dropped in by the Supply Transponder.


# ^#E2C344;Jamming^reset;
Some guns have a chance to jam when firing, especially when reloaded badly. When they do, they fail to fire, and an orange jam bar appears beside the crosshair.

^#EA9931;Press the fire button to deplenish the jam bar.^reset;

Your gun will unjam and load the next round when the jam bar is empty.

# ^#E2C344;Gun Modding^reset;
Modding weapons is similar to installing augments on EPPs. Whether you can install a mod on a weapon or not is largely dependent on their ^#d29ce7;Categories^reset;, ^#95d1f3;Upgrade Capacity^reset; and associated ^#9da8af;Mod Slots^reset;. For ammo mods, their ^#EA9931;Archetype^reset; also matters.

If a mod cannot be installed on a weapon, it will be indicated the next time you hold your weapon via red text that appears above the player character's head.

# ^#E2C344;Stat Bonuses^reset;
Weapons spawn with a seeded stat ^#96cbe7;bonus ratio^reset;.

The weapons can have
- up to a ^#ea9931;+12%^reset; bonus to their base damage,
- up to a ^#f4988c;+20%^reset; bonus to their base critical chance, and
- up to a ^#d93a3a;+6%^reset; bonus to their base critical damage multiplier.

#
For example, if a weapon is indicated to bear a \"60% bonus\", this means that they get
- 1 + ^#96cbe7;0.6^reset; * ^#ea9931;0.12^reset; = ^#ea9931;x1.072 multiplier to their base damage^reset;
- 1 + ^#96cbe7;0.6^reset; * ^#f4988c;0.20^reset; = ^#f4988c;x1.120 multiplier to their base crit chance^reset;
- 1 + ^#96cbe7;0.6^reset; * ^#d93a3a;0.06^reset; = ^#d93a3a;x1.036 multiplier to their base crit damage^reset;

Items bought from the Project 45 Gun Shop can only have a maximum bonus ratio of ^#d93a3a;50%.^reset;

# ^#E2C344;The Supply Transponder^reset;
^#eab3db;The Supply Transponder^reset; provides a relatively affordable way to obtain various Project 45 items. You can purchase one from the Gun Shop, and it comes with 10 free Cipher Keys applied.

It is recommended to use this on the surface of a planet: To call in a Project 45 item, activate the transponder and a supply pod will drop down. Attack and destroy the pod to obtain the item(s).

#
The transponder can call in supplies via applied Cipher Keys, or via Essence. ^#a451c4;(300 essence per pull)^reset; To add Cipher keys to the transponder, simply apply them like a weapon mod.

#
The transponder has the following odds for calling in a pod with:

- a ^#96cbe7;50%^reset; chance to drop a ^#96cbe7;Common or Rare Supply Drop (R)^reset;,
- a ^#cb44ff;46%^reset; chance to drop a ^#cb44ff;Rare or higher rarity Supply Drop (SR)^reset;,
- a ^#ffffa7;2%^reset; chance to drop an ^#ffffa7;Essential Supply Drop (SSR)^reset;, and
- a ^#f4988c;2%^reset; chance to drop ^#f4988c;Unique Essential Supply Drop (XSSR)^reset;.

# ^#E2C344;The Supply Transponder^reset;
The transponder will guarantee you a ^#f4988c;Unique (XSSR)^reset; drop within the first 25 calls. After that, it will guarantee you either a ^#f4988c;Unique (XSSR)^reset; or ^#ffffa7;Essential (SSR)^reset; drop within the next 25 calls thereafter.

If you obtain an ^#ffffa7;Essential (SSR)^reset; drop, you are guaranteed a ^##f4988c;Unique (XSSR)^reset; drop within the next 25 calls. This guarantee is indicated with a ^#e2c344;yellow pity counter^reset;.

# ^#E2C344;(Quickbar) Mod Settings^reset;
If you have Stardust Core/Lite or Quickbar Mini installed, you can change the following settings:
- ^#EA9931;Performance Mode:^reset; If this setting is ticked,
    - most particles (e.g. casings, smoke) will not be emitted,
    - dynamic audio (hollow sounds, firing sound pitch changes) is disabled, and
    - screenshake, magazine animations, and lasers are disabled

#
- ^#EA9931;Render Bars Beside Cursor:^reset; If this setting is ticked, the reload bar and jam bar will be rendered beside the cursor.
- ^#EA9931;Use Reload/Empty Images:^reset; If this setting is ticked, animated sprites will be used to indicate a reloading or empty gun, instead of 'R' and 'E'.
    - ^#D93A3A;Enabling Performance Mode disables this setting.^reset;

#
- ^#EA9931;Accurate Reload/Charge Bars:^reset; If this setting is ticked, drawables will be used to render both the reload ranges and arrow and the charge bar progress.
    - ^#D93A3A;Enabling Performance Mode disables this setting.^reset;