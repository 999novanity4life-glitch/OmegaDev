--!strict
-- The objective marker: a slime-green pin floating over the floor's active
-- puzzle (or the exit lift once every floor is solved). It bobs over a
-- pulsing glow ring, shows through walls, reads out the distance, fades as
-- you reach the puzzle (the themed interact button takes over there), and an
-- arrow at the screen edge points to it whenever it is off-screen.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MatchState = require(script.Parent.MatchState)

local MarkerController = {}

local player = Players.LocalPlayer
local FONT = Font.fromName("FredokaOne")
local DARK = Color3.fromRGB(26, 18, 48)

local function objective(): Vector3?
	local x, y, z = MatchState.number("ObjectiveX"), MatchState.number("ObjectiveY"), MatchState.number("ObjectiveZ")
	if x and y and z then
		return Vector3.new(x, y, z)
	end
	return nil
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = FONT
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	for key, value in props do
		(l :: any)[key] = value
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = DARK
	stroke.Parent = l
	l.Parent = parent
	return l
end

function MarkerController.start()
	local gui = player:WaitForChild("PlayerGui")

	-- World marker: an invisible client-only anchor carrying the billboard.
	local anchor = Instance.new("Part")
	anchor.Name = "ObjectiveAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Parent = workspace

	local board = Instance.new("BillboardGui")
	board.Name = "ObjectiveMarker"
	board.Size = UDim2.fromOffset(92, 128)
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.MaxDistance = math.huge
	board.ResetOnSpawn = false
	board.Adornee = anchor
	board.Enabled = false
	board.Parent = gui

	local ring = Instance.new("ImageLabel")
	ring.BackgroundTransparency = 1
	ring.Image = Config.Icons.MarkerRing
	ring.ImageColor3 = Config.Colors.Slime
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.4)
	ring.Size = UDim2.fromOffset(86, 86)
	ring.Parent = board

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = Config.Icons.MarkerPin
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.36)
	icon.Size = UDim2.fromOffset(76, 76)
	icon.Parent = board

	local distance = label(board, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.74),
		Size = UDim2.fromOffset(84, 26),
		Text = "",
	})

	-- Off-screen pointer.
	local screen = Instance.new("ScreenGui")
	screen.Name = "ObjectivePointer"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 4
	screen.Parent = gui
	local arrow = Instance.new("ImageLabel")
	arrow.BackgroundTransparency = 1
	arrow.Image = Config.Icons.MarkerArrow
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(58, 58)
	arrow.Visible = false
	arrow.Parent = screen
	local arrowPin = Instance.new("ImageLabel")
	arrowPin.BackgroundTransparency = 1
	arrowPin.Image = Config.Icons.MarkerPin
	arrowPin.AnchorPoint = Vector2.new(0.5, 0.5)
	arrowPin.Size = UDim2.fromOffset(40, 40)
	arrowPin.Visible = false
	arrowPin.Parent = screen

	local cfg = Config.Marker
	RunService.RenderStepped:Connect(function()
		local target = objective()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local show = target ~= nil
			and root ~= nil
			and MatchState.inRound()
			and player:GetAttribute("Cutscene") ~= true
			and player:GetAttribute("MatchId") ~= nil
		if not show or not target or not root then
			board.Enabled = false
			arrow.Visible = false
			arrowPin.Visible = false
			return
		end
		local now = os.clock()
		local calm = GuiService.ReducedMotionEnabled
		anchor.Position = target + Vector3.new(0, cfg.Height, 0)

		-- Fade out as you arrive: the interact button takes over up close.
		local dist = (root.Position - target).Magnitude
		local fade = math.clamp((dist - cfg.FadeNear) / (cfg.FadeFar - cfg.FadeNear), 0, 1)
		board.Enabled = fade > 0.02
		icon.ImageTransparency = 1 - fade
		distance.TextTransparency = 1 - fade
		distance.Text = string.format("%dm", math.floor(dist * 0.28 + 0.5))
		if calm then
			icon.Position = UDim2.fromScale(0.5, 0.36)
			ring.Size = UDim2.fromOffset(86, 86)
			ring.ImageTransparency = 1 - 0.55 * fade
		else
			icon.Position = UDim2.new(0.5, 0, 0.36, math.sin(now * 2.4) * 6)
			local pulse = (now * 0.8) % 1
			local s = 60 + pulse * 56
			ring.Size = UDim2.fromOffset(s, s)
			ring.ImageTransparency = 1 - (1 - pulse) * 0.8 * fade
		end

		-- Off-screen: an arrow at the edge pointing the way, with the pin beside it.
		local camera = workspace.CurrentCamera
		local vp = camera:WorldToViewportPoint(anchor.Position)
		local size = camera.ViewportSize
		local margin = cfg.EdgeMargin
		local onScreen = vp.Z > 0
			and vp.X > margin
			and vp.X < size.X - margin
			and vp.Y > margin
			and vp.Y < size.Y - margin
		if onScreen then
			arrow.Visible = false
			arrowPin.Visible = false
			return
		end
		local cx, cy = size.X / 2, size.Y / 2
		local dx, dy = vp.X - cx, vp.Y - cy
		if vp.Z < 0 then
			dx, dy = -dx, -dy
		end
		if math.abs(dx) < 1e-3 and math.abs(dy) < 1e-3 then
			dy = 1
		end
		local sx = (cx - margin) / math.max(math.abs(dx), 1e-3)
		local sy = (cy - margin) / math.max(math.abs(dy), 1e-3)
		local k = math.min(sx, sy)
		local ex, ey = cx + dx * k, cy + dy * k
		local angle = math.deg(math.atan2(dy, dx))
		arrow.Position = UDim2.fromOffset(ex, ey)
		arrow.Rotation = angle
		local back = 44 / math.sqrt(dx * dx + dy * dy)
		arrowPin.Position = UDim2.fromOffset(ex - dx * back, ey - dy * back)
		arrow.Visible = true
		arrowPin.Visible = true
		if not calm then
			arrow.Size = UDim2.fromOffset(58 + math.sin(now * 5) * 4, 58 + math.sin(now * 5) * 4)
		end
	end)
end

return MarkerController
