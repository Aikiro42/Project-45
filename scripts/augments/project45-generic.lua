require "/scripts/set.lua"
require "/scripts/util.lua"
require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"

-- Generic Mod Application. All of the stuff in augment will be applied on the weapon.
function apply(input)

  local augment = config.getParameter("augment")
  if augment then

    -- fail if certain parameters (specified in checks) are already modified
    local checks = config.getParameter("checks", {})
    for _, k in ipairs(checks) do
      if input.parameters[k] ~= nil then return end
    end

    local output

    -- normally an item is generated with Item.new() before the augment is applied.
    -- this allows the cart before the horse or something.
    -- downside is, we can't access the config of the item without generating with root.itemConfig()
    -- we wanna generate ONCE as much as possible
    local applyBeforeBuild = config.getParameter("applyBeforeBuild")
    if not applyBeforeBuild then
      output = Item.new(input)
      local modInfo = output:instanceValue("project45GunModInfo")
      if not modInfo then return end   
    else
      output = input
      output.setInstanceValue = function(self, name, value)
        self.parameters[name] = value
      end
    end
    
    -- apply augment stuff verbatim
    for k, v in pairs(augment) do
      output:setInstanceValue(k, sb.jsonMerge(input.parameters[k] or {}, v))
    end

    if applyBeforeBuild then
      output.setInstanceValue = nil  -- prevent errors when generating new output
      local new_output = Item.new(output)
      local modInfo = new_output:instanceValue("project45GunModInfo")
      if not modInfo then return end   
      output = new_output
    end

    return output, 1


  end
end