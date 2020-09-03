--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local locale = GetLocale()

-- /run for i=1,GetNumSavedInstances() do print(GetSavedInstanceInfo(i)) end
local instance_keys = locale == "enUS" and {
    -- ["Reserved"] = "x",

    -- Tier 4
    ["Karazhan"] = "k",
    ["Gruul's Lair"] = "g",
    ["Magtheridon's Lair"] = "m",

    -- Tier 5
    ["Coilfang: Serpentshrine Cavern"] = "s",
    ["Tempest Keep"] = "t",
    ["Zul'Aman"] = "z",

    -- Tier 6
    ["The Battle for Mount Hyjal"] = "h",
    ["Black Temple"] = "b",
    ["The Sunwell"] = "p",

    -- Vanilla
    ["Naxxramas"] = "n",
    ["Onyxia's Lair"] = "o",
}
or {
}

function LetsPug:GetInstanceKeyForMap(name)
    return instance_keys[name]
end
