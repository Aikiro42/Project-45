require "/scripts/util.lua"

gunmodHelper = {}

function gunmodHelper.addMessage(input, message)
  local messages = {""}
  for _, m in ipairs(input.parameters.project45GunFireMessages or {}) do
    table.insert(messages, m)
  end
  table.insert(messages, message)
  table.remove(messages, 1)
  local output = Item.new(input)
  output:setInstanceValue("project45GunFireMessages", messages)
  return output:descriptor(), 0
end