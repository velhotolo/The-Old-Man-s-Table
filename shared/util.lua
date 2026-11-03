-- small functions used by the server, the client and the tests.
-- it doesn't depend on LÖVE: runs on LuaJIT.

local Util = {}

-- deep copy: creates a new table with same content.
-- the idea is to alter a character sheet without changing the original too early.
function Util.copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = Util.copy(v) end
    return out
end

-- Checks if the string is at UTF-8 and it's valid.
-- UTF-8 uses from up to 4 bytes per caracter.
function Util.valid_utf8(s)
    local i, n = 1, #s
    while i <= n do
        local c = s:byte(i)
        local extra
        if c < 0x80 then
            extra = 0
        elseif c >= 0xC2 and c <= 0xDF then
            extra = 1
        elseif c >= 0xE0 and c <= 0xEF then
            extra = 2
        elseif c >= 0xF0 and c <= 0xF4 then
            extra = 3
        else
            return false
        end
        for j = i + 1, i + extra do
            local cc = s:byte(j)
            if not cc or cc < 0x80 or cc > 0xBF then return false end
        end
        i = i + extra + 1
    end
    return true
end

-- Clean up a text from outside (keyboard, file, etc)
-- Returns clean text or nil + error message
function Util.clean_text(s, max_bytes)
    if type(s) ~= "string" then return nil, "text expected" end
    s = s:match("^%s*(.-)%s*$")
    if s == "" then return nil, "empty text" end
    if #s > max_bytes then return nil, "text too long (max " .. max_bytes .. " bytes)" end
    if s:find("[%z\1-\31\127]") then return nil, "control characters are not allowed" end
    return s
end

-- removes the last caracter (note: not the last byte) of a UTF-8 string.
-- used by the Backspace of the textfields.
function Util.drop_last_char(s)
    local i = #s
    -- walks backwards when it's a continuation caracter (10xxxxxx)
    while i > 0 do
        local c = s:byte(i)
        if c < 0x80 or c >= 0xC0 then break end
        i = i - 1
    end
    return s:sub(1, i - 1)
end

-- usernames: 3 to 20 caracters, a-z, 0-9 and _.
-- this avoids issues between "Bosano" and "bosano" e garantees that nobody is called @gm (internally used by the app)
function Util.valid_username(name)
    return type(name) == "string" and #name >= 3 and #name <= 20
        and name:match("^[a-z0-9_]+$") ~= nil
end

return Util
