--!strict
-- Team puzzles, one per tier. Everything is decided on the server: prompts
-- fire on the server, plates are checked from server positions. A solve
-- calls ctx.onSolved, which opens the tier (hatch + bridge).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShaftLayout = require(Shared:WaitForChild("ShaftLayout"))
local PuzzleRules = require(Shared:WaitForChild("PuzzleRules"))
local MapService = require(script.Parent.MapService)
local LabKit = require(script.Parent.LabKit)
local MiniGames = require(script.Parent.MiniGames)

local PuzzleService = {}

export type Context = {
	origin: Vector3,
	playerCount: number,
	seed: number,
	isClimber: (player: Player) -> boolean,
	climbers: () -> { Player },
	onSolved: () -> (),
	onProgress: (sound: string, position: Vector3) -> (),
}
export type Puzzle = {
	kind: string,
	title: string, -- shown on the intro push-in
	label: string,
	focus: Vector3, -- where the intro camera frames this puzzle
	update: (dt: number) -> (),
	progress: () -> (number, number),
	solved: () -> boolean,
	cleanup: () -> (),
}

local COLORS: { [string]: Color3 } = {
	Green = Config.Colors.Slime,
	Purple = Color3.fromRGB(166, 107, 255),
	Teal = Color3.fromRGB(61, 232, 255),
	Orange = Color3.fromRGB(255, 150, 40),
}
local DARK = Color3.fromRGB(28, 24, 40)
local METAL = Color3.fromRGB(110, 116, 140)

local function part(props: { [string]: any }, parent: Instance): Part
	if props.Kit == nil and props.Material == nil then
		props.Kit = "SR_Steel"
	end
	return LabKit.part(props, parent)
end

local function ringCFrame(origin: Vector3, angle: number, radius: number, y: number): CFrame
	local x, z = ShaftLayout.polar(angle, radius)
	local pos = origin + Vector3.new(x, y, z)
	return CFrame.lookAt(pos, Vector3.new(origin.X, pos.Y, origin.Z))
end

local function prompt(parent: Instance, action: string, object: string, hold: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = Config.Puzzles.PromptDistance
	p.RequiresLineOfSight = false
	p.Style = Enum.ProximityPromptStyle.Default
	p.Parent = parent
	return p
end

-- Valve Wheels: hold E on every valve.
local function valves(tier: MapService.TierParts, ctx: Context): Puzzle
	local count = PuzzleRules.valveCount(ctx.playerCount)
	local folder = Instance.new("Folder")
	folder.Name = "Valves"
	folder.Parent = tier.folder
	local done = 0
	local pads = tier.info.pads
	local focus = Vector3.zero
	for i = 1, count do
		local pad = pads[math.clamp(math.floor((i - 0.5) * #pads / count) + 1, 1, #pads)]
		local base = ringCFrame(ctx.origin, pad.angle + 9, Config.Shaft.Radius - 1.2, pad.y + 3.2)
		if i == 1 then
			focus = base.Position
		end
		-- Steel wall bracket with a generated valve on it and a status lamp.
		LabKit.part({
			Size = Vector3.new(3.6, 0.5, 3),
			CFrame = base * CFrame.new(0, -1.95, -0.6),
			Kit = "SR_Steel",
			Color = METAL,
		}, folder)
		LabKit.deco({
			Size = Vector3.new(0.5, 1.6, 2.6),
			CFrame = base * CFrame.new(-1.4, -2.9, 0.4),
			Kit = "SR_Steel",
			Color = METAL,
		}, folder)
		LabKit.deco({
			Size = Vector3.new(0.5, 1.6, 2.6),
			CFrame = base * CFrame.new(1.4, -2.9, 0.4),
			Kit = "SR_Steel",
			Color = METAL,
		}, folder)
		local lamp = part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.9,
			CFrame = base * CFrame.new(1.4, 2.1, 0.4),
			Color = Color3.fromRGB(255, 60, 60),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
		local wheel: BasePart = LabKit.prop("Valve", base * CFrame.new(0, -1.7, -0.6), 3.4, folder)
			or part({
				Name = "Valve",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.5, 3.2, 3.2),
				CFrame = base * CFrame.new(0, 0, -0.8) * CFrame.Angles(0, math.rad(90), 0),
				Color = Color3.fromRGB(230, 60, 60),
				CanCollide = false,
			}, folder)
		local p = prompt(wheel, "Turn valve", "Valve " .. i, Config.Puzzles.ValveHoldSeconds)
		p.Triggered:Connect(function(player)
			if not ctx.isClimber(player) or not p.Enabled then
				return
			end
			p.Enabled = false
			done += 1
			lamp.Color = COLORS.Green
			TweenService:Create(
				wheel,
				TweenInfo.new(0.8, Enum.EasingStyle.Back),
				{ CFrame = wheel.CFrame * CFrame.Angles(0, math.rad(270), 0) }
			):Play()
			ctx.onProgress("Valve", wheel.Position)
			if done >= count then
				ctx.onSolved()
			end
		end)
	end
	return {
		kind = "Valves",
		title = "VALVE CONTROL",
		label = "Turn the valves",
		focus = focus,
		update = function() end,
		progress = function()
			return done, count
		end,
		solved = function()
			return done >= count
		end,
		cleanup = function()
			folder:Destroy()
		end,
	}
end

-- Pressure Plates: stand on all of them at once.
local function plates(tier: MapService.TierParts, ctx: Context): Puzzle
	local count = PuzzleRules.plateCount(ctx.playerCount)
	local folder = Instance.new("Folder")
	folder.Name = "Plates"
	folder.Parent = tier.folder
	local list: { Part } = {}
	local floorY = tier.info.floorY
	for i = 1, count do
		local angle = tier.info.hatchAngle + 180 + (i - (count + 1) / 2) * 40
		local cf = ringCFrame(ctx.origin, angle, 15, floorY + 0.2)
		part({ Size = Vector3.new(7, 0.3, 7), CFrame = cf, Color = DARK, CanCollide = false }, folder)
		local plate = part({
			Name = "Plate",
			Size = Vector3.new(5.6, 0.4, 5.6),
			CFrame = cf * CFrame.new(0, 0.1, 0),
			Color = Color3.fromRGB(120, 60, 60),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
		table.insert(list, plate)
	end
	-- Solo: a heavy ballast canister to carry onto one plate (weights = plates
	-- the players alone can't cover).
	local solvedFlag = false
	local weighted: { [BasePart]: boolean } = {}
	local weights = PuzzleRules.plateWeights(ctx.playerCount)
	for w = 1, weights do
		local homeCf = ringCFrame(ctx.origin, tier.info.hatchAngle + 180 + (w - 1) * 8, 22, floorY + 1.4)
		local body = part({
			Name = "Ballast",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.4, 1.9, 1.9),
			CFrame = homeCf * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(70, 74, 92),
			CanCollide = false,
		}, folder)
		local function attach(props: { [string]: any }, offset: CFrame)
			props.CanCollide = false
			props.CanQuery = false
			props.CFrame = body.CFrame * offset
			local piece = part(props, folder)
			piece.Anchored = false
			piece.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = piece
			weld.Parent = piece
		end
		for _, x in { -0.75, 0.75 } do
			attach({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, 2, 2),
				Color = Config.Colors.Exit,
				Material = Enum.Material.SmoothPlastic,
			}, CFrame.new(x, 0, 0))
		end
		attach({ Size = Vector3.new(0.3, 0.3, 1.2), Color = METAL }, CFrame.new(1.35, 0, 0))
		attach({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.45, 0.45, 0.45),
			Color = COLORS.Green,
			Material = Enum.Material.Neon,
		}, CFrame.new(0.2, 0, -0.95))
		local onPlate: BasePart? = nil
		local holder: Player? = nil
		local pick = prompt(body, "Pick up", "Ballast", 0.3)
		local function release(player: Player)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
			end
			local weld = body:FindFirstChild("CarryWeld")
			if weld then
				weld:Destroy()
			end
			holder = nil
			body.Anchored = true
			pick.Enabled = true
		end
		pick.Triggered:Connect(function(player)
			if solvedFlag or holder or not ctx.isClimber(player) then
				return
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid then
				return
			end
			if onPlate then
				weighted[onPlate] = nil
				onPlate = nil
			end
			holder = player
			pick.Enabled = false
			body.Anchored = false
			body.Massless = true
			body.CFrame = root.CFrame * CFrame.new(0, 0, -1.6) * CFrame.Angles(0, 0, math.rad(90))
			local weld = Instance.new("WeldConstraint")
			weld.Name = "CarryWeld"
			weld.Part0 = root
			weld.Part1 = body
			weld.Parent = body
			humanoid.WalkSpeed = Config.Puzzles.FuseWalkSpeed
			humanoid.Died:Once(function()
				if holder == player then
					release(player)
					body.CFrame = homeCf * CFrame.Angles(0, 0, math.rad(90))
				end
			end)
			ctx.onProgress("Valve", body.Position)
		end)
		for _, plate in list do
			local set = prompt(plate, "Set down", "Ballast", 0.3)
			set.Triggered:Connect(function(player)
				if holder ~= player or weighted[plate] then
					return
				end
				release(player)
				body.CFrame = plate.CFrame * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90))
				weighted[plate] = true
				onPlate = plate
				ctx.onProgress("Valve", plate.Position)
			end)
		end
	end
	local heldFor = 0
	local lit = 0
	return {
		kind = "Plates",
		title = "PRESSURE PLATES",
		label = if weights > 0 then "Weigh down a plate, stand on the other" else "Stand on every plate together",
		focus = ringCFrame(ctx.origin, tier.info.hatchAngle + 180, 15, floorY + 0.2).Position,
		update = function(dt: number)
			if solvedFlag then
				return
			end
			lit = 0
			for _, plate in list do
				local on = weighted[plate] == true
				if not on then
					for _, player in ctx.climbers() do
						local character = player.Character
						local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if root then
							local d = root.Position - plate.Position
							if math.abs(d.X) < 3.4 and math.abs(d.Z) < 3.4 and d.Y > 0 and d.Y < 5 then
								on = true
								break
							end
						end
					end
				end
				plate.Color = if on then COLORS.Green else Color3.fromRGB(120, 60, 60)
				if on then
					lit += 1
				end
			end
			heldFor = if lit == #list then heldFor + dt else 0
			if heldFor >= Config.Puzzles.PlateHoldSeconds then
				solvedFlag = true
				ctx.onProgress("Valve", list[1].Position)
				ctx.onSolved()
			end
		end,
		progress = function()
			return if solvedFlag then #list else lit, #list
		end,
		solved = function()
			return solvedFlag
		end,
		cleanup = function()
			folder:Destroy()
		end,
	}
end

-- Color Code: set every lever lamp to the code on the monitor.
local function colors(tier: MapService.TierParts, ctx: Context): Puzzle
	local names = Config.Puzzles.ColorNames
	local code = PuzzleRules.colorCode(ctx.seed + tier.info.index, Config.Puzzles.ColorLevers, #names)
	local folder = Instance.new("Folder")
	folder.Name = "Colors"
	folder.Parent = tier.folder
	-- Monitor above the landing shows the code.
	local screenCf = ringCFrame(ctx.origin, tier.info.hatchAngle - 25, Config.Shaft.Radius - 0.8, tier.info.floorY + 12)
	local monitor = part({ Size = Vector3.new(9, 5, 0.6), CFrame = screenCf, Color = DARK, CanCollide = false }, folder)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = monitor
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.3)
	title.BackgroundTransparency = 1
	title.Text = "OVERRIDE CODE"
	title.TextScaled = true
	title.FontFace = Font.fromName("FredokaOne")
	title.TextColor3 = COLORS.Green
	title.Parent = gui
	for i, index in code do
		local swatch = Instance.new("Frame")
		swatch.Size = UDim2.fromScale(0.26, 0.55)
		swatch.Position = UDim2.fromScale(0.05 + (i - 1) * 0.31, 0.38)
		swatch.BackgroundColor3 = COLORS[names[index]]
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = swatch
		swatch.Parent = gui
	end
	local current: { number } = {}
	local solvedFlag = false
	for i = 1, #code do
		current[i] = (code[i] % #names) + 1 -- start wrong on purpose
		local angle = tier.info.hatchAngle + 160 + (i - 2) * 22
		local base = ringCFrame(ctx.origin, angle, Config.Shaft.Radius - 2, tier.info.floorY + 2)
		part({ Size = Vector3.new(2.4, 4, 1.4), CFrame = base, Color = DARK }, folder)
		local lamp = part({
			Name = "Lamp",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.6,
			CFrame = base * CFrame.new(0, 2.8, 0),
			Color = COLORS[names[current[i]]],
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, folder)
		local lever = part({
			Size = Vector3.new(0.5, 2.2, 0.5),
			CFrame = base * CFrame.new(0, 0.4, -1) * CFrame.Angles(math.rad(-30), 0, 0),
			Color = METAL,
			CanCollide = false,
		}, folder)
		local p = prompt(lever, "Switch color", "Lever " .. i, 0)
		p.Triggered:Connect(function(player)
			if solvedFlag or not ctx.isClimber(player) then
				return
			end
			current[i] = current[i] % #names + 1
			lamp.Color = COLORS[names[current[i]]]
			ctx.onProgress("Valve", lamp.Position)
			if PuzzleRules.codeMatches(current, code) then
				solvedFlag = true
				ctx.onSolved()
			end
		end)
	end
	return {
		kind = "Colors",
		title = "OVERRIDE CODE",
		label = "Match the override code",
		focus = ringCFrame(
			ctx.origin,
			tier.info.hatchAngle + 160 + ((#code + 1) / 2 - 2) * 22,
			Config.Shaft.Radius - 2,
			tier.info.floorY + 2
		).Position,
		update = function() end,
		progress = function()
			local right = 0
			for i, v in current do
				if v == code[i] then
					right += 1
				end
			end
			return right, #code
		end,
		solved = function()
			return solvedFlag
		end,
		cleanup = function()
			folder:Destroy()
		end,
	}
end

-- Fuse Run: carry fuses from the shelf up to the socket on the landing.
local function fuses(tier: MapService.TierParts, ctx: Context): Puzzle
	local count = PuzzleRules.fuseCount(ctx.playerCount)
	local folder = Instance.new("Folder")
	folder.Name = "Fuses"
	folder.Parent = tier.folder
	local shelfCf = ringCFrame(ctx.origin, tier.info.hatchAngle + 70, Config.Shaft.Radius - 3, tier.info.floorY + 1.5)
	part({ Size = Vector3.new(8, 3, 3), CFrame = shelfCf, Color = DARK }, folder)
	local socketCf = tier.landing.CFrame * CFrame.new(0, tier.landing.Size.Y / 2 + 1.5, tier.landing.Size.Z / 2 - 1)
	local socket = part({ Size = Vector3.new(3, 3, 1.4), CFrame = socketCf, Color = DARK }, folder)
	local inserted = 0
	local carrying: { [Player]: BasePart } = {}
	local fuseParts: { BasePart } = {}
	local function shelfSpot(i: number): CFrame
		return shelfCf * CFrame.new((i - (count + 1) / 2) * 2.2, 2.4, 0)
	end
	local function drop(player: Player)
		local fuse = carrying[player]
		if not fuse then
			return
		end
		carrying[player] = nil
		local weld = fuse:FindFirstChildOfClass("WeldConstraint")
		if weld then
			weld:Destroy()
		end
		local idx = table.find(fuseParts, fuse) or 1
		fuse.Anchored = true
		fuse.CFrame = shelfSpot(idx)
		local p = fuse:FindFirstChildOfClass("ProximityPrompt")
		if p then
			p.Enabled = true
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
		end
	end
	for i = 1, count do
		local fuseMesh = LabKit.prop("Fuse", shelfSpot(i) * CFrame.new(0, -1.2, 0), 2.4, folder)
		local fuse: BasePart = fuseMesh
			or part({
				Name = "Fuse",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(2, 1.2, 1.2),
				CFrame = shelfSpot(i) * CFrame.Angles(0, 0, math.rad(90)),
				Color = COLORS.Green,
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, folder)
		table.insert(fuseParts, fuse)
		local p = prompt(fuse, "Pick up", "Fuse", 0.3)
		p.Triggered:Connect(function(player)
			if not ctx.isClimber(player) or carrying[player] or not p.Enabled then
				return
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid then
				return
			end
			p.Enabled = false
			carrying[player] = fuse
			fuse.Anchored = false
			fuse.Massless = true
			fuse.CFrame = root.CFrame * CFrame.new(0, 0.5, 1.2) * CFrame.Angles(0, 0, math.rad(90))
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = fuse
			weld.Parent = fuse
			humanoid.WalkSpeed = Config.Puzzles.FuseWalkSpeed
			humanoid.Died:Once(function()
				drop(player)
			end)
			ctx.onProgress("Valve", fuse.Position)
		end)
	end
	local socketPrompt = prompt(socket, "Insert fuse", "Fuse socket", 0.5)
	socketPrompt.Triggered:Connect(function(player)
		local fuse = carrying[player]
		if not fuse or not ctx.isClimber(player) then
			return
		end
		carrying[player] = nil
		local weld = fuse:FindFirstChildOfClass("WeldConstraint")
		if weld then
			weld:Destroy()
		end
		fuse.Anchored = true
		fuse.CFrame = socketCf
			* CFrame.new((inserted - (count - 1) / 2) * 0.9, 0, -0.8)
			* CFrame.Angles(0, 0, math.rad(90))
		inserted += 1
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
		end
		ctx.onProgress("Valve", socket.Position)
		if inserted >= count then
			socketPrompt.Enabled = false
			socket.Color = COLORS.Green
			socket.Material = Enum.Material.Neon
			ctx.onSolved()
		end
	end)
	return {
		kind = "Fuses",
		title = "FUSE RUN",
		label = "Carry the fuses to the socket",
		focus = shelfCf.Position,
		update = function()
			for player in carrying do
				if not ctx.isClimber(player) then
					drop(player)
				end
			end
		end,
		progress = function()
			return inserted, count
		end,
		solved = function()
			return inserted >= count
		end,
		cleanup = function()
			for player in carrying do
				drop(player)
			end
			folder:Destroy()
		end,
	}
end

local function miniGame(kind: string): (MapService.TierParts, Context) -> Puzzle
	return function(tier: MapService.TierParts, ctx: Context): Puzzle
		return MiniGames.create(kind, tier, {
			origin = ctx.origin,
			playerCount = ctx.playerCount,
			seed = ctx.seed + tier.info.index * 31,
			isClimber = ctx.isClimber,
			onSolved = ctx.onSolved,
			onProgress = ctx.onProgress,
		})
	end
end

local BUILDERS: { [string]: (MapService.TierParts, Context) -> Puzzle } = {
	Valves = valves,
	Plates = plates,
	Colors = colors,
	Fuses = fuses,
	Pipes = miniGame("Pipes"),
	Wires = miniGame("Wires"),
	Memory = miniGame("Memory"),
}

function PuzzleService.create(tier: MapService.TierParts, ctx: Context): Puzzle
	local builder = BUILDERS[tier.info.puzzle] or valves
	return builder(tier, ctx)
end

return PuzzleService
