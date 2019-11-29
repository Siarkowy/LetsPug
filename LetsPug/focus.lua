--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

function LetsPug:GetPlayerInstanceFocus(player, instance_key)
    return self.db.profile.focused_instances[player][instance_key]
end

function LetsPug:SetPlayerInstanceFocus(player, instance_key, v)
    self.db.profile.focused_instances[player][instance_key] = v or nil

    if player == self.player then
        self:SendMessage("LETSPUG_PLAYER_FOCUS_UPDATE", self.player, save_info)
    end
end
