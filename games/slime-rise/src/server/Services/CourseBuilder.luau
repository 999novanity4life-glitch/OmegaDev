--!strict
-- Builds one tier's parkour route (CourseLayout) out of lab equipment: the
-- Blender kit pieces when imported, styled stand-ins otherwise. Every
-- standing surface gets a clean invisible collider so landings are exact.
-- Moving gear is real physics: conveyor pushes, centrifuge spins on a motor,
-- the robot-arm platform rides a prismatic lift. Bounce pads and fan
-- updrafts are tagged for the client (ParkourController).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ParticleArt = require(Shared:WaitForChild("ParticleArt"))
local ShaftLayout = require(Shared:WaitForChild("ShaftLayout"))
local CourseLayout = require(Shared:WaitForChild("CourseLayout"))
local JumpMath = require(Shared:WaitForChild("JumpMath"))
local LabKit = require(script.Parent.LabKit)
local Room = require(script.Parent.Room)
local Themes = require(script.Parent.Themes)

local CourseBuilder = {}

local SAFE = Color3.fromRGB(226, 232, 244)

-- Theme of the map being built (which kit piece stands in for each element).
local theme: Themes.Theme = Themes.Lab

local function ringCFrame(origin: Vector3, angle: number, radius: number, y: number): CFrame
	return Room.ring(origin, angle, radius, y)
end

-- The theme's kit piece for a lab piece, falling back to the lab piece.
local function kit(piece: string, cf: CFrame, parent: Instance, opts: LabKit.KitOptions?): Model?
	local themed = theme.kit[piece]
	if themed then
		local model = LabKit.kit(themed, cf, parent, opts)
		if model then
			return model
		end
	end
	local model = LabKit.kit(piece, cf, parent, opts)
	Themes.dress(model, theme)
	return model
end

-- Invisible exact collider for a standing surface (top at `top`).
local function collider(parent: Instance, cf: CFrame, size: Vector3, name: string?): Part
	return LabKit.part({
		Name = name or "Surface",
		Size = size,
		CFrame = cf * CFrame.new(0, -size.Y / 2, 0),
		Transparency = 1,
		CanQuery = true,
	}, parent)
end

-- Steel column from the floor up to a height, for gear that stands raised.
local function pedestal(parent: Instance, cf: CFrame, height: number, width: number)
	if height <= 0.2 then
		return
	end
	LabKit.part({
		Size = Vector3.new(width, height, width),
		CFrame = cf * CFrame.new(0, height / 2, 0),
		Kit = "SR_Steel",
		Tint = Color3.fromRGB(96, 100, 120),
	}, parent)
	LabKit.deco({
		Size = Vector3.new(width + 0.3, 0.5, width + 0.3),
		CFrame = cf * CFrame.new(0, height - 0.25, 0),
		Kit = "SR_Hazard",
	}, parent)
end

-- Strut from the wall to a raised element so nothing floats.
local function strut(parent: Instance, origin: Vector3, e: CourseLayout.Element, y: number)
	local cfg = Config.Shaft
	local near = ringCFrame(origin, e.angle, e.radius + e.half * 0.2, y)
	local wall = ringCFrame(origin, e.angle, cfg.Radius, y - 1.5)
	local a, b = near.Position, wall.Position
	LabKit.deco({
		Size = Vector3.new(0.6, 0.6, (b - a).Magnitude),
		CFrame = CFrame.lookAt((a + b) / 2, b),
		Kit = "SR_Steel",
	}, parent)
end

local function build(parent: Instance, origin: Vector3, floorY: number, e: CourseLayout.Element): BasePart?
	local top = floorY + e.y
	local floorCf = ringCFrame(origin, e.angle, e.radius, floorY)
	local topCf = ringCFrame(origin, e.angle, e.radius, top)
	local kind = e.kind
	if kind == "Crate" then
		local count = math.max(1, math.floor(e.y / 4 + 0.5))
		for k = 0, count - 1 do
			local cf = floorCf * CFrame.new(0, k * 4, 0) * CFrame.Angles(0, math.rad((k * 37) % 20 - 10), 0)
			if not kit("Crate", cf, parent, { collide = true }) then
				LabKit.part(
					{ Size = Vector3.new(4, 4, 4), CFrame = cf * CFrame.new(0, 2, 0), Kit = "SR_Steel" },
					parent
				)
			end
		end
		return collider(parent, topCf, Vector3.new(4, 0.4, 4))
	elseif kind == "Tank" then
		local raise = e.y - 9
		pedestal(parent, floorCf, raise, 6)
		local cf = floorCf * CFrame.new(0, math.max(raise, 0), 0)
		if not kit("Tank", cf, parent, { collide = true, fidelity = Enum.CollisionFidelity.Hull }) then
			LabKit.part({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(9, 5.2, 5.2),
				CFrame = cf * CFrame.new(0, 4.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Kit = "SR_Steel",
			}, parent)
		end
		return collider(parent, topCf, Vector3.new(5.2, 0.4, 5.2))
	elseif kind == "Shelf" then
		local raise = e.y - 12
		pedestal(parent, floorCf, raise, 5)
		local cf = floorCf * CFrame.new(0, math.max(raise, 0), 0)
		if not kit("Shelf", cf, parent, { collide = true }) then
			LabKit.part({ Size = Vector3.new(6, 12, 3), CFrame = cf * CFrame.new(0, 6, 0), Kit = "SR_Steel" }, parent)
		end
		return collider(parent, topCf, Vector3.new(6, 0.4, 3))
	elseif kind == "PipeBeam" then
		local cf = topCf * CFrame.new(0, -2, 0)
		if not kit("PipeBeam", cf, parent) then
			LabKit.deco({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(12, 2, 2),
				CFrame = cf * CFrame.new(0, 1, 0),
				Kit = "SR_Steel",
			}, parent)
		end
		for _, x in { -5.5, 5.5 } do
			local pole = topCf * CFrame.new(x, -1, 0)
			local height = top - floorY - 1
			LabKit.deco({
				Size = Vector3.new(0.7, height, 0.7),
				CFrame = pole * CFrame.new(0, -height / 2 - 1, 0),
				Kit = "SR_Steel",
			}, parent)
		end
		strut(parent, origin, e, top - 1)
		return collider(parent, topCf, Vector3.new(12, 0.6, 1.8))
	elseif kind == "Conveyor" then
		local raise = e.y - 2.4
		pedestal(parent, floorCf * CFrame.new(-4, 0, 0), raise, 1.4)
		pedestal(parent, floorCf * CFrame.new(4, 0, 0), raise, 1.4)
		local cf = floorCf * CFrame.new(0, math.max(raise, 0), 0)
		if not kit("Conveyor", cf, parent) then
			LabKit.part(
				{ Size = Vector3.new(14, 2.4, 4), CFrame = cf * CFrame.new(0, 1.2, 0), Kit = "SR_Steel" },
				parent
			)
		end
		-- The belt pushes back against the route (towards the previous gear).
		local belt = collider(parent, topCf, Vector3.new(14, 0.4, 3.2), "Belt")
		belt.AssemblyLinearVelocity = topCf.RightVector * 7
		return belt
	elseif kind == "Centrifuge" then
		local columnHeight = e.y - 1
		LabKit.part({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(columnHeight, 2.4, 2.4),
			CFrame = floorCf * CFrame.new(0, columnHeight / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Kit = "SR_Steel",
		}, parent)
		kit("CentrifugeBase", floorCf * CFrame.new(0, columnHeight - 2.2, 0), parent)
		-- Spinning disc: an unanchored collider on a hinge motor, meshes welded on.
		local disc = LabKit.part({
			Name = "CentrifugeDisc",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 10, 10),
			CFrame = topCf * CFrame.new(0, -0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Transparency = 1,
		}, parent)
		local visual = kit("CentrifugeDisc", topCf * CFrame.new(0, -0.95, 0), parent, { name = "DiscVisual" })
		if not visual then
			disc.Transparency = 0
			LabKit.mat(disc, "SR_Pad", SAFE)
		else
			for _, m in visual:GetChildren() do
				if m:IsA("BasePart") then
					m.Anchored = false
					m.Massless = true
					local w = Instance.new("WeldConstraint")
					w.Part0 = disc
					w.Part1 = m
					w.Parent = m
				end
			end
		end
		local anchor =
			LabKit.deco({ Size = Vector3.one, CFrame = topCf * CFrame.new(0, -0.9, 0), Transparency = 1 }, parent)
		local a0 = Instance.new("Attachment")
		a0.CFrame = CFrame.Angles(0, 0, math.rad(90))
		a0.Parent = anchor
		local a1 = Instance.new("Attachment")
		a1.Parent = disc
		a1.WorldCFrame = a0.WorldCFrame * CFrame.new(0, 0, 0)
		local hinge = Instance.new("HingeConstraint")
		hinge.Attachment0 = a0
		hinge.Attachment1 = a1
		hinge.ActuatorType = Enum.ActuatorType.Motor
		hinge.MotorMaxTorque = 1e8
		hinge.AngularVelocity = 0.7
		hinge.Parent = disc
		disc.Anchored = false
		return disc
	elseif kind == "Bounce" then
		local raise = e.y - 0.6
		pedestal(parent, floorCf, raise, 5.6)
		local cf = floorCf * CFrame.new(0, math.max(raise, 0), 0)
		if not kit("BouncePad", cf, parent) then
			LabKit.deco({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(4.4, 2, 4.4),
				CFrame = cf * CFrame.new(0, 0.6, 0),
				Color = Config.Colors.SlimeDeep,
				Material = Enum.Material.Neon,
			}, parent)
		end
		local pad = collider(parent, topCf, Vector3.new(4.6, 0.4, 4.6), "BouncePad")
		-- Launch speed to clear the lift plus 3 studs: v = sqrt(2 g h).
		pad:SetAttribute("Launch", JumpMath.launchSpeed((e.rise or 10) + 3))
		CollectionService:AddTag(pad, "BouncePad")
		return pad
	elseif kind == "Fan" then
		local raise = e.y - 1.05
		pedestal(parent, floorCf, raise, 7.6)
		local cf = floorCf * CFrame.new(0, math.max(raise, 0), 0)
		kit("Fan", cf, parent)
		local blades = kit("FanBlades", cf * CFrame.new(0, 0.55, 0), parent)
		if blades then
			for _, m in blades:GetChildren() do
				CollectionService:AddTag(m, "FanSpinY")
				m:SetAttribute("Pivot", cf.Position)
			end
		end
		local zone = LabKit.deco({
			Name = "Updraft",
			Size = Vector3.new(6.5, (e.rise or 10) + 6, 6.5),
			CFrame = topCf * CFrame.new(0, ((e.rise or 10) + 6) / 2, 0),
			Transparency = 1,
		}, parent)
		zone:SetAttribute("Top", top + (e.rise or 10) + 2)
		CollectionService:AddTag(zone, "Updraft")
		-- Rising air streaks so players can see the lift.
		local streaks = Instance.new("ParticleEmitter")
		streaks.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
		streaks.Transparency = NumberSequence.new(0.6, 1)
		streaks.Size = NumberSequence.new(0.9, 0.5)
		streaks.Lifetime = NumberRange.new(0.8, 1.2)
		streaks.Speed = NumberRange.new(14, 20)
		streaks.EmissionDirection = Enum.NormalId.Top
		streaks.Rate = 30
		ParticleArt.style(streaks, "Streak")
		streaks.Parent = zone
		return collider(parent, topCf, Vector3.new(7, 0.4, 7), "FanGrill")
	elseif kind == "Arm" then
		kit("RobotBase", ringCFrame(origin, e.angle, e.radius + 5, floorY + e.y - 9), parent)
		local lift = e.rise or 6
		local platform = LabKit.part({
			Name = "ArmPlatform",
			Size = Vector3.new(6, 0.7, 6),
			CFrame = topCf * CFrame.new(0, -0.35, 0),
			Transparency = 1,
		}, parent)
		local visual = kit("ArmPlatform", topCf * CFrame.new(0, -0.7, 0), parent, { name = "ArmVisual" })
		if not visual then
			platform.Transparency = 0
			LabKit.mat(platform, "SR_Pad", SAFE)
		else
			for _, m in visual:GetChildren() do
				if m:IsA("BasePart") then
					m.Anchored = false
					m.Massless = true
					local w = Instance.new("WeldConstraint")
					w.Part0 = platform
					w.Part1 = m
					w.Parent = m
				end
			end
		end
		local base =
			LabKit.deco({ Size = Vector3.one, CFrame = topCf * CFrame.new(0, -0.35, 0), Transparency = 1 }, parent)
		local a0 = Instance.new("Attachment")
		a0.CFrame = CFrame.Angles(0, 0, math.rad(90)) -- slide along world up
		a0.Parent = base
		local a1 = Instance.new("Attachment")
		a1.Parent = platform
		a1.WorldCFrame = a0.WorldCFrame
		local slider = Instance.new("PrismaticConstraint")
		slider.Attachment0 = a0
		slider.Attachment1 = a1
		slider.ActuatorType = Enum.ActuatorType.Servo
		slider.ServoMaxForce = 1e7
		slider.Speed = 3.5
		slider.LimitsEnabled = true
		slider.LowerLimit = 0
		slider.UpperLimit = lift
		slider.Parent = platform
		platform.Anchored = false
		-- Ride up, pause, come back down.
		task.spawn(function()
			while platform.Parent do
				slider.TargetPosition = lift
				task.wait(lift / slider.Speed + 1.5)
				slider.TargetPosition = 0
				task.wait(lift / slider.Speed + 1.5)
			end
		end)
		return platform
	elseif kind == "IceLedge" then
		-- Steel ledge under a thick ice top: slippery underfoot.
		if not kit("IceLedge", topCf * CFrame.new(0, -1, 0), parent) then
			LabKit.part(
				{ Size = Vector3.new(6, 0.6, 3), CFrame = topCf * CFrame.new(0, -0.7, 0), Kit = "SR_Steel" },
				parent
			)
			LabKit.deco({
				Size = Vector3.new(6.2, 0.5, 3.2),
				CFrame = topCf * CFrame.new(0, -0.2, 0),
				Color = Color3.fromRGB(190, 236, 255),
				Material = Enum.Material.Ice,
				Transparency = 0.15,
			}, parent)
		end
		strut(parent, origin, e, top - 0.8)
		local surface = collider(parent, topCf, Vector3.new(6, 0.4, 3), "IceSurface")
		surface.CustomPhysicalProperties = PhysicalProperties.new(0.9, 0.02, 0, 100, 1)
		return surface
	elseif kind == "FrostPanel" then
		-- Frosted glass panel: cracks and fades a moment after you land, then
		-- refreezes. Telegraphed by a frost tint that whitens as it goes.
		local visual = kit("FrostPanel", topCf * CFrame.new(0, -0.6, 0), parent)
		local looks: { BasePart } = {}
		if visual then
			for _, d in visual:GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(looks, d)
				end
			end
		else
			table.insert(
				looks,
				LabKit.deco({
					Size = Vector3.new(5, 0.5, 5),
					CFrame = topCf * CFrame.new(0, -0.25, 0),
					Color = Color3.fromRGB(200, 240, 255),
					Material = Enum.Material.Glass,
					Transparency = 0.3,
				}, parent)
			)
			for _, edge in { { 0, 2.6, 5.4, 0.3 }, { 0, -2.6, 5.4, 0.3 }, { 2.6, 0, 0.3, 5.4 }, { -2.6, 0, 0.3, 5.4 } } do
				table.insert(
					looks,
					LabKit.deco({
						Size = Vector3.new(edge[3], 0.6, edge[4]),
						CFrame = topCf * CFrame.new(edge[1], -0.3, edge[2]),
						Kit = "SR_Steel",
					}, parent)
				)
			end
		end
		strut(parent, origin, e, top - 0.6)
		local surface = collider(parent, topCf, Vector3.new(5, 0.4, 5), "FrostPanel")
		local base: { [BasePart]: number } = {}
		for _, look in looks do
			base[look] = look.Transparency
		end
		local busy = false
		surface.Touched:Connect(function(hit)
			if busy or not hit.Parent or not hit.Parent:FindFirstChildOfClass("Humanoid") then
				return
			end
			busy = true
			task.spawn(function()
				task.wait(Config.Course.FrostWarnSeconds)
				for _, look in looks do
					look.Transparency = math.max(base[look], 0.75)
				end
				surface.CanCollide = false
				task.wait(Config.Course.FrostGoneSeconds)
				for _, look in looks do
					look.Transparency = base[look]
				end
				surface.CanCollide = true
				busy = false
			end)
		end)
		return surface
	elseif kind == "Catwalk" then
		if not kit("Catwalk", topCf, parent) then
			LabKit.part(
				{ Size = Vector3.new(8, 0.4, 4), CFrame = topCf * CFrame.new(0, -0.2, 0), Kit = "SR_Steel" },
				parent
			)
		end
		strut(parent, origin, e, top - 0.5)
		LabKit.deco({
			Size = Vector3.new(0.6, top - floorY, 0.6),
			CFrame = topCf * CFrame.new(-3.5, -(top - floorY) / 2, -1.6),
			Kit = "SR_Steel",
		}, parent)
		return collider(parent, topCf, Vector3.new(8, 0.4, 4))
	end
	return nil
end

-- Builds the whole route; returns the standing surfaces in route order.
function CourseBuilder.build(parent: Instance, origin: Vector3, info: ShaftLayout.Tier, themeId: string?): { BasePart }
	Room.use(info.footprint)
	theme = Themes.get(themeId)
	local folder = Instance.new("Folder")
	folder.Name = "Course"
	folder.Parent = parent
	local surfaces: { BasePart } = {}
	-- "Climb here" marker: a lit sign on a post beside the first piece of gear.
	local first = info.course[1]
	if first then
		local postCf = ringCFrame(origin, first.angle - 9, first.radius - 3, info.floorY)
		LabKit.part(
			{ Size = Vector3.new(0.5, 6, 0.5), CFrame = postCf * CFrame.new(0, 3, 0), Kit = "SR_Steel" },
			folder
		)
		LabKit.sign(
			folder,
			postCf * CFrame.new(0, 6.6, -0.3),
			Vector2.new(4.6, 1.8),
			"CLIMB  >",
			Color3.fromRGB(255, 220, 90)
		)
		LabKit.deco({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, 7, 7),
			CFrame = ringCFrame(origin, first.angle, first.radius, info.floorY + 0.05)
				* CFrame.Angles(0, 0, math.rad(90)),
			Kit = "SR_Hazard",
		}, folder)
	end
	for _, e in info.course do
		local s = build(folder, origin, info.floorY, e)
		if s then
			table.insert(surfaces, s)
		end
	end
	return surfaces
end

return CourseBuilder
