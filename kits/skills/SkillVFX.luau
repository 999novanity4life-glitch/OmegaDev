-- SkillVFX: one module that plays any skill effect (the pattern every top VFX pack uses:
-- "1 module to play, attach, fire and stop any effect, with scale, speed and screen-shake").
-- Everything is built from scratch with engine particle textures, Neon parts, Trails and lights,
-- coloured by the active theme, so one effect serves every game. Client-only.
-- Budgets (Roblox docs): emitters <= 400 particles/s (100 on mobile), use Emit() bursts,
-- keep each effect well under ~400 particles total. Lives at ReplicatedStorage.Skills.SkillVFX.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SkillVFX = {}

local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
}

local fxFolder: Folder? = nil
local function folder(): Folder
	if not fxFolder or not fxFolder.Parent then
		local f = Instance.new("Folder")
		f.Name = "SkillFX"
		f.Parent = Workspace
		fxFolder = f
	end
	return fxFolder :: Folder
end

local function anchor(cf: CFrame, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size or Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = cf
	p.Parent = folder()
	return p
end

local function tween(o: Instance, t: number, goals, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), goals)
	tw:Play()
	return tw
end

-- Particle burst. opts: tex, count, size, life, speed, drag, accel, spread, c1, c2, light
function SkillVFX.burst(pos: Vector3, theme, opts)
	opts = opts or {}
	local p = anchor(CFrame.new(pos))
	local att = Instance.new("Attachment")
	att.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX[opts.tex or "spark"]
	e.Color = ColorSequence.new(opts.c1 or theme.primary, opts.c2 or theme.secondary)
	e.LightEmission = opts.light or 1
	local size = opts.size or 1.2
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) })
	local life = opts.life or 0.35
	e.Lifetime = NumberRange.new(life, life * 1.6)
	local speed = opts.speed or 18
	local s1, s2 = speed * 0.6, speed * 1.4 -- negative speed = particles pulled inward (charge-up)
	e.Speed = NumberRange.new(math.min(s1, s2), math.max(s1, s2))
	local spread = opts.spread or 180
	e.SpreadAngle = Vector2.new(spread, spread)
	e.Drag = opts.drag or 6
	e.Acceleration = opts.accel or Vector3.zero
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.Enabled = false
	e.Parent = att
	e:Emit(opts.count or 24)
	Debris:AddItem(p, life * 1.6 + 0.5)
end

-- Expanding neon disc (shockwave). cf = ground CFrame (Y up).
function SkillVFX.ring(cf: CFrame, color: Color3, radius: number, dur: number, startT: number?)
	local r = Instance.new("Part")
	r.Shape = Enum.PartType.Cylinder
	r.Anchored = true
	r.CanCollide = false
	r.CanQuery = false
	r.CanTouch = false
	r.CastShadow = false
	r.Material = Enum.Material.Neon
	r.Color = color
	r.Transparency = startT or 0.25
	r.Size = Vector3.new(0.15, 1, 1)
	r.CFrame = cf * CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X -> world up
	r.Parent = folder()
	tween(r, dur, { Size = Vector3.new(0.15, radius * 2, radius * 2), Transparency = 1 })
	Debris:AddItem(r, dur + 0.1)
end

-- Short-lived glow light.
function SkillVFX.flash(pos: Vector3, color: Color3, range: number, dur: number)
	local p = anchor(CFrame.new(pos))
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 4
	l.Shadows = false
	l.Parent = p
	tween(l, dur, { Brightness = 0 })
	Debris:AddItem(p, dur + 0.1)
end

-- Rock shards flung out of the ground (physics, client-only, no collisions with players).
function SkillVFX.shards(pos: Vector3, theme, count: number, power: number)
	for i = 1, count do
		local w = Instance.new("WedgePart")
		w.Size = Vector3.new(0.6, 0.6, 0.9) * (0.7 + math.random() * 0.8)
		w.Color = (i % 3 == 0) and theme.primary or theme.shard
		w.Material = (i % 3 == 0) and Enum.Material.Neon or Enum.Material.Slate
		w.CanQuery = false
		w.CanTouch = false
		w.CastShadow = false
		w.CollisionGroup = "Default"
		local a = math.random() * math.pi * 2
		w.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 2, 0.5, math.sin(a) * 2)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		w.Parent = folder()
		w.AssemblyLinearVelocity = Vector3.new(math.cos(a), 1.6 + math.random(), math.sin(a)) * power * (0.6 + math.random() * 0.6)
		w.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		task.delay(1.2, function()
			if w.Parent then tween(w, 0.4, { Transparency = 1 }) end
		end)
		Debris:AddItem(w, 1.7)
	end
end

-- Glowing ball travelling from -> to with a trail. Returns travel time.
function SkillVFX.projectile(from: Vector3, to: Vector3, theme, speed: number): number
	local dist = (to - from).Magnitude
	local t = math.max(dist / speed, 0.05)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = theme.primary
	ball.Size = Vector3.new(1.3, 1.3, 1.3)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.CFrame = CFrame.lookAt(from, to)
	ball.Parent = folder()
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.55, 0); a0.Parent = ball
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.55, 0); a1.Parent = ball
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 0.22
	tr.Color = ColorSequence.new(theme.primary, theme.secondary)
	tr.LightEmission = 1
	tr.Transparency = NumberSequence.new(0.1, 1)
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.FaceCamera = true
	tr.Parent = ball
	local l = Instance.new("PointLight"); l.Color = theme.primary; l.Range = 9; l.Brightness = 2.5; l.Parent = ball
	local core = Instance.new("ParticleEmitter")
	core.Texture = TEX.spark
	core.Color = ColorSequence.new(theme.secondary)
	core.LightEmission = 1
	core.Size = NumberSequence.new(0.6, 0)
	core.Lifetime = NumberRange.new(0.2, 0.3)
	core.Speed = NumberRange.new(1, 3)
	core.Rate = 60
	core.SpreadAngle = Vector2.new(180, 180)
	core.Parent = a0
	tween(ball, t, { CFrame = CFrame.lookAt(to, to + (to - from)) }, Enum.EasingStyle.Linear)
	task.delay(t, function() core.Enabled = false; ball.Transparency = 1; l.Enabled = false end)
	Debris:AddItem(ball, t + 0.4)
	return t
end

-- Translucent copy of a character's parts that fades (dash afterimage).
function SkillVFX.afterimage(char: Model, color: Color3)
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 and not d:FindFirstAncestorOfClass("Accessory") then
			local g = anchor(d.CFrame, d.Size)
			g.Material = Enum.Material.Neon
			g.Color = color
			g.Transparency = 0.55
			tween(g, 0.3, { Transparency = 1 })
			Debris:AddItem(g, 0.35)
		end
	end
end

-- Floating damage number.
function SkillVFX.number(pos: Vector3, amount: number, theme)
	local p = anchor(CFrame.new(pos + Vector3.new(0, 2.5, 0)))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 48)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
	t.Text = tostring(amount)
	t.TextScaled = true
	t.TextColor3 = theme.primary
	t.Parent = bb
	local s = Instance.new("UIStroke"); s.Thickness = 2.5; s.Color = Color3.new(0, 0, 0); s.Parent = t
	local sc = Instance.new("UIScale"); sc.Scale = 0.4; sc.Parent = t
	tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(p, 0.8, { CFrame = p.CFrame + Vector3.new(0, 3, 0) }, Enum.EasingStyle.Quad)
	task.delay(0.45, function()
		tween(t, 0.35, { TextTransparency = 1 })
		tween(s, 0.35, { Transparency = 1 })
	end)
	Debris:AddItem(p, 0.9)
end

-- Camera shake: decaying random rotation applied after the camera module each frame.
local shakeMag, shakeEnd = 0, 0
local bound = false
function SkillVFX.shake(intensity: number, duration: number)
	shakeMag = math.max(shakeMag, intensity)
	shakeEnd = math.max(shakeEnd, os.clock() + duration)
	if bound then return end
	bound = true
	RunService:BindToRenderStep("SkillShake", Enum.RenderPriority.Camera.Value + 1, function()
		local left = shakeEnd - os.clock()
		if left <= 0 then
			RunService:UnbindFromRenderStep("SkillShake")
			bound = false
			shakeMag = 0
			return
		end
		local m = shakeMag * math.clamp(left / 0.35, 0, 1)
		local cam = Workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(math.rad((math.random() - 0.5) * m), math.rad((math.random() - 0.5) * m), 0)
	end)
end

-- High-level recipes per skill shape -------------------------------------------
function SkillVFX.charge(handPart: BasePart?, theme)
	if not handPart then return end
	SkillVFX.burst(handPart.Position, theme, { count = 14, size = 0.7, speed = -6, life = 0.3, drag = 0 })
	SkillVFX.flash(handPart.Position, theme.primary, 8, 0.3)
end

function SkillVFX.impact(pos: Vector3, theme)
	SkillVFX.burst(pos, theme, { count = 30, size = 1.4, speed = 26, life = 0.3 })
	SkillVFX.burst(pos, theme, { tex = "smoke", count = 8, size = 3, speed = 6, life = 0.6, light = 0, c1 = theme.dust, c2 = theme.dust })
	SkillVFX.ring(CFrame.new(pos), theme.secondary, 5, 0.3)
	SkillVFX.flash(pos, theme.primary, 14, 0.35)
end

function SkillVFX.slam(groundPos: Vector3, theme, radius: number)
	local cf = CFrame.new(groundPos + Vector3.new(0, 0.1, 0))
	SkillVFX.ring(cf, theme.primary, radius, 0.45, 0.1)
	task.delay(0.06, function() SkillVFX.ring(cf, theme.secondary, radius * 0.7, 0.4, 0.3) end)
	SkillVFX.burst(groundPos, theme, { tex = "smoke", count = 22, size = 4, speed = 22, life = 0.7, spread = 80, drag = 4, light = 0, c1 = theme.dust, c2 = theme.dust, accel = Vector3.new(0, 4, 0) })
	SkillVFX.burst(groundPos, theme, { count = 26, size = 1.1, speed = 30, life = 0.4, spread = 70 })
	SkillVFX.shards(groundPos, theme, 10, 18)
	SkillVFX.flash(groundPos + Vector3.new(0, 2, 0), theme.primary, 22, 0.45)
end

return SkillVFX
