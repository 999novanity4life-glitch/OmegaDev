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
	b.Size = UDim2.fromOffset(52, 52)
	b.BackgroundColor3 = color
	b.LayoutOrder = order
	Theme.corner(b, 26)
	Theme.stroke(b, if selected then Theme.ORANGE else Theme.SLATE_HI, if selected then 4 else 2)
	Juice.bindButton(b)
	return b
end

local function grid(parent: Instance, y: number, height: number): Frame
	local f = Theme.frame(UDim2.new(1, 0, 0, height), UDim2.fromOffset(0, y), Theme.SLATE, 1)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(52, 52)
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = f
	f.Parent = parent
	return f
end

function Suit.start()
	local gui = Theme.screen("Suit", player:WaitForChild("PlayerGui"), 6)
	local card, body = Theme.card(gui, "Suit locker", "Moon Mop Co. crew", UDim2.fromScale(0.8, 0.8))
	local customize = Remotes.get("Customize")
	local gearRemote = Remotes.get("Gear")
	local pick = { visor = 1, colour = 1 }

	local function refresh()
		for _, c in body:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local s = State.get()
		local suit = s.suit or { visor = 1, colour = 1 }
		pick.visor, pick.colour = suit.visor, suit.colour
		local left = Theme.frame(UDim2.new(0.58, -8, 1, 0), nil, Theme.SLATE, 1)
		left.Parent = body
		local head = Theme.text("SUIT COLOUR", UDim2.new(1, 0, 0, 22), Theme.TEAL, Enum.Font.GothamBold, 16)
		head.Parent = left
		local colours = grid(left, 28, 124)
		for i, c in G.SuitColours do
			local b = swatch(Color3.fromRGB(c[1], c[2], c[3]), i == pick.colour, i)
			b.Activated:Connect(function()
				customize:FireServer(pick.visor, i)
				pick.colour = i
			end)
			b.Parent = colours
		end
		local vhead = Theme.text("VISOR", UDim2.new(1, 0, 0, 22), Theme.TEAL, Enum.Font.GothamBold, 16)
		vhead.Position = UDim2.fromOffset(0, 160)
		vhead.Parent = left
		local visors = grid(left, 188, 200)
		for i = 1, G.VisorStyles do
			local b = swatch(visorColour(i), i == pick.visor, i)
			b.Activated:Connect(function()
				customize:FireServer(i, pick.colour)
				pick.visor = i
			end)
			b.Parent = visors
		end
		local right = Theme.frame(UDim2.new(0.42, -8, 1, 0), UDim2.new(0.58, 8, 0, 0), Theme.SLATE_HI)
		Theme.corner(right, 8)
		Theme.pad(right, 12)
		right.Parent = body
		local ghead = Theme.text("GEAR", UDim2.new(1, 0, 0, 22), Theme.TEAL, Enum.Font.GothamBold, 16)
		ghead.Parent = right
		local gear = s.gear or {}
		for i, g in GEAR_NAMES do
			local row = Theme.frame(UDim2.new(1, 0, 0, 60), UDim2.fromOffset(0, 30 + (i - 1) * 68), Theme.SLATE)
			Theme.corner(row, 6)
			row.Parent = right
			local n = Theme.text(g.name, UDim2.new(0.6, 0, 0, 24), Theme.WHITE, Enum.Font.GothamBlack, 18)
			n.Position = UDim2.fromOffset(10, 6)
			n.Parent = row
			local t = Theme.text(g.text, UDim2.new(0.5, 0, 0, 18), Theme.MUTED, Enum.Font.GothamBold, 13)
			t.Position = UDim2.fromOffset(10, 32)
			t.Parent = row
			if gear[g.id] then
				-- the Jetpack is on unless switched off; the others are off until switched on
				local on = if g.id == "Jetpack" then gear.JetpackOn ~= false else gear[g.id .. "On"] == true
				local b =
					Theme.button(if on then "ON" else "OFF", UDim2.fromOffset(80, 44), if on then "Green" else "Dark")
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -8, 0.5, 0)
				b.Activated:Connect(function()
					gearRemote:FireServer(g.id, not on)
				end)
				b.Parent = row
			else
				local tag = Theme.tag("SUPPLY WALL", "Info")
				tag.Size = UDim2.fromOffset(110, 24)
				tag.AnchorPoint = Vector2.new(1, 0.5)
				tag.Position = UDim2.new(1, -8, 0.5, 0)
				tag.Parent = row
			end
		end
	end

	Menus.register("suit", card, refresh)
	State.changed(function()
		if card.Visible then
			refresh()
		end
	end)
	-- a SUIT button for touch and mouse players, clear of the thumbstick and jump button
	local launcherGui = Theme.screen("SuitButton", player:WaitForChild("PlayerGui"), 3)
	local launcher = Theme.button("SUIT", UDim2.fromOffset(72, 44), "Dark")
	launcher.Position = UDim2.fromOffset(16, 150)
	launcher.Parent = launcherGui
	launcher.Activated:Connect(function()
		if card.Visible then
			Menus.close()
		else
			Menus.open("suit")
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.C then
			if card.Visible then
				Menus.close()
			else
				Menus.open("suit")
			end
		end
	end)
end

return Suit
