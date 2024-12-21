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

-- Engine callback - called on initialization of entity
function init()
  restorePreservedStorage()

  self.shouldDie = true
  self.forceDie = false
  self.pathing = {}

  self.notifications = {}
  if storage.spawnPosition == nil then
    local position = mcontroller.position()
    local groundPosition = findGroundPosition(position, -20, 3)
    storage.spawnPosition = groundPosition or position
  end

  local questOutbox = Outbox.new("questOutbox", ContactList.new("questContacts"))
  self.quest = QuestParticipant.new("quest", questOutbox)
  self.quest.onOfferedQuestStarted = offeredQuestStarted
  self.quest.onOfferedQuestFinished = offeredQuestFinished

  if config.getParameter("behavior") then
    self.behavior = behavior.behavior(config.getParameter("behavior"), config.getParameter("behaviorConfig", {}), _ENV)

    self.board = self.behavior:blackboard()
    self.board:setPosition("spawn", storage.spawnPosition)
  end

  npc.setInteractive(true)
  script.setUpdateDelta(10)

  self.behaviorConfig = config.getParameter("behaviorConfig", {})
  if personality().behaviorConfig then
    self.behaviorConfig = applyDefaults(personality().behaviorConfig, self.behaviorConfig)
  end

  self.primary = npc.getItemSlot("primary")
  self.alt = npc.getItemSlot("alt")
  self.sheathedPrimary = npc.getItemSlot("sheathedprimary")
  self.sheathedAlt = npc.getItemSlot("sheathedalt")
  self.delayedSetItemSlot = {}

  self.debug = false

  mcontroller.setAutoClearControls(false)

  self.stuckCheckTime = config.getParameter("stuckCheckTime", 3.0)
  self.stuckCheckTimer = 0.1

  message.setHandler("notify", function (_, _, notification)
      return notify(notification)
    end)

  message.setHandler("suicide", function ()
      status.setResource("health", 0)
    end)

  self.uniqueId = config.getParameter("uniqueId")
  updateUniqueId()

  npc.setDamageOnTouch(true)
  npc.setAggressive(config.getParameter("aggressive", false))

  if (config.getParameter("facingDirection")) then
    mcontroller.controlFace(config.getParameter("facingDirection"))
  end

  recruitable.init()

  if type(extraInit) == "function" then
    extraInit()
  end
  status.addEphemeralEffect("beamin")

end