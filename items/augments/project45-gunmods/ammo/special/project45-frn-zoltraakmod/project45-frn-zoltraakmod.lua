---@diagnostic disable: duplicate-set-field
require "/scripts/set.lua"
require "/items/active/weapons/ranged/abilities/project45gunfire/project45passive.lua"

Passive = Project45Passive:new()

function Passive:init()
  self.spellIds = {}
end

function Passive:update(dt, fireMode, shiftheld)
  self.spellIds = util.filter(self.spellIds, world.entityExists)
  for _, spellId in pairs(self.spellIds) do
    world.callScriptedEntity(spellId, "setTargetPosition", activeItem.ownerAimPosition())
  end
end

function Passive:onSpawnProjectile(projectileId)
  table.insert(self.spellIds, projectileId)
end
