--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 3-Clause "New" license (see LICENSE file).
--------------------------------------------------------------------------------

local LetsRaid = LetsRaid

local function getSlashInstanceFocus(spec_id, instance_key)
    return function(info)
        return LetsRaid:GetPlayerInstanceFocus(LetsRaid.player, spec_id, instance_key)
    end
end

local function setSlashInstanceFocus(spec_id, instance_key)
    return function(info, v)
        return LetsRaid:SetPlayerInstanceFocus(LetsRaid.player, spec_id, instance_key, v)
    end
end

local function getInstanceToggle(order, spec_id, inst_key)
    local inst_name = LetsRaid:GetInstanceNameForKey(inst_key)
    return {
        name = inst_name,
        desc = format("Focus %s", inst_name),
        type = "toggle",
        get = getSlashInstanceFocus(spec_id, inst_key),
        set = setSlashInstanceFocus(spec_id, inst_key),
        -- width = "half",
        order = order,
    }
end

local function getRoleLabel(file, name)
    return ("|TInterface\\AddOns\\LetsRaid\\media\\%s:32:32:0:0:64:64:10:54:10:54|t %s"):format(file, name)
end

local function getRoleToggle(order, spec_id, role_id, role_name)
    return {
        name = getRoleLabel(role_id:lower(), role_name),
        desc = format("Set Role for this talent tree: %s", role_name),
        type = "toggle",
        get = function(info)
            return LetsRaid:GetPlayerRole(LetsRaid.player, spec_id) == role_id
        end,
        set = function(info, v)
            LetsRaid:SetPlayerRole(LetsRaid.player, spec_id, v and role_id)
        end,
        order = order,
    }
end

local LETSRAID_SPEC_HINT = [[Select|cff00ff00 role & instances of interest|r for this talent specialization. Choose at most|cff00ff00 3 raids your gear level.|r

Respective specialization settings will be activated automatically|cff00ff00 after you respec talents.|r]]

local function getTalentSpecConfig(spec_id)
    return {
        hint1 = {
            name = "Hint",
            type = "header",
            cmdHidden = true,
            order = 200
        },
        hint2 = {
            name = LETSRAID_SPEC_HINT,
            type = "description",
            cmdHidden = true,
            order = 205,
        },

        role = {
            name = "Role",
            type = "header",
            cmdHidden = true,
            order = 10
        },
        tank   = getRoleToggle(11, spec_id, LetsRaid.RAID_ROLES.TANK, "Tank"),
        healer = getRoleToggle(12, spec_id, LetsRaid.RAID_ROLES.HEALER, "Healer"),
        dps    = getRoleToggle(13, spec_id, LetsRaid.RAID_ROLES.DAMAGER, "DPS"),

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

function LetsRaid:LETSRAID_TALENTS_AVAILABLE()
    self:UnregisterMessage("LETSRAID_TALENTS_AVAILABLE")

    self:Debug("LETSRAID_TALENTS_AVAILABLE")
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

--- Switches GUI to active talent spec configuration.
function LetsRaid:SwitchOptionsToActiveTalentSpec()
    local spec_name, _ = LetsRaid:GetActiveTalentSpec()
    if not spec_name then return end

    LibStub("AceConfigDialog-3.0"):SelectGroup(self.name, "spec", spec_name)
end

LetsRaid.slash.args.spec = {
    type = "group",
    name = "Spec",
    desc = "Configure Raid Specs",
    order = 2,
    childGroups = "tab",
    args = {} -- placeholder before LETSRAID_TALENTS_AVAILABLE is fired
}
