--!strict
-- In-world fruit showcase after a landing (2026-11-20, replaces the card).
-- Sharman: "show the actual model", rarities "cool and exaggerated with many
-- effects, not like a clash of clans card".
-- The real fruit model (FruitMesh) bursts out of the splash and hangs in
-- front of the camera, spinning. Its aura then climbs tier by tier
-- (ShowcaseBeats): every step recolours everything, fires a shockwave ring,
-- a spark burst and a camera punch, and the big tier word swaps and pops.
-- Layers stack by tier:
--   Rare       glow puffs, point light, rotating god rays, shockwave rings
--   Epic       + lightning arcs crackling round the fruit
--   Legendary  + light pillar through the fruit, rising embers, two spinning
--                halo rings, white flash on the slam
--   Mythical   + three orbiting comets, a rainbow cycle on every layer,
--                a heavier star burst and shake
-- The world is darkened (ColorCorrection) and blurred behind the fruit with
-- DepthOfField (a BlurEffect would blur the fruit too); Bloom is raised so
-- the Neon pops. ReducedMotionEnabled: no shake, spin, flashes or lightning,
-- fewer particles.
-- APIs used (create.roblox.com/docs/reference/engine): Beam, ParticleEmitter
-- (Shape, ShapeStyle, ShapeInOut, Emit), Highlight, DepthOfFieldEffect,
-- ColorCorrectionEffect, BloomEffect, Model:ScaleTo/PivotTo/GetExtentsSize.

local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Motion = require(Shared:WaitForChild("Motion"))
local RarityStyle = require(Shared:WaitForChild("RarityStyle"))
local ShowcaseBeats = require(Shared:WaitForChild("ShowcaseBeats"))
local FruitMesh = require(script.Parent.FruitMesh)
local Juice = require(script.Parent.Juice)

local cfg = Config.UI.Showcase
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.LuckiestGuy
local BODY_FONT = Enum.Font.GothamBlack

local FruitShowcase = {}

-- Painted texture id from Config.UI.Vfx, or nil when it is not uploaded yet.
local function tex(name: string): string?
	local id = Config.UI.Vfx[name]
	return if id and id ~= "" then id else nil
end

-- A camera-facing sprite (BillboardGui + ImageLabel) sized in studs.
local function sprite(parent: Instance, adornee: BasePart, image: string, z: number): (BillboardGui, ImageLabel)
	local bb = Instance.new("BillboardGui")
	bb.Adornee = adornee
	bb.Size = UDim2.fromScale(0, 0)
	bb.LightInfluence = 0
	bb.Brightness = 2
	bb.AlwaysOnTop = false
	bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	bb.Parent = parent
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = image
	img.ZIndex = z
	img.Parent = bb
	return bb, img
end

export type Showcase = {
	play: (key: string, fruitName: string, rarity: string, at: Vector3, fallback: Instance?) -> number,
	playing: () -> boolean,
}

type Anim = (now: number, dt: number) -> boolean -- false = finished

local function reduced(): boolean
	return GuiService.ReducedMotionEnabled
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function tierColor(name: string): Color3
	return rgb(Config.Rarity.Color[name] or { 255, 255, 255 })
end

local function part(name: string, parent: Instance, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function attachment(parent: Instance, pos: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Position = pos
	a.Parent = parent
	return a
end

local function beam(a0: Attachment, a1: Attachment, w0: number, w1: number, alpha: NumberSequence): Beam
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Width0 = w0
	b.Width1 = w1
	b.FaceCamera = true
	b.LightEmission = 1
	b.LightInfluence = 0
	b.Segments = 1
	b.Transparency = alpha
	b.Brightness = 1.5
	local ray = tex("Ray")
	if ray then
		b.Texture = ray
		b.TextureMode = Enum.TextureMode.Stretch
	end
	b.Parent = a0
	return b
end

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rate = 0
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- A closed loop of beams through `n` attachments on a holder part; returns a
-- setter for its radius (rings expand, halos breathe).
local function ringOf(holder: BasePart, n: number, width: number, alpha: number): ({ Beam }, (number) -> ())
	local atts: { Attachment } = {}
	for i = 1, n do
		atts[i] = attachment(holder, Vector3.zero)
	end
	local beams: { Beam } = {}
	for i = 1, n do
		local b = beam(atts[i], atts[i % n + 1], width, width, NumberSequence.new(alpha))
		b.FaceCamera = false
		table.insert(beams, b)
	end
	local function setRadius(r: number)
		for i, a in atts do
			local ang = (i - 1) / n * math.pi * 2
			a.Position = Vector3.new(math.cos(ang) * r, math.sin(ang) * r, 0)
		end
	end
	setRadius(1)
	return beams, setRadius
end

-- Ref P7: the tier word as real 3D text in the world. TextLayers SurfaceGui
-- slices stacked behind each other give the extrusion (each deeper slice
-- darker), the front slice has a chrome gradient face and a thick stroke,
-- and red/cyan ghost slices start split apart and snap together on impact.
-- The block is angled a little off the camera axis so the depth reads.
type Text3D = {
	root: Part,
	set: (word: string, color: Color3, rainbow: { Color3 }?) -> (),
	split: (amount: number) -> (),
	setShine: (offset: number) -> (),
}

local function text3D(parent: Instance, width: number, height: number): Text3D
	local root = part("TierText", parent, Vector3.new(width, height, 0.05), CFrame.new())
	local slices: { { part: Part, label: TextLabel, stroke: UIStroke } } = {}
	local function slice(name: string, z: number, x: number): (Part, TextLabel, UIStroke)
		local p = part(name, parent, Vector3.new(width, height, 0.05), CFrame.new())
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = p
		weld.C0 = CFrame.new(x, 0, z)
		weld.Parent = p
		p.Anchored = false
		p.Massless = true
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 80
		sg.LightInfluence = 0
		sg.ZOffset = -z
		sg.Parent = p
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = FONT
		t.TextScaled = true
		t.Text = ""
		t.Parent = sg
		local st = Instance.new("UIStroke")
		st.Thickness = 10
		st.Color = Color3.new(0, 0, 0)
		st.Parent = t
		return p, t, st
	end
	local layers = cfg.TextLayers
	for i = layers, 1, -1 do
		local p, t, st = slice("Depth" .. i, i * cfg.TextDepth, 0)
		table.insert(slices, { part = p, label = t, stroke = st })
	end
	local ghostR, ghostRLabel = slice("GhostR", 0.01, 0)
	local ghostC, ghostCLabel = slice("GhostC", 0.02, 0)
	ghostRLabel.TextColor3 = Color3.fromRGB(255, 40, 70)
	ghostCLabel.TextColor3 = Color3.fromRGB(40, 230, 255)
	for _, g in { ghostRLabel, ghostCLabel } do
		g.TextTransparency = 0.25
		local st = g:FindFirstChildOfClass("UIStroke")
		if st then
			st.Transparency = 1
		end
	end
	local _, face, faceStroke = slice("Face", 0, 0)
	local faceGrad = Instance.new("UIGradient")
	faceGrad.Rotation = 90
	faceGrad.Parent = face
	local rim = Instance.new("UIGradient") -- chrome banding on the stroke, swept by setShine
	rim.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 42, 50)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(40, 42, 50)),
		ColorSequenceKeypoint.new(0.5, WHITE),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(40, 42, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 42, 50)),
	})
	rim.Rotation = 20
	rim.Parent = faceStroke
	local function weldOf(p: Part): Weld?
		return p:FindFirstChildOfClass("Weld")
	end
	local rWeld, cWeld = weldOf(ghostR), weldOf(ghostC)

	return {
		root = root,
		set = function(word: string, color: Color3, rainbow: { Color3 }?)
			face.Text = word
			ghostRLabel.Text = word
			ghostCLabel.Text = word
			for i, sl in slices do
				sl.label.Text = word
				-- deepest (i = 1) darkest
				sl.label.TextColor3 = color:Lerp(Color3.new(0, 0, 0), 0.82 - 0.4 * (i - 1) / math.max(1, layers - 1))
				sl.stroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.9)
			end
			face.TextColor3 = WHITE
			if rainbow then
				local pts = {}
				for i, c in rainbow do
					table.insert(pts, ColorSequenceKeypoint.new((i - 1) / (#rainbow - 1), c))
				end
				faceGrad.Color = ColorSequence.new(pts)
			else
				-- chrome face tinted by the tier: bright top, dark band, tier bottom
				faceGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, WHITE),
					ColorSequenceKeypoint.new(0.42, color:Lerp(WHITE, 0.55)),
					ColorSequenceKeypoint.new(0.5, color:Lerp(Color3.new(0, 0, 0), 0.35)),
					ColorSequenceKeypoint.new(0.62, color),
					ColorSequenceKeypoint.new(1, color:Lerp(WHITE, 0.3)),
				})
			end
		end,
		split = function(amount: number)
			if rWeld then
				rWeld.C0 = CFrame.new(-amount, amount * 0.25, 0.01)
			end
			if cWeld then
				cWeld.C0 = CFrame.new(amount, -amount * 0.25, 0.02)
			end
			ghostRLabel.TextTransparency = if amount > 0.005 then 0.25 else 1
			ghostCLabel.TextTransparency = ghostRLabel.TextTransparency
		end,
		setShine = function(offset: number)
			rim.Offset = Vector2.new(offset, 0)
		end,
	}
end

function FruitShowcase.new(gui: ScreenGui): Showcase
	-- Screen text: the tier word slams in big at the top, name and odds under the fruit.
	local overlay = Instance.new("Frame")
	overlay.Name = "Showcase"
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Visible = false
	overlay.ZIndex = 6
	overlay.Parent = gui

	local function label(name: string, size: UDim2, pos: UDim2, font: Enum.Font, z: number): TextLabel
		local t = Instance.new("TextLabel")
		t.Name = name
		t.BackgroundTransparency = 1
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Size = size
		t.Position = pos
		t.Font = font
		t.TextScaled = true
		t.Text = ""
		t.TextColor3 = WHITE
		t.ZIndex = z
		t.Parent = overlay
		local c = Instance.new("UITextSizeConstraint")
		c.MinTextSize = 9 -- CLAUDE.md rule 5 floor
		c.MaxTextSize = 220
		c.Parent = t
		return t
	end

	-- Smoked glass plate under the name and odds (ref T1/P4): dark
	-- translucent body, 1 px light top edge, chrome stroke. The world behind is
	-- already blurred by the DepthOfField pass (ref T2).
	local glass = Instance.new("Frame")
	glass.Name = "Glass"
	glass.AnchorPoint = Vector2.new(0.5, 0.5)
	glass.Size = UDim2.fromScale(0.46, 0.17)
	glass.Position = UDim2.fromScale(0.5, 0.835)
	glass.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
	glass.BackgroundTransparency = 0.3
	glass.BorderSizePixel = 0
	glass.ZIndex = 6
	glass.Parent = overlay
	local glassCorner = Instance.new("UICorner")
	glassCorner.CornerRadius = UDim.new(0.18, 0)
	glassCorner.Parent = glass
	local glassStroke = Instance.new("UIStroke")
	glassStroke.Thickness = 1.5
	glassStroke.Color = Color3.fromRGB(201, 206, 216)
	glassStroke.Transparency = 0.45
	glassStroke.Parent = glass
	local glassGrad = Instance.new("UIGradient")
	glassGrad.Rotation = 90
	glassGrad.Transparency = NumberSequence.new(0.05, 0.4)
	glassGrad.Parent = glass
	local glassEdge = Instance.new("Frame")
	glassEdge.Name = "TopEdge"
	glassEdge.AnchorPoint = Vector2.new(0.5, 0)
	glassEdge.Size = UDim2.new(0.86, 0, 0, 1)
	glassEdge.Position = UDim2.new(0.5, 0, 0, 2)
	glassEdge.BackgroundColor3 = WHITE
	glassEdge.BackgroundTransparency = 0.35
	glassEdge.BorderSizePixel = 0
	glassEdge.ZIndex = 7
	glassEdge.Parent = glass
	local glassTint = Instance.new("Frame") -- tier-coloured underglow strip
	glassTint.Name = "Tint"
	glassTint.AnchorPoint = Vector2.new(0.5, 1)
	glassTint.Size = UDim2.new(0.7, 0, 0, 3)
	glassTint.Position = UDim2.fromScale(0.5, 1)
	glassTint.BorderSizePixel = 0
	glassTint.ZIndex = 7
	glassTint.Parent = glass
	local tintFade = Instance.new("UIGradient")
	tintFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	tintFade.Parent = glassTint

	local nameLabel = label("FruitName", UDim2.fromScale(0.42, 0.075), UDim2.fromScale(0.5, 0.805), FONT, 8)
	local nameStroke = Instance.new("UIStroke")
	nameStroke.Thickness = 3
	nameStroke.Parent = nameLabel
	local oddsLabel = label("Odds", UDim2.fromScale(0.3, 0.04), UDim2.fromScale(0.5, 0.875), BODY_FONT, 8)
	local oddsStroke = Instance.new("UIStroke")
	oddsStroke.Thickness = 2
	oddsStroke.Parent = oddsLabel

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = WHITE
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 9
	flash.Parent = overlay

	local isPlaying = false
	local anims: { Anim } = {}
	-- Showcase clock: real time scaled by the workspace attribute
	-- ShowcaseTimeScale (Studio slow-motion capture; 1 when unset), so every
	-- beat, anim and scheduled step can be slowed down together.
	local vnow = 0
	local scheduled: { { at: number, fn: () -> () } } = {}
	RunService.RenderStepped:Connect(function(realDt: number)
		local scale = workspace:GetAttribute("ShowcaseTimeScale")
		local dt = realDt * (if typeof(scale) == "number" and scale > 0 then scale else 1)
		vnow += dt
		local now = vnow
		if #scheduled > 0 then
			local due: { () -> () } = {}
			local later = {}
			for _, job in scheduled do
				if job.at <= now then
					table.insert(due, job.fn)
				else
					table.insert(later, job)
				end
			end
			scheduled = later
			for _, fn in due do
				local ok, err = pcall(fn)
				if not ok then
					warn("[FruitShowcase]", err)
				end
			end
		end
		if #anims == 0 then
			return
		end
		local keep: { Anim } = {}
		for _, a in anims do
			local ok, alive = pcall(a, now, dt)
			if ok and alive then
				table.insert(keep, a)
			elseif not ok then
				warn("[FruitShowcase]", alive)
			end
		end
		anims = keep
	end)
	local function after(seconds: number, fn: () -> ())
		table.insert(scheduled, { at = vnow + seconds, fn = fn })
	end
	local function run(a: Anim)
		table.insert(anims, a)
	end

	local function screenFlash(strength: number, seconds: number)
		if reduced() then
			return
		end
		flash.BackgroundTransparency = 1 - strength
		TweenService:Create(flash, TweenInfo.new(seconds), { BackgroundTransparency = 1 }):Play()
	end

	local function play(key: string, fruitName: string, rarity: string, at: Vector3, fallback: Instance?): number
		if isPlaying then
			return 0
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return 0
		end
		isPlaying = true
		local plan = ShowcaseBeats.plan(rarity, Config.Rarity.Order, cfg)
		local layers = ShowcaseBeats.layers(plan.rank)
		local calm = reduced()
		local fx = if calm then 0.35 else 1 -- particle scale
		local start = vnow
		local color = tierColor(Config.Rarity.Order[1])
		local rainbow = false

		-- Stage: the fruit hangs above the splash; the camera sits off to the
		-- side at eye level so the world behind blurs out.
		local stage = Instance.new("Folder")
		stage.Name = "FruitShowcase"
		stage.Parent = workspace
		local spot = at + Vector3.new(0, cfg.Lift, 0)
		local flat = Vector3.new(cam.CFrame.Position.X - spot.X, 0, cam.CFrame.Position.Z - spot.Z)
		local toCam = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
		local camPos = spot + toCam * cfg.CameraDistance + Vector3.new(0, 1.2, 0)
		local savedType = cam.CameraType
		local savedFov = cam.FieldOfView
		cam.CameraType = Enum.CameraType.Scriptable
		local baseCam = CFrame.lookAt(camPos, spot)
		cam.CFrame = baseCam
		local facing = CFrame.lookAt(spot, camPos) -- -Z of this points at the camera... LookVector toward cam
		local behind = spot - toCam * 2.5 -- rays and pillar sit behind the fruit

		-- Post: darken + desaturate the world, focus on the fruit, more bloom.
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "ShowcaseGrade"
		cc.Parent = Lighting
		local dof = Instance.new("DepthOfFieldEffect")
		dof.Name = "ShowcaseFocus"
		dof.FocusDistance = cfg.CameraDistance
		dof.InFocusRadius = 4
		dof.NearIntensity = 0
		dof.FarIntensity = 0
		dof.Parent = Lighting
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "ShowcaseBloom"
		bloom.Intensity = 0
		bloom.Size = 30
		bloom.Threshold = 0.9
		bloom.Parent = Lighting
		local postIn = TweenInfo.new(0.35)
		TweenService:Create(cc, postIn, { Brightness = -0.22, Contrast = 0.25, Saturation = -0.45 }):Play()
		TweenService:Create(dof, postIn, { FarIntensity = cfg.DofFar }):Play()
		TweenService:Create(bloom, postIn, { Intensity = 0.45 }):Play()

		-- The fruit: the real model, scaled to FruitSize.
		local fruit: Model? = FruitMesh.get(key)
		if not fruit and fallback then
			local m = Instance.new("Model")
			local copy = fallback:Clone()
			for _, d in copy:GetDescendants() do
				if d:IsA("Trail") or d:IsA("ParticleEmitter") or d:IsA("PointLight") then
					d:Destroy()
				end
			end
			copy.Parent = m
			if copy:IsA("BasePart") then
				m.PrimaryPart = copy
			end
			fruit = m
		end
		local fruitSize = cfg.FruitSize
		local highlight: Highlight? = nil
		if fruit then
			fruit.Name = "ShowcaseFruit"
			local e = fruit:GetExtentsSize()
			local widest = math.max(e.X, e.Y, e.Z)
			if widest > 0 then
				fruit:ScaleTo(fruit:GetScale() * fruitSize / widest)
			end
			fruit:PivotTo(CFrame.new(at))
			fruit.Parent = stage
			local h = Instance.new("Highlight")
			h.FillTransparency = 1
			h.OutlineTransparency = 0.1
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Adornee = fruit
			h.Parent = fruit
			highlight = h
		end

		-- Core: carries the light, the aura and the step bursts.
		local core = part("Core", stage, Vector3.one, CFrame.new(spot))
		local light = Instance.new("PointLight")
		light.Range = 12
		light.Brightness = 0
		light.Parent = core
		local aura = emitter(core, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.3, 2.2),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new(0.6, 1),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(1.5, 3),
			Drag = 3,
			RotSpeed = NumberRange.new(-120, 120),
			Rotation = NumberRange.new(0, 360),
			ZOffset = -1,
		})
		local sparks = emitter(core, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
			Size = NumberSequence.new(0.35, 0),
			Squash = NumberSequence.new(-1.5),
			Transparency = NumberSequence.new(0, 1),
			Lifetime = NumberRange.new(0.35, 0.8),
			Speed = NumberRange.new(18, 34),
			Drag = 5,
			Acceleration = Vector3.new(0, -12, 0),
		})
		local stars = emitter(core, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.2, 1.1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new(0, 1),
			Lifetime = NumberRange.new(0.6, 1.4),
			Speed = NumberRange.new(6, 16),
			Drag = 2,
			RotSpeed = NumberRange.new(-200, 200),
		})

		-- Painted textures on the particles when uploaded.
		aura.Texture = tex("Glow") or aura.Texture
		stars.Texture = tex("Flare") or stars.Texture
		local sparkTex = tex("Spark")
		if sparkTex then
			sparks.Texture = sparkTex
			sparks.Orientation = Enum.ParticleOrientation.VelocityParallel
			sparks.Squash = NumberSequence.new(0)
			sparks.Size = NumberSequence.new(1.6, 0)
		end
		local wisp = emitter(core, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.5),
				NumberSequenceKeypoint.new(1, 4),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.7),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.8, 1.3),
			Speed = NumberRange.new(0.5, 1.5),
			RotSpeed = NumberRange.new(-60, 60),
			Rotation = NumberRange.new(0, 360),
			ZOffset = -2,
		})
		wisp.Texture = tex("Wisp") or wisp.Texture
		local twinkles = emitter(core, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.7),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new(0),
			Lifetime = NumberRange.new(0.4, 0.9),
			Speed = NumberRange.new(0, 0.5),
		})
		twinkles.Texture = tex("Twinkle") or twinkles.Texture
		core.Size = Vector3.one * fruitSize * 2.2

		-- Big soft glow behind the fruit in the tier colour (sprite).
		local glowTex = tex("Glow")
		local glowImg: ImageLabel? = nil
		local glowBB: BillboardGui? = nil
		if glowTex then
			local bb, img = sprite(stage, core, glowTex, 1)
			bb.StudsOffsetWorldSpace = -toCam * 1.5
			bb.Size = UDim2.fromScale(fruitSize * 3.2, fruitSize * 3.2)
			img.ImageTransparency = 0.25
			glowImg = img
			glowBB = bb
		end

		-- Dark backdrop far behind the fruit (the refs all reveal on a dark
		-- field so the colour reads): a big translucent black plane.
		local backdrop = part("Backdrop", stage, Vector3.new(90, 60, 0.2), CFrame.lookAt(spot - toCam * 14, camPos))
		backdrop.Color = Color3.new(0, 0, 0)
		backdrop.Material = Enum.Material.SmoothPlastic
		backdrop.Transparency = 1
		TweenService:Create(backdrop, TweenInfo.new(0.4), { Transparency = 0.3 }):Play()

		-- God rays: beams fanning out behind the fruit, the whole fan turning.
		local fanPart = part("Rays", stage, Vector3.one, CFrame.lookAt(behind, behind - toCam))
		local rayBeams: { Beam } = {}
		local hub = attachment(fanPart, Vector3.zero)
		for i = 1, plan.rays do
			local ang = (i - 1) / plan.rays * math.pi * 2
			local len = cfg.RayLength * (if i % 2 == 0 then 0.65 else 1)
			local tip = attachment(fanPart, Vector3.new(math.cos(ang) * len, math.sin(ang) * len, 0))
			local b = beam(
				hub,
				tip,
				0.1,
				if i % 2 == 0 then 1.4 else 2.4,
				NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.5),
					NumberSequenceKeypoint.new(0.6, 0.82),
					NumberSequenceKeypoint.new(1, 1),
				})
			)
			b.FaceCamera = false
			b.Brightness = 1
			table.insert(rayBeams, b)
		end
		for _, b in rayBeams do
			b.Enabled = false
		end

		-- Halos (Legendary+): two tilted rings round the fruit.
		local halos: { { part: Part, beams: { Beam }, tilt: CFrame, speed: number } } = {}
		if layers.halos then
			for i, tilt in
				{ CFrame.Angles(math.rad(70), 0, math.rad(15)), CFrame.Angles(math.rad(-60), math.rad(35), 0) }
			do
				local holder = part("Halo", stage, Vector3.one, CFrame.new(spot) * tilt)
				local beams, setR = ringOf(holder, 28, 0.16, 0.15)
				setR(fruitSize * (0.85 + 0.15 * i))
				for _, b in beams do
					b.Enabled = false
				end
				table.insert(halos, { part = holder, beams = beams, tilt = tilt, speed = if i == 1 then 1.6 else -2.2 })
			end
		end

		-- Pillar + embers (Legendary+).
		local pillarBeam: Beam? = nil
		local embers: ParticleEmitter? = nil
		if layers.pillar then
			local base = part("PillarBase", stage, Vector3.one, CFrame.new(behind.X, at.Y - 1, behind.Z))
			local a0 = attachment(base, Vector3.zero)
			local a1 = attachment(base, Vector3.new(0, 70, 0))
			local pb = beam(
				a0,
				a1,
				1.6,
				3,
				NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(0.5, 0.6),
					NumberSequenceKeypoint.new(1, 1),
				})
			)
			pb.Enabled = false
			pillarBeam = pb
			embers = emitter(base, {
				Shape = Enum.ParticleEmitterShape.Cylinder,
				Size = NumberSequence.new(0.3, 0),
				Transparency = NumberSequence.new(0, 1),
				Lifetime = NumberRange.new(1.2, 2.2),
				Speed = NumberRange.new(6, 14),
				SpreadAngle = Vector2.new(12, 12),
				Acceleration = Vector3.new(0, 4, 0),
			})
			base.Size = Vector3.new(6, 1, 6)
		end

		-- Orbiting comets (Mythical).
		local comets: { Part } = {}
		if layers.orbit then
			for i = 1, 3 do
				local c = part("Comet", stage, Vector3.one * 0.5, CFrame.new(spot))
				c.Shape = Enum.PartType.Ball
				c.Material = Enum.Material.Neon
				c.Transparency = 0
				local t0 = attachment(c, Vector3.new(0, 0.25, 0))
				local t1 = attachment(c, Vector3.new(0, -0.25, 0))
				local trail = Instance.new("Trail")
				trail.Attachment0 = t0
				trail.Attachment1 = t1
				trail.Lifetime = 0.35
				trail.LightEmission = 1
				trail.WidthScale = NumberSequence.new(1, 0)
				trail.Transparency = NumberSequence.new(0, 1)
				trail.Parent = c
				c:SetAttribute("Phase", (i - 1) / 3 * math.pi * 2)
				table.insert(comets, c)
			end
		end

		-- Lightning (Epic+): zigzag Neon segments regenerated every few frames.
		local boltParts: { Part } = {}
		local function clearBolts()
			for _, p in boltParts do
				p:Destroy()
			end
			table.clear(boltParts)
		end
		local function drawBolts(c: Color3)
			clearBolts()
			local n = 2 + plan.rank
			for _ = 1, n do
				local dir = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
				if dir.Magnitude < 0.05 then
					dir = Vector3.yAxis
				end
				dir = dir.Unit
				local a = spot + dir * fruitSize * 0.45
				local b = spot + dir * fruitSize * (1.3 + math.random() * 0.9)
				local pts = ShowcaseBeats.bolt({ a.X, a.Y, a.Z }, { b.X, b.Y, b.Z }, 6, 0.45, math.random)
				for i = 1, #pts - 1 do
					local p0 = Vector3.new(pts[i][1], pts[i][2], pts[i][3])
					local p1 = Vector3.new(pts[i + 1][1], pts[i + 1][2], pts[i + 1][3])
					local len = (p1 - p0).Magnitude
					local seg = part("Bolt", stage, Vector3.new(0.05, 0.05, len), CFrame.lookAt((p0 + p1) / 2, p1))
					seg.Material = Enum.Material.Neon
					seg.Color = c:Lerp(WHITE, 0.55)
					seg.Transparency = 0
					table.insert(boltParts, seg)
				end
			end
		end

		-- Shockwave ring expanding from the fruit on every step.
		local function shockwave(c: Color3, big: boolean)
			local holder = part("Shock", stage, Vector3.one, facing)
			local beams, setR = ringOf(holder, 32, if big then 0.7 else 0.4, 0)
			for _, b in beams do
				b.Color = ColorSequence.new(c:Lerp(WHITE, 0.4))
			end
			local t0 = vnow
			local seconds = if big then 0.6 else 0.45
			local r1 = if big then 13 else 8
			-- painted ring + a star pop on top of the beam ring
			local ringImg: ImageLabel? = nil
			local ringBB: BillboardGui? = nil
			local popImg: ImageLabel? = nil
			local popBB: BillboardGui? = nil
			local ringTex, flareTex = tex("Ring"), tex("Flare")
			if ringTex then
				ringBB, ringImg = sprite(holder, holder, ringTex, 3)
				if ringImg then
					ringImg.ImageColor3 = c:Lerp(WHITE, 0.3)
				end
			end
			if flareTex then
				popBB, popImg = sprite(holder, holder, flareTex, 4)
				if popImg then
					popImg.ImageColor3 = c:Lerp(WHITE, 0.6)
					popImg.Rotation = math.random(0, 45)
				end
			end
			run(function(now)
				local k = (now - t0) / seconds
				if k >= 1 then
					holder:Destroy()
					return false
				end
				local r = ShowcaseBeats.ring(now - t0, seconds, fruitSize * 0.5, r1)
				if ringBB and ringImg then
					ringBB.Size = UDim2.fromScale(r * 2.3, r * 2.3)
					ringImg.ImageTransparency = k * k
				end
				if popBB and popImg then
					local pk = math.clamp(k * 2.5, 0, 1)
					local sz = (if big then 16 else 10) * math.sin(pk * math.pi)
					popBB.Size = UDim2.fromScale(sz, sz)
					popImg.ImageTransparency = pk * 0.6
				end
				setR(ShowcaseBeats.ring(now - t0, seconds, fruitSize * 0.5, r1))
				local alpha = NumberSequence.new(k * k)
				for _, b in beams do
					b.Transparency = alpha
					b.Width0 = (if big then 0.7 else 0.4) * (1 - k)
					b.Width1 = b.Width0
				end
				return true
			end)
		end

		local function recolor(c: Color3)
			color = c
			light.Color = c
			aura.Color = ColorSequence.new(c:Lerp(WHITE, 0.3), c)
			sparks.Color = ColorSequence.new(WHITE, c)
			stars.Color = ColorSequence.new(WHITE, c:Lerp(WHITE, 0.4))
			wisp.Color = ColorSequence.new(c)
			twinkles.Color = ColorSequence.new(WHITE, c:Lerp(WHITE, 0.5))
			if glowImg then
				glowImg.ImageColor3 = c
			end
			local rayColor = ColorSequence.new(c:Lerp(WHITE, 0.6), c)
			for _, b in rayBeams do
				b.Color = rayColor
			end
			for _, h in halos do
				for _, b in h.beams do
					b.Color = ColorSequence.new(c:Lerp(WHITE, 0.3))
				end
			end
			if pillarBeam then
				pillarBeam.Color = ColorSequence.new(WHITE, c)
			end
			if embers then
				embers.Color = ColorSequence.new(c:Lerp(WHITE, 0.5), c)
			end
			for _, cm in comets do
				cm.Color = c:Lerp(WHITE, 0.3)
				local tr = cm:FindFirstChildOfClass("Trail")
				if tr then
					tr.Color = ColorSequence.new(WHITE, c)
				end
			end
			if highlight then
				highlight.OutlineColor = c:Lerp(WHITE, 0.25)
			end
			cc.TintColor = WHITE:Lerp(c, 0.12)
		end

		local function punch(amount: number)
			if calm then
				return
			end
			cam.FieldOfView = savedFov - amount
			TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { FieldOfView = savedFov }):Play()
		end

		-- 3D tier word above the fruit (ref P7), angled off the camera axis.
		local up = Vector3.yAxis
		local textHome = spot + up * (fruitSize * 0.75 + 1.7)
		local textAim = CFrame.lookAt(textHome, camPos) * CFrame.Angles(math.rad(6), math.rad(-14), math.rad(-3))
		local word = text3D(stage, 8, 2.1)
		word.root.CFrame = textAim
		word.root.Transparency = 1
		local wordVisible = false
		local function showWordAt(cf: CFrame)
			word.root.CFrame = if wordVisible then cf else cf + Vector3.new(0, -500, 0)
		end
		showWordAt(textAim)
		local slamAt, slamBig = -1, false
		local function slamWord(tier: string, c: Color3, big: boolean)
			word.set(string.upper(tier), c, nil)
			wordVisible = true
			slamAt = vnow
			slamBig = big
		end

		-- Star flare build-up (ref M4): four long points and four short ones
		-- grow and turn in front of the fruit, then pop into the first step.
		local flarePart: Part? = nil
		local flareBeams: { { beam: Beam, tip: Attachment, dir: Vector3, len: number } } = {}
		if plan.flare > 0 then
			local fp = part("Flare", stage, Vector3.one, CFrame.lookAt(spot + toCam * 0.6, camPos))
			local centre = attachment(fp, Vector3.zero)
			for i = 0, 7 do
				local ang = i * math.pi / 4
				local long = i % 2 == 0
				local dir = Vector3.new(math.cos(ang), math.sin(ang), 0)
				local tip = attachment(fp, Vector3.zero)
				local b = beam(
					centre,
					tip,
					if long then 0.9 else 0.5,
					0,
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.6) })
				)
				b.FaceCamera = false
				b.Brightness = 3
				table.insert(flareBeams, { beam = b, tip = tip, dir = dir, len = if long then 9 else 4.5 })
			end
			flarePart = fp
		end
		local flareBB: BillboardGui? = nil
		local flareImg: ImageLabel? = nil
		local flareTex = tex("Flare")
		if flarePart and flareTex then
			flareBB, flareImg = sprite(flarePart, flarePart, flareTex, 5)
		end

		-- 1) Rise: white-out (ref P3) and the fruit bursts up out of the splash.
		recolor(color)
		light.Brightness = 1.5
		sparks:Emit(math.floor(30 * fx))
		screenFlash(0.8, 0.45)
		local spin = 0
		local shake = 0
		local zoomFrom = plan.slam
		local lunge = spot + toCam * (cfg.CameraDistance * 0.62)
		run(function(now, dt)
			if not isPlaying then
				return false
			end
			local t = now - start
			local k = math.clamp(t / cfg.RiseSeconds, 0, 1)
			local rise = Motion.backOut(k, 1.2)
			if not calm then
				spin += dt * cfg.SpinRate * (1 + 5 * (1 - k)) -- whips round on the way up, then settles
			end
			local bob = if calm then 0 else math.sin(t * 2.2) * 0.18
			local pos = at:Lerp(spot, rise) + Vector3.new(0, bob, 0)
			-- Mythical lunge at the camera (ref M6): snap in, hold, settle back.
			if plan.zoom > 0 and not calm then
				local z = (t - zoomFrom) / plan.zoom
				if z > 0 and z < 1 then
					local w = if z < 0.22
						then 1 - (1 - z / 0.22) ^ 3
						elseif z < 0.6 then 1
						else 1 - ((z - 0.6) / 0.4) ^ 2
					pos = pos:Lerp(lunge, w)
				end
			end
			if fruit then
				fruit:PivotTo(CFrame.new(pos) * CFrame.Angles(0.25, spin, 0.12))
			end
			-- star flare
			local fp = flarePart
			if fp then
				local fk = (t - cfg.RiseSeconds) / plan.flare
				if fk >= 0 and fk < 1.15 then
					local grow = if fk < 1 then fk * fk else math.max(0, 1 - (fk - 1) / 0.15)
					local pulse = 1 + 0.08 * math.sin(t * 40)
					for _, fb in flareBeams do
						fb.tip.Position = fb.dir * fb.len * grow * pulse
						fb.beam.Color = ColorSequence.new(WHITE, color)
					end
					fp.CFrame = CFrame.lookAt(spot + toCam * 0.6, camPos)
						* CFrame.Angles(0, 0, if calm then 0 else t * 0.8)
					light.Brightness = 1.5 + 4 * grow
					if flareBB and flareImg then
						local sz = 22 * grow * pulse
						flareBB.Size = UDim2.fromScale(sz, sz)
						flareImg.Rotation = if calm then 0 else t * 35
						flareImg.ImageColor3 = color:Lerp(WHITE, 0.55)
					end
				elseif fk >= 1.15 then
					fp:Destroy()
					flarePart = nil
				end
			end
			-- fan + halos + comets
			if not calm then
				fanPart.CFrame = CFrame.lookAt(behind, behind - toCam) * CFrame.Angles(0, 0, t * 0.35)
			end
			for _, h in halos do
				h.part.CFrame = CFrame.new(spot) * h.tilt * CFrame.Angles(0, 0, if calm then 0 else t * h.speed)
			end
			for i, cm in comets do
				local ph = (cm:GetAttribute("Phase") :: number?) or 0
				local a = t * 3.2 + ph
				local r = fruitSize * 1.15
				local tilt = CFrame.Angles(0.5 * i, 0.9 * i, 0)
				cm.CFrame = CFrame.new(spot) * tilt * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r)
			end
			if rainbow then
				local speed = Config.UI.RainbowSpeed * 2
				recolor(rgb(Motion.rainbow(now, speed * 1.25)))
				word.set(string.upper(rarity), color, {
					rgb(Motion.rainbow(now, speed, 0)),
					rgb(Motion.rainbow(now, speed, 0.25)),
					rgb(Motion.rainbow(now, speed, 0.5)),
					rgb(Motion.rainbow(now, speed, 0.75)),
				})
				glassTint.BackgroundColor3 = color
			end
			-- 3D word: punch in from near the camera, RGB split closes, chrome shine sweeps
			word.setShine(((now * 0.7) % 2) - 1)
			if wordVisible then
				local sk = if slamAt < 0 then 1 else (now - slamAt) / (if slamBig then 0.36 else 0.22)
				if calm then
					sk = 1
				end
				local fromCf = textAim + (camPos - textHome) * (if slamBig then 0.55 else 0.25)
				local e = Motion.backOut(math.clamp(sk, 0, 1), if slamBig then 2.2 else 1.6)
				local sway = if calm then CFrame.identity else CFrame.Angles(0, math.sin(t * 1.3) * 0.05, 0)
				showWordAt(fromCf:Lerp(textAim, e) * sway)
				word.split(cfg.RgbSplit * math.max(0, 1 - math.clamp(sk, 0, 1) * 1.4))
			else
				showWordAt(textAim)
			end
			if not flarePart then
				light.Brightness = 1.5 + 0.5 * math.sin(t * 6)
			end
			-- camera: slow push in + decaying shake
			shake = math.max(0, shake - dt * 2.5)
			local push = math.clamp(t / plan.total, 0, 1)
			local jitter = if calm or shake <= 0
				then Vector3.zero
				else Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shake * 0.5
			cam.CFrame = (baseCam * CFrame.new(0, 0, -push * 1.6)) * CFrame.new(jitter)
			return true
		end)

		-- Lightning loop (Epic+).
		if layers.lightning and not calm then
			local nextBolt = 0
			run(function(now)
				if not isPlaying then
					clearBolts()
					return false
				end
				if now >= nextBolt and now - start >= cfg.RiseSeconds + plan.flare then
					nextBolt = now + 0.07 + math.random() * 0.06
					if math.random() < 0.8 then
						drawBolts(color)
					else
						clearBolts()
					end
				end
				return true
			end)
		end

		-- The name + odds land on the glass after the final slam (and after the
		-- Mythical lunge).
		local function showName(c: Color3)
			glass.Visible = true
			glassTint.BackgroundColor3 = c
			nameLabel.Text = string.upper(fruitName)
			nameLabel.TextColor3 = WHITE
			nameStroke.Color = c:Lerp(Color3.new(0, 0, 0), 0.6)
			oddsLabel.Text = RarityStyle.oddsText(RarityStyle.chance(rarity, Config.Rarity))
			oddsLabel.TextColor3 = c:Lerp(WHITE, 0.55)
			oddsStroke.Color = Color3.new(0, 0, 0)
			Juice.popIn(glass)
			Juice.popIn(nameLabel)
			Juice.popIn(oddsLabel)
		end

		-- 2) Climb: one beat per tier.
		overlay.Visible = true
		glass.Visible = false
		nameLabel.Text = ""
		oddsLabel.Text = ""
		for i, step in plan.steps do
			local final = i == #plan.steps
			after(step.time, function()
				if not isPlaying then
					return
				end
				local c = tierColor(step.tier)
				recolor(c)
				shockwave(c, final)
				sparks:Emit(math.floor(plan.burst * fx * (if final then 2 else 1)))
				aura.Rate = 30 * fx * i
				for _, b in rayBeams do
					b.Enabled = true
					b.Width1 = (if final then 2.6 else 1.6) + 0.3 * i
				end
				shake = math.max(shake, if final then 0.6 + 0.25 * plan.rank else 0.3)
				punch(if final then 10 else 4)
				if not final then
					slamWord(step.tier, c, false)
					return
				end
				stars:Emit(math.floor((40 + 60 * (plan.rank - 1)) * fx))
				if layers.flash then
					screenFlash(if layers.orbit then 0.85 else 0.6, 0.35)
				end
				if layers.halos then
					for _, h in halos do
						for _, b in h.beams do
							b.Enabled = true
						end
					end
				end
				if pillarBeam then
					pillarBeam.Enabled = true
				end
				if embers then
					embers.Rate = 45 * fx
				end
				if layers.orbit then
					rainbow = true
					aura.Rate = 160 * fx
				end
				if plan.zoom > 0 then
					wordVisible = false -- the fruit owns the screen during the lunge
					after(plan.zoom, function()
						if isPlaying then
							slamWord(step.tier, color, true)
							shockwave(color, true)
							shake = math.max(shake, 0.8)
							showName(color)
						end
					end)
				else
					slamWord(step.tier, c, true)
					showName(c)
				end
			end)
		end

		-- 3) Out: fade the post, drop the stage, hand the camera back.
		after(plan.total, function()
			isPlaying = false
			rainbow = false
			overlay.Visible = false
			local out = TweenInfo.new(0.3)
			TweenService:Create(cc, out, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = WHITE }):Play()
			TweenService:Create(dof, out, { FarIntensity = 0 }):Play()
			TweenService:Create(bloom, out, { Intensity = 0 }):Play()
			clearBolts()
			stage:Destroy()
			cam.FieldOfView = savedFov
			if cam.CameraType == Enum.CameraType.Scriptable then
				cam.CameraType = savedType
			end
			task.delay(0.35, function()
				cc:Destroy()
				dof:Destroy()
				bloom:Destroy()
			end)
		end)
		return plan.total
	end

	return {
		play = play,
		playing = function(): boolean
			return isPlaying
		end,
	}
end

return FruitShowcase
