--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

LetsPug = assert(LibStub("AceAddon-3.0"):NewAddon("LetsPug", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0"))

local LetsPug = LetsPug

local defaults = {
    profile = {
        alts = {
            -- [char_name] = is_shown
        },
        specs = { -- player specs cache
            -- [char_name] = active_spec_id
        },
        focus = { -- instance focus
            ["*"] = { -- [char_name ":" spec_id]
                -- [inst_key] = is_focused
                -- role = "DAMAGER" | "TANK" | "HEALER" | false -- a la UnitCharacterPoints()
            },
        },
        sync = {
            public_notes = true,
        },
        debug = false,
    },
    realm = {
        server = {
            reset_hour = 08,
            -- hour_offset = 00,
        },
        saves = {
            -- [char_name] = save_info
        },
        instances = {
            -- key = { [char_name] = readable_date }

            -- Tier 4
            k = {},
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

            -- Vanilla
            n = {},
            o = {},
        },
        classes = {
            -- [char_name] = class_id
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

    self.slash.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(self.name, self.slash)
    self:RegisterChatCommand("lp", "OnSlashCmd")

    self.options = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, "LetsPug")
    self.options.default = function() self.db:ResetProfile() end

    self:RegisterMessage("LETSPUG_TALENTS_AVAILABLE")
end

function LetsPug:OnSlashCmd(input)
    LibStub("AceConfigCmd-3.0").HandleCommand(self, "lp", self.name, input)
end

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
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_ALIVE")

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

--- Fired (1) during login, (2) interface reload and (3) at every instance entry/leaving.
-- During login, talent info is only available after PLAYER_ALIVE event.
function LetsPug:PLAYER_ENTERING_WORLD()
    RequestRaidInfo()
    self:CheckTalents()
end

--- Fired after PLAYER_ENTERING_WORLD event, only during player login.
-- Talent info is already available at this stage.
function LetsPug:PLAYER_ALIVE()
    self:CheckTalents()
end

--- If talents are available, stores current spec and notifies UI to refresh specs.
function LetsPug:CheckTalents()
    if not GetTalentTabInfo(1) then return end

    local _, spec_id = self:GetActiveTalentSpec()
    self:SetLastTalentSpecIdForPlayer(self.player, spec_id)

    self:SendMessage("LETSPUG_TALENTS_AVAILABLE")
end

function LetsPug:GUILD_ROSTER_UPDATE()
    if not self.got_info then return end

    self:Debug("GUILD_ROSTER_UPDATE")

    if self:IsPublicNoteSyncEnabled() then
        self:SyncFromGuildRosterPublicNotes()
        self:CheckGuildRosterPublicNote()
    end
end

function LetsPug:FRIENDLIST_UPDATE()
    if not self.got_info then return end

    self:Debug("FRIENDLIST_UPDATE")
end

function LetsPug:UPDATE_INSTANCE_INFO()
    self:Debug("UPDATE_INSTANCE_INFO")

    self.got_info = true
    self:RefreshSavedInstances()

    local save_info = self:EncodeSaveInfo(self.saves)
    self:RegisterPlayerSaveInfo(self.player, save_info)
    self:SendMessage("LETSPUG_PLAYER_SAVEINFO_UPDATE", self.player, save_info)
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
    local instance_key = self:GetInstanceKeyForMap(name)
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
