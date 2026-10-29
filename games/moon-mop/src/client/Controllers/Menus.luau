--!strict
-- Station menus, laid out like the original's (P1 f_003 supply wall, f_145 upgrades; d_0014
-- field manual): a title panel and a money panel on top, a list panel and a detail panel
-- below, key hints underneath, the world blurred behind. This module owns opening and closing
-- (blur, free cursor, HUD menu flag) and builds the supply wall, the upgrade board, the station
-- link and the field manual. Menus only ask; the server checks every purchase.

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

local Brooms = require(script.Parent.Brooms)
local Hud = require(script.Parent.Hud)
local Juice = require(script.Parent.Juice)
local MoonView = require(script.Parent.MoonView)
local Movement = require(script.Parent.Movement)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Menus = {}

local player = Players.LocalPlayer
local buy = Remotes.get("Buy")
local gui: ScreenGui
local openCard: Frame? = nil
local openName: string? = nil
local openedAt = 0
local refreshers: { [string]: () -> () } = {}
local cards: { [string]: Frame } = {}
-- Enter / Return runs the open menu's main action, when it has one.
local primary: { [string]: () -> () } = {}

local function close()
	if openCard then
		openCard.Visible = false
		openCard = nil
		openName = nil
	end
	Theme.setBlur(false)
	Movement.freeCursor("menu", false)
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
	openName = name
	openedAt = os.clock()
	Hud.setMenuOpen(true)
	Theme.setBlur(true)
	Movement.freeCursor("menu", true)
	local r = refreshers[name]
	if r then
		r()
	end
	Juice.popIn(card)
	Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.12)
end
Menus.open = open

function Menus.isOpen(name: string): boolean
	return openName == name
end

function Menus.register(name: string, card: Frame, refresh: () -> (), action: (() -> ())?)
	cards[name] = card
	refreshers[name] = refresh
	if action then
		primary[name] = action
	end
	local closeButton = card:FindFirstChild("Close", true) :: TextButton?
	if closeButton then
		closeButton.Activated:Connect(close)
	end
end

local function cash(label: TextLabel)
	label.Text = Theme.cash(State.get().money or 0)
end

-- "+8% cleaning width" at level n: scale the first number in the text.
local function effectText(text: string, levels: number): string
	local out = string.gsub(text, "%d+%.?%d*", function(n: string)
		local v = (tonumber(n) or 0) * levels
		return if v == math.floor(v) then tostring(v) else string.format("%.1f", v)
	end, 1)
	return out
end

local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }

---------------------------------------------------------------------------- supply wall
type GearItem = {
	id: string,
	name: string,
	text: string,
	price: number?,
	owned: boolean,
	status: string,
	kind: string,
	arg: string?,
	glyph: string,
}

local function gearItems(s: { [string]: any }): { GearItem }
	local items: { GearItem } = {}
	local slots = s.slots or 1
	local slotPrice = Economy.slotPrice(slots + 1)
	table.insert(items, {
		id = "slot",
		name = "Tool Belt",
		text = "One more slot on your tool belt. Press 1 to 6 to swap tools.",
		price = slotPrice,
		owned = slotPrice == nil,
		status = string.format("Slot %d", slots + (if slotPrice then 1 else 0)),
		kind = "slot",
		glyph = "+",
	})
	local carryPrice = Economy.carryPrice(s.carryBought or 0)
	table.insert(items, {
		id = "carry",
		name = "Pod Strap",
		text = "Carry one more dust pod at a time.",
		price = carryPrice,
		owned = carryPrice == nil,
		status = string.format("Carry %d", s.carry or 3),
		kind = "carry",
		glyph = "◎",
	})
	table.insert(items, {
		id = "buildTool",
		name = "Build Tool",
		text = "A hammer for building your Mop Base: belts, machines, robots. Press B to use it.",
		price = Config.BuildToolPrice,
		owned = s.buildTool == true,
		status = if s.buildTool then "Owned" else "Not owned",
		kind = "buildTool",
		glyph = "⚒",
	})
	local gear = s.gear or {}
	for _, g in
		{
			{ "Jetpack", "Forward Jetpack", "Hold jump in the air to fly." },
			{ "GravityBoots", "Gravity Boots", "Walk faster on the dust." },
			{ "NightVision", "Night Vision", "See in the dark on the night side." },
		}
	do
		local spec = (Config.Gear :: any)[g[1]] -- Config.Gear mixes gear specs and suit lists
		table.insert(items, {
			id = g[1],
			name = g[2],
			text = g[3],
			price = spec.price,
			owned = gear[g[1]] == true,
			status = if gear[g[1]] then "Owned" else "Not owned",
			kind = "gear",
			arg = g[1],
			glyph = if g[1] == "Jetpack" then "▲" elseif g[1] == "GravityBoots" then "▼" else "◉",
		})
	end
	return items
end

local function supplyWall()
	local m = Theme.stationMenu(gui, "Supply Wall")
	-- two insets: tools on the left, gears on the right (P1 f_003)
	m.body.Size = UDim2.fromOffset(492, 472)
	local toolsTab =
		Theme.label("TOOLS", 10, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(80, 22), UDim2.fromOffset(35, 14))
	toolsTab.Parent = m.main
	local gearsTab =
		Theme.label("GEARS", 10, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(80, 22), UDim2.fromOffset(543, 14))
	gearsTab.Parent = m.main
	local gearsBox = Theme.inset(m.main, UDim2.fromOffset(237, 472), UDim2.fromOffset(524, 36))
	local grid = Instance.new("ScrollingFrame")
	grid.Size = UDim2.new(1, -12, 1, -12)
	grid.Position = UDim2.fromOffset(6, 6)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 4
	grid.ScrollBarImageColor3 = Theme.ORANGE
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = UDim2.fromOffset(113, 168)
	gl.CellPadding = UDim2.fromOffset(6, 6)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = grid
	grid.Parent = m.body
	local gears = Theme.list(gearsBox, UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6), 4)
	local foot = Theme.label("", 11, Theme.WHITE, Theme.F.semi, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16))
	Theme.setHints(m.hints, {
		{ "1", "2", "Belt slot" },
		{ "Enter", "Buy or take" },
		{ "LMB", "Choose" },
		{ "E", "Leave" },
	})
	local selected = "Toothbrush"
	local action: (() -> ())? = nil

	local function refresh()
		local s = State.get()
		local fx = s.fx or {}
		local money = s.money or 0
		cash(m.money)
		local belt = s.belt or {}
		local function slotOf(id: string): number?
			for i, b in belt do
				if b == id then
					return i
				end
			end
			return nil
		end
		Theme.clear(grid)
		for i, def in Config.Tools do
			local owned = s.tools and s.tools[def.id]
			local sel = def.id == selected
			local cell = Theme.cell(UDim2.fromOffset(113, 168), Theme.INNER)
			cell.BackgroundTransparency = 1
			cell.LayoutOrder = i
			local icon = Theme.icon3d(Brooms.model(def.id), UDim2.fromOffset(113, 112), UDim2.fromOffset(0, 18), 60, 20)
			icon.Parent = cell
			local chip = Theme.frame(
				UDim2.fromOffset(107, 22),
				UDim2.fromOffset(3, 133),
				if sel then Theme.ORANGE else Theme.ROW
			)
			Theme.corner(chip, 3)
			local n =
				Theme.label(def.name, 10, Theme.WHITE, Theme.F.bold, UDim2.new(1, -6, 1, 0), UDim2.fromOffset(3, 0))
			n.TextXAlignment = Enum.TextXAlignment.Center
			n.TextScaled = #def.name > 17
			n.Parent = chip
			chip.Parent = cell
			local bar = Theme.frame(UDim2.fromOffset(119, 5), UDim2.fromOffset(-3, 160), Theme.ORANGE)
			bar.Parent = cell
			if owned then
				local slot = slotOf(def.id)
				local t = Theme.label(
					if slot then string.format("SLOT %d", slot) else "OWNED",
					9,
					Theme.TEAL,
					Theme.F.bold,
					UDim2.fromOffset(60, 18),
					UDim2.fromOffset(28, 8)
				)
				t.BackgroundColor3 = Theme.ROW
				t.BackgroundTransparency = 0
				t.TextXAlignment = Enum.TextXAlignment.Center
				Theme.corner(t, 3)
				t.Parent = cell
			else
				local price = Economy.price(def.price, fx)
				local tag = Theme.luggage(Theme.money(price), if money + 1e-6 >= price then "Good" else "Bad", -7)
				tag.AnchorPoint = Vector2.new(1, 0)
				tag.Position = UDim2.fromOffset(110, 6)
				tag.Parent = cell
			end
			cell.Activated:Connect(function()
				selected = def.id
				refresh()
			end)
			cell.Parent = grid
		end
		-- gears column
		Theme.clear(gears)
		local items = gearItems(s)
		for i, g in items do
			local sel = selected == "gear:" .. g.id
			local row = Theme.cell(UDim2.new(1, 0, 0, 74), Theme.INNER)
			row.BackgroundTransparency = 1
			row.LayoutOrder = i
			local disc = Theme.frame(UDim2.fromOffset(44, 44), UDim2.fromOffset(6, 10), Color3.fromRGB(58, 64, 72))
			Theme.corner(disc, 22)
			Theme.stroke(disc, Color3.fromRGB(90, 98, 108), 2)
			local gl2 = Theme.label(g.glyph, 22, Theme.WHITE, Theme.F.bold, UDim2.fromScale(1, 1))
			gl2.TextXAlignment = Enum.TextXAlignment.Center
			gl2.Parent = disc
			disc.Parent = row
			local n =
				Theme.label(g.name, 14, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(150, 18), UDim2.fromOffset(60, 14))
			n.Parent = row
			local chip = Theme.frame(
				UDim2.fromOffset(120, 20),
				UDim2.fromOffset(60, 38),
				if sel then Theme.ORANGE else Theme.ROW
			)
			Theme.corner(chip, 3)
			local st = Theme.label(
				g.status,
				10,
				if g.owned then Theme.TEAL else Theme.MUTED,
				Theme.F.semi,
				UDim2.fromScale(1, 1)
			)
			if sel then
				st.TextColor3 = Theme.WHITE
			end
			st.TextXAlignment = Enum.TextXAlignment.Center
			st.Parent = chip
			chip.Parent = row
			local bar = Theme.frame(UDim2.new(1, 0, 0, 5), UDim2.new(0, 0, 1, -5), Theme.ORANGE)
			bar.Parent = row
			if g.price and not g.owned then
				local price = Economy.price(g.price, fx)
				local tag = Theme.luggage(Theme.money(price), if money >= price then "Good" else "Bad", -7)
				tag.AnchorPoint = Vector2.new(1, 0)
				tag.Position = UDim2.new(1, -4, 0, 0)
				tag.Parent = row
			end
			row.Activated:Connect(function()
				selected = "gear:" .. g.id
				refresh()
			end)
			row.Parent = gears
		end

		-- detail card
		Theme.clear(m.detail)
		action = nil
		if string.sub(selected, 1, 5) == "gear:" then
			local gid = string.sub(selected, 6)
			local g: GearItem? = nil
			for _, it in items do
				if it.id == gid then
					g = it
				end
			end
			if not g then
				return
			end
			local gi = g :: GearItem
			Theme.detailHead(m.detail, "Gear", gi.name, gi.text)
			Theme.statRow(m.detail, 150, "Status", gi.status)
			if gi.price and not gi.owned then
				local price = Economy.price(gi.price, fx)
				Theme.statRow(m.detail, 186, "Price", Theme.money(price), if money >= price then nil else Theme.RED)
				local function buyIt()
					buy:FireServer(gi.kind, gi.arg)
				end
				local b = Theme.action(m.detail, "BUY  " .. Theme.money(price), money >= price, 300)
				b.Activated:Connect(buyIt)
				action = buyIt
				local note = Theme.label(
					if money >= price
						then string.format("Leaves %s in your wallet.", Theme.money(money - price))
						else string.format("You need %s more.", Theme.money(price - money)),
					11,
					if money >= price then Theme.MUTED else Theme.RED,
					Theme.F.semi,
					UDim2.new(1, 0, 0, 16),
					UDim2.fromOffset(0, 360)
				)
				note.Parent = m.detail
			else
				Theme.action(m.detail, if gi.owned then "OWNED" else "MAXED", false, 300)
			end
			return
		end
		local def = Loadout.tool(selected) or Config.Tools[1]
		local cur = Loadout.tool(belt[1] or "Toothbrush") or Config.Tools[1]
		local mine = Loadout.toolStats(def, s.packUps and s.packUps[def.id] == true, fx)
		local base = Loadout.toolStats(cur, s.packUps and s.packUps[cur.id] == true, fx)
		local category = if def.look == "Junk"
			then "Cleaning tool"
			elseif def.planet then string.format("%s broom  ·  %s tier", def.planet, def.look)
			else string.format("%s tier broom", def.look)
		Theme.detailHead(
			m.detail,
			category,
			def.name,
			def.blurb,
			Theme.icon3d(Brooms.model(def.id), UDim2.fromScale(1, 1), nil, 60, 20)
		)
		local function delta(a: number, b: number, unit: (number) -> string): string
			local d = a - b
			if math.abs(d) < 0.005 then
				return unit(a)
			end
			return string.format(
				"%s   <font color='#%s'>%s%s</font>",
				unit(a),
				if d > 0 then "5BE27F" else "FF5A4E",
				if d > 0 then "+" else "-",
				unit(math.abs(d))
			)
		end
		local owned = s.tools and s.tools[def.id]
		local slot = slotOf(def.id)
		local rows = {
			{ "Width", delta(mine.width, base.width, Theme.metres) },
			{ "Reach", delta(mine.reach, base.reach, Theme.metres) },
			{ "Container", delta(mine.pack, base.pack, Theme.mass) },
			{
				"Where",
				if slot then string.format("Slot %d", slot) elseif owned then "In the locker" else "On the wall",
			},
		}
		for i, r in rows do
			local row = Theme.statRow(m.detail, 140 + (i - 1) * 36, r[1], r[2])
			local v = row:FindFirstChild("Value") :: TextLabel
			v.RichText = true
		end
		local against = Theme.label(
			string.format("AGAINST SLOT 1: %s", string.upper(cur.name)),
			9,
			Theme.MUTED,
			Theme.F.bold,
			UDim2.new(1, 0, 0, 14),
			UDim2.fromOffset(0, 286)
		)
		against.Parent = m.detail
		if not owned then
			local price = Economy.price(def.price, fx)
			local function buyIt()
				buy:FireServer("tool", def.id)
			end
			local b = Theme.action(m.detail, "BUY  " .. Theme.money(price), money >= price, 310)
			b.Activated:Connect(buyIt)
			action = buyIt
			local note = Theme.label(
				if money >= price
					then string.format("Leaves %s in your wallet.", Theme.money(money - price))
					else string.format("You need %s more.", Theme.money(price - money)),
				11,
				if money >= price then Theme.MUTED else Theme.RED,
				Theme.F.semi,
				UDim2.new(1, 0, 0, 16),
				UDim2.fromOffset(0, 368)
			)
			note.Parent = m.detail
		else
			Theme.action(m.detail, if slot then string.format("IN SLOT %d", slot) else "IN THE LOCKER", false, 310)
			-- put it on a belt slot
			local row = Theme.frame(UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 368), Theme.PANEL, 1)
			local rl = Instance.new("UIListLayout")
			rl.FillDirection = Enum.FillDirection.Horizontal
			rl.Padding = UDim.new(0, 6)
			rl.Parent = row
			for n = 1, s.slots or 1 do
				local b = Theme.button(
					string.format("Slot %d", n),
					UDim2.fromOffset(62, 32),
					if belt[n] == def.id then "Green" else "Dark"
				)
				b.Activated:Connect(function()
					buy:FireServer("beltSet", def.id, n)
				end)
				b.Parent = row
			end
			row.Parent = m.detail
			action = function()
				buy:FireServer("beltSet", def.id, 1)
			end
			if not (s.packUps and s.packUps[def.id]) then
				local price = Economy.price(Economy.packUpgradeCost(def), fx)
				local b = Theme.button(
					string.format("Bigger container  x2   %s", Theme.money(price)),
					UDim2.new(1, 0, 0, 34),
					if money >= price then "Dark" else "Gray"
				)
				b.Position = UDim2.fromOffset(0, 410)
				b.Activated:Connect(function()
					buy:FireServer("packUp", def.id)
				end)
				b.Parent = m.detail
			end
		end
		foot.Text = string.format("%s in slot 1.", cur.name)
		foot.Parent = m.detail
	end
	Menus.register("supply", m.root, refresh, function()
		if action then
			action()
		end
	end)
	State.changed(function()
		if openCard == m.root then
			refresh()
		end
	end)
	-- 1-6 put the selected tool on that belt slot while the wall is open
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or openCard ~= m.root then
			return
		end
		local k = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
		if k >= 1 and k <= 6 and Loadout.tool(selected) then
			buy:FireServer("beltSet", selected, k)
		end
	end)
end

---------------------------------------------------------------------------- upgrade board
local TAB_GLYPH: { [string]: string } = {
	Cleaning = "⌇",
	Storage = "▣",
	Market = "$",
	Machines = "⚙",
	Crew = "☺",
}

local function upgradeBoard()
	local m = Theme.stationMenu(gui, "Upgrades")
	m.counterLabel.Text = "INSTALLED"
	Theme.setHints(m.hints, {
		{ "W", "S", "Choose" },
		{ "A", "D", "Branches" },
		{ "Enter", "Install" },
		{ "E", "Leave" },
	})
	local list = Theme.list(m.body, UDim2.new(1, -16, 1, -16), UDim2.fromOffset(8, 8), 7)
	local tab = Config.UpgradeTabs[1]
	local selected = "WideHead"
	local action: (() -> ())? = nil
	local refresh: () -> ()

	local function tabDefs(): { Config.UpgradeDef }
		local out = {}
		for _, def in Config.Upgrades do
			if def.tab == tab then
				table.insert(out, def)
			end
		end
		return out
	end

	local function pickTab(name: string)
		tab = name
		local defs = tabDefs()
		if defs[1] then
			selected = defs[1].id
		end
		refresh()
	end

	function refresh()
		local s = State.get()
		local owned = s.upgrades or {}
		local money = s.money or 0
		local hasPackUp = s.packUps and next(s.packUps) ~= nil
		cash(m.money)
		m.counter.Text = string.format("%d / %d", Upgrades.nodesDone(owned), #Config.Upgrades)
		Theme.setTabs(m.tabs, Config.UpgradeTabs, tab, pickTab)
		Theme.clear(list)
		for i, def in tabDefs() do
			local level = owned[def.id] or 0
			local visible = Upgrades.visible(owned, def.id) or level > 0
			local ok, _, price = Upgrades.check(owned, def.id, { packUpgrade = hasPackUp })
			local sel = def.id == selected
			local row = Theme.cell(UDim2.new(1, -6, 0, 32), if sel then Theme.ORANGE else Theme.ROW)
			row.LayoutOrder = i
			Theme.corner(row, 3)
			local dim = not ok and level < def.max
			local glyph = Theme.label(
				if visible then (TAB_GLYPH[def.tab] or "•") else "?",
				14,
				if sel then Theme.WHITE elseif dim then Theme.DIM else Theme.MUTED,
				Theme.F.bold,
				UDim2.fromOffset(24, 32),
				UDim2.fromOffset(10, 0)
			)
			glyph.TextXAlignment = Enum.TextXAlignment.Center
			glyph.Parent = row
			local name = Theme.label(
				if visible then def.name else "?",
				13,
				if sel then Theme.WHITE elseif dim then Theme.DIM else Theme.WHITE,
				Theme.F.bold,
				UDim2.fromOffset(380, 32),
				UDim2.fromOffset(42, 0)
			)
			name.Parent = row
			if def.capstone then
				local cap = Theme.label(
					"CAPSTONE",
					8,
					if sel then Theme.WHITE else Theme.AMBER,
					Theme.F.bold,
					UDim2.fromOffset(80, 32),
					UDim2.fromOffset(300, 0)
				)
				cap.Parent = row
			end
			Theme.pips(row, def.max, level, UDim2.new(0, 525, 0.5, 0), sel)
			if level >= def.max then
				local t = Theme.label(
					"MAX",
					10,
					if sel then Theme.WHITE else Theme.TEAL,
					Theme.F.bold,
					UDim2.fromOffset(80, 32),
					UDim2.new(1, -92, 0, 0)
				)
				t.TextXAlignment = Enum.TextXAlignment.Right
				t.Parent = row
			elseif ok then
				local tag = Theme.luggage(Theme.money(price), if money >= price then "Good" else "Bad")
				tag.AnchorPoint = Vector2.new(1, 0.5)
				tag.Position = UDim2.new(1, -6, 0.5, 0)
				tag.Parent = row
			else
				local t = Theme.label(
					"LOCKED",
					10,
					if sel then Theme.WHITE else Theme.MUTED,
					Theme.F.bold,
					UDim2.fromOffset(80, 32),
					UDim2.new(1, -92, 0, 0)
				)
				t.TextXAlignment = Enum.TextXAlignment.Right
				t.Parent = row
			end
			row.Activated:Connect(function()
				selected = def.id
				refresh()
			end)
			row.Parent = list
		end

		Theme.clear(m.detail)
		action = nil
		local def = Upgrades.get(selected) :: Config.UpgradeDef
		local level = owned[def.id] or 0
		local visible = Upgrades.visible(owned, def.id) or level > 0
		local icon = Theme.label(TAB_GLYPH[def.tab] or "•", 46, Theme.WHITE, Theme.F.bold, UDim2.fromScale(1, 1))
		icon.TextXAlignment = Enum.TextXAlignment.Center
		Theme.detailHead(
			m.detail,
			def.tab .. (if def.capstone then "  ·  capstone" else ""),
			if visible then def.name else "Hidden upgrade",
			if visible then def.text else "Install what this needs to reveal it.",
			icon
		)
		local ok, why, price = Upgrades.check(owned, def.id, { packUpgrade = hasPackUp })
		Theme.statRow(
			m.detail,
			150,
			"Level",
			if level > 0 then string.format("%d / %d", level, def.max) else "Not installed"
		)
		Theme.statRow(m.detail, 186, "Now", if level > 0 and visible then effectText(def.text, level) else "—")
		Theme.statRow(
			m.detail,
			222,
			"Next",
			if level >= def.max then "—" elseif visible then effectText(def.text, level + 1) else "?"
		)
		Theme.statRow(
			m.detail,
			258,
			"Cost",
			if level >= def.max then "—" elseif ok then Theme.money(price) else "—",
			if ok and money < price then Theme.RED else nil
		)
		local y = 300
		local needs: { [string]: number } = def.needs or {}
		if next(needs) then
			local req =
				Theme.label("REQUIRES", 9, Theme.MUTED, Theme.F.bold, UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, y))
			req.Parent = m.detail
			y += 18
			for needId, needLevel in needs do
				local have = if needId == "@packUpgrade" then (if hasPackUp then 1 else 0) else owned[needId] or 0
				local needName = if needId == "@packUpgrade"
					then "A bigger tool container"
					else string.format("%s level %d", (Upgrades.get(needId) :: Config.UpgradeDef).name, needLevel)
				local met = have >= needLevel
				local r = Theme.label(
					string.format(
						"<font color='#%s'><b>%s</b></font>   %s",
						if met then "5BE27F" else "FF5A4E",
						if met then "READY" else "NEEDED",
						needName
					),
					12,
					Theme.WHITE,
					Theme.F.semi,
					UDim2.new(1, 0, 0, 18),
					UDim2.fromOffset(0, y)
				)
				r.RichText = true
				r.Parent = m.detail
				y += 20
			end
		end
		local function install()
			if ok then
				buy:FireServer("upgrade", def.id)
			end
		end
		local label = if level >= def.max
			then "MAXED"
			elseif not ok then "LOCKED"
			else string.format(
				"INSTALL LEVEL %s   %s",
				ROMAN[level + 1] or tostring(level + 1),
				Theme.money(price)
			)
		local b = Theme.action(m.detail, label, ok and money >= price, 394)
		b.Activated:Connect(install)
		action = install
		local note = Theme.label(
			if level >= def.max
				then "Fully installed."
				elseif not ok then why
				elseif money >= price then string.format("Leaves %s in team funds.", Theme.money(money - price))
				else string.format("You need %s more.", Theme.money(price - money)),
			11,
			if ok and money < price then Theme.RED else Theme.MUTED,
			Theme.F.semi,
			UDim2.new(1, 0, 0, 16),
			UDim2.fromOffset(0, 452)
		)
		note.Parent = m.detail
	end

	Menus.register("board", m.root, refresh, function()
		if action then
			action()
		end
	end)
	State.changed(function()
		if openCard == m.root then
			refresh()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or openCard ~= m.root then
			return
		end
		local k = input.KeyCode
		if k == Enum.KeyCode.W or k == Enum.KeyCode.S or k == Enum.KeyCode.Up or k == Enum.KeyCode.Down then
			local defs = tabDefs()
			for i, d in defs do
				if d.id == selected then
					local n = i + (if k == Enum.KeyCode.W or k == Enum.KeyCode.Up then -1 else 1)
					if defs[n] then
						selected = defs[n].id
						refresh()
					end
					break
				end
			end
		elseif k == Enum.KeyCode.A or k == Enum.KeyCode.D or k == Enum.KeyCode.Left or k == Enum.KeyCode.Right then
			local idx = table.find(Config.UpgradeTabs, tab) or 1
			local n = idx + (if k == Enum.KeyCode.A or k == Enum.KeyCode.Left then -1 else 1)
			if Config.UpgradeTabs[n] then
				pickTab(Config.UpgradeTabs[n])
			end
		end
	end)
end

---------------------------------------------------------------------------- station link
local function teleportMenu()
	local root, body = Theme.card(gui, "Station Link", "Teleport", UDim2.fromScale(0.5, 0.74))
	local list = Theme.list(body, UDim2.fromScale(1, 1), nil, 7)
	local tp = Remotes.get("Teleport")
	local function refresh()
		local s = State.get()
		Theme.clear(list)
		local char = player.Character
		local rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local here = if rootPart then Places.dirOf(rootPart.Position) else Vector3.yAxis
		local price = Economy.teleportPrice(s.fx)
		for _, st in Places.stations do
			local dist = Places.arc(here, st.dir)
			local row = Theme.frame(UDim2.new(1, -6, 0, 48), nil, Theme.ROW)
			row.LayoutOrder = st.index
			Theme.corner(row, 3)
			local cat = Theme.label(
				if dist < 120 then "YOU ARE HERE" else Theme.metres(dist),
				9,
				if dist < 120 then Theme.TEAL else Theme.MUTED,
				Theme.F.bold,
				UDim2.fromOffset(200, 14),
				UDim2.fromOffset(14, 7)
			)
			cat.Parent = row
			local name = Theme.label(
				st.name .. " Station",
				15,
				Theme.WHITE,
				Theme.F.heavy,
				UDim2.fromOffset(300, 20),
				UDim2.fromOffset(14, 21)
			)
			name.Parent = row
			if dist >= 120 then
				local b = Theme.button(
					"GO  " .. Theme.money(price),
					UDim2.fromOffset(110, 34),
					if (s.money or 0) >= price then "Orange" else "Gray"
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
	Menus.register("teleport", root, refresh)
end

---------------------------------------------------------------------------- field manual
-- A spiral notebook (d_0014): your details and the sector report on the left page, the chosen
-- chapter on the right, coloured chapter tabs down the right edge.
local CHAPTERS: { { title: string, color: Color3, lines: { string } } } = {
	{
		title = "Welcome to the Moon",
		color = Color3.fromRGB(240, 102, 12),
		lines = {
			"Somebody decided the Moon was too dusty. You have been hired to fix that.",
			"This manual explains everything you need. Reading it is compulsory and unpaid.",
			"Press H any time to open it again.",
		},
	},
	{
		title = "Your job",
		color = Color3.fromRGB(240, 160, 20),
		lines = {
			"Clean the Moon, one hexagon sector at a time.",
			"The gold outline on the ground is your current sector. The ring at the top right shows how much of it is clean.",
			"Finish a sector for a bonus. Finish a whole region for a bigger one.",
		},
	},
	{
		title = "Cleaning",
		color = Color3.fromRGB(70, 190, 90),
		lines = {
			"Hold the left mouse button (or BRUSH on a touch screen) and walk over the dust.",
			"Your container fills in kilograms. When it is full, press Q to pack the dust into a pod.",
			"Steep crater walls hold Stardust, worth five times more. Only brooms reach it.",
		},
	},
	{
		title = "Getting paid",
		color = Color3.fromRGB(56, 190, 220),
		lines = {
			"Carry pods to the Dust Drum in any station and hold E to deposit them.",
			"The Pod Cannon launches them home and you are paid per kilogram.",
			"Spend your pay at the Supply Wall (tools) and the Upgrades board.",
		},
	},
	{
		title = "Building",
		color = Color3.fromRGB(70, 120, 240),
		lines = {
			"Buy the Build Tool at the Supply Wall, claim a Mop Base plot, then press B.",
			"Belts carry pods to the Pod Cannon on their own. Machines turn dust into glass and gems.",
			"Solar panels and batteries power the machines.",
		},
	},
	{
		title = "Robots",
		color = Color3.fromRGB(150, 90, 230),
		lines = {
			"Dot Bots clean the sectors round your base and drop the dust on your belts.",
			"The Cosmic Octo cleans far away and fires pods home to a Pod Catcher.",
			"Your base keeps earning while you are away.",
		},
	},
	{
		title = "Vehicles",
		color = Color3.fromRGB(220, 70, 120),
		lines = {
			"Build a Garage on your plot and buy sweepers there.",
			"Vehicles clean wide strips fast and hold far more dust. Empty the tank at a Collector Pad.",
		},
	},
	{
		title = "Exploring",
		color = Color3.fromRGB(230, 60, 60),
		lines = {
			"Untangle flags and survey buried probes for rewards.",
			"The Moon Map in each station shows what is clean. Station Links teleport you between stations.",
			"Watch the sky: meteor showers put dust back.",
		},
	},
}

local function fieldManual()
	local root = Theme.frame(UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Theme.PANEL, 1)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Name = "Field Manual"
	root.Visible = false
	root.Parent = gui
	local canvas = Theme.canvas(root)
	local PAGE = Color3.fromRGB(246, 243, 234)
	local INK = Color3.fromRGB(40, 42, 48)
	local book = Theme.frame(UDim2.fromOffset(700, 470), UDim2.fromOffset(290, 96), Color3.fromRGB(58, 64, 72))
	Theme.corner(book, 10)
	book.Rotation = -2
	book.Parent = canvas
	local left = Theme.frame(UDim2.fromOffset(336, 450), UDim2.fromOffset(10, 10), PAGE)
	Theme.corner(left, 4)
	left.Parent = book
	local right = Theme.frame(UDim2.fromOffset(336, 450), UDim2.fromOffset(354, 10), PAGE)
	Theme.corner(right, 4)
	right.Parent = book
	-- faint ruled lines
	for _, pg in { left, right } do
		for i = 0, 17 do
			local l =
				Theme.frame(UDim2.new(1, -40, 0, 1), UDim2.fromOffset(20, 60 + i * 22), Color3.fromRGB(214, 220, 232))
			l.Parent = pg
		end
	end
	-- the spiral
	for i = 0, 15 do
		local ring =
			Theme.frame(UDim2.fromOffset(22, 9), UDim2.fromOffset(339, 22 + i * 27), Color3.fromRGB(200, 204, 212))
		Theme.corner(ring, 5)
		Theme.stroke(ring, Color3.fromRGB(120, 124, 132), 1)
		ring.Parent = book
	end
	local owner = Theme.label(
		"THIS FIELD MANUAL BELONGS TO",
		8,
		Color3.fromRGB(120, 124, 132),
		Theme.F.bold,
		UDim2.fromOffset(290, 12),
		UDim2.fromOffset(24, 22)
	)
	owner.Parent = left
	local name = Theme.label(
		player.DisplayName,
		22,
		Color3.fromRGB(28, 44, 140),
		Theme.F.hand,
		UDim2.fromOffset(290, 30),
		UDim2.fromOffset(24, 34)
	)
	name.Parent = left
	local report = Theme.label("", 11, INK, Theme.F.serif, UDim2.fromOffset(290, 330), UDim2.fromOffset(24, 76))
	report.TextWrapped = true
	report.RichText = true
	report.TextYAlignment = Enum.TextYAlignment.Top
	report.LineHeight = 1.25
	report.Parent = left
	local stamp = Theme.frame(UDim2.fromOffset(56, 56), UDim2.fromOffset(250, 370), PAGE, 1)
	stamp.Rotation = -14
	Theme.corner(stamp, 28)
	Theme.stroke(stamp, Theme.RED, 2, 0.4)
	local sl = Theme.label("MMC", 14, Theme.RED, Theme.F.black, UDim2.fromScale(1, 1))
	sl.TextXAlignment = Enum.TextXAlignment.Center
	sl.TextTransparency = 0.4
	sl.Parent = stamp
	stamp.Parent = left
	local title = Theme.label("", 18, INK, Theme.F.heavy, UDim2.fromOffset(290, 26), UDim2.fromOffset(24, 26))
	title.Parent = right
	local text = Theme.label("", 12, INK, Theme.F.serif, UDim2.fromOffset(290, 300), UDim2.fromOffset(24, 64))
	text.TextWrapped = true
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.LineHeight = 1.3
	text.Parent = right
	local pageNo = Theme.label(
		"",
		10,
		Color3.fromRGB(120, 124, 132),
		Theme.F.bold,
		UDim2.fromOffset(60, 14),
		UDim2.fromOffset(256, 422)
	)
	pageNo.TextXAlignment = Enum.TextXAlignment.Right
	pageNo.Parent = right
	-- chapter tabs down the right edge
	local tabs: { TextButton } = {}
	local chapter = 1
	local function show(n: number)
		chapter = math.clamp(n, 1, #CHAPTERS)
		local c = CHAPTERS[chapter]
		title.Text = c.title
		text.Text = table.concat(c.lines, "\n\n")
		pageNo.Text = string.format("%d / %d", chapter, #CHAPTERS)
		for i, t in tabs do
			t.Size = UDim2.fromOffset(if i == chapter then 30 else 22, 40)
		end
	end
	for i, c in CHAPTERS do
		local t = Theme.cell(UDim2.fromOffset(22, 40), c.color)
		t.Position = UDim2.fromOffset(694, 24 + (i - 1) * 50)
		Theme.corner(t, 4)
		local n =
			Theme.label(tostring(i), 11, Theme.WHITE, Theme.F.bold, UDim2.new(1, -6, 1, 0), UDim2.fromOffset(6, 0))
		n.Parent = t
		t.Activated:Connect(function()
			show(i)
		end)
		t.Parent = book
		table.insert(tabs, t)
	end
	Theme.hints(canvas, { { "A", "D", "Flip pages" }, { "LMB", "Pick a chapter" }, { "H", "Close" } })
	local closeButton = Theme.button("×", UDim2.fromOffset(44, 44), "Dark")
	closeButton.Name = "Close"
	closeButton.Position = UDim2.fromOffset(1000, 70)
	closeButton.Parent = canvas

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
			"<b>POSITION</b>",
			"Junior Lunar Surface Hygiene Associate",
			"",
			string.format(
				"<b>SECTOR %d</b>   %.2f° %s, %.2f° %s",
				id,
				math.abs(lat),
				if lat >= 0 then "N" else "S",
				math.abs(lon),
				if lon >= 0 then "E" else "W"
			),
			string.format(
				"State: %s, %d%% clean",
				if state == 2 then "complete" elseif state == 1 then "started" else "untouched",
				math.floor(MoonView.progress(id) * 100)
			),
			string.format("Bonus when clean: %s", Theme.money(reward)),
			string.format("Nearest station: %s, %s", station.name, Theme.metres(arc)),
			string.format("The Moon is %.3f%% clean.", MoonView.cleanPct()),
		}
		if s.fx and s.fx.manualPlus then
			table.insert(lines, string.format("Region bonus: %s", Theme.money(Economy.regionReward(s.fx))))
		end
		report.Text = table.concat(lines, "\n")
		show(chapter)
	end
	Menus.register("manual", root, refresh)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or openCard ~= root then
			return
		end
		if input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			show(chapter + 1)
		elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			show(chapter - 1)
		end
	end)
end

function Menus.start()
	gui = Theme.screen("Menus", player:WaitForChild("PlayerGui"), 5)
	supplyWall()
	upgradeBoard()
	teleportMenu()
	fieldManual()

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local menu = prompt:GetAttribute("Menu") :: string?
		if menu then
			open(menu)
		end
	end)
	State.onFeedback(function(kind: string, data: any)
		if kind == "OpenMenu" then
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
			elseif not openCard then
				open("manual")
			end
		elseif
			input.KeyCode == Enum.KeyCode.Escape
			or input.KeyCode == Enum.KeyCode.ButtonB
			or (input.KeyCode == Enum.KeyCode.E and openName ~= "map" and os.clock() - openedAt > 0.4)
		then
			if openCard then
				close()
			end
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			local a = openName and primary[openName]
			if a then
				a()
			end
		end
	end)
end

return Menus
