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

do
    local result = {}
    function LetsPug:SortedByDate(...)
        wipe(result)
        for i = 1, select('#', ...) do
            table.insert(result, (select(i, ...)))
        end
        table.sort(result, function(a, b)
            local a = tonumber((a or ""):match("%d+")) or 30000000
            local b = tonumber((b or ""):match("%d+")) or 30000000
            return a < b
        end)
        return unpack(result)
    end
end

function LetsPug:EncodeSaveInfo(saves, since)
    saves = saves or self.saves or {}
    since = since or self:GetReadableDateFromTimestamp(self:GetServerNow())

    local function save(key)
        local expire_date = saves[key]
        return expire_date and expire_date >= since and key or ""
    end

    -- reset dates are assumed to be equal within tier
    local t4d = saves.k or saves.g or saves.m
    local t5d = saves.s or saves.t or saves.z
    local t6d = saves.h or saves.b or saves.p

    -- filter saves since given date
    t4d = t4d and t4d > since and t4d
    t5d = t5d and t5d > since and t5d
    t6d = t6d and t6d > since and t6d

    -- construct per tier infos
    local t4 = t4d and format("%s%s%s%s", save"k", save"g", save"m", t4d or "") or ""
    local t5 = t5d and format("%s%s%s%s", save"s", save"t", save"z", t5d or "") or ""
    local t6 = t6d and format("%s%s%s%s", save"h", save"b", save"p", t6d or "") or ""

    -- construct initial info in sorted reset order (ensures proper date shortening)
    local save_info = format("%s%s%s", self:SortedByDate(t4, t5, t6))
    save_info = save_info == "" and format("A%d", since) or save_info

    -- combine equal dates
    save_info = gsub(save_info, "(%d%d%d%d%d%d%d%d)(%D+)(%1)", "%2%3")
    save_info = gsub(save_info, "(%d%d%d%d%d%d%d%d)(%D+)(%1)", "%2%3")

    -- shorten dates to days (twice from the end)
    save_info = gsub(save_info, "(.*)(%d%d%d%d%d%d%d%d)(%D+)(%d%d%d%d%d%d)(%d%d)", "%1%2%3%5")
    save_info = gsub(save_info, "(.*)(%d%d%d%d%d%d%d%d)(%D+)(%d%d%d%d%d%d)(%d%d)", "%1%2%3%5")

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

    ----------------------------------------------------------------------------
    -- Encoding
    ----------------------------------------------------------------------------

    --------------------
    -- Date grouping
    --------------------
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101}, X1231), "k0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0101}, X1231), "ks0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0101, h = Y0101}, X1231), "ksh0101")

    --------------------
    -- Filtering
    --------------------
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101}, X1231), "k0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102}, Y0101), "s0102")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102}, X1231), "k0101s02")

    --------------------
    -- Month shortening
    --------------------
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102}, X1231), "k0101s02")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0102, s = Y0101}, X1231), "s0101k02")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0131, s = Y0201}, X1231), "k0131s01")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0201, s = Y0131}, X1231), "s0131k01")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, s = Y0102, h = Y0103}, X1231), "k0101s02h03")

    --------------------
    -- Complements
    --------------------
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101}, X1231), "M0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, m = Y0101}, X1231), "G0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101}, X1231), "q0101")

    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, t = Y0101}, X1231), "Z0101")
    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, z = Y0101}, X1231), "T0101")
    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, t = Y0101, z = Y0101}, X1231), "w0101")

    assertEqual(LetsPug:EncodeSaveInfo({h = Y0101, b = Y0101}, X1231), "P0101")
    assertEqual(LetsPug:EncodeSaveInfo({h = Y0101, p = Y0101}, X1231), "B0101")
    assertEqual(LetsPug:EncodeSaveInfo({h = Y0101, b = Y0101, p = Y0101}, X1231), "e0101")

    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101}, X1231), "E0101")
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, h = Y0101, b = Y0101, p = Y0101}, X1231), "W0101")
    assertEqual(LetsPug:EncodeSaveInfo({s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101}, X1231), "Q0101")

    --------------------
    -- All and no saves
    --------------------
    assertEqual(LetsPug:EncodeSaveInfo({k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101}, X1231), "a0101")
    assertEqual(LetsPug:EncodeSaveInfo({}, X1231), "A1231")

    ----------------------------------------------------------------------------
    -- Decoding
    ----------------------------------------------------------------------------

    assertEqualKV(LetsPug:DecodeSaveInfo("", Y0101), {})

    --------------------
    -- Date grouping
    --------------------
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101", X1231), {k = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("ks0101", X1231), {k = Y0101, s = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("ksh0101", X1231), {k = Y0101, s = Y0101, h = Y0101})

    --------------------
    -- Date recovery
    --------------------
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02", X1231), {k = Y0101, s = Y0102})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0102s01", X1231), {k = Y0102, s = Y0201})

    --------------------
    -- Month shortening
    --------------------
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02", X1231), {k = Y0101, s = Y0102})
    assertEqualKV(LetsPug:DecodeSaveInfo("s0101k02", X1231), {k = Y0102, s = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0131s01", X1231), {k = Y0131, s = Y0201})
    assertEqualKV(LetsPug:DecodeSaveInfo("s0131k01", X1231), {k = Y0201, s = Y0131})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02h03", X1231), {k = Y0101, s = Y0102, h = Y0103})

    --------------------
    -- Complements
    --------------------
    assertEqualKV(LetsPug:DecodeSaveInfo("M0101", X1231), {k = Y0101, g = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("G0101", X1231), {k = Y0101, m = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("q0101", X1231), {k = Y0101, g = Y0101, m = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("Z0101", X1231), {s = Y0101, t = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("T0101", X1231), {s = Y0101, z = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("w0101", X1231), {s = Y0101, t = Y0101, z = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("P0101", X1231), {h = Y0101, b = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("B0101", X1231), {h = Y0101, p = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("e0101", X1231), {h = Y0101, b = Y0101, p = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("E0101", X1231), {k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("W0101", X1231), {k = Y0101, g = Y0101, m = Y0101, h = Y0101, b = Y0101, p = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("Q0101", X1231), {s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101})

    assertEqualKV(LetsPug:DecodeSaveInfo("k0101S02h03", X1231), {k = Y0101, t = Y0102, z = Y0102, h = Y0103})
    assertEqualKV(LetsPug:DecodeSaveInfo("k0101s02H03", X1231), {k = Y0101, s = Y0102, b = Y0103, p = Y0103})

    --------------------
    -- All and no saves
    --------------------
    assertEqualKV(LetsPug:DecodeSaveInfo("a0101", X1231), {k = Y0101, g = Y0101, m = Y0101, s = Y0101, t = Y0101, z = Y0101, h = Y0101, b = Y0101, p = Y0101})
    assertEqualKV(LetsPug:DecodeSaveInfo("A1231", X1231), {})
end
