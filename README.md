# Old Man's Table

A small virtual tabletop (VTT) for tabletop RPGs, written in Lua with [LÖVE](https://love2d.org/) 11.5.

> **Status:** work in progress. This is a learning project, built step by step.

## Features

- Grid map with tokens, camera drag and zoom.
- Floating windows: one per character sheet, plus chat, character list and help.
- Dice roller with expressions like `2d6+1`, `d20` and `1d8+1d4-2`.
- **Online build:** accounts, login and chat for a group of friends. The server decides every action; players only receive their own sheets, the GM receives all of them.
- **Offline build:** the same table with no network code at all, for anyone to download and try.
- Ships with *Trilha d6*, a tiny example rules system invented for this project (not a published game, not balanced).

## Project layout

```
main.lua, conf.lua     LÖVE entry point (only forwards events to the app)
shared/                rules used by the server AND the client (no LÖVE here)
  game.lua             commands -> events -> state
  perms.lua            who can see and change what
  dice.lua             dice expressions
  sheet.lua            generic character sheet rules
  util.lua             text, UTF-8 and copy helpers
  rules/trilha_d6.lua  the example rules system
lib/dkjson.lua         JSON library (vendored)
client/                LÖVE code: scenes, windows, map, backends
server/                LuaJIT + Pegasus + SQLite + Argon2id
tests/                 unit, integration and in-LÖVE tests
build.sh               builds both versions into dist/
```

## Requirements

- **Client:** LÖVE 11.5.
- **Server (online build only):** LuaJIT 2.1 and these Lua modules: `pegasus`, `lsqlite3`, `argon2` (lua-argon2) and `luasocket`.

With LuaRocks, the modules can be installed for LuaJIT (Lua 5.1) like this:

```
luarocks --lua-version=5.1 --local install pegasus
luarocks --lua-version=5.1 --local install lsqlite3
luarocks --lua-version=5.1 --local install argon2
luarocks --lua-version=5.1 --local install luasocket
eval "$(luarocks --lua-version=5.1 path)"
```

## Running

All commands run from the project root.

**Offline:** set `ONLINE = false` in `client/build.lua`, then:

```
love .
```

**Online:** set `ONLINE = true` in `client/build.lua`, then start the server:

```
cp server/config.example.lua server/config.lua   # edit INVITE, GMS and HOST
luajit server/main.lua
```

and open the client with `love .`. Create an account with the invite code, then log in. Names listed in `GMS` log in as game masters.

## Playing with friends

The server is meant to be reachable only inside a [Tailscale](https://tailscale.com/) network:

1. Set `HOST` in `server/config.lua` to this machine's Tailscale IP (`tailscale ip -4`).
2. Share the machine with your friends from the Tailscale admin console.
3. Give them the online build and, privately, the invite code.

Plain HTTP is used inside the tailnet, which Tailscale already encrypts. Do not expose the server port to the internet.

## Rules systems

A rules system is a Lua file in `shared/rules/` that describes attributes, resources, derived values and actions. The character sheet window builds itself from that description, so a new system needs no interface code.

Only *Trilha d6* is included in this repository. Systems based on commercial games can't be implemented.

## Building

```
./build.sh                                   # dist/omt-online.love and dist/omt-offline.love
./build.sh --win path/to/love-11.5-win64     # + Windows .zip with .exe
./build.sh --linux path/to/squashfs-root     # + Linux .tar.gz (extracted LÖVE AppImage)
```

The script checks that the offline build contains no network code.

## Tests

```
luajit tests/test_core.lua      # rules, dice, permissions
luajit tests/test_server.lua    # real server over HTTP
tests/run_all.sh path/to/love   # everything, including scripted runs inside LÖVE (needs xvfb-run)
```
## License

Not chosen yet.
