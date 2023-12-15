require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)

  if input.name == "project45gacha" then
    local output = Item.new(input)
    output:setInstanceValue("pulls", (input.parameters.pulls or 1) + 1)
    return output
  end

end
