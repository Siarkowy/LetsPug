--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local function wipe(t)
    for k, v in pairs(t) do
        if type(v) == "table" then wipe(v) end
        t[k] = nil
    end
end

LetsPug.wipe = wipe

function LetsPug:Printf(fmt, ...)
    self:Print(string.format(fmt, ...))
end

--- Returns input string in Pascal case (upper case first, lower case rest).
-- Appropriate for character names.
function LetsPug.StrToPascalCase(str)
    if not str or str == "" then return nil end
    str = str:sub(1, 1):upper() .. str:sub(2):lower()
    return str
end
