--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local LetsRaid = LetsRaid
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

LetsRaid_Alts = LetsRaid:NewModule(
    "Alts",

    "AceConsole-3.0",
    "AceEvent-3.0",
    "LibFuBarPlugin-Mod-3.0"
)

local LetsRaid_Alts = LetsRaid_Alts
LetsRaid_Alts.title = "LetsRaid Alts"

function LetsRaid_Alts.DecimalToHexColor(r, g, b) -- from http://wowprogramming.com/snippets/Convert_decimal_classcolor_into_hex_27
    return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function LetsRaid_Alts:GetPlayerExpandedSaveInfo(player)
    local now = time()
    local reset_str = "%k%g%m - %s%t%z - %h%b%p - %n%o"
    local available_color, focused_color, saved_color = self:GetSaveColors()

    reset_str = reset_str:gsub("%%(%a)", function(instance_key)
        local reset_readable = LetsRaid:GetPlayerInstanceResetReadable(player, instance_key)
        local reset_time = LetsRaid:GetResetTimestampFromReadableDate(reset_readable)
        local is_focused = LetsRaid:GetPlayerInstanceFocus(player, false, instance_key, true)
        local is_saved = reset_time and reset_time > now

        local color = is_saved and saved_color or is_focused and focused_color or available_color
        local mark = is_saved and instance_key or is_focused and "o" or "x"
        return format("|cff%s%s|r", color, mark)
    end)

    return reset_str
end

function LetsRaid_Alts:GetClassColoredPlayerName(player, max_chars)
    max_chars = max_chars or 25
    local class = LetsRaid:GetPlayerClass(player) or "PRIEST"
    player = player:sub(0, max_chars)
    local c = RAID_CLASS_COLORS[class]
    return c and format("%s%s|r", self.DecimalToHexColor(c.r, c.g, c.b), player) or player
end

local HOUR = 60 * 60
function LetsRaid_Alts:GetFullHoursBetweenTimestamps(a, b)
    return ceil((b - a) / HOUR)
end

function LetsRaid_Alts:GetPrettyTimeBetweenTimestamps(a, b)
    local hours = self:GetFullHoursBetweenTimestamps(a, b)
    return hours >= 24 and format("%dd", ceil(hours / 24)) or format("%dh", hours)
end

function LetsRaid_Alts:GetSaveColors()
    local colors = self.db.profile.colors
    return colors.available, colors.focused, colors.saved
end

local defaults = {
    profile = {
        colors = {
            available = "888888",
            focused = "33ff88",
            saved = "ff8833",
        },
    },
}

function LetsRaid_Alts:OnInitialize()
    self.db = LetsRaid.db:RegisterNamespace("Alts", defaults)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    self:OnFuInitialize()
end

function LetsRaid_Alts:OnProfileChanged()
    self:Disable()
    self:Enable()
end

function LetsRaid_Alts:OnEnable()
    self:RefreshAlts()

    self:RegisterMessage("LETSRAID_PLAYER_SAVEINFO_UPDATE", "UpdateFuBarPlugin")
    self:RegisterMessage("LETSRAID_PLAYER_SPEC_UPDATE", "UpdateFuBarPlugin")
    self:RegisterMessage("LETSRAID_ALTS_UPDATE", "RefreshAlts")
end

function LetsRaid_Alts:OnSlashCmd(input)
    LibStub("AceConfigCmd-3.0").HandleCommand(self, "lprw", self.name, input)
end

function LetsRaid_Alts:RefreshAlts()
    self.alts = {}

    for k, v in pairs(LetsRaid.db.profile.alts) do
        if v then
            table.insert(self.alts, k)
        end
    end
    table.sort(self.alts)
end

function LetsRaid_Alts:HasAlts()
    return #self.alts > 0
end
