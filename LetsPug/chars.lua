--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

--- Registers character as player's alt.
function LetsPug:RegisterAlt(name)
    name = self.StrToPascalCase(name)
    if name and self:GetAltVisibility(name) == nil then
        self:SetAltVisibility(name, true)
    end
end

--- Clears alt status from given character.
function LetsPug:ClearAlt(name)
    self.db.profile.alts[name] = nil
    self.db.profile.specs[name] = nil
    for key, _ in pairs(self.db.profile.focus) do
        if key:find(name) then
            self.db.profile.focus[key] = nil
        end
    end
    self:SendMessage("LETSPUG_ALTS_UPDATE")
end

--- Returns alt visiblity for GUIs.
function LetsPug:GetAltVisibility(name)
    return self.db.profile.alts[name]
end

--- Sets alt visiblity for GUIs.
function LetsPug:SetAltVisibility(name, is_shown)
    self.db.profile.alts[name] = is_shown
    self:SendMessage("LETSPUG_ALTS_UPDATE")
end

-- Saves realm character's class.
function LetsPug:RegisterPlayerClass(player, class)
    self.db.realm.classes[player] = class
end

-- Returns realm character's class.
function LetsPug:GetPlayerClass(name)
    return self.db.realm.classes[name] or select(2, UnitClass(name))
end
