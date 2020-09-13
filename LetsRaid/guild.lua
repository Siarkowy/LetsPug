--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local format = string.format

--------------------------------------------------------------------------------
-- Guild API wrappers
--------------------------------------------------------------------------------

--- Returns guild roster index for specified player name, nil if not found.
function LetsRaid:GetGuildRosterIndexByName(name)
    for i = 1, GetNumGuildMembers(true) do
        if GetGuildRosterInfo(i) == name then
            return i
        end
    end
end

--- Returns guild roster info for given player.
function LetsRaid:GetGuildRosterInfoByName(name)
    local idx = self:GetGuildRosterIndexByName(name)
    return GetGuildRosterInfo(idx or 0)
end

--- Returns public note for given player.
function LetsRaid:GetGuildRosterPublicNoteByName(name, _note)
    return _note or select(7, self:GetGuildRosterInfoByName(name))
end

--- Returns officer note for given player.
function LetsRaid:GetGuildRosterOfficerNoteByName(name, _note)
    return _note or select(8, self:GetGuildRosterInfoByName(name))
end

--- Sets public note for given player.
function LetsRaid:SetGuildRosterPublicNoteByName(name, note)
    if not self.HasPassed(8, "SetGuildRosterPublicNoteByName") then return end
    GuildRosterSetPublicNote(self:GetGuildRosterIndexByName(name), note)
end

--- Returns main name from QDKP-like note.
function LetsRaid:ExtractMainFromNote(note)
    return (note or ""):match("{([^}]+)}")
end

local alts = {}
--- Returns given player's alts as a `name = class` table.
-- Character is considered an alt if its officer note either
-- (1) equals the given player name or (2) contains a matching QDKP-style note.
function LetsRaid:FindPlayerAlts(player)
    self.wipe(alts)
    if not player or not IsInGuild() then return alts end

    local note = self:GetGuildRosterOfficerNoteByName(player) or ""
    local main = (self:ExtractMainFromNote(note) or player):lower()

    for i = 1, GetNumGuildMembers(true) do
        local name, _, _, _, _, _, note, onote, _, _, class = GetGuildRosterInfo(i)
        local _main = (self:ExtractMainFromNote(onote) or name):lower()

        if (_main == main or onote:trim():lower() == main) then
            alts[name] = class
        end
    end

    return alts
end

--------------------------------------------------------------------------------
-- Save info handling
--------------------------------------------------------------------------------

--- Extracts save info from player note.
function LetsRaid:ExtractNoteSaveInfo(note)
    return (note or ""):match("!(.+)")
end

--- Replaces existing save info in guild note with provided one.
function LetsRaid:CombineNoteSaveInfo(current_note, save_info)
    current_note = (current_note or ""):gsub("!.*", "")
    save_info = save_info or ""
    local excl = save_info ~= "" and "!" or ""
    return format("%s%s%s", current_note:sub(1, 31 - save_info:len() - 1), excl, save_info)
end

--- Checks player save info and updates guild note if needed.
function LetsRaid:CheckGuildRosterPublicNote()
    local current_note = self:GetGuildRosterPublicNoteByName(self.player)
    local note_info = self:ExtractNoteSaveInfo(current_note)
    local current_info = self:EncodePlayerInfo()

    if note_info ~= current_info and self:IsEditPublicNoteAvailable() then
        local new_note = self:CombineNoteSaveInfo(current_note, current_info)
        self:Debug("CheckGuildRosterPublicNote:", current_note, "->", new_note)
        self:SetGuildRosterPublicNoteByName(self.player, new_note)
    end
end

--- Synchronizes player save info from guild notes. Skips currently logged in player.
-- Triggers LETSRAID_GUILD_SAVEINFO_UPDATE(player, info) event on any change detected.
function LetsRaid:SyncFromGuildRosterPublicNotes()
    for i = 1, GetNumGuildMembers(true) do
        local player, _, _, _, _, _, note, _, _, _, class = GetGuildRosterInfo(i)
        local note_info = self:ExtractNoteSaveInfo(note)
        local current_info = self:GetPlayerSaveInfo(player)
        if note_info and note_info ~= current_info and player ~= self.player then
            self:RegisterPlayerSaveInfo(player, note_info)
            self:RegisterPlayerClass(player, class)

            self:SendMessage("LETSRAID_GUILD_SAVEINFO_UPDATE", player, note_info)
        end
    end
end

--- Returns true if specified player is able to edit public notes.
function LetsRaid:IsEditPublicNoteAvailable(player)
    local name, _, rank = self:GetGuildRosterInfoByName(player or self.player)
    if not name then return end

    GuildControlSetRank(rank + 1)
    return not not select(10, GuildControlGetRankFlags())
end

--- Returns true if reading info from player notes is currently enabled.
function LetsRaid:IsReadPlayerNotesEnabled()
    return self.db.profile.sync.read_notes
end

--- Toggles player note reading on/off.
function LetsRaid:SetReadPlayerNotesEnabled(enabled)
    enabled = not not enabled
    self.db.profile.sync.read_notes = enabled
end

--- Returns true if writing into to player notes is currently enabled.
function LetsRaid:IsWritePlayerNoteEnabled()
    return self.db.profile.sync.write_notes
end

--- Toggles player note writing on/off.
function LetsRaid:SetWritePlayerNoteEnabled(enabled)
    enabled = not not enabled
    self.db.profile.sync.write_notes = enabled
end

--------------------------------------------------------------------------------
-- Tests
--------------------------------------------------------------------------------

do
    local assertEqual = LetsRaid.assertEqual

    assertEqual(LetsRaid:ExtractNoteSaveInfo("abc!def!ghi"), "def!ghi")
    assertEqual(LetsRaid:ExtractNoteSaveInfo("abc!def"), "def")
    assertEqual(LetsRaid:ExtractNoteSaveInfo("abc!"), nil)
    assertEqual(LetsRaid:ExtractNoteSaveInfo("!def"), "def")
    assertEqual(LetsRaid:ExtractNoteSaveInfo("abc"), nil)
    assertEqual(LetsRaid:ExtractNoteSaveInfo(""), nil)
    assertEqual(LetsRaid:ExtractNoteSaveInfo(nil), nil)

    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!def!ghi", "A0101"), "abc!A0101")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!def", "A0101"), "abc!A0101")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!", "A0101"), "abc!A0101")
    assertEqual(LetsRaid:CombineNoteSaveInfo("!def", "A0101"), "!A0101")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc", "A0101"), "abc!A0101")
    assertEqual(LetsRaid:CombineNoteSaveInfo("", "A0101"), "!A0101")
    assertEqual(LetsRaid:CombineNoteSaveInfo(nil, "A0101"), "!A0101")

    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!def!ghi", ""), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!def", ""), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!", ""), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("!def", ""), "")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc", ""), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("", ""), "")
    assertEqual(LetsRaid:CombineNoteSaveInfo(nil, ""), "")

    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!def!ghi", nil), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!def", nil), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc!", nil), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("!def", nil), "")
    assertEqual(LetsRaid:CombineNoteSaveInfo("abc", nil), "abc")
    assertEqual(LetsRaid:CombineNoteSaveInfo("", nil), "")
    assertEqual(LetsRaid:CombineNoteSaveInfo(nil, nil), "")
end
