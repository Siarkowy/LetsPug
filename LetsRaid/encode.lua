--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 3-Clause "New" license (see LICENSE file).
--------------------------------------------------------------------------------

local gsub = string.gsub
local join = string.join
local tinsert = table.insert

local wipe = LetsRaid.wipe

local function less_than(a, b)
    return a < b
end

--- Sorts table with provided comparator func or in ascending order by default.
-- Can be used in place of table.sort as a guaranteed stable sort.
-- Currently uses bubble sort, making it suitable for small tables.
local function stable_sort(t, comp_func)
    comp_func = comp_func or less_than

    local n = #t
    while n > 1 do
        for i = 1, n - 1 do
            if comp_func(t[i+1], t[i]) then
                t[i], t[i+1] = t[i+1], t[i]
            end
        end
        n = n - 1
    end
end

do
    local result = {}
    function LetsRaid:SortedByDate(...)
        wipe(result)
        for i = 1, select('#', ...) do
            table.insert(result, (select(i, ...)))
        end
        stable_sort(result, function(a, b)
            local a = tonumber((a or ""):match("%d+")) or 30000000
            local b = tonumber((b or ""):match("%d+")) or 30000000
            return a < b
        end)
        return unpack(result)
    end
end

local DAY = 86400
local save_pairs = {}
function LetsRaid:EncodeSaveInfo(saves, since)
    local hr_frac = since and 0 or (self:GetServerResetOffset() or 0) / DAY

    saves = saves or self.saves or {}
    since = since or self:GetReadableDateHourFromTimestamp(time())

    wipe(save_pairs)
    self.supportedInstanceKeys:gsub("%a", function(key)
        local expire_date = saves[key]
        local pair = expire_date and expire_date + hr_frac > since and format("%s%s", key, expire_date) or ""
        tinsert(save_pairs, pair)
    end)

    -- construct initial info in sorted reset order (ensures proper date shortening)
    local save_info = join("", self:SortedByDate(unpack(save_pairs)))
    save_info = save_info == "" and format("A%d", since) or save_info

    -- combine equal dates
    for i = 1, 4 do
        save_info = gsub(save_info, "(%d%d%d%d%d%d%d%d)(%D+)(%1)", "%2%3")
    end

    -- shorten dates to days
    for i = 1, 8 do
        save_info = gsub(save_info, "(.*)(%d%d%d%d%d%d%d%d)(%D+)(%d%d%d%d%d%d)(%d%d)", "%1%2%3%5")
    end

    -- drop years
    save_info = gsub(save_info, "(%d%d%d%d)(%d+)", "%2")

    return save_info
end

do
    local assertEqual = LetsRaid.assertEqual

    local X1231 = 20181231
    local Y0101 = 20190101
    local Y0102 = 20190102
    local Y0103 = 20190103
    local Y0131 = 20190131
    local Y0201 = 20190201

    -- date sorting
    assertEqual(string.join("", LetsRaid:SortedByDate("a02", "b03", "c01")), "c01a02b03")
    assertEqual(string.join("", LetsRaid:SortedByDate("a01", "b01", "c01")), "a01b01c01")
    assertEqual(string.join("", LetsRaid:SortedByDate("c01", "b01", "a01")), "c01b01a01")

    -- no saves
    assertEqual(LetsRaid:EncodeSaveInfo({}, X1231), "A1231")

    -- date grouping
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101}, X1231), "k0101")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, s = Y0101}, X1231), "ks0101")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, s = Y0101, h = Y0101}, X1231), "ksh0101")

    -- date filtering
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101}, X1231), "k0101")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, s = Y0102}, Y0101), "s0102")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, s = Y0102}, X1231), "k0101s02")

    -- month shortening
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, s = Y0102}, X1231), "k0101s02")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0102, s = Y0101}, X1231), "s0101k02")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0131, s = Y0201}, X1231), "k0131s01")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0201, s = Y0131}, X1231), "s0131k01")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, s = Y0102, h = Y0103}, X1231), "k0101s02h03")

    -- different reset for all instances
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101+0, g = Y0101+1, m = Y0101+2, s = Y0101+3, t = Y0101+4, z = Y0101+5, h = Y0101+6, b = Y0101+7, p = Y0101+8}, X1231), "k0101g02m03s04t05z06h07b08p09")

    -- all but one reset equal
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0102}, X1231), "kgmstzhb0101p02")

    -- unknown instances
    assertEqual(LetsRaid:EncodeSaveInfo({x = Y0101}, X1231), "A1231")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, x = Y0101}, X1231), "k0101")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0101, x = Y0102}, X1231), "k0101")
    assertEqual(LetsRaid:EncodeSaveInfo({k = Y0102, x = Y0101}, X1231), "k0102")
end
