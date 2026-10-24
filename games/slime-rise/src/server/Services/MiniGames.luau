--!strict
-- Station mini-games: Pipe Repair (rotate tiles until slime reaches every
-- pipe), Wire Fix (connect matching colour + symbol), Memory Lights (repeat
-- the sequence, 3 rounds). The server builds each puzzle from a seed, keeps
-- the answer and checks every move; the client only draws and sends moves.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Validate = require(Shared:WaitForChild("Validate"))
local PuzzleGen = require(Shared:WaitForChild("PuzzleGen"))
local RemoteGuard = require(script.Parent.RemoteGuard)
local Room = require(script.Parent.Room)
local LabKit = require(script.Parent.LabKit)

local MiniGames = {}

type Station = {
	id: string,
	kind: string,
	part: BasePart,
	screen: TextLabel,
	solver: Player?,
	solved: boolean,
	pipes: PuzzleGen.Pipes?,
	wires: PuzzleGen.Wires?,
	memoryRound: number,
	memorySeq: { number },
	memoryProgress: number,
	seed: number,
	isClimber: (Player) -> boolean,
	onStationSolved: () -> (),
	onProgress: (sound: string, position: Vector3) -> (),
}

export type Context = {
	origin: Vector3,
	playerCount: number,
	seed: number,
	isClimber: (player: Player) -> boolean,
	onSolved: () -> (),
	onProgress: (sound: string, position: Vector3) -> (),
}

local LABELS = {
	Pipes = { title = "PIPE REPAIR", prompt = "Fix pipes", task = "Repair the slime pipes" },
	Wires = { title = "WIRE FIX", prompt = "Fix wires", task = "Reconnect the power wires" },
	Memory = { title = "MEMORY LIGHTS", prompt = "Unlock door", task = "Crack the door code" },
}
local REACH = 14

local notify = Remotes.get("Notify")
local stations: { [string]: Station } = {}
local nextId = 0

local function pipesSize(players: number): (number, number)
	return if players >= 4 then 5 else 4, 4
end

local function wireCount(players: number): number
	return if players >= 4 then 5 else 4
end

local function sendOpen(station: Station, player: Player)
	local data: { [string]: any } = { id = station.id, kind = station.kind, title = LABELS[station.kind].title }
	if station.pipes then
		local p = station.pipes
		data.width, data.height, data.source = p.width, p.height, p.source
		local shown = {}
		for i = 1, p.width * p.height do
			shown[i] = PuzzleGen.shownMask(p, i)
		end
		data.masks = shown
	elseif station.wires then
		data.left, data.right = station.wires.left, station.wires.right
	else
		data.sequence = station.memorySeq
		data.round = station.memoryRound
	end
	notify:FireClient(player, "MiniGameOpen", data)
end

local function newMemoryRound(station: Station)
	station.memorySeq = PuzzleGen.memory(station.seed + station.memoryRound * 101, 2 + station.memoryRound, 4)
	station.memoryProgress = 0
end

local function setScreen(station: Station)
	if station.solved then
		station.screen.Text = "ONLINE"
		station.screen.TextColor3 = Config.Colors.Slime
	else
		station.screen.Text = LABELS[station.kind].title
		station.screen.TextColor3 = Color3.fromRGB(255, 120, 120)
	end
end

local function finishStation(station: Station, player: Player)
	station.solved = true
	station.solver = nil
	setScreen(station)
	notify:FireClient(player, "MiniGameDone", { id = station.id })
	station.onProgress("Solve", station.part.Position)
	station.onStationSolved()
end

local function near(player: Player, station: Station): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - station.part.Position).Magnitude <= REACH
end

local function buildStation(parent: Instance, cf: CFrame, kind: string): (BasePart, TextLabel)
	-- A console with a screen; the generated console mesh when available.
	local base = LabKit.part(
		{ Size = Vector3.new(5, 3.6, 3), CFrame = cf * CFrame.new(0, 1.8, 0), Kit = "SR_Steel", Transparency = 1 },
		parent
	)
	if not LabKit.prop("Console", cf, 4.4, parent, true) then
		base.Transparency = 0
	end
	local screenPart = LabKit.deco({
		Size = Vector3.new(4.2, 2.2, 0.2),
		CFrame = cf * CFrame.new(0, 5.6, 0.6) * CFrame.Angles(math.rad(-12), 0, 0),
		Color = Color3.fromRGB(14, 18, 26),
		Material = Enum.Material.SmoothPlastic,
	}, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = screenPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.92, 0.7)
	label.Position = UDim2.fromScale(0.04, 0.15)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = Font.fromName("FredokaOne")
	label.Text = LABELS[kind].title
	label.Parent = gui
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = LABELS[kind].prompt
	prompt.ObjectText = LABELS[kind].title
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	return base, label
end

-- Creates one mini-game puzzle (1-3 stations by party size) on a tier.
function MiniGames.create(kind: string, tier: any, ctx: Context): any
	local folder = Instance.new("Folder")
	folder.Name = kind
	folder.Parent = tier.folder
	local count = math.min(1 + (math.max(1, ctx.playerCount) - 1) // 3, 3)
	local solvedCount = 0
	local list: { Station } = {}
	local info = tier.info
	for i = 1, count do
		nextId += 1
		-- Consoles stand in the free arc between the landing and the route start.
		local angle = info.hatchAngle + 38 + (i - 1) * 34
		Room.use(info.footprint)
		local cf = Room.ring(ctx.origin, angle, Config.Shaft.Radius - 4, info.floorY)
		local part, screen = buildStation(folder, cf, kind)
		local station: Station = {
			id = "MG" .. nextId,
			kind = kind,
			part = part,
			screen = screen,
			solver = nil,
			solved = false,
			pipes = nil,
			wires = nil,
			memoryRound = 1,
			memorySeq = {},
			memoryProgress = 0,
			seed = ctx.seed + nextId * 977,
			isClimber = ctx.isClimber,
			onStationSolved = function()
				solvedCount += 1
				if solvedCount >= count then
					ctx.onSolved()
				end
			end,
			onProgress = ctx.onProgress,
		}
		if kind == "Pipes" then
			local w, h = pipesSize(ctx.playerCount)
			station.pipes = PuzzleGen.pipes(station.seed, w, h)
		elseif kind == "Wires" then
			station.wires = PuzzleGen.wires(station.seed, wireCount(ctx.playerCount))
		else
			newMemoryRound(station)
		end
		setScreen(station)
		stations[station.id] = station
		table.insert(list, station)
		local prompt = part:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
		prompt.Triggered:Connect(function(player)
			if station.solved or not station.isClimber(player) then
				return
			end
			local current = station.solver
			if current and current ~= player and current.Parent == Players and near(current, station) then
				notify:FireClient(player, "MiniGameBusy", { name = current.DisplayName })
				return
			end
			station.solver = player
			sendOpen(station, player)
		end)
	end
	local middle = list[math.ceil(#list / 2)]
	return {
		kind = kind,
		title = LABELS[kind].title,
		label = LABELS[kind].task,
		focus = middle.part.Position + Vector3.new(0, 2.5, 0),
		update = function(_dt: number) end,
		progress = function()
			return solvedCount, count
		end,
		solved = function()
			return solvedCount >= count
		end,
		cleanup = function()
			for _, s in list do
				stations[s.id] = nil
			end
			folder:Destroy()
		end,
	}
end

local function handle(player: Player, id: string, action: string, a: number?, b: number?)
	local station = stations[id]
	if not station or station.solved or station.solver ~= player then
		return
	end
	if action == "close" then
		station.solver = nil
		return
	end
	if not near(player, station) or not station.isClimber(player) then
		station.solver = nil
		notify:FireClient(player, "MiniGameDone", { id = id, closed = true })
		return
	end
	local pipes, wires = station.pipes, station.wires
	if action == "rotate" and pipes and a then
		local index = math.floor(a)
		if index < 1 or index > pipes.width * pipes.height then
			return
		end
		pipes.rotations[index] = (pipes.rotations[index] + 1) % 4
		local flow = {}
		for i in PuzzleGen.pipesFlow(pipes) do
			table.insert(flow, i)
		end
		notify:FireClient(player, "MiniGameState", {
			id = id,
			index = index,
			mask = PuzzleGen.shownMask(pipes, index),
			flow = flow,
		})
		if PuzzleGen.pipesSolved(pipes) then
			finishStation(station, player)
		end
	elseif action == "connect" and wires and a and b then
		local l, r = math.floor(a), math.floor(b)
		if not wires.left[l] or not wires.right[r] then
			return
		end
		local ok = PuzzleGen.wireMatches(wires, l, r)
		if ok then
			wires.connected[l] = r
		end
		notify:FireClient(player, "MiniGameState", { id = id, left = l, right = r, ok = ok })
		if PuzzleGen.wiresSolved(wires) then
			finishStation(station, player)
		end
	elseif action == "press" and station.kind == "Memory" and a then
		local pad = math.floor(a)
		local expected = station.memorySeq[station.memoryProgress + 1]
		if pad == expected then
			station.memoryProgress += 1
			if station.memoryProgress >= #station.memorySeq then
				if station.memoryRound >= 3 then
					finishStation(station, player)
					return
				end
				station.memoryRound += 1
				newMemoryRound(station)
				notify:FireClient(player, "MiniGameState", {
					id = id,
					round = station.memoryRound,
					sequence = station.memorySeq,
					ok = true,
				})
			else
				notify:FireClient(player, "MiniGameState", { id = id, pad = pad, ok = true })
			end
		else
			station.memoryProgress = 0
			notify:FireClient(player, "MiniGameState", {
				id = id,
				pad = pad,
				ok = false,
				round = station.memoryRound,
				sequence = station.memorySeq,
			})
		end
	end
end

function MiniGames.start()
	RemoteGuard.connect(Remotes.get("MiniGame"), function(id: any, action: any, a: any, b: any)
		return Validate.shortString(id, 16)
			and (action == "rotate" or action == "connect" or action == "press" or action == "close")
			and (a == nil or Validate.finiteNumber(a))
			and (b == nil or Validate.finiteNumber(b))
	end, handle)
	Players.PlayerRemoving:Connect(function(player)
		for _, s in stations do
			if s.solver == player then
				s.solver = nil
			end
		end
	end)
end

return MiniGames
