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
            desc = "Shows graphical interface.",
            type = "execute",
            func = function(info)
                InterfaceOptionsFrame_OpenToFrame(LetsPug.options)
            end,
            guiHidden = true,
            order = 0
        },
        server = {
            name = "Server",
            type = "group",
            order = 10,
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
                    width = "full",
                    order = 10
                },
                tzoffset = {
                    name = "Client to server hours",
                    desc = "Difference between client and server timezones in hours. Positive value means client time is ahead of server time. Given a server in GMT (UTC+0) timezone, positive values apply to most of EU zone, while negative to NA.",
                    type = "range",
                    min = -11,
                    max = 12,
                    step = 1,
                    get = function(info)
                        return LetsPug:GetServerHourOffset()
                    end,
                    set = function(info, v)
                        LetsPug:SetServerHourOffset(v)
                    end,
                    width = "full",
                    order = 11
                },
            }
        },
        sync = {
            name = "Sync",
            type = "group",
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
        alts = {
            name = "Alts",
            type = "group",
            order = 5,
            args = {
                add = {
                    name = "Add",
                    desc = "Marks character as your alt.",
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
                    name = "Toggle visibility",
                    desc = "Toggles alt's visibility on/off.",
                    type = "multiselect",
                    values = "GetAltValuesSlash",
                    get = function(info, name)
                        return LetsPug:GetAltVisibility(name)
                    end,
                    set = function(info, name, is_shown)
                        LetsPug:SetAltVisibility(name, is_shown)
                    end,
                    width = "full",
                    order = 2
                },
                delete = {
                    name = "Delete",
                    desc = "Clears alt mark from character, leaving instance save info intact.",
                    type = "select",
                    values = "GetAltValuesSlash",
                    get = function(info, name) end,
                    set = function(info, name, ...)
                        LetsPug:ClearAlt(name)
                    end,
                    width = "full",
                    order = 3
                },
            }
        },
    }
}
