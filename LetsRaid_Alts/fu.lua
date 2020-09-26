--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 3-Clause "New" license (see LICENSE file).
--------------------------------------------------------------------------------

local LetsRaid = LetsRaid
local LetsRaid_Alts = LetsRaid_Alts

local AceConfigDialog30 = LibStub("AceConfigDialog-3.0")
local tablet = LibStub("Tablet-2.0")
local wipe = LetsRaid.wipe

function LetsRaid_Alts:OnFuInitialize()
    self:SetFuBarOption("configType", "Custom")
    self:SetFuBarOption("tooltipType", "Tablet-2.0")
    self:SetFuBarOption("clickableTooltip", true)
    self:SetFuBarOption("defaultPosition", "RIGHT")
    self:SetFuBarOption("defaultMinimapPosition", 235)
    self:SetFuBarOption("iconPath", [[Interface\Icons\Spell_Nature_Invisibilty]]) -- [[Interface\ICONS\INV_Misc_GroupNeedMore]]
end

function LetsRaid_Alts:OnFuBarMouseDown(btn)
    AceConfigDialog30:Open(LetsRaid.name)

    if not self:HasAlts() then
        LetsRaid:SwitchOptionsToAlts()
        return
    end

    LetsRaid:SwitchOptionsToActiveTalentSpec()
end

function LetsRaid_Alts:OnUpdateFuBarText()
    local player = LetsRaid.player
    local role_info = LetsRaid:GetPlayerRoleInfo()
    local exp_save_info = self:GetPlayerExpandedSaveInfo(player)
    local colored_player = self:GetClassColoredPlayerName(player)
    local text = format("%s %s - %s", colored_player, role_info, exp_save_info)
    self:SetFuBarText(text)
end

local line = {}
function LetsRaid_Alts:OnUpdateFuBarTooltip()
    if not self:HasAlts() then
        return tablet:SetHint("No alts are shown. Click to add at least one.")
    end

    wipe(line)
    tinsert(line, "columns")
    tinsert(line, #self.alts + 1)
    tinsert(line, "text")
    tinsert(line, "|cffccccccTier 4|r")
    for i, name in ipairs(self.alts) do
        tinsert(line, "text" .. (i + 1))
        tinsert(line, self:GetClassColoredPlayerName(name, 3))
    end
    cat = tablet:AddCategory(unpack(line))

    self:ShowTierInfo(cat, "k", "g", "m")
    cat:AddLine()

    cat:AddLine("text", "|cffccccccTier 5|r")
    self:ShowTierInfo(cat, "s", "t", "z")
    cat:AddLine()

    cat:AddLine("text", "|cffccccccTier 6|r")
    self:ShowTierInfo(cat, "h", "b", "p")
    cat:AddLine()

    cat:AddLine("text", "|cffccccccOther|r")
    self:ShowTierInfo(cat, "n", "o")
end

function LetsRaid_Alts:ShowTierInfo(cat, ...)
    local now = time()
    local available_color, focused_color, saved_color = self:GetSaveColors()

    for i = 1, select("#", ...) do
        local inst_key = select(i, ...)

        wipe(line)
        tinsert(line, "text")
        tinsert(line, LetsRaid:GetInstanceNameForKey(inst_key))
        for i, player in ipairs(self.alts) do
            local reset_readable = LetsRaid:GetPlayerInstanceResetReadable(player, inst_key)
            local reset_time = LetsRaid:GetResetTimestampFromReadableDate(reset_readable)
            local is_focused = LetsRaid:GetPlayerInstanceFocus(player, false, inst_key, true)
            local is_saved = reset_time and reset_time > now
    
            local color = is_saved and saved_color
                or is_focused and focused_color
                or available_color
            local mark = is_saved and self:GetPrettyTimeBetweenTimestamps(now, reset_time)
                or is_focused and "o"
                or "x"
            local info = format("|cff%s%s|r", color, mark)

            tinsert(line, "text" .. (i + 1))
            tinsert(line, info)
            tinsert(line, "hasCheck")
            tinsert(line, true)
        end
        cat:AddLine(unpack(line))
    end
end
