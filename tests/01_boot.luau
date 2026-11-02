-- M0: the server and client boot from git, the world is built, both say they started (brief §11 M0)
--@ Server
local logs = {}
for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
local all = table.concat(logs, "\n")
check(all:find("[LangVong] server started", 1, true), "no 'server started' line")
eq(workspace:GetAttribute("WorldBuilt"), "LangVong", "world")
check(dbg("get").phase ~= nil, "no phase")
return "server started, world built, phase " .. dbg("get").phase
--@ Client
local logs = {}
for _, m in game:GetService("LogService"):GetLogHistory() do table.insert(logs, m.message) end
check(table.concat(logs, "\n"):find("[LangVong] client started", 1, true), "no 'client started' line")
check(gui, "no LangVongUI")
return "client started, UI built"
