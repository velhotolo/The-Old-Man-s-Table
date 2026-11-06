-- accounts, passwords and sessions.
-- passwords: keeps just the HASH Argon2id (too slow to get it). If somebody steal omt.db, can't read the passwords
-- and it takes too long to guess.
-- session: after login the client receives a token and use it in every req. The sessions are just in memory: if the server restarts
-- everybody need to login again.

local argon2 = require("argon2")
local Util = require("shared.util")
local Random = require("server.random")

local Auth = {}
Auth.__index = Auth

local ARGON = {
    variant = argon2.variants.argon2_id,
    m_cost = 19456,
    t_cost = 2,
    parallelism = 1,
}

local MIN_PASSWORD, MAX_PASSWORD = 15, 128

function Auth.new(db, config)
    local self = setmetatable({ db = db, config = config, sessions = {} }, Auth)
    self.dummy_hash = assert(argon2.hash_encoded(Random.hex(16), Random.bytes(16), ARGON))
    return self
end

local function is_gm(config, name)
    for _, n in ipairs(config.GMS) do
        if n == name then return true end
    end
    return false
end

function Auth:register(name, password, invite)
    if invite ~= self.config.INVITE then return nil, "invalid invite code" end
    if not Util.valid_username(name) then return nil, "name must be 3-20 chars: a-z, 0-9, _" end
    if type(password) ~= "string" or #password < MIN_PASSWORD then
        return nil, "password must have at least " .. MIN_PASSWORD .. " characters "
    end
    if #password > MAX_PASSWORD then return nil, "password too long" end
    if not Util.valid_utf8(password) then return nil, "invalid characters in password" end
    if password == password:sub(1, 1):rep(#password) then return nil, "password is too simple" end
    if password:lower():find(name, 1, true) then return nil, "password must not contain your name" end
    local hash = assert(argon2.hash_encoded(password, Random.bytes(16), ARGON))
    if not self.db:create_user(name, hash) then return nil, "name already taken" end
    return true
end

function Auth:login(name, password)
    if type(name) ~= "string" or type(password) ~= "string" or #password > MAX_PASSWORD then
        return nil, "wrong name or password"
    end
    local hash = Util.valid_username(name) and self.db:user_hash(name)
    local ok = argon2.verify(hash or self.dummy_hash, password)
    if not (hash and ok) then return nil, "wrong name or password" end
    local token = Random.hex(32)
    local user = { name = name, gm = is_gm(self.config, name) }
    self.sessions[token] = { user = user, expires = os.time() + self.config.SESSION_TTL }
    return token, user
end

function Auth:check(headers)
    local h = headers["authorization"]
    local token = type(h) == "string" and h:match("^Bearer (%x+)$")
    local s = token and self.sessions[token]
    if not s then return nil end
    if s.expires < os.time() then
        self.sessions[token] = nil; return nil
    end
    s.expires = os.time() + self.config.SESSION_TTL
    return s.user, token
end

function Auth:logout(token)
    self.sessions[token] = nil
end

function Auth:cleanup()
    local now = os.time()
    for token, s in pairs(self.sessions) do
        if s.expires < now then self.sessions[token] = nil end
    end
end

return Auth
