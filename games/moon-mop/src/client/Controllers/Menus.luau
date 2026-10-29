--!strict
-- Station menus in the hazard-stripe style: the supply wall (tools on a pegboard with luggage-tag
-- prices and a detail card that shows the difference from your current tool in green), the
-- Upgrade Board (5 tabs, 56 upgrades, level pips, READY / NEEDED, "?" for locked nodes), the
-- teleport pad, the field manual (H) and the Boss Bot's hiring talk with the joke contract.
-- Menus only ask; the server checks every purchase.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Places = require(Shared:WaitForChild("Places"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sweep = require(Shared:WaitForChild("Sweep"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Hud = require(script.Parent.Hud)
local Juice = require(script.Parent.Juice)
local MoonView = require(script.Parent.MoonView)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Menus = {}

local player = Players.LocalPlayer
local buy = Remotes.get("Buy")
local gui: ScreenGui
local openCard: Frame? = nil
local refreshers: { [string]: () -> () } = {}
local cards: { [string]: Frame } = {}

local function close()
	if openCard then
		openCard.Visible = false
		openCard = nil
	end
	Hud.setMenuOpen(false)
end
Menus.close = close

local function open(name: string)
	local card = cards[name]
	if not card then
		return
	end
	if openCard and openCard ~= card then
		openCard.Visible = false
	end
	openCard = card
	Hud.setMenuOpen(true)
	local r = refreshers[name]
	if r then
		r()
	end
	Juice.popIn(card)
end
Menus.open = open

function Menus.register(name: string, card: Frame, refresh: () -> ())
	cards[name] = card
	refreshers[name] = refresh
	local closeButton = card:FindFirstChild("Close") :: TextButton?
	if closeButton then
		closeButton.Activated:Connect(close)
	end
end

local function priceTag(price: number, money: number, owned: boolean?): TextLabel
	if owned then
		return Theme.tag("OWNED", "Owned")
	end
	return Theme.tag(Theme.money(price), if money + 1e-6 >= price then "Good" else "Bad")
end

---------------------------------------------------------------------------- supply wall
local function supplyWall()
	local card, body = Theme.card(gui, "Supply Wall", "Station supplies", UDim2.fromScale(0.9, 0.84))
	local list = Theme.list(body, UDim2.new(0.5, -8, 1, -64))
	local detail = Theme.frame(UDim2.new(0.5, -8, 1, -64), UDim2.new(0.5, 8, 0, 0), Theme.SLATE_HI, 0)
	Theme.corner(detail, 8)
	Theme.pad(detail, 14)
	detail.Parent = body
	local extras = Theme.frame(UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 1, -54), Theme.SLATE, 1)
	local el = Instance.new("UIListLayout")
	el.FillDirection = Enum.FillDirection.Horizontal
	el.Padding = UDim.new(0, 8)
	el.Parent = extras
	extras.Parent = body
	local selected = "ScrubBrush"

	local function refresh()
		local s = State.get()
		local fx = s.fx or {}
		local money = s.money or 0
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, def in Config.Tools do
			local owned = s.tools and s.tools[def.id]
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, -8, 0, 52)
			row.LayoutOrder = i
			row.AutoButtonColor = false
			row.Text = ""
			row.BackgroundColor3 = if def.id == selected then Theme.ORANGE else Theme.SLATE_HI
			Theme.corner(row, 6)
			local name = Theme.text(
				def.name,
				UDim2.new(0.58, 0, 0, 24),
				if def.id == selected then Theme.BLACK else Theme.WHITE,
				Enum.Font.GothamBlack,
				20
			)
			name.Position = UDim2.fromOffset(12, 5)
			name.Parent = row
			local stats = Theme.text(
				string.format("%.1f st wide · %s kg", def.width, Theme.kg(def.pack)),
				UDim2.new(0.58, 0, 0, 18),
				if def.id == selected then Theme.SLATE else Theme.MUTED,
				Enum.Font.GothamBold,
				15
			)
			stats.Position = UDim2.fromOffset(12, 29)
			stats.Parent = row
			local tag = priceTag(Economy.price(def.price, fx), money, owned)
			tag.AnchorPoint = Vector2.new(1, 0.5)
			tag.Position = UDim2.new(1, -10, 0.5, 0)
			tag.Parent = row
			row.Activated:Connect(function()
				selected = def.id
				refresh()
			end)
			row.Parent = list
		end
		-- detail card
		for _, c in detail:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local def = Loadout.tool(selected) or Config.Tools[1]
		local cur = Loadout.tool(s.tool or "Toothbrush") or Config.Tools[1]
		local mine = Loadout.toolStats(def, s.packUps and s.packUps[def.id] == true, fx)
		local now = Loadout.toolStats(cur, s.packUps and s.packUps[cur.id] == true, fx)
		local title = Theme.text(string.upper(def.name), UDim2.new(1, 0, 0, 34), Theme.WHITE, Enum.Font.GothamBlack, 30)
		title.Parent = detail
		local tier = Theme.text(
			string.upper(def.look .. " tier" .. (if def.planet then " · " .. def.planet else "")),
			UDim2.new(1, 0, 0, 18),
			Theme.TEAL,
			Enum.Font.GothamBold,
			15
		)
		tier.Position = UDim2.fromOffset(0, 36)
		tier.Parent = detail
		local blurb = Theme.text(def.blurb, UDim2.new(1, 0, 0, 40), Theme.MUTED, Enum.Font.GothamBold, 17)
		blurb.Position = UDim2.fromOffset(0, 58)
		blurb.TextWrapped = true
		blurb.Parent = detail
		local function statRow(y: number, label: string, value: number, base: number, unit: string)
			local l = Theme.text(label, UDim2.new(0.4, 0, 0, 24), Theme.WHITE, Enum.Font.GothamBold, 19)
			l.Position = UDim2.fromOffset(0, y)
			l.Parent = detail
			local v = Theme.text(
				string.format("%.1f %s", value, unit),
				UDim2.new(0.3, 0, 0, 24),
				Theme.WHITE,
				Enum.Font.GothamBlack,
				20
			)
			v.Position = UDim2.new(0.4, 0, 0, y)
			v.Parent = detail
			local diff = value - base
			if math.abs(diff) > 0.01 then
				local d = Theme.text(
					string.format("%s%.1f", if diff > 0 then "+" else "", diff),
					UDim2.new(0.28, 0, 0, 24),
					if diff > 0 then Theme.GREEN else Theme.RED,
					Enum.Font.GothamBlack,
					20
				)
				d.Position = UDim2.new(0.72, 0, 0, y)
				d.Parent = detail
			end
		end
		statRow(108, "Width", mine.width, now.width, "st")
		statRow(136, "Reach", mine.reach, now.reach, "st")
		statRow(164, "Container", mine.pack, now.pack, "kg")
		local owned = s.tools and s.tools[def.id]
		local actions = Theme.frame(UDim2.new(1, 0, 0, 110), UDim2.new(0, 0, 1, -110), Theme.SLATE, 1)
		local al = Instance.new("UIListLayout")
		al.Padding = UDim.new(0, 8)
		al.Parent = actions
		actions.Parent = detail
		if not owned then
			local price = Economy.price(def.price, fx)
			local b = Theme.button(
				"BUY  " .. Theme.money(price),
				UDim2.new(1, 0, 0, 48),
				if money >= price then "Orange" else "Dark"
			)
			b.Activated:Connect(function()
				buy:FireServer("tool", def.id)
			end)
			b.Parent = actions
		else
			local row = Theme.frame(UDim2.new(1, 0, 0, 48), UDim2.new(), Theme.SLATE, 1)
			local rl = Instance.new("UIListLayout")
			rl.FillDirection = Enum.FillDirection.Horizontal
			rl.Padding = UDim.new(0, 6)
			rl.Parent = row
			for slot = 1, s.slots or 1 do
				local b = Theme.button(
					"SLOT " .. slot,
					UDim2.new(0, 84, 0, 46),
					if (s.belt or {})[slot] == def.id then "Green" else "Dark"
				)
				b.Activated:Connect(function()
					buy:FireServer("beltSet", def.id, slot)
				end)
				b.Parent = row
			end
			row.Parent = actions
		end
		if owned and not (s.packUps and s.packUps[def.id]) then
			local price = Economy.price(Economy.packUpgradeCost(def), fx)
			local b = Theme.button(
				string.format("BIGGER PACK  x2  %s", Theme.money(price)),
				UDim2.new(1, 0, 0, 44),
				if money >= price then "Orange" else "Dark"
			)
			b.Activated:Connect(function()
				buy:FireServer("packUp", def.id)
			end)
			b.Parent = actions
		end
		-- extras along the bottom
		for _, c in extras:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local function extra(text: string, price: number?, kind: string, id: string?)
			if not price then
				return
			end
			local p = Economy.price(price, fx)
			local b = Theme.button(
				string.format("%s  %s", text, Theme.money(p)),
				UDim2.new(0, 210, 0, 50),
				if money >= p then "Orange" else "Dark"
			)
			b.Activated:Connect(function()
				buy:FireServer(kind, id)
			end)
			b.Parent = extras
		end
		extra("BELT SLOT " .. tostring((s.slots or 1) + 1), Economy.slotPrice((s.slots or 1) + 1), "slot")
		extra("POD STRAP +1", Economy.carryPrice(s.carryBought or 0), "carry")
		if not s.buildTool then
			extra("BUILD TOOL", Config.BuildToolPrice, "buildTool")
		end
		for _, g in { "GravityBoots", "NightVision", "Jetpack" } do
			if not (s.gear and s.gear[g]) then
				local spec = (Config.Gear :: any)[g]
				extra(
					string.upper(
						if g == "GravityBoots" then "Gravity Boots" elseif g == "NightVision" then "Night Vision" else g
					),
					spec.price,
					"gear",
					g
				)
			end
		end
	end
	Menus.register("supply", card, refresh)
	State.changed(function()
		if openCard == card then
			refresh()
		end
	end)
end

---------------------------------------------------------------------------- upgrade board
local function upgradeBoard()
	local card, body = Theme.card(gui, "Upgrade Board", "Company upgrades", UDim2.fromScale(0.92, 0.86))
	local tabs = Theme.frame(UDim2.new(1, 0, 0, 44), UDim2.new(), Theme.SLATE, 1)
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.Padding = UDim.new(0, 6)
	tl.Parent = tabs
	tabs.Parent = body
	local counter = Theme.text("0 OF 56", UDim2.new(0, 160, 0, 30), Theme.TEAL, Enum.Font.GothamBlack, 22)
	counter.AnchorPoint = Vector2.new(1, 0)
	counter.Position = UDim2.new(1, 0, 0, 6)
	counter.TextXAlignment = Enum.TextXAlignment.Right
	counter.Parent = body
	local grid = Instance.new("ScrollingFrame")
	grid.Size = UDim2.new(0.6, -8, 1, -54)
	grid.Position = UDim2.new(0, 0, 0, 54)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.ScrollBarThickness = 6
	grid.ScrollBarImageColor3 = Theme.ORANGE
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = UDim2.new(0, 132, 0, 92)
	gl.CellPadding = UDim2.new(0, 8, 0, 8)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = grid
	grid.Parent = body
	local detail = Theme.frame(UDim2.new(0.4, -8, 1, -54), UDim2.new(0.6, 8, 0, 54), Theme.SLATE_HI)
	Theme.corner(detail, 8)
	Theme.pad(detail, 14)
	detail.Parent = body
	local tab = Config.UpgradeTabs[1]
	local selected = "WideHead"

	local function refresh()
		local s = State.get()
		local owned = s.upgrades or {}
		local money = s.money or 0
		local hasPackUp = s.packUps and next(s.packUps) ~= nil
		counter.Text = string.format("%d OF %d", Upgrades.nodesDone(owned), #Config.Upgrades)
		for _, c in tabs:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for _, name in Config.UpgradeTabs do
			local b =
				Theme.button(string.upper(name), UDim2.new(0, 120, 0, 40), if name == tab then "Orange" else "Dark")
			b.Activated:Connect(function()
				tab = name
				for _, def in Config.Upgrades do
					if def.tab == name then
						selected = def.id
						break
					end
				end
				refresh()
			end)
			b.Parent = tabs
		end
		for _, c in grid:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, def in Config.Upgrades do
			if def.tab ~= tab then
				continue
			end
			local level = owned[def.id] or 0
			local visible = Upgrades.visible(owned, def.id) or level > 0
			local ok = Upgrades.check(owned, def.id, { packUpgrade = hasPackUp })
			local node = Instance.new("TextButton")
			node.LayoutOrder = i
			node.AutoButtonColor = false
			node.Text = ""
			node.BackgroundColor3 = if def.id == selected
				then Theme.ORANGE
				elseif def.capstone then Color3.fromRGB(60, 50, 30)
				else Theme.SLATE_HI
			Theme.corner(node, 8)
			if def.capstone then
				Theme.stroke(node, Theme.AMBER, 2)
			end
			local name = Theme.text(
				if visible then def.name else "?",
				UDim2.new(1, -12, 0, 40),
				if def.id == selected then Theme.BLACK else Theme.WHITE,
				Enum.Font.GothamBlack,
				17
			)
			name.Position = UDim2.fromOffset(6, 6)
			name.TextWrapped = true
			name.Parent = node
			-- level pips
			for k = 1, def.max do
				local pip = Theme.frame(
					UDim2.new(0, 12, 0, 6),
					UDim2.new(0, 6 + (k - 1) * 15, 1, -30),
					if k <= level then Theme.TEAL else Theme.SLATE_LO
				)
				Theme.corner(pip, 2)
				pip.Parent = node
			end
			local status = Theme.text(
				if level >= def.max then "MAX" elseif ok then "READY" else "NEEDED",
				UDim2.new(1, -12, 0, 16),
				if level >= def.max then Theme.TEAL elseif ok then Theme.GREEN else Theme.RED,
				Enum.Font.GothamBlack,
				13
			)
			status.Position = UDim2.new(0, 6, 1, -20)
			status.Parent = node
			node.Activated:Connect(function()
				selected = def.id
				refresh()
			end)
			node.Parent = grid
		end
		for _, c in detail:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local def = Upgrades.get(selected) :: Config.UpgradeDef
		local level = owned[def.id] or 0
		local visible = Upgrades.visible(owned, def.id) or level > 0
		local title = Theme.text(
			if visible then string.upper(def.name) else "LOCKED",
			UDim2.new(1, 0, 0, 32),
			Theme.WHITE,
			Enum.Font.GothamBlack,
			28
		)
		title.Parent = detail
		local lv = Theme.text(
			string.format("LEVEL %d / %d%s", level, def.max, if def.capstone then "  ·  CAPSTONE" else ""),
			UDim2.new(1, 0, 0, 18),
			Theme.TEAL,
			Enum.Font.GothamBold,
			15
		)
		lv.Position = UDim2.fromOffset(0, 36)
		lv.Parent = detail
		local text = Theme.text(
			if visible then def.text else "Buy what this needs to reveal it.",
			UDim2.new(1, 0, 0, 60),
			Theme.MUTED,
			Enum.Font.GothamBold,
			18
		)
		text.TextWrapped = true
		text.Position = UDim2.fromOffset(0, 60)
		text.Parent = detail
		local y = 126
		local needs: { [string]: number } = def.needs or {}
		for needId, needLevel in needs do
			local have = if needId == "@packUpgrade" then (if hasPackUp then 1 else 0) else owned[needId] or 0
			local needName = if needId == "@packUpgrade"
				then "A Bigger Pack"
				else ((Upgrades.get(needId) :: Config.UpgradeDef).name .. " " .. needLevel)
			local met = have >= needLevel
			local r = Theme.text(
				(if met then "READY  " else "NEEDED  ") .. needName,
				UDim2.new(1, 0, 0, 20),
				if met then Theme.GREEN else Theme.RED,
				Enum.Font.GothamBlack,
				16
			)
			r.Position = UDim2.fromOffset(0, y)
			r.Parent = detail
			y += 24
		end
		local ok, why, price = Upgrades.check(owned, def.id, { packUpgrade = hasPackUp })
		local b = Theme.button(
			if level >= def.max then "MAXED" elseif ok then "BUY  " .. Theme.money(price) else string.upper(why),
			UDim2.new(1, 0, 0, 52),
			if ok and money >= price then "Orange" else "Dark"
		)
		b.AnchorPoint = Vector2.new(0, 1)
		b.Position = UDim2.new(0, 0, 1, 0)
		b.Activated:Connect(function()
			if ok then
				buy:FireServer("upgrade", def.id)
			end
		end)
		b.Parent = detail
	end
	Menus.register("board", card, refresh)
	State.changed(function()
		if openCard == card then
			refresh()
		end
	end)
end

---------------------------------------------------------------------------- teleport
local function teleportMenu()
	local card, body = Theme.card(gui, "Station Link", "Teleport", UDim2.fromScale(0.6, 0.8))
	local list = Theme.list(body, UDim2.fromScale(1, 1))
	local tp = Remotes.get("Teleport")
	local function refresh()
		local s = State.get()
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local here = if root then Places.dirOf(root.Position) else Vector3.yAxis
		local price = Economy.teleportPrice(s.fx)
		for _, st in Places.stations do
			local dist = Places.arc(here, st.dir)
			local row = Theme.frame(UDim2.new(1, -8, 0, 52), UDim2.new(), Theme.SLATE_HI)
			row.LayoutOrder = st.index
			Theme.corner(row, 6)
			local name = Theme.text(
				string.upper(st.name) .. " STATION",
				UDim2.new(0.5, 0, 1, 0),
				Theme.WHITE,
				Enum.Font.GothamBlack,
				20
			)
			name.Position = UDim2.fromOffset(12, 0)
			name.Parent = row
			local d = Theme.text(
				if dist < 120 then "YOU ARE HERE" else string.format("%.1f km", dist * 0.28 / 1000),
				UDim2.new(0.22, 0, 1, 0),
				Theme.MUTED,
				Enum.Font.GothamBold,
				16
			)
			d.Position = UDim2.new(0.5, 0, 0, 0)
			d.Parent = row
			if dist >= 120 then
				local b = Theme.button(
					"GO  " .. Theme.money(price),
					UDim2.new(0, 120, 0, 40),
					if (s.money or 0) >= price then "Orange" else "Dark"
				)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -8, 0.5, 0)
				b.Activated:Connect(function()
					tp:FireServer(st.index)
					close()
				end)
				b.Parent = row
			end
			row.Parent = list
		end
	end
	Menus.register("teleport", card, refresh)
end

---------------------------------------------------------------------------- field manual
local function fieldManual()
	local card, body = Theme.card(gui, "Field Manual", "Sector report", UDim2.fromScale(0.6, 0.76))
	local text = Theme.text("", UDim2.fromScale(1, 1), Theme.WHITE, Enum.Font.GothamBold, 20)
	text.TextScaled = false
	text.TextSize = 18
	text.TextWrapped = true
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.RichText = true
	text.Parent = body
	local function refresh()
		local s = State.get()
		local id = MoonView.current()
		local dir = MoonView.sector:position(math.max(id, 0))
		local lat = math.deg(math.asin(math.clamp(dir.Y, -1, 1)))
		local lon = math.deg(math.atan2(dir.Z, dir.X))
		local state = MoonView.state(id)
		local reward = Economy.sectorReward(Sweep.angleFromNorth(dir), s.fx)
		local station, arc = Places.nearestStation(dir)
		local lines = {
			string.format(
				"<b>SECTOR %d</b>   %.2f%s %s, %.2f%s %s",
				id,
				math.abs(lat),
				"°",
				if lat >= 0 then "N" else "S",
				math.abs(lon),
				"°",
				if lon >= 0 then "E" else "W"
			),
			string.format(
				"State: <font color='#%s'>%s</font>   Cleaned: %d%%",
				if state == 2 then "40E0D0" elseif state == 1 then "4696FF" else "FF7A1E",
				if state == 2 then "COMPLETE" elseif state == 1 then "STARTED" else "UNTOUCHED",
				math.floor(MoonView.progress(id) * 100)
			),
			string.format("Reward when cleaned: <b>+%s</b>", Theme.money(reward)),
			string.format("Nearest station: %s, %.2f km", station.name, arc * 0.28 / 1000),
			string.format("Moon cleaned: %.3f%% of %d sectors", MoonView.cleanPct(), MoonView.sector.count),
			"",
			"<b>HOW THE JOB WORKS</b>",
			"Hold to brush and walk over the dust. Your Dust Pack fills in kg.",
			"Press Q to pack it into a pod. Carry pods to a Dust Drum in any station and deposit them: we launch them home and pay you.",
			"Finish a sector (the gold outline) for a bonus. Finish a whole region for a bigger one.",
			"Steep crater walls hold Stardust, worth five times more. Only brooms reach it.",
		}
		if s.fx and s.fx.manualPlus then
			table.insert(
				lines,
				6,
				string.format(
					"Region bonus: +%s. Stardust here: %s",
					Theme.money(Economy.regionReward(s.fx)),
					"check the slopes"
				)
			)
		end
		text.Text = table.concat(lines, "\n")
	end
	Menus.register("manual", card, refresh)
end

---------------------------------------------------------------------------- hiring talk
local BOSS_LINES = {
	"Welcome to Moon Mop Co., the cheapest cleaning contractor on the Moon.",
	"Your job is to clean the Moon. All of it. Every single sector.",
	"The budget covered exactly one toothbrush. Here it is. Please don't lose it.",
	"Brush the dust and your Dust Pack fills up. Press Q to pack it into a pod.",
	"Drop pods in the Dust Drum. We launch them home with the Pod Cannon and pay you.",
	"Finish a sector and you get a bonus. Buy better brooms at the supply wall.",
	"Stop standing there. You've got a whole Moon to clean.",
}

local function bossTalk()
	local card, body = Theme.card(gui, "Boss Bot", "Moon Mop Co. management", UDim2.fromScale(0.7, 0.5))
	local line = Theme.text("", UDim2.new(1, 0, 0.62, 0), Theme.WHITE, Enum.Font.GothamBold, 26)
	line.TextWrapped = true
	line.TextYAlignment = Enum.TextYAlignment.Top
	line.Parent = body
	local nextButton = Theme.button("NEXT", UDim2.new(0, 160, 0, 52), "Orange")
	nextButton.AnchorPoint = Vector2.new(1, 1)
	nextButton.Position = UDim2.fromScale(1, 1)
	nextButton.Parent = body
	local index = 1
	local contract = Theme.frame(UDim2.fromScale(1, 1), UDim2.new(), Color3.fromRGB(240, 234, 216))
	contract.Visible = false
	Theme.corner(contract, 6)
	Theme.pad(contract, 16)
	contract.Parent = body
	local cText = Theme.text(
		"EMPLOYMENT CONTRACT\n\n1. You will clean the Moon.\n2. The toothbrush remains company property.\n3. Breathing is permitted on breaks.\n4. Pay is per kilogram. Feelings are unpaid.",
		UDim2.new(1, 0, 0.75, 0),
		Theme.SLATE_LO,
		Enum.Font.GothamBold,
		22
	)
	cText.TextYAlignment = Enum.TextYAlignment.Top
	cText.TextWrapped = true
	cText.Parent = contract
	local sign = Theme.button("SIGN", UDim2.new(0, 180, 0, 52), "Orange")
	sign.AnchorPoint = Vector2.new(1, 1)
	sign.Position = UDim2.fromScale(1, 1)
	sign.Parent = contract
	local function refresh()
		index = 1
		contract.Visible = false
		line.Text = BOSS_LINES[1]
		State.emit("BossTalk", true)
	end
	nextButton.Activated:Connect(function()
		index += 1
		if index > #BOSS_LINES then
			if State.get().hired then
				close()
				State.emit("BossTalk", false)
			else
				contract.Visible = true
			end
		else
			line.Text = BOSS_LINES[index]
		end
	end)
	sign.Activated:Connect(function()
		Remotes.get("Story"):FireServer("hired")
		Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.6)
		close()
		State.emit("BossTalk", false)
		Hud.toast("Hired! Grab your toothbrush and get brushing.", Theme.GREEN)
	end)
	Menus.register("boss", card, refresh)
	local closeButton = card:FindFirstChild("Close") :: TextButton?
	if closeButton then
		closeButton.Activated:Connect(function()
			State.emit("BossTalk", false)
		end)
	end
end

function Menus.start()
	gui = Theme.screen("Menus", player:WaitForChild("PlayerGui"), 5)
	supplyWall()
	upgradeBoard()
	teleportMenu()
	fieldManual()
	bossTalk()

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local menu = prompt:GetAttribute("Menu") :: string?
		if menu then
			if menu == "map" then
				State.emit("OpenMenu", "map")
			else
				open(menu)
			end
		end
	end)
	State.onFeedback(function(kind: string, data: any)
		if kind == "OpenMenu" and data ~= "map" then
			open(data)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.H then
			if openCard == cards.manual then
				close()
			else
				open("manual")
			end
		elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			close()
		end
	end)
	-- First visit: the Boss Bot hires you.
	local hireShown = false
	State.changed(function(s)
		if s.hired == false and not hireShown then
			hireShown = true
			task.delay(1.5, function()
				if not State.get().hired then
					open("boss")
				end
			end)
		end
	end)
end

return Menus
