--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local LetsPug = LetsPug
local RaidWatch = RaidWatch

local tablet = LibStub("Tablet-2.0")
local wipe = LetsPug.wipe

function RaidWatch:OnFuInitialize()
    self:SetFuBarOption("configType", "AceConfigDialog-3.0")
    self:SetFuBarOption("tooltipType", "Tablet-2.0")
    self:SetFuBarOption("defaultPosition", "RIGHT")
    self:SetFuBarOption("defaultMinimapPosition", 235)
    self:SetFuBarOption("iconPath", [[Interface\Icons\Spell_Nature_Invisibilty]]) -- [[Interface\ICONS\INV_Misc_GroupNeedMore]]
end

function RaidWatch:OnUpdateFuBarText()
    local player = LetsPug.player
    local exp_save_info = self:GetPlayerExpandedSaveInfo(player)
    local colored_player = self:GetClassColoredPlayerName(player)
    local text = format("%s - %s", colored_player, exp_save_info)
    self:SetFuBarText(text)
end

local line = {}
function RaidWatch:OnUpdateFuBarTooltip()
    if #self.alts == 0 then
        return tablet:SetHint("All alts are hidden. Mark at least one visible.")
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

function RaidWatch:ShowTierInfo(cat, ...)
    local now = LetsPug:GetServerNow()
    local available_color, focused_color, saved_color = self:GetSaveColors()

    for i = 1, select("#", ...) do
        local inst_key = select(i, ...)

        wipe(line)
        tinsert(line, "text")
        tinsert(line, LetsPug:GetInstanceNameForKey(inst_key))
        for i, player in ipairs(self.alts) do
            local reset_readable = LetsPug:GetPlayerInstanceResetReadable(player, inst_key)
            local reset_time = LetsPug:GetResetTimestampFromReadableDate(reset_readable)
            local is_focused = LetsPug:GetPlayerInstanceFocus(player, false, inst_key)
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
