--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

function LetsRaid:RefreshSavedInstances()
    for i = 1, GetNumSavedInstances() do
        local name, id, ttl = GetSavedInstanceInfo(i)
        local expire_timestamp = time() + ttl
        local expire_readable = self:GetReadableDateFromTimestamp(expire_timestamp)
        self:RegisterSavedInstance(name, expire_readable)
    end
end

function LetsRaid:RegisterSavedInstance(name, expire_readable)
    local instance_key = self:GetInstanceKeyForMap(name)
    if instance_key then
        self.saves[instance_key] = expire_readable
    end
end

function LetsRaid:RegisterPlayerSaveInfo(player, save_info)
    self.db.realm.saves[player] = save_info

    local instances = self.db.realm.instances
    for instance_key, readable in pairs(self:DecodeSaveInfo(save_info)) do
        instances[instance_key][player] = readable
    end
end

function LetsRaid:GetPlayerSaveInfo(player)
    return self.db.realm.saves[player]
end

function LetsRaid:GetPlayerInstanceResetReadable(player, instance_key)
    local instance_info = assert(self.db.realm.instances[instance_key], "Wrong instance key")
    local reset_readable = instance_info[player]
    return reset_readable
end
