--!strict
-- Models for the robots that leave a base to clean: the Dot Bot (a hovering ball with a glowing
-- ring) and the Cosmic Octo (a big purple dome on eight arms). Anchored, moved by the server.
-- Each body has a "Dust" ParticleEmitter the server turns on while it cleans.

local WHITE = Color3.fromRGB(236, 238, 243)
local DARK = Color3.fromRGB(20, 22, 26)
local PURPLE = Color3.fromRGB(150, 110, 255)

local function part(
	m: Model,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Parent = m
	return p
end

local function dustEmitter(body: BasePart, size: number)
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Color = ColorSequence.new(Color3.fromRGB(200, 200, 205))
	dust.Size = NumberSequence.new(size * 0.3, size)
	dust.Transparency = NumberSequence.new(0.3, 1)
	dust.Lifetime = NumberRange.new(0.6, 1.2)
	dust.Speed = NumberRange.new(2, 4 + size)
	dust.SpreadAngle = Vector2.new(70, 70)
	dust.EmissionDirection = Enum.NormalId.Bottom
	dust.Rate = 0
	dust.Parent = body
end

local function finish(m: Model, body: BasePart): Model
	m.PrimaryPart = body
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return m
end

local Robots = {}

function Robots.dotBot(color: Color3): Model
	local m = Instance.new("Model")
	m.Name = "DotBot"
	local body =
		part(m, "Body", Enum.PartType.Ball, Vector3.new(3, 3, 3), CFrame.new(), WHITE, Enum.Material.SmoothPlastic)
	body.CanQuery = true
	part(
		m,
		"Ring",
		Enum.PartType.Cylinder,
		Vector3.new(0.4, 3.6, 3.6),
		CFrame.Angles(0, 0, math.pi / 2),
		color,
		Enum.Material.Neon
	)
	part(m, "Eye", Enum.PartType.Ball, Vector3.new(0.8, 0.8, 0.8), CFrame.new(0, 0.4, -1.3), DARK, Enum.Material.Glass)
	dustEmitter(body, 1.6)
	return finish(m, body)
end

function Robots.octo(): Model
	local m = Instance.new("Model")
	m.Name = "CosmicOcto"
	local body = part(
		m,
		"Body",
		Enum.PartType.Ball,
		Vector3.new(10, 10, 10),
		CFrame.new(0, 2, 0),
		PURPLE,
		Enum.Material.SmoothPlastic
	)
	body.CanQuery = true
	part(
		m,
		"Band",
		Enum.PartType.Cylinder,
		Vector3.new(1.2, 10.6, 10.6),
		CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(255, 132, 28),
		Enum.Material.Neon
	)
	part(m, "Visor", Enum.PartType.Ball, Vector3.new(4, 2.2, 2), CFrame.new(0, 3, -4.2), DARK, Enum.Material.Glass)
	for k = 0, 7 do
		local a = k * math.pi / 4
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		-- each arm: a thick upper segment angled out and a thinner tip reaching the ground
		local upper = CFrame.lookAt(out * 4 + Vector3.new(0, -1, 0), out * 8 + Vector3.new(0, -4, 0))
		part(
			m,
			"Arm",
			Enum.PartType.Block,
			Vector3.new(1.2, 1.2, 6),
			upper * CFrame.new(0, 0, -2.5),
			PURPLE,
			Enum.Material.SmoothPlastic
		)
		part(
			m,
			"Tip",
			Enum.PartType.Ball,
			Vector3.new(1.6, 1.6, 1.6),
			CFrame.new(out * 8.6 + Vector3.new(0, -5, 0)),
			WHITE,
			Enum.Material.Neon
		)
	end
	dustEmitter(body, 5)
	return finish(m, body)
end

return table.freeze(Robots)
