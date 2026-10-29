--!strict
-- Base automation: runs each claimed plot's belt network (Shared/Belts), its solar and battery
-- power (Shared/Factory), the Pod Packer, and the Dot Bots that clean the sectors round a base
-- and send their dust home by belt. The Pod Cannon's sales are paid every couple of seconds so
-- the HUD isn't flooded. Pod positions go to every client a few times a second for drawing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Belts = require(Shared:WaitForChild("Belts"))
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Factory = require(Shared:WaitForChild("Factory"))
local Places = require(Shared:WaitForChild("Places"))
local Plot = require(Shared:WaitForChild("Plot"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Base = require(script.Parent.Base)
local Crew = require(script.Parent.Crew)
local Moon = require(script.Parent.Moon)
local Sky = require(script.Parent.Sky)
local Stations = require(script.Parent.Stations)
local Robots = require(script.Parent.Parent.World.Robots)

local Automation = {}

local A = Config.Automation
local TICK = 0.1
local VIEW_EVERY = 0.25
local PAY_EVERY = 2

type Bot = {
	uid: number,
	octo: boolean, -- a Cosmic Octo: roams far, fires pods home to the Pod Catcher
	carry: number, -- kg an Octo holds before it fires a pod
	model: Model,
	area: { number }, -- sectors this bot looks after, nearest first
	target: number?,
	cursor: number, -- next patch index inside the target sector
	busyUntil: number,
}

type BaseState = {
	net: Belts.Net,
	power: Factory.PowerState?,
	owed: { [string]: number }, -- kg sold since the last payout, by product
	owedAt: Vector3?,
	payT: number,
	bots: { [number]: Bot },
}

local bases: { [Player]: BaseState } = {}
local factoryRemote = Remotes.get("Factory")
local worldEvent = Remotes.get("WorldEvent")

local function isYard(dir: Vector3): boolean
	for _, pad in Places.pads() do
		if Places.arc(dir, pad.dir) < pad.radius + 16 then
			return true
		end
	end
	return false
end

-- The sectors a bot on this dock looks after: the nearest 1 + 3r(r + 1) outside the yards.
local function botArea(dockPos: Vector3, rings: number): { number }
	local want = 1 + 3 * rings * (rings + 1)
	local out = {}
	for _, sid in Moon.ring(Moon.sector:locate(Places.up(dockPos)), rings + 7) do
		if not isYard(Moon.sector:position(sid)) then
			table.insert(out, sid)
			if #out >= want then
				break
			end
		end
	end
	return out
end

local function moveBot(bot: Bot, to: CFrame, seconds: number)
	local from = bot.model:GetPivot()
	local value = Instance.new("CFrameValue")
	value.Value = from
	value.Changed:Connect(function(cf)
		bot.model:PivotTo(cf)
	end)
	local tween = TweenService:Create(value, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Value = to })
	tween.Completed:Connect(function()
		value:Destroy()
	end)
	tween:Play()
end

local function hoverAt(dir: Vector3, look: Vector3): CFrame
	local ground = Stations.groundAt(dir)
	local pos = ground + dir * 3
	local fwd = (look - dir * look:Dot(dir))
	if fwd.Magnitude < 1e-3 then
		fwd = dir:Cross(Vector3.xAxis)
	end
	return CFrame.lookAt(pos, pos + fwd.Unit, dir)
end

local unloadPack: (player: Player, uid: number) -> ()

-- Rebuild a base's net and bots after its buildings change.
local function refresh(player: Player)
	local s = Crew.get(player)
	local plot = Base.plotOf(player)
	local st = bases[player]
	if not s or not plot then
		if st then
			for _, bot in st.bots do
				bot.model:Destroy()
			end
			bases[player] = nil
		end
		return
	end
	if not st then
		st = {
			net = Belts.build(s.data.buildings),
			power = nil,
			owed = {},
			owedAt = nil,
			payT = 0,
			bots = {},
		}
		bases[player] = st
	else
		st.net = Belts.build(s.data.buildings, st.net)
	end
	local base = st :: BaseState
	local alive: { [number]: boolean } = {}
	for _, b in s.data.buildings do
		local model = Base.model(player, b.uid)
		if not model then
			continue
		end
		if b.id == "PodPacker" and not model:GetAttribute("Prompted") then
			local intake = model:FindFirstChild("Intake") :: BasePart?
			if intake then
				model:SetAttribute("Prompted", true)
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Unload pods"
				prompt.ObjectText = "Pod Packer"
				prompt.HoldDuration = 0.4
				prompt.MaxActivationDistance = 12
				prompt.RequiresLineOfSight = false
				prompt.Style = Enum.ProximityPromptStyle.Custom
				prompt.Parent = intake
				local uid = b.uid
				prompt.Triggered:Connect(function(who)
					if who == player then
						unloadPack(player, uid)
					end
				end)
			end
		end
		if b.id == "DotBotMk1" or b.id == "DotBotMk2" or b.id == "CosmicOcto" then
			alive[b.uid] = true
			if not base.bots[b.uid] then
				local octo = b.id == "CosmicOcto"
				local rings = if octo
					then A.OctoRange * 8
					else (if b.id == "DotBotMk2" then A.BotMk2 else A.BotMk1).rings + (s.fx.botRings or 0)
				local m = if octo
					then Robots.octo()
					else Robots.dotBot(
						if b.id == "DotBotMk2" then Color3.fromRGB(255, 205, 40) else Color3.fromRGB(60, 220, 210)
					)
				local dock = model:GetPivot()
				m:PivotTo(dock * CFrame.new(0, if octo then 7 else 2.5, 0))
				if os.time() - b.t <= 10 then
					-- just built (not a base coming back on join)
					Crew.stat(s, if octo then "octos" else "bots", 1)
					if octo then
						Crew.feedback(player, "Cutscene", { name = "Octo", at = dock.Position })
					end
				end
				m:SetAttribute("Owner", player.UserId)
				m.Name = string.format("%s_%d", if octo then "Octo" else "DotBot", b.uid)
				m.Parent = plot.buildings
				base.bots[b.uid] = {
					uid = b.uid,
					octo = octo,
					carry = 0,
					model = m,
					area = botArea(dock.Position, rings),
					target = nil,
					cursor = 0,
					busyUntil = 0,
				}
			end
		end
	end
	for uid, bot in base.bots do
		if not alive[uid] then
			bot.model:Destroy()
			base.bots[uid] = nil
		end
	end
end
Base.onChanged(refresh)

Players.PlayerRemoving:Connect(function(player)
	local st = bases[player]
	if st then
		for _, bot in st.bots do
			bot.model:Destroy()
		end
	end
	bases[player] = nil
end)

-- The Collector Pad you are parked on, if it feeds a belt.
function Automation.collectorFor(player: Player): (number?, Vector3?)
	local st = bases[player]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local s = Crew.get(player)
	if not st or not root or not s then
		return nil, nil
	end
	for _, b in s.data.buildings do
		if b.id == "CollectorPad" then
			local model = Base.model(player, b.uid)
			if model and (model:GetPivot().Position - root.Position).Magnitude <= 18 then
				if Belts.connected(st.net, b.uid) then
					return b.uid, model:GetPivot().Position
				end
			end
		end
	end
	return nil, nil
end

-- Pour dust onto a source's belts. Returns kg taken.
function Automation.feed(player: Player, uid: number, kind: Belts.Kind, kg: number): number
	local st = bases[player]
	return if st then Belts.feed(st.net, uid, kind, kg) else 0
end

-- Tip your carried pods (and the Dust Pack) into a Pod Packer.
function unloadPack(player: Player, uid: number)
	local s = Crew.get(player)
	local st = bases[player]
	if not s or not st then
		return
	end
	if not Belts.connected(st.net, uid) then
		Crew.feedback(player, "Error", { text = "Lay a belt from the Pod Packer's side first" })
		return
	end
	local dust, star = s.packKg - s.packStar, s.packStar
	for _, pod in s.pods do
		dust += pod.kg - (pod.stardust or 0)
		star += pod.stardust or 0
	end
	if dust + star < 0.01 then
		Crew.feedback(player, "Error", { text = "Nothing to unload" })
		return
	end
	Belts.feed(st.net, uid, "Dust", dust)
	Belts.feed(st.net, uid, "Stardust", star)
	s.pods = {}
	s.packKg, s.packStar = 0, 0
	s.dirty = true
	Crew.feedback(player, "Toast", { text = string.format("Unloaded %.1f kg onto the belts", dust + star) })
end

Automation.unloadPack = unloadPack

local function solarAndStorage(buildings: { Plot.Building }): (number, number)
	local rated, capacity = 0, 0
	for _, b in buildings do
		local def = Plot.def(b.id)
		if def and def.power and def.power < 0 then
			rated -= def.power
		elseif b.id == "Battery" then
			capacity += A.BatteryKWh
		end
	end
	return rated, capacity
end

-- Where a base's Pod Catcher catches (the top of its net), if it has one.
local function catcherAt(player: Player, s: Crew.Session): Vector3?
	for _, b in s.data.buildings do
		if b.id == "PodCatcher" then
			local m = Base.model(player, b.uid)
			local net = m and m:FindFirstChild("Net") :: BasePart?
			return if net then net.Position else nil
		end
	end
	return nil
end

local function fly(bot: Bot, to: CFrame, now: number)
	local here = bot.model:GetPivot().Position
	local speed = if bot.octo then A.OctoMoveSpeed else 20
	local seconds = math.clamp((to.Position - here).Magnitude / speed, 0.5, if bot.octo then 20 else 8)
	moveBot(bot, to, seconds)
	bot.busyUntil = now + seconds
end

local function stepBot(player: Player, s: Crew.Session, st: BaseState, bot: Bot, now: number)
	if now < bot.busyUntil then
		return
	end
	local dockModel = Base.model(player, bot.uid)
	if not dockModel then
		return
	end
	local node = st.net.nodes[bot.uid]
	local catcher = if bot.octo then catcherAt(player, s) else nil
	local status: string
	if bot.octo and not catcher then
		status = "Needs a Pod Catcher"
	elseif not bot.octo and not (node and Belts.connected(st.net, bot.uid)) then
		status = "Lay a belt from the dock to a Pod Cannon"
	elseif not bot.octo and node and (node.store.Dust or 0) >= A.BotStoreKg - 0.01 then
		status = "Dock full: the belt is backed up"
	else
		if bot.target == nil or Moon.isSectorDone(bot.target) then
			bot.target = nil
			for _, sid in bot.area do
				if not Moon.isSectorDone(sid) then
					bot.target = sid
					bot.cursor = 0
					break
				end
			end
			if bot.target then
				local dir = Moon.sector:position(bot.target)
				local lift = if bot.octo then 7 else 3
				local to = hoverAt(dir, Stations.groundAt(dir) - bot.model:GetPivot().Position)
					* CFrame.new(0, lift - 3, 0)
				fly(bot, to, now)
				dockModel:SetAttribute("Status", "Flying out")
				return
			end
		end
		local target = bot.target
		if not target then
			status = "All clean round here"
		else
			local rate = if bot.octo
				then A.OctoKgPerMin * (1 + (s.fx.octoRatePct or 0) / 100)
				else (if node and node.id == "DotBotMk2" then A.BotMk2 else A.BotMk1).kgPerMin
					* (1 + (s.fx.botRatePct or 0) / 100)
			local budget = rate / 60
			local a, b = Moon.patchesOf(target)
			local kg = 0
			while kg < budget and a + bot.cursor < b do
				kg += Moon.clearPatch(Moon.patchAt(a + bot.cursor), player, false)
				bot.cursor += 1
			end
			if a + bot.cursor >= b then
				-- steep patches a robot can't reach leave the sector for a broom
				bot.area = table.clone(bot.area)
				table.remove(bot.area, table.find(bot.area, target) :: number)
				bot.target = nil
			end
			if kg > 0 and bot.octo and catcher then
				bot.carry += kg
				Crew.stat(s, "octoKg", kg)
				while bot.carry >= A.PodValueKg do
					bot.carry -= A.PodValueKg
					local from = bot.model:GetPivot().Position
					local flight = math.clamp((catcher - from).Magnitude / 120, 1, 4)
					worldEvent:FireAllClients("OctoPod", { from = from, to = catcher, t = flight })
					task.delay(flight, function()
						st.owed.Dust = (st.owed.Dust or 0) + A.PodValueKg
						st.owedAt = catcher
					end)
				end
			elseif kg > 0 then
				Belts.feed(st.net, bot.uid, "Dust", kg)
				Crew.stat(s, "botKg", kg)
			end
			status = "Cleaning"
		end
	end
	local body = bot.model.PrimaryPart
	local dust = body and body:FindFirstChild("Dust") :: ParticleEmitter?
	if dust then
		dust.Rate = if status == "Cleaning" then (if bot.octo then 60 else 25) else 0
	end
	if status ~= "Cleaning" then
		local home = dockModel:GetPivot() * CFrame.new(0, if bot.octo then 7 else 2.5, 0)
		if (bot.model:GetPivot().Position - home.Position).Magnitude > 4 then
			fly(bot, home, now)
		end
	end
	dockModel:SetAttribute("Status", status)
	bot.busyUntil = math.max(bot.busyUntil, now + 1)
end

local function pay(player: Player, s: Crew.Session, st: BaseState)
	local total = 0
	local pods = 0
	for kind, kg in st.owed do
		total += Economy.productPayout(kind :: Economy.Product, kg, s.fx)
		pods += math.ceil(kg / A.PodValueKg - 1e-6)
		if kind == "Glass" then
			Crew.stat(s, "glassKg", kg)
		elseif kind == "Gem" then
			Crew.stat(s, "gemKg", kg)
		end
		Crew.stat(s, "kg", kg)
	end
	table.clear(st.owed)
	-- smoothed $/min over the last minute or so, for "while you were away"
	s.data.awayRate = s.data.awayRate * 0.95 + total / PAY_EVERY * 60 * 0.05
	s.data.lastOnline = os.time()
	if total > 0 then
		Crew.earn(s, total, "Launch", st.owedAt)
		Crew.stat(s, "launches", pods)
		if st.owedAt then
			worldEvent:FireAllClients("Launch", { at = st.owedAt, pods = pods, by = player.UserId })
		end
	end
end

-- While you were away: a share of what the base was earning, paid when you come back.
Crew.onReady(function(s)
	local d = s.data
	local now = os.time()
	if d.lastOnline > 0 then
		local away = now - d.lastOnline
		local amount = Economy.awayEarnings(d.awayRate, away, s.fx)
		if amount > 0 then
			Crew.earn(s, amount, "Away")
			Crew.feedback(s.player, "Away", { amount = amount, minutes = math.floor(away / 60) })
		end
	end
	d.lastOnline = now
end)

local viewT = 0

task.spawn(function()
	while true do
		local dt = task.wait(TICK)
		local now = os.clock()
		for player, st in bases do
			local s = Crew.get(player)
			local plot = Base.plotOf(player)
			if not s or not plot then
				continue
			end
			local rated, capacity = solarAndStorage(s.data.buildings)
			local up = Places.up(plot.frame.Position)
			local power = Factory.power(
				rated,
				Sky.sunlightAt(up),
				Belts.demand(st.net),
				math.min(s.data.battery, capacity),
				capacity,
				dt,
				s.fx
			)
			st.power = power
			s.data.battery = power.battery
			local sold = Belts.tick(st.net, dt, power.satisfied, s.fx)
			for _, item in sold do
				st.owed[item.kind] = (st.owed[item.kind] or 0) + item.kg
				if not st.owedAt then
					for _, b in s.data.buildings do
						if b.id == "PodCannon" then
							local m = Base.model(player, b.uid)
							local muzzle = m and m:FindFirstChild("Muzzle") :: BasePart?
							st.owedAt = if muzzle then muzzle.Position else nil
							break
						end
					end
				end
			end
			st.payT += dt
			if st.payT >= PAY_EVERY then
				st.payT = 0
				pay(player, s, st)
				plot.model:SetAttribute("PowerIn", power.produced)
				plot.model:SetAttribute("PowerUse", power.demand)
				plot.model:SetAttribute("Battery", power.battery)
				plot.model:SetAttribute("BatteryMax", power.capacity)
			end
			for _, bot in st.bots do
				stepBot(player, s, st, bot, now)
			end
		end
		viewT += dt
		if viewT >= VIEW_EVERY then
			viewT = 0
			local view = {}
			for player, st in bases do
				local plot = Base.plotOf(player)
				if plot then
					local flat: { number | string } = {}
					for _, pod in Belts.pods(st.net) do
						table.insert(flat, pod.id)
						table.insert(flat, pod.x)
						table.insert(flat, pod.z)
						table.insert(flat, pod.h)
						table.insert(flat, pod.kind)
					end
					view[tostring(plot.index)] = flat
				end
			end
			factoryRemote:FireAllClients(view)
		end
	end
end)

return Automation
