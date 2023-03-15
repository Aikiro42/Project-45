require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/actions/world.lua"
require "/scripts/async.lua"

function apply(input)

  if input.parameters.acceptsGunMods and input.parameters.isModded then
    local output = Item.new(root.createItem(input.name))
    return output:descriptor(), 1
  end

end
