--!strict
-- The mini-game window: Pipe Repair, Wire Fix and Memory Lights. Draws the
-- puzzle the server sent, sends moves, and shows the server's answers.
-- The server decides every move; this only renders and gives feedback.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PuzzleGen = require(Shared:WaitForChild("PuzzleGen"))
local Juice = require(script.Parent.Juice)
local AmbienceController = require(script.Parent.AmbienceController)

local MiniGameController = {}

local player = Players.LocalPlayer
local FONT = Font.fromName("FredokaOne")
local DARK = Color3.fromRGB(24, 18, 38)
local PANEL = Color3.fromRGB(40, 32, 62)
local HAZARD = Color3.fromRGB(255, 201, 60)
local RED = Color3.fromRGB(255, 90, 100)
local ART = Config.PuzzleArt
local CANON = { ["end"] = 1, straight = 5, elbow = 3, tee = 7, cross = 15 }

local remote: RemoteEvent
local gui: ScreenGui
local window: Frame
local title: TextLabel
local hint: TextLabel
local content: Frame
local currentId: string? = nil
local onState: ((data: any) -> ())? = nil

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function stroke(parent: Instance, thickness: number, color: Color3, border: boolean?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	if border then
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	s.Parent = parent
	return s
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = FONT
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	for k, v in props do
		(l :: any)[k] = v
	end
	stroke(l, 2, DARK)
	l.Parent = parent
	return l
end

-- Pipe shape + rotation for a connection mask.
local function pipeLook(mask: number): (string, number)
	local bits = 0
	for _, b in { 1, 2, 4, 8 } do
		if bit32.band(mask, b) ~= 0 then
			bits += 1
		end
	end
	local shape = if bits == 1
		then "end"
		elseif bits == 2 and (mask == 5 or mask == 10) then "straight"
		elseif bits == 2 then "elbow"
		elseif bits == 3 then "tee"
		else "cross"
	for k = 0, 3 do
		if PuzzleGen.rotateMask(CANON[shape], k) == mask then
			return shape, k * 90
		end
	end
	return shape, 0
end

local function close(sendToServer: boolean)
	if currentId and sendToServer then
		remote:FireServer(currentId, "close")
	end
	currentId = nil
	onState = nil
	window.Visible = false
	gui.Enabled = false
	content:ClearAllChildren()
end

local function success()
	local burst = text(content, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.3),
		Text = "FIXED!",
		TextColor3 = Config.Colors.Slime,
		ZIndex = 20,
	})
	Juice.popIn(burst)
	AmbienceController.play("Solve", 0.7)
	task.delay(1.1, function()
		close(false)
	end)
end

local function shake(target: GuiObject)
	local base = target.Position
	for i = 1, 4 do
		local dx = if i % 2 == 0 then -0.01 else 0.01
		target.Position = base + UDim2.fromScale(dx, 0)
		task.wait(0.04)
	end
	target.Position = base
end

-- Pipe Repair ---------------------------------------------------------------

local function openPipes(data: any)
	hint.Text = "Turn the pipes so slime reaches every one"
	local w, h = data.width :: number, data.height :: number
	local masks: { number } = data.masks
	local grid = Instance.new("Frame")
	grid.AnchorPoint = Vector2.new(0.5, 0.5)
	grid.Position = UDim2.fromScale(0.54, 0.5)
	grid.Size = UDim2.fromScale(0.86, 0.86)
	grid.BackgroundColor3 = DARK
	grid.Parent = content
	corner(grid, 0.04)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = w / h
	ratio.Parent = grid
	local tiles: { ImageButton } = {}
	local flowing: { [number]: boolean } = {}
	local function draw(i: number)
		local shape, rot = pipeLook(masks[i])
		local art = ART.Pipe[shape]
		tiles[i].Image = if flowing[i] then art.on else art.off
		tiles[i].Rotation = rot
	end
	for i = 1, w * h do
		local x, y = (i - 1) % w, (i - 1) // w
		local tile = Instance.new("ImageButton")
		tile.BackgroundTransparency = 1
		tile.AutoButtonColor = false
		tile.Size = UDim2.fromScale(1 / w, 1 / h)
		tile.Position = UDim2.fromScale(x / w, y / h)
		tile.Parent = grid
		tiles[i] = tile
		tile.Activated:Connect(function()
			if not currentId then
				return
			end
			AmbienceController.play("Valve", 0.35)
			-- Instant feel: spin now, the server's answer corrects it.
			TweenService:Create(tile, TweenInfo.new(0.12), { Rotation = tile.Rotation + 90 }):Play()
			remote:FireServer(currentId, "rotate", i)
		end)
	end
	flowing[data.source] = true
	for i = 1, w * h do
		draw(i)
	end
	-- The slime tank feeding the source tile, on the left edge.
	local tank = Instance.new("Frame")
	tank.AnchorPoint = Vector2.new(1, 0.5)
	tank.Position = UDim2.new(0, -4, ((data.source - 1) // w + 0.5) / h, 0)
	tank.Size = UDim2.fromScale(0.08, 0.6 / h)
	tank.BackgroundColor3 = Config.Colors.Slime
	tank.Parent = grid
	corner(tank, 0.4)
	stroke(tank, 3, DARK, true)
	onState = function(state: any)
		if state.index then
			masks[state.index] = state.mask
		end
		if state.flow then
			table.clear(flowing)
			for _, i in state.flow do
				flowing[i] = true
			end
		end
		for i = 1, w * h do
			draw(i)
		end
	end
end

-- Wire Fix ------------------------------------------------------------------

local function line(parent: Frame, a: Vector2, b: Vector2, color: Color3): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	local origin = parent.AbsolutePosition
	local mid = (a + b) / 2 - origin
	f.Position = UDim2.fromOffset(mid.X, mid.Y)
	f.Size = UDim2.fromOffset((b - a).Magnitude, 12)
	f.Rotation = math.deg(math.atan2(b.Y - a.Y, b.X - a.X))
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = 3
	corner(f, 1)
	stroke(f, 2, DARK, true)
	f.Parent = parent
	return f
end

local function openWires(data: any)
	hint.Text = "Drag each wire to its matching plug"
	local left: { number }, right: { number } = data.left, data.right
	local n = #left
	local board = Instance.new("Frame")
	board.Size = UDim2.fromScale(1, 1)
	board.BackgroundTransparency = 1
	board.Parent = content
	local leftPlugs: { Frame } = {}
	local rightPlugs: { Frame } = {}
	local function plug(side: number, slot: number, colorIndex: number): Frame
		local sym = ART.Symbols[colorIndex]
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(if side == 1 then 0.12 else 0.88, (slot - 0.5) / n)
		f.Size = UDim2.fromScale(0.16, 0.8 / n)
		f.BackgroundColor3 = sym.color
		f.Parent = board
		corner(f, 0.25)
		stroke(f, 3, DARK, true)
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.Parent = f
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Image = sym.image
		icon.ImageColor3 = DARK
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Size = UDim2.fromScale(0.62, 0.62)
		icon.Parent = f
		-- Socket housing behind the plug.
		local housing = Instance.new("Frame")
		housing.AnchorPoint = Vector2.new(0.5, 0.5)
		housing.Position = UDim2.fromScale(if side == 1 then -0.35 else 1.35, 0.5)
		housing.Size = UDim2.fromScale(0.5, 0.5)
		housing.BackgroundColor3 = Color3.fromRGB(150, 156, 176)
		housing.ZIndex = 0
		housing.Parent = f
		corner(housing, 0.3)
		return f
	end
	for i = 1, n do
		leftPlugs[i] = plug(1, i, left[i])
		rightPlugs[i] = plug(2, i, right[i])
	end
	local pending: { [number]: Frame } = {}
	local dragging: { slot: number, wire: Frame? }? = nil
	local function centre(f: Frame): Vector2
		return f.AbsolutePosition + f.AbsoluteSize / 2
	end
	local function pointer(input: InputObject): Vector2
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	for i, f in leftPlugs do
		f.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			if pending[i] then
				return
			end
			dragging = { slot = i, wire = nil }
		end)
	end
	local moveConn = UserInputService.InputChanged:Connect(function(input)
		local d = dragging
		if not d then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if d.wire then
			d.wire:Destroy()
		end
		d.wire = line(board, centre(leftPlugs[d.slot]), pointer(input), ART.Symbols[left[d.slot]].color)
	end)
	local endConn = UserInputService.InputEnded:Connect(function(input)
		local d = dragging
		if not d then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		dragging = nil
		local at = pointer(input)
		local target: number? = nil
		for r, f in rightPlugs do
			local p, s = f.AbsolutePosition, f.AbsoluteSize
			if at.X >= p.X - 12 and at.X <= p.X + s.X + 12 and at.Y >= p.Y - 12 and at.Y <= p.Y + s.Y + 12 then
				target = r
			end
		end
		if d.wire then
			d.wire:Destroy()
		end
		if target and currentId then
			pending[d.slot] =
				line(board, centre(leftPlugs[d.slot]), centre(rightPlugs[target]), ART.Symbols[left[d.slot]].color)
			remote:FireServer(currentId, "connect", d.slot, target)
		end
	end)
	board.Destroying:Connect(function()
		moveConn:Disconnect()
		endConn:Disconnect()
	end)
	onState = function(state: any)
		local l, r = state.left :: number, state.right :: number
		if state.ok then
			AmbienceController.play("Valve", 0.4)
			if not pending[l] then
				pending[l] = line(board, centre(leftPlugs[l]), centre(rightPlugs[r]), ART.Symbols[left[l]].color)
			end
			for _, f in { leftPlugs[l], rightPlugs[r] } do
				local s = f:FindFirstChildOfClass("UIStroke") :: UIStroke
				s.Color = Color3.new(1, 1, 1)
			end
			Juice.popIn(rightPlugs[r])
		else
			AmbienceController.play("Slimed", 0.35)
			if pending[l] then
				pending[l]:Destroy()
				pending[l] = nil
			end
			local s = rightPlugs[r]:FindFirstChildOfClass("UIStroke") :: UIStroke
			s.Color = RED
			task.delay(0.4, function()
				s.Color = DARK
			end)
			task.spawn(shake, rightPlugs[r])
		end
	end
end

-- Memory Lights -------------------------------------------------------------

local function openMemory(data: any)
	local pads: { TextButton } = {}
	local base: { Color3 } = {}
	local inputLocked = true
	local roundLabel = text(content, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.6, 0.1),
		TextColor3 = HAZARD,
	})
	local grid = Instance.new("Frame")
	grid.AnchorPoint = Vector2.new(0.5, 1)
	grid.Position = UDim2.fromScale(0.5, 1)
	grid.Size = UDim2.fromScale(0.84, 0.86)
	grid.BackgroundTransparency = 1
	grid.Parent = content
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = grid
	for i = 1, 4 do
		local sym = ART.Symbols[i]
		local b = Instance.new("TextButton")
		b.Text = ""
		b.AutoButtonColor = false
		b.Size = UDim2.fromScale(0.46, 0.46)
		b.Position = UDim2.fromScale(((i - 1) % 2) * 0.54, ((i - 1) // 2) * 0.54)
		local h, s, v = sym.color:ToHSV()
		base[i] = Color3.fromHSV(h, s * 0.8, v * 0.45)
		b.BackgroundColor3 = base[i]
		b.Parent = grid
		corner(b, 0.2)
		stroke(b, 4, DARK, true)
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Image = sym.image
		icon.ImageColor3 = Color3.new(1, 1, 1)
		icon.ImageTransparency = 0.3
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Size = UDim2.fromScale(0.5, 0.5)
		icon.Parent = b
		pads[i] = b
	end
	local function flash(i: number, seconds: number)
		local pad = pads[i]
		pad.BackgroundColor3 = ART.Symbols[i].color
		Juice.popIn(pad)
		task.delay(seconds, function()
			if pad.Parent then
				TweenService:Create(pad, TweenInfo.new(0.15), { BackgroundColor3 = base[i] }):Play()
			end
		end)
	end
	local function play(sequence: { number }, round: number)
		inputLocked = true
		roundLabel.Text = string.format("WATCH  ·  ROUND %d/3", round)
		task.wait(0.6)
		for _, i in sequence do
			if not pads[i].Parent then
				return
			end
			flash(i, 0.35)
			AmbienceController.play("Valve", 0.3)
			task.wait(0.6)
		end
		roundLabel.Text = string.format("YOUR TURN  ·  ROUND %d/3", round)
		inputLocked = false
	end
	for i, pad in pads do
		pad.Activated:Connect(function()
			if inputLocked or not currentId then
				return
			end
			flash(i, 0.2)
			remote:FireServer(currentId, "press", i)
		end)
	end
	hint.Text = "Watch the lights, then repeat them"
	task.spawn(play, data.sequence, data.round)
	onState = function(state: any)
		if state.sequence then
			if not state.ok then
				roundLabel.Text = "TRY AGAIN!"
				AmbienceController.play("Slimed", 0.35)
				task.spawn(shake, grid)
			end
			task.spawn(play, state.sequence, state.round)
		end
	end
end

-- Window ----------------------------------------------------------------------

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "MiniGame"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Enabled = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.5
	dim.Parent = gui
	window = Instance.new("Frame")
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.52)
	window.Size = UDim2.fromScale(0.62, 0.78)
	window.BackgroundColor3 = PANEL
	window.Visible = false
	window.Parent = gui
	corner(window, 0.05)
	stroke(window, 5, Config.Colors.Slime, true)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 0.92
	ratio.Parent = window
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(640, 700)
	limit.Parent = window
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(70, 58, 104), DARK)
	gradient.Rotation = 90
	gradient.Parent = window
	local header = Instance.new("Frame")
	header.Size = UDim2.fromScale(1, 0.12)
	header.BackgroundColor3 = HAZARD
	header.BorderSizePixel = 0
	header.Parent = window
	corner(header, 0.35)
	local stripes = Instance.new("UIGradient")
	local keys = {}
	for i = 0, 12 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 12, if i % 2 == 0 then HAZARD else DARK))
	end
	stripes.Color = ColorSequence.new(keys)
	stripes.Rotation = 25
	stripes.Parent = header
	title = text(window, { Size = UDim2.fromScale(0.7, 0.1), Position = UDim2.fromScale(0.15, 0.01) })
	hint = text(window, {
		Size = UDim2.fromScale(0.9, 0.06),
		Position = UDim2.fromScale(0.05, 0.14),
		TextColor3 = Color3.fromRGB(210, 220, 255),
	})
	local closeButton = Instance.new("TextButton")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(0.98, 0.015)
	closeButton.Size = UDim2.fromScale(0.09, 0.09)
	closeButton.BackgroundColor3 = RED
	closeButton.Text = "X"
	closeButton.FontFace = FONT
	closeButton.TextScaled = true
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Parent = window
	corner(closeButton, 1)
	stroke(closeButton, 3, DARK, true)
	local closeRatio = Instance.new("UIAspectRatioConstraint")
	closeRatio.Parent = closeButton
	Juice.bindButton(closeButton)
	closeButton.Activated:Connect(function()
		close(true)
	end)
	content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromScale(0.06, 0.22)
	content.Size = UDim2.fromScale(0.88, 0.74)
	content.Parent = window
end

function MiniGameController.start()
	remote = Remotes.get("MiniGame")
	build()
	Remotes.get("Notify").OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "MiniGameOpen" and type(data) == "table" then
			content:ClearAllChildren()
			currentId = data.id
			title.Text = tostring(data.title)
			gui.Enabled = true
			window.Visible = true
			Juice.popIn(window)
			if data.kind == "Pipes" then
				openPipes(data)
			elseif data.kind == "Wires" then
				openWires(data)
			else
				openMemory(data)
			end
		elseif kind == "MiniGameState" and type(data) == "table" and data.id == currentId then
			local handler = onState
			if handler then
				handler(data)
			end
		elseif kind == "MiniGameDone" and type(data) == "table" and data.id == currentId then
			if data.closed then
				close(false)
			else
				success()
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and currentId then
			close(true)
		end
	end)
end

return MiniGameController
