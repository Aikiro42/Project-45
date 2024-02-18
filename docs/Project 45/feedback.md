
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

## Planning/Planned

## Pushed to Github

- [ ] Ryu Ketsueki: I wonder if it would be possible to put manual reload on Shift and make that mod available for all weapons and not only those which don't have an action on Right Shift (Pushed to Github)

- [ ] Ryu Ketsueki: I refer to some items as R, SR, SSR, and XSSR in the in-game manual codex, so maybe I could alter the buildscript and the item configs to use those rarities instead (Pushed to Github)

## Tested

## Completed

- [x] ~~container7799: add all guns in treasure pools with random stats and random installed features; what about looting? gun shop is good but i like when game decide which gun i can use, like borderlands. and also want ammo as resource.~~ (Partially implemented)

- [x] ~~LostVandal: "I love these designs. I wish more weapon mods added stuff to loot pools though. I hate having to craft all the good stuff. Finding it feels so much more rewarding."~~ (Implemented) 

- [x] ~~goblin with a fat ass: Would it be possible to turn off laser sights and whatnot while reloading? The handcannons are especially distracting with the beam spinning.~~ (Implemented)

- [x] ~~At-Las OS: a drum fed shotgun would be pretty neat~~ (Implemented)

# Bugs

## Under Deliberation

- [ ] Azure: I recently discovered a bug that when I equipped my gun - AMR to be exact - with incendiary bullets and when dealing damage to a monster with incendiary bullets, the game crushed and a pop-up says: "Exception caught in client main-loop (StarException) Unknown damage definition with kind 'physical'. " it happens occasionally but as long as you keep triggering this mod, it becomes frequent. I might also subscribed other mods related with damage (I forgot the name, but I can still remember one of which it changed the elemental effects when hit, for example: you can frozen the enemy with ice elemental weapon) when I tested this. As so far with my reasoning, I could tell this crash has something to do with the incendiary bullets. (Enhanced Elemental Effects mod bug)

## Planning/Planned

- [ ] JamesonMdrago: If you stack the right mods on the LMG (God mod included, no that's not a joke name), you can get 5 digits of DPS on a single target, to say nothing of getting a lucky wildcard to sell for ridiculous valuation, the efficiency of the guns, or other characteristics about the other guns.

- [ ] JamesonMdrago: This is ontop of the fact that humanoid enemies drop so many guns and gun mods that it absolutely floods your inventory in a single visit.

- [ ] JamesonMdrago: it absolutely needs a very hard balance pass, primarily with even early/mid game gun builds, primarily with guns that have a high RoF.

- [ ] DefinitelyNotScythe: Been testing out the weapons, I agree with JamesonMdragon, the mechanics are incredibly fun and the sound / visual designs are great, but I'd say some hard limits need to be implemented on varying damage stats or at the very least tone the damage down quite a bit on the higher end guns. Right now a high end gun with a decent mod setup can completely outclass the end game mods from most of the big gun mods, shellguard, knightfall, FU, etc.

  One of them was 1389731840 pixels, and another I found had a value so high it caused an overflow and would result in -237832423462138761... too much to show up on screen lmao

  In a similar line, I noticed it's easy to hit incredibly high damage numbers, casually hitting the thousands per hit range on a basic pistol I was messing with. I'm not sure what you want to aim for, I know you do have the "cheats and god items" tag but in the description you mentioned trying to balance around "endgame" with a notice that things may become overpowered.

  But I imagine you are trying to aim for balance around the endgame of some of the common gun mods like shellguard or knightfall, in which case if you are, and if it's possible, I think implementing range limits on damage stats as well would be a good idea

  In addition to my previous comment, while I'm not sure, it *may* be possible that the mod **"Tougher Mobs with Better Loot!"** which increases loot rates and makes mobs in general harder, might be influencing the drops. I'm not sure if the wildcard stats are at all tied to rarity in the traditional sense, but I figured it could be worth mentioning just in case. I know the mods certainly seemed to drop quite a bit more often at the very least, but I never did any proper analysis


- [ ] Work_In_Progress: Great mod, but saying that it's breaking balance is an understatement, most of it is probably intentional but one thing that stood out for me is how mush money some wildcard mods can be sold for, in range from 200 to millions of pixels, which easily lets you get just stupid amounts of money.

## Pushed to Github

## Partially Fixed

- [x] ~~Sanshi: A good portion of weapon mods uses the running animations for the holding animations, and because of this, it makes certain species visually incompatible (e.g. avali), as it has different arm animations for its run cycle.~~ (Partial fix implemented)

# Fixed

- [x] ~~Kampfbell: bk3k's Inventory mismatch issue with some of the weapon like combat rifle in the wrong category making them not moddable. I'm not sure if you've fixed the particular issue, I'm still seeing it (re-bought and dropped the weapon) but from what I noticed most of two-handed weapon would fall under the general category, while one handed such as pistol, sawed-off shotgun, bow, and weapon mod falls under weapon & armor category on bk3k's inventory which makes the former not able to mount a mod.~~ (Fixed)