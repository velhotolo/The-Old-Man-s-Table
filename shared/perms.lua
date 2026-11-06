-- attempt limit through amount of time (5 wrong logins in 10 minutes)

local Limiter = {}
Limiter.__index = Limiter

-- max attempts every window seconds
function Limiter.new(max, window, clock)
    return setmetatable({ max = max, window = window, hits = {}, clock = clock or os.time }, Limiter)
end

-- take out from the list what's older than the window
local function prune(self, list, now)
    local keep = {}
    for _, t in ipairs(list) do
        if now - t < self.window then keep[#keep + 1] = t end
    end
    return keep
end

function Limiter:allowed(key)
    local list = self.hits[key] or {}
    list[#list + 1] = self.clock()
    self.hits[key] = list
end

-- timely clean up so the table won't grow forever
function Limiter:cleanup()
    local now = self.clock()
    for key, list in pairs(self.hits) do
        list = prune(self, list, now)
        self.hits[key] = (#list > 0) and list or nil
    end
end

return Limiter
