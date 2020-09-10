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
                        resethr = {
                            name = "Server reset hour",
                            desc = "Specifies at what hour do the instance saves reset. Needs to be provided in server timezone.",
                            type = "range",
                            min = 0,
                            max = 23,
                            step = 1,
                            get = function(info)
                                return LetsPug:GetServerResetHour()
                            end,
                            set = function(info, v)
                                LetsPug:SetServerResetHour(v)
                            end,
                            order = 10
                        },
                        tzoffset = {
                            name = "Client to server hours",
                            desc = "Difference between client and server timezones in hours. Positive value means client time is ahead of server time. Given a server in GMT (UTC+0) timezone, positive values apply to most of EU zone, while negative to NA.",
                            type = "range",
                            min = -10,
                            max = 14,
                            step = 1,
                            get = function(info)
                                return LetsPug:GetServerHourOffset()
                            end,
                            set = function(info, v)
                                LetsPug:SetServerHourOffset(v)
                            end,
                            order = 11
                        },
                    }
                },
                sync = {
                    name = "Sync Settings",
                    type = "group",
                    inline = true,
                    order = 15,
                    args = {
                        pubnotes = {
                            name = "Sync to/from public notes while in guild",
                            desc = "When enabled, player's public note will be automatically edited with save info if player is able to edit public notes. Additionally, save info will be synced from other players' notes.",
                            type = "toggle",
                            get = function(info)
                                return LetsPug:IsPublicNoteSyncEnabled()
                            end,
                            set = function(info, v)
                                LetsPug:SetPublicNoteSyncEnabled(v)
                            end,
                            width = "full",
                            order = 10
                        },
                    }
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
