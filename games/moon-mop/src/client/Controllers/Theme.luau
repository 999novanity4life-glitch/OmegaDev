--!strict
-- The Moon Mop menu look, from the reference frames (P1 f_003, f_145, f_181, f_403): a dark
-- slate card with an orange and black hazard stripe along the top, a heavy white title, a teal
-- category label, green tags for affordable and red for too expensive, an orange selected row and
-- an orange buy button. Mobile-first (CLAUDE.md rule 5): Scale sizes, aspect constraints, text
-- never under 9 px, safe-area insets on every screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UITokens = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UITokens"))
local Juice = require(script.Parent.Juice)

local Theme = {}

Theme.SLATE = Color3.fromRGB(30, 34, 42)
Theme.SLATE_HI = Color3.fromRGB(44, 50, 60)
Theme.SLATE_LO = Color3.fromRGB(20, 23, 29)
Theme.ORANGE = Color3.fromRGB(255, 132, 28)
Theme.AMBER = Color3.fromRGB(255, 190, 60)
Theme.YELLOW = Color3.fromRGB(255, 214, 50)
Theme.TEAL = Color3.fromRGB(64, 224, 208)
Theme.GREEN = Color3.fromRGB(92, 214, 120)
Theme.RED = Color3.fromRGB(255, 84, 84)
Theme.WHITE = Color3.fromRGB(242, 244, 248)
Theme.MUTED = Color3.fromRGB(168, 176, 190)
Theme.BLACK = Color3.fromRGB(14, 14, 16)

function Theme.corner(parent: GuiObject, px: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = parent
end

function Theme.stroke(parent: GuiObject, color: Color3, thickness: number, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

function Theme.pad(parent: GuiObject, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = parent
end

function Theme.screen(name: string, parent: Instance, order: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = order or 0
	gui.Parent = parent
	return gui
end

function Theme.frame(size: UDim2, pos: UDim2?, color: Color3?, transparency: number?): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos or UDim2.new()
	f.BackgroundColor3 = color or Theme.SLATE
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	return f
end

function Theme.text(text: string, size: UDim2, color: Color3?, font: Enum.Font?, maxSize: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Text = text
	l.TextColor3 = color or Theme.WHITE
	l.Font = font or Enum.Font.GothamBold
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = math.max(UITokens.MIN_TEXT, 10)
	limit.MaxTextSize = maxSize or 28
	limit.Parent = l
	return l
end

-- Orange and black hazard stripe, clipped to a bar.
function Theme.stripe(parent: GuiObject, height: number, pos: UDim2?): Frame
	local bar = Theme.frame(UDim2.new(1, 0, 0, height), pos or UDim2.new(), Theme.BLACK)
	bar.ClipsDescendants = true
	bar.Name = "Hazard"
	for i = -2, 60 do
		local s =
			Theme.frame(UDim2.new(0, height * 0.7, 0, height * 3), UDim2.new(0, i * height * 1.4, 0.5, 0), Theme.ORANGE)
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Rotation = 40
		s.Parent = bar
	end
	bar.Parent = parent
	return bar
end

-- A menu card: hazard stripe, title, teal category label and a close button. Returns the card
-- and the body frame to fill.
function Theme.card(gui: ScreenGui, title: string, category: string, size: UDim2): (Frame, Frame, TextButton)
	local card = Theme.frame(size, UDim2.fromScale(0.5, 0.5), Theme.SLATE, 0.04)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Name = title
	card.Visible = false
	card.ClipsDescendants = true
	Theme.corner(card, 10)
	Theme.stroke(card, Color3.fromRGB(70, 78, 92), 1.5)
	Theme.stripe(card, 10)
	local cat = Theme.text(string.upper(category), UDim2.new(0.6, 0, 0, 18), Theme.TEAL, Enum.Font.GothamBold, 16)
	cat.Position = UDim2.new(0, 18, 0, 18)
	cat.Parent = card
	local head = Theme.text(string.upper(title), UDim2.new(0.75, 0, 0, 34), Theme.WHITE, Enum.Font.GothamBlack, 34)
	head.Position = UDim2.new(0, 18, 0, 36)
	head.Parent = card
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.new(0, 44, 0, 44)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 20)
	close.BackgroundColor3 = Theme.SLATE_HI
	close.Text = "X"
	close.TextColor3 = Theme.WHITE
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 22
	close.AutoButtonColor = false
	Theme.corner(close, 8)
	close.Parent = card
	Juice.bindButton(close)
	local body = Theme.frame(UDim2.new(1, -36, 1, -92), UDim2.new(0, 18, 0, 80), Theme.SLATE, 1)
	body.Name = "Body"
	body.Parent = card
	card.Parent = gui
	local ratio = Instance.new("UISizeConstraint")
	ratio.MaxSize = Vector2.new(1100, 720)
	ratio.Parent = card
	return card, body, close
end

export type ButtonStyle = "Orange" | "Dark" | "Green" | "Red"

function Theme.button(text: string, size: UDim2, style: ButtonStyle?): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.BackgroundColor3 = if style == "Dark"
		then Theme.SLATE_HI
		elseif style == "Green" then Theme.GREEN
		elseif style == "Red" then Theme.RED
		else Theme.ORANGE
	b.TextColor3 = if style == "Dark" then Theme.WHITE else Theme.BLACK
	b.Font = Enum.Font.GothamBlack
	b.Text = text
	b.TextScaled = true
	Theme.corner(b, 8)
	Theme.pad(b, 6)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 11
	limit.MaxTextSize = 22
	limit.Parent = b
	local min = Instance.new("UISizeConstraint")
	min.MinSize = Vector2.new(UITokens.MIN_TOUCH, UITokens.MIN_TOUCH)
	min.Parent = b
	Juice.bindButton(b)
	return b
end

-- Small price/status tag: green when affordable, red when not, slate for owned/info.
function Theme.tag(text: string, kind: "Good" | "Bad" | "Info" | "Owned"): TextLabel
	local t = Theme.text(text, UDim2.new(0, 96, 0, 24), Theme.BLACK, Enum.Font.GothamBlack, 16)
	t.BackgroundTransparency = 0
	t.BackgroundColor3 = if kind == "Good"
		then Theme.GREEN
		elseif kind == "Bad" then Theme.RED
		elseif kind == "Owned" then Theme.TEAL
		else Theme.SLATE_HI
	if kind == "Info" then
		t.TextColor3 = Theme.WHITE
	end
	t.TextXAlignment = Enum.TextXAlignment.Center
	Theme.corner(t, 5)
	return t
end

function Theme.money(n: number): string
	if n >= 1e6 then
		return string.format("$%.2fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("$%.1fk", n / 1e3)
	elseif n >= 100 or n == math.floor(n) then
		return string.format("$%d", math.floor(n + 0.5))
	end
	return string.format("$%.2f", n)
end

function Theme.kg(n: number): string
	if n >= 1000 then
		return string.format("%.2f T", n / 1000)
	elseif n >= 10 then
		return string.format("%.1f", n)
	end
	return string.format("%.2f", n)
end

-- A mass with its unit, switching to tonnes from 1000 kg ("40.0 kg", "1.20 t").
function Theme.mass(n: number): string
	if n >= 1000 then
		return string.format("%.2f t", n / 1000)
	end
	return Theme.kg(n) .. " kg"
end

-- A scrolling list body with a vertical layout.
function Theme.list(parent: Instance, size: UDim2, pos: UDim2?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Size = size
	s.Position = pos or UDim2.new()
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = Theme.ORANGE
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.CanvasSize = UDim2.new()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = s
	s.Parent = parent
	return s
end

return Theme
