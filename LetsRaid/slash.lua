--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local LetsRaid = LetsRaid
local wipe = LetsRaid.wipe

local alts = {}
function LetsRaid:GetAltValuesSlash(info)
    wipe(alts)
    for name, _ in pairs(LetsRaid.db.profile.alts) do
        alts[name] = name
    end
    return alts
end

LetsRaid.slash = {
    handler = LetsRaid,
    type = "group",
    childGroups = "tab",
    args = {
        gui = {
            name = "GUI",
            desc = "Show Graphical Interface",
            type = "execute",
            func = function(info)
                InterfaceOptionsFrame_OpenToFrame(LetsRaid.options)
                LetsRaid:SwitchOptionsToActiveTalentSpec()
            end,
            guiHidden = true,
            order = 0
        },
        set = {
            name = "Settings",
            desc = "Manage Settings",
            type = "group",
            order = 10,
            args = {
                time = {
                    name = "Time Settings",
                    type = "group",
                    inline = true,
                    order = 5,
                    args = {
                        autotime = {
                            name = "Automatic",
                            desc = "Enable automatic time calibration. Settings will be adjusted after you get saved to any raid instance. It is highly recommended to keep this setting on.",
                            type = "toggle",
                            get = function(info)
                                return LetsRaid:IsAutomaticTime()
                            end,
                            set = function(info, v)
                                LetsRaid:SetAutomaticTime(v)
                                if v then LetsRaid:CalibrateTime(true) end
                            end,
                            order = 5
                        },
                        resethr = {
                            name = "Lockout Reset Hour",
                            desc = "Specifies at what hour do the instance saves reset. Needs to be provided in UTC timezone.",
                            type = "range",
                            min = 0,
                            max = 24,
                            step = 0.5,
                            get = function(info)
                                return (LetsRaid:GetServerResetOffset() or 0) / 3600
                            end,
                            set = function(info, v)
                                LetsRaid:SetServerResetOffset(v * 3600)
                            end,
                            disabled = "IsAutomaticTime",
                            order = 10
                        },
                        tzoffset = {
                            name = "Client Time Zone",
                            desc = "Difference between your local and UTC time in hours. Positive value means local time is ahead of UTC time, and applies to Europe, Asia, Africa & Oceania, while negative to Americas.",
                            type = "range",
                            min = -10,
                            max = 14,
                            step = 0.25,
                            get = function(info)
                                return LetsRaid:GetClientTimeOffset() / 3600
                            end,
                            set = function(info, v)
                                LetsRaid:SetClientTimeOffset(v * 3600)
                            end,
                            disabled = "IsAutomaticTime",
                            order = 9
                        },
                    }
                },
                sync = {
                    name = "Sync Settings",
                    type = "group",
                    inline = true,
                    order = 15,
                    args = {
                        readnotes = {
                            name = "Sync info from player notes while in guild",
                            desc = "When enabled, other players' notes will be read for lockout & spec info.",
                            type = "toggle",
                            get = function(info)
                                return LetsRaid:IsReadPlayerNotesEnabled()
                            end,
                            set = function(info, v)
                                LetsRaid:SetReadPlayerNotesEnabled(v)
                            end,
                            width = "full",
                            order = 10
                        },
                        writenotes = {
                            name = "Update my player note while in guild",
                            desc = "When enabled, player's note will be automatically edited with lockout & spec info if player is able to edit notes.",
                            type = "toggle",
                            get = function(info)
                                return LetsRaid:IsWritePlayerNoteEnabled()
                            end,
                            set = function(info, v)
                                LetsRaid:SetWritePlayerNoteEnabled(v)
                            end,
                            width = "full",
                            order = 15
                        },
                    }
                },
                debug = {
                    name = "Debug Level",
                    type = "select",
                    values = { [0] = "INFO", "DEBUG", "TRACE" },
                    get = function(info)
                        return LetsRaid.db.profile.debug
                    end,
                    set = function(info, v)
                        LetsRaid:SetDebug(v)
                    end,
                    guiHidden = true,
                    order = 100
                },
            }
        },
        alt = {
            name = "Alts",
            desc = "Manage Alts",
            type = "group",
            order = 5,
            args = {
                add = {
                    name = "Add alt by name",
                    desc = "Mark character as your alt",
                    usage = "<alt name>",
                    type = "input",
                    get = function(info)
                        return ""
                    end,
                    set = function(info, name)
                        LetsRaid:RegisterAlt(name)
                    end,
                    width = "full",
                    order = 1
                },
                toggle = {
                    name = "Show alt",
                    desc = "Show/hide alt. Control click to delete",
                    type = "multiselect",
                    values = "GetAltValuesSlash",
                    get = function(info, name)
                        return LetsRaid:GetAltVisibility(name)
                    end,
                    set = function(info, name, is_shown)
                        if IsControlKeyDown() then
                            LetsRaid:ClearAlt(name)
                        else
                            LetsRaid:SetAltVisibility(name, is_shown)
                        end
                    end,
                    width = "normal",
                    order = 2
                },
                delete = {
                    name = "Delete",
                    desc = "Clear alt mark from character, leaving instance save info intact",
                    type = "select",
                    values = "GetAltValuesSlash",
                    get = function(info, name) end,
                    set = function(info, name, ...)
                        LetsRaid:ClearAlt(name)
                    end,
                    guiHidden = true,
                    order = 3
                },
                find = {
                    name = "Find in Guild",
                    desc = function(info)
                        local alts = LetsRaid:FindPlayerAlts(LetsRaid.player)
                        local count = 0
                        for _, _ in pairs(alts) do count = count + 1 end
                        return format("Mark %d |4guild character:guild characters; as alts. Works best with QDKP-style system, where alt's officer note contains {Main} info", count)
                    end,
                    type = "execute",
                    func = function(info)
                        local alts = LetsRaid:FindPlayerAlts(LetsRaid.player)
                        for name, class in pairs(alts) do
                            LetsRaid:RegisterPlayerClass(name, class)
                            LetsRaid:RegisterAlt(name)
                        end
                    end,
                    width = "full",
                    order = 10
                },
            }
        },
    }
}

--- Switches GUI to alt configuration.
function LetsRaid:SwitchOptionsToAlts()
    LibStub("AceConfigDialog-3.0"):SelectGroup(self.name, "alt")
end
