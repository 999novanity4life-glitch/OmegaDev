--!strict
-- Powers on the client: the power button, keys (Q use, E switch), instant
-- local movement for feel, then a UsePower request the server validates.
-- Effects for everyone play when the server answers with PowerFx.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Powers = require(Shared:WaitForChild("Powers"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Juice = require(script.Parent.Juice)

local PowerController = {}

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("RoundState")
local FONT = Font.fromName("FredokaOne")
local DARK = Color3.fromRGB(24, 18, 38)
local NAMES = { Dash = "DASH", Shield = "BUBBLE", Grapple = "GOO HOOK" }
local ICONS: { [string]: string } =
	{ Dash = Config.Icons.Dash, Shield = Config.Icons.Shield, Grapple = Config.Icons.Grapple }

local active = Powers.activeIds()
local selected = 1
local lastUsed: { [string]: number } = {}
local doubleJumpUsed = false

local function crowns(): number
	local value = player:GetAttribute("Crowns")
	return if type(value) == "number" then value else 0
end

local function parts(): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, nil, nil
	end
	return character, root, humanoid
end

local function inRound(): boolean
	local slimeStart = state:GetAttribute("SlimeStart")
	return state:GetAttribute("State") == "Round" and type(slimeStart) == "number"
end

-- Effects ------------------------------------------------------------------

local fxFolder = Instance.new("Folder")
fxFolder.Name = "PowerFx"
fxFolder.Parent = workspace

local function fade(part: BasePart, seconds: number)
	TweenService:Create(part, TweenInfo.new(seconds), { Transparency = 1 }):Play()
	task.delay(seconds, function()
		part:Destroy()
	end)
end

-- Green see-through copies of the body left behind while dashing.
local function afterimages(character: Model, seconds: number)
	local stop = os.clock() + seconds
	task.spawn(function()
		while os.clock() < stop and character.Parent do
			for _, item in character:GetChildren() do
				if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
					local ghost = Instance.new("Part")
					ghost.Anchored = true
					ghost.CanCollide = false
					ghost.CanQuery = false
					ghost.CanTouch = false
					ghost.CastShadow = false
					ghost.Material = Enum.Material.Neon
					ghost.Color = Config.Colors.Slime
					ghost.Transparency = 0.45
					ghost.Size = item.Size
					ghost.CFrame = item.CFrame
					ghost.Parent = fxFolder
					fade(ghost, 0.3)
				end
			end
			task.wait(0.05)
		end
	end)
end

local function splat(position: Vector3)
	local blob = Instance.new("Part")
	blob.Shape = Enum.PartType.Ball
	blob.Anchored = true
	blob.CanCollide = false
	blob.CanQuery = false
	blob.CanTouch = false
	blob.Material = Enum.Material.Neon
	blob.Color = Config.Colors.Slime
	blob.Size = Vector3.one * 1.5
	blob.Position = position
	blob.Parent = fxFolder
	TweenService:Create(blob, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = Vector3.one * 6 }):Play()
	fade(blob, 0.35)
end

local function shieldBubble(character: Model, seconds: number)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local bubble = Instance.new("Part")
	bubble.Name = "ShieldBubble"
	bubble.Shape = Enum.PartType.Ball
	bubble.Massless = true
	bubble.CanCollide = false
	bubble.CanQuery = false
	bubble.CanTouch = false
	bubble.CastShadow = false
	bubble.Material = Enum.Material.ForceField
	bubble.Color = Config.Colors.Slime
	bubble.Size = Vector3.one * 2
	bubble.CFrame = root.CFrame
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bubble
	weld.Part1 = root
	weld.Parent = bubble
	bubble.Parent = character
	TweenService:Create(bubble, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = Vector3.one * 8 }):Play()
	task.delay(seconds, function()
		if bubble.Parent then
			fade(bubble, 0.25)
		end
	end)
end

local function gooBall(size: number, color: Color3): Part
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.Material = Enum.Material.Glass
	ball.Reflectance = 0.1
	ball.Color = color
	ball.Size = Vector3.one * size
	ball.Parent = fxFolder
	return ball
end

-- Goo rope: thick dark goo with a glowing core, wobbling beads riding it,
-- drips falling off, and a fat splat stuck where it hit.
local function rope(character: Model, target: Vector3, seconds: number)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = target
	anchor.Parent = fxFolder
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0.6, 0.8, -0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Parent = anchor
	local function beam(width0: number, width1: number, color: Color3, emission: number, transparency: number): Beam
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Color = ColorSequence.new(color)
		b.LightEmission = emission
		b.Transparency = NumberSequence.new(transparency)
		b.Width0 = width0
		b.Width1 = width1
		b.FaceCamera = true
		b.Segments = 20
		b.CurveSize0 = 1.5
		b.CurveSize1 = -1
		b.Parent = anchor
		return b
	end
	local outer = beam(1.6, 1.1, Config.Colors.SlimeDeep, 0.15, 0)
	local inner = beam(0.7, 0.45, Color3.fromRGB(214, 255, 170), 1, 0.15)
	-- Drips falling off the rope near the hand.
	local drips = Instance.new("ParticleEmitter")
	drips.Color = ColorSequence.new(Config.Colors.Slime, Config.Colors.SlimeDeep)
	drips.LightEmission = 0.3
	drips.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.15) })
	drips.Lifetime = NumberRange.new(0.4, 0.7)
	drips.Speed = NumberRange.new(1, 3)
	drips.SpreadAngle = Vector2.new(60, 60)
	drips.Acceleration = Vector3.new(0, -60, 0)
	drips.Rate = 45
	drips.Parent = a0
	local dripsTop = drips:Clone()
	dripsTop.Rate = 30
	dripsTop.Parent = a1
	-- A fat squashed splat stuck at the hit point.
	local stuck = gooBall(2.6, Config.Colors.Slime)
	stuck.Size = Vector3.new(3.2, 1.6, 3.2)
	stuck.Shape = Enum.PartType.Cylinder
	stuck.CFrame = CFrame.new(target) * CFrame.Angles(0, 0, math.rad(90))
	splat(target)
	-- Beads of goo sliding along the rope with a wobble.
	local beads: { Part } = {}
	for i = 1, 5 do
		beads[i] = gooBall(0.7 + (i % 3) * 0.25, if i % 2 == 0 then Config.Colors.Slime else Config.Colors.SlimeDeep)
	end
	local start = os.clock()
	local follow = RunService.RenderStepped:Connect(function()
		local from = a0.WorldPosition
		local t = os.clock() - start
		for i, bead in beads do
			local along = ((i / #beads) + t * 0.9) % 1
			local wobble = math.sin(t * 14 + i * 1.7) * 0.25
			bead.Position = from:Lerp(target, along) + Vector3.new(0, wobble - math.sin(along * math.pi) * 0.8, 0)
			local squish = 1 + math.sin(t * 18 + i) * 0.18
			local base = 0.7 + (i % 3) * 0.25
			bead.Size = Vector3.new(base * squish, base / squish, base * squish)
		end
	end)
	task.delay(seconds, function()
		follow:Disconnect()
		drips.Enabled = false
		dripsTop.Enabled = false
		for _, bead in beads do
			fade(bead, 0.2)
		end
		-- Rope thins out and snaps.
		local snap = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
		TweenService:Create(outer, snap, { Width0 = 0.1, Width1 = 0.1 }):Play()
		TweenService:Create(inner, snap, { Width0 = 0.05, Width1 = 0.05 }):Play()
		fade(stuck, 0.5)
		task.delay(0.6, function()
			a0:Destroy()
			anchor:Destroy()
		end)
	end)
end

local function playFx(character: Model, id: string, target: Vector3?)
	local def = Powers.def(id)
	if not def then
		return
	end
	if id == "Dash" then
		afterimages(character, def.Duration or 0.2)
	elseif id == "Shield" then
		shieldBubble(character, def.Duration or 2)
	elseif id == "Grapple" and target then
		rope(character, target, def.Duration or 0.6)
	end
end

local function fovKick()
	local camera = workspace.CurrentCamera
	if not camera or GuiService.ReducedMotionEnabled then
		return
	end
	local base = 70
	camera.FieldOfView = base + 12
	TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { FieldOfView = base }):Play()
end

-- Movement -----------------------------------------------------------------

local function push(root: BasePart, velocity: Vector3, seconds: number)
	local attachment = root:FindFirstChild("RootAttachment") :: Attachment?
	if not attachment then
		return
	end
	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = attachment
	mover.MaxForce = math.huge
	mover.VectorVelocity = velocity
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.Parent = root
	task.delay(seconds, function()
		mover:Destroy()
	end)
end

-- Where the player is aiming: the mouse on PC, the screen centre on touch.
local function aimPoint(range: number): Vector3?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local screen = if UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		then camera.ViewportSize / 2
		else UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance, fxFolder }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (range + 40), params)
	return if hit then hit.Position else nil
end

-- Aim assist for kids: the best pad above you, in front of the camera, in range.
local function autoTarget(root: BasePart, range: number): Vector3?
	local map = workspace:FindFirstChild("Map")
	local camera = workspace.CurrentCamera
	if not map or not camera then
		return nil
	end
	local look = camera.CFrame.LookVector
	local best: Vector3? = nil
	local bestScore = -math.huge
	for _, item in map:GetDescendants() do
		if item:IsA("BasePart") and (string.match(item.Name, "^Pad%d") or item.Name == "ExitPad") then
			local top = item.Position + Vector3.new(0, item.Size.Y / 2 + 3, 0)
			local offset = top - root.Position
			local distance = offset.Magnitude
			if distance <= range and distance > 6 and offset.Y > 1 then
				local score = offset.Unit:Dot(look) + offset.Y / range
				if score > bestScore then
					bestScore = score
					best = top
				end
			end
		end
	end
	return best
end

local function tryUse(id: string): boolean
	local character, root, humanoid = parts()
	local def = Powers.def(id)
	if not character or not root or not humanoid or not def or not inRound() then
		return false
	end
	if not Powers.isUnlocked(id, crowns()) or not Powers.cooldownReady(lastUsed[id], def.Cooldown, os.clock()) then
		return false
	end
	local target: Vector3? = nil
	if id == "Dash" then
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z).Unit
		local duration = def.Duration or 0.2
		push(root, flat * ((def.Distance or 20) / duration), duration)
		fovKick()
		playFx(character, id, nil)
	elseif id == "Grapple" then
		local range = def.Range or 40
		target = aimPoint(range)
		if not target or (target - root.Position).Magnitude > range then
			target = autoTarget(root, range)
		end
		if not target then
			return false
		end
		local duration = def.Duration or 0.6
		local offset = target - root.Position
		push(root, offset / duration, duration)
		playFx(character, id, target)
	end
	lastUsed[id] = os.clock()
	Remotes.get("UsePower"):FireServer(id, target)
	return true
end

local function setupDoubleJump()
	UserInputService.JumpRequest:Connect(function()
		local _, root, humanoid = parts()
		if not root or not humanoid or doubleJumpUsed or not inRound() then
			return
		end
		if not Powers.isUnlocked("DoubleJump", crowns()) then
			return
		end
		if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			return
		end
		doubleJumpUsed = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, humanoid.JumpPower * 1.05, v.Z)
		splat(root.Position - Vector3.new(0, 3, 0))
	end)
	local function hook(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
				doubleJumpUsed = false
			end
		end)
	end
	player.CharacterAdded:Connect(hook)
	if player.Character then
		hook(player.Character)
	end
end

-- Button ---------------------------------------------------------------------

function PowerController.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PowerHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Sits above the default jump button, bottom right.
	local button = Instance.new("TextButton")
	button.Name = "PowerButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -28, 1, -175)
	button.Size = UDim2.fromScale(0.09, 0.09)
	button.BackgroundColor3 = DARK
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = gui
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = button
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MinSize = Vector2.new(70, 70)
	sizeLimit.MaxSize = Vector2.new(120, 120)
	sizeLimit.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Config.Colors.Slime
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	Juice.bindButton(button)

	-- Dark sweep that drains downward while the power recharges.
	local sweep = Instance.new("Frame")
	sweep.AnchorPoint = Vector2.new(0, 1)
	sweep.Position = UDim2.fromScale(0, 1)
	sweep.Size = UDim2.fromScale(1, 0)
	sweep.BackgroundColor3 = Color3.new(0, 0, 0)
	sweep.BackgroundTransparency = 0.45
	sweep.BorderSizePixel = 0
	sweep.ZIndex = 2
	local sweepCorner = Instance.new("UICorner")
	sweepCorner.CornerRadius = UDim.new(1, 0)
	sweepCorner.Parent = sweep
	sweep.Parent = button

	local function makeLabel(y: number, h: number): TextLabel
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, y)
		l.Size = UDim2.fromScale(0.86, h)
		l.FontFace = FONT
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.ZIndex = 3
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = DARK
		s.Parent = l
		l.Parent = button
		return l
	end
	local nameLabel = makeLabel(-0.2, 0.26)
	nameLabel.Size = UDim2.fromScale(1.5, 0.26)
	nameLabel.TextColor3 = Config.Colors.Slime
	local infoLabel = makeLabel(0.8, 0.2)

	local function image(props: { [string]: any }, parent: Instance): ImageLabel
		local i = Instance.new("ImageLabel")
		i.BackgroundTransparency = 1
		i.ScaleType = Enum.ScaleType.Fit
		for key, value in props do
			(i :: any)[key] = value
		end
		i.Parent = parent
		return i
	end
	-- Power icon sits under the cooldown sweep so recharging darkens it.
	local powerIcon = image({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.43),
		Size = UDim2.fromScale(0.62, 0.62),
		ZIndex = 1,
	}, button)
	local lockBadge = image({
		Image = Config.Icons.Lock,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.86, 0.14),
		Size = UDim2.fromScale(0.38, 0.38),
		ZIndex = 4,
	}, button)

	-- Passive Double Jump badge to the left of the button.
	local jumpBadge = Instance.new("Frame")
	jumpBadge.AnchorPoint = Vector2.new(1, 0.5)
	jumpBadge.Position = UDim2.new(0, -10, 0.62, 0)
	jumpBadge.Size = UDim2.fromScale(0.5, 0.5)
	jumpBadge.BackgroundColor3 = DARK
	jumpBadge.Parent = button
	local jumpCorner = Instance.new("UICorner")
	jumpCorner.CornerRadius = UDim.new(1, 0)
	jumpCorner.Parent = jumpBadge
	local jumpStroke = Instance.new("UIStroke")
	jumpStroke.Thickness = 3
	jumpStroke.Color = Color3.fromRGB(166, 107, 255)
	jumpStroke.Parent = jumpBadge
	local jumpIcon = image({
		Image = Config.Icons.DoubleJump,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
	}, jumpBadge)
	local jumpLock = image({
		Image = Config.Icons.Lock,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.85, 0.15),
		Size = UDim2.fromScale(0.5, 0.5),
		ZIndex = 2,
	}, jumpBadge)

	-- Small hint under the button for keyboard players.
	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 1, 6)
	hint.Size = UDim2.new(1.6, 0, 0, 16)
	hint.FontFace = FONT
	hint.TextScaled = true
	hint.TextColor3 = Color3.new(1, 1, 1)
	hint.Text = "Q use  ·  E switch"
	hint.Visible = UserInputService.KeyboardEnabled
	local hintStroke = Instance.new("UIStroke")
	hintStroke.Thickness = 1.5
	hintStroke.Color = DARK
	hintStroke.Parent = hint
	hint.Parent = button

	local function use()
		local id = active[selected]
		if tryUse(id) then
			Juice.popIn(button)
		else
			-- Nothing happened: a quick red flash so the press never feels dead.
			stroke.Color = Color3.fromRGB(255, 80, 80)
			TweenService:Create(stroke, TweenInfo.new(0.35), { Color = Config.Colors.Slime }):Play()
		end
	end
	local function cycle()
		selected = selected % #active + 1
		Juice.popIn(button)
	end
	button.Activated:Connect(use)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q then
			use()
		elseif input.KeyCode == Enum.KeyCode.E then
			cycle()
		end
	end)

	RunService.RenderStepped:Connect(function()
		local id = active[selected]
		local def = Powers.def(id) :: Config.PowerDef
		local have = crowns()
		nameLabel.Text = NAMES[id] or id
		powerIcon.Image = ICONS[id] or ""
		local jumpReady = Powers.isUnlocked("DoubleJump", have)
		jumpIcon.ImageTransparency = if jumpReady then 0 else 0.55
		jumpLock.Visible = not jumpReady
		local locked = not Powers.isUnlocked(id, have)
		lockBadge.Visible = locked
		powerIcon.ImageColor3 = if locked then Color3.fromRGB(150, 145, 170) else Color3.new(1, 1, 1)
		if not Powers.isUnlocked(id, have) then
			infoLabel.Text = string.format("%d crowns", Powers.crownsNeeded(id, have))
			stroke.Color = Color3.fromRGB(120, 110, 140)
			sweep.Size = UDim2.fromScale(1, 1)
			return
		end
		stroke.Color = Config.Colors.Slime
		local used = lastUsed[id]
		local left = if used then def.Cooldown - (os.clock() - used) else 0
		if left > 0 then
			infoLabel.Text = string.format("%.1fs", left)
			sweep.Size = UDim2.fromScale(1, math.clamp(left / def.Cooldown, 0, 1))
		else
			infoLabel.Text = if inRound() then "READY" else "next round"
			sweep.Size = UDim2.fromScale(1, 0)
		end
	end)

	Remotes.get("PowerFx").OnClientEvent:Connect(function(userId: number, id: string, target: Vector3?)
		local who = Players:GetPlayerByUserId(userId)
		local character = who and who.Character
		if not character then
			return
		end
		-- Our own Dash and Grapple already played the instant we pressed.
		if who == player and id ~= "Shield" then
			return
		end
		playFx(character, id, target)
	end)

	setupDoubleJump()
end

return PowerController
