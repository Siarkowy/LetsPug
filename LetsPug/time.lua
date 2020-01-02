--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local wipe = LetsPug.wipe

local MINUTE = 60
local HOUR   = 60 * MINUTE
local DAY    = 24 * HOUR
local WEEK   =  7 * DAY

--- Returns a guessed hour difference between client and server.
function LetsPug:GuessServerHourOffset(_client_hr, _server_hr)
    local now_stamp = time()
    local client_tz = (_client_hr or date("%H", now_stamp)) - (_server_hr or date("!%H", now_stamp))
    local server_tz = 0 -- assume GMT

    local diff_tz = client_tz - server_tz
    if diff_tz < -9 then
        diff_tz = diff_tz + 24
    elseif diff_tz > 13 then
        diff_tz = diff_tz - 24
    end
    return diff_tz
end

--- Returns hour difference between client and server.
function LetsPug:GetServerHourOffset()
    return self.db.realm.server.hour_offset
end

--- Sets hour difference between client and server.
function LetsPug:SetServerHourOffset(offset)
    self.db.realm.server.hour_offset = tonumber(offset) or 0
end

--- Returns hour at which instance saves reset server-side.
-- Stored in server's timezone.
function LetsPug:GetServerResetHour()
    return tonumber(self.db.realm.server.reset_hour) or 0
end

--- Sets hour at which instance saves reset server-side.
-- Stored in server's timezone.
function LetsPug:SetServerResetHour(hour)
    self.db.realm.server.reset_hour = tonumber(hour) or 0
end

--- Returns server's current timestamp.
-- Calculated from player's current timestamp with inferred hour offset.
function LetsPug:GetServerNow()
    local now = time()
    local hour_offset = self:GetServerHourOffset()
    return now - hour_offset * 60 * 60
end

--- Throws an error if argument under test in not a readable date in YYYYMMDD format.
function LetsPug:AssertReadable(arg)
    if type(arg) ~= "number" then
        error(("Arg should be a number, got %q"):format(type(arg)), 2)
    end
    if arg <= 20000101 or arg >= 30000101 then
        error(("Arg should be a readable date, got %q"):format(arg), 2)
    end
end

--- Returns a readable date in YYYYMMDD format for specified timestamp.
function LetsPug:GetReadableDateFromTimestamp(stamp)
    return tonumber(date("%Y%m%d", stamp))
end

--- Returns a readable date/hour in YYYYMMDD.P format for specified timestamp.
-- The P stands for fractional part of whole day, with minute resolution.
function LetsPug:GetReadableDateHourFromTimestamp(stamp)
    return tonumber(date("%Y%m%d", stamp)) + (date("%H", stamp) * 60 + date("%M", stamp)) / 1440
end

do
    local temp_date = {}

    --- Returns a timestamp for specified YYYYMMDD readable date.
    function LetsPug:GetTimestampFromReadableDate(readable)
        if not readable then return nil end

        temp_date.year  = tonumber(string.sub(readable, 0, 4))
        temp_date.month = tonumber(string.sub(readable, 5, 6))
        temp_date.day   = tonumber(string.sub(readable, 7, 8))
        temp_date.hour  = date("%H", 0)
        temp_date.min   = 0
        temp_date.sec   = 0
        return time(temp_date)
    end
end

--- Returns server daily reset timestamp for specified YYYYMMDD readable date.
function LetsPug:GetResetTimestampFromReadableDate(readable)
    local reset_tstmp = self:GetTimestampFromReadableDate(readable)
    if not reset_tstmp then return nil end

    return reset_tstmp + (self:GetServerResetHour() - self:GetServerHourOffset()) * HOUR
end

--- Returns a short date in MMDD format for specified timestamp.
function LetsPug:GetShortDateFromTimestamp(timestamp)
    return date("%m%d", timestamp)
end

--- Returns a short date in MMDD format for specified YYYYMMDD readable date.
function LetsPug:GetShortDateFromReadable(readable)
    return string.sub(readable, 5, 8)
end

--- Recovers a timestamp from specified MMDD short date.
-- Tries both current and neighbour year and returns the closer one.
-- Neighbour year is either (1) previous year for `now` before Jun 01
-- or (2) next year otherwise.
function LetsPug:GetTimestampFromShort(short, now_readable)
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
function LetsPug:GetReadableDateFromShort(short, now_readable)
    return self:GetReadableDateFromTimestamp(self:GetTimestampFromShort(short, now_readable))
end

do
    local assertEqual = LetsPug.assertEqual

    assertEqual(LetsPug:GetReadableDateFromTimestamp(0), 19700101)

    assertEqual(LetsPug:GetShortDateFromTimestamp(0), "0101")

    assertEqual(LetsPug:GetShortDateFromReadable(19700101), "0101")

    assertEqual(LetsPug:GetTimestampFromReadableDate(19700101), 0)
    assertEqual(LetsPug:GetTimestampFromReadableDate("19700101"), 0)

    assertEqual(LetsPug:GetReadableDateFromShort("0722", 20190722), 20190722)
    assertEqual(LetsPug:GetReadableDateFromShort("722",  20190722), 20190722)

    assertEqual(LetsPug:GetReadableDateFromShort("0122", 20190715), 20190122)
    assertEqual(LetsPug:GetReadableDateFromShort("0122", 20190722), 20190122)
    assertEqual(LetsPug:GetReadableDateFromShort("0122", 20190729), 20200122)

    assertEqual(LetsPug:GetReadableDateFromShort("0722", 20190115), 20180722)
    assertEqual(LetsPug:GetReadableDateFromShort("0722", 20190122), 20190722)
    assertEqual(LetsPug:GetReadableDateFromShort("0722", 20190129), 20190722)

    -- UTC+0 / GMT
    assertEqual(LetsPug:GuessServerHourOffset(00, 00), 0)
    assertEqual(LetsPug:GuessServerHourOffset(23, 23), 0)

    -- UTC+1 / CET
    assertEqual(LetsPug:GuessServerHourOffset(01, 00), 1)
    assertEqual(LetsPug:GuessServerHourOffset(23, 22), 1)
    assertEqual(LetsPug:GuessServerHourOffset(00, 23), 1)

    -- UTC+13 / NZDT
    assertEqual(LetsPug:GuessServerHourOffset(13, 00), 13)
    assertEqual(LetsPug:GuessServerHourOffset(23, 10), 13)
    assertEqual(LetsPug:GuessServerHourOffset(00, 11), 13)
    assertEqual(LetsPug:GuessServerHourOffset(12, 23), 13)

    -- UTC-9 / AKST
    assertEqual(LetsPug:GuessServerHourOffset(00, 09), -9)
    assertEqual(LetsPug:GuessServerHourOffset(14, 23), -9)
    assertEqual(LetsPug:GuessServerHourOffset(15, 00), -9)
    assertEqual(LetsPug:GuessServerHourOffset(23, 08), -9)
end
