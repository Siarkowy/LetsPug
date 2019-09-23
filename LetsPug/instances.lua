--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local locale = GetLocale()

-- /run for i=1,GetNumSavedInstances() do print(GetSavedInstanceInfo(i)) end
local instance_keys = locale == "enUS" and {
    ["Karazhan"] = "k",
    ["Gruul's Lair"] = "g",
    ["Magtheridon's Lair"] = "m",

    ["Coilfang: Serpentshrine Cavern"] = "s",
    ["Tempest Keep"] = "t",
    ["Zul'Aman"] = "z",

    ["The Battle for Mount Hyjal"] = "h",
    ["Black Temple"] = "b",
    ["The Sunwell"] = "p",
}
or {
}

function LetsPug:GetInstanceKey(name)
    return instance_keys[name]
end
