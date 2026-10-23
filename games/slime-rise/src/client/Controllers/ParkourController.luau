--!strict
-- Client-side lab gear: slime bounce pads launch you, fan updrafts lift you,
-- fan blades spin. The character is client-owned, so these run here for
-- instant feel; the server only builds and tags the gear.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AmbienceController = require(script.Parent.AmbienceController)

local ParkourController = {}

local player = Players.LocalPlayer
local UPDRAFT_SPEED = 30
local lastBounce = 0

local function inside(part: BasePart, point: Vector3, pad: number): boolean
	local p = part.CFrame:PointToObjectSpace(point)
	local h = part.Size / 2
	return math.abs(p.X) <= h.X + pad and math.abs(p.Z) <= h.Z + pad and p.Y >= -h.Y - pad and p.Y <= h.Y + pad
end

function ParkourController.start()
	RunService.RenderStepped:Connect(function(dt: number)
		for _, blade in CollectionService:GetTagged("FanSpinY") do
			if blade:IsA("BasePart") then
				local pivot = blade:GetAttribute("Pivot")
				if typeof(pivot) == "Vector3" then
					local rot = CFrame.new(pivot) * CFrame.Angles(0, dt * 9, 0) * CFrame.new(-pivot)
					blade.CFrame = rot * blade.CFrame
				end
			end
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		local vel = root.AssemblyLinearVelocity
		local now = os.clock()
		-- Bounce pads: standing on (or landing on) the jelly launches you.
		if now - lastBounce > 0.4 then
			for _, pad in CollectionService:GetTagged("BouncePad") do
				if pad:IsA("BasePart") then
					local top = pad.Position.Y + pad.Size.Y / 2
					local feet = root.Position.Y - 3
					local flat = pad.CFrame:PointToObjectSpace(root.Position)
					if
						math.abs(flat.X) <= pad.Size.X / 2 + 0.5
						and math.abs(flat.Z) <= pad.Size.Z / 2 + 0.5
						and feet - top < 0.8
						and feet - top > -1
						and vel.Y <= 4
					then
						local launch = pad:GetAttribute("Launch")
						root.AssemblyLinearVelocity =
							Vector3.new(vel.X, if type(launch) == "number" then launch else 70, vel.Z)
						lastBounce = now
						AmbienceController.play("Grapple", 0.6, pad.Position)
						break
					end
				end
			end
		end
		-- Fan updrafts: rise while inside the column, until its top.
		for _, zone in CollectionService:GetTagged("Updraft") do
			if zone:IsA("BasePart") and inside(zone, root.Position, 0.5) then
				local topY = zone:GetAttribute("Top")
				if type(topY) == "number" and root.Position.Y < topY then
					root.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, UPDRAFT_SPEED), vel.Z)
				end
			end
		end
	end)
end

return ParkourController
