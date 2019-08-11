--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local DAY = 24 * 60 * 60

function LetsPug:CleanupSaveTable(saves, now)
    now = now and self:GetTimestampFromReadableDate(now) or self:GetServerNow()
    local since = self:GetReadableDateFromTimestamp(now - 14 * DAY)

    for k, readable in pairs(saves) do
        if readable < since then
            saves[k] = nil
        end
    end
end

function LetsPug:CleanupInstanceSaves(...)
    if self.debug then
        self:Print("CleanupInstanceSaves", ...)
    end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        self:CleanupSaveTable(self.db.realm.instances[key])
    end
end

do
    local assertEqualKV = LetsPug.assertEqualKV

    local now = 20181224
    local saves = LetsPug:DecodeSaveInfo("s0101h02", now)
    LetsPug:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190101
    local saves = LetsPug:DecodeSaveInfo("s0101h02", now)
    LetsPug:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190108
    local saves = LetsPug:DecodeSaveInfo("s0101h02", now)
    LetsPug:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190115
    local saves = LetsPug:DecodeSaveInfo("s0101h02", now)
    LetsPug:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190116
    local saves = LetsPug:DecodeSaveInfo("s0101h02", now)
    LetsPug:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {h = 20190102})

    local now = 20190117
    local saves = LetsPug:DecodeSaveInfo("s0101h02", now)
    LetsPug:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {})
end
