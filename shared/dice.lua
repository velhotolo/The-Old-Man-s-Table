-- reads and rolls expressions such as "2d6+1", "3d8", etc. In the future I'll render 3D dice animation to the thrown.
-- there's a function to be called on each version (test, offline and online)
local Dice = {
    random = math.random,
    MAX_DICE = 100,
    MAX_FACES = 1000,
    MAX_CONST = 1000,
}

-- transforms a text in a "terms" list. For example:
-- { sign = 1, n = 2, faces = 6 } -> +2d6
-- { sign = -1, const = 2 } -> -2
-- this is essentially what makes the dice rolling work
function Dice.parse(expr)
    if type(expr) ~= "string" then return nil, "invalid expression" end
    -- empty areas accepted only around + and -
    -- erasing all empty areas would make "2d6 3" a "d63"
    s = expr:lower():gsub("%s*([+-])%s*", "%1"):match("^%s*(.-)%s*$")
    if s == "" or #s > 40 then return nil, "empty or too long expression" end
    if s:find("%s") then return nil, "unexpected space" end


    local terms, pos, dice_count = {}, 1, 0
    while pos <= #s do
        local sg, after_sign = s:match("^([+-]?)()", pos)
        if sg == "" and #terms > 0 then return nil, "missing + or - between terms" end
        pos = after_sign
        local sign = (sg == "-") and -1 or 1

        local n, faces, after_die = s:match("^(%d*)d(%d+)()", pos)
        if faces then
            n = (n == "") and 1 or tonumber(n)
            faces = tonumber(faces)
            if n < 1 then return nil, "need at least 1 die" end
            if faces < 2 or faces > Dice.MAX_FACES then return nil, "faces must be 2 to " .. Dice.MAX_FACES end
            dice_count = dice_count + n
            if dice_count > Dice.MAX_DICE then return nil, "too many dice (max " .. Dice.MAX_DICE .. ")" end
            terms[#terms + 1] = { sign = sign, n = n, faces = faces }
            pos = after_die
        else
            local k, after_num = s:match("^(%d+)()", pos)
            if not k then return nil, "invalid term near '" .. s:sub(pos, pos + 4) .. "'" end
            k = tonumber(k)
            if k > Dice.MAX_CONST then return nil, "number too big" end
            terms[#terms + 1] = { sign = sign, const = k }
            pos = after_num
        end
    end
    return terms
end

-- rolls the expression. Returns total with a text
-- Dice.roll("2d6+1") -> 9, "[3,5]+1"
function Dice.roll(expr)
    local terms, err = Dice.parse(expr)
    if not terms then return nil, err end
    local total, parts = 0, {}
    for i, t in ipairs(terms) do
        local piece
        if t.const then
            total = total + t.sign * t.const
            piece = tostring(t.const)
        else
            local faces = {}
            for _ = 1, t.n do
                local v = Dice.random(1, t.faces)
                faces[#faces + 1] = v
                total = total + t.sign * v
            end
            piece = "[" .. table.concat(faces, ",") .. "]"
        end
        if i > 1 or t.sign < 0 then piece = (t.sign < 0 and "-" or "+") .. piece end
        parts[#parts + 1] = piece
    end
    return total, table.concat(parts)
end

-- for dice pools: rolls n dice and returns list
function Dice.pool(n, faces)
    local list = {}
    for _ = 1, math.max(0, math.min(n, Dice.MAX_DICE)) do
        list[#list + 1] = Dice.random(1, faces)
    end
    return list
end

return Dice
