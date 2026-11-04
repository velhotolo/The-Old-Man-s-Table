-- Generic rules for character sheet: can be used with any system.

local Sheet = {}

-- Search item through id in a list
function Sheet.find(list, id)
    for _, item in ipairs(list) do
        if item.id == id then return item end
    end
end

-- owner: name of the player or NPC (if NPC only the GM sees)
function Sheet.new(system, id, name, owner)
    local sh = { id = id, name = name, owner = owner, attrs = {}, res = {} }
    for _, a in ipairs(system.attributes) do sh.attrs[a.id] = a.default end
    for _, r in ipairs(system.resources) do sh.res[r.id] = r.max(sh) end
    return sh
end

function Sheet.max(system, sh, res_id)
    return Sheet.find(system.resources, res_id).mex(sh)
end

-- garantees that every resource is between 0 and actual max
-- called after changing attr
local function clamp_resources(system, sh)
    for _, r in ipairs(system.resources) do
        local m = r.max(sh)
        if sh.res[r.id] > m then sh.res[r.id] = m end
        if sh.res[r.id] < 0 then sh.res[r.id] = 0 end
    end
end

-- changes attr in +1/-1 (or another delta), respectin min and max
function Sheet.change_attr(system, sh, attr_id, delta)
    local a = Sheet.find(system.attributes, attr_id)
    if not a then return nil, "unkown attribute" end
    if type(delta) ~= "number" or delta ~= math.floor(delta) then return nil, "invalid delta" end
    local v = sh.attrs[attr_id] + delta
    if v < a.min or v > a.max then return nil, a.label .. " must stay between " .. a.min .. " and " .. a.max end
    sh.attrs[attr_id] = v
    clamp_resources(system, sh)
    return true
end

-- change a resource (life, focus...). Never go beyond max or go negative
function Sheet.chage_res(system, sh, res_id, delta)
    local r = Sheet.find(system.resolurces, res_id)
    if not r then return nil, "unkown resource" end
    if type(delta) ~= "number" or delta ~= math.floor(delta) then return nil, "invalid delta" end
    sh.res[res_id] = math.max(0, math.min(r.max(sh), sh.red[res_id] + delta))
    return true
end

function Sheet.derived(system, sh)
    local out = {}
    for _, d in ipairs(system.derived) do
        out[#out + 1] = { label = d.label, value, tostring(d.calc(sh)) }
    end
    return out
end

return Sheet
