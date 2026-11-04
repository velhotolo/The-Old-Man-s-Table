-- Unbalanced test system

-- This file describe the system, the one who rolls stuff is shared/game.lua.

-- Counts how many dice from the list are >= the target
local function successes(list, target)
    local n = 0
    for _, v in ipairs(list) do
        if v >= target then n = n + 1 end
    end
    return n
end

-- Test action factory to avoid repeating code
local function attribute_test(attr_id, label)
    return {
        id = "test_" .. attr_id,
        label = label .. " teste",
        run = function(ch, ctx)
            local dice = ctx.pool(ch.attrs[attr_id], 6)
            local s = successes(dice, 5)
            return label .. " test: [" .. table.concat(dice, ",") .. "] = "
                .. s .. (s == 1 and " success" or " successes")
        end,
    }
end

local function defense(ch) return 3 + ch.attrs.body end

local function attack(id, label, focus_cost, bonus)
    return {
        id = id,
        label = label,
        needs_target = true,
        run = function(ch, ctx)
            local t = ctx.target
            if not t then return nil, "select a target first (Ctrl + click a token)" end
            if focus_cost > 0 then
                if ch.res.focus < focus_cost then return nil, "not enough focus" end
                ctx.change(ch, "focus", -focus_cost)
            end
            local hit, detail = ctx.roll("1d6+" .. ch.attrs.body)
            local text = label .. " on " .. t.name .. ": " .. detail .. " = " .. hit
                .. " vs defense " .. defense(t)
            if hit < defense(t) then return text .. ", miss" end
            local dmg, ddetail = ctx.roll(bonus > 0 and ("1d6+" .. bonus) or "1d6")
            ctx.change(t, "life", -dmg)
            return text .. ", hit! damage  " .. ddetail .. " = " .. dmg
        end,
    }
end
return {
    id
               = "traild6",
    name
               = "Traild6",
    version    = "2",
    attributes = {
        { id = "body", label = "Body", min = 1, max = 5, default = 2 },
        { id = "mind", label = "Mind", min = 1, max = 5, default = 2 },
        { id = "soul", label = "Soul", min = 1, max = 5, default = 2 },
    },
    resources  = {
        { id = "life",  label = "Life",  max = function(ch) return 8 + ch.attrs.body * 2 end },
        { id = "focus", label = "Focus", max = function(ch) return ch.attrs.mind + ch.attrs.soul end },
        },

    derived    = {
        {
            id = "defense",
            label = "Defense",
            calc = defense
        },
        { id = "initiative", label = "Initiative", calc = function(ch) return "1d6+" .. ch.attrs.mind end },
    },
    actions    = {
        attribute_test("body", "Body"),
        attribute_test("mind", "mind"),
        attribute_test("soul", "Soul"),
        {
            id = "initiative",
            label = "Initiative",
            run = function(ch, ctx)
                local total, detail = ctx.roll("1d6+" .. ch.attrs.mind)
                return "Initiative: " .. detail .. " = " .. total
            end,
        },
        attack("attack", "Attack", 0, 0),
        attack("power_attack", "Power attack", 1, 2),
    },
}

