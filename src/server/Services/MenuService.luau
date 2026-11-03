--!strict
-- The menu and teams (docs/ISSUES.md I-09). Every server is one of three kinds (ReplicatedStorage attribute "ServerKind"):
--   Menu    a public live server: players see the menu and make teams of up to 4; Begin teleports a team to its own
--           reserved server of this same place, so nobody else can walk into their run
--   Run     a reserved server made by Begin: the team that arrives plays (GameStateService.BeginRun once all are in)
--   Studio  a Studio playtest: the menu, and Begin starts the run in this same server (Studio can't teleport)
-- Characters never load by themselves: only players in a run (player attribute "InRun") get one.
-- Teams are open (anyone in this server can join) or private (the leader's friends and invited players only).
-- Invites carry { inviter, team } as launch data; an invited friend who lands in another menu server follows the
-- inviter there. Players who arrive as a Roblox Party are put in one team (if Roblox lets us read PartyId).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Analytics = require(Shared:WaitForChild("Analytics"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Text = require(Shared:WaitForChild("Content"):WaitForChild("Text"))

export type ServerKind = "Menu" | "Run" | "Studio"

type Team = {
	id: string,
	leader: number,
	members: { number }, -- user ids, in the order they joined
	open: boolean,
	starting: boolean, -- teleporting (Menu) or playing (Studio)
	party: string?, -- the Roblox Party it was made for
	invited: { [number]: boolean },
}

local MenuService = {}

local kind: ServerKind = "Menu"
local teams: { [string]: Team } = {}
local teamOf: { [number]: string } = {}
local nextId = 0
local version = 0
local friendCache: { [string]: boolean } = {}

local function notice(p: Player, text: string)
	Remotes.event(Remotes.Names.MenuNotice):FireClient(p, text)
end

local function isFriend(p: Player, other: number): boolean
	if p.UserId == other then
		return true
	end
	local key = `{p.UserId}:{other}`
	if friendCache[key] == nil then
		local ok, res = pcall(p.IsFriendsWithAsync, p, other)
		friendCache[key] = ok and res == true
	end
	return friendCache[key]
end

local function canJoin(p: Player, team: Team): boolean
	return team.open or team.invited[p.UserId] == true or isFriend(p, team.leader)
end

-- what one player sees: every team in the server, with whether they may join it
local function stateFor(p: Player, v: number): { [string]: any }
	local list = {}
	for _, team in teams do
		local members = {}
		for _, id in team.members do
			local m = Players:GetPlayerByUserId(id)
			table.insert(members, { userId = id, name = if m then m.DisplayName else "?" })
		end
		table.insert(list, {
			id = team.id,
			leader = team.leader,
			members = members,
			open = team.open,
			starting = team.starting,
			canJoin = canJoin(p, team),
		})
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return { version = v, kind = kind, teams = list }
end

local function broadcast()
	version += 1
	local v = version
	for _, p in Players:GetPlayers() do
		task.spawn(function()
			Remotes.event(Remotes.Names.MenuState):FireClient(p, stateFor(p, v))
		end)
	end
end

local function leave(p: Player)
	local id = teamOf[p.UserId]
	if not id then
		return
	end
	teamOf[p.UserId] = nil
	local team = teams[id]
	if not team then
		return
	end
	local i = table.find(team.members, p.UserId)
	if i then
		table.remove(team.members, i)
	end
	if #team.members == 0 then
		teams[id] = nil
	elseif team.leader == p.UserId then
		team.leader = team.members[1]
	end
end

local function create(p: Player, open: boolean, party: string?): Team
	leave(p)
	nextId += 1
	local team: Team = {
		id = string.format("T%03d", nextId),
		leader = p.UserId,
		members = { p.UserId },
		open = open,
		starting = false,
		party = party,
		invited = {},
	}
	teams[team.id] = team
	teamOf[p.UserId] = team.id
	return team
end

local function join(p: Player, team: Team, force: boolean?): boolean
	if teamOf[p.UserId] == team.id then
		return true
	end
	if team.starting or #team.members >= Config.TeamMax or not (force or canJoin(p, team)) then
		return false
	end
	leave(p)
	table.insert(team.members, p.UserId)
	teamOf[p.UserId] = team.id
	return true
end

local function anyoneInRun(): boolean
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InRun") then
			return true
		end
	end
	return false
end

local function spawnIn(p: Player)
	p:SetAttribute("InRun", true)
	task.spawn(function()
		p:LoadCharacter()
	end)
end

-- Begin: the team goes to its run (its own reserved server live; this server in Studio)
local function begin(team: Team)
	if team.starting then
		return
	end
	local players = {}
	for _, id in team.members do
		local m = Players:GetPlayerByUserId(id)
		if m then
			table.insert(players, m)
		end
	end
	if #players == 0 then
		return
	end
	Analytics.track("team_begin", { size = #players, open = team.open })
	if kind == "Studio" then
		if anyoneInRun() then
			for _, m in players do
				notice(m, Text.Menu.busyStudio)
			end
			return
		end
		team.starting = true
		for _, m in players do
			spawnIn(m)
		end
		broadcast()
		local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
		GameState.BeginRun()
		return
	end
	team.starting = true
	broadcast()
	task.spawn(function()
		local ids = {}
		for _, m in players do
			table.insert(ids, m.UserId)
		end
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		options:SetTeleportData({ team = ids })
		for try = 1, Config.TeleportTries do
			-- (rebuilt every try: a member who left meanwhile made every retry fail)
			players = {}
			for _, id in team.members do
				local m = Players:GetPlayerByUserId(id)
				if m then
					table.insert(players, m)
				end
			end
			if #players == 0 then
				break
			end
			local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, players, options)
			if ok then
				return
			end
			warn(`[LangVong] team teleport failed ({try}/{Config.TeleportTries}): {err}`)
			task.wait(2 * try)
		end
		team.starting = false
		for _, m in players do
			notice(m, Text.Menu.teleportFailed)
		end
		broadcast()
	end)
end

local lastAction: { [Player]: number } = {}
local function onAction(p: Player, action: any, arg: any)
	-- a few clicks a second at most: every action re-sends the menu (and asks Roblox about friendships) to everyone
	if os.clock() - (lastAction[p] or 0) < 0.25 then
		return
	end
	lastAction[p] = os.clock()
	if action == "sync" then -- a client that just connected (the PlayerAdded broadcast can come before it listens)
		Remotes.event(Remotes.Names.MenuState):FireClient(p, stateFor(p, version))
		return
	end
	if action == "backToMenu" then
		if kind == "Run" then
			p:SetAttribute("InRun", false)
			local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, { p })
			if not ok then
				warn(`[LangVong] back to menu failed: {err}`)
				p:SetAttribute("InRun", true)
				notice(p, Text.Menu.teleportFailed)
			end
		end
		return
	end
	if p:GetAttribute("InRun") then
		return
	end
	local team = teams[teamOf[p.UserId] or ""]
	if action == "create" then
		create(p, arg == true)
	elseif action == "solo" then
		begin(create(p, false))
	elseif action == "join" then
		local target = if typeof(arg) == "string" then teams[arg] else nil
		if not (target and join(p, target)) then
			notice(p, Text.Menu.cantJoin)
		end
	elseif action == "leave" then
		leave(p)
	elseif action == "setOpen" then
		if team and team.leader == p.UserId and not team.starting then
			team.open = arg == true
		end
	elseif action == "begin" then
		if team and team.leader == p.UserId then
			begin(team)
		end
	else
		return
	end
	broadcast()
end

-- an invite's launch data ({ inviter, team }), or the same thing carried by a follow teleport
local function inviteOf(p: Player): { inviter: number, team: string? }?
	for _ = 1, Config.InviteDataTries do
		local ok, data = pcall(p.GetJoinData, p)
		if not ok or not p.Parent then
			return nil
		end
		local tp = (data :: any).TeleportData
		if typeof(tp) == "table" and typeof(tp.inviter) == "number" then
			return { inviter = tp.inviter, team = tp.inviteTeam }
		end
		local launch = (data :: any).LaunchData
		if typeof(launch) == "string" and launch ~= "" then
			local decoded = nil
			pcall(function()
				decoded = HttpService:JSONDecode(launch)
			end)
			local d = decoded :: any
			if typeof(d) == "table" and typeof(d.inviter) == "number" then
				return { inviter = d.inviter, team = if typeof(d.team) == "string" then d.team else nil }
			end
			return nil
		end
		task.wait(1)
	end
	return nil
end

-- a friend accepted an invite: put them in the inviter's team, or follow the inviter to their menu server
local function handleInvite(p: Player)
	local invite = inviteOf(p)
	if not invite or not p.Parent then
		return
	end
	local inviter = Players:GetPlayerByUserId(invite.inviter)
	if inviter then
		local team = teams[teamOf[invite.inviter] or ""]
		if team then
			team.invited[p.UserId] = true
			join(p, team, true)
			broadcast()
		end
		return
	end
	if kind ~= "Menu" then
		return
	end
	local ok, _, _, placeId, jobId = pcall(TeleportService.GetPlayerPlaceInstanceAsync, TeleportService, invite.inviter)
	if ok and placeId == game.PlaceId and typeof(jobId) == "string" and jobId ~= game.JobId then
		local options = Instance.new("TeleportOptions")
		options.ServerInstanceId = jobId
		options:SetTeleportData({ inviter = invite.inviter, inviteTeam = invite.team })
		local tok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, { p }, options)
		if not tok then
			warn(`[LangVong] following the inviter failed: {err}`)
			notice(p, Text.Menu.cantFollow) -- (their team is already in its own run: it can't be joined)
		end
	end
end

-- players who came in as a Roblox Party go in one (private) team
local function handleParty(p: Player)
	local ok, party = pcall(function()
		return (p :: any).PartyId
	end)
	if not ok or typeof(party) ~= "string" or party == "" or teamOf[p.UserId] then
		return
	end
	for _, team in teams do
		if team.party == party and join(p, team, true) then
			broadcast()
			return
		end
	end
	create(p, false, party)
	broadcast()
end

-- Run server: the team arrives; start once they're all here, or RunWaitForTeamSeconds after the first one
local expected: { number }? = nil
local firstArrival: number? = nil

local startedOnce = false
local function runArrival(p: Player)
	spawnIn(p)
	if not expected then
		local ok, data = pcall(p.GetJoinData, p)
		local tp = if ok then (data :: any).TeleportData else nil
		if typeof(tp) == "table" and typeof(tp.team) == "table" then
			expected = tp.team
			ReplicatedStorage:SetAttribute("TeamExpected", #tp.team)
		end
	end
	firstArrival = firstArrival or os.clock()
	-- everyone before them left and the run went back to Lobby: it starts again for whoever is here now
	local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
	if startedOnce and GameState.GetPhase() == "Lobby" then
		task.spawn(GameState.BeginRun)
	end
end

local function runReady(): boolean
	if not firstArrival then
		return false
	end
	if os.clock() - firstArrival >= Config.RunWaitForTeamSeconds then
		return true
	end
	local list: { number } = expected or {}
	for _, id in list do
		if not Players:GetPlayerByUserId(id) then
			return false
		end
	end
	return true
end

-- respawn after a fall or a reset that killed the character (players are never killed on purpose)
local function watchCharacter(p: Player)
	p.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
		if hum then
			hum.Died:Connect(function()
				task.wait(Config.RespawnSeconds)
				if p.Parent and p:GetAttribute("InRun") and p.Character == char then
					p:LoadCharacter()
				end
			end)
		end
	end)
end

local function onPlayerAdded(p: Player)
	watchCharacter(p)
	if kind == "Run" then
		runArrival(p)
		return
	end
	broadcast()
	task.spawn(handleParty, p)
	task.spawn(handleInvite, p)
end

function MenuService.Kind(): ServerKind
	return kind
end

-- after an ending on a team's own run server: everyone back to the menu (release council 11-03 B5). false = failed
function MenuService.SendAllBack(): boolean
	local players = Players:GetPlayers()
	if kind ~= "Run" or #players == 0 then
		return false
	end
	for _, p in players do
		p:SetAttribute("InRun", false)
	end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, players)
	if not ok then
		warn(`[LangVong] sending the team back to the menu failed: {err}`)
		for _, p in players do
			p:SetAttribute("InRun", true)
		end
	end
	return ok
end

-- Studio/debug: put a player straight into a solo run (the factory tests use this through DebugService "begin")
function MenuService.BeginSolo(p: Player)
	if p:GetAttribute("InRun") then
		return
	end
	if kind == "Run" then
		spawnIn(p)
		return
	end
	begin(create(p, false))
end

-- the run is over and everyone left it (Studio): the menu comes back for the next team
function MenuService.RunEnded()
	for id, team in teams do
		if team.starting and kind == "Studio" then
			for _, uid in team.members do
				teamOf[uid] = nil
			end
			teams[id] = nil
		end
	end
	broadcast()
end

function MenuService.Snapshot(): { [string]: any }
	local p = Players:GetPlayers()[1]
	return if p then stateFor(p, version) else { version = version, kind = kind, teams = {} }
end

function MenuService.Init()
	if RunService:IsStudio() then
		kind = "Studio"
	elseif game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		kind = "Run" -- reserved servers have no owner; a bought private server (owner ~= 0) gets the menu
	end
	ReplicatedStorage:SetAttribute("ServerKind", kind)
	Players.CharacterAutoLoads = false
	for _, name in { Remotes.Names.MenuState, Remotes.Names.MenuNotice } do
		Remotes.event(name)
	end
	Remotes.event(Remotes.Names.MenuAction).OnServerEvent:Connect(onAction)
	TeleportService.TeleportInitFailed:Connect(function(p: Player, result: Enum.TeleportResult, err: string)
		warn(`[LangVong] teleport failed for {p.Name}: {result.Name} {err}`)
		-- the team was left "starting" with no way on: free it and tell them (they can press Begin again)
		local team = teams[teamOf[p.UserId] or ""]
		if team and team.starting and kind ~= "Run" then
			team.starting = false
			for _, id in team.members do
				local m = Players:GetPlayerByUserId(id)
				if m then
					notice(m, Text.Menu.teleportFailed)
				end
			end
			broadcast()
		end
	end)
end

function MenuService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastAction[p] = nil
		leave(p)
		for key in friendCache do
			if key:sub(1, #tostring(p.UserId) + 1) == `{p.UserId}:` then
				friendCache[key] = nil
			end
		end
		broadcast()
	end)
	if kind == "Run" then
		local GameState = require(script.Parent:WaitForChild("GameStateService")) :: any
		while not runReady() do
			task.wait(0.5)
		end
		startedOnce = true
		GameState.BeginRun()
	end
end

return MenuService
