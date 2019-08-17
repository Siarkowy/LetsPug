--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local LetsPug = LetsPug

LetsPug.slash = {
    type = "group",
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
            name = "Server settings",
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
                    order = 11
                },
            }
        },
    }
}
