---@diagnostic disable: undefined-global
require "/scripts/behavior.lua"
require "/scripts/pathing.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/quest/participant.lua"
require "/scripts/relationships.lua"
require "/scripts/actions/dialog.lua"
require "/scripts/actions/movement.lua"
require "/scripts/drops.lua"
require "/scripts/statusText.lua"
require "/scripts/tenant.lua"
require "/scripts/companions/recruitable.lua"
require "/npcs/bmain.lua"

local oldInit = init

-- Engine callback - called on initialization of entity
function init()
  oldInit()
  status.addEphemeralEffect("beamin")
end