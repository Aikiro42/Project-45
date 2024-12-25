require "/scripts/util.lua"
require "/items/active/weapons/project45neoweapon.lua"
-- require "/items/active/weapons/ranged/gunfire.lua"

Project45GunFireReload = WeaponAbility:new()

function Project45GunFireReload:init()
    self.shiftTriggerTime = self.shiftTriggerTime or 0.2
    self.shiftTriggerTimer = -1
end

function Project45GunFireReload:update(dt, fireMode, shiftHeld)
    
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    if self.shiftActivates then

        if shiftHeld then
            self.shiftTriggerTimer = math.max(0, self.shiftTriggerTimer + self.dt)
        else
            if 0 <= self.shiftTriggerTimer and self.shiftTriggerTimer <= self.shiftTriggerTime
            and (self.weapon.reloadTimer < 0 or self.weapon.isReloading)
            and not self.triggered
            then
                self:sendReloadSignal()
                self.triggered = true
            else
                storage.reloadSignal = false
                self.triggered = false
            end
            self.shiftTriggerTimer = -1
        end

    else

        if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) then
            self.triggered = false
        end
        
        if self.fireMode == "alt"
        and not self.weapon.currentAbility
        and (self.weapon.reloadTimer < 0 or self.weapon.isReloading)
        and not self.triggered
        then
            self:sendReloadSignal()
            self.triggered = true
        else
            storage.reloadSignal = false
        end

    end


end

function Project45GunFireReload:sendReloadSignal()
    if not status.resourceLocked("energy")
    or storage.project45GunState.stockAmmo + math.max(storage.project45GunState.ammo, 0) > 0 then
        storage.reloadSignal = true
    else
        animator.playSound("error")
    end
end

function Project45GunFireReload:uninit()
end