--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local format = string.format
local gsub = string.gsub
local strsplit = string.split

LetsRaid.RAID_ROLES = {
    TANK = "TANK",
    HEALER = "HEALER",
    DAMAGER = "DAMAGER",
}

LetsRaid.RAID_ROLES_SHORT = {
    TANK = "T",
    HEALER = "H",
    DAMAGER = "D",

    T = "TANK",
    H = "HEALER",
    D = "DAMAGER",
}

LetsRaid.DEFAULT_ROLES = {
    HUNTER = "DAMAGER",
    MAGE = "DAMAGER",
    ROGUE = "DAMAGER",
    WARLOCK = "DAMAGER",

    PriestDiscipline = "HEALER",
    PriestHoly = "HEALER",
    PriestShadow = "DAMAGER",

    ShamanElementalCombat = "DAMAGER",
    ShamanEnhancement = "DAMAGER",
    ShamanRestoration = "HEALER",

    PaladinHoly = "HEALER",
    PaladinProtection = "TANK",
    PaladinCombat = "DAMAGER",

    DruidBalance = "DAMAGER",
    DruidFeralCombat = "TANK",
    DruidRestoration = "HEALER",

    WarriorArms = "DAMAGER",
    WarriorFury = "DAMAGER",
    WarriorProtection = "TANK",

    -- /run for t=1,3 do LetsRaid:Debug(LetsRaid:GetTalentSpecByTab(t)) end
}

function LetsRaid:IsSingleSpecClass(class_id)
    return not not self.DEFAULT_ROLES[class_id]
end

function LetsRaid:GetDefaultRoleForSpec(spec_id)
    return assert(self.DEFAULT_ROLES[spec_id], spec_id)
end

function LetsRaid:GetActiveTalentTabIndex()
    local tab = -1
    local pts = -1
    for current_tab = 1, GetNumTalentTabs(false) do
        local _, _, current_pts = GetTalentTabInfo(current_tab, false)
        if current_pts > pts then
            tab = current_tab
            pts = current_pts
        end
    end
    return tab, pts
end

function LetsRaid:GetTalentSpecByTab(tab)
    local spec_name, _, _, spec_id = GetTalentTabInfo(tab, false)
    local spec_name_short = select(1, string.split(" ", spec_name or ""))
    return spec_name_short, spec_id
end

function LetsRaid:GetActiveTalentSpec()
    local class_name, class_id = UnitClass("player")
    if self:IsSingleSpecClass(class_id) then
        return class_name, class_id
    else
        local idx = self:GetActiveTalentTabIndex()
        return self:GetTalentSpecByTab(idx)
    end
end

function LetsRaid:GetLastTalentSpecIdForPlayer(player)
    return self.db.profile.specs[player]
end

function LetsRaid:SetLastTalentSpecIdForPlayer(player, spec_id)
    self.db.profile.specs[player] = spec_id
end

function LetsRaid:GetPlayerInstanceFocusFromNote(player, instance_key, note)
    note = note or self:GetPlayerSaveInfo(player)
    return self:ExtractFocusInfoFromNote(note):find(instance_key) ~= nil
end

function LetsRaid:GetPlayerInstanceFocus(player, spec_id, instance_key, read_note)
    spec_id = spec_id or self:GetLastTalentSpecIdForPlayer(player)
    if not spec_id or read_note then
        return self:GetPlayerInstanceFocusFromNote(player, instance_key)
    end

    local spec_key = format("%s:%s", player, spec_id)
    local spec_data = self.db.profile.focus[spec_key]

    return spec_data[instance_key]
end

function LetsRaid:SetPlayerInstanceFocus(player, spec_id, instance_key, v)
    local spec_key = format("%s:%s", player, spec_id)
    self.db.profile.focus[spec_key][instance_key] = v or nil

    if player == self.player then
        self:SendMessage("LETSRAID_PLAYER_SPEC_UPDATE", self.player)
    end
end

--- Returns a string encoding of instance focus for current player's active spec.
function LetsRaid:GetPlayerFocusInfo()
    local _, spec_id = self:GetActiveTalentSpec()
    local spec_key = format("%s:%s", self.player, spec_id)
    local spec_data = rawget(self.db.profile.focus, spec_key)

    if not spec_data then return "" end
    local focus_info = self.supportedInstanceKeys:gsub("%a", function(key) return spec_data[key] and key or "" end)
    return focus_info:sub(1, 4)
end

function LetsRaid:GetPlayerRole(player, spec_id)
    local spec_key = format("%s:%s", player, spec_id)
    local spec_data = rawget(self.db.profile.focus, spec_key)

    return spec_data and spec_data.role
end

--- Assigns a raid role to player's spec.
-- A special value of `false` denotes a minor spec, which is intended for
-- gearing up/"some day in the future" scenarios. A hidden spec is only
-- advertised publicly if it is the active talent spec of the character.
function LetsRaid:SetPlayerRole(player, spec_id, role_id)
    assert(not role_id or self.RAID_ROLES[role_id])

    local spec_key = format("%s:%s", player, spec_id)
    self.db.profile.focus[spec_key].role = role_id

    if player == self.player then
        self:SendMessage("LETSRAID_PLAYER_SPEC_UPDATE", self.player)
    end
end

local role_info = {}
--- Returns a string encoding of available raid specs for the current character.
-- Possible raid roles are: T - tank, H - healer, D - DPS.
-- Main spec is in upper case, while off specs in lower case.
function LetsRaid:GetPlayerRoleInfo()
    self.wipe(role_info)

    -- main spec
    local player = self.player
    local _, active_spec_id = self:GetActiveTalentSpec()
    local role_id = self:GetPlayerRole(player, active_spec_id) or self:GetDefaultRoleForSpec(active_spec_id)
    local role_short = self.RAID_ROLES_SHORT[role_id]
    role_info[role_short:upper()] = true

    -- off specs
    for tab = 1, 3 do
        local _, spec_id = self:GetTalentSpecByTab(tab)
        role_id = self:GetPlayerRole(player, spec_id)
        role_short = self.RAID_ROLES_SHORT[role_id]

        if role_id and not role_info[role_short:upper()] then
            role_info[role_short:lower()] = true
        end
    end

    local result = gsub("THDthd", "%a", function(key) return role_info[key] and key or "" end)
    return result
end

function LetsRaid:ExtractFocusInfoFromNote(note)
    note = note or ""
    note = note:gsub("%.?(%a+)(%d?%d?)(%d%d)", "")
    note = select(-1, strsplit(":", note))
    return note:match("%a+") or ""
end

function LetsRaid:ExtractRoleInfoFromNote(note)
    note = note or ""
    return note:match("([THDthd]+)[^:]*:") or "D"
end

do
    local spec_data = {}
    function LetsRaid:DecodeSpecFromNote(note)
        self.wipe(spec_data)

        local focus_info = self:ExtractFocusInfoFromNote(note)
        for key in focus_info:gmatch("%a") do
            spec_data[key] = true
        end

        local role_info = self:ExtractRoleInfoFromNote(note)
        for key in role_info:gmatch("[THD]") do
            spec_data.role = spec_data.role or self.RAID_ROLES_SHORT[key]
        end

        return spec_data
    end
end

function LetsRaid:DecodePlayerSpecInfo(player)
    local note = self:GetPlayerSaveInfo(player)
    return self:DecodeSpecFromNote(note), note
end

do
    for _, role in pairs(LetsRaid.DEFAULT_ROLES) do assert(LetsRaid.RAID_ROLES[role], role) end

    local assertEqual = LetsRaid.assertEqual
    local assertEqualKV = LetsRaid.assertEqualKV

    assertEqual(LetsRaid:ExtractFocusInfoFromNote(), "")
    assertEqual(LetsRaid:ExtractFocusInfoFromNote(""), "")

    assertEqual(LetsRaid:ExtractFocusInfoFromNote("p"), "p")
    assertEqual(LetsRaid:ExtractFocusInfoFromNote("T:p"), "p")
    assertEqual(LetsRaid:ExtractFocusInfoFromNote("Td:p"), "p")
    assertEqual(LetsRaid:ExtractFocusInfoFromNote("TD:p"), "p")

    assertEqual(LetsRaid:ExtractFocusInfoFromNote("p.A1020h"), "ph")
    assertEqual(LetsRaid:ExtractFocusInfoFromNote("T:p.A1020h"), "ph")
    assertEqual(LetsRaid:ExtractFocusInfoFromNote("Td:p.A1020h"), "ph")
    assertEqual(LetsRaid:ExtractFocusInfoFromNote("Td.1020:p.A1020h"), "ph")

    assertEqual(LetsRaid:ExtractRoleInfoFromNote(), "D")
    assertEqual(LetsRaid:ExtractRoleInfoFromNote(""), "D")

    assertEqual(LetsRaid:ExtractRoleInfoFromNote("p"), "D")
    assertEqual(LetsRaid:ExtractRoleInfoFromNote("T:p"), "T")
    assertEqual(LetsRaid:ExtractRoleInfoFromNote("Td:p"), "Td")
    assertEqual(LetsRaid:ExtractRoleInfoFromNote("TD:p"), "TD")

    assertEqual(LetsRaid:ExtractRoleInfoFromNote("p.A1020h"), "D")
    assertEqual(LetsRaid:ExtractRoleInfoFromNote("T:p.A1020h"), "T")
    assertEqual(LetsRaid:ExtractRoleInfoFromNote("Td:p.A1020h"), "Td")
    assertEqual(LetsRaid:ExtractRoleInfoFromNote("Td.1020:p.A1020h"), "Td")

    local DAMAGER = LetsRaid.RAID_ROLES.DAMAGER
    local TANK = LetsRaid.RAID_ROLES.TANK

    assertEqualKV(LetsRaid:DecodeSpecFromNote(), { role = DAMAGER })
    assertEqualKV(LetsRaid:DecodeSpecFromNote(""), { role = DAMAGER })

    assertEqualKV(LetsRaid:DecodeSpecFromNote("p"), { role = DAMAGER, p = true })
    assertEqualKV(LetsRaid:DecodeSpecFromNote("T:p"), { role = TANK, p = true })
    assertEqualKV(LetsRaid:DecodeSpecFromNote("Td:p"), { role = TANK, p = true })
    assertEqualKV(LetsRaid:DecodeSpecFromNote("TD:p"), { role = TANK, p = true })

    assertEqualKV(LetsRaid:DecodeSpecFromNote("p.A1020h"), { role = DAMAGER, p = true, h = true })
    assertEqualKV(LetsRaid:DecodeSpecFromNote("T:p.A1020h"), { role = TANK, p = true, h = true })
    assertEqualKV(LetsRaid:DecodeSpecFromNote("Td:p.A1020h"), { role = TANK, p = true, h = true })
    assertEqualKV(LetsRaid:DecodeSpecFromNote("Td.1020:p.A1020h"), { role = TANK, p = true, h = true })
end
