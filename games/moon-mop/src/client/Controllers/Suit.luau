--!strict
-- The suit locker (C): pick your spacesuit colour and visor tint, and switch owned gear on or
-- off (Jetpack, Gravity Boots, Night Vision). The server saves the choice and dresses the
-- character; the swatches show the change straight away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Juice = require(script.Parent.Juice)
local Menus = require(script.Parent.Menus)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Suit = {}

local player = Players.LocalPlayer
local G = Config.Gear

-- Same rule as the server's Suits.visorColour.
local function visorColour(style: number): Color3
	if style <= 1 then
		return Color3.fromRGB(255, 190, 60)
	end
	return Color3.fromHSV(((style - 2) / (G.VisorStyles - 1)) % 1, 0.75, 0.95)
end

local GEAR_NAMES = {
	{ id = "Jetpack", name = "Jetpack", text = "Hold jump in the air to fly" },
	{ id = "GravityBoots", name = "Gravity Boots", text = "Walk faster" },
	{ id = "NightVision", name = "Night Vision", text = "See in the dark" },
}

local function swatch(color: Color3, selected: boolean, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Text = ""
	b.AutoButtonColor = false
	b.Size = UDim2.fromOffset(58, 58)
	b.BackgroundColor3 = if selected then Theme.ORANGE else Theme.ROW
	b.LayoutOrder = order
	Theme.corner(b, 6)
	local dot = Theme.frame(UDim2.fromOffset(40, 40), UDim2.fromScale(0.5, 0.5), color)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.corner(dot, 20)
	Theme.stroke(dot, Theme.EDGE, 2)
	dot.Parent = b
	Juice.bindButton(b)
	return b
end

local function grid(parent: Instance, y: number, height: number): Frame
	local f = Theme.frame(UDim2.new(1, -24, 0, height), UDim2.fromOffset(12, y), Theme.INNER, 1)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(58, 58)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = f
	f.Parent = parent
	return f
end

local function heading(parent: Instance, text: string, y: number)
	local h = Theme.label(text, 11, Theme.TEAL, Theme.F.bold, UDim2.new(1, -24, 0, 16), UDim2.fromOffset(12, y))
	h.Parent = parent
end

function Suit.start()
	local gui = Theme.screen("Suit", player:WaitForChild("PlayerGui"), 6)
	local m = Theme.stationMenu(gui, "Suit locker")
	local customize = Remotes.get("Customize")
	local gearRemote = Remotes.get("Gear")
	local tab = "Suit"
	local selectedGear = GEAR_NAMES[1].id
	local action: (() -> ())? = nil
	local refresh: () -> ()

	local function pickTab(name: string)
		tab = name
		refresh()
	end

	function refresh()
		Theme.clear(m.body)
		Theme.clear(m.detail)
		action = nil
		local s = State.get()
		local suit = s.suit or { visor = 1, colour = 1 }
		local gear = s.gear or {}
		m.money.Text = Theme.cash(s.money or 0)
		m.counterLabel.Text = "GEAR OWNED"
		local owned = 0
		for _, g in GEAR_NAMES do
			if gear[g.id] then
				owned += 1
			end
		end
		m.counter.Text = string.format("%d / %d", owned, #GEAR_NAMES)
		Theme.setTabs(m.tabs, { "Suit", "Gear" }, tab, pickTab)
		Theme.setHints(m.hints, {
			{ "1", "2", "Tabs" },
			{ "LMB", "Choose" },
			{ "Enter", if tab == "Suit" then "Done" else "Switch on or off" },
			{ "C", "Leave" },
		})
		local colour = G.SuitColours[suit.colour] or G.SuitColours[1]
		local suitColour = Color3.fromRGB(colour[1], colour[2], colour[3])

		if tab == "Suit" then
			heading(m.body, "SUIT COLOUR", 12)
			local colours = grid(m.body, 34, 132)
			for i, c in G.SuitColours do
				local b = swatch(Color3.fromRGB(c[1], c[2], c[3]), i == suit.colour, i)
				b.Activated:Connect(function()
					customize:FireServer(suit.visor, i)
				end)
				b.Parent = colours
			end
			heading(m.body, "VISOR TINT", 184)
			local visors = grid(m.body, 206, 200)
			for i = 1, G.VisorStyles do
				local b = swatch(visorColour(i), i == suit.visor, i)
				b.Activated:Connect(function()
					customize:FireServer(i, suit.colour)
				end)
				b.Parent = visors
			end
			-- detail: a helmet badge in the chosen colours
			local thumb = Theme.frame(UDim2.fromScale(1, 1), nil, suitColour)
			Theme.corner(thumb, 6)
			local visor = Theme.frame(UDim2.fromScale(0.7, 0.42), UDim2.fromScale(0.5, 0.45), visorColour(suit.visor))
			visor.AnchorPoint = Vector2.new(0.5, 0.5)
			Theme.corner(visor, 10)
			Theme.stroke(visor, Theme.EDGE, 2)
			visor.Parent = thumb
			Theme.detailHead(m.detail, "Spacesuit", "Your suit", "Pick a colour and a visor. The crew sees it.", thumb)
			Theme.statRow(m.detail, 140, "Colour", string.format("No. %d of %d", suit.colour, #G.SuitColours))
			Theme.statRow(m.detail, 176, "Visor", string.format("No. %d of %d", suit.visor, G.VisorStyles))
			local b = Theme.action(m.detail, "DONE", true, 300)
			local function done()
				Menus.close()
			end
			b.Activated:Connect(done)
			action = done
			return
		end

		local list = Theme.list(m.body, UDim2.new(1, -16, 1, -16), UDim2.fromOffset(8, 8), 7)
		local chosen = GEAR_NAMES[1]
		for i, g in GEAR_NAMES do
			local sel = g.id == selectedGear
			if sel then
				chosen = g
			end
			local row = Theme.cell(UDim2.new(1, -6, 0, 40), if sel then Theme.ORANGE else Theme.ROW)
			row.LayoutOrder = i
			Theme.corner(row, 3)
			local n = Theme.label(
				g.name,
				14,
				if gear[g.id] or sel then Theme.WHITE else Theme.DIM,
				Theme.F.bold,
				UDim2.fromOffset(300, 40),
				UDim2.fromOffset(16, 0)
			)
			n.Parent = row
			local on = if g.id == "Jetpack" then gear.JetpackOn ~= false else gear[g.id .. "On"] == true
			local word = if not gear[g.id] then "NOT OWNED" elseif on then "ON" else "OFF"
			local t = Theme.label(
				word,
				10,
				if sel then Theme.WHITE elseif not gear[g.id] then Theme.MUTED elseif on then Theme.MINT else Theme.MUTED,
				Theme.F.bold,
				UDim2.fromOffset(120, 40),
				UDim2.new(1, -132, 0, 0)
			)
			t.TextXAlignment = Enum.TextXAlignment.Right
			t.Parent = row
			row.Activated:Connect(function()
				selectedGear = g.id
				refresh()
			end)
			row.Parent = list
		end
		Theme.detailHead(m.detail, "Gear", chosen.name, chosen.text)
		if gear[chosen.id] then
			local on = if chosen.id == "Jetpack" then gear.JetpackOn ~= false else gear[chosen.id .. "On"] == true
			Theme.statRow(
				m.detail,
				140,
				"Status",
				if on then "Switched on" else "Switched off",
				if on then Theme.MINT else nil
			)
			local function toggle()
				gearRemote:FireServer(chosen.id, not on)
			end
			local b = Theme.action(m.detail, if on then "SWITCH OFF" else "SWITCH ON", true, 300)
			b.Activated:Connect(toggle)
			action = toggle
		else
			Theme.statRow(m.detail, 140, "Where", "Supply wall, Gears")
			Theme.action(m.detail, "BUY IT AT THE SUPPLY WALL", false, 300)
		end
	end

	Menus.register("suit", m.root, refresh, function()
		if action then
			action()
		end
	end)
	State.changed(function()
		if m.root.Visible then
			refresh()
		end
	end)
	-- a SUIT button for touch and mouse players, clear of the thumbstick and jump button
	local launcherGui = Theme.screen("SuitButton", player:WaitForChild("PlayerGui"), 3)
	launcherGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local launcher = Theme.button("SUIT", UDim2.fromOffset(72, 44), "Dark")
	launcher.Position = UDim2.fromOffset(16, 150)
	launcher.Visible = UserInputService.TouchEnabled
	launcher.Parent = launcherGui
	local function toggleMenu()
		if m.root.Visible then
			Menus.close()
		else
			Menus.open("suit")
		end
	end
	launcher.Activated:Connect(toggleMenu)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.C then
			toggleMenu()
		elseif m.root.Visible and input.KeyCode == Enum.KeyCode.One then
			pickTab("Suit")
		elseif m.root.Visible and input.KeyCode == Enum.KeyCode.Two then
			pickTab("Gear")
		end
	end)
end

return Suit
