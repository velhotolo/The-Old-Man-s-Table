-- tables:
-- users (name, hash, created) -> accounts
-- events (id, json)            -> everything that happened on the table, in order

local sqlite3 = require("sqlite3")
local json = require("lib.dkjson")

local Db = {}
Db.__index = Db

local SCHEMA = [[
PRAGMA journal_mode = WAL;
CREATE TABLE IF NOT EXISTS users (
name TEXT PRIMARY KEY,
hash TEXT NOT NULL,
created INTEGER NOT NULL );
CREATE TABLE IF NOT EXISTS events (
id INTEGER PRIMARY KEY,
json TEXT NOT NULL ); ]]

function Db.open(path)
    local conn, _, msg = sqlite3.open(path)
    if not conn then return nil, msg end
    if conn:exec(SCHEMA) ~= sqlite3.OK then return nil, conn:errmsg() end
    return setmetatable({ conn = conn }, Db)
end

local function run(self, sql, ...)
    local stmt = assert(self.conn:prepare(sql), self.conn:errmsg())
    stmt:bind_values(...)
    local rc = stmt:step()
    stmt:finalize()
    return rc == sqlite3.DONE or rc == sqlite3.ROW, rc
end

function Db:create_user(name, hash)
    local ok = run(self, "INSERT INTO users (name, hash, created) VALUES (?, ?, ?)", name, hash, os.time())
    return ok
end

function Db:user_hash(name)
    local stmt = self.conn:prepare("SELECT hash FROM users WHERE name = ?")
    stmt:bind_values(name)
    local hash
    for row in stmt:nrows() do hash = row.hash end
    stmt:finalize()
    return hash
end

function Db:append_event(ev)
    assert(run(self, "INSERT INTO events (id, json) VALUES (?, ?)", ev.id, json.encode(ev)))
end

function Db:each_event(fn)
    for row in self.conn:nrows("SELECT json FROM events ORDER BY id") do
        fn(json.decode(row.json))
    end
end

function Db:transaction(fn)
    self.conn:exec("BEGIN")
    local ok, err = pcall(fn)
    self.conn:exec(ok and "COMMIT" or "ROLLBACK")
    if not ok then error(err, 0) end
end

return Db
