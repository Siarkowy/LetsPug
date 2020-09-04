--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local SINGLE_SPEC_CLASSES = {
    HUNTER = true,
    MAGE = true,
    ROGUE = true,
    WARLOCK = true,
}
function LetsPug:IsSingleSpecClass(class_id)
    return SINGLE_SPEC_CLASSES[class_id]
end

function LetsPug:GetActiveTalentTabIndex()
    local tab = -1
    local pts = -1
    for current_tab = 1, GetNumTalentTabs(false) do
        local _, _, current_pts = GetTalentTabInfo(current_tab, false)
        if current_pts > pts then
            tab = current_tab
            pts = current_pts
        end
    end
    return tab, pts
end

function LetsPug:GetTalentSpecByTab(tab)
    local spec_name, _, _, spec_id = GetTalentTabInfo(tab, false)
    local spec_name_short = select(1, string.split(" ", spec_name or ""))
    return spec_name_short, spec_id
end

function LetsPug:GetActiveTalentSpec()
    local class_name, class_id = UnitClass("player")
    if self:IsSingleSpecClass(class_id) then
        return class_name, class_id
    else
        local idx = self:GetActiveTalentTabIndex()
        return self:GetTalentSpecByTab(idx)
    end
end

function LetsPug:GetLastTalentSpecIdForPlayer(player)
    return self.db.profile.specs[player]
end

function LetsPug:SetLastTalentSpecIdForPlayer(player, spec_id)
    self.db.profile.specs[player] = spec_id

    if player == self.player then
        self:SendMessage("LETSPUG_PLAYER_FOCUS_UPDATE", self.player)
    end
end

function LetsPug:GetPlayerInstanceFocus(player, spec_id, instance_key)
    spec_id = spec_id or self:GetLastTalentSpecIdForPlayer(player)
    if not spec_id then return false end

    local spec_key = format("%s:%s", player, spec_id)
    local spec_data = self.db.profile.focus[spec_key]

    return spec_data[instance_key]
end

function LetsPug:SetPlayerInstanceFocus(player, spec_id, instance_key, v)
    local spec_key = format("%s:%s", player, spec_id)
    self.db.profile.focus[spec_key][instance_key] = v or nil

    if player == self.player then
        self:SendMessage("LETSPUG_PLAYER_FOCUS_UPDATE", self.player)
    end
end
