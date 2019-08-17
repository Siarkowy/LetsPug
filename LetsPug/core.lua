--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

LetsPug = assert(LibStub("AceAddon-3.0"):NewAddon("LetsPug", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0"))

local LetsPug = LetsPug

local defaults = {
    profile = {
        alts = {
            -- [name] = is_shown
        },
        debug = false,
    },
    realm = {
        server = {
            reset_hour = 09,
            -- hour_offset = 00,
        },
        saves = {
            -- [name] = save_info
        },
        instances = {
            -- Tier 4
            k = {
                -- [name] = readable_date
            },
            g = {},
            m = {},
            -- Tier 5
            s = {},
            t = {},
            z = {},
            -- Tier 6
            h = {},
            b = {},
            p = {},
        },
        classes = {
            -- [name] = class_id
        }
    },
}

function LetsPug:OnInitialize()
    self.player = UnitName("player")
    self.saves = {}

    self.db = LibStub("AceDB-3.0"):New("LetsPugDB", defaults, "Default")
    self.debug = self.db.profile.debug

    if not self:GetServerHourOffset() then
        self:SetServerHourOffset(self:GuessServerHourOffset())
    end

    self:RegisterAlt(self.player)
    self:RegisterPlayerClass(self.player, select(2, UnitClass("player")))
end

function LetsPug:RegisterAlt(name)
    if self.db.profile.alts[name] == nil then
        self.db.profile.alts[name] = true
    end
end

function LetsPug:RegisterPlayerClass(player, class)
    self.db.realm.classes[player] = class
end

function LetsPug:GetPlayerClass(name)
    return self.db.realm.classes[name] or select(2, UnitClass(name))
end

function LetsPug:OnEnable()
    self:RegisterEvent("FRIENDLIST_UPDATE")
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", RequestRaidInfo)

    ShowFriends()
    self:ScheduleRepeatingTimer(ShowFriends, 30)

    if IsInGuild() then
        GuildRoster()
        self:ScheduleRepeatingTimer(GuildRoster, 30)
    end

    -- RequestRaidInfo()
    self:ScheduleRepeatingTimer(RequestRaidInfo, 60)

    self:ScheduleInstanceCleanup()
end

function LetsPug:ScheduleInstanceCleanup()
    self:ScheduleRepeatingTimer(function() self:CleanupInstanceSaves("k", "g", "m") end, 31)
    self:ScheduleRepeatingTimer(function() self:CleanupInstanceSaves("s", "t", "z") end, 53)
    self:ScheduleRepeatingTimer(function() self:CleanupInstanceSaves("h", "b", "p") end, 71)
end

function LetsPug:GUILD_ROSTER_UPDATE()
    if self.debug then
        self:Print("GUILD_ROSTER_UPDATE")
    end
end

function LetsPug:FRIENDLIST_UPDATE()
    if self.debug then
        self:Print("FRIENDLIST_UPDATE")
    end
end

function LetsPug:UPDATE_INSTANCE_INFO()
    if self.debug then
        self:Print("UPDATE_INSTANCE_INFO")
    end

    self:RefreshSavedInstances()
    self:RegisterPlayerSaveInfo(self.player, self:EncodeSaveInfo(self.saves))
end

function LetsPug:RefreshSavedInstances()
    for i = 1, GetNumSavedInstances() do
        local name, id, ttl = GetSavedInstanceInfo(i)
        local expire_timestamp = self:GetServerNow() + ttl
        local expire_readable = self:GetReadableDateFromTimestamp(expire_timestamp)
        self:RegisterSavedInstance(name, expire_readable)
    end
end

function LetsPug:RegisterSavedInstance(name, expire_readable)
    local instance_key = self:GetInstanceKey(name)
    if instance_key then
        self.saves[instance_key] = expire_readable
    end
end

function LetsPug:RegisterPlayerSaveInfo(player, save_info)
    self.db.realm.saves[player] = save_info

    local instances = self.db.realm.instances
    for instance_key, readable in pairs(self:DecodeSaveInfo(save_info)) do
        instances[instance_key][player] = readable
    end
end

function LetsPug:GetPlayerSaveInfo(player)
    return self.db.realm.saves[player]
end

function LetsPug:GetPlayerInstanceResetReadable(player, instance_key)
    local instance_info = assert(self.db.realm.instances[instance_key], "Wrong instance key")
    local reset_readable = instance_info[player]
    return reset_readable
end
