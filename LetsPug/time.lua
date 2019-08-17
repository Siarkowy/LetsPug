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
-- Susceptible to off-by-one error because of possible client-server time drift.
function LetsPug:GuessServerHourOffset()
    local client_hr = tonumber(date("%H"))
    local server_hr = GetGameTime()
    local diff = client_hr - server_hr
    return diff
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

--- Returns a readable date in YYYYMMDD format for specified timestamp.
function LetsPug:GetReadableDateFromTimestamp(stamp)
    return tonumber(date("%Y%m%d", stamp))
end

do
    local temp_date = {}

    --- Returns a timestamp for specified YYYYMMDD readable date.
    function LetsPug:GetTimestampFromReadableDate(readable)
        assert(readable, "GetTimestampFromReadableDate: readable is required")

        temp_date.year  = tonumber(string.sub(readable, 0, 4))
        temp_date.month = tonumber(string.sub(readable, 5, 6))
        temp_date.day   = tonumber(string.sub(readable, 7, 8))
        temp_date.hour  = date("%H", 0)
        temp_date.min   = 0
        temp_date.sec   = 0
        return time(temp_date)
    end
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
function LetsPug:GetTimestampFromShort(short, now)
    local now = now or time()
    local now_short = self:GetShortDateFromTimestamp(now)
    local padded_short = format("%04d", short)

    local current_year = date("%Y")
    local neighbour_year = current_year + (now_short >= "0601" and 1 or -1)

    local a = self:GetTimestampFromReadableDate(current_year .. padded_short)
    local b = self:GetTimestampFromReadableDate(neighbour_year .. padded_short)
    local da, db = abs(a - now), abs(b - now)
    return da < db and a or b
end

--- Returns a readable date in YYYYMMDD format for specified MMDD short date.
-- Limitations of GetTimestampFromShort apply.
function LetsPug:GetReadableDateFromShort(short, now)
    return self:GetReadableDateFromTimestamp(self:GetTimestampFromShort(short, now))
end

do
    local assertEqual = LetsPug.assertEqual

    assertEqual(LetsPug:GetReadableDateFromTimestamp(0), 19700101)

    assertEqual(LetsPug:GetShortDateFromTimestamp(0), "0101")

    assertEqual(LetsPug:GetShortDateFromReadable(19700101), "0101")

    assertEqual(LetsPug:GetTimestampFromReadableDate(19700101), 0)
    assertEqual(LetsPug:GetTimestampFromReadableDate("19700101"), 0)

    local now = time{year = 2019, month = 07, day = 22, hour = 0, min = 0, sec = 0}
    assertEqual(LetsPug:GetReadableDateFromShort("0722", now), 20190722)
    assertEqual(LetsPug:GetReadableDateFromShort("722", now), 20190722)

    local now = time{year = 2019, month = 07, day = 22, hour = 0, min = 0, sec = 0}
    assertEqual(LetsPug:GetReadableDateFromShort("0122", now - 1 * WEEK), 20190122)
    assertEqual(LetsPug:GetReadableDateFromShort("0122", now + 0 * WEEK), 20190122)
    assertEqual(LetsPug:GetReadableDateFromShort("0122", now + 1 * WEEK), 20200122)

    local now = time{year = 2019, month = 01, day = 22, hour = 0, min = 0, sec = 0}
    assertEqual(LetsPug:GetReadableDateFromShort("0722", now - 1 * WEEK), 20180722)
    assertEqual(LetsPug:GetReadableDateFromShort("0722", now + 0 * WEEK), 20190722)
    assertEqual(LetsPug:GetReadableDateFromShort("0722", now + 1 * WEEK), 20190722)
end
