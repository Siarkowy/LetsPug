--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local wipe = LetsPug.wipe

local encode_abbrevs = {
    kgm = "q",
    kg = "M",
    km = "G",
    gm = "K",

    stz = "w",
    st = "Z",
    sz = "T",
    tz = "S",

    hbp = "e",
    hb = "P",
    hp = "B",
    bp = "H",

    eqw = "a",
    ewq = "a",
    qew = "a",
    qwe = "a",
    weq = "a",
    wqe = "a",

    qw = "E",
    qe = "W",
    we = "Q",
    wq = "E",
    eq = "W",
    ew = "Q",
}

local decode_abbrevs = {
    M = "kg",
    G = "km",
    K = "gm",

    Z = "st",
    T = "sz",
    S = "tz",

    P = "hb",
    B = "hp",
    H = "bp",

    q = "kgm",
    w = "stz",
    e = "hbp",

    Q = "stzhbp",
    W = "kgmhbp",
    E = "kgmstz",

    a = "kgmstzhbp",
    A = "",
}

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
    function LetsPug:SortedByDate(...)
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

function LetsPug:EncodeSaveInfo(saves, since)
    local hr_frac = since and 0 or self:GetServerResetHour() / 24

    saves = saves or self.saves or {}
    since = since or self:GetReadableDateHourFromTimestamp(self:GetServerNow())

    local function save(key)
        local expire_date = saves[key]
        return expire_date and expire_date + hr_frac > since and format("%s%s", key, expire_date) or ""
    end

    -- construct initial info in sorted reset order (ensures proper date shortening)
    local save_info = format("%s%s%s%s%s%s%s%s%s", self:SortedByDate(
        save"k", save"g", save"m", save"s", save"t", save"z", save"h", save"b", save"p"))
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

    -- apply complements
    save_info = gsub(save_info, "[kgm]+", encode_abbrevs)
    save_info = gsub(save_info, "[stz]+", encode_abbrevs)
    save_info = gsub(save_info, "[hbp]+", encode_abbrevs)
    save_info = gsub(save_info, "[qwe]+", encode_abbrevs)

    return save_info
end

do
    local saves = {}
    function LetsPug:DecodeSaveInfo(save_info, now)
        wipe(saves)

        local _month, _day
        for instance_keys, month, day in save_info:gmatch("(%a+)(%d?%d?)(%d%d)") do
            -- expand complements
            instance_keys = instance_keys:gsub("%a", decode_abbrevs)

            -- increase month on decreasing day
            _month = _month or month ~= "" and month
            if _day and day < _day then
                _month = format("%02d", _month + 1)
            end
            _day = day

            -- store instance vs. recovered YYYYMMDD pair
            local readable = self:GetReadableDateFromShort(_month .. _day, now)
            for instance_key in instance_keys:gmatch("[kgmstzhbp]") do
                saves[instance_key] = readable
            end
        end

        return saves
    end
end

do
    local assertEqual = LetsPug.assertEqual
    local assertEqualKV = LetsPug.assertEqualKV

    local X1231 = 20181231
    local Y0101 = 20190101
    local Y0102 = 20190102
    local Y0103 = 20190103
    local Y0131 = 20190131
    local Y0201 = 20190201

    -- date sorting
    assertEqual(string.join("", LetsPug:SortedByDate("a02", "b03", "c01")), "c01a02b03")
    assertEqual(string.join("", LetsPug:SortedByDate("a01", "b01", "c01")), "a01b01c01")
    assertEqual(string.join("", LetsPug:SortedByDate("c01", "b01", "a01")), "c01b01a01")

    -- no saves
    assertEqual(LetsPug:EncodeSaveInfo({}, X1231), "A1231")

    -- date grouping
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101}, X1231), "k0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0101}, X1231), "ks0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0101, h = Y0101}, X1231), "ksh0101")

    -- date filtering
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101}, X1231), "k0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102}, Y0101), "s0102")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102}, X1231), "k0101s02")

    -- month shortening
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102}, X1231), "k0101s02")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0102, s = Y0101}, X1231), "s0101k02")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0131, s = Y0201}, X1231), "k0131s01")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0201, s = Y0131}, X1231), "s0131k01")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102, h = Y0103}, X1231), "k0101s02h03")

    -- tier grouping
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101}, X1231), "q0101")
    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, t = Y0101, z = Y0101}, X1231), "w0101")
    assertEqual(LetsPug:EncodeSaveInfo({h = Y0101, b = Y0101, p = Y0101}, X1231), "e0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101}, X1231), "a0101")

    -- complements
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101}, X1231), "M0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, m = Y0101}, X1231), "G0101")
    assertEqual(LetsPug:EncodeSaveInfo({g = Y0101, m = Y0101}, X1231), "K0101")

    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, t = Y0101}, X1231), "Z0101")
    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, z = Y0101}, X1231), "T0101")
    assertEqual(LetsPug:EncodeSaveInfo({t = Y0101, z = Y0101}, X1231), "S0101")

    assertEqual(LetsPug:EncodeSaveInfo({h = Y0101, b = Y0101}, X1231), "P0101")
    assertEqual(LetsPug:EncodeSaveInfo({h = Y0101, p = Y0101}, X1231), "B0101")
    assertEqual(LetsPug:EncodeSaveInfo({b = Y0101, p = Y0101}, X1231), "H0101")

    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101}, X1231), "E0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, h = Y0101, b = Y0101, p = Y0101}, X1231), "W0101")
    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101}, X1231), "Q0101")

    -- different reset for all instances
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101+0, g = Y0101+1, m = Y0101+2, s = Y0101+3, t = Y0101+4, z = Y0101+5, h = Y0101+6, b = Y0101+7, p = Y0101+8}, X1231), "k0101g02m03s04t05z06h07b08p09")

    -- all but one reset equal
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0102}, X1231), "EP0101p02")

    -- unknown instances
    assertEqual(LetsPug:EncodeSaveInfo({x = Y0101}, X1231), "A1231")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, x = Y0101}, X1231), "k0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, x = Y0102}, X1231), "k0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0102, x = Y0101}, X1231), "k0102")

    -- no saves
    assertEqualKV(LetsPug:DecodeSaveInfo("", Y0101), {})

    -- date grouping
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101", X1231), {k = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("ks0101", X1231), {k = Y0101, s = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("ksh0101", X1231), {k = Y0101, s = Y0101, h = Y0101})

    -- date recovery
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02", X1231), {k = Y0101, s = Y0102})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0102s01", X1231), {k = Y0102, s = Y0201})

    -- month shortening
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02", X1231), {k = Y0101, s = Y0102})
    assertEqualKV(LetsPug:DecodeSaveInfo("s0101k02", X1231), {k = Y0102, s = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0131s01", X1231), {k = Y0131, s = Y0201})
    assertEqualKV(LetsPug:DecodeSaveInfo("s0131k01", X1231), {k = Y0201, s = Y0131})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02h03", X1231), {k = Y0101, s = Y0102, h = Y0103})

    -- tier grouping
    assertEqualKV(LetsPug:DecodeSaveInfo("q0101", X1231), {k = Y0101, g = Y0101, m = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("w0101", X1231), {s = Y0101, t = Y0101, z = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("e0101", X1231), {h = Y0101, b = Y0101, p = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("a0101", X1231), {k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101})

    -- complements
    assertEqualKV(LetsPug:DecodeSaveInfo("A1231", X1231), {})

    assertEqualKV(LetsPug:DecodeSaveInfo("M0101", X1231), {k = Y0101, g = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("G0101", X1231), {k = Y0101, m = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("K0101", X1231), {g = Y0101, m = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("Z0101", X1231), {s = Y0101, t = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("T0101", X1231), {s = Y0101, z = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("S0101", X1231), {t = Y0101, z = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("P0101", X1231), {h = Y0101, b = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("B0101", X1231), {h = Y0101, p = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("H0101", X1231), {b = Y0101, p = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("E0101", X1231), {k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("W0101", X1231), {k = Y0101, g = Y0101, m = Y0101, h = Y0101, b = Y0101, p = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("Q0101", X1231), {s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("K0101s02h03", X1231), {g = Y0101, m = Y0101, s = Y0102, h = Y0103})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101S02h03", X1231), {k = Y0101, t = Y0102, z = Y0102, h = Y0103})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02H03", X1231), {k = Y0101, s = Y0102, b = Y0103, p = Y0103})

    -- unknown instances
    assertEqualKV(LetsPug:DecodeSaveInfo("x0101", X1231), {})
    assertEqualKV(LetsPug:DecodeSaveInfo("kx0101", X1231), {k = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101x02", X1231), {k = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("x0101k02", X1231), {k = Y0102})
end
