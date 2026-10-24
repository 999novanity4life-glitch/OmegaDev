--!strict
-- The surface lift bay on the roof: the end of the run, told through visuals
-- instead of text. Everything below is the purple lab under alarm; up here the
-- palette flips to clean white and mint, warm daylight pours down a shaft onto
-- a rescue lift, a pulsing chevron runway and two decontamination arches lead
-- from the last hatch to it, and the lift's towers carry rising rings and
-- up-chevrons into the light.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ParticleArt = require(Shared:WaitForChild("ParticleArt"))
local ShaftLayout = require(Shared:WaitForChild("ShaftLayout"))
local LabKit = require(script.Parent.LabKit)
local Room = require(script.Parent.Room)

local ExitBay = {}

local C = {
	Clean = Color3.fromRGB(234, 242, 240), -- clean-room panels
	Mint = Color3.fromRGB(182, 218, 206),
	Deck = Color3.fromRGB(222, 236, 232),
	Trim = Color3.fromRGB(150, 160, 178),
	Dark = Color3.fromRGB(58, 74, 84),
	Hazard = Color3.fromRGB(255, 200, 48),
	Daylight = Color3.fromRGB(255, 236, 200),
}

local function part(props: { [string]: any }, parent: Instance): Part
	return LabKit.part(props, parent)
end

local function deco(props: { [string]: any }, parent: Instance): Part
	return LabKit.deco(props, parent)
end

-- Soft glowing strip (neon toned down so Bloom doesn't blow it out).
local function glow(props: { [string]: any }, parent: Instance, color: Color3?): Part
	props.Material = Enum.Material.Neon
	props.Color = color or Config.Colors.Slime
	local p = deco(props, parent)
	LabKit.soften(p)
	return p
end

-- A bar from a to b (beams, rails).
local function bar(a: Vector3, b: Vector3, thickness: number, props: { [string]: any }, parent: Instance): Part
	props.Size = Vector3.new(thickness, thickness, (b - a).Magnitude)
	props.CFrame = CFrame.lookAt((a + b) / 2, b)
	return part(props, parent)
end

-- Re-dress a Blender wall bay in the clean-room palette; its windows glow
-- with daylight from outside.
local function cleanBay(model: Model?)
	if not model then
		return
	end
	for _, m in model:GetChildren() do
		if m:IsA("BasePart") then
			if m.Name == "Frame" then
				m.Color = C.Clean
			elseif m.Name == "Inset" then
				m.Color = C.Mint
			elseif m.Name == "Dark" then
				m.Color = C.Dark
			elseif m.Name == "Glass" then
				-- Warm daylight panes; plain material so Bloom doesn't haze the room.
				m.Material = Enum.Material.SmoothPlastic
				m.Color = Color3.fromRGB(255, 226, 170)
				m.Transparency = 0
			end
		end
	end
end

-- Builds the bay on top of the last floor. Returns the exit point and the
-- part players stand on to escape.
function ExitBay.build(model: Model, origin: Vector3, layout: ShaftLayout.Layout): (Vector3, BasePart)
	local cfg = Config.Shaft
	local top = layout.topY
	local R = cfg.Radius
	local folder = Instance.new("Model")
	folder.Name = "ExitBay"
	folder.Parent = model
	Room.use(layout.footprint)
	local function at(angle: number, radius: number, y: number): Vector3
		return Room.at(origin, angle, radius, y)
	end
	local exitPos = at(layout.exitAngle, layout.exitRadius, layout.exitY)
	local last = layout.tiers[#layout.tiers]
	local hatch = at(last.hatchAngle, last.hatchRadius, 0)
	local hx, hz = hatch.X - origin.X, hatch.Z - origin.Z

	-- 1. Clean deck over the roof slab, open around the last hatch.
	local deckY = top + 0.3
	local bx0, bx1, bz0, bz1 = Room.bounds(2)
	local hh = cfg.HatchSize / 2 + 1.2
	local function slab(x0: number, x1: number, z0: number, z1: number)
		if x1 - x0 < 0.1 or z1 - z0 < 0.1 then
			return
		end
		part({
			Name = "CleanDeck",
			Size = Vector3.new(x1 - x0, 0.3, z1 - z0),
			Position = origin + Vector3.new((x0 + x1) / 2, deckY - 0.15, (z0 + z1) / 2),
			Kit = "SR_Grate",
			Tint = C.Deck,
		}, folder)
	end
	slab(bx0, hx - hh, bz0, bz1)
	slab(hx + hh, bx1, bz0, bz1)
	slab(hx - hh, hx + hh, bz0, hz - hh)
	slab(hx - hh, hx + hh, hz + hh, bz1)
	for _, side in { { 0, -hh, hh * 2, 0.8 }, { 0, hh, hh * 2, 0.8 }, { -hh, 0, 0.8, hh * 2 }, { hh, 0, 0.8, hh * 2 } } do
		deco({
			Size = Vector3.new(side[3], 0.06, side[4]),
			Position = origin + Vector3.new(hx + side[1], deckY + 0.03, hz + side[2]),
			Color = C.Hazard,
			Material = Enum.Material.SmoothPlastic,
		}, folder)
	end

	-- 2. Clean-room walls: Blender bays re-dressed white and mint, with
	-- daylight windows along the upper row.
	local rowH = 10
	for i, seg in Room.segments(origin, 9.7, 0) do
		local width = seg.width + 0.4
		local function wallAt(out: number, y: number): CFrame
			return seg.cf * CFrame.new(0, y, out)
		end
		for row = 1, 2 do
			local piece = if row == 2 and i % 2 == 0 then "WallWindow" elseif i % 3 == 0 then "WallVent" else "WallPlain"
			local cf = wallAt(-0.05, top + (row - 1) * rowH)
			cleanBay(LabKit.kit(piece, cf, folder, { scale = Vector3.new((width - 0.3) / 8, rowH / 10.5, 1) }))
		end
		-- Steel ring beam and a soft green strip along the top of the bay.
		deco({
			Size = Vector3.new(width, 1.2, 1.6),
			CFrame = wallAt(-0.8, top + 20.6),
			Kit = "SR_Steel",
			Tint = C.Trim,
		}, folder)
		glow({ Size = Vector3.new(width, 0.25, 0.25), CFrame = wallAt(-1.7, top + 19.9) }, folder)
		if i % 4 == 2 then
			LabKit.lightFixture(folder, wallAt(-0.6, top + 8.5), C.Daylight, 26)
		end
	end

	-- 3. Ceiling with a daylight skylight over the lift: the bay is the one
	-- bright, warm room in the whole lab. Warm fill lights keep it clean white.
	local ceilY = top + 21.5
	local ceiling = part({
		Name = "BayCeiling",
		Size = Vector3.new(bx1 - bx0, 1, bz1 - bz0),
		Position = Vector3.new(origin.X + (bx0 + bx1) / 2, ceilY + 0.5, origin.Z + (bz0 + bz1) / 2),
		Color = Color3.fromRGB(196, 210, 210),
		Material = Enum.Material.SmoothPlastic,
	}, folder)
	local fill = Instance.new("SurfaceLight")
	fill.Face = Enum.NormalId.Bottom
	fill.Color = C.Daylight
	fill.Range = 30
	fill.Angle = 120
	fill.Brightness = 0.45
	fill.Parent = ceiling
	-- Ceiling panel grid lines.
	for k = math.ceil(bx0 / 10), math.floor(bx1 / 10) do
		deco({
			Size = Vector3.new(0.3, 0.1, bz1 - bz0),
			Position = Vector3.new(origin.X + k * 10, ceilY - 0.05, origin.Z + (bz0 + bz1) / 2),
			Color = C.Trim,
			Material = Enum.Material.SmoothPlastic,
		}, folder)
	end
	for k = math.ceil(bz0 / 10), math.floor(bz1 / 10) do
		deco({
			Size = Vector3.new(bx1 - bx0, 0.1, 0.3),
			Position = Vector3.new(origin.X + (bx0 + bx1) / 2, ceilY - 0.05, origin.Z + k * 10),
			Color = C.Trim,
			Material = Enum.Material.SmoothPlastic,
		}, folder)
	end
	-- The skylight: a glowing daylight disc in a steel ring right above the lift.
	deco({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 21, 21),
		CFrame = CFrame.new(exitPos.X, ceilY - 0.25, exitPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Kit = "SR_Steel",
		Tint = C.Trim,
	}, folder)
	glow({
		Name = "Skylight",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 19, 19),
		CFrame = CFrame.new(exitPos.X, ceilY - 0.4, exitPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
	}, folder, Color3.fromRGB(255, 246, 226))
	for k = 0, 5 do
		local a = math.rad(k * 60)
		local lamp = deco({
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(origin.X + math.cos(a) * 24, top + 13, origin.Z + math.sin(a) * 24),
			Transparency = 1,
		}, folder)
		local light = Instance.new("PointLight")
		light.Color = C.Daylight
		light.Range = 24
		light.Brightness = 0.5
		light.Parent = lamp
	end

	-- Daylight shaft onto the lift: warm spotlight from the skylight, layered
	-- light cones and slow dust motes drifting up.
	local sun = deco({
		Name = "SunShaft",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(exitPos.X, ceilY - 1, exitPos.Z),
		Transparency = 1,
	}, folder)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = 55
	spot.Range = 60
	spot.Brightness = 1.8
	spot.Color = C.Daylight
	spot.Shadows = true
	spot.Parent = sun
	-- Plain (not neon) haze cylinders: big neon areas bloom the whole bay white.
	for _, cone in { { 19, 0.93 }, { 13, 0.9 }, { 8, 0.86 } } do
		deco({
			Name = "LightCone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(ceilY - deckY - 1, cone[1], cone[1]),
			CFrame = CFrame.new(exitPos.X, (ceilY + deckY) / 2, exitPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 240, 210),
			Material = Enum.Material.SmoothPlastic,
			Transparency = cone[2],
		}, folder)
	end
	local moteBox =
		deco({ Size = Vector3.new(12, 1, 12), Position = exitPos + Vector3.new(0, 1, 0), Transparency = 1 }, folder)
	local motes = Instance.new("ParticleEmitter")
	motes.Color = ColorSequence.new(C.Daylight)
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.45) })
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Lifetime = NumberRange.new(6, 9)
	motes.Speed = NumberRange.new(1, 2.5)
	motes.SpreadAngle = Vector2.new(20, 20)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.Rate = 10
	ParticleArt.style(motes, "Mote")
	motes.Parent = moteBox

	-- 4. The rescue lift.
	local outward = (exitPos - Vector3.new(origin.X, exitPos.Y, origin.Z)).Unit
	local liftCf = CFrame.lookAt(exitPos, exitPos + outward)
	local function flat(radius: number, height: number, y: number, props: { [string]: any }, collide: boolean?): Part
		props.Shape = Enum.PartType.Cylinder
		props.Size = Vector3.new(height, radius * 2, radius * 2)
		props.CFrame = CFrame.new(exitPos.X, y, exitPos.Z) * CFrame.Angles(0, 0, math.rad(90))
		return if collide then part(props, folder) else deco(props, folder)
	end
	flat(7.6, 0.5, deckY + 0.25, { Kit = "SR_Steel", Tint = C.Mint }, true)
	flat(6.5, 0.7, deckY + 0.6, { Kit = "SR_Steel", Tint = C.Clean }, true)
	glow({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 12.2, 12.2),
		CFrame = CFrame.new(exitPos.X, deckY + 0.98, exitPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
	}, folder)
	local pad = flat(5.6, 0.3, deckY + 1.05, { Name = "ExitPad", Kit = "SR_Steel", Tint = C.Clean }, true)
	-- Target rings painted on the lift floor.
	local rings: { { r: number, color: Color3 } } = {
		{ r = 3.6, color = C.Dark },
		{ r = 3.3, color = C.Clean },
		{ r = 1.6, color = C.Dark },
		{ r = 1.3, color = Config.Colors.Slime },
	}
	for _, ring in rings do
		flat(ring.r, 0.04, deckY + 1.22 + (3.6 - ring.r) * 0.002, {
			Color = ring.color,
			Material = Enum.Material.SmoothPlastic,
		})
	end
	-- Hazard ring marking the lift zone.
	for k = 0, 19 do
		local a = k * 18
		local p = exitPos + Vector3.new(math.cos(math.rad(a)) * 8.3, 0, math.sin(math.rad(a)) * 8.3)
		deco({
			Size = Vector3.new(2.5, 0.08, 0.9),
			CFrame = CFrame.lookAt(
				Vector3.new(p.X, deckY + 0.05, p.Z),
				Vector3.new(exitPos.X, deckY + 0.05, exitPos.Z)
			) * CFrame.Angles(0, math.rad(90), 0),
			Color = if k % 2 == 0 then C.Hazard else C.Dark,
			Material = Enum.Material.SmoothPlastic,
		}, folder)
	end
	-- Four towers with up-chevrons, set off the core side so nothing blocks the way in.
	local crownY = top + 18
	for _, offset in { 50, -50, 130, -130 } do
		local dir = (liftCf * CFrame.Angles(0, math.rad(offset), 0)).LookVector
		local base = Vector3.new(exitPos.X, deckY, exitPos.Z) + dir * 8.8
		local face = CFrame.lookAt(base, Vector3.new(exitPos.X, deckY, exitPos.Z))
		local h = crownY - deckY
		part({
			Name = "LiftTower",
			Size = Vector3.new(1.8, h, 1.8),
			CFrame = face * CFrame.new(0, h / 2, 0),
			Kit = "SR_Steel",
			Tint = C.Clean,
		}, folder)
		part(
			{ Size = Vector3.new(2.6, 1, 2.6), CFrame = face * CFrame.new(0, 0.5, 0), Kit = "SR_Steel", Tint = C.Trim },
			folder
		)
		glow({ Size = Vector3.new(0.3, h - 2, 0.12), CFrame = face * CFrame.new(0, h / 2, -0.96) }, folder)
		for _, y in { 5, 8.5, 12 } do
			for _, s in { -1, 1 } do
				glow({
					Size = Vector3.new(1.3, 0.28, 0.1),
					CFrame = face * CFrame.new(s * 0.45, y, -1) * CFrame.Angles(0, 0, math.rad(s * -38)),
				}, folder)
			end
		end
		-- Gantry beam from each tower top out to the ring beam on the wall.
		local flatDir = Vector3.new(base.X - origin.X, 0, base.Z - origin.Z)
		if flatDir.Magnitude > 1 then
			local wallAngle = math.deg(math.atan2(flatDir.Z, flatDir.X))
			local wall = at(wallAngle, R - 1.4, top + 20.4)
			bar(base + Vector3.new(0, h - 0.6, 0), wall, 1, { Kit = "SR_Steel", Tint = C.Trim }, folder)
		end
	end
	-- Crown ring linking the towers, lit underneath.
	for k = 0, 15 do
		local a0, a1 = math.rad(k * 22.5), math.rad((k + 1) * 22.5)
		local p0 = Vector3.new(exitPos.X + math.cos(a0) * 8.8, crownY, exitPos.Z + math.sin(a0) * 8.8)
		local p1 = Vector3.new(exitPos.X + math.cos(a1) * 8.8, crownY, exitPos.Z + math.sin(a1) * 8.8)
		bar(p0, p1, 1.1, { Kit = "SR_Steel", Tint = C.Clean }, folder)
		glow({
			Size = Vector3.new(0.3, 0.2, (p1 - p0).Magnitude),
			CFrame = CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, -0.65, 0),
		}, folder)
	end
	-- Rings of light that keep rising from the lift into the shaft (client animates).
	for phase = 0, 1 do
		local ring = glow({
			Name = "RiseRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.12, 12.4, 12.4),
			CFrame = CFrame.new(exitPos.X, deckY + 1.4, exitPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		}, folder)
		ring:SetAttribute("BaseY", deckY + 1.4)
		ring:SetAttribute("Height", crownY - deckY - 2)
		ring:SetAttribute("Phase", phase * 0.5)
		CollectionService:AddTag(ring, "RiseRing")
	end

	-- 5. Sealed reactor cap on the core in the middle of the bay.
	local capY = deckY
	part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 13.6, 13.6),
		CFrame = CFrame.new(origin.X, capY + 0.7, origin.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Kit = "SR_Steel",
		Tint = C.Trim,
	}, folder)
	deco({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(10.4, 10.4, 10.4),
		Position = Vector3.new(origin.X, capY + 1.2, origin.Z),
		Color = Color3.fromRGB(170, 240, 214),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
	}, folder)
	glow({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(8, 8, 8),
		Position = Vector3.new(origin.X, capY + 0.8, origin.Z),
	}, folder)
	for k = 0, 7 do
		local a = math.rad(k * 45)
		glow({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.6, 0.6, 0.6),
			Position = Vector3.new(origin.X + math.cos(a) * 6.2, capY + 1.45, origin.Z + math.sin(a) * 6.2),
		}, folder)
	end

	-- 6. Runway from the hatch round the core to the lift: chevrons that pulse
	-- toward the exit, edge light strips and two decontamination arches.
	local a0 = last.hatchAngle + 24
	local a1 = layout.exitAngle - 22
	local sweep = (a1 - a0) % 360
	local runR = 15
	local count = math.floor(sweep / 10)
	for k = 0, count do
		local a = a0 + sweep * k / count
		local p = at(a, runR, deckY + 0.04)
		local ahead = at(a + 4, runR, deckY + 0.04)
		local cf = CFrame.lookAt(p, ahead)
		for _, s in { -1, 1 } do
			local chevron = glow({
				Name = "Chevron",
				Size = Vector3.new(0.35, 0.06, 2.2),
				CFrame = cf * CFrame.new(s * 0.75, 0, 0.55) * CFrame.Angles(0, math.rad(s * 35), 0),
			}, folder)
			chevron:SetAttribute("Index", k)
			CollectionService:AddTag(chevron, "Chevron")
		end
	end
	for _, edge in { runR - 2.4, runR + 2.4 } do
		local n = math.floor(sweep / 6)
		for k = 0, n - 1 do
			local p0 = at(a0 + sweep * k / n, edge, deckY + 0.05)
			local p1 = at(a0 + sweep * (k + 1) / n, edge, deckY + 0.05)
			glow(
				{ Size = Vector3.new(0.25, 0.08, (p1 - p0).Magnitude), CFrame = CFrame.lookAt((p0 + p1) / 2, p1) },
				folder,
				C.Mint
			)
		end
	end
	for _, f in { 0.33, 0.66 } do
		local a = a0 + sweep * f
		local inner, outer = at(a, runR - 3.6, deckY), at(a, runR + 3.6, deckY)
		for _, post in { inner, outer } do
			local face = CFrame.lookAt(post, at(a + 10, runR, deckY))
			part({
				Size = Vector3.new(1.3, 9, 1.6),
				CFrame = face * CFrame.new(0, 4.5, 0),
				Kit = "SR_Steel",
				Tint = C.Clean,
			}, folder)
			glow({ Size = Vector3.new(0.2, 7.5, 0.2), CFrame = face * CFrame.new(0, 4.5, -0.82) }, folder)
		end
		local beamA, beamB = inner + Vector3.new(0, 9.4, 0), outer + Vector3.new(0, 9.4, 0)
		local beam = bar(beamA, beamB, 1.3, { Kit = "SR_Steel", Tint = C.Trim }, folder)
		glow({
			Size = Vector3.new(0.3, 0.15, (beamB - beamA).Magnitude - 1),
			CFrame = beam.CFrame * CFrame.new(0, -0.72, 0),
		}, folder)
		local nozzle = deco({
			Size = Vector3.new(1, 0.2, (beamB - beamA).Magnitude - 1.5),
			CFrame = beam.CFrame * CFrame.new(0, -0.8, 0),
			Transparency = 1,
		}, folder)
		local mist = Instance.new("ParticleEmitter")
		mist.Color = ColorSequence.new(Color3.fromRGB(220, 255, 240))
		mist.Size = NumberSequence.new(0.7, 0.4)
		mist.Transparency = NumberSequence.new(0.55, 1)
		mist.Lifetime = NumberRange.new(0.7, 1)
		mist.Speed = NumberRange.new(6, 9)
		mist.SpreadAngle = Vector2.new(8, 8)
		mist.EmissionDirection = Enum.NormalId.Bottom
		mist.Rate = 30
		ParticleArt.style(mist, "Streak")
		mist.Parent = nozzle
	end

	-- Wall fixtures are tuned for the dark lab; up here they only add a touch.
	for _, d in folder:GetDescendants() do
		if d:IsA("PointLight") and d.Brightness > 2 then
			d.Brightness = 0.7
			d.Range = 18
		end
	end

	return exitPos, pad
end

return ExitBay
