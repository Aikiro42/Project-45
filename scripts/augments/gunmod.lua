require "/scripts/augments/item.lua"
require "/scripts/util.lua"

function apply(input)
  local augment = config.getParameter("augment")
  local output = Item.new(input)
  
  if augment then
    
    local modTypeCheck = output:instanceValue("acceptsModType", {sights = false, rail = false, stat = false})
    
    if modTypeCheck[augment.type] then

      if augment.altAbilityType and input.parameters.altAbilityType ~= augment.altAbilityType then
      
        output:setInstanceValue("altAbilityType", augment.altAbilityType)
        output:setInstanceValue("twoHanded", true)
              
        if augment.altAbility then
          output:setInstanceValue("altAbility", augment.altAbility)
        end
        
      end
                
      return output:descriptor(), 1

    end
  end
end
