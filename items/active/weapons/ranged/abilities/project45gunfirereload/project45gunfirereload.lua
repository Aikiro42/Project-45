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
    -- and not self.weapon.currentAbility
    and (self.weapon.reloadTimer < 0 or self.weapon.isReloading)
    and not self.triggered
    then
        
        if not status.resourceLocked("energy")
        or storage.stockAmmo + math.max(storage.ammo, 0) > 0 then
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