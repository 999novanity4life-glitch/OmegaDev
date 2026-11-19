--!strict
-- Server authority for the 3-beat throw. The client reports how far its
-- wind-up marker was from the zone centre and how early/late its taps were;
-- the server grades them (ThrowGrade), owns the combo, decides the distance,
-- and checks the air tap arrives while the fruit is really in the air.
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
	flight: number,
	windup: Grade,
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
local MAX_ZONE_RATIO = 50
local MAX_TAP_OFFSET = 2

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
	local distance = ThrowGrade.finalDistance(flight.launch, flight.windup, flight.release, air, cfg)
	local rounded = math.floor(distance + 0.5)
	if rounded > state.best.Value then
		state.best.Value = rounded
	end
	stateChanged:FireClient(player, "Landed", {
		air = air,
		distance = rounded,
		masterwork = ThrowGrade.isMasterwork(flight.windup, flight.release, air),
		best = state.best.Value,
		combo = state.combo,
	})
end

local function onThrow(player: Player, zoneRatio: number, releaseOffset: number)
	local state = states[player]
	if not state or state.flight then
		return -- one fruit in the air at a time
	end
	local cfg = Config.Throw
	local windup: Grade = ThrowGrade.gradeZone(zoneRatio, cfg.ZoneGrades)
	local release: Grade = ThrowGrade.gradeTiming(releaseOffset, cfg.TimingWindows)
	local launch = ThrowGrade.launchDistance(windup, release, state.combo, cfg)
	state.combo = ThrowGrade.comboAfter(state.combo, release, cfg.ComboMax)
	local flightTime = ThrowGrade.flightTime(launch, cfg)
	state.nextToken += 1
	local token = state.nextToken
	state.flight = {
		token = token,
		startedAt = os.clock(),
		flight = flightTime,
		windup = windup,
		release = release,
		launch = launch,
	}
	stateChanged:FireClient(player, "Launched", {
		windup = windup,
		release = release,
		distance = launch,
		flight = flightTime,
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
	local earliest = flight.flight * cfg.AirRingAt - cfg.TimingWindows.Good
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

	RemoteGuard.connect(Remotes.get("Throw"), function(zoneRatio: any, releaseOffset: any)
		return Validate.finiteNumber(zoneRatio, -MAX_ZONE_RATIO, MAX_ZONE_RATIO)
			and Validate.finiteNumber(releaseOffset, -MAX_TAP_OFFSET, MAX_TAP_OFFSET)
	end, onThrow)

	RemoteGuard.connect(Remotes.get("AirTap"), function(offset: any)
		return Validate.finiteNumber(offset, -MAX_TAP_OFFSET, MAX_TAP_OFFSET)
	end, onAirTap)
end

return ThrowService
