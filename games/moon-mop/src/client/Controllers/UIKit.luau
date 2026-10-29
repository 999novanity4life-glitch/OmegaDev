--!strict
-- Builds UI from UITokens so every screen shares one look: carbon surfaces,
-- chrome strokes, orange accent, the same radii, padding and motion.
-- Mobile-first (CLAUDE.md rule 5): Scale sizing, an aspect-ratio constraint
-- on buttons, text never below the token floor, safe-area insets on screens.
-- Not yet run in Studio: verify with docs/VISUAL_QA.md before relying on it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UITokens = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UITokens"))
local Juice = require(script.Parent.Juice)

type RGB = UITokens.RGB

local UIKit = {}

local function rgb(c: RGB): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function corner(parent: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: GuiObject, thickness: number, color: RGB)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Thickness = thickness
	s.Color = rgb(color)
	s.Parent = parent
end

local function padding(parent: GuiObject, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
end

-- A ScreenGui whose content stays clear of the device notch and Roblox's
-- top-bar buttons.
function UIKit.screen(name: string, parent: Instance): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = parent
	return gui
end

-- A rounded panel on the Surface color.
function UIKit.panel(size: UDim2, raised: boolean?): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.BackgroundColor3 = rgb(if raised then UITokens.Color.SurfaceRaised else UITokens.Color.Surface)
	frame.BorderSizePixel = 0
	corner(frame, UITokens.Radius.Large)
	stroke(frame, UITokens.Stroke.Hairline, UITokens.Color.Stroke)
	padding(frame, UITokens.Space.L)
	return frame
end

export type ButtonStyle = "Primary" | "Secondary"

-- A button with press feedback (Juice.bindButton) wired in. `aspect` is
-- width / height; the size is in Scale so it holds on every screen.
function UIKit.button(text: string, size: UDim2, style: ButtonStyle?, aspect: number?): TextButton
	local primary = style ~= "Secondary"
	local button = Instance.new("TextButton")
	button.Size = size
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.BackgroundColor3 = rgb(if primary then UITokens.Color.Accent else UITokens.Color.SurfaceRaised)
	button.TextColor3 = rgb(if primary then UITokens.Color.AccentText else UITokens.Color.Text)
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextScaled = true
	corner(button, UITokens.Radius.Medium)
	stroke(button, UITokens.Stroke.Regular, if primary then UITokens.Color.Accent else UITokens.Color.Stroke)
	padding(button, UITokens.Space.S)

	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MinTextSize = UITokens.MIN_TEXT
	textLimit.MaxTextSize = UITokens.Text.Button
	textLimit.Parent = button

	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = aspect or 3
	ratio.Parent = button

	-- Keep tap targets at least MIN_TOUCH px on small screens.
	local minSize = Instance.new("UISizeConstraint")
	minSize.MinSize = Vector2.new(UITokens.MIN_TOUCH * (aspect or 3), UITokens.MIN_TOUCH)
	minSize.Parent = button

	Juice.bindButton(button)
	return button
end

-- A text label in a token size and color.
function UIKit.label(text: string, size: UDim2, textSize: number?, muted: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = rgb(if muted then UITokens.Color.TextMuted else UITokens.Color.Text)
	label.TextSize = math.max(UITokens.MIN_TEXT, textSize or UITokens.Text.Body)
	label.TextWrapped = true
	return label
end

return UIKit
