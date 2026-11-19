--!strict
-- Greybox throwing lane for the feel test: a dock to stand on, sea, and a
-- distance marker every Config.Lane.MarkerEvery studs. Throws go along -Z
-- from the dock edge. Art pass replaces this later (needs Sharman's OK on refs).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Lane = {}

local function part(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Builds the lane once and returns the throw origin (dock edge, at chest height).
function Lane.build(): CFrame
	local cfg = Config.Lane
	local folder = workspace:FindFirstChild("Lane") or Instance.new("Folder")
	folder.Name = "Lane"
	folder:ClearAllChildren()
	folder.Parent = workspace

	local dock = part(
		"Dock",
		Vector3.new(24, 2, 24),
		CFrame.new(0, cfg.DeckHeight - 1, 0),
		Color3.fromRGB(110, 78, 52),
		Enum.Material.WoodPlanks
	)
	dock.Parent = folder

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, cfg.DeckHeight + 0.5, 6)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = folder

	local sea = part(
		"Sea",
		Vector3.new(400, 1, cfg.Length + 200),
		CFrame.new(0, -0.5, -cfg.Length / 2),
		Color3.fromRGB(24, 92, 140),
		Enum.Material.SmoothPlastic
	)
	sea.Transparency = 0.15
	sea.Parent = folder

	for d = cfg.MarkerEvery, cfg.Length, cfg.MarkerEvery do
		local post = part(
			"Marker" .. d,
			Vector3.new(30, 0.4, 1),
			CFrame.new(0, 0.2, -12 - d),
			if d % (cfg.MarkerEvery * 4) == 0 then Color3.fromRGB(255, 138, 31) else Color3.fromRGB(235, 235, 235),
			Enum.Material.Neon
		)
		post.CanCollide = false
		post.Parent = folder

		if d % (cfg.MarkerEvery * 2) ~= 0 then
			continue -- label every other marker so far labels don't pile up
		end
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(120, 40)
		billboard.StudsOffset = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 220
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = tostring(d) .. " m"
		label.Parent = billboard
		billboard.Parent = post
	end

	return CFrame.lookAt(Vector3.new(0, cfg.DeckHeight + 3, -12), Vector3.new(0, cfg.DeckHeight + 3, -100))
end

return Lane
