--!strict
-- The Garage console on your plot, laid out like the original's (P1 f_403, f_588; P3 f_040):
-- VEHICLES shows the five vehicles as 3D renders with luggage-tag prices (teal PARKED / OUT for
-- ones you own) and a detail card with BUY, TAKE OUT or STORE; UPGRADES lists the chosen
-- vehicle's seven upgrades with level pips. The server checks you are at your own Garage and can
-- pay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local buildVehicle = require(Shared:WaitForChild("World"):WaitForChild("Vehicles"))

local Menus = require(script.Parent.Menus)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Garage = {}

local player = Players.LocalPlayer

local BLURB: { [string]: string } = {
	PushCart = "Push it in front of you. A wide sweep and a small tank.",
	SitSweeper = "Sit down and sweep. Room for a lot more dust.",
	CrewShuttle = "No brushes, just speed. Fast travel for the whole crew.",
	CraterSweeper = "A street sweeper for the Moon, with three spinning brushes.",
	BigSuckRover = "Six wheels, two stacks and a tank the size of a house.",
}

local models: { [string]: Model } = {}
local function modelOf(id: string): Model?
	if not models[id] then
		local ok, m = pcall(buildVehicle, id)
		if ok then
			models[id] = m
		end
	end
	return models[id]
end

function Garage.start()
	local gui = Theme.screen("Garage", player:WaitForChild("PlayerGui"), 6)
	local m = Theme.stationMenu(gui, "Garage")
	local buy = Remotes.get("Buy")
	local intent = Remotes.get("VehicleIntent")
	local tab = "Vehicles"
	local selected = Config.Vehicles[1].id
	local selectedUp = Config.VehicleUpgrades.List[1].id
	local action: (() -> ())? = nil
	local refresh: () -> ()

	local grid = Theme.frame(UDim2.new(1, -16, 1, -16), UDim2.fromOffset(8, 8), Theme.INNER, 1)
	grid.Parent = m.body
	local upList = Theme.list(m.body, UDim2.new(1, -16, 1, -16), UDim2.fromOffset(8, 8), 7)

	local function pickTab(name: string)
		tab = name
		refresh()
	end

	local function vehicleCard(v: Config.VehicleDef, x: number, y: number, w: number, s: { [string]: any })
		local owned = s.vehicles and s.vehicles[v.id] ~= nil
		local sel = v.id == selected
		local money = s.money or 0
		local cell = Theme.cell(UDim2.fromOffset(w, 220), Theme.INNER)
		cell.BackgroundTransparency = 1
		cell.Position = UDim2.fromOffset(x, y)
		local mdl = modelOf(v.id)
		if mdl then
			local icon = Theme.icon3d(mdl, UDim2.fromOffset(w, 158), UDim2.fromOffset(0, 18), 40, 22)
			icon.Parent = cell
		end
		local chip =
			Theme.frame(UDim2.fromOffset(w - 10, 22), UDim2.fromOffset(5, 182), if sel then Theme.ORANGE else Theme.ROW)
		Theme.corner(chip, 3)
		local n = Theme.label(v.name, 11, Theme.WHITE, Theme.F.bold, UDim2.fromScale(1, 1))
		n.TextXAlignment = Enum.TextXAlignment.Center
		n.Parent = chip
		chip.Parent = cell
		if owned then
			local t = Theme.label(
				if s.vehicle == v.id then "OUT" else "PARKED",
				9,
				Theme.TEAL,
				Theme.F.bold,
				UDim2.fromOffset(70, 18),
				UDim2.new(1, -80, 0, 10)
			)
			t.BackgroundColor3 = Theme.ROW
			t.BackgroundTransparency = 0
			t.TextXAlignment = Enum.TextXAlignment.Center
			Theme.corner(t, 3)
			t.Parent = cell
		else
			local price = Economy.price(v.price, s.fx or {})
			local tag = Theme.luggage(Theme.money(price), if money >= price then "Good" else "Bad", -7)
			tag.AnchorPoint = Vector2.new(1, 0)
			tag.Position = UDim2.new(1, -8, 0, 8)
			tag.Parent = cell
		end
		cell.Activated:Connect(function()
			selected = v.id
			refresh()
		end)
		cell.Parent = grid
	end

	function refresh()
		local s = State.get()
		local money = s.money or 0
		local fx = s.fx or {}
		m.money.Text = Theme.cash(money)
		Theme.setTabs(m.tabs, { "Vehicles", "Upgrades" }, tab, pickTab)
		Theme.setHints(m.hints, {
			{ "1", "2", "Tabs" },
			{ "LMB", "Choose" },
			{ "Enter", if tab == "Vehicles" then "Buy or take out" else "Install" },
			{ "X", "Store" },
			{ "E", "Esc", "Leave" },
		})
		Theme.clear(grid)
		Theme.clear(upList)
		grid.Visible = tab == "Vehicles"
		upList.Visible = tab == "Upgrades"
		local v = Loadout.vehicle(selected) :: Config.VehicleDef
		local ups = s.vehicles and s.vehicles[v.id]
		if tab == "Vehicles" then
			-- three across the top, two below, with an orange bar under each row (P1 f_403)
			for i, def in Config.Vehicles do
				if i <= 3 then
					vehicleCard(def, (i - 1) * 245, 0, 239, s)
				else
					vehicleCard(def, (i - 4) * 368, 232, 362, s)
				end
			end
			for _, y in { 212, 444 } do
				local bar = Theme.frame(UDim2.new(1, 0, 0, 6), UDim2.fromOffset(0, y), Theme.ORANGE)
				bar.Parent = grid
			end
		else
			for i, u in Config.VehicleUpgrades.List do
				local level = if ups then ups[u.id] or 0 else 0
				local sel = u.id == selectedUp
				local row = Theme.cell(UDim2.new(1, -6, 0, 32), if sel then Theme.ORANGE else Theme.ROW)
				row.LayoutOrder = i
				Theme.corner(row, 3)
				local name = Theme.label(
					u.name,
					13,
					if ups then Theme.WHITE else Theme.DIM,
					Theme.F.bold,
					UDim2.fromOffset(300, 32),
					UDim2.fromOffset(16, 0)
				)
				if sel then
					name.TextColor3 = Theme.WHITE
				end
				name.Parent = row
				Theme.pips(row, u.max, level, UDim2.new(0, 525, 0.5, 0), sel)
				if level >= u.max then
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
				elseif ups then
					local price = Economy.price(Economy.vehicleUpgradeCost(v.price, level + 1), fx)
					local tag = Theme.luggage(Theme.money(price), if money >= price then "Good" else "Bad")
					tag.AnchorPoint = Vector2.new(1, 0.5)
					tag.Position = UDim2.new(1, -6, 0.5, 0)
					tag.Parent = row
				else
					local t = Theme.label(
						"LOCKED",
						10,
						Theme.MUTED,
						Theme.F.bold,
						UDim2.fromOffset(80, 32),
						UDim2.new(1, -92, 0, 0)
					)
					t.TextXAlignment = Enum.TextXAlignment.Right
					t.Parent = row
				end
				row.Activated:Connect(function()
					selectedUp = u.id
					refresh()
				end)
				row.Parent = upList
			end
		end

		-- detail card
		Theme.clear(m.detail)
		action = nil
		local st = Loadout.vehicleStats(v, ups, fx, 0)
		local mdl = modelOf(v.id)
		Theme.detailHead(
			m.detail,
			if v.cleans then "Cleaning vehicle" else "Crew transport",
			v.name,
			BLURB[v.id] or "",
			if mdl then Theme.icon3d(mdl, UDim2.fromScale(1, 1), nil, 40, 22) else nil
		)
		if tab == "Upgrades" then
			local u = Config.VehicleUpgrades.List[1]
			for _, it in Config.VehicleUpgrades.List do
				if it.id == selectedUp then
					u = it
				end
			end
			local level = if ups then ups[u.id] or 0 else 0
			Theme.statRow(m.detail, 140, "Upgrade", u.name)
			Theme.statRow(m.detail, 176, "Level", string.format("%d / %d", level, u.max))
			Theme.statRow(m.detail, 212, "Effect", u.text)
			if not ups then
				Theme.action(m.detail, "BUY THE VEHICLE FIRST", false, 300)
			elseif level >= u.max then
				Theme.action(m.detail, "MAXED", false, 300)
			else
				local price = Economy.price(Economy.vehicleUpgradeCost(v.price, level + 1), fx)
				Theme.statRow(m.detail, 248, "Cost", Theme.money(price), if money >= price then nil else Theme.RED)
				local function install()
					buy:FireServer("vehicleUp", v.id, u.id)
				end
				local b = Theme.action(m.detail, "INSTALL  " .. Theme.money(price), money >= price, 300)
				b.Activated:Connect(install)
				action = install
			end
			return
		end
		Theme.statRow(
			m.detail,
			140,
			"Where",
			if not ups then "Not yours yet" elseif s.vehicle == v.id then "Out on the Moon" else "In the garage"
		)
		if v.cleans then
			Theme.statRow(m.detail, 176, "Hopper", Theme.mass(st.tank))
			Theme.statRow(m.detail, 212, "Sweep", Theme.metres(st.width))
		else
			Theme.statRow(m.detail, 176, "Seats", tostring(v.seats))
		end
		Theme.statRow(
			m.detail,
			if v.cleans then 248 else 212,
			"Top speed",
			string.format("%d km/h", st.speed * 0.28 * 3.6)
		)
		if not ups then
			local price = Economy.price(v.price, fx)
			local function buyIt()
				buy:FireServer("vehicle", v.id)
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
				UDim2.fromOffset(0, 358)
			)
			note.Parent = m.detail
		else
			local out = s.vehicle == v.id
			local function go()
				if out then
					intent:FireServer("store")
				else
					intent:FireServer("spawn", v.id)
					Menus.close()
				end
			end
			local b = Theme.action(m.detail, if out then "CALL BACK" else "TAKE OUT", true, 300)
			b.Activated:Connect(go)
			action = go
			if out then
				local n = Theme.label(
					"It is out on the Moon.",
					11,
					Theme.MINT,
					Theme.F.semi,
					UDim2.new(1, 0, 0, 16),
					UDim2.fromOffset(0, 358)
				)
				n.Parent = m.detail
			end
		end
	end

	Menus.register("garage", m.root, refresh, function()
		if action then
			action()
		end
	end)
	State.changed(function()
		if m.root.Visible then
			refresh()
		end
	end)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not m.root.Visible then
			return
		end
		if input.KeyCode == Enum.KeyCode.One then
			pickTab("Vehicles")
		elseif input.KeyCode == Enum.KeyCode.Two then
			pickTab("Upgrades")
		elseif input.KeyCode == Enum.KeyCode.X then
			intent:FireServer("store")
		end
	end)
end

return Garage
