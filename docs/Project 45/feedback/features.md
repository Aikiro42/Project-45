
`DefinitelyNotScythe, 2024-02-19`: Technically not a feature but it would be a good idea imo to create a Discord server to handle feature requests, so that people can upvote/downvote ideas, to get a better idea of what's liked and disliked

---

- [ ] `Work_In_Progress, 2024-02-19`I don't know if it's to hard to impliment this, but it's would've been just awesome to see coin mechanic from ULTRAKILL, when you can toss a coin in the air and then shoot to ricochet bullet at the enemy


- [ ] `Hisdearmother`: Ammo mod for shotguns that would Increase damage by 2x and recoil by 3x would be funny. (Under deliberation)

- [ ] `JackieGames, 2024-02-18`: a katana that can have rail attachment (i wanna phase-shift in and out of reality at will >:D muahaha) (Under Deliberation)

- [ ] `container7799`: yes. variants of wildcard that can change more parameters sounds good. my vision are 3 types:
  - vanilla wilcard.
  - advanced wildcard (more affected stats)
  - mystical wildcard (costs essence. doesn't consume upgrade capacity. can change almost all parameters. completely random. can break weapon)
  (Under Deliberation)

- [ ] `Ryu Ketsueki`: Add a way for primary and alt abilities to more easily access the installed mods of the weapon (Under Deliberation)
This is easy to achieve:
```lua
Passive = {}

function Passive:init()
  self.weapon.installedMods = config.getParameter("modSlots", {})
  -- ...
end

-- ...

```

- [ ] `JamesonMDrago, 2024-02-18`: A simple request not knowing how the system works: More attachments, and more attachment slots.
  If it's simple enough I want to have enough customization to make my gun truly MY gun, not just the be-all end-all (At least until absolute min/maxing comes into play), but I want my AR, MG, etc, to reflect exactly how I want to play, whether it's extreme burst damage, a constant stream of inaccurate suppressive fire, a single sniper shot, or whatever other combo I can make, I'd like to have a gun which is something which I can well and truly call "my" personal weapon, that nobody else will use quite like I will.

- [ ] `Hisdearmother (poggers), 2024-02-22`: An attachment for rocket launchers that allows rocket jumping, decreases damage, and increases max ammo would be awesome.

- [ ] `Orifan1, 2024-02-21`: additional sources of multishot pls?

- [ ] `Orifan1, 2024-02-26`: so... you know the singularity ammo for summon weapons? can we get a weak and cheap earlygame version of that? the utility of actually being able to pick up your ship pet and move it so you can access something its standing in front of is quite useful. same goes for NPCs in hub worlds, actually


## Pushed to Github

- [ ] `Orifan1` : also please dear god i hope the update changes the Cyclo's charge sound. idk why but my tinnitus pops off harder than it has ever popped off before when i use it. makes it really tempting to spawn something in as a replacement for it

- [ ] `Ryu Ketsueki`: I refer to some items as R, SR, SSR, and XSSR in the in-game manual codex, so maybe I could alter the buildscript and the item configs to use those rarities instead (Pushed to Github)

- [ ] `Ryu Ketsueki`: Also, one thing I noticed that may seem confusing at first. Since now it is possible to have manual reload on shift, you can even start the reload with shift but it only recognizes Left Click to actually click on the bar to get a perfect reload and stuff. It's possible that may throw some people off since you have to use two buttons to reload. Shift can be used to eject magazine, start reloading but can't complete the reload? If possible, can it be made so Shift also completes the reload in addition to the Left Click? (Pushed to Github)

## Tested

- [ ] `Ryu Ketsueki`: I wonder if it would be possible to put manual reload on Shift and make that mod available for all weapons and not only those which don't have an action on Right Shift (Pushed to Github)

## Completed

- [x] ~~`container7799`: add all guns in treasure pools with random stats and random installed features; what about looting? gun shop is good but i like when game decide which gun i can use, like borderlands. and also want ammo as resource.~~ (Partially implemented)

- [x] ~~`LostVandal`: "I love these designs. I wish more weapon mods added stuff to loot pools though. I hate having to craft all the good stuff. Finding it feels so much more rewarding."~~ (Implemented) 

- [x] ~~`goblin with a fat ass`: Would it be possible to turn off laser sights and whatnot while reloading? The handcannons are especially distracting with the beam spinning.~~ (Implemented)

- [x] ~~`At-Las OS`: a drum fed shotgun would be pretty neat~~ (Implemented)

