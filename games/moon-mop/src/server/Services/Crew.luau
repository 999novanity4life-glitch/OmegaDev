--!strict
-- Per-player session state on top of the save: the Dust Pack, carried pods, tool on/off, the
-- cached Upgrade Board effects. Money and stats only change through here, and every change is
-- pushed to the player's HUD (throttled) through the State remote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))
local Factory = require(Shared:WaitForChild("Factory"))

local Data = require(script.Parent.Data)
local Moon = require(script.Parent.Moon)

export type Pod = { kg: number, stardust: number }

export type Session = {
	player: Player,
	data: Data.SaveData,
	fx: { [string]: number },
	toolOn: boolean,
	lastHead: Vector3?,
	lastT: number,
	packKg: number,
	packStar: number,
	pods: { Pod },
	packBusyUntil: number,
	vehicle: Model?,
	vehicleId: string?,
	tankKg: number,
	tankStar: number,
	dial: number,
	dirty: boolean,
	sectorId: number,
	joined: number,
}

local Crew = {}

local sessions: { [Player]: Session } = {}
local stateRemote = Remotes.get("State")
local feedbackRemote = Remotes.get("Feedback")
local readyCallbacks: { (Session) -> () } = {}

function Crew.get(player: Player): Session?
	return sessions[player]
end

function Crew.all(): { [Player]: Session }
	return sessions
end

function Crew.onReady(fn: (Session) -> ())
	table.insert(readyCallbacks, fn)
	for _, s in sessions do
		task.spawn(fn, s)
	end
end

function Crew.refreshEffects(s: Session)
	s.fx = Upgrades.effects(s.data.upgrades)
	s.dirty = true
end

function Crew.equippedTool(s: Session): (Config.ToolDef, Loadout.ToolStats)
	local id = s.data.belt[s.data.equipped] or s.data.belt[1] or "Toothbrush"
	local def = Loadout.tool(id) or Config.Tools[1]
	return def, Loadout.toolStats(def, s.data.packUps[def.id] == true, s.fx)
end

function Crew.carryLimit(s: Session): number
	return Loadout.carryLimit(s.data.carryBought, s.fx)
end

function Crew.feedback(player: Player, kind: string, data: any?)
	feedbackRemote:FireClient(player, kind, data)
end

function Crew.stat(s: Session, key: string, add: number)
	s.data.stats[key] = (s.data.stats[key] or 0) + add
	s.dirty = true
end

-- The one place money is added. `reason` drives the HUD popup.
function Crew.earn(s: Session, amount: number, reason: string, at: Vector3?)
	if amount <= 0 then
		return
	end
	amount = Economy.round(amount)
	s.data.money = Economy.round(s.data.money + amount)
	Crew.stat(s, "earned", amount)
	Crew.feedback(s.player, "Earned", { amount = amount, reason = reason, at = at })
end

-- Charge a price. Returns false (and tells the player) when they can't afford it.
function Crew.spend(s: Session, amount: number, what: string): boolean
	amount = Economy.round(amount)
	if s.data.money + 1e-6 < amount then
		Crew.feedback(s.player, "Error", { text = "Not enough money for " .. what })
		return false
	end
	s.data.money = Economy.round(s.data.money - amount)
	s.dirty = true
	return true
end

local function snapshot(s: Session)
	local d = s.data
	local tool, stats = Crew.equippedTool(s)
	local pods = 0
	local podKg = 0
	for _, p in s.pods do
		pods += 1
		podKg += p.kg
	end
	local vehicle = s.vehicleId and Loadout.vehicle(s.vehicleId)
	local vstats = vehicle and Loadout.vehicleStats(vehicle, d.vehicles[vehicle.id], s.fx, s.dial)
	return {
		money = d.money,
		stats = d.stats,
		hired = d.hired,
		tools = d.tools,
		packUps = d.packUps,
		belt = d.belt,
		slots = d.slots,
		equipped = d.equipped,
		tool = tool.id,
		width = stats.width,
		pack = s.packKg,
		packStar = s.packStar,
		packMax = stats.pack,
		pods = pods,
		podKg = podKg,
		carry = Crew.carryLimit(s),
		carryBought = d.carryBought,
		toolOn = s.toolOn,
		upgrades = d.upgrades,
		flags = d.flags,
		probes = d.probes,
		waypoints = d.waypoints,
		garage = d.garage,
		vehicles = d.vehicles,
		vehicle = s.vehicleId,
		tank = s.tankKg,
		tankMax = if vstats then vstats.tank else 0,
		dial = s.dial,
		buildTool = d.buildTool,
		plot = d.plot,
		buildings = d.buildings,
		gear = d.gear,
		suit = d.suit,
		achievements = d.achievements,
		walk = Loadout.walkSpeed(s.fx, d.gear.GravityBootsOn),
		jump = Loadout.jumpSpeed(s.fx),
		lamp = Loadout.lampRange(s.fx),
		fx = s.fx,
	}
end

function Crew.push(s: Session)
	s.dirty = false
	stateRemote:FireClient(s.player, snapshot(s))
end

-- Character attributes other clients read for visuals (tool look, pods on the back, suit).
function Crew.syncCharacter(s: Session)
	local char = s.player.Character
	if not char then
		return
	end
	local tool, stats = Crew.equippedTool(s)
	char:SetAttribute("Tool", tool.id)
	char:SetAttribute("ToolWidth", stats.width)
	char:SetAttribute("ToolReach", stats.reach)
	char:SetAttribute("Brushing", s.toolOn and s.vehicle == nil)
	char:SetAttribute("Pods", #s.pods)
	char:SetAttribute("Visor", s.data.suit.visor)
	char:SetAttribute("SuitColour", s.data.suit.colour)
	char:SetAttribute("WalkSpeed", Loadout.walkSpeed(s.fx, s.data.gear.GravityBootsOn))
	char:SetAttribute("JumpSpeed", Loadout.jumpSpeed(s.fx))
	char:SetAttribute("Jetpack", s.data.gear.Jetpack == true and s.data.gear.JetpackOn ~= false)
	char:SetAttribute("JetpackFuelPct", s.fx.jetpackPct or 0)
	char:SetAttribute("NightVision", s.data.gear.NightVision == true and s.data.gear.NightVisionOn == true)
	char:SetAttribute("Lamp", Loadout.lampRange(s.fx))
end

local function moonPct(): number
	return (Moon.doneCount() - Moon.yardSectors) / Moon.sector.count * 100
end

-- Achievements: checked whenever stats change (cheap: 33 entries).
function Crew.checkAchievements(s: Session)
	local d = s.data
	local stats = table.clone(d.stats)
	local _, toolIndex = Loadout.tool(d.belt[d.equipped] or "Toothbrush")
	local best = 0
	for id in d.tools do
		local _, i = Loadout.tool(id)
		best = math.max(best, i)
	end
	stats.toolTier = math.max(best, toolIndex)
	local nVehicles = 0
	for _ in d.vehicles do
		nVehicles += 1
	end
	stats.vehicles = nVehicles
	local nFlags, nProbes = 0, 0
	for _ in d.flags do
		nFlags += 1
	end
	for _ in d.probes do
		nProbes += 1
	end
	stats.flags = nFlags
	stats.probes = nProbes
	stats.upgrades = Upgrades.nodesDone(d.upgrades)
	stats.moonPct = moonPct()
	for _, a in Factory.newAchievements(stats, d.achievements) do
		d.achievements[a.id] = true
		Crew.feedback(s.player, "Achievement", { id = a.id, name = a.name })
		if a.badgeId ~= 0 then
			task.spawn(function()
				pcall(function()
					game:GetService("BadgeService"):AwardBadge(s.player.UserId, a.badgeId)
				end)
			end)
		end
	end
end

Data.onLoaded(function(player, data)
	local s: Session = {
		player = player,
		data = data,
		fx = Upgrades.effects(data.upgrades),
		toolOn = false,
		lastHead = nil,
		lastT = os.clock(),
		packKg = 0,
		packStar = 0,
		pods = {},
		packBusyUntil = 0,
		vehicle = nil,
		vehicleId = nil,
		tankKg = 0,
		tankStar = 0,
		dial = 0,
		dirty = true,
		sectorId = -1,
		joined = os.time(),
	}
	-- make sure the belt only holds owned tools and fits the slots
	local belt = {}
	for _, id in data.belt do
		if data.tools[id] and #belt < data.slots then
			table.insert(belt, id)
		end
	end
	if #belt == 0 then
		belt = { "Toothbrush" }
	end
	data.belt = belt
	data.equipped = math.clamp(data.equipped, 1, #belt)
	sessions[player] = s
	player:SetAttribute("Loaded", true)
	for _, fn in readyCallbacks do
		task.spawn(fn, s)
	end
	Crew.push(s)
	Crew.syncCharacter(s)
	player.CharacterAdded:Connect(function()
		task.wait()
		s.toolOn = false
		s.lastHead = nil
		Crew.syncCharacter(s)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)

-- Throttled pushes and periodic achievement checks.
task.spawn(function()
	local tick = 0
	while true do
		task.wait(0.25)
		tick += 1
		for _, s in sessions do
			if s.dirty then
				Crew.push(s)
				Crew.syncCharacter(s)
			end
			if tick % 8 == 0 then
				Crew.checkAchievements(s)
			end
		end
	end
end)

return Crew
