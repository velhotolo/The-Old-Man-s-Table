-- Generic rules for character sheet: can be used with any system.

local Sheet = {}

-- Search item through id in a list
function Sheet.find(list, id)
    for _, item in ipairs(list) do
        if item.id == id then return item end
    end
end

-- TODO A LOT OF STUFF!!
