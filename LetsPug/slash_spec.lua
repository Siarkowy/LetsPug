--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local LetsPug = LetsPug

local function getSlashInstanceFocus(spec_id, instance_key)
    return function(info)
        return LetsPug:GetPlayerInstanceFocus(LetsPug.player, spec_id, instance_key)
    end
end

local function setSlashInstanceFocus(spec_id, instance_key)
    return function(info, v)
        return LetsPug:SetPlayerInstanceFocus(LetsPug.player, spec_id, instance_key, v)
    end
end

local function getInstanceToggle(order, spec_id, inst_key)
    local inst_name = LetsPug:GetInstanceNameForKey(inst_key)
    return {
        name = inst_name,
        type = "toggle",
        get = getSlashInstanceFocus(spec_id, inst_key),
        set = setSlashInstanceFocus(spec_id, inst_key),
        -- width = "half",
        order = order,
    }
end

local function getTalentSpecConfig(spec_id)
    return {
        tier4 = {
            name = "Tier 4",
            type = "header",
            cmdHidden = true,
            order = 40
        },
        kz = getInstanceToggle(41, spec_id, "k"),
        gl = getInstanceToggle(42, spec_id, "g"),
        ml = getInstanceToggle(43, spec_id, "m"),

        tier5 = {
            name = "Tier 5",
            type = "header",
            cmdHidden = true,
            order = 50
        },
        ssc = getInstanceToggle(51, spec_id, "s"),
        tk  = getInstanceToggle(52, spec_id, "t"),
        za  = getInstanceToggle(53, spec_id, "z"),

        tier6 = {
            name = "Tier 6",
            type = "header",
            cmdHidden = true,
            order = 60
        },
        mh  = getInstanceToggle(61, spec_id, "h"),
        bt  = getInstanceToggle(62, spec_id, "b"),
        swp = getInstanceToggle(63, spec_id, "p"),

        other = {
            name = "Other",
            type = "header",
            cmdHidden = true,
            order = 70
        },
        naxx = getInstanceToggle(71, spec_id, "n"),
        ony  = getInstanceToggle(72, spec_id, "o"),
    }
end

function LetsPug:LETSPUG_TALENTS_AVAILABLE()
    self:UnregisterMessage("LETSPUG_TALENTS_AVAILABLE")

    self:Debug("LETSPUG_TALENTS_AVAILABLE")
    local spec_tabs = {}

    local class_name, class_id = UnitClass("player")
    if self:IsSingleSpecClass(class_id) then
        local spec_tab = {
            name = class_name,
            desc = ("Configure %s Spec"):format(class_name),
            type = "group",
            guiInline = true,
            order = 1,
            args = getTalentSpecConfig(class_id),
        }
        spec_tabs[class_name] = spec_tab
    else
        for tab = 1, GetNumTalentTabs(false) do
            local spec_name, spec_id = self:GetTalentSpecByTab(tab)
            local spec_tab = {
                name = spec_name,
                desc = ("Configure %s Spec"):format(spec_name),
                type = "group",
                order = tab,
                args = getTalentSpecConfig(spec_id),
            }
            spec_tabs[spec_name] = spec_tab
        end
    end

    self.slash.args.spec.args = spec_tabs
end

LetsPug.slash.args.spec = {
    type = "group",
    name = "Spec",
    desc = "Configure Raid Specs",
    order = 2,
    childGroups = "tab",
    args = {} -- placeholder before LETSPUG_TALENTS_AVAILABLE is fired
}
