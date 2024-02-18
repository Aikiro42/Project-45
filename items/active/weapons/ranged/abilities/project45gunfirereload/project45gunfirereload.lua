require "/scripts/util.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45GunFireReload = WeaponAbility:new()

function Project45GunFireReload:init()
end

function Project45GunFireReload:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
        self.triggered = false
    end
    
    if self.fireMode == "alt"
    and not self.weapon.currentAbility
    and not self.triggered
    then

        if status.resourcePositive("energy") and not status.resourceLocked("energy") then
            storage.reloadSignal = true
        else
            animator.playSound("error")
        end

        self.triggered = true
    else
        storage.reloadSignal = false
    end

end

function Project45GunFireReload:uninit()
end