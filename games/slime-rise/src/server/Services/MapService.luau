--!strict
-- Builds one containment shaft (a match map) at an origin from ShaftLayout.
-- Greybox-plus-dressing in parts; Blender kit pieces replace the dressing later.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ParticleArt = require(Shared:WaitForChild("ParticleArt"))
local ShaftLayout = require(Shared:WaitForChild("ShaftLayout"))
local LabKit = require(script.Parent.LabKit)
local CourseBuilder = require(script.Parent.CourseBuilder)
local ExitBay = require(script.Parent.ExitBay)
local Room = require(script.Parent.Room)
local Themes = require(script.Parent.Themes)
local Footprint = require(Shared:WaitForChild("Footprint"))

local MapService = {}

export type TierParts = {
	info: ShaftLayout.Tier,
	folder: Folder,
	doors: { BasePart },
	doorOpen: { CFrame },
	bridge: { BasePart },
	bridgeTargets: { CFrame },
	landing: BasePart,
	pads: { BasePart },
	opened: boolean,
}
export type Map = {
	model: Model,
	origin: Vector3,
	layout: ShaftLayout.Layout,
	tiers: { TierParts },
	spawnPoints: { CFrame },
	exitPosition: Vector3,
	exitY: number,
	bottomY: number,
}

local C = {
	Wall = Color3.fromRGB(170, 160, 200),
	WallDark = Color3.fromRGB(30, 25, 44),
	Floor = Color3.fromRGB(150, 150, 170),
	Hazard = Color3.fromRGB(255, 196, 40),
	HazardDark = Color3.fromRGB(28, 24, 30),
	Pad = Color3.fromRGB(56, 182, 196),
	PadAlt = Color3.fromRGB(140, 92, 214),
	Trim = Config.Colors.Trim,
	Glass = Color3.fromRGB(150, 255, 190),
	Pipe = Color3.fromRGB(110, 116, 140),
	Alarm = Color3.fromRGB(255, 50, 60),
}

local function part(props: { [string]: any }, parent: Instance): Part
	return LabKit.part(props, parent)
end

local function deco(props: { [string]: any }, parent: Instance): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return part(props, parent)
end

-- Placement in the current map's room (see Room): angle/radius authored for
-- the round reference shaft, warped onto this room's shape.
local function polar(origin: Vector3, angle: number, radius: number, y: number): Vector3
	return Room.at(origin, angle, radius, y)
end

-- CFrame on the ring at an angle, facing into the room.
local function ringCFrame(origin: Vector3, angle: number, radius: number, y: number): CFrame
	return Room.ring(origin, angle, radius, y)
end

-- The theme of the map being built (wall bays, tints, centrepiece).
local theme: Themes.Theme = Themes.Lab

-- Walls as a grid of individual panels (4 rows per tier), each picked from the
-- surface-specific variants: kick band at the bottom, weighted specials in the
-- middle (never repeated next to or above each other), control panels and the
-- level stencil beside each landing, a trim line under each ceiling.
local function buildWalls(model: Model, origin: Vector3, height: number, layout: ShaftLayout.Layout, seed: number)
	local cfg = Config.Shaft
	local folder = Instance.new("Folder")
	folder.Name = "Walls"
	folder.Parent = model
	local rand = Random.new(seed)
	local rows = 4
	local rowH = cfg.TierHeight / rows
	-- One column of panels per wall segment, laid flat along the room's edges.
	local segments = Room.segments(origin, 9.7, 0)
	local segs = #segments
	local angles: { number } = {}
	for i, seg in segments do
		local p = seg.cf.Position
		angles[i] = math.deg(math.atan2(p.Z - origin.Z, p.X - origin.X)) % 360
	end
	-- Panel CFrame `out` studs behind the wall line (negative = in front).
	local function at(i: number, out: number, y: number): CFrame
		return segments[i].cf * CFrame.new(0, y - origin.Y, out)
	end
	local function nearest(angle: number): number
		local best, bestD = 1, math.huge
		for i, a in angles do
			local d = math.abs(((a - angle + 180) % 360) - 180)
			if d < bestD then
				best, bestD = i, d
			end
		end
		return best
	end
	local function panelKit(kit: string): string?
		if theme.panelKit == "Plain" then
			return nil
		end
		return theme.panelKit or kit
	end
	local panelColor = if theme.panelKit == "Plain" then theme.panelTint else nil
	local panelMaterial = if theme.panelKit == "Plain" then Enum.Material.SmoothPlastic else nil
	-- Filler below the floor and above the roof.
	for i, seg in segments do
		for _, band in { { -20, 0 }, { height, height + 20 } } do
			local mid = (band[1] + band[2]) / 2
			part({
				Name = "Wall",
				Size = Vector3.new(seg.width + 0.4, band[2] - band[1], 2),
				CFrame = at(i, 1, origin.Y + mid),
				Kit = panelKit("SR_WallPlain"),
				Tint = theme.panelTint,
				Color = panelColor,
				Material = panelMaterial,
			}, folder)
		end
	end
	local below: { [number]: string } = {}
	for _, tier in layout.tiers do
		-- Segment closest to this tier's landing gets the control panel and stencil.
		local landingSeg = nearest(tier.hatchAngle)
		local left: string? = nil
		for i, seg in segments do
			local width = seg.width + 0.4
			local prevSeg = (i - 2) % segs + 1
			local nextSeg = i % segs + 1
			for row = 1, rows do
				local y = origin.Y + tier.floorY + (row - 0.5) * rowH
				local kit: string
				if row == 1 then
					kit = "SR_WallBase"
				elseif row == 3 and (landingSeg == prevSeg or landingSeg == nextSeg) then
					kit = "SR_WallControl"
				elseif row == 4 and i == landingSeg then
					kit = "SR_WallPlain"
				else
					kit = LabKit.pickPanel(rand, if row == 2 then left else nil, below[i * 10 + row - 1])
				end
				below[i * 10 + row] = kit
				if row == 2 then
					left = kit
				end
				local panel = part({
					Name = "Wall",
					Size = Vector3.new(width, rowH, 2),
					CFrame = at(i, 1, y),
					Kit = panelKit(kit),
					Tint = theme.panelTint,
					Color = panelColor,
					Material = panelMaterial,
				}, folder)
				-- Real 3D wall bay (Blender kit) in front of the panel where one exists.
				local bay = theme.wallBays[kit]
				if bay then
					local scale = Vector3.new((width - 0.3) / 8, rowH / 10.5, 1)
					if not LabKit.kit(bay, at(i, -0.05, y - rowH / 2), folder, { scale = scale }) then
						local fallback = Themes.Lab.wallBays[kit]
						if fallback then
							Themes.dress(
								LabKit.kit(fallback, at(i, -0.05, y - rowH / 2), folder, { scale = scale }),
								theme
							)
						end
					end
				end
				if row == 1 then
					-- Soft contact shadow where wall meets floor.
					LabKit.decal(panel, "Shadow", Enum.NormalId.Front, nil, 0.15)
				elseif kit == "SR_WallWindow" and tier.index == 1 and theme.id == "Lab" then
					-- Slime oozing out under the windows on the lowest tier.
					LabKit.decalPlate(folder, at(i, -0.06, y - rowH * 0.45), Vector2.new(width - 2, 3.5), "Drip")
				end
				if row == 4 and i == landingSeg then
					LabKit.decalPlate(
						folder,
						at(i, -0.06, y),
						Vector2.new(7, 7),
						"Level" .. tier.index,
						Config.Colors.Slime
					)
				end
			end
			-- Climb arrows on the wall behind each pad, pointing up the route.
			for _, pad in tier.pads do
				if nearest(pad.angle) == i then
					LabKit.decalPlate(
						folder,
						at(i, -0.07, origin.Y + pad.y + 4.5),
						Vector2.new(2.6, 2.6),
						"Arrow",
						Color3.fromRGB(255, 220, 90)
					)
				end
			end
			-- Ribs between panels and a trim line under the ceiling.
			deco({
				Size = Vector3.new(0.8, cfg.TierHeight, 0.8),
				CFrame = at(i, -0.2, origin.Y + tier.floorY + cfg.TierHeight / 2) * CFrame.new(seg.width / 2, 0, 0),
				Kit = "SR_Steel",
			}, folder)
			deco({
				Size = Vector3.new(width, 1.6, 0.4),
				CFrame = at(i, -0.1, origin.Y + tier.ceilingY - 3),
				Kit = "SR_Trim",
			}, folder)
		end
		task.wait()
		Room.use(layout.footprint)
	end
	-- Vertical pipes on every fourth panel, glowing ones on every eighth.
	for i, seg in segments do
		if i % 4 == 1 then
			local pipe = at(i, -1.6, origin.Y + height / 2) * CFrame.new(seg.width / 2, 0, 0)
			deco({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(height, 1.4, 1.4),
				CFrame = pipe * CFrame.Angles(0, 0, math.rad(90)),
				Color = if i % 8 == 1
					then (if theme.id == "Lab" then Config.Colors.SlimeDeep else theme.accent)
					else theme.pipe,
				Material = if i % 8 == 1 then Enum.Material.Glass else Enum.Material.Metal,
				Transparency = if i % 8 == 1 then 0.35 else 0,
			}, folder)
		end
	end
end

local function buildCryoCore(model: Model, origin: Vector3, height: number, tiers: number)
	-- Frost-covered cooling column: stacked Blender segments when the Cryo kit
	-- is imported, otherwise an icy column with steel rings and cyan bands.
	local cfg = Config.Shaft
	local segH = 10.5
	local kitted = false
	for k = 0, math.ceil(height / segH) - 1 do
		local cf = CFrame.new(origin + Vector3.new(0, k * segH, 0)) * CFrame.Angles(0, math.rad(k * 37), 0)
		kitted = LabKit.kit("CryoColumn", cf, model, { collide = true, scale = Vector3.new(1, 1, 1) }) ~= nil or kitted
	end
	if not kitted then
		local column = part({
			Name = "SlimeTank",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, cfg.CoreRadius * 2, cfg.CoreRadius * 2),
			CFrame = CFrame.new(origin + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(205, 228, 240),
			Material = Enum.Material.Glacier,
		}, model)
		column.CanCollide = true
	else
		deco({
			Name = "SlimeTank",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, 1, 1),
			CFrame = CFrame.new(origin + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Transparency = 1,
		}, model)
	end
	for t = 0, tiers do
		local y = t * cfg.TierHeight
		deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, cfg.CoreRadius * 2 + 1.6, cfg.CoreRadius * 2 + 1.6),
			CFrame = CFrame.new(origin + Vector3.new(0, y + 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Kit = "SR_Steel",
			Tint = theme.pipe,
		}, model)
		for _, dy in { 14, 28 } do
			local band = deco({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.5, cfg.CoreRadius * 2 + 0.3, cfg.CoreRadius * 2 + 0.3),
				CFrame = CFrame.new(origin + Vector3.new(0, y + dy, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = theme.accent,
				Material = Enum.Material.Neon,
			}, model)
			LabKit.soften(band)
		end
	end
	local mist = deco({
		Size = Vector3.new(cfg.CoreRadius * 2, 1, cfg.CoreRadius * 2),
		Position = origin + Vector3.new(0, 1, 0),
		Transparency = 1,
	}, model)
	local fog = Instance.new("ParticleEmitter")
	fog.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	fog.Size = NumberSequence.new(2, 5)
	fog.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	fog.Lifetime = NumberRange.new(4, 6)
	fog.Speed = NumberRange.new(1, 2)
	fog.SpreadAngle = Vector2.new(80, 80)
	fog.Rate = 6
	ParticleArt.style(fog, "Mote")
	fog.LightEmission = 0.1
	fog.Parent = mist
end

local function buildGreenCore(model: Model, origin: Vector3, height: number, tiers: number)
	-- Glass bio-column with a giant vine stalk growing up through every floor:
	-- stacked Blender segments when the kit is imported, crafted otherwise.
	local cfg = Config.Shaft
	local segH = 10.5
	local kitted = false
	for k = 0, math.ceil(height / segH) - 1 do
		local cf = CFrame.new(origin + Vector3.new(0, k * segH, 0)) * CFrame.Angles(0, math.rad(k * 53), 0)
		kitted = LabKit.kit("GreenColumn", cf, model, { collide = true }) ~= nil or kitted
	end
	local glass = deco({
		Name = "SlimeTank",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, cfg.CoreRadius * 2, cfg.CoreRadius * 2),
		CFrame = CFrame.new(origin + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(210, 255, 220),
		Material = Enum.Material.Glass,
		Transparency = if kitted then 1 else 0.6,
	}, model)
	glass.CanCollide = true
	if not kitted then
		-- One continuous twisting stalk, with paired leaves every few studs.
		local prev: Vector3? = nil
		for y = 0, height, 2 do
			local a = math.rad(y * 9)
			local point = origin + Vector3.new(math.cos(a) * 1.3, y, math.sin(a) * 1.3)
			if prev then
				local stem = deco({
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new((point - prev).Magnitude + 0.6, 1.8, 1.8),
					CFrame = CFrame.lookAt((point + prev) / 2, point) * CFrame.Angles(0, math.rad(90), 0),
					Color = Color3.fromRGB(104, 150, 64),
					Material = Enum.Material.SmoothPlastic,
				}, model)
				stem.CastShadow = true
			end
			if y % 6 == 0 then
				for _, side in { 0, math.pi } do
					deco({
						Size = Vector3.new(3, 0.25, 1.5),
						CFrame = CFrame.new(point) * CFrame.Angles(0, a + side, math.rad(25)) * CFrame.new(1.7, 0.3, 0),
						Color = Color3.fromRGB(96, 200, 84),
						Material = Enum.Material.SmoothPlastic,
					}, model)
				end
			end
			prev = point
		end
	end
	for t = 0, tiers do
		local y = t * cfg.TierHeight
		deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, cfg.CoreRadius * 2 + 1.6, cfg.CoreRadius * 2 + 1.6),
			CFrame = CFrame.new(origin + Vector3.new(0, y + 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Kit = "SR_Steel",
			Tint = theme.pipe,
		}, model)
		local band = deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.5, cfg.CoreRadius * 2 + 0.3, cfg.CoreRadius * 2 + 0.3),
			CFrame = CFrame.new(origin + Vector3.new(0, y + 20, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = theme.accent,
			Material = Enum.Material.Neon,
		}, model)
		LabKit.soften(band)
	end
end

local function buildCore(model: Model, origin: Vector3, height: number, tiers: number)
	if theme.core == "Green" then
		buildGreenCore(model, origin, height, tiers)
		return
	end
	if theme.core == "Cryo" then
		buildCryoCore(model, origin, height, tiers)
		return
	end
	local cfg = Config.Shaft
	local core = deco({
		Name = "SlimeTank",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, cfg.CoreRadius * 2, cfg.CoreRadius * 2),
		CFrame = CFrame.new(origin + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Glass,
		Material = Enum.Material.Glass,
		Transparency = 0.45,
	}, model)
	core.CanCollide = true
	local inner = deco({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, cfg.CoreRadius * 2 - 1.2, cfg.CoreRadius * 2 - 1.2),
		CFrame = core.CFrame,
		Color = Config.Colors.Slime,
		Material = Enum.Material.Glass,
		Transparency = 0.78,
	}, model)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(Color3.fromRGB(220, 255, 200))
	bubbles.LightEmission = 0.7
	bubbles.Size = NumberSequence.new(0.7, 1.4)
	bubbles.Lifetime = NumberRange.new(3, 6)
	bubbles.Speed = NumberRange.new(4, 9)
	bubbles.EmissionDirection = Enum.NormalId.Right -- cylinder axis points along X
	bubbles.Rate = 40
	ParticleArt.style(bubbles, "Bubble")
	bubbles.Parent = inner
	-- Steel rings around the tank at every floor.
	for t = 0, tiers do
		deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, cfg.CoreRadius * 2 + 1.4, cfg.CoreRadius * 2 + 1.4),
			CFrame = CFrame.new(origin + Vector3.new(0, t * cfg.TierHeight + 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = C.Pipe,
		}, model)
	end
end

-- Floor drains: real trenches ~1.6 deep running along Z, slime flowing in
-- them (scrolling texture, soft glow) under a see-through walkable grate.
local TRENCH_SPACING = 16
local trenchX: { number } = { -24, -8, 8, 24 } -- set per map from the room's width
local TRENCH_W = 3
local TRENCH_DEPTH = 1.6
local SLIME_FLOW = "rbxassetid://100553516752013"
local BAR_PITCH = 1.4 -- one cross bar every 1.4 studs leaves ~1.1-stud open slots

local function flowLayer(slime: BasePart, w: number, tile: number, speed: number, transparency: number)
	local flow = Instance.new("Texture")
	flow.Texture = SLIME_FLOW
	flow.Face = Enum.NormalId.Top
	flow.StudsPerTileU = w
	flow.StudsPerTileV = tile
	flow.Transparency = transparency
	flow:SetAttribute("FlowSpeed", speed)
	flow.Parent = slime
	CollectionService:AddTag(flow, "SlimeFlow")
end

-- Open drain channel: dark steel walls, slime flowing ~1 stud below the deck
-- (two scrolling layers at different speeds for depth), real 3D cross bars on
-- top and an invisible collider so players walk over it like a solid floor.
local function trench(parent: Instance, origin: Vector3, top: number, x0: number, x1: number, z0: number, z1: number)
	local w, len = x1 - x0, z1 - z0
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local at = function(y: number): Vector3
		return origin + Vector3.new(cx, y, cz)
	end
	LabKit.part({
		Size = Vector3.new(w, 0.4, len),
		Position = at(top - TRENCH_DEPTH - 0.2),
		Kit = "SR_Steel",
		Tint = Color3.fromRGB(46, 50, 64),
	}, parent)
	-- Inner walls, so the channel reads as a cut into the deck from any angle.
	for _, side in { -1, 1 } do
		LabKit.deco({
			Size = Vector3.new(0.2, TRENCH_DEPTH, len),
			Position = at(top - TRENCH_DEPTH / 2) + Vector3.new(side * (w / 2 - 0.1), 0, 0),
			Kit = "SR_Steel",
			Tint = Color3.fromRGB(70, 76, 98),
		}, parent)
	end
	local slime = LabKit.deco({
		Name = "DrainSlime",
		Size = Vector3.new(w - 0.4, 0.5, len),
		Position = at(top - 1.05),
		Color = theme.coolant,
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.05,
	}, parent)
	flowLayer(slime, w, 6, 2.5, 0)
	flowLayer(slime, w * 0.7, 9, 4.2, 0.55)
	if theme.id ~= "Lab" then
		-- Same flow art as a pale swirl over this room's coolant colour.
		for _, flow in slime:GetChildren() do
			if flow:IsA("Texture") then
				flow.Color3 = Color3.fromRGB(225, 250, 255)
				flow.Transparency = math.max(flow.Transparency, 0.5)
			end
		end
	end
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Top
	glow.Color = theme.coolant
	glow.Range = 7
	glow.Brightness = 1.3
	glow.Parent = slime
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "DrainBubbles"
	bubbles.Color = ColorSequence.new(theme.coolant)
	bubbles.LightEmission = 0.4
	bubbles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.45) })
	bubbles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	bubbles.Lifetime = NumberRange.new(0.5, 0.9)
	bubbles.Speed = NumberRange.new(0.6, 1.2)
	bubbles.EmissionDirection = Enum.NormalId.Top
	bubbles.Rate = math.clamp(len / 6, 1, 14)
	ParticleArt.style(bubbles, "Bubble")
	bubbles.Parent = slime
	-- Cross bars sit just under the lips so the open slots show the slime below.
	local bars = Instance.new("Model")
	bars.Name = "DrainBars"
	local count = math.max(1, math.floor(len / BAR_PITCH))
	local step = len / count
	for i = 0, count - 1 do
		LabKit.deco({
			Size = Vector3.new(w - 0.1, 0.22, 0.26),
			Position = at(top - 0.13) + Vector3.new(0, 0, -len / 2 + step * (i + 0.5)),
			Kit = "SR_Steel",
			Tint = Color3.fromRGB(150, 156, 178),
		}, bars)
	end
	-- One carrier rail down the middle holding the bars up.
	LabKit.deco({
		Size = Vector3.new(0.18, 0.3, len),
		Position = at(top - 0.39),
		Kit = "SR_Steel",
		Tint = Color3.fromRGB(110, 116, 140),
	}, bars)
	bars.Parent = parent
	LabKit.part({
		Name = "DrainGrate",
		Size = Vector3.new(w + 0.1, 0.12, len),
		Position = at(top - 0.06),
		Transparency = 1,
	}, parent)
	-- Steel lips along both trench edges.
	for _, side in { -1, 1 } do
		LabKit.deco({
			Size = Vector3.new(0.35, 0.14, len),
			Position = at(top + 0.02) + Vector3.new(side * (w / 2 + 0.1), 0, 0),
			Kit = "SR_Steel",
			Tint = Color3.fromRGB(150, 156, 176),
		}, parent)
	end
end

-- A floor slab over [x0,x1]x[z0,z1] (top at `top`, thickness t), split into
-- plate strips with drain trenches where the trench lines cross it.
local function deckSlab(
	parent: Instance,
	origin: Vector3,
	top: number,
	t: number,
	x0: number,
	x1: number,
	z0: number,
	z1: number
)
	if x1 - x0 < 0.1 or z1 - z0 < 0.1 then
		return
	end
	local cuts = { x0 }
	for _, tx in trenchX do
		local a, b = tx - TRENCH_W / 2, tx + TRENCH_W / 2
		if b > x0 and a < x1 then
			table.insert(cuts, math.max(a, x0))
			table.insert(cuts, math.min(b, x1))
		end
	end
	table.insert(cuts, x1)
	for i = 1, #cuts - 1 do
		local a, b = cuts[i], cuts[i + 1]
		if b - a >= 0.1 then
			local isTrench = i % 2 == 0
			if isTrench then
				trench(parent, origin, top, a, b, z0, z1)
			else
				part({
					Name = "Bulkhead",
					Size = Vector3.new(b - a, t, z1 - z0),
					Position = origin + Vector3.new((a + b) / 2, top - t / 2, (z0 + z1) / 2),
					Color = C.Floor,
					Kit = "SR_Grate",
					Tint = theme.floorTint,
				}, parent)
			end
		end
	end
end

-- Square slab with a square hole (the hatch) at a point, plus two sliding doors.
local function buildBulkhead(parent: Instance, origin: Vector3, y: number, hole: Vector3): ({ BasePart }, { CFrame })
	local cfg = Config.Shaft
	local bx0, bx1, bz0, bz1 = Room.bounds(2)
	local h = cfg.HatchSize / 2
	local t = cfg.BulkheadThickness
	local cy = y - t / 2
	local hx, hz = hole.X - origin.X, hole.Z - origin.Z
	local function slab(x0: number, x1: number, z0: number, z1: number)
		deckSlab(parent, origin, cy + t / 2, t, x0, x1, z0, z1)
	end
	slab(bx0, hx - h, bz0, bz1)
	slab(hx + h, bx1, bz0, bz1)
	slab(hx - h, hx + h, bz0, hz - h)
	slab(hx - h, hx + h, hz + h, bz1)
	-- Hazard frame around the hatch.
	for _, side in
		{
			{ 0, -h - 0.5, cfg.HatchSize + 2, 1 },
			{ 0, h + 0.5, cfg.HatchSize + 2, 1 },
			{ -h - 0.5, 0, 1, cfg.HatchSize },
			{ h + 0.5, 0, 1, cfg.HatchSize },
		}
	do
		deco({
			Size = Vector3.new(side[3], 0.2, side[4]),
			Position = origin + Vector3.new(hx + side[1], y + 0.1, hz + side[2]),
			Color = C.Hazard,
			Material = Enum.Material.SmoothPlastic,
		}, parent)
	end
	local doors: { BasePart } = {}
	local open: { CFrame } = {}
	for i, dir in { -1, 1 } do
		local closed = CFrame.new(origin + Vector3.new(hx + dir * h / 2, cy + 0.05, hz))
		local door = part({
			Name = "HatchDoor" .. i,
			Size = Vector3.new(h, t + 0.1, cfg.HatchSize),
			CFrame = closed,
			Color = C.HazardDark,
			Material = Enum.Material.DiamondPlate,
		}, parent)
		local stripe = deco({
			Size = Vector3.new(h - 1, 0.15, 1.2),
			CFrame = closed * CFrame.new(0, t / 2 + 0.05, 0),
			Color = C.Hazard,
			Material = Enum.Material.Neon,
		}, parent)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = door
		weld.Part1 = stripe
		weld.Parent = door
		stripe.Anchored = false
		table.insert(doors, door)
		table.insert(open, closed * CFrame.new(dir * (h - 0.4), 0, 0))
	end
	return doors, open
end

local function padPart(parent: Instance, origin: Vector3, pad: ShaftLayout.Pad, size: Vector3, color: Color3): Part
	local cf = ringCFrame(origin, pad.angle, pad.radius, pad.y - size.Y / 2)
	local p = part({ Name = "Pad", Size = size, CFrame = cf, Color = color, Kit = "SR_Pad" }, parent)
	-- Neon edge trim and a strut back to the wall.
	deco({
		Size = Vector3.new(size.X + 0.3, 0.3, size.Z + 0.3),
		CFrame = cf * CFrame.new(0, -size.Y / 2, 0),
		Color = C.Trim,
		Material = Enum.Material.Neon,
	}, parent)
	local wallPoint = polar(origin, pad.angle, Config.Shaft.Radius, pad.y - size.Y - 2)
	local under = cf.Position - Vector3.new(0, size.Y / 2, 0)
	local length = (wallPoint - under).Magnitude
	deco({
		Size = Vector3.new(0.6, 0.6, length),
		CFrame = CFrame.lookAt((wallPoint + under) / 2, wallPoint),
		Color = C.WallDark,
	}, parent)
	return p
end

-- Dense set dressing for one tier: lights, vents, pipes, racks, crates,
-- console, gauges, cables, signs and a railing on the landing.
-- Cryo floors: ice crystal clusters along the walls and standing cryo pods
-- (Blender pieces when imported, crafted from parts otherwise).
local function frostProps(folder: Instance, origin: Vector3, info: ShaftLayout.Tier)
	local rand = Random.new(info.index * 131 + 7)
	for k = 1, 7 do
		local angle = info.hatchAngle + 200 + k * 21 + rand:NextNumber(-5, 5)
		local cf = ringCFrame(origin, angle, Config.Shaft.Radius - 2.2, info.floorY)
			* CFrame.Angles(0, math.rad(rand:NextNumber(0, 360)), 0)
		if not LabKit.kit("IceCluster", cf, folder) then
			for c = 1, 4 do
				local h = rand:NextNumber(1.6, 3.6)
				local shard = deco({
					Size = Vector3.new(0.9, h, 0.9),
					CFrame = cf
						* CFrame.new(rand:NextNumber(-0.9, 0.9), h / 2 - 0.2, rand:NextNumber(-0.9, 0.9))
						* CFrame.Angles(
							math.rad(rand:NextNumber(-18, 18)),
							math.rad(c * 45),
							math.rad(rand:NextNumber(-18, 18))
						),
					Color = Color3.fromRGB(176, 230, 255),
					Material = Enum.Material.Ice,
					Transparency = 0.15,
				}, folder)
				shard.CastShadow = true
			end
			deco({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(3.2, 1, 3.2),
				CFrame = cf * CFrame.new(0, 0.1, 0),
				Color = Color3.fromRGB(236, 246, 255),
				Material = Enum.Material.Snow,
			}, folder)
		end
	end
	for k = 1, 2 do
		local angle = info.hatchAngle - 40 - k * 26
		local cf = ringCFrame(origin, angle, Config.Shaft.Radius - 3, info.floorY)
		if not LabKit.kit("CryoPod", cf, folder, { collide = true }) then
			part({
				Size = Vector3.new(4, 1, 4),
				CFrame = cf * CFrame.new(0, 0.5, 0),
				Kit = "SR_Steel",
				Tint = theme.pipe,
			}, folder)
			deco({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(7, 3.2, 3.2),
				CFrame = cf * CFrame.new(0, 4.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(180, 236, 255),
				Material = Enum.Material.Glass,
				Transparency = 0.45,
			}, folder)
			local blob = deco({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2, 2.4, 2),
				CFrame = cf * CFrame.new(0, 3.6, 0),
				Color = Config.Colors.SlimeDeep,
				Material = Enum.Material.SmoothPlastic,
			}, folder)
			blob.Transparency = 0.1
			part({
				Size = Vector3.new(4, 1, 4),
				CFrame = cf * CFrame.new(0, 8.5, 0),
				Kit = "SR_Steel",
				Tint = theme.pipe,
			}, folder)
			local band = deco({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, 3.4, 3.4),
				CFrame = cf * CFrame.new(0, 7.8, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Color = theme.accent,
				Material = Enum.Material.Neon,
			}, folder)
			LabKit.soften(band)
		end
	end
end

-- Greenhouse floors: mutant plant pods along the walls, hanging vines and
-- warm grow lights (Blender pieces when imported, crafted otherwise).
local function greenProps(folder: Instance, origin: Vector3, info: ShaftLayout.Tier)
	local rand = Random.new(info.index * 173 + 11)
	for k = 1, 5 do
		local angle = info.hatchAngle + 190 + k * 26 + rand:NextNumber(-6, 6)
		local cf = ringCFrame(origin, angle, Config.Shaft.Radius - 3, info.floorY)
		if not LabKit.kit("MutantPlant", cf, folder, { collide = true }) then
			part({
				Size = Vector3.new(3, 1.6, 3),
				CFrame = cf * CFrame.new(0, 0.8, 0),
				Kit = "SR_Steel",
				Tint = theme.pipe,
			}, folder)
			local bulb = deco({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(3, 3.6, 3),
				CFrame = cf * CFrame.new(0, 3.2, 0),
				Color = Color3.fromRGB(150, 80, 170),
				Material = Enum.Material.SmoothPlastic,
			}, folder)
			bulb.CastShadow = true
			for l = 0, 4 do
				deco({
					Size = Vector3.new(2.6, 0.25, 1.1),
					CFrame = cf
						* CFrame.new(0, 1.9, 0)
						* CFrame.Angles(0, math.rad(l * 72), math.rad(-30))
						* CFrame.new(1.4, 0, 0),
					Color = Color3.fromRGB(96, 200, 84),
					Material = Enum.Material.SmoothPlastic,
				}, folder)
			end
			local glowDot = deco({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.7, 0.7, 0.7),
				CFrame = cf * CFrame.new(0, 4.9, 0),
				Color = Config.Colors.Slime,
				Material = Enum.Material.Neon,
			}, folder)
			LabKit.soften(glowDot)
		end
	end
	-- Hanging vines down the walls and grow lights under the ceiling.
	for k = 1, 8 do
		local angle = info.hatchAngle + k * 45 + rand:NextNumber(-8, 8)
		local length = rand:NextNumber(6, 14)
		local top = info.ceilingY - Config.Shaft.BulkheadThickness
		local cf = ringCFrame(origin, angle, Config.Shaft.Radius - 0.6, top)
		for s = 0, math.floor(length / 1.6) do
			deco({
				Size = Vector3.new(0.9, 0.25, 0.6),
				CFrame = cf * CFrame.new((s % 2) * 0.5 - 0.25, -s * 1.6, 0) * CFrame.Angles(0, 0, math.rad(s * 40)),
				Color = Color3.fromRGB(86 + (s % 3) * 10, 180, 76),
				Material = Enum.Material.SmoothPlastic,
			}, folder)
		end
	end
	for k = 1, 3 do
		local angle = info.hatchAngle + 100 + k * 50
		local cf = ringCFrame(origin, angle, 18, info.ceilingY - Config.Shaft.BulkheadThickness - 1.6)
		if not LabKit.kit("GrowLight", cf, folder) then
			deco({ Size = Vector3.new(4, 0.6, 1.4), CFrame = cf, Kit = "SR_Steel", Tint = theme.pipe }, folder)
			local strip = deco({
				Size = Vector3.new(3.6, 0.15, 1),
				CFrame = cf * CFrame.new(0, -0.35, 0),
				Color = theme.lamp,
				Material = Enum.Material.Neon,
			}, folder)
			LabKit.soften(strip)
		end
	end
end

local function dressTier(folder: Instance, origin: Vector3, info: ShaftLayout.Tier, landing: BasePart)
	local cfg = Config.Shaft
	local floorY = info.floorY
	local h = info.hatchAngle
	local R = cfg.Radius
	-- Caged lights, two rows, between the pads.
	for i = 0, 5 do
		local angle = h + 15 + i * 60
		local y = floorY + (if i % 2 == 0 then 10 else 24)
		LabKit.lightFixture(folder, ringCFrame(origin, angle, R - 0.6, y), Color3.fromRGB(220, 240, 255), 32)
	end
	-- Ceiling light panels under the bulkhead: even fill light for the whole
	-- tier (wall fixtures alone leave the middle of upper tiers dark).
	-- Round shaft: four panels in a ring. Bigger rooms: a grid sized to the room.
	local lampCfs: { CFrame } = {}
	local lampY = info.ceilingY - cfg.BulkheadThickness - 0.4
	if info.footprint.shape == "circle" then
		for k = 0, 3 do
			local x, z = ShaftLayout.polar(h + 45 + k * 90, 17)
			local pos = origin + Vector3.new(x, lampY, z)
			table.insert(lampCfs, CFrame.lookAt(pos, Vector3.new(origin.X, pos.Y, origin.Z)))
		end
	else
		local x0, x1, z0, z1 = Room.bounds(-8)
		for gx = x0, x1, 20 do
			for gz = z0, z1, 18 do
				if Footprint.contains(info.footprint, gx, gz, 6) and (gx * gx + gz * gz) > 100 then
					table.insert(lampCfs, CFrame.new(origin + Vector3.new(gx, lampY, gz)))
				end
			end
		end
	end
	-- Many lamps in a big room: each one is softer.
	local lampScale = if #lampCfs > 4 then 0.4 else 1
	for _, cf in lampCfs do
		LabKit.deco(
			{ Size = Vector3.new(4.4, 0.5, 11), CFrame = cf, Kit = "SR_Steel", Tint = Color3.fromRGB(70, 74, 92) },
			folder
		)
		local panel = LabKit.deco({
			Size = Vector3.new(3.4, 0.2, 10),
			CFrame = cf * CFrame.new(0, -0.3, 0),
			Color = if theme.id == "Lab" then Color3.fromRGB(230, 242, 255) else theme.lamp,
			Material = Enum.Material.Neon,
		}, folder)
		local fill = Instance.new("SurfaceLight")
		fill.Face = Enum.NormalId.Bottom
		fill.Range = 44
		fill.Angle = 120
		fill.Brightness = 1.4 * lampScale
		fill.Color = theme.lamp
		if lampScale < 1 then
			LabKit.soften(panel)
		end
		fill.Parent = panel
	end
	-- Vents low on the wall.
	for _, angle in { h + 95, h + 265 } do
		LabKit.vent(folder, ringCFrame(origin, angle, R - 0.2, floorY + 6), 5)
	end
	-- Pipe clusters with gauges beside them.
	for _, angle in { h + 60, h - 120 } do
		local base = ringCFrame(origin, angle, R - 2.2, floorY)
		if not LabKit.prop("Pipes", base, 7, folder) then
			LabKit.deco(
				{ Size = Vector3.new(6, 7, 1.5), CFrame = base * CFrame.new(0, 3.5, 0), Kit = "SR_Steel" },
				folder
			)
		end
		LabKit.gauge(folder, ringCFrame(origin, angle + 7, R - 0.5, floorY + 5))
		LabKit.gauge(folder, ringCFrame(origin, angle - 7, R - 0.5, floorY + 3.5))
	end
	-- Server racks against the wall.
	for _, angle in { h + 138, h + 150 } do
		LabKit.serverRack(folder, ringCFrame(origin, angle, R - 2, floorY))
	end
	-- Crate stacks and a control console on the floor.
	for k, angle in { h + 200, h + 212, h + 224 } do
		local cf = ringCFrame(origin, angle, R - 3.5, floorY) * CFrame.Angles(0, math.rad(k * 23), 0)
		if not LabKit.prop("Crates", cf, 4 + (k % 2) * 1.5, folder, true) then
			LabKit.part({ Size = Vector3.new(3, 3, 3), CFrame = cf * CFrame.new(0, 1.5, 0), Kit = "SR_Steel" }, folder)
		end
	end
	local consoleCf = ringCFrame(origin, h + 25, R - 3, floorY)
	if not LabKit.prop("Console", consoleCf, 4.4, folder, true) then
		LabKit.part(
			{ Size = Vector3.new(6, 3, 3), CFrame = consoleCf * CFrame.new(0, 1.5, 0), Kit = "SR_Steel" },
			folder
		)
	end
	-- Cables sagging between wall points near the ceiling.
	for k = 0, 2 do
		local a1 = h + 40 + k * 110
		local p1 = origin
			+ Vector3.new(0, floorY + 37, 0)
			+ Vector3.new(math.cos(math.rad(a1)) * (R - 0.8), 0, math.sin(math.rad(a1)) * (R - 0.8))
		local a2 = a1 + 45
		local p2 = origin
			+ Vector3.new(0, floorY + 36, 0)
			+ Vector3.new(math.cos(math.rad(a2)) * (R - 0.8), 0, math.sin(math.rad(a2)) * (R - 0.8))
		LabKit.cable(folder, p1, p2, 3 + k, if k == 1 then Config.Colors.SlimeDeep else nil)
	end
	-- Signs.
	LabKit.sign(
		folder,
		ringCFrame(origin, h - 14, R - 0.4, floorY + cfg.LandingHeight + 4),
		Vector2.new(7, 2.4),
		string.format("LEVEL %d", info.index)
	)
	LabKit.sign(
		folder,
		ringCFrame(origin, h + 175, R - 0.4, floorY + 12),
		Vector2.new(8, 2.6),
		"! SLIME HAZARD !",
		Color3.fromRGB(255, 210, 60)
	)
	LabKit.sign(
		folder,
		ringCFrame(origin, h + 115, R - 0.4, floorY + 14),
		Vector2.new(6, 2.2),
		"SECTOR 7",
		Color3.fromRGB(150, 220, 255)
	)
	-- Floor accents: drain plates, a walkway strip toward the first pad.
	local function floorPlate(angle: number, radius: number, size: Vector2, kit: string, yaw: number?)
		local x, z = ShaftLayout.polar(angle, radius)
		local pos = origin + Vector3.new(x, floorY + 0.03, z)
		local facing = CFrame.lookAt(pos, Vector3.new(origin.X, pos.Y, origin.Z))
			* CFrame.Angles(0, math.rad(yaw or 0), 0)
		LabKit.deco({ Size = Vector3.new(size.X, 0.06, size.Y), CFrame = facing, Kit = kit }, folder)
	end
	floorPlate(h + 190, 22, Vector2.new(7, 7), "SR_FloorDrain")
	floorPlate(h + 250, 18, Vector2.new(7, 7), "SR_FloorDrain", 45)
	local firstPad = info.pads[1]
	for k = 0, 2 do
		floorPlate(firstPad.angle - 8, 10 + k * 5.5, Vector2.new(4, 5.5), "SR_Walkway")
	end
	-- The leak tier gets puddles spreading from the broken pipe.
	if info.index == 1 then
		for k, spec in { { 0, 30, 9 }, { 12, 25, 6 }, { -14, 27, 7 }, { 6, 19, 5 } } do
			local x, z = ShaftLayout.polar(h + 180 + spec[1], spec[2])
			local pos = origin + Vector3.new(x, floorY + 0.06 + k * 0.01, z)
			LabKit.decalPlate(
				folder,
				CFrame.new(pos) * CFrame.Angles(0, math.rad(k * 47), 0) * CFrame.Angles(math.rad(90), 0, 0),
				Vector2.new(spec[3], spec[3] * 0.7),
				"Puddle"
			)
		end
	end
	LabKit.mat(landing, "SR_Walkway")
	-- Railing on the landing's inner edge.
	local size = landing.Size
	LabKit.railing(folder, landing.CFrame * CFrame.new(0, size.Y / 2, -size.Z / 2 + 0.3), size.X - 0.6)
end

local function alarmLight(parent: Instance, cf: CFrame)
	local housing = deco({ Size = Vector3.new(1.6, 1.2, 1.6), CFrame = cf, Color = C.WallDark }, parent)
	local lamp = deco({
		Name = "AlarmLamp",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.4,
		CFrame = cf * CFrame.new(0, 0.7, 0),
		Color = C.Alarm,
		Material = Enum.Material.Neon,
	}, parent)
	local spot = Instance.new("SpotLight")
	spot.Color = C.Alarm
	spot.Range = 30
	spot.Angle = 50
	spot.Brightness = 4
	spot.Face = Enum.NormalId.Front
	spot.Parent = lamp
	CollectionService:AddTag(lamp, "AlarmLight") -- client spins these
	local _ = housing
end

-- Makes the map being built current for every builder (call again after a yield).
local function useMap(layout: ShaftLayout.Layout)
	Room.use(layout.footprint)
	theme = Themes.get(layout.map.theme)
	local x0, x1 = Room.bounds(0)
	local count = math.max(1, math.floor((x1 - x0) / TRENCH_SPACING))
	trenchX = {}
	for k = 1, count do
		table.insert(trenchX, (k - (count + 1) / 2) * TRENCH_SPACING)
	end
end

function MapService.buildShaft(origin: Vector3, seed: number, mapId: string?): Map
	local cfg = Config.Shaft
	local layout = ShaftLayout.build(seed, mapId)
	useMap(layout)
	local model = Instance.new("Model")
	model.Name = "Shaft"
	model:SetAttribute("Map", layout.map.id)
	model:SetAttribute("Theme", layout.map.theme)
	local height = layout.topY
	buildWalls(model, origin, height, layout, seed)
	useMap(layout)
	buildCore(model, origin, height, #layout.tiers)

	-- Bottom floor (tier 1).
	local bx0, bx1, bz0, bz1 = Room.bounds(2)
	deckSlab(model, origin, 0, 2, bx0, bx1, bz0, bz1)
	-- Leak: cracked pipe at the bottom with slime pouring out.
	local leak = deco({
		Name = "Leak",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(10, 3, 3),
		CFrame = ringCFrame(origin, layout.tiers[1].hatchAngle + 180, cfg.Radius - 3, 4)
			* CFrame.Angles(0, math.rad(90), 0),
		Color = C.Pipe,
	}, model)
	local gush = Instance.new("ParticleEmitter")
	gush.Color = ColorSequence.new(Config.Colors.Slime)
	gush.LightEmission = 0.4
	gush.Size = NumberSequence.new(1.2, 0.4)
	gush.Lifetime = NumberRange.new(0.8, 1.2)
	gush.Speed = NumberRange.new(8, 14)
	gush.Acceleration = Vector3.new(0, -40, 0)
	gush.SpreadAngle = Vector2.new(15, 15)
	gush.Rate = 60
	ParticleArt.style(gush, "Goo")
	gush.Parent = leak

	local tiers: { TierParts } = {}
	for _, info in layout.tiers do
		local folder = Instance.new("Folder")
		folder.Name = "Tier" .. info.index
		folder.Parent = model
		-- The climb: a lab-equipment parkour route (CourseLayout + CourseBuilder).
		local pads = CourseBuilder.build(folder, origin, info, layout.map.theme)
		local landing = padPart(folder, origin, info.landing, Vector3.new(14, 1.4, 10), C.Floor)
		landing.Name = "Landing"
		alarmLight(folder, ringCFrame(origin, info.hatchAngle, cfg.Radius - 1, info.floorY + cfg.LandingHeight + 6))
		dressTier(folder, origin, info, landing)
		if theme.id == "Cryo" then
			frostProps(folder, origin, info)
		elseif theme.id == "Greenhouse" then
			greenProps(folder, origin, info)
		end
		task.wait()
		useMap(layout)
		local hole = polar(origin, info.hatchAngle, info.hatchRadius, 0)
		local doors, doorOpen = buildBulkhead(folder, origin, info.ceilingY, hole)
		-- Bridge pads wait inside the wall until the puzzle is solved.
		local bridge: { BasePart } = {}
		local targets: { CFrame } = {}
		for _, pad in info.bridge do
			local target = ringCFrame(origin, pad.angle, pad.radius, pad.y - 0.6)
			local stowed = ringCFrame(origin, pad.angle, cfg.Radius + 3, pad.y - 0.6)
			local b = part({
				Name = "BridgePad",
				Size = Vector3.new(4, 1.2, 4),
				CFrame = stowed,
				Color = C.Hazard,
				Material = Enum.Material.DiamondPlate,
				CanCollide = false,
				Transparency = 1,
			}, folder)
			table.insert(bridge, b)
			table.insert(targets, target)
		end
		table.insert(tiers, {
			info = info,
			folder = folder,
			doors = doors,
			doorOpen = doorOpen,
			bridge = bridge,
			bridgeTargets = targets,
			landing = landing :: BasePart,
			pads = pads,
			opened = false,
		})
	end

	-- Roof: the surface lift bay (the end of the run).
	local exitPos = ExitBay.build(model, origin, layout)

	local spawns: { CFrame } = {}
	for i = 0, 11 do
		local angle = layout.tiers[1].hatchAngle + 150 + i * 5
		local pos = polar(origin, angle, 14 + (i % 3) * 4, 3)
		table.insert(spawns, CFrame.lookAt(pos, Vector3.new(origin.X, pos.Y, origin.Z)))
	end

	model.Parent = workspace:FindFirstChild("Matches")
		or (function()
			local f = Instance.new("Folder")
			f.Name = "Matches"
			f.Parent = workspace
			return f
		end)()
	return {
		model = model,
		origin = origin,
		layout = layout,
		tiers = tiers,
		spawnPoints = spawns,
		exitPosition = exitPos,
		exitY = layout.exitY,
		bottomY = origin.Y,
	}
end

-- Opens a tier: hatch doors slide apart and the bridge pads slide out of the wall.
function MapService.openTier(tier: TierParts)
	if tier.opened then
		return
	end
	tier.opened = true
	local info = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for i, door in tier.doors do
		TweenService:Create(door, info, { CFrame = tier.doorOpen[i] }):Play()
	end
	for i, pad in tier.bridge do
		pad.Transparency = 0
		pad.CanCollide = true
		task.delay((i - 1) * 0.25, function()
			TweenService:Create(pad, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = tier.bridgeTargets[i],
			}):Play()
		end)
	end
end

function MapService.destroy(map: Map)
	map.model:Destroy()
end

return MapService
