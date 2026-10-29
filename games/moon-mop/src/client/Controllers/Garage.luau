--!strict
-- The Garage console on your plot: the five vehicles with their stats, buy / take out / store,
-- and each vehicle's seven upgrades with level pips. Opened by the console prompt. The server
-- checks you are at your own Garage and can pay.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Menus = require(script.Parent.Menus)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Garage = {}

local player = Players.LocalPlayer

local function bar(parent: Instance, label: string, value: number, max: number, text: string, y: number)
	local l = Theme.text(label, UDim2.new(0.3, 0, 0, 20), Theme.MUTED, Enum.Font.GothamBold, 15)
	l.Position = UDim2.fromOffset(0, y)
	l.Parent = parent
	local track = Theme.frame(UDim2.new(0.5, 0, 0, 10), UDim2.new(0.3, 0, 0, y + 5), Theme.SLATE)
	Theme.corner(track, 5)
	track.Parent = parent
	local fill = Theme.frame(UDim2.fromScale(math.clamp(value / max, 0.04, 1), 1), nil, Theme.ORANGE)
	Theme.corner(fill, 5)
	fill.Parent = track
	local v = Theme.text(text, UDim2.new(0.18, 0, 0, 20), Theme.WHITE, Enum.Font.GothamBlack, 15)
	v.Position = UDim2.new(0.82, 0, 0, y)
	v.TextXAlignment = Enum.TextXAlignment.Right
	v.Parent = parent
end

function Garage.start()
	local gui = Theme.screen("Garage", player:WaitForChild("PlayerGui"), 6)
	local card, body = Theme.card(gui, "Garage", "Moon Mop Co. motor pool", UDim2.fromScale(0.92, 0.86))
	local list = Theme.list(body, UDim2.new(0.38, -8, 1, 0))
	local detail = Theme.frame(UDim2.new(0.62, -8, 1, 0), UDim2.new(0.38, 8, 0, 0), Theme.SLATE_HI)
	Theme.corner(detail, 8)
	Theme.pad(detail, 14)
	detail.Parent = body
	local buy = Remotes.get("Buy")
	local intent = Remotes.get("VehicleIntent")
	local selected = Config.Vehicles[1].id

	local function refresh()
		local s = State.get()
		local money = s.money or 0
		local fx = s.fx or {}
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for _, c in detail:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local maxSpeed, maxTank, maxWidth = 1, 1, 1
		for _, v in Config.Vehicles do
			maxSpeed = math.max(maxSpeed, v.speed)
			maxTank = math.max(maxTank, Loadout.maxTank(v))
			maxWidth = math.max(maxWidth, v.width)
		end
		for i, v in Config.Vehicles do
			local owned = s.vehicles and s.vehicles[v.id] ~= nil
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, -8, 0, 58)
			row.LayoutOrder = i
			row.AutoButtonColor = false
			row.Text = ""
			row.BackgroundColor3 = if v.id == selected then Theme.ORANGE else Theme.SLATE_HI
			Theme.corner(row, 6)
			local name = Theme.text(
				v.name,
				UDim2.new(0.6, 0, 0, 24),
				if v.id == selected then Theme.BLACK else Theme.WHITE,
				Enum.Font.GothamBlack,
				20
			)
			name.Position = UDim2.fromOffset(12, 6)
			name.Parent = row
			local sub = Theme.text(
				if v.cleans
					then string.format("%d st brush · %s tank", v.width, Theme.mass(v.tank))
					else string.format("%d seats · fast travel", v.seats),
				UDim2.new(0.6, 0, 0, 18),
				if v.id == selected then Theme.SLATE else Theme.MUTED,
				Enum.Font.GothamBold,
				14
			)
			sub.Position = UDim2.fromOffset(12, 32)
			sub.Parent = row
			local price = Economy.price(v.price, fx)
			local tag = if owned
				then Theme.tag("OWNED", "Owned")
				else Theme.tag(Theme.money(price), if money >= price then "Good" else "Bad")
			tag.AnchorPoint = Vector2.new(1, 0.5)
			tag.Position = UDim2.new(1, -10, 0.5, 0)
			tag.Parent = row
			row.Activated:Connect(function()
				selected = v.id
				refresh()
			end)
			row.Parent = list
		end

		local v = Loadout.vehicle(selected) :: Config.VehicleDef
		local ups = s.vehicles and s.vehicles[v.id]
		local st = Loadout.vehicleStats(v, ups, fx, 0)
		local title = Theme.text(string.upper(v.name), UDim2.new(1, 0, 0, 34), Theme.WHITE, Enum.Font.GothamBlack, 32)
		title.Parent = detail
		bar(detail, "TOP SPEED", st.speed, maxSpeed * 1.5, string.format("%d km/h", st.speed * 0.28 * 3.6), 44)
		bar(detail, "TANK", st.tank, maxTank, Theme.mass(st.tank), 70)
		bar(detail, "BRUSH", st.width, maxWidth, string.format("%d st", st.width), 96)
		-- actions
		local actions = Theme.frame(UDim2.new(1, 0, 0, 50), UDim2.fromOffset(0, 126), Theme.SLATE, 1)
		local al = Instance.new("UIListLayout")
		al.FillDirection = Enum.FillDirection.Horizontal
		al.Padding = UDim.new(0, 8)
		al.Parent = actions
		actions.Parent = detail
		if not ups then
			local price = Economy.price(v.price, fx)
			local b = Theme.button(
				"BUY  " .. Theme.money(price),
				UDim2.new(0, 200, 0, 46),
				if money >= price then "Orange" else "Dark"
			)
			b.Activated:Connect(function()
				buy:FireServer("vehicle", v.id)
			end)
			b.Parent = actions
		else
			local out = s.vehicle == v.id
			local b = Theme.button(if out then "STORE" else "TAKE OUT", UDim2.new(0, 180, 0, 46), "Orange")
			b.Activated:Connect(function()
				if out then
					intent:FireServer("store")
				else
					intent:FireServer("spawn", v.id)
					Menus.close()
				end
			end)
			b.Parent = actions
		end
		-- upgrades
		local head = Theme.text("UPGRADES", UDim2.new(1, 0, 0, 20), Theme.TEAL, Enum.Font.GothamBold, 16)
		head.Position = UDim2.fromOffset(0, 184)
		head.Parent = detail
		local upList = Theme.list(detail, UDim2.new(1, 0, 1, -210), UDim2.fromOffset(0, 208))
		for i, u in Config.VehicleUpgrades.List do
			local level = if ups then ups[u.id] or 0 else 0
			local row = Theme.frame(UDim2.new(1, -8, 0, 46), nil, Theme.SLATE)
			row.LayoutOrder = i
			Theme.corner(row, 6)
			local n = Theme.text(u.name, UDim2.new(0.45, 0, 0, 20), Theme.WHITE, Enum.Font.GothamBlack, 16)
			n.Position = UDim2.fromOffset(10, 4)
			n.Parent = row
			local t = Theme.text(u.text, UDim2.new(0.45, 0, 0, 16), Theme.MUTED, Enum.Font.GothamBold, 13)
			t.Position = UDim2.fromOffset(10, 25)
			t.Parent = row
			for p = 1, u.max do
				local pip = Theme.frame(
					UDim2.fromOffset(12, 12),
					UDim2.new(0.47, (p - 1) * 16, 0.5, -6),
					if p <= level then Theme.ORANGE else Theme.SLATE_HI
				)
				Theme.corner(pip, 3)
				pip.Parent = row
			end
			if level >= u.max then
				local tag = Theme.tag("MAX", "Owned")
				tag.AnchorPoint = Vector2.new(1, 0.5)
				tag.Position = UDim2.new(1, -8, 0.5, 0)
				tag.Parent = row
			elseif ups then
				local price = Economy.price(Economy.vehicleUpgradeCost(v.price, level + 1), fx)
				local b = Theme.button(
					Theme.money(price),
					UDim2.new(0, 110, 0, 36),
					if money >= price then "Green" else "Dark"
				)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -6, 0.5, 0)
				b.Activated:Connect(function()
					buy:FireServer("vehicleUp", v.id, u.id)
				end)
				b.Parent = row
			end
			row.Parent = upList
		end
	end

	Menus.register("garage", card, refresh)
	State.changed(function()
		if card.Visible then
			refresh()
		end
	end)
end

return Garage
