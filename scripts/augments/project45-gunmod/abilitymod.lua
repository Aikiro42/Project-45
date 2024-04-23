require "/scripts/augments/item.lua"
require "/scripts/augments/project45-gunmod-helper.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/set.lua"
require "/scripts/project45/project45util.lua"

function apply(input, augment)

    local output = Item.new(input)
    local modInfo = output:instanceValue("project45GunModInfo")

    if augment then

        -- alter or set ability type if present
        if augment.ability.altAbilityType and output:instanceValue("altAbilityType") ~= augment.ability.altAbilityType then

            output:setInstanceValue("altAbilityType", augment.ability.altAbilityType)

            if augment.ability.overrideTwoHanded then
                output:setInstanceValue("twoHanded", augment.ability.twoHanded)
            end

            -- merge ability parameters
            if augment.ability.altAbility then
                output:setInstanceValue("altAbility", sb.jsonMerge(output:instanceValue("altAbility", {}),
                    augment.ability.altAbility))
            end

        end

        -- establish whether shift action is used
        output:setInstanceValue("hasShiftAction", augment.ability.hasShiftAction)

        return output

    end
end
