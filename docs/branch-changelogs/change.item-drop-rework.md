fix: reorganized drop tables
- moved level mod drop to respective unknown stat mod drop tables
- fixed bad weights

fix: add custom attache case animation

feat: rework stat and mod drops
- Reworked stat and mod drops so that they drop in the form of cases and unknown stat mods, instead of themselves, so that gathering them won't result in a cluttered inventory. XSSR stat mods still drop as themselves.
- Added the Prototype Case, which drops XSSR gun mods.
- Decreased the weight of the max level mod.
- Increased the weight of the SSR Wildcard mod.
- Changed supplies provided by R and SR gacha drops; R drops now give 3 bandages.

fix: decrease stat drops
- Made stat drops more consistent:
  - for planet difficulties 0-3, there is a 3% chance to drop ONE tier 1 (diff. 0-1)/tier 2 (diff. 2) unknown stat mod. or ONE level mod.
  - for planet difficulties 4-5, there is a 1% chance to drop ONE tier 3 unknown stat mod, or ONE level mod.
  - for planet difficulty 6, there is a 0.5% chance to drop either ONE tier 3 unknown stat mod or ONE level mod.
  - for planet difficulty 7 and beyond, there is a 0.5% chance to drop either ONE tier 3 unknown stat mod or ONE XSSR mod (i.e. either a god mod or an admin mod).

feat: add unknown stat mod "rewardbags"
- added unknown stat mod reward bags to help with inventory congestion
- changed treasure pools to accommodate this change

init: reworked-drops
- add project45-attachecase, project45-oldattachecase and project45-wornattachecase