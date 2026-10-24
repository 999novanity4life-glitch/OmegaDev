--!strict
-- What makes each map's room look like its own part of the lab: wall bays,
-- panel finish, which Blender kit piece stands in for each course element,
-- floor and accent colours, and the centrepiece. Kit pieces that aren't
-- imported yet fall back to the lab kit, then to plain parts.

local Themes = {}

export type Theme = {
	id: string,
	wallBays: { [string]: string }, -- wall panel variant -> Blender wall bay
	panelKit: string?, -- override every wall panel's material (nil = per-variant, "Plain" = flat colour)
	panelTint: Color3?,
	kit: { [string]: string }, -- course element kind -> kit piece
	floorTint: Color3?,
	accent: Color3, -- glow strips, trim lights
	pipe: Color3,
	core: string, -- "Slime" | "Cryo"
	props: { string }, -- decor kit pieces scattered on each floor
	palette: { [string]: Color3 }?, -- re-dress lab kit stand-ins (by material group)
	coolant: Color3, -- what flows in the floor drains
	lamp: Color3, -- ceiling light colour
}

Themes.Lab = {
	id = "Lab",
	wallBays = {
		SR_WallPlain = "WallPlain",
		SR_WallVent = "WallVent",
		SR_WallWindow = "WallWindow",
		SR_WallPipe = "WallPipes",
	},
	panelKit = nil,
	panelTint = nil,
	kit = {},
	floorTint = nil,
	accent = Color3.fromRGB(107, 255, 61),
	pipe = Color3.fromRGB(110, 116, 140),
	core = "Slime",
	props = {},
	palette = nil,
	coolant = Color3.fromRGB(107, 255, 61),
	lamp = Color3.fromRGB(225, 238, 255),
} :: Theme

Themes.Cryo = {
	id = "Cryo",
	wallBays = {
		SR_WallPlain = "CryoWallPlain",
		SR_WallVent = "CryoWallVent",
		SR_WallWindow = "CryoWallWindow",
		SR_WallPipe = "CryoWallPlain",
		SR_WallControl = "CryoWallPlain",
	},
	panelKit = "Plain",
	panelTint = Color3.fromRGB(184, 204, 222),
	kit = {
		Crate = "CryoCrate",
		Tank = "CryoTank",
		Shelf = "CryoRack",
		PipeBeam = "CryoPipe",
		Catwalk = "CryoCatwalk",
		IceLedge = "IceLedge",
		FrostPanel = "FrostPanel",
	},
	floorTint = Color3.fromRGB(196, 220, 236),
	accent = Color3.fromRGB(110, 220, 255),
	pipe = Color3.fromRGB(150, 176, 200),
	core = "Cryo",
	props = { "CryoPod", "IceCluster" },
	palette = {
		Frame = Color3.fromRGB(206, 224, 236),
		Inset = Color3.fromRGB(112, 152, 190),
		Dark = Color3.fromRGB(38, 52, 72),
		Glow = Color3.fromRGB(110, 220, 255),
		Slime = Color3.fromRGB(110, 220, 255),
		Glass = Color3.fromRGB(180, 236, 255),
	},
	coolant = Color3.fromRGB(90, 210, 255),
	lamp = Color3.fromRGB(225, 238, 255),
} :: Theme

Themes.Greenhouse = {
	id = "Greenhouse",
	wallBays = {
		SR_WallPlain = "GreenWallPlain",
		SR_WallVent = "GreenWallVent",
		SR_WallWindow = "GreenWallWindow",
		SR_WallPipe = "GreenWallPlain",
		SR_WallControl = "GreenWallPlain",
	},
	panelKit = "Plain",
	panelTint = Color3.fromRGB(214, 208, 188),
	kit = {
		Crate = "GreenPlanter",
		Tank = "GreenTank",
		Shelf = "GreenRack",
		PipeBeam = "GreenBeam",
		Catwalk = "GreenCatwalk",
		BouncePad = "MushroomPad",
		Leaf = "LeafPad",
		Vine = "VineTruss",
	},
	floorTint = Color3.fromRGB(214, 220, 196),
	accent = Color3.fromRGB(240, 130, 190),
	pipe = Color3.fromRGB(70, 130, 120),
	core = "Green",
	props = { "MutantPlant", "GrowLight" },
	palette = {
		Frame = Color3.fromRGB(52, 122, 112),
		Inset = Color3.fromRGB(220, 212, 190),
		Dark = Color3.fromRGB(34, 52, 48),
		Glow = Color3.fromRGB(240, 130, 190),
		Slime = Color3.fromRGB(150, 255, 90),
		Glass = Color3.fromRGB(210, 255, 220),
	},
	coolant = Color3.fromRGB(120, 230, 140),
	lamp = Color3.fromRGB(255, 236, 200),
} :: Theme

-- Re-dress a lab kit model in a theme's palette (until its own kit exists).
function Themes.dress(model: Model?, theme: Theme)
	local palette = theme.palette
	if not model or not palette then
		return
	end
	for _, m in model:GetDescendants() do
		if m:IsA("BasePart") then
			local color = palette[m.Name]
			if color then
				m.Color = color
				if m.Name == "Glow" or m.Name == "Slime" then
					local h, s, v = color:ToHSV()
					m.Color = Color3.fromHSV(h, s, v * 0.62)
				end
			end
		end
	end
end

function Themes.get(id: string?): Theme
	if id == "Cryo" then
		return Themes.Cryo
	elseif id == "Greenhouse" then
		return Themes.Greenhouse
	end
	return Themes.Lab
end

return Themes
