--!strict
-- The real fruit models on every client (2026-11-20). The preview meshes in
-- Shared/FruitMeshes are built here with EditableMesh + CreateMeshPartAsync:
-- a MeshPart made this way in Studio does not replicate, so each client
-- builds its own copy. One template per fruit is cached and cloned.
-- APIs: AssetService:CreateEditableMesh, EditableMesh:AddVertex/AddTriangle/
-- AddColor/SetFaceColors, AssetService:CreateMeshPartAsync(Content.fromObject)
-- https://create.roblox.com/docs/reference/engine/classes/EditableMesh
-- When the shipped FBX gets an uploaded MeshId this module is the one place
-- to switch over.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FruitMeshData = require(Shared:WaitForChild("FruitMeshData"))

local FruitMesh = {}

local GLOW_THRESHOLD = 0.25 -- glow-mask average that counts as a crevice
local SHELL_PUSH = 1.03 -- the glow shell sits just outside the body

local templates: { [string]: Model | false } = {}

local function glowOf(key: string): Color3
	for _, f in Config.Fruits do
		if f.key == key then
			return Color3.fromRGB(f.glow[1], f.glow[2], f.glow[3])
		end
	end
	return Color3.new(1, 1, 1)
end

local function meshPart(mesh: FruitMeshData.Mesh, tris: { { number } }, scale: number, colored: boolean): MeshPart?
	local ok, result = pcall(function()
		local em = AssetService:CreateEditableMesh()
		local ids: { [number]: number } = {}
		local colors: { [number]: number } = {}
		local function vertex(i: number): number
			local known = ids[i]
			if known then
				return known
			end
			local v = mesh.verts[i]
			local id = em:AddVertex(Vector3.new(v.x, v.y, v.z) * scale)
			ids[i] = id
			if colored then
				colors[i] = em:AddColor(Color3.new(v.r, v.g, v.b), 1)
			end
			return id
		end
		for _, tri in tris do
			local face = em:AddTriangle(vertex(tri[1]), vertex(tri[2]), vertex(tri[3]))
			if colored then
				em:SetFaceColors(face, { colors[tri[1]], colors[tri[2]], colors[tri[3]] })
			end
		end
		return AssetService:CreateMeshPartAsync(Content.fromObject(em))
	end)
	if ok and result and result:IsA("MeshPart") then
		return result
	end
	warn("[FruitMesh] could not build mesh:", result)
	return nil
end

-- Builds (once) and returns a fresh clone of the fruit: a Model whose
-- PrimaryPart "Body" is the vertex-coloured fruit and "GlowShell" a Neon copy
-- of its crevices, welded. `nil` if the key is unknown or building failed.
function FruitMesh.get(key: string): Model?
	local cached = templates[key]
	if cached == nil then
		templates[key] = false
		local folder = Shared:FindFirstChild("FruitMeshes")
		local source = folder and folder:FindFirstChild(key)
		if source and source:IsA("ModuleScript") then
			local data = (require :: any)(source) :: { v: string, t: string }
			local mesh = FruitMeshData.parse(data.v, data.t)
			local body = meshPart(mesh, mesh.tris, 1, true)
			if body then
				local model = Instance.new("Model")
				model.Name = key
				body.Name = "Body"
				body.Material = Enum.Material.SmoothPlastic
				body.Color = Color3.new(1, 1, 1) -- vertex colours carry the paint
				body.CastShadow = true
				body.Parent = model
				model.PrimaryPart = body
				local shell = meshPart(mesh, FruitMeshData.glowTris(mesh, GLOW_THRESHOLD), SHELL_PUSH, false)
				if shell then
					shell.Name = "GlowShell"
					shell.Material = Enum.Material.Neon
					shell.Color = glowOf(key)
					shell.CastShadow = false
					-- CreateMeshPartAsync keeps the mesh origin, so the shell
					-- shares the body's CFrame (dock thread finding).
					shell.CFrame = body.CFrame
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = body
					weld.Part1 = shell
					weld.Parent = shell
					shell.Parent = model
				end
				for _, p in model:GetDescendants() do
					if p:IsA("BasePart") then
						p.Anchored = p == body
						p.CanCollide = false
						p.CanQuery = false
						p.CanTouch = false
						p.Massless = true
					end
				end
				templates[key] = model
				cached = model
			end
		end
	end
	if typeof(cached) == "Instance" and cached:IsA("Model") then
		return cached:Clone()
	end
	return nil
end

-- The glow colour for a fruit key (Config.Fruits), for lights and effects.
FruitMesh.glow = glowOf

return FruitMesh
