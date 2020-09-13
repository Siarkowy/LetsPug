--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local DAY = 24 * 60 * 60

function LetsRaid:CleanupSaveTable(saves, now)
    now = now and self:GetTimestampFromReadableDate(now) or time()
    local since = self:GetReadableDateFromTimestamp(now - 14 * DAY)

    for k, readable in pairs(saves) do
        if readable < since then
            saves[k] = nil
        end
    end
end

function LetsRaid:CleanupInstanceSaves(...)
    self:Debug("CleanupInstanceSaves", ...)

    if InCombatLockdown() then return end
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        self:CleanupSaveTable(self.db.realm.instances[key])
    end
end

local primes = {307, 331, 353, 359, 383}
function LetsRaid:ScheduleInstanceCleanup()
    local i = 0
    for inst_key, _ in pairs(self.db.realm.instances) do
        self:ScheduleRepeatingTimer(function() self:CleanupInstanceSaves(inst_key) end, primes[i + 1])
        i = (i + 1) % #primes
    end
end

do
    local assertEqualKV = LetsRaid.assertEqualKV

    local now = 20181224
    local saves = LetsRaid:DecodeSaveInfo("s0101h02", now)
    LetsRaid:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190101
    local saves = LetsRaid:DecodeSaveInfo("s0101h02", now)
    LetsRaid:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190108
    local saves = LetsRaid:DecodeSaveInfo("s0101h02", now)
    LetsRaid:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190115
    local saves = LetsRaid:DecodeSaveInfo("s0101h02", now)
    LetsRaid:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {s = 20190101, h = 20190102})

    local now = 20190116
    local saves = LetsRaid:DecodeSaveInfo("s0101h02", now)
    LetsRaid:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {h = 20190102})

    local now = 20190117
    local saves = LetsRaid:DecodeSaveInfo("s0101h02", now)
    LetsRaid:CleanupSaveTable(saves, now)
    assertEqualKV(saves, {})
end
