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

local Automation = {}

local A = Config.Automation
local TICK = 0.1
local VIEW_EVERY = 0.25
local PAY_EVERY = 2

type Bot = {
	uid: number,
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

local function botModel(color: Color3): Model
	local m = Instance.new("Model")
	m.Name = "DotBot"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3, 3, 3)
	body.Color = Color3.fromRGB(236, 238, 243)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CastShadow = true
	body.Parent = m
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 3.6, 3.6)
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = body.CFrame * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = m
	local eye = Instance.new("Part")
	eye.Name = "Eye"
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(0.8, 0.8, 0.8)
	eye.Color = Color3.fromRGB(20, 22, 26)
	eye.Material = Enum.Material.Glass
	eye.Anchored = true
	eye.CanCollide = false
	eye.CFrame = body.CFrame * CFrame.new(0, 0.4, -1.3)
	eye.Parent = m
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Color = ColorSequence.new(Color3.fromRGB(200, 200, 205))
	dust.Size = NumberSequence.new(0.6, 1.6)
	dust.Transparency = NumberSequence.new(0.3, 1)
	dust.Lifetime = NumberRange.new(0.6, 1.2)
	dust.Speed = NumberRange.new(2, 4)
	dust.SpreadAngle = Vector2.new(60, 60)
	dust.Rate = 0
	dust.Parent = body
	m.PrimaryPart = body
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return m
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
		if b.id == "DotBotMk1" or b.id == "DotBotMk2" then
			alive[b.uid] = true
			if not base.bots[b.uid] then
				local tier = if b.id == "DotBotMk2" then A.BotMk2 else A.BotMk1
				local rings = tier.rings + (s.fx.botRings or 0)
				local m =
					botModel(if b.id == "DotBotMk2" then Color3.fromRGB(255, 205, 40) else Color3.fromRGB(60, 220, 210))
				local dock = model:GetPivot()
				m:PivotTo(dock * CFrame.new(0, 2.5, 0))
				m:SetAttribute("Owner", player.UserId)
				m.Name = string.format("DotBot_%d", b.uid)
				m.Parent = plot.buildings
				base.bots[b.uid] = {
					uid = b.uid,
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
	Crew.stat(s, "kg", dust + star)
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

local function stepBot(player: Player, s: Crew.Session, st: BaseState, bot: Bot, now: number)
	if now < bot.busyUntil then
		return
	end
	local dockModel = Base.model(player, bot.uid)
	local node = st.net.nodes[bot.uid]
	if not dockModel or not node then
		return
	end
	local tier = if node.id == "DotBotMk2" then A.BotMk2 else A.BotMk1
	local status: string
	if not Belts.connected(st.net, bot.uid) then
		status = "Lay a belt from the dock to a Pod Cannon"
	elseif (node.store.Dust or 0) >= A.BotStoreKg - 0.01 then
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
				local here = bot.model:GetPivot().Position
				local to = hoverAt(dir, Stations.groundAt(dir) - here)
				local seconds = math.clamp((to.Position - here).Magnitude / 20, 0.5, 8)
				moveBot(bot, to, seconds)
				bot.busyUntil = now + seconds
				dockModel:SetAttribute("Status", "Flying out")
				return
			end
		end
		local target = bot.target
		if not target then
			status = "All clean round here"
		else
			local budget = tier.kgPerMin / 60 * (1 + (s.fx.botRatePct or 0) / 100)
			local a, b = Moon.patchesOf(target)
			local kg = 0
			while kg < budget and a + bot.cursor < b do
				kg += Moon.clearPatch(Moon.patchAt(a + bot.cursor), player, false)
				bot.cursor += 1
			end
			if a + bot.cursor >= b then
				-- steep patches a bot can't reach leave the sector for a broom
				bot.area = table.clone(bot.area)
				table.remove(bot.area, table.find(bot.area, target) :: number)
				bot.target = nil
			end
			if kg > 0 then
				Belts.feed(st.net, bot.uid, "Dust", kg)
				Crew.stat(s, "botKg", kg)
			end
			status = "Cleaning"
		end
	end
	local body = bot.model.PrimaryPart
	local dust = body and body:FindFirstChild("Dust") :: ParticleEmitter?
	if dust then
		dust.Rate = if status == "Cleaning" then 25 else 0
	end
	if status ~= "Cleaning" and status ~= "Flying out" then
		local home = dockModel:GetPivot() * CFrame.new(0, 2.5, 0)
		if (bot.model:GetPivot().Position - home.Position).Magnitude > 4 then
			local seconds = math.clamp((home.Position - bot.model:GetPivot().Position).Magnitude / 20, 0.5, 8)
			moveBot(bot, home, seconds)
			bot.busyUntil = now + seconds
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
	if total > 0 then
		Crew.earn(s, total, "Launch", st.owedAt)
		Crew.stat(s, "launches", pods)
		s.data.awayRate = s.data.awayRate * 0.8 + total / PAY_EVERY * 60 * 0.2
		if st.owedAt then
			worldEvent:FireAllClients("Launch", { at = st.owedAt, pods = pods, by = player.UserId })
		end
	end
end

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
