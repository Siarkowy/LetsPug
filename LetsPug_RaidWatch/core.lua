--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local LetsPug = LetsPug
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

RaidWatch = LetsPug:NewModule(
    "RaidWatch",

    "AceConsole-3.0",
    "AceEvent-3.0",
    "LibFuBarPlugin-Mod-3.0"
)

local RaidWatch = RaidWatch
RaidWatch.title = "LetsPug RaidWatch"

function RaidWatch.DecimalToHexColor(r, g, b) -- from http://wowprogramming.com/snippets/Convert_decimal_classcolor_into_hex_27
    return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function RaidWatch:GetPlayerExpandedSaveInfo(player)
    local now = LetsPug:GetServerNow()
    local reset_str = "%k%g%m - %s%t%z - %h%b%p - %n%o"
    local available_color, focused_color, saved_color = self:GetSaveColors()

    reset_str = reset_str:gsub("%%(%a)", function(instance_key)
        local reset_readable = LetsPug:GetPlayerInstanceResetReadable(player, instance_key)
        local reset_time = LetsPug:GetResetTimestampFromReadableDate(reset_readable)
        local is_focused = LetsPug:GetPlayerInstanceFocus(player, false, instance_key)
        local is_saved = reset_time and reset_time > now

        local color = is_saved and saved_color or is_focused and focused_color or available_color
        local mark = is_saved and instance_key or is_focused and "o" or "x"
        return format("|cff%s%s|r", color, mark)
    end)

    return reset_str
end

function RaidWatch:GetClassColoredPlayerName(player, max_chars)
    max_chars = max_chars or 25
    local class = LetsPug:GetPlayerClass(player) or "PRIEST"
    player = player:sub(0, max_chars)
    local c = RAID_CLASS_COLORS[class]
    return c and format("%s%s|r", self.DecimalToHexColor(c.r, c.g, c.b), player) or player
end

local HOUR = 60 * 60
function RaidWatch:GetFullHoursBetweenTimestamps(a, b)
    return ceil((b - a) / HOUR)
end

function RaidWatch:GetPrettyTimeBetweenTimestamps(a, b)
    local hours = self:GetFullHoursBetweenTimestamps(a, b)
    return hours >= 24 and format("%dd", ceil(hours / 24)) or format("%dh", hours)
end

function RaidWatch:GetSaveColors()
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

function RaidWatch:OnInitialize()
    self:RefreshAlts()

    self.db = LetsPug.db:RegisterNamespace("RaidWatch", defaults)
    self.db.RegisterCallback(self, "OnProfileChanged", function(event, db, newprofile)
        self:UpdateFuBarPlugin()
    end)

    self:OnFuInitialize()
end

function RaidWatch:OnEnable()
    self:RegisterMessage("LETSPUG_PLAYER_SAVEINFO_UPDATE", "UpdateFuBarPlugin")
    self:RegisterMessage("LETSPUG_PLAYER_SPEC_UPDATE", "UpdateFuBarPlugin")
    self:RegisterMessage("LETSPUG_ALTS_UPDATE", "RefreshAlts")
end

function RaidWatch:OnSlashCmd(input)
    LibStub("AceConfigCmd-3.0").HandleCommand(self, "lprw", self.name, input)
end

function RaidWatch:RefreshAlts()
    self.alts = {}

    for k, v in pairs(LetsPug.db.profile.alts) do
        if v then
            table.insert(self.alts, k)
        end
    end
    table.sort(self.alts)
end

function RaidWatch:HasAlts()
    return #self.alts > 0
end
