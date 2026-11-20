--!strict
-- Grand Line shop panel + the smart offer card. Client only shows things and
-- sends intent (ShopIntent); the server decides offers and grants purchases.
--
-- Theme: "Grand Line" (jump-training design doc v1, section 1): deep navy
-- panels, treasure-gold borders and numbers, Haki red for accents.
-- Mobile-first (CLAUDE.md rule 5): Scale sizes, aspect constraints, text >= 9,
-- CoreUISafeInsets; the shop button sits mid-left and the offer card
-- mid-right, clear of the thumbstick and the jump button.
-- Covers: Config.Shop.CoverImages when approved art exists, otherwise a
-- built-in placeholder (rays + gold emblem) so the layout can be tested.

local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Juice = require(script.Parent.Juice)

local ShopUI = {}

local NAVY = Color3.fromHex("0B1A2E")
local CHART = Color3.fromHex("13294A")
local GOLD_LO = Color3.fromHex("D9A93B")
local GOLD_HI = Color3.fromHex("F6D77A")
local BRASS = Color3.fromHex("7A5A1E")
local HAKI_RED = Color3.fromHex("E0122B")
local PARCHMENT = Color3.fromHex("E9D9B4")
local SEA_FOAM = Color3.fromHex("7FE3E0")
local BLACK = Color3.new(0, 0, 0)

local TITLE_FONT = Font.fromEnum(Enum.Font.Bangers)
local BODY_FONT = Font.fromEnum(Enum.Font.GothamBold)

-- Placeholder emblem per cover: big word, small word, glow colour.
local EMBLEMS: { [string]: { string | Color3 } } = {
	DoubleTraining = { "2x", "TRAINING", HAKI_RED },
	DoubleBerries = { "2x", "BERRIES", GOLD_HI },
	AutoTrain = { "AUTO", "TRAIN", SEA_FOAM },
	FruitVault = { "+20", "FRUIT SLOTS", Color3.fromHex("B46CFF") },
	VIPCaptain = { "VIP", "CAPTAIN", GOLD_HI },
	HakiTrail = { "HAKI", "TRAIL", HAKI_RED },
	GoldenSplash = { "GOLD", "SPLASH", GOLD_HI },
	CloudTrail = { "SKY", "TRAIL", Color3.fromHex("CFE8FF") },
	JumpSurge = { "+25%", "JUMP", SEA_FOAM },
	BerryPouch = { "10K", "BERRIES", GOLD_HI },
	BerryChest = { "60K", "BERRIES", GOLD_HI },
	BerryHoard = { "400K", "BERRIES", GOLD_HI },
}

type ItemView = {
	Id: string,
	Kind: string,
	Name: string,
	Blurb: string,
	Price: number,
	Cover: string,
	Order: number,
	Tab: string,
}

local items: { ItemView } = {}
local itemsById: { [string]: ItemView } = {}
for id: string, raw: Config.ShopItem in Config.Shop.Items do
	local view: ItemView = {
		Id = id,
		Kind = raw.Kind,
		Name = raw.Name,
		Blurb = raw.Blurb,
		Price = raw.Price,
		Cover = raw.Cover,
		Order = raw.Order,
		Tab = raw.Tab,
	}
	table.insert(items, view)
	itemsById[id] = view
end
table.sort(items, function(a, b)
	return a.Order < b.Order
end)

local owned: { [string]: boolean } = {}
local muted = false
local intent: RemoteEvent
local screen: ScreenGui
local panel: Frame
local grid: ScrollingFrame
local offerCard: Frame?
local offerItemId: string? = nil
local currentTab = Config.Shop.Tabs[1]
local priceButtons: { [string]: TextButton } = {}
local spinners: { GuiObject } = {}
local muteButton: TextButton

local function motion(seconds: number): number
	return if GuiService.ReducedMotionEnabled then 0 else seconds
end

local function corner(parent: GuiObject, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function stroke(parent: GuiObject, thickness: number, color: Color3, mode: Enum.ApplyStrokeMode?)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	s.Thickness = thickness
	s.Color = color
	s.Parent = parent
	return s
end

local function goldGradient(parent: GuiObject)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(GOLD_HI, GOLD_LO)
	g.Rotation = 90
	g.Parent = parent
end

local function text(
	value: string,
	size: UDim2,
	font: Font,
	color: Color3,
	maxSize: number,
	align: Enum.TextXAlignment?
): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.FontFace = font
	label.Text = value
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = align or Enum.TextXAlignment.Center
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 9
	limit.MaxTextSize = maxSize
	limit.Parent = label
	return label
end

-- Gold 3D-ish text: brass extrusion copy under a gold-gradient face.
local function heroText(value: string, size: UDim2, maxSize: number): Frame
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = size
	local back = text(value, UDim2.fromScale(1, 1), TITLE_FONT, BRASS, maxSize)
	back.Position = UDim2.new(0, 2, 0, 3)
	stroke(back, 2, BLACK, Enum.ApplyStrokeMode.Contextual)
	back.Parent = holder
	local face = text(value, UDim2.fromScale(1, 1), TITLE_FONT, Color3.new(1, 1, 1), maxSize)
	goldGradient(face)
	stroke(face, 1.5, BLACK, Enum.ApplyStrokeMode.Contextual)
	face.Parent = holder
	return holder
end

local function button(label: string, fill: Color3, textColor: Color3, aspect: number): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = fill
	b.FontFace = BODY_FONT
	b.Text = label
	b.TextColor3 = textColor
	b.TextScaled = true
	corner(b, 0.25)
	stroke(b, 2, BLACK)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 9
	limit.MaxTextSize = 24
	limit.Parent = b
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = aspect
	ratio.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0)
	pad.PaddingBottom = UDim.new(0.18, 0)
	pad.PaddingLeft = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.06, 0)
	pad.Parent = b
	Juice.bindButton(b)
	return b
end

-- Cover art: the approved image if there is one, else the placeholder.
local function makeCover(item: ItemView, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.BackgroundColor3 = CHART
	frame.ClipsDescendants = true
	corner(frame, 0.08)
	stroke(frame, 3, GOLD_LO)

	local image = Config.Shop.CoverImages[item.Cover]
	if image and image ~= "" then
		local art = Instance.new("ImageLabel")
		art.BackgroundTransparency = 1
		art.Size = UDim2.fromScale(1, 1)
		art.Image = image
		art.ScaleType = Enum.ScaleType.Crop
		art.Parent = frame
		return frame
	end

	local emblem: { string | Color3 } = EMBLEMS[item.Cover] or { "?", item.Name, GOLD_HI }
	local glow = emblem[3] :: Color3
	local bg = Instance.new("UIGradient")
	bg.Color = ColorSequence.new(CHART, NAVY)
	bg.Rotation = 90
	bg.Parent = frame

	local rays = Instance.new("ImageLabel")
	rays.BackgroundTransparency = 1
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.45)
	rays.Size = UDim2.fromScale(1.6, 1.6)
	rays.SizeConstraint = Enum.SizeConstraint.RelativeXX
	rays.Image = Config.UI.Vfx.Ray or ""
	rays.ImageColor3 = glow
	rays.ImageTransparency = 0.45
	rays.Parent = frame
	table.insert(spinners, rays)

	local halo = Instance.new("ImageLabel")
	halo.BackgroundTransparency = 1
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.fromScale(0.5, 0.45)
	halo.Size = UDim2.fromScale(0.9, 0.9)
	halo.SizeConstraint = Enum.SizeConstraint.RelativeXX
	halo.Image = Config.UI.Vfx.Glow or ""
	halo.ImageColor3 = glow
	halo.ImageTransparency = 0.25
	halo.Parent = frame

	local big = heroText(emblem[1] :: string, UDim2.fromScale(0.9, 0.5), 80)
	big.AnchorPoint = Vector2.new(0.5, 0.5)
	big.Position = UDim2.fromScale(0.5, 0.42)
	big.Parent = frame

	local small = text(emblem[2] :: string, UDim2.fromScale(0.9, 0.16), TITLE_FONT, PARCHMENT, 28)
	small.AnchorPoint = Vector2.new(0.5, 0)
	small.Position = UDim2.fromScale(0.5, 0.74)
	stroke(small, 1.5, BLACK, Enum.ApplyStrokeMode.Contextual)
	small.Parent = frame

	if item.Kind == "GamePass" then
		local ribbon = text("FOREVER", UDim2.fromScale(0.42, 0.12), BODY_FONT, Color3.new(1, 1, 1), 14)
		ribbon.BackgroundTransparency = 0
		ribbon.BackgroundColor3 = HAKI_RED
		ribbon.Position = UDim2.fromScale(0.04, 0.04)
		corner(ribbon, 0.3)
		ribbon.Parent = frame
	end
	return frame
end

local function priceLabel(item: ItemView): string
	if item.Kind == "GamePass" and owned[item.Id] then
		return "OWNED"
	end
	return "R$ " .. tostring(item.Price)
end

local function setBlur(on: boolean)
	local blur = Lighting:FindFirstChild("ShopBlur") :: BlurEffect?
	if not blur then
		local made = Instance.new("BlurEffect")
		made.Name = "ShopBlur"
		made.Size = 0
		made.Parent = Lighting
		blur = made
	end
	local target = if on then Config.Shop.Motion.MenuBlur else 0
	local seconds = if on then Config.Shop.Motion.PanelOpen else Config.Shop.Motion.PanelClose
	TweenService:Create(blur :: BlurEffect, TweenInfo.new(motion(seconds), Enum.EasingStyle.Quad), { Size = target })
		:Play()
end

local function refreshPrices()
	for id, b in priceButtons do
		local item = itemsById[id]
		b.Text = priceLabel(item)
		local isOwned = item.Kind == "GamePass" and owned[id]
		b.BackgroundColor3 = if isOwned then CHART else GOLD_LO
		b.TextColor3 = if isOwned then PARCHMENT else NAVY
	end
	if muteButton then
		muteButton.Text = if muted then "Suggestions: OFF" else "Suggestions: ON"
	end
end

local function buy(itemId: string)
	Juice.playSound(Config.Shop.Sounds.Open, 0.4)
	intent:FireServer("Buy", itemId)
end

local function toast(message: string, color: Color3)
	local label = text(message, UDim2.fromScale(0.5, 0.07), TITLE_FONT, color, 34)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.18)
	stroke(label, 2, BLACK, Enum.ApplyStrokeMode.Contextual)
	label.Parent = screen
	Juice.popIn(label)
	task.delay(1.6, function()
		label:Destroy()
	end)
end

local function buildGrid()
	for _, child in grid:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	table.clear(priceButtons)
	for _, item in items do
		if item.Tab ~= currentTab then
			continue
		end
		local card = Instance.new("Frame")
		card.Name = item.Id
		card.LayoutOrder = item.Order
		card.BackgroundColor3 = NAVY
		corner(card, 0.06)
		stroke(card, 2, BRASS)

		local cover = makeCover(item, UDim2.fromScale(0.92, 0.56))
		cover.AnchorPoint = Vector2.new(0.5, 0)
		cover.Position = UDim2.fromScale(0.5, 0.04)
		cover.Parent = card

		local name = text(item.Name, UDim2.fromScale(0.92, 0.1), TITLE_FONT, GOLD_HI, 26)
		name.AnchorPoint = Vector2.new(0.5, 0)
		name.Position = UDim2.fromScale(0.5, 0.61)
		name.Parent = card

		local blurb = text(item.Blurb, UDim2.fromScale(0.92, 0.12), BODY_FONT, PARCHMENT, 16)
		blurb.AnchorPoint = Vector2.new(0.5, 0)
		blurb.Position = UDim2.fromScale(0.5, 0.715)
		blurb.Parent = card

		local price = button(priceLabel(item), GOLD_LO, NAVY, 3.2)
		price.AnchorPoint = Vector2.new(0.5, 1)
		price.Position = UDim2.fromScale(0.5, 0.97)
		price.Size = UDim2.fromScale(0.8, 0.13)
		price.Parent = card
		price.Activated:Connect(function()
			buy(item.Id)
		end)
		priceButtons[item.Id] = price
		card.Parent = grid
	end
	refreshPrices()
end

local function openPanel(open: boolean)
	if open == panel.Visible then
		return
	end
	setBlur(open)
	if open then
		Juice.playSound(Config.Shop.Sounds.Open, 0.35)
		buildGrid()
		Juice.popIn(panel)
	else
		panel.Visible = false
	end
end

local function buildPanel()
	panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.Visible = false
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.52)
	panel.Size = UDim2.fromScale(0.9, 0.86)
	panel.BackgroundColor3 = NAVY
	panel.BackgroundTransparency = 0.08
	corner(panel, 0.04)
	stroke(panel, 4, GOLD_LO)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1.55
	ratio.Parent = panel
	local maxSize = Instance.new("UISizeConstraint")
	maxSize.MaxSize = Vector2.new(1100, 710)
	maxSize.Parent = panel
	panel.Parent = screen

	local title = heroText("GRAND LINE SHOP", UDim2.fromScale(0.6, 0.1), 46)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.02)
	title.Parent = panel

	local close = button("X", HAKI_RED, Color3.new(1, 1, 1), 1)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(0.985, 0.025)
	close.Size = UDim2.fromScale(0.07, 0.1)
	close.Parent = panel
	close.Activated:Connect(function()
		openPanel(false)
	end)

	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.fromScale(0.03, 0.13)
	tabs.Size = UDim2.fromScale(0.94, 0.08)
	tabs.Parent = panel
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0.015, 0)
	tabLayout.Parent = tabs
	local tabButtons: { [string]: TextButton } = {}
	local function paintTabs()
		for name, b in tabButtons do
			b.BackgroundColor3 = if name == currentTab then GOLD_LO else CHART
			b.TextColor3 = if name == currentTab then NAVY else PARCHMENT
		end
	end
	for i, name in Config.Shop.Tabs do
		local b = button(string.upper(name), CHART, PARCHMENT, 3)
		b.LayoutOrder = i
		b.Size = UDim2.fromScale(0.2, 1)
		b.Parent = tabs
		tabButtons[name] = b
		b.Activated:Connect(function()
			currentTab = name
			paintTabs()
			buildGrid()
		end)
	end
	paintTabs()

	muteButton = button("Suggestions: ON", CHART, PARCHMENT, 4.2)
	muteButton.AnchorPoint = Vector2.new(1, 0)
	muteButton.Position = UDim2.fromScale(0.97, 0.13)
	muteButton.Size = UDim2.fromScale(0.26, 0.08)
	muteButton.Parent = panel
	muteButton.Activated:Connect(function()
		intent:FireServer(if muted then "Unmute" else "Mute")
		muted = not muted -- instant feedback; the server's Owned event confirms
		refreshPrices()
	end)

	grid = Instance.new("ScrollingFrame")
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromScale(0.03, 0.24)
	grid.Size = UDim2.fromScale(0.94, 0.73)
	grid.ScrollBarThickness = 6
	grid.ScrollBarImageColor3 = GOLD_LO
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(0.235, 0.96)
	layout.CellPadding = UDim2.fromScale(0.018, 0.02)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
end

local function buildShopButton()
	local b = button("SHOP", GOLD_LO, NAVY, 1)
	b.Name = "ShopButton"
	b.FontFace = TITLE_FONT
	b.AnchorPoint = Vector2.new(0, 0.5)
	b.Position = UDim2.new(0, 12, 0.42, 0)
	b.Size = UDim2.fromScale(0.09, 0.09)
	b.SizeConstraint = Enum.SizeConstraint.RelativeYY
	local min = Instance.new("UISizeConstraint")
	min.MinSize = Vector2.new(48, 48)
	min.Parent = b
	b.Parent = screen
	b.Activated:Connect(function()
		openPanel(not panel.Visible)
	end)
end

local function closeOffer(reportDismiss: boolean)
	local card = offerCard
	local itemId = offerItemId
	offerCard = nil
	offerItemId = nil
	if reportDismiss and itemId then
		intent:FireServer("Dismiss", itemId)
	end
	if not card then
		return
	end
	local tween = TweenService:Create(
		card,
		TweenInfo.new(motion(0.2), Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.fromScale(1.5, card.Position.Y.Scale) }
	)
	tween:Play()
	tween.Completed:Once(function()
		card:Destroy()
	end)
end

local function showOffer(itemId: string, reason: string)
	local item = itemsById[itemId]
	if not item then
		return
	end
	closeOffer(false)
	local card = Instance.new("Frame")
	card.Name = "SmartOffer"
	card.AnchorPoint = Vector2.new(1, 0.5)
	card.Position = UDim2.fromScale(1.5, 0.42)
	card.Size = UDim2.fromScale(0.3, 0.62)
	card.BackgroundColor3 = NAVY
	card.BackgroundTransparency = 0.04
	corner(card, 0.05)
	stroke(card, 3, GOLD_LO)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 0.72
	ratio.Parent = card
	local maxSize = Instance.new("UISizeConstraint")
	maxSize.MaxSize = Vector2.new(340, 470)
	maxSize.MinSize = Vector2.new(200, 280)
	maxSize.Parent = card

	local why = text(reason, UDim2.fromScale(0.9, 0.13), BODY_FONT, PARCHMENT, 18)
	why.AnchorPoint = Vector2.new(0.5, 0)
	why.Position = UDim2.fromScale(0.5, 0.03)
	why.Parent = card

	local cover = makeCover(item, UDim2.fromScale(0.82, 0.44))
	cover.AnchorPoint = Vector2.new(0.5, 0)
	cover.Position = UDim2.fromScale(0.5, 0.17)
	cover.Parent = card

	local name = heroText(item.Name, UDim2.fromScale(0.9, 0.09), 30)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.fromScale(0.5, 0.62)
	name.Parent = card

	local blurb = text(item.Blurb, UDim2.fromScale(0.9, 0.08), BODY_FONT, PARCHMENT, 15)
	blurb.AnchorPoint = Vector2.new(0.5, 0)
	blurb.Position = UDim2.fromScale(0.5, 0.71)
	blurb.Parent = card

	local get = button("Get it  R$ " .. tostring(item.Price), GOLD_LO, NAVY, 4)
	get.AnchorPoint = Vector2.new(0.5, 0)
	get.Position = UDim2.fromScale(0.5, 0.8)
	get.Size = UDim2.fromScale(0.86, 0.1)
	get.Parent = card
	get.Activated:Connect(function()
		offerItemId = nil -- a buy is not a dismissal
		buy(item.Id)
		closeOffer(false)
	end)

	local notNow = Instance.new("TextButton")
	notNow.BackgroundTransparency = 1
	notNow.AnchorPoint = Vector2.new(0.5, 0)
	notNow.Position = UDim2.fromScale(0.5, 0.91)
	notNow.Size = UDim2.fromScale(0.6, 0.075)
	notNow.FontFace = BODY_FONT
	notNow.Text = "Not now"
	notNow.TextColor3 = PARCHMENT
	notNow.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 12
	limit.MaxTextSize = 18
	limit.Parent = notNow
	notNow.Parent = card
	Juice.bindButton(notNow)
	notNow.Activated:Connect(function()
		closeOffer(true)
	end)

	card.Parent = screen
	offerCard = card
	offerItemId = itemId
	Juice.playSound(Config.Shop.Sounds.Offer, 0.4)
	TweenService:Create(
		card,
		TweenInfo.new(motion(Config.Shop.Motion.OfferSlide), Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.98, 0, 0.42, 0) }
	):Play()

	task.delay(Config.Shop.Offers.AutoCloseSeconds, function()
		if offerCard == card then
			closeOffer(true)
		end
	end)
end

local function onShopEvent(kind: string, data: { [string]: any })
	if kind == "Offer" then
		if not panel.Visible then
			showOffer(data.itemId, data.reason)
		else
			intent:FireServer("Dismiss", data.itemId) -- never stack on an open shop
		end
	elseif kind == "Owned" then
		table.clear(owned)
		for _, id in data.owned do
			owned[id] = true
		end
		muted = data.muted == true
		refreshPrices()
	elseif kind == "Result" then
		local item = itemsById[data.itemId]
		if data.status == "Granted" then
			if item and item.Kind == "GamePass" then
				owned[item.Id] = true
			end
			refreshPrices()
			toast(if item then item.Name .. " unlocked!" else "Unlocked!", GOLD_HI)
			Juice.shakeCamera(0.3)
		elseif data.status == "ComingSoon" then
			toast("Coming soon!", PARCHMENT)
		elseif data.status == "Owned" then
			toast("You already own this", PARCHMENT)
		end
	end
end

function ShopUI.start()
	local player = Players.LocalPlayer
	intent = Remotes.get("ShopIntent")
	screen = Instance.new("ScreenGui")
	screen.Name = "Shop"
	screen.ResetOnSpawn = false
	screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	screen.DisplayOrder = 20
	screen.Parent = player:WaitForChild("PlayerGui")
	buildPanel()
	buildShopButton()
	Remotes.get("ShopEvent").OnClientEvent:Connect(onShopEvent)

	-- Slow spin on every placeholder cover's rays (skipped with Reduced Motion).
	RunService.RenderStepped:Connect(function(dt: number)
		if GuiService.ReducedMotionEnabled then
			return
		end
		local step = Config.Shop.Motion.RaySpinDegPerSec * dt
		for i = #spinners, 1, -1 do
			local s = spinners[i]
			if s.Parent == nil then
				table.remove(spinners, i)
			else
				s.Rotation = (s.Rotation + step) % 360
			end
		end
	end)
end

return ShopUI
