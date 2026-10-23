-- SkillClient: input, own-character animation + dash movement, every player's VFX, skill bar UI.
-- Keys: Q / E / R = skills, T = switch theme (shows the same skills reskinned).
-- Lives at StarterPlayerScripts.SkillClient.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Skills = ReplicatedStorage:WaitForChild("Skills")
local Data = require(Skills:WaitForChild("SkillData"))
local VFX = require(Skills:WaitForChild("SkillVFX"))
local Anims = require(Skills:WaitForChild("SkillAnims"))
local remotes = Skills:WaitForChild("SkillRemotes")
local UseSkill = remotes:WaitForChild("UseSkill") :: RemoteEvent
local SkillFx = remotes:WaitForChild("SkillFx") :: RemoteEvent
local SetTheme = remotes:WaitForChild("SetTheme") :: RemoteEvent

local player = Players.LocalPlayer
local cam = Workspace.CurrentCamera
local tracks: { [string]: AnimationTrack } = {}
local readyAt: { [string]: number } = {}
local activeTrack: AnimationTrack? = nil

local function myTheme() return Data.Themes[player:GetAttribute("SkillTheme") or "Amber"] end

local function onCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid
	local animator = hum and hum:WaitForChild("Animator", 10) :: Animator
	if animator then tracks = Anims.load(animator) end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end

-- Skill bar UI (Dark Glass family, matches the settings panel) ------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SkillBar"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -24)
bar.Size = UDim2.fromOffset(3 * 86 + 2 * 10, 112)
bar.BackgroundTransparency = 1
bar.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar
local themeLabel = Instance.new("TextLabel")
themeLabel.AnchorPoint = Vector2.new(0.5, 1)
themeLabel.Position = UDim2.new(0.5, 0, 1, -142)
themeLabel.Size = UDim2.fromOffset(320, 22)
themeLabel.BackgroundTransparency = 1
themeLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
themeLabel.TextSize = 16
themeLabel.TextColor3 = Color3.fromHex("#EDEDED")
themeLabel.Parent = gui
local tlStroke = Instance.new("UIStroke"); tlStroke.Thickness = 1.5; tlStroke.Transparency = 0.3; tlStroke.Parent = themeLabel

local slots = {}
for i, id in Data.Order do
	local def = Data.Skills[id]
	local s = Instance.new("Frame")
	s.LayoutOrder = i
	s.Size = UDim2.fromOffset(86, 112)
	s.BackgroundColor3 = Color3.fromHex("#202126")
	s.BackgroundTransparency = 0.08
	s.Parent = bar
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = s
	local st = Instance.new("UIStroke"); st.Color = Color3.new(1, 1, 1); st.Transparency = 0.85; st.Thickness = 1.5; st.Parent = s
	local orb = Instance.new("Frame")
	orb.AnchorPoint = Vector2.new(0.5, 0)
	orb.Position = UDim2.new(0.5, 0, 0, 12)
	orb.Size = UDim2.fromOffset(46, 46)
	orb.Parent = s
	local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(1, 0); oc.Parent = orb
	local og = Instance.new("UIGradient"); og.Rotation = 90; og.Parent = orb
	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromScale(1, 1)
	key.BackgroundTransparency = 1
	key.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
	key.Text = def.key.Name
	key.TextSize = 22
	key.TextColor3 = Color3.new(1, 1, 1)
	key.Parent = orb
	local ks = Instance.new("UIStroke"); ks.Thickness = 2; ks.Transparency = 0.2; ks.Parent = key
	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0, 6, 0, 64)
	name.Size = UDim2.new(1, -12, 0, 36)
	name.BackgroundTransparency = 1
	name.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	name.TextSize = 14
	name.TextWrapped = true
	name.TextColor3 = Color3.fromHex("#EDEDED")
	name.Parent = s
	local cover = Instance.new("Frame") -- cooldown sweep: shrinks from full height to 0
	cover.AnchorPoint = Vector2.new(0, 1)
	cover.Position = UDim2.fromScale(0, 1)
	cover.Size = UDim2.fromScale(1, 0)
	cover.BackgroundColor3 = Color3.new(0, 0, 0)
	cover.BackgroundTransparency = 0.45
	cover.ZIndex = 5
	cover.Parent = s
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 16); cc.Parent = cover
	local scale = Instance.new("UIScale"); scale.Parent = s
	slots[id] = { frame = s, gradient = og, name = name, cover = cover, scale = scale, stroke = st }
end

local function paintTheme()
	local th = myTheme()
	themeLabel.Text = "Theme: " .. th.game .. "  (T to switch)"
	for id, sl in slots do
		sl.name.Text = th.labels[id]
		sl.gradient.Color = ColorSequence.new(th.primary, th.secondary)
	end
end
player:GetAttributeChangedSignal("SkillTheme"):Connect(paintTheme)
paintTheme()

local function startCooldown(id: string, cd: number)
	local sl = slots[id]
	sl.cover.Size = UDim2.fromScale(1, 1)
	TweenService:Create(sl.cover, TweenInfo.new(cd, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 0) }):Play()
	sl.scale.Scale = 0.88
	TweenService:Create(sl.scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(cd, function() -- ready ping
		sl.stroke.Transparency = 0.2
		TweenService:Create(sl.stroke, TweenInfo.new(0.4), { Transparency = 0.85 }):Play()
	end)
end

-- Using skills ------------------------------------------------------------------------
local function aimDirection(root: BasePart): Vector3
	local m = UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(m.X, m.Y)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { player.Character :: Instance, Workspace:FindFirstChild("SkillFX") :: Instance }
	local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, rp)
	local target = res and res.Position or ray.Origin + ray.Direction * 500
	local d = target - (root.Position + Vector3.new(0, 1.2, 0))
	return d.Magnitude > 0.1 and d.Unit or root.CFrame.LookVector
end

local function doDash(char: Model, root: BasePart, dir: Vector3, def)
	local att = root:FindFirstChild("RootAttachment") :: Attachment
	if not att then return end
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * (def.distance / def.duration)
	lv.MaxForce = 1e6
	lv.Parent = root
	root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	local baseFov = cam.FieldOfView
	TweenService:Create(cam, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { FieldOfView = baseFov + 10 }):Play()
	local th = myTheme()
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < def.duration do
			VFX.afterimage(char, th.secondary)
			task.wait(0.045)
		end
	end)
	task.delay(def.duration, function()
		lv:Destroy()
		root.AssemblyLinearVelocity *= Vector3.new(0.2, 1, 0.2)
		TweenService:Create(cam, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { FieldOfView = baseFov }):Play()
	end)
end

local function useSkill(id: string)
	local def = Data.Skills[id]
	local now = os.clock()
	if (readyAt[id] or 0) > now then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hum or not root or hum.Health <= 0 then return end
	readyAt[id] = now + def.cooldown
	startCooldown(id, def.cooldown)
	local aim = aimDirection(root)
	local flat = aim * Vector3.new(1, 0, 1)
	if flat.Magnitude > 0.1 then root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit) end
	local track = tracks[id]
	if track then
		track:Play(0.05)
		activeTrack = track
	end
	if def.shape == "Dash" then doDash(char :: Model, root, flat.Magnitude > 0.1 and flat.Unit or root.CFrame.LookVector, def) end
	UseSkill:FireServer(id, aim)
end

UserInputService.InputBegan:Connect(function(io, processed)
	if processed then return end
	for _, id in Data.Order do
		if io.KeyCode == Data.Skills[id].key then useSkill(id) return end
	end
	if io.KeyCode == Enum.KeyCode.T then
		local cur = player:GetAttribute("SkillTheme") or "Amber"
		local idx = table.find(Data.ThemeOrder, cur) or 1
		SetTheme:FireServer(Data.ThemeOrder[idx % #Data.ThemeOrder + 1])
	end
end)

-- Hit-stop: freeze the caster's animation for a beat when their hit lands (game feel).
local function hitStop()
	local t = activeTrack
	if t and t.IsPlaying then
		t:AdjustSpeed(0)
		task.delay(0.07, function() if t.IsPlaying then t:AdjustSpeed(1) end end)
	end
end

-- Visuals for every player's skills ----------------------------------------------------
SkillFx.OnClientEvent:Connect(function(userId: number, kind: string, themeName: string, d)
	local th = Data.Themes[themeName] or Data.Themes.Amber
	local caster = Players:GetPlayerByUserId(userId)
	local char = caster and caster.Character
	local isMe = userId == player.UserId
	if kind == "Cast" then
		local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
		if d.skill == "Bolt" then VFX.charge(hand :: BasePart, th) end
	elseif kind == "Bolt" then
		local t = VFX.projectile(d.origin, d.hit, th, Data.Skills.Bolt.speed)
		task.delay(t, function()
			VFX.impact(d.hit, th)
			if (d.hit - cam.CFrame.Position).Magnitude < 40 then VFX.shake(0.8, 0.2) end
		end)
	elseif kind == "Slam" then
		VFX.slam(d.pos, th, Data.Skills.Slam.radius)
		local dist = (d.pos - cam.CFrame.Position).Magnitude
		if dist < 60 then VFX.shake(isMe and 2.2 or 1.2, 0.35) end
	elseif kind == "Dash" then
		if not isMe and char then -- other players: afterimages only (their client moved them)
			task.spawn(function()
				for _ = 1, 5 do VFX.afterimage(char, th.secondary); task.wait(0.045) end
			end)
		end
	elseif kind == "Damage" then
		VFX.number(d.pos, d.amount, th)
		VFX.burst(d.pos, th, { count = 10, size = 0.8, speed = 14, life = 0.25 })
		if isMe then hitStop() end
	end
end)
