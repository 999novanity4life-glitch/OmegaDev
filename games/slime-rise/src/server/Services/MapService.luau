--!strict
-- Builds the slime lab tower (rebuilt from a new seed every round) and the
-- lobby balcony that overlooks it. Everything is anchored, decor never collides
-- or blocks queries, and the whole map lives under workspace.Map.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapService = {}

export type Layout = {
	spawnPoints: { CFrame },
	exitPosition: Vector3,
	exitY: number,
	lobbySpawn: CFrame,
	bottomY: number,
}

local mapFolder: Folder? = nil
local lobbyFolder: Folder? = nil

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

local function decor(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

local function buildLobby(origin: Vector3): CFrame
	if lobbyFolder then
		lobbyFolder:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	local center = origin + Config.Tower.LobbyOffset
	part({
		Name = "Balcony",
		Size = Vector3.new(44, 2, 34),
		CFrame = CFrame.new(center),
		Color = Config.Colors.Floor,
		Material = Enum.Material.Metal,
	}, folder)
	-- Glass rail on the side that faces the tower, so kids can watch the round.
	local rail = part({
		Name = "Rail",
		Size = Vector3.new(1, 4, 34),
		CFrame = CFrame.new(center + Vector3.new(-22.5, 3, 0)),
		Color = Config.Colors.Trim,
		Material = Enum.Material.Glass,
		Transparency = 0.6,
	}, folder)
	rail.CanQuery = false
	local trim = part({
		Name = "Trim",
		Size = Vector3.new(44.4, 0.4, 34.4),
		CFrame = CFrame.new(center + Vector3.new(0, -1.1, 0)),
		Color = Config.Colors.Trim,
		Material = Enum.Material.Neon,
	}, folder)
	decor(trim)
	folder.Parent = workspace
	lobbyFolder = folder
	return CFrame.lookAt(center + Vector3.new(6, 4, 0), origin + Vector3.new(0, 40, 0))
end

function MapService.build(seed: number): Layout
	local cfg = Config.Tower
	local origin = cfg.Origin
	local rng = Random.new(seed)
	if mapFolder then
		mapFolder:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Map"

	-- Floor disc and the central pillar.
	part({
		Name = "Floor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, cfg.FloorRadius * 2, cfg.FloorRadius * 2),
		CFrame = CFrame.new(origin + Vector3.new(0, -1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Config.Colors.Floor,
		Material = Enum.Material.Metal,
	}, folder)
	local topY = cfg.Pads * cfg.RisePerPad + 12
	part({
		Name = "Pillar",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(topY, cfg.PillarRadius * 2, cfg.PillarRadius * 2),
		CFrame = CFrame.new(origin + Vector3.new(0, topY / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Config.Colors.Pillar,
		Material = Enum.Material.Metal,
	}, folder)
	-- Glowing slime pipes running up the pillar.
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		local pipe = part({
			Name = "Pipe",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(topY, 1.4, 1.4),
			CFrame = CFrame.new(
				origin
					+ Vector3.new(
						math.cos(a) * (cfg.PillarRadius + 0.4),
						topY / 2,
						math.sin(a) * (cfg.PillarRadius + 0.4)
					)
			) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Config.Colors.Trim,
			Material = Enum.Material.Neon,
			Transparency = 0.15,
		}, folder)
		decor(pipe)
	end

	-- The climb: a spiral of pads around the pillar, with a little seeded jitter
	-- so every round feels different but every jump stays makeable.
	local pads = Instance.new("Folder")
	pads.Name = "Pads"
	pads.Parent = folder
	local angle = rng:NextNumber(0, 360)
	local lastPosition = origin
	for i = 1, cfg.Pads do
		angle += cfg.DegreesPerPad + rng:NextNumber(-3, 3)
		local a = math.rad(angle)
		local radius = cfg.SpiralRadius + rng:NextNumber(-1.5, 1.5)
		local y = i * cfg.RisePerPad
		local position = origin + Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
		local facing = CFrame.lookAt(position, origin + Vector3.new(0, y, 0))
		local pad = part({
			Name = "Pad" .. i,
			Size = Vector3.new(9, 1.2, 7),
			CFrame = facing,
			Color = if i % 2 == 0 then Config.Colors.PadA else Config.Colors.PadB,
		}, pads)
		pad:SetAttribute("Index", i)
		local edge = part({
			Name = "Edge",
			Size = Vector3.new(9.2, 0.25, 7.2),
			CFrame = facing * CFrame.new(0, -0.7, 0),
			Color = Config.Colors.Trim,
			Material = Enum.Material.Neon,
		}, pads)
		decor(edge)
		-- A strut back to the pillar so pads never look like they float.
		local inner = origin + Vector3.new(math.cos(a) * cfg.PillarRadius, y - 0.9, math.sin(a) * cfg.PillarRadius)
		local strutLength = (position - inner).Magnitude
		local strut = part({
			Name = "Strut",
			Size = Vector3.new(0.6, 0.6, strutLength),
			CFrame = CFrame.lookAt((position + inner) / 2 - Vector3.new(0, 0.9, 0), position - Vector3.new(0, 0.9, 0)),
			Color = Config.Colors.Pillar,
			Material = Enum.Material.Metal,
		}, pads)
		decor(strut)
		lastPosition = position
	end

	-- Exit pad: a gold pad and a glowing ring right above the last spiral pad.
	local exitPosition = lastPosition + Vector3.new(0, cfg.RisePerPad, 0)
	local exitCFrame = CFrame.lookAt(exitPosition, origin + Vector3.new(0, exitPosition.Y, 0))
	part({
		Name = "ExitPad",
		Size = Vector3.new(11, 1.2, 9),
		CFrame = exitCFrame,
		Color = Config.Colors.Exit,
		Material = Enum.Material.Neon,
	}, folder)
	local ring = part({
		Name = "ExitRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 12, 12),
		CFrame = exitCFrame * CFrame.new(0, 6.5, 0) * CFrame.Angles(0, math.rad(90), 0),
		Color = Config.Colors.Exit,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
	}, folder)
	decor(ring)
	local light = Instance.new("PointLight")
	light.Color = Config.Colors.Exit
	light.Range = 18
	light.Brightness = 2
	light.Parent = ring

	-- Spawn ring on the floor, facing the first pads.
	local spawnPoints = {}
	for i = 1, 12 do
		local a = math.rad(i * 30)
		local p = origin + Vector3.new(math.cos(a) * 30, 3, math.sin(a) * 30)
		table.insert(spawnPoints, CFrame.lookAt(p, origin + Vector3.new(0, 3, 0)))
	end

	folder.Parent = workspace
	mapFolder = folder
	return {
		spawnPoints = spawnPoints,
		exitPosition = exitPosition,
		exitY = exitPosition.Y,
		lobbySpawn = buildLobby(origin),
		bottomY = origin.Y,
	}
end

return MapService
