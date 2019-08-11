--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local wipe = LetsPug.wipe

local function superror(message, suppress)
    if suppress then
        return DEFAULT_CHAT_FRAME:AddMessage(message .. " (suppressed)")
    else
        error(message, 3)
    end
end

local function assertEqual(actual, expected, suppress)
    if actual == expected then return end

    local error_msg = format("LetsPug: Unequal: %s vs. %s", tostring(actual), tostring(expected))
    return superror(error_msg, suppress)
end

local keys = {}
local actual_keys = {}
local expected_keys = {}
local function assertEqualKV(actual, expected, suppress)
    wipe(keys)
    wipe(actual_keys)
    wipe(expected_keys)

    for k in pairs(expected) do
        keys[k] = (keys[k] or 0) + 1
        table.insert(expected_keys, k)
    end
    for k in pairs(actual) do
        keys[k] = (keys[k] or 0) - 1
        table.insert(actual_keys, k)
    end

    for k, v in pairs(keys) do
        if v ~= 0 then
            local actual_str = table.concat(actual_keys, ", ")
            local expected_str = table.concat(expected_keys, ", ")
            return superror(format(
                "LetsPug: Different keys: %s vs. %s",
                actual_str ~= "" and actual_str or "(none)",
                expected_str ~= "" and expected_str or "(none)"),
            suppress)
        end
    end

    for k, v in pairs(expected) do
        if actual[k] ~= v then
            return superror(format("LetsPug: Different value: [%s] = %s vs. %s",
                k, tostring(actual[k]), tostring(v)), suppress)
        end
    end
end

local function assertError(callable, message_match, suppress)
    local ok, message = pcall(callable)
    if ok then
        return superror("LetsPug: Expected error not thrown", suppress)
    end
    if message_match and message then
        if not message:find(message_match, 1, true) and not message:match(message_match) then
            return superror(format("LetsPug: Error didn't match: %q !~ %q",
                message, message_match), suppress)
        end
    end
end

LetsPug.assertEqual = assertEqual
LetsPug.assertEqualKV = assertEqualKV
LetsPug.assertError = assertError

do
    assertEqualKV({}, {})
    assertEqualKV({a = 3}, {a = 3})
    assertError(function() assertEqualKV({a = 3}, {b = 3}) end, "Different keys: a vs. b")
    assertError(function() assertEqualKV({a = 3}, {}) end, "a vs. (none)")
    assertError(function() assertEqualKV({}, {b = 3}) end, "(none) vs. b")
    assertError(function() assertEqualKV({a = 3}, {a = 6}) end, "Different value: [a] = 3 vs. 6")
    assertEqualKV({a = 3, b = 6}, {a = 3, b = 6})
end
