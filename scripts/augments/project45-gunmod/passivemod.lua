require "/scripts/augments/item.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

function apply(output, augment)

  local input = output:descriptor()
  local modInfo = output:instanceValue("project45GunModInfo")

  if augment then

    -- prepare to alter stats and the primary ability in general
    local newPrimaryAbility = {}

    -- Establish Passive Script
    if augment.passiveScript then
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
        passiveScript = augment.passiveScript
      })
    end

    -- Establish Passive Parameters
    if augment.passiveParameters then
      newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, augment.passiveParameters)
    end
    newPrimaryAbility = sb.jsonMerge(newPrimaryAbility, {
      overrideShiftAction = augment.overrideShiftAction,
      passiveDescription = augment.passiveDescription
    })
    -- merge changes
    output:setInstanceValue("primaryAbility", sb.jsonMerge(input.parameters.primaryAbility, newPrimaryAbility))

    -- merge in custom animations
    output:setInstanceValue("animationCustom",
        sb.jsonMerge(input.parameters.animationCustom or {}, augment.animationCustom or {}))

    -- MODIFICATION POST-MORTEM

    return output

  end
end
