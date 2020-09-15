--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 3-Clause "New" license (see LICENSE file).
--------------------------------------------------------------------------------

local function wipe(t)
    for k, v in pairs(t) do
        if type(v) == "table" then wipe(v) end
        t[k] = nil
    end
end

LetsRaid.wipe = wipe

--- Dumps parameters into chat (only if current log level >= message level).
function LetsRaid:Log(level, ...)
    if not self.debug or self.debug < level then return end
    self:Print(...)
end

function LetsRaid:Debug(...) self:Log(1, "(D)", ...) end
function LetsRaid:Trace(...) self:Log(2, "(T)", ...) end

--- Sets debug level.
function LetsRaid:SetDebug(level)
    level = tonumber(level) or 0
    self.db.profile.debug = level
    self.debug = level
end

--- Shows a formatted message in chat.
function LetsRaid:Printf(fmt, ...)
    self:Print(string.format(fmt, ...))
end

--- Returns input string in Pascal case (upper case first, lower case rest).
-- Appropriate for character names.
function LetsRaid.StrToPascalCase(str)
    if not str or str == "" then return nil end
    str = str:sub(1, 1):upper() .. str:sub(2):lower()
    return str
end

do
    local _timers = {}
    LetsRaid.timers = _timers

    --- Returns true if specified timer has passed the desired interval.
    -- Timers are stored in an (optionally specified) array, and are
    -- distinguished by an (optional) key, likely related to caller function.
    function LetsRaid.HasPassed(interval, key, timers)
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
