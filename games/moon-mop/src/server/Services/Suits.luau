--!strict
-- Everyone on the Moon wears a Moon Mop Co. spacesuit: the avatar's accessories and clothes
-- come off, the body takes the suit colour, and a helmet with a tinted visor and an air pack go
-- on. The colour and visor follow the character's SuitColour and Visor attributes (set by Crew
-- from the save, changed in the Suit menu).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Suits = {}

local G = Config.Gear

-- Visor tint for a style number: style 1 is the classic gold, the rest go round the colour wheel.
function Suits.visorColour(style: number): Color3
	if style <= 1 then
		return Color3.fromRGB(255, 190, 60)
	end
	return Color3.fromHSV(((style - 2) / (G.VisorStyles - 1)) % 1, 0.75, 0.95)
end

local function suitColour(index: number): Color3
	local c = G.SuitColours[math.clamp(index, 1, #G.SuitColours)]
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function weld(part: BasePart, to: BasePart, offset: CFrame)
	part.CFrame = to.CFrame * offset
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

local function piece(name: string, shape: Enum.PartType, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material
	p.CastShadow = true
	return p
end

local function paint(char: Model)
	local colour = suitColour((char:GetAttribute("SuitColour") :: number?) or 1)
	local visor = Suits.visorColour((char:GetAttribute("Visor") :: number?) or 1)
	local body = char:FindFirstChildOfClass("BodyColors")
	if body then
		body.HeadColor3 = colour
		body.TorsoColor3 = colour
		body.LeftArmColor3 = colour
		body.RightArmColor3 = colour
		body.LeftLegColor3 = colour
		body.RightLegColor3 = colour
	end
	local suit = char:FindFirstChild("MoonSuit")
	if suit then
		local v = suit:FindFirstChild("Visor") :: BasePart?
		if v then
			v.Color = visor
		end
		local stripe = suit:FindFirstChild("Stripe") :: BasePart?
		if stripe then
			stripe.Color = colour
		end
	end
end

local function dress(char: Model)
	for _, d in char:GetChildren() do
		if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			d:Destroy()
		end
	end
	local head = char:FindFirstChild("Head") :: BasePart?
	local torso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	if not head or not torso then
		return
	end
	local face = head:FindFirstChildOfClass("Decal")
	if face then
		face.Transparency = 1
	end
	local suit = Instance.new("Folder")
	suit.Name = "MoonSuit"
	local helmet = piece(
		"Helmet",
		Enum.PartType.Ball,
		Vector3.one * (head.Size.Y * 1.9),
		Color3.fromRGB(236, 238, 243),
		Enum.Material.SmoothPlastic
	)
	weld(helmet, head, CFrame.new(0, 0.1, 0))
	helmet.Parent = suit
	local visor = piece(
		"Visor",
		Enum.PartType.Ball,
		Vector3.new(head.Size.X * 1.5, head.Size.Y * 1.2, head.Size.Z * 1.2),
		Color3.fromRGB(255, 190, 60),
		Enum.Material.Glass
	)
	visor.Reflectance = 0.25
	weld(visor, head, CFrame.new(0, 0.15, -head.Size.Z * 0.45))
	visor.Parent = suit
	local pack = piece(
		"AirPack",
		Enum.PartType.Block,
		Vector3.new(torso.Size.X * 0.8, torso.Size.Y * 0.9, 0.9),
		Color3.fromRGB(226, 230, 236),
		Enum.Material.SmoothPlastic
	)
	weld(pack, torso, CFrame.new(0, 0.1, torso.Size.Z / 2 + 0.45))
	pack.Parent = suit
	local stripe = piece(
		"Stripe",
		Enum.PartType.Block,
		Vector3.new(torso.Size.X * 0.82, 0.25, 0.95),
		Color3.fromRGB(255, 132, 28),
		Enum.Material.SmoothPlastic
	)
	weld(stripe, torso, CFrame.new(0, torso.Size.Y * 0.1, torso.Size.Z / 2 + 0.45))
	stripe.Parent = suit
	local light =
		piece("Beacon", Enum.PartType.Ball, Vector3.one * 0.35, Color3.fromRGB(255, 132, 28), Enum.Material.Neon)
	weld(light, torso, CFrame.new(torso.Size.X * 0.3, torso.Size.Y * 0.5, torso.Size.Z / 2 + 0.5))
	light.Parent = suit
	suit.Parent = char
	paint(char)
	char:GetAttributeChangedSignal("SuitColour"):Connect(function()
		paint(char)
	end)
	char:GetAttributeChangedSignal("Visor"):Connect(function()
		paint(char)
	end)
end

local function onCharacter(char: Model)
	-- accessories and clothes arrive with the appearance; wait for it before dressing
	local player = Players:GetPlayerFromCharacter(char)
	if player and not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end
	if char.Parent then
		dress(char)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacter)
end)
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return Suits
