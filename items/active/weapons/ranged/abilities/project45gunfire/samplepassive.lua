---@diagnostic disable: duplicate-set-field
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()
  self.passiveTimer = 0
  self.passiveTime = self.passiveTime or 1 -- passiveTime field can be added to the weaponAbility
end

function Passive:update(dt, fireMode, shiftheld)
  -- Example passive: replenish ammo by half of maximum ammo every second
  --[[
  if self.passiveTimer <= 0
  and self.weapon.reloadTimer < 0
  and storage.project45GunState.ammo > 0 then
    local replenished = math.floor(self.maxAmmo/2)
    self:updateAmmo(replenished)
    storage.project45GunState.unejectedCasings = math.max(0, storage.project45GunState.unejectedCasings - replenished)
    self.passiveTimer = self.passiveTime
  end
  self.passiveTimer = self.passiveTimer - dt
  --]]
end

--[[

Effective functions:

"init"
"update"
"uninit"

"onFire": runs when gun enters firing state
"onEject": runs when gun enters ejecting state
"onFeed": runs when gun enters feeding state
"onJam": runs when gun jams
"onUnjam": runs when gun is unjammed (also runs when gun is fully unjammed)
"onFullUnjam": runs when gun is fully unjammed
"onEjectMag": runs when ejecting the magazine
"onReloadStart": runs when reload starts
"onLoadRound": runs when rounds are loaded (only works on guns that load by batches)
"onReloadEnd": runs when reload ends
"onCrit": runs when evaluating a crit shot (crit doesn't necessarily have to hit the enemy)

The passive has access to the following variables

- self.passiveParameters
- self.passiveDamageMult

]]