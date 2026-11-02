--!strict
-- Bakes the graybox village from git (src/server/World/Build.luau, synced by Rojo) into the open place, so the
-- world-builder can dress it and save it. Run with the MCP execute_luau tool in Edit context, Rojo connected.
-- WARNING: replaces Workspace.World completely; only run it on a place that has no art yet.
local ServerScriptService = game:GetService("ServerScriptService")
local build = require(ServerScriptService:WaitForChild("Server"):WaitForChild("World"):WaitForChild("Build")) :: any
build()
local base = workspace:FindFirstChild("Baseplate")
if base then
	base:Destroy()
end
return "graybox built into Workspace.World; save the place"
