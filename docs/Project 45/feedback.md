
# Features

## Under Deliberation

- [ ] Hisdearmother: Ammo mod for shotguns that would Increase damage by 2x and recoil by 3x would be funny. (Under deliberation)

- [ ] JackieGames: a katana that can have rail attachment (i wanna phase-shift in and out of reality at will >:D muahaha) (Under Deliberation)

- [ ] container7799: yes. variants of wildcard that can change more parameters sounds good. my vision are 3 types:
  - vanilla wilcard.
  - advanced wildcard (more affected stats)
  - mystical wildcard (costs essence. doesn't consume upgrade capacity. can change almost all parameters. completely random. can break weapon)
  (Under Deliberation)

- [ ] Ryu Ketsueki: Add a way for primary and alt abilities to more easily access the installed mods of the weapon (Under Deliberation)
This is easy to achieve:
```lua
Passive = {}

function Passive:init()
  self.weapon.installedMods = config.getParameter("modSlots", {})
  -- ...
end

-- ...

```

- [ ] JamesonMDrago: A simple request not knowing how the system works: More attachments, and more attachment slots.
  If it's simple enough I want to have enough customization to make my gun truly MY gun, not just the be-all end-all (At least until absolute min/maxing comes into play), but I want my AR, MG, etc, to reflect exactly how I want to play, whether it's extreme burst damage, a constant stream of inaccurate suppressive fire, a single sniper shot, or whatever other combo I can make, I'd like to have a gun which is something which I can well and truly call "my" personal weapon, that nobody else will use quite like I will.


## Planning/Planned

## Pushed to Github

- [ ] Orifan1 : also please dear god i hope the update changes the Cyclo's charge sound. idk why but my tinnitus pops off harder than it has ever popped off before when i use it. makes it really tempting to spawn something in as a replacement for it


- [ ] Ryu Ketsueki: I refer to some items as R, SR, SSR, and XSSR in the in-game manual codex, so maybe I could alter the buildscript and the item configs to use those rarities instead (Pushed to Github)

- [ ] Also, one thing I noticed that may seem confusing at first. Since now it is possible to have manual reload on shift, you can even start the reload with shift but it only recognizes Left Click to actually click on the bar to get a perfect reload and stuff
It's possible that may throw some people off since you have to use two buttons to reload. Shift can be used to eject magazine, start reloading but can't complete the reload? If possible, can it be made so Shift also completes the reload in addition to the Left Click? (Pushed to Github)


## Tested

- [ ] Ryu Ketsueki: I wonder if it would be possible to put manual reload on Shift and make that mod available for all weapons and not only those which don't have an action on Right Shift (Pushed to Github)

## Completed

- [x] ~~container7799: add all guns in treasure pools with random stats and random installed features; what about looting? gun shop is good but i like when game decide which gun i can use, like borderlands. and also want ammo as resource.~~ (Partially implemented)

- [x] ~~LostVandal: "I love these designs. I wish more weapon mods added stuff to loot pools though. I hate having to craft all the good stuff. Finding it feels so much more rewarding."~~ (Implemented) 

- [x] ~~goblin with a fat ass: Would it be possible to turn off laser sights and whatnot while reloading? The handcannons are especially distracting with the beam spinning.~~ (Implemented)

- [x] ~~At-Las OS: a drum fed shotgun would be pretty neat~~ (Implemented)

# Bugs

## Under Deliberation

- [ ] Azure: I recently discovered a bug that when I equipped my gun - AMR to be exact - with incendiary bullets and when dealing damage to a monster with incendiary bullets, the game crushed and a pop-up says: "Exception caught in client main-loop (StarException) Unknown damage definition with kind 'physical'. " it happens occasionally but as long as you keep triggering this mod, it becomes frequent. I might also subscribed other mods related with damage (I forgot the name, but I can still remember one of which it changed the elemental effects when hit, for example: you can frozen the enemy with ice elemental weapon) when I tested this. As so far with my reasoning, I could tell this crash has something to do with the incendiary bullets. (Enhanced Elemental Effects mod bug)

## Planning/Planned

- [ ] DefinitelyNotScythe: Been testing out the weapons, I agree with JamesonMdragon, the mechanics are incredibly fun and the sound / visual designs are great, but I'd say some hard limits need to be implemented on varying damage stats or at the very least tone the damage down quite a bit on the higher end guns. Right now a high end gun with a decent mod setup can completely outclass the end game mods from most of the big gun mods, shellguard, knightfall, FU, etc.

## In Progress

- [ ] JamesonMdrago: Balance early/mid game guns

- [ ] JamesonMdrago: Balance high firerate guns

- [ ] DefinitelyNotScythe: Balance around popula gun mods e.g. shellguard, knightfall, unbound; implement range limits on damage stats?

- [ ] DefinitelyNotScythe: Easy to gain high damage with the pistol

## Pushed to Github

- [ ] Work_In_Progress: Great mod, but saying that it's breaking balance is an understatement, most of it is probably intentional but one thing that stood out for me is how mush money some wildcard mods can be sold for, in range from 200 to millions of pixels, which easily lets you get just stupid amounts of money.

- [ ] JamesonMdrago: This is ontop of the fact that humanoid enemies drop so many guns and gun mods that it absolutely floods your inventory in a single visit.

- [ ] DefinitelyNotScythe: (Regarding wildcard mods) One of them was 1389731840 pixels, and another I found had a value so high it caused an overflow and would result in -237832423462138761... too much to show up on screen lmao

## Partially Fixed

- [x] ~~Sanshi: A good portion of weapon mods uses the running animations for the holding animations, and because of this, it makes certain species visually incompatible (e.g. avali), as it has different arm animations for its run cycle.~~ (Partial fix implemented)

# Fixed

- [x] ~~Kampfbell: bk3k's Inventory mismatch issue with some of the weapon like combat rifle in the wrong category making them not moddable. I'm not sure if you've fixed the particular issue, I'm still seeing it (re-bought and dropped the weapon) but from what I noticed most of two-handed weapon would fall under the general category, while one handed such as pistol, sawed-off shotgun, bow, and weapon mod falls under weapon & armor category on bk3k's inventory which makes the former not able to mount a mod.~~ (Fixed)