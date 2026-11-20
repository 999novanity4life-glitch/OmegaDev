--!strict
-- Server authority for the throw. The client reports the power it locked on
-- the meter (0..MeterMax) and how early/late its taps were; the server grades
-- them (ThrowGrade), checks the player is at the dock edge, rolls the fruit,
-- owns the combo, decides the distance, and checks the air tap arrives while
-- the fruit is really in the air.
-- Feel-test scope: no saving (best distance lives in leaderstats only).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local ThrowGrade = require(Shared:WaitForChild("ThrowGrade"))
local Validate = require(Shared:WaitForChild("Validate"))
local RemoteGuard = require(script.Parent.RemoteGuard)

type Grade = ThrowGrade.Grade

type Flight = {
	token: number,
	startedAt: number,
	flight: number, -- real seconds in the air (rarity paced)
	base: number, -- unpaced flight seconds
	pace: ThrowGrade.Pace,
	meter: Grade,
	release: Grade,
	launch: number,
}

type PlayerState = {
	combo: number,
	flight: Flight?,
	nextToken: number,
	best: IntValue,
}

-- Client-reported numbers are clamped to these ranges before grading.
local MAX_TAP_OFFSET = 2
-- Slack on top of EdgeTriggerRadius for lag and the cutscene walk.
local EDGE_SLACK = 8

local ThrowService = {}

local states: { [Player]: PlayerState } = {}
local stateChanged: RemoteEvent

local function setupPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local best = Instance.new("IntValue")
	best.Name = "Best"
	best.Parent = leaderstats
	leaderstats.Parent = player
	states[player] = { combo = 0, flight = nil, nextToken = 0, best = best }
end

local function land(player: Player, token: number, air: Grade)
	local state = states[player]
	local flight = state and state.flight
	if not state or not flight or flight.token ~= token then
		return -- already landed
	end
	state.flight = nil
	local cfg = Config.Throw
	local distance = ThrowGrade.finalDistance(flight.launch, flight.meter, flight.release, air, cfg)
	local rounded = math.floor(distance + 0.5)
	if rounded > state.best.Value then
		state.best.Value = rounded
	end
	stateChanged:FireClient(player, "Landed", {
		air = air,
		distance = rounded,
		masterwork = ThrowGrade.isMasterwork(flight.meter, flight.release, air),
		best = state.best.Value,
		combo = state.combo,
	})
end

-- Where the player must stand to throw (DockLayout.throwOrigin, on the deck).
local function throwSpot(): Vector3
	local dock = Config.Dock
	if dock.Enabled then
		return Vector3.new(0, dock.DeckHeight + 3, dock.ThrowEdgeZ + Config.Throw.EdgeSpotBack)
	end
	return Vector3.new(0, Config.Lane.DeckHeight + 3, -12)
end

local function atEdge(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
	local offset = root.Position - throwSpot()
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.Throw.EdgeTriggerRadius + EDGE_SLACK
end

local function rollFruit()
	local weights = {}
	for i, fruit in Config.Fruits do
		weights[i] = Config.Rarity.Weight[fruit.rarity] or 0
	end
	return Config.Fruits[ThrowGrade.pickWeighted(weights, math.random())]
end

local function onThrow(player: Player, power: number, releaseOffset: number)
	local state = states[player]
	if not state or state.flight or not atEdge(player) then
		return -- one fruit in the air at a time, and only from the dock edge
	end
	local cfg = Config.Throw
	power = ThrowGrade.meterPower(power, cfg)
	local meter: Grade = ThrowGrade.gradePower(power, cfg)
	local release: Grade = ThrowGrade.gradeTiming(releaseOffset, cfg.TimingWindows)
	local launch = ThrowGrade.launchDistance(power, release, state.combo, cfg)
	state.combo = ThrowGrade.comboAfter(state.combo, release, cfg.ComboMax)
	local fruit = rollFruit()
	local pace = Config.Rarity.Pace[fruit.rarity]
	local base = ThrowGrade.flightTime(launch, cfg)
	local flightTime = ThrowGrade.pacedFlight(base, pace)
	state.nextToken += 1
	local token = state.nextToken
	state.flight = {
		token = token,
		startedAt = os.clock(),
		flight = flightTime,
		base = base,
		pace = pace,
		meter = meter,
		release = release,
		launch = launch,
	}
	stateChanged:FireClient(player, "Launched", {
		power = power,
		meter = meter,
		release = release,
		distance = launch,
		flight = flightTime,
		base = base,
		fruit = fruit.key,
		fruitName = fruit.name,
		rarity = fruit.rarity,
		combo = state.combo,
	})
	-- No air tap in time counts as a miss.
	task.delay(flightTime + cfg.LagAllowance, land, player, token, "Miss" :: Grade)
end

local function onAirTap(player: Player, offset: number)
	local state = states[player]
	local flight = state and state.flight
	if not state or not flight then
		return
	end
	local cfg = Config.Throw
	local elapsed = os.clock() - flight.startedAt
	-- The air ring cannot be hit before it appears or after the fruit lands.
	local earliest = ThrowGrade.realTimeAt(cfg.AirRingAt, flight.base, flight.pace) - cfg.TimingWindows.Good
	if elapsed < earliest or elapsed > flight.flight + cfg.LagAllowance then
		land(player, flight.token, "Miss" :: Grade)
		return
	end
	land(player, flight.token, ThrowGrade.gradeTiming(offset, cfg.TimingWindows))
end

function ThrowService.start()
	stateChanged = Remotes.get("StateChanged")
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	RemoteGuard.connect(Remotes.get("Throw"), function(power: any, releaseOffset: any)
		return Validate.finiteNumber(power, 0, Config.Throw.MeterMax)
			and Validate.finiteNumber(releaseOffset, -MAX_TAP_OFFSET, MAX_TAP_OFFSET)
	end, onThrow)

	RemoteGuard.connect(Remotes.get("AirTap"), function(offset: any)
		return Validate.finiteNumber(offset, -MAX_TAP_OFFSET, MAX_TAP_OFFSET)
	end, onAirTap)
end

return ThrowService
