--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

LetsRaid = assert(LibStub("AceAddon-3.0"):NewAddon("LetsRaid", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0"))

local LetsRaid = LetsRaid

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
            read_notes = true,
            write_notes = true,
        },
        debug = false,
    },
    realm = {
        time = {
            automatic = true,
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

function LetsRaid:OnInitialize()
    self.player = UnitName("player")
    self.saves = {}

    self.db = LibStub("AceDB-3.0"):New("LetsRaidDB", defaults, GetRealmName())
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    self.slash.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(self.name, self.slash)
    self:RegisterChatCommand("lr", "OnSlashCmd")
    self:RegisterChatCommand("lp", "OnSlashCmd")

    self.options = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, "LetsRaid")
    self.options.default = function() self.db:ResetProfile() end

    self:RegisterMessage("LETSRAID_TALENTS_AVAILABLE")
end

function LetsRaid:OnSlashCmd(input)
    LibStub("AceConfigCmd-3.0").HandleCommand(self, "lr", self.name, input)
end

function LetsRaid:OnProfileChanged()
    self:Disable()
    self:Enable()
end

function LetsRaid:OnEnable()
    self.debug = tonumber(self.db.profile.debug) or 0

    self:RegisterPlayerClass(self.player, select(2, UnitClass("player")))
    self:RegisterAlt(self.player)

    self:CheckTalents()

    self:RegisterEvent("FRIENDLIST_UPDATE")
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_ALIVE")
    self:RegisterEvent("CHARACTER_POINTS_CHANGED")

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
function LetsRaid:PLAYER_ENTERING_WORLD()
    RequestRaidInfo()
    self:CheckTalents()
end

--- Fired after PLAYER_ENTERING_WORLD event, only during player login.
-- Talent info is already available at this stage.
function LetsRaid:PLAYER_ALIVE()
    self:CheckTalents()
end

function LetsRaid:CHARACTER_POINTS_CHANGED()
    if UnitCharacterPoints("player") == 0 then
        self:CheckTalents()
    end
end

--- If talents are available, stores current spec and notifies UI to refresh specs.
function LetsRaid:CheckTalents()
    if not GetTalentTabInfo(1) then return end

    local _, spec_id = self:GetActiveTalentSpec()
    self:SetLastTalentSpecIdForPlayer(self.player, spec_id)

    self:SendMessage("LETSRAID_TALENTS_AVAILABLE")

    -- assign default role if seen for the first time in this talent spec
    if self:GetPlayerRole(self.player, spec_id) == nil then
        local role_id = self:GetDefaultRoleForSpec(spec_id)
        self:SetPlayerRole(self.player, spec_id, role_id)
    end
end

function LetsRaid:GUILD_ROSTER_UPDATE()
    if not self.got_info then return end

    self:Debug("GUILD_ROSTER_UPDATE")

    if self:IsReadPlayerNotesEnabled() then
        self:SyncFromGuildRosterPublicNotes()
    end
    if self:IsWritePlayerNoteEnabled() then
        self:CheckGuildRosterPublicNote()
    end
end

function LetsRaid:FRIENDLIST_UPDATE()
    if not self.got_info then return end

    self:Debug("FRIENDLIST_UPDATE")
end

function LetsRaid:UPDATE_INSTANCE_INFO()
    self:Debug("UPDATE_INSTANCE_INFO")

    if self:IsAutomaticTime() then
        self:CalibrateTime()
    end

    self.got_info = true
    self:RefreshSavedInstances()

    local save_info = self:EncodeSaveInfo(self.saves)
    self:RegisterPlayerSaveInfo(self.player, save_info)
    self:SendMessage("LETSRAID_PLAYER_SAVEINFO_UPDATE", self.player, save_info)
end
