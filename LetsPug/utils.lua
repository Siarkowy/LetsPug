--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local function wipe(t)
    for k, v in pairs(t) do
        if type(v) == "table" then wipe(v) end
        t[k] = nil
    end
end

LetsPug.wipe = wipe

function LetsPug:Printf(fmt, ...)
    self:Print(string.format(fmt, ...))
end

--- Returns input string in Pascal case (upper case first, lower case rest).
-- Appropriate for character names.
function LetsPug.StrToPascalCase(str)
    if not str or str == "" then return nil end
    str = str:sub(1, 1):upper() .. str:sub(2):lower()
    return str
end

do
    local _timers = {}
    LetsPug.timers = _timers

    --- Returns true if specified timer has passed the desired interval.
    -- Timers are stored in an (optionally specified) array, and are
    -- distinguished by an (optional) key, likely related to caller function.
    function LetsPug.HasPassed(interval, key, timers)
        assert(interval)
        assert(type(interval) == "number")
        key = key or "timer"
        timers = timers or _timers

        local now = GetTime()
        local last_time = timers[key] or 0
        if now - last_time >= interval then
            timers[key] = now
            return true
        end
    end
end
