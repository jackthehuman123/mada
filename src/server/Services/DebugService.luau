--!strict
-- Studio-only debug commands for testing (AGENTS.md §5). Does nothing in live servers.
-- TODO(M1/M2): add TextChatCommand "/lv" with subcommands, and expose the same functions on
-- ServerStorage attribute-driven hooks so the agent can call them via execute_luau (Server context):
--   /lv phase <Phase>      jump to a phase
--   /lv time <hour>        set the clock, e.g. 23.9
--   /lv give letter        give the letter to the caller
--   /lv clue <ClueId|all>  mark clue(s) found
--   /lv take <name|me>     take a player   /lv rescue <name|me>
--   /lv goto <Location>    teleport the caller

local RunService = game:GetService("RunService")

local DebugService = {}

function DebugService.Init()
	if not RunService:IsStudio() then
		return
	end
end

function DebugService.Start()
	if not RunService:IsStudio() then
		return
	end
	print("[LangVong] debug commands enabled (Studio only)")
end

return DebugService
