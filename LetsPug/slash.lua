--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local LetsPug = LetsPug
local wipe = LetsPug.wipe

local alts = {}
function LetsPug:GetAltValuesSlash(info)
    wipe(alts)
    for name, _ in pairs(LetsPug.db.profile.alts) do
        alts[name] = name
    end
    return alts
end

LetsPug.slash = {
    handler = LetsPug,
    type = "group",
    childGroups = "tab",
    args = {
        gui = {
            name = "GUI",
            desc = "Show Graphical Interface",
            type = "execute",
            func = function(info)
                InterfaceOptionsFrame_OpenToFrame(LetsPug.options)
                LetsPug:SwitchOptionsToActiveTalentSpec()
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
                                return LetsPug:IsAutomaticTime()
                            end,
                            set = function(info, v)
                                LetsPug:SetAutomaticTime(v)
                                if v then LetsPug:CalibrateTime(true) end
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
                                return (LetsPug:GetServerResetOffset() or 0) / 3600
                            end,
                            set = function(info, v)
                                LetsPug:SetServerResetOffset(v * 3600)
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
                                return LetsPug:GetClientTimeOffset() / 3600
                            end,
                            set = function(info, v)
                                LetsPug:SetClientTimeOffset(v * 3600)
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
                            desc = "When enabled, players' notes will be read for lockout & spec info.",
                            type = "toggle",
                            get = function(info)
                                return LetsPug:IsReadPlayerNotesEnabled()
                            end,
                            set = function(info, v)
                                LetsPug:SetReadPlayerNotesEnabled(v)
                            end,
                            width = "full",
                            order = 10
                        },
                        writenotes = {
                            name = "Update my player note while in guild",
                            desc = "When enabled, player's note will be automatically edited with lockout & spec info if player is able to edit notes.",
                            type = "toggle",
                            get = function(info)
                                return LetsPug:IsWritePlayerNoteEnabled()
                            end,
                            set = function(info, v)
                                LetsPug:SetWritePlayerNoteEnabled(v)
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
                        return LetsPug.db.profile.debug
                    end,
                    set = function(info, v)
                        LetsPug:SetDebug(v)
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
                        LetsPug:RegisterAlt(name)
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
                        return LetsPug:GetAltVisibility(name)
                    end,
                    set = function(info, name, is_shown)
                        if IsControlKeyDown() then
                            LetsPug:ClearAlt(name)
                        else
                            LetsPug:SetAltVisibility(name, is_shown)
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
                        LetsPug:ClearAlt(name)
                    end,
                    guiHidden = true,
                    order = 3
                },
                find = {
                    name = "Find in Guild",
                    desc = function(info)
                        local alts = LetsPug:FindPlayerAlts(LetsPug.player)
                        local count = 0
                        for _, _ in pairs(alts) do count = count + 1 end
                        return format("Mark %d |4guild character:guild characters; as alts. Works best with QDKP-style system, where alt's officer note contains {Main} info", count)
                    end,
                    type = "execute",
                    func = function(info)
                        local alts = LetsPug:FindPlayerAlts(LetsPug.player)
                        for name, class in pairs(alts) do
                            LetsPug:RegisterPlayerClass(name, class)
                            LetsPug:RegisterAlt(name)
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
function LetsPug:SwitchOptionsToAlts()
    LibStub("AceConfigDialog-3.0"):SelectGroup(self.name, "alt")
end
