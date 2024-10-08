require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

function apply(output, augment)

  local input = output:descriptor()

  if augment then

    -- alter or set alt ability type if present
    if augment.altAbilityType and output:instanceValue("altAbilityType") ~= augment.altAbilityType then

      output:setInstanceValue("altAbilityType", augment.altAbilityType)

      if augment.overrideTwoHanded then
        output:setInstanceValue("twoHanded", augment.twoHanded)
      end

      -- merge ability parameters
      if augment.altAbility then
        output:setInstanceValue("altAbility",
            sb.jsonMerge(output:instanceValue("altAbility", {}), augment.altAbility))
      end

    end

    -- alter or set shift ability type if present
    -- THIS SHOULD NOT OVERRIDE TWO-HANDEDNESS
    if augment.shiftAbilityType and output:instanceValue("shiftAbilityType") ~= augment.shiftAbilityType then

      output:setInstanceValue("shiftAbilityType", augment.shiftAbilityType)

      -- merge ability parameters
      if augment.shiftAbility then
        output:setInstanceValue("shiftAbility",
            sb.jsonMerge(output:instanceValue("shiftAbility", {}), augment.shiftAbility))
      end

    end

    -- establish whether shift action is used
    output:setInstanceValue("hasShiftAction", augment.hasShiftAction)

    return output

  end
end
