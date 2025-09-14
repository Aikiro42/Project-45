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

# <span style="color: #E2C344">Introduction</span>
Project 45 guns are different from vanilla guns in the following aspects:

1. They have the ability to <span style="color: #D93A3A">crit</span> (and <span style="color: #f4988c">supercrit beyond 100% chance</span>).
2. They are more <span style="color: #51BD3B">energy-efficient</span> due to being ammo-based.
3. They are <span style="color: #d29ce7">modifiable and upgradable</span> on the fly.
4. Some fire different kinds of projectiles.
5. Most can be converted to fire other kinds of projectiles.

# <span style="color: #E2C344">Weapon Stats</span>
- <span style="color: #95d1f3">Upgrade Capacity</span>: The number of Stat Mods you can install on the weapon.
- <span style="color: #EA9931">Damage per Shot</span>: The range of damage a gun's (initial) projectiles will deal at 100% power multiplier, disregarding the target's defense.
- <span style="color: #E2C344">Fire Time</span>: the overall time it takes for the gun to fire: <span style="color: #f4988c">Charge Time</span>, <span style="color: #E2C344">Cycle Time</span> and <span style="color: #9da8af">Trigger Time</span>.
#

- <span style="color: #51BD3B">Reload Cost</span>: the total percentage of energy required to reload a gun to its full capacity.
- <span style="color: #cccccc">Reload Time</span>: the maximum possible amount of time it takes to reload a gun to its full capacity. This also includes the <span style="color: #E2C344">Cock Time</span> of the weapon.
#

- <span style="color: #D93A3A">Crit Chance</span>: the chance of the gun dealing increased damage. Odds beyond 100% give shots a chance to deal even more damage (i.e. a <span style="color: #f4988c">\"Supercrit\"</span>).
- <span style="color: #D93A3A">Crit Damage</span>: the number multiplied to the projectile's damage when it deals a super/crit.


# <span style="color: #E2C344">Firing & Recoil</span>
Project 45 guns fire like any other gun, except they have a relatively predictable recoil.

When firing, your gun's muzzle will kick up, and you will have to adjust your aim downward to counteract the recoil.

Take a moment to steady your aim; <span style="color: #D93A3A">projectile direction is based on the angle of your gun</span>.

#
The amount of recoil is also affected by how much you're moving, whether you're walking, running or standing still.

To drastically reduce recoil, it is recommended to shoot while crouched. You could also modify your weapon with mods that reduce recoil.

# <span style="color: #E2C344">Charged Weapons</span>
Some weapons require to be charged before being able to fire them, and some continue <span style="color: #96cbe7">overcharging</span> to deal bonus damage.

The charge level of the weapon is indicated below the chamber indicator:

- If the bar is <span style="color: #838383">gray</span>, the weapon is charging and <span style="color: #D93A3A">cannot be triggered to fire</span>.

#
- If the bar is <span style="color: #E2C344">yellow</span> turning <span style="color: #D93A3A">red</span>, the weapon is <span style="color: #96cbe7">overcharging</span>. Projectiles fired by the weapon while the charge level is in this <span style="color: #96cbe7">deals up to 2x bonus damage</span> at <span style="color: #D93A3A">full overcharge</span>.
- If the bar is lit up, the charge is <span style="color: #E2C344">perfect</span>; Projectiles fired by the weapon during perfect charge <span style="color: #E2C344">deals at least 2x bonus damage</span>.

# <span style="color: #E2C344">Misc Stats</span>
These stats are not necessarily shown in the weapon's tooltip, but affect the weapon's performance nonetheless.
- <span style="color: #96cbe7">Multishot</span>: Multiplier to the number of projectiles a weapon fires. Decimals are treated as odds that the gun fires an additional set of projectiles.
- <span style="color: #f4988c">Heavy</span>: Forces the wielder to walk while holding the weapon.
- <span style="color: #f4988c">Recoil</span>: Multiplier to the kick-up angle (and maximum recoil angle) of the gun when firing.

#
- <span style="color: #f4988c">Inaccuracy</span>: Random movement of the arm as the weapon fires.
- <span style="color: #f4988c">Spread</span>: Natural deviation of bullets from their trajectory.
- <span style="color: #9da8af">Trigger Time</span>: Amount of time it takes before registering the next click. A factor of overall <span style="color: #E2C344">fire time</span>.


# <span style="color: #E2C344">Ammo & Reloading</span>
You will have an indicator next to your crosshair showing the amount of ammo your weapon has.

- If the indicator is <span style="color: #D93A3A">\"0\"</span>, you'll need to eject the mag to reload: <span style="color: #EA9931">fire the gun to eject the mag</span>.
- If the indicator is <span style="color: #D93A3A">\"E\"</span>, the weapon has no mag: <span style="color: #EA9931">Fire the gun to consume energy and begin reloading.</span>

If you have <span style="color: #EA9931">OSB</span> or <span style="color: #EA9931">StarExtensions</span>, press <span style="color: #EA9931">'V' (default)</span> to eject the mag.
#
When you begin reloading, a vertical bar with a colored section will appear in place of the ammo indicator, and a red line will move up along it.

<span style="color: #EA9931">Fire the weapon when the red line is over the colored region to execute an Active Reload, finishing the reloading process early.</span>

Take a moment to ready your aim after reloading; firing immediately can shoot projectiles off-target.

# <span style="color: #E2C344">Reload Rating</span>
Your weapon's performance will change depending on whether you executed an Active Reload and whether you hit the colored regions:

<span style="color: #E2C344">PERFECT</span> - Hitting the lighter-colored region gives your gun a <span style="color: #E2C344">1.3x damage bonus</span> and <span style="color: #E2C344">completely prevents jamming</span>

#
<span style="color: #60B8EA">GOOD</span> - Hitting the darker-colored region gives your gun a <span style="color: #60B8EA">1.1x damage bonus</span> and <span style="color: #60B8EA">completely prevents jamming</span>.

OK - Allowing the red line to reach the end of the bar will simply reload your gun.

<span style="color: #D93A3A">BAD</span> - Hitting the white region will <span style="color: #D93A3A">increase the chance of a gun jam happening</span>

# <span style="color: #E2C344">Per-bullet Reload</span>
Some guns allow you to reload them on a per-bullet or per-clip basis. The \"reload rating\" of your gun (discussed in the previous section) depends on your \"reload score\" from reloading each (set of) bullets:

- <span style="color: #E2C344">Perfect reloads are worth 2 points.</span>
- <span style="color: #60B8EA">Good reloads are worth 1 point.</span>
- <span style="color: #D93A3A">Bad reloads are worth 0 points.</span>

#
Allowing the red line to reach the end of the bar will end the reload sequence, leaving your gun with the amount of ammo you ended up with.

Your <span style="color: #EA9931">reload score</span> will be evaluated at the end of the reload sequence: This is the <span style="color: #EA9931">total reload rating points divided by the number of bullets/clips you loaded</span>.

#
Your per-bullet reload rating is evaluated as thus:

- <span style="color: #E2C344">>1 (i.e. more points than reloads): PERFECT RATING</span>
- <span style="color: #60B8EA">>0.66 (i.e. two-thirds of reloads): GOOD RATING</span>
- >0.33 (i.e. one-thirds of reloads): OK RATING
- <span style="color: #D93A3A">Worse: BAD RATING</span>.

# <span style="color: #E2C344">Stock Ammo</span>
You can stock ammo on your gun to <span style="color: #ea9931">increase its damage (up to 2x)</span> based on the amount of ammo stocked.

Ammo Stock can be bought from the Gun Shop, or can be dropped in by the Supply Transponder.


# <span style="color: #E2C344">Jamming</span>
Some guns have a chance to jam when firing, especially when reloaded badly. When they do, they fail to fire, and an orange jam bar appears beside the crosshair.

<span style="color: #EA9931">Press the fire button to deplenish the jam bar.</span>

Your gun will unjam and load the next round when the jam bar is empty.

# <span style="color: #E2C344">Gun Modding</span>
Modding weapons is similar to installing augments on EPPs. Whether you can install a mod on a weapon or not is largely dependent on their <span style="color: #d29ce7">Categories</span>, <span style="color: #95d1f3">Upgrade Capacity</span> and associated <span style="color: #9da8af">Mod Slots</span>. For ammo mods, their <span style="color: #EA9931">Archetype</span> also matters.

If a mod cannot be installed on a weapon, it will be indicated the next time you hold your weapon via red text that appears above the player character's head.

# <span style="color: #E2C344">Stat Bonuses</span>
Weapons spawn with a seeded stat <span style="color: #96cbe7">bonus ratio</span>.

The weapons can have
- up to a <span style="color: #ea9931">+12%</span> bonus to their base damage,
- up to a <span style="color: #f4988c">+20%</span> bonus to their base critical chance, and
- up to a <span style="color: #d93a3a">+6%</span> bonus to their base critical damage multiplier.

#
For example, if a weapon is indicated to bear a \"60% bonus\", this means that they get
- 1 + <span style="color: #96cbe7">0.6</span> * <span style="color: #ea9931">0.12</span> = <span style="color: #ea9931">x1.072 multiplier to their base damage</span>
- 1 + <span style="color: #96cbe7">0.6</span> * <span style="color: #f4988c">0.20</span> = <span style="color: #f4988c">x1.120 multiplier to their base crit chance</span>
- 1 + <span style="color: #96cbe7">0.6</span> * <span style="color: #d93a3a">0.06</span> = <span style="color: #d93a3a">x1.036 multiplier to their base crit damage</span>

Items bought from the Project 45 Gun Shop can only have a maximum bonus ratio of <span style="color: #d93a3a">50%.</span>

# <span style="color: #E2C344">The Supply Transponder</span>
<span style="color: #eab3db">The Supply Transponder</span> provides a relatively affordable way to obtain various Project 45 items. You can purchase one from the Gun Shop, and it comes with 10 free Cipher Keys applied.

It is recommended to use this on the surface of a planet: To call in a Project 45 item, activate the transponder and a supply pod will drop down. Attack and destroy the pod to obtain the item(s).

#
The transponder can call in supplies via applied Cipher Keys, or via Essence. <span style="color: #a451c4">(300 essence per pull)</span> To add Cipher keys to the transponder, simply apply them like a weapon mod.

#
The transponder has the following odds for calling in a pod with:

- a <span style="color: #96cbe7">50%</span> chance to drop a <span style="color: #96cbe7">Common or Rare Supply Drop (R)</span>,
- a <span style="color: #cb44ff">46%</span> chance to drop a <span style="color: #cb44ff">Rare or higher rarity Supply Drop (SR)</span>,
- a <span style="color: #ffffa7">2%</span> chance to drop an <span style="color: #ffffa7">Essential Supply Drop (SSR)</span>, and
- a <span style="color: #f4988c">2%</span> chance to drop <span style="color: #f4988c">Unique Essential Supply Drop (XSSR)</span>.

# <span style="color: #E2C344">The Supply Transponder</span>
The transponder will guarantee you a <span style="color: #f4988c">Unique (XSSR)</span> drop within the first 25 calls. After that, it will guarantee you either a <span style="color: #f4988c">Unique (XSSR)</span> or <span style="color: #ffffa7">Essential (SSR)</span> drop within the next 25 calls thereafter.

If you obtain an <span style="color: #ffffa7">Essential (SSR)</span> drop, you are guaranteed a ^##f4988c;Unique (XSSR)</span> drop within the next 25 calls. This guarantee is indicated with a <span style="color: #e2c344">yellow pity counter</span>.

# <span style="color: #E2C344">(Quickbar) Mod Settings</span>
If you have Stardust Core/Lite or Quickbar Mini installed, you can change the following settings:
- <span style="color: #EA9931">Performance Mode:</span> If this setting is ticked,
    - most particles (e.g. casings, smoke) will not be emitted,
    - dynamic audio (hollow sounds, firing sound pitch changes) is disabled, and
    - screenshake, magazine animations, and lasers are disabled

#
- <span style="color: #EA9931">Render Bars Beside Cursor:</span> If this setting is ticked, the reload bar and jam bar will be rendered beside the cursor.
- <span style="color: #EA9931">Use Reload/Empty Images:</span> If this setting is ticked, animated sprites will be used to indicate a reloading or empty gun, instead of 'R' and 'E'.
    - <span style="color: #D93A3A">Enabling Performance Mode disables this setting.</span>

#
- <span style="color: #EA9931">Accurate Reload/Charge Bars:</span> If this setting is ticked, drawables will be used to render both the reload ranges and arrow and the charge bar progress.
    - <span style="color: #D93A3A">Enabling Performance Mode disables this setting.</span>