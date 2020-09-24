--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 3-Clause "New" license (see LICENSE file).
--------------------------------------------------------------------------------

local abs = abs
local date = date
local format = string.format
local modf = math.modf
local time = time

local GetQuestResetTime = GetQuestResetTime

local wipe = LetsRaid.wipe

local MINUTE = 60
local HOUR   = 60 * MINUTE
local DAY    = 24 * HOUR
local WEEK   =  7 * DAY

local function toHHMM(t) -- from http://lua-users.org/wiki/TimeZone
    if not t then return end

    local h, m = modf(t / 3600)
    return format("%+.4d", 100 * h + 60 * m)
end

LetsRaid.toHHMM = toHHMM

local function toISO8601(utc_t, utc_dt)
    if not utc_t then return end
    utc_dt = utc_dt or 0

    local date_str = date("!%Y-%m-%dT%X", utc_t + utc_dt)
    local offset = toHHMM(utc_dt)
    local stamp = format("%s%s", date_str, offset):gsub("+0000","Z")
    return stamp
end

LetsRaid.toISO8601 = toISO8601

--- Returns true if automatic time calibration is enabled.
function LetsRaid:IsAutomaticTime()
    return self.db.realm.time.automatic
end

--- Toggles automatic time calibration on/off.
function LetsRaid:SetAutomaticTime(enabled)
    self.db.realm.time.automatic = not not enabled
end

--- Returns a guessed local to UTC (client) time difference in seconds.
-- Negative for time zones west of Greenwich, positive otherwise.
function LetsRaid:GuessClientTimeOffset(loc_hh, loc_mm, utc_hh, utc_mm)
    local now_t = time()

    loc_hh = loc_hh or date("%H", now_t)
    loc_mm = loc_mm or date("%M", now_t)

    utc_hh = utc_hh or date("!%H", now_t)
    utc_mm = utc_mm or date("!%M", now_t)

    local loc_now_t = loc_hh * HOUR + loc_mm * MINUTE
    local utc_now_t = utc_hh * HOUR + utc_mm * MINUTE
    local offset_dt = loc_now_t - utc_now_t

    if offset_dt < -9 * HOUR then
        offset_dt = offset_dt + DAY
    elseif offset_dt > 13 * HOUR then
        offset_dt = offset_dt - DAY
    end

    if self.debug then self:Trace("GuessClientTimeOffset", offset_dt, "->", toHHMM(offset_dt)) end
    return offset_dt
end

function LetsRaid:GuessAndStoreClientTimeOffset(...)
    local offset_dt = self:GuessClientTimeOffset(...)
    self:SetClientTimeOffset(offset_dt)
    return offset_dt
end

--- Returns local to UTC (client) time difference in seconds.
function LetsRaid:GetClientTimeOffset()
    return self.db.realm.time.client_dt or self:GuessAndStoreClientTimeOffset()
end

--- Saves local to UTC (client) time difference in seconds.
function LetsRaid:SetClientTimeOffset(dt)
    self.db.realm.time.client_dt = tonumber(dt)
end

--- Returns time to server-side quest reset in seconds.
function LetsRaid:GetServerQuestResetOffset()
    -- GetQuestResetTime() returns a value of `-time()` during first
    -- UPDATE_INSTANCE_INFO after restarting the game client
    local reset_dt = GetQuestResetTime()
    if reset_dt > 0 then
        if self.debug then self:Trace("GetServerQuestResetOffset", reset_dt, "->", toHHMM(reset_dt)) end
        return reset_dt
    end

    self:Trace("GetServerQuestResetOffset", nil)
end

--- Returns time to server-side raid reset in seconds if player has an active lockout.
-- It is assumed that all raid instance types reset at the same time.
function LetsRaid:GetServerRaidResetOffset()
    for i = 1, GetNumSavedInstances() do
        local name, _, reset_dt = GetSavedInstanceInfo(i)
        reset_dt = reset_dt % DAY

        if self:GetInstanceKeyForMap(name) then
            if self.debug then self:Trace("GetServerRaidResetOffset", reset_dt, "->", toHHMM(reset_dt)) end
            return reset_dt
        end
    end

    self:Trace("GetServerRaidResetOffset", nil)
end

--- Returns UTC timestamp of next server-side quest reset.
function LetsRaid:GetServerNextQuestReset()
    local reset_dt = self:GetServerQuestResetOffset()
    if not reset_dt then
        self:Debug("GetServerNextQuestReset", nil)
        return
    end
    local reset_t = time() + reset_dt

    if self.debug then self:Debug("GetServerNextQuestReset", reset_t, "->", toISO8601(reset_t)) end
    return reset_t
end

--- Returns UTC timestamp of next server-side raid reset.
-- Only correct right after UPDATE_INSTANCE_INFO event.
function LetsRaid:GetServerNextRaidReset()
    local reset_dt = self:GetServerRaidResetOffset()
    if not reset_dt then
        self:Debug("GetServerNextRaidReset", nil)
        return
    end
    local reset_t = time() + reset_dt

    if self.debug then self:Debug("GetServerNextRaidReset", reset_t, "->", toISO8601(reset_t)) end
    return reset_t
end

--- Returns number of seconds past UTC midnight at which lockouts reset.
-- Infers the value from available lockouts & quest reset timer.
function LetsRaid:GuessServerResetOffset(use_quest)
    local raid_t = self:GetServerNextRaidReset()
    local quest_t = self:GetServerNextQuestReset()

    local raid_dt = raid_t and (raid_t % DAY)
    local quest_dt = quest_t and (quest_t % DAY)
    local cur_dt = self:GetServerResetOffset()

    local reset_dt = use_quest and quest_dt or raid_dt or cur_dt or quest_dt
    if self.debug then self:Trace("GuessServerResetOffset", raid_dt, quest_dt, cur_dt, reset_dt, "->",
        toHHMM(raid_dt), toHHMM(quest_dt), toHHMM(cur_dt), toHHMM(reset_dt)) end
    return reset_dt
end

function LetsRaid:GuessAndStoreServerResetOffset(...)
    local reset_dt = self:GuessServerResetOffset(...)
    if reset_dt then self:SetServerResetOffset(reset_dt) end
    return reset_dt
end

--- Returns number of seconds past UTC midnight at which lockouts reset.
function LetsRaid:GetServerResetOffset()
    local reset_dt = self.db.realm.time.reset_dt
    if reset_dt then
        return reset_dt
    end
end

--- Saves number of seconds past UTC midnight at which lockouts reset.
function LetsRaid:SetServerResetOffset(dt)
    self.db.realm.time.reset_dt = (tonumber(dt) or 0) % DAY
end

--- Returns UTC timestamp of next server-side lockout reset, either raid or quest.
function LetsRaid:GetServerNextInstanceReset()
    local now_t = time()
    local midnight_t = now_t - now_t % DAY
    local reset_dt = self:GetServerResetOffset()
    if not reset_dt then
        self:Debug("GetServerNextInstanceReset", "unknown")
        return
    end
    local reset_t = midnight_t + reset_dt
    if reset_t < now_t then reset_t = reset_t + DAY end

    if self.debug then self:Debug("GetServerNextInstanceReset", reset_t, "->", toISO8601(reset_t)) end
    return reset_t
end

--- Adjusts time settings from available lockout timers.
-- Raid lockout timers are always the preferred source of information.
-- Daily quests reset timer is used only if there was no information collected yet,
-- otherwise the existing time settings are kept intact. This can be overridden
-- with `use_quest` flag to force a refresh when there's no raid lockout timers.
function LetsRaid:CalibrateTime(use_quest)
    local client_dt = self:GuessAndStoreClientTimeOffset()
    self:GuessAndStoreServerResetOffset(use_quest)

    if self.debug then
        local reset_t = self:GetServerNextInstanceReset()
        self:Debug("CalibrateTime", use_quest, reset_t, client_dt, "->", toISO8601(reset_t, client_dt))
    end
end

--- Throws an error if argument under test in not a readable date in YYYYMMDD format.
function LetsRaid:AssertReadable(arg)
    if type(arg) ~= "number" then
        error(("Arg should be a number, got %q"):format(type(arg)), 2)
    end
    if arg <= 20000101 or arg >= 30000101 then
        error(("Arg should be a readable date, got %q"):format(arg), 2)
    end
end

--- Returns a readable date in YYYYMMDD format for specified timestamp.
function LetsRaid:GetReadableDateFromTimestamp(stamp)
    if not stamp then return nil end
    return tonumber(date("!%Y%m%d", stamp))
end

--- Returns a readable date/hour in YYYYMMDD.P format for specified timestamp.
-- The P stands for fractional part of whole day, with minute resolution.
function LetsRaid:GetReadableDateHourFromTimestamp(stamp)
    if not stamp then return nil end
    return tonumber(date("!%Y%m%d", stamp)) + (date("!%H", stamp) * HOUR + date("!%M", stamp) * MINUTE) / DAY
end

do
    local temp_date = {}
    local dt = LetsRaid:GuessClientTimeOffset()
    local t = date("*t")

    --- Returns a timestamp for specified YYYYMMDD readable date.
    function LetsRaid:GetTimestampFromReadableDate(readable)
        if not readable then return nil end

        temp_date.year  = tonumber(string.sub(readable, 1, 4))
        temp_date.month = tonumber(string.sub(readable, 5, 6))
        temp_date.day   = tonumber(string.sub(readable, 7, 8))
        temp_date.hour  = dt / HOUR
        temp_date.min   = 0
        temp_date.sec   = 0
        temp_date.isdst = t.isdst

        return time(temp_date)
    end
end

--- Returns server daily reset timestamp for specified YYYYMMDD readable date.
function LetsRaid:GetResetTimestampFromReadableDate(readable, reset_dt)
    local reset_tstmp = self:GetTimestampFromReadableDate(readable)
    if not reset_tstmp then return nil end

    reset_dt = reset_dt or self:GetServerResetOffset()
    return reset_tstmp + reset_dt
end

--- Returns a short date in MMDD format for specified timestamp.
function LetsRaid:GetShortDateFromTimestamp(stamp)
    if not stamp then return nil end
    return date("!%m%d", stamp)
end

--- Returns a short date in MMDD format for specified YYYYMMDD readable date.
function LetsRaid:GetShortDateFromReadable(readable)
    if not readable then return nil end
    return string.sub(readable, 5, 8)
end

--- Recovers a timestamp from specified MMDD short date.
-- Tries both current and neighbour year and returns the closer one.
-- Neighbour year is either (1) previous year for `now` before Jun 01
-- or (2) next year otherwise.
function LetsRaid:GetTimestampFromShort(short, now_readable)
    local now_readable = now_readable or self:GetReadableDateFromTimestamp(time())
    self:AssertReadable(now_readable)

    local now_short = self:GetShortDateFromReadable(now_readable)
    local now_stamp = self:GetTimestampFromReadableDate(now_readable)
    local padded_short = format("%04d", short)

    local current_year = tostring(now_readable):sub(1, 4)
    local neighbour_year = current_year + (now_short >= "0601" and 1 or -1)

    local a = self:GetTimestampFromReadableDate(current_year .. padded_short)
    local b = self:GetTimestampFromReadableDate(neighbour_year .. padded_short)
    local da, db = abs(a - now_stamp), abs(b - now_stamp)
    return da < db and a or b
end

--- Returns a readable date in YYYYMMDD format for specified MMDD short date.
-- Limitations of GetTimestampFromShort apply.
function LetsRaid:GetReadableDateFromShort(short, now_readable)
    return self:GetReadableDateFromTimestamp(self:GetTimestampFromShort(short, now_readable))
end

do
    local assertEqual = LetsRaid.assertEqual

    assertEqual(toHHMM(), nil)
    assertEqual(toHHMM(0), "+0000")
    assertEqual(toHHMM(3600), "+0100")
    assertEqual(toHHMM(7260), "+0201")
    assertEqual(toHHMM(-3600), "-0100")
    assertEqual(toHHMM(-7260), "-0201")

    assertEqual(toISO8601(), nil)
    assertEqual(toISO8601(0), "1970-01-01T00:00:00Z")
    assertEqual(toISO8601(0, 0), "1970-01-01T00:00:00Z")
    assertEqual(toISO8601(7200, 0), "1970-01-01T02:00:00Z")
    assertEqual(toISO8601(0, 3600), "1970-01-01T01:00:00+0100")
    assertEqual(toISO8601(7200, 3600), "1970-01-01T03:00:00+0100")
    assertEqual(toISO8601(0, 7200), "1970-01-01T02:00:00+0200")
    assertEqual(toISO8601(3600, 7200), "1970-01-01T03:00:00+0200")

    assertEqual(LetsRaid:GuessClientTimeOffset(00, 00, 00, 00), 0 * HOUR) -- UTC+0 / GMT
    assertEqual(LetsRaid:GuessClientTimeOffset(23, 00, 23, 00), 0 * HOUR)

    assertEqual(LetsRaid:GuessClientTimeOffset(01, 00, 00, 00), 1 * HOUR) -- UTC+1 / CET
    assertEqual(LetsRaid:GuessClientTimeOffset(23, 00, 22, 00), 1 * HOUR)
    assertEqual(LetsRaid:GuessClientTimeOffset(00, 00, 23, 00), 1 * HOUR)

    assertEqual(LetsRaid:GuessClientTimeOffset(13, 00, 00, 00), 13 * HOUR) -- UTC+13 / NZDT
    assertEqual(LetsRaid:GuessClientTimeOffset(23, 00, 10, 00), 13 * HOUR)
    assertEqual(LetsRaid:GuessClientTimeOffset(00, 00, 11, 00), 13 * HOUR)
    assertEqual(LetsRaid:GuessClientTimeOffset(12, 00, 23, 00), 13 * HOUR)

    assertEqual(LetsRaid:GuessClientTimeOffset(00, 00, 09, 00), -9 * HOUR) -- UTC-9 / AKST
    assertEqual(LetsRaid:GuessClientTimeOffset(14, 00, 23, 00), -9 * HOUR)
    assertEqual(LetsRaid:GuessClientTimeOffset(15, 00, 00, 00), -9 * HOUR)
    assertEqual(LetsRaid:GuessClientTimeOffset(23, 00, 08, 00), -9 * HOUR)

    assertEqual(LetsRaid:GetReadableDateFromTimestamp(), nil)
    assertEqual(LetsRaid:GetReadableDateFromTimestamp(0), 19700101)
    assertEqual(LetsRaid:GetReadableDateFromTimestamp(DAY), 19700102)
    assertEqual(LetsRaid:GetReadableDateFromTimestamp(DAY-1), 19700101)

    assertEqual(LetsRaid:GetReadableDateHourFromTimestamp(), nil)
    assertEqual(LetsRaid:GetReadableDateHourFromTimestamp(0), 19700101)
    assertEqual(LetsRaid:GetReadableDateHourFromTimestamp(12 * HOUR), 19700101.5)
    assertEqual(LetsRaid:GetReadableDateHourFromTimestamp(DAY), 19700102)

    assertEqual(LetsRaid:GetShortDateFromTimestamp(), nil)
    assertEqual(LetsRaid:GetShortDateFromTimestamp(0), "0101")
    assertEqual(LetsRaid:GetShortDateFromTimestamp(DAY), "0102")
    assertEqual(LetsRaid:GetShortDateFromTimestamp(DAY-1), "0101")

    assertEqual(LetsRaid:GetShortDateFromReadable(), nil)
    assertEqual(LetsRaid:GetShortDateFromReadable(19700101), "0101")
    assertEqual(LetsRaid:GetShortDateFromReadable(19700102), "0102")

    assertEqual(LetsRaid:GetTimestampFromReadableDate(), nil)
    assertEqual(LetsRaid:GetTimestampFromReadableDate(19700101), 0)
    assertEqual(LetsRaid:GetTimestampFromReadableDate("19700101"), 0)
    assertEqual(LetsRaid:GetTimestampFromReadableDate(19700102), DAY)
    assertEqual(LetsRaid:GetTimestampFromReadableDate("19700102"), DAY)

    assertEqual(LetsRaid:GetReadableDateFromShort("0722", 20190722), 20190722)
    assertEqual(LetsRaid:GetReadableDateFromShort("722",  20190722), 20190722)

    assertEqual(LetsRaid:GetReadableDateFromShort("0122", 20190715), 20190122)
    assertEqual(LetsRaid:GetReadableDateFromShort("0122", 20190722), 20190122)
    assertEqual(LetsRaid:GetReadableDateFromShort("0122", 20190729), 20200122)

    assertEqual(LetsRaid:GetReadableDateFromShort("0722", 20190115), 20180722)
    assertEqual(LetsRaid:GetReadableDateFromShort("0722", 20190122), 20190722)
    assertEqual(LetsRaid:GetReadableDateFromShort("0722", 20190129), 20190722)

    assertEqual(LetsRaid:GetResetTimestampFromReadableDate(19700101, 10 * HOUR), 0 * DAY + 10 * HOUR)
    assertEqual(LetsRaid:GetResetTimestampFromReadableDate(19700102, 10 * HOUR), 1 * DAY + 10 * HOUR)

    local now_t = time()
    local hour = (now_t % DAY - now_t % HOUR) / HOUR
    assertEqual(hour, 0 + date("!%H", now_t)) -- time() is modulo friendly
end
