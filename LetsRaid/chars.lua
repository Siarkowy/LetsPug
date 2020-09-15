--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 3-Clause "New" license (see LICENSE file).
--------------------------------------------------------------------------------

--- Registers character as player's alt.
function LetsRaid:RegisterAlt(name)
    name = self.StrToPascalCase(name)
    if name and self:GetAltVisibility(name) == nil then
        self:SetAltVisibility(name, true)
    end
end

--- Clears alt status from given character.
function LetsRaid:ClearAlt(name)
    self.db.profile.alts[name] = nil
    self.db.profile.specs[name] = nil
    for key, _ in pairs(self.db.profile.focus) do
        if key:find(name) then
            self.db.profile.focus[key] = nil
        end
    end
    self:SendMessage("LETSRAID_ALTS_UPDATE")
end

--- Returns alt visiblity for GUIs.
function LetsRaid:GetAltVisibility(name)
    return self.db.profile.alts[name]
end

--- Sets alt visiblity for GUIs.
function LetsRaid:SetAltVisibility(name, is_shown)
    self.db.profile.alts[name] = is_shown
    self:SendMessage("LETSRAID_ALTS_UPDATE")
end

-- Saves realm character's class.
function LetsRaid:RegisterPlayerClass(player, class)
    self.db.realm.classes[player] = class
end

-- Returns realm character's class.
function LetsRaid:GetPlayerClass(name)
    return self.db.realm.classes[name] or select(2, UnitClass(name))
end
