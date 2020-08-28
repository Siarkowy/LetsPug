--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local wipe = LetsPug.wipe

local decode_abbrevs = {
    A = "",

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
}

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
    local assertEqualKV = LetsPug.assertEqualKV

    local X1231 = 20181231
    local Y0101 = 20190101
    local Y0102 = 20190102
    local Y0103 = 20190103
    local Y0131 = 20190131
    local Y0201 = 20190201

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
