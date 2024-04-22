require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)

  if input.name == "project45-gunbag" or input.name == "project45-gachabag" then
    local output = Item.new(input)
    local pullsAdd = config.getParameter("pullsAdd", 1)
    output:setInstanceValue("pulls", (input.parameters.pulls or 1) + pullsAdd)
    return output
  end

end
