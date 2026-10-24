--!strict
-- One match per elevator party, each in its own map slot in this server.
-- Owns the match timeline (intro -> round -> results), slime contact,
-- escapes, puzzle solves and crown rewards. Clients read the match folder's
-- attributes in ReplicatedStorage.Matches and draw them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local SlimeCurve = require(Shared:WaitForChild("SlimeCurve"))
local Crowns = require(Shared:WaitForChild("Crowns"))
local IntroPath = require(Shared:WaitForChild("IntroPath"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local MapService = require(script.Parent.MapService)
local PuzzleService = require(script.Parent.PuzzleService)
local DataService = require(script.Parent.DataService)

type Entry = { status: "climbing" | "escaped" | "slimed", escapedAt: number? }
type Match = {
	id: string,
	slot: number,
	folder: Folder,
	map: MapService.Map,
	entries: { [Player]: Entry },
	puzzles: { PuzzleService.Puzzle },
	escaped: number,
	slimeStart: number,
	endsAt: number,
	slimeDuration: number,
	heldTotal: number, -- slime holds (freezes) that have ended
	holdStart: number?,
	holdUntil: number?,
	live: boolean,
}

local MatchService = {}

local notify = Remotes.get("Notify")
local matchesFolder = Instance.new("Folder")
matchesFolder.Name = "Matches"
matchesFolder.Parent = ReplicatedStorage

local matches: { [string]: Match } = {}
local slotsUsed: { [number]: boolean } = {}
local byPlayer: { [Player]: Match } = {}
local nextId = 0
local lobbyReturn: (player: Player) -> () = function(_player: Player) end

local function now(): number
	return workspace:GetServerTimeNow()
end

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?, character:FindFirstChildOfClass("Humanoid")
end

local function climbers(match: Match): { Player }
	local list = {}
	for player, entry in match.entries do
		if entry.status == "climbing" then
			table.insert(list, player)
		end
	end
	return list
end

local function slimeHeight(match: Match): number
	return SlimeCurve.height(
		SlimeCurve.clock(now(), match.heldTotal, match.holdStart, match.holdUntil),
		match.slimeStart,
		match.slimeDuration,
		match.map.bottomY - Config.Slime.BaseDepth,
		match.map.exitY + Config.Slime.TopMargin,
		Config.Slime.Exponent
	)
end

local function fireMatch(match: Match, kind: string, data: any)
	for player in match.entries do
		if player.Parent == Players then
			notify:FireClient(player, kind, data)
		end
	end
end

local function leaveMatch(player: Player)
	byPlayer[player] = nil
	player:SetAttribute("MatchId", nil)
end

-- Objective text for the HUD: the lowest tier whose puzzle is not solved.
local function refreshObjective(match: Match)
	for i, puzzle in match.puzzles do
		if not puzzle.solved() then
			local done, total = puzzle.progress()
			match.folder:SetAttribute("Tier", i)
			match.folder:SetAttribute("Objective", puzzle.label)
			match.folder:SetAttribute("ObjectiveDone", done)
			match.folder:SetAttribute("ObjectiveTotal", total)
			return
		end
	end
	match.folder:SetAttribute("Tier", #match.puzzles + 1)
	match.folder:SetAttribute("Objective", "Reach the exit!")
	match.folder:SetAttribute("ObjectiveDone", 0)
	match.folder:SetAttribute("ObjectiveTotal", 0)
end

function MatchService.isClimbing(player: Player): boolean
	local match = byPlayer[player]
	if not match or not match.live then
		return false
	end
	local entry = match.entries[player]
	return entry ~= nil and entry.status == "climbing" and match.folder:GetAttribute("State") == "Round"
end

function MatchService.inMatch(player: Player): boolean
	return byPlayer[player] ~= nil
end

function MatchService.setLobbyReturn(fn: (player: Player) -> ())
	lobbyReturn = fn
end

local function onEscape(match: Match, player: Player, entry: Entry)
	match.escaped += 1
	entry.status = "escaped"
	local seconds = math.max(0, now() - match.slimeStart)
	entry.escapedAt = seconds
	local earned = Crowns.forEscape(seconds, match.escaped)
	DataService.addCrowns(player, earned)
	local best = DataService.recordEscape(player, seconds, match.folder:GetAttribute("Map") :: string?)
	notify:FireClient(player, "Escaped", { crowns = earned, place = match.escaped, seconds = seconds, best = best })
	task.delay(1.5, function()
		if byPlayer[player] == match then
			leaveMatch(player)
			lobbyReturn(player)
		end
	end)
end

local function tickMatch(match: Match, dt: number)
	local slimeY = slimeHeight(match)
	for _, puzzle in match.puzzles do
		puzzle.update(dt)
	end
	refreshObjective(match)
	for player, entry in match.entries do
		if entry.status ~= "climbing" then
			continue
		end
		local root, humanoid = rootOf(player)
		if not root or not humanoid or humanoid.Health <= 0 then
			continue
		end
		if (root.Position - match.map.exitPosition).Magnitude <= Config.Shaft.ExitRadius + 2 then
			onEscape(match, player, entry)
			continue
		end
		local character = player.Character :: Model
		local shieldUntil = character:GetAttribute("ShieldUntil")
		local shielded = type(shieldUntil) == "number" and shieldUntil > now()
		if not shielded and SlimeCurve.isTouching(root.Position.Y - 2.5, slimeY, Config.Slime.ContactMargin) then
			humanoid:TakeDamage(Config.Slime.DamagePerSecond * dt)
		end
	end
end

local function finish(match: Match)
	match.live = false
	local results = {}
	for player, entry in match.entries do
		if entry.status == "climbing" then
			entry.status = "slimed"
		end
		table.insert(results, { name = player.DisplayName, status = entry.status, seconds = entry.escapedAt })
	end
	table.sort(results, function(a, b)
		return (a.seconds or math.huge) < (b.seconds or math.huge)
	end)
	match.folder:SetAttribute("State", "Results")
	match.folder:SetAttribute("EndsAt", now() + Config.Match.ResultsSeconds)
	fireMatch(match, "Results", { results = results })
	task.wait(Config.Match.ResultsSeconds)
	for player in match.entries do
		if byPlayer[player] == match then
			leaveMatch(player)
			if player.Parent == Players then
				lobbyReturn(player)
			end
		end
	end
	for _, puzzle in match.puzzles do
		puzzle.cleanup()
	end
	MapService.destroy(match.map)
	match.folder:Destroy()
	matches[match.id] = nil
	slotsUsed[match.slot] = nil
end

local function freeSlot(): number
	local slot = 1
	while slotsUsed[slot] do
		slot += 1
	end
	slotsUsed[slot] = true
	return slot
end

-- Starts a match for a party. Yields through the intro; call in task.spawn.
function MatchService.create(party: { Player }, mapId: string?)
	local members = {}
	for _, player in party do
		if player.Parent == Players and not byPlayer[player] then
			table.insert(members, player)
		end
	end
	if #members == 0 then
		return
	end
	nextId += 1
	local slot = freeSlot()
	local origin = Config.Match.FirstOrigin + Vector3.new((slot - 1) * Config.Match.Spacing, 0, 0)
	local seed = os.time() + nextId * 7919
	local map = MapService.buildShaft(origin, seed, mapId)
	local def = map.layout.map
	local folder = Instance.new("Folder")
	folder.Name = "Match_" .. nextId
	folder:SetAttribute("OriginX", origin.X)
	folder:SetAttribute("OriginY", origin.Y)
	folder:SetAttribute("OriginZ", origin.Z)
	folder:SetAttribute("ExitY", map.exitY)
	folder:SetAttribute("BottomY", map.bottomY)
	folder:SetAttribute("SlimeBaseY", map.bottomY - Config.Slime.BaseDepth)
	folder:SetAttribute("SlimeTopY", map.exitY + Config.Slime.TopMargin)
	folder:SetAttribute("State", "Intro")
	folder:SetAttribute("Sector", slot + 6)
	folder:SetAttribute("Map", def.id)
	folder:SetAttribute("MapName", def.name)
	folder:SetAttribute("Theme", def.theme)
	folder:SetAttribute("Difficulty", def.difficulty)
	folder:SetAttribute("Tiers", #map.layout.tiers)
	folder.Parent = matchesFolder

	local match: Match = {
		id = folder.Name,
		slot = slot,
		folder = folder,
		map = map,
		entries = {},
		puzzles = {},
		escaped = 0,
		slimeStart = math.huge,
		endsAt = math.huge,
		slimeDuration = 0,
		heldTotal = 0,
		holdStart = nil,
		holdUntil = nil,
		live = true,
	}
	matches[match.id] = match
	for i, player in members do
		match.entries[player] = { status = "climbing" }
		byPlayer[player] = match
		player:SetAttribute("MatchId", match.id)
		local root = rootOf(player)
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			local character = player.Character :: Model
			character:PivotTo(map.spawnPoints[(i - 1) % #map.spawnPoints + 1])
		end
	end
	for _, tier in map.tiers do
		local puzzle = PuzzleService.create(tier, {
			origin = origin,
			playerCount = #members,
			seed = seed,
			isClimber = function(player: Player): boolean
				return byPlayer[player] == match and MatchService.isClimbing(player)
			end,
			climbers = function(): { Player }
				return climbers(match)
			end,
			onSolved = function()
				MapService.openTier(tier)
				-- Reward: the slime freezes for a moment (and the match end moves with it).
				local hold = Config.Slime.SolveHoldSeconds
				match.heldTotal, match.holdStart, match.holdUntil =
					SlimeCurve.addHold(now(), hold, match.heldTotal, match.holdStart, match.holdUntil)
				match.endsAt += hold
				folder:SetAttribute("SlimeHeld", match.heldTotal)
				folder:SetAttribute("SlimeHoldStart", match.holdStart)
				folder:SetAttribute("SlimeHoldUntil", match.holdUntil)
				folder:SetAttribute("EndsAt", match.endsAt)
				for _, player in climbers(match) do
					DataService.addCrowns(player, Config.Crowns.TeamBonus)
				end
				fireMatch(match, "PuzzleSolved", {
					tier = tier.info.index,
					position = tier.landing.Position,
					crowns = Config.Crowns.TeamBonus,
					hold = hold,
				})
			end,
			onProgress = function(sound: string, position: Vector3)
				fireMatch(match, "PuzzleProgress", { sound = sound, position = position })
			end,
		})
		table.insert(match.puzzles, puzzle)
	end
	refreshObjective(match)

	-- Intro: every client plays the flyover, then the head start, then slime.
	local tierInfo: { IntroPath.TierInfo } = {}
	for i, puzzle in match.puzzles do
		local rel = puzzle.focus - origin
		tierInfo[i] = { title = puzzle.title, label = puzzle.label, focus = { x = rel.X, y = rel.Y, z = rel.Z } }
	end
	local intro = IntroPath.build(map.layout, tierInfo, string.upper(def.name))
	fireMatch(match, "MatchIntro", {
		origin = map.origin,
		shots = intro.shots,
		cuts = intro.cuts,
		captions = intro.captions,
		seconds = intro.seconds,
	})
	task.wait(intro.seconds)
	if not match.live then
		return
	end
	match.slimeStart = now() + Config.Match.HeadStartSeconds
	match.endsAt = now() + def.matchSeconds
	match.slimeDuration = match.endsAt - match.slimeStart
	folder:SetAttribute("SlimeStart", match.slimeStart)
	folder:SetAttribute("SlimeDuration", match.slimeDuration)
	folder:SetAttribute("SlimeHeld", 0)
	folder:SetAttribute("EndsAt", match.endsAt)
	folder:SetAttribute("State", "Round")

	while now() < match.endsAt and #climbers(match) > 0 do
		tickMatch(match, task.wait(Config.Slime.CheckInterval))
	end
	finish(match)
end

local function hookCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		local match = byPlayer[player]
		local entry = match and match.entries[player]
		if match and entry and entry.status == "climbing" then
			entry.status = "slimed"
			notify:FireClient(player, "Slimed", {})
			leaveMatch(player)
		end
	end)
end

function MatchService.start()
	Players.RespawnTime = Config.Match.RespawnSeconds
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			hookCharacter(player, character)
		end)
		if player.Character then
			hookCharacter(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local match = byPlayer[player]
		if match then
			match.entries[player] = nil
		end
		byPlayer[player] = nil
	end)
end

return MatchService
