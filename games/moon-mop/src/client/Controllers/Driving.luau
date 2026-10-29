--!strict
-- Driving a vehicle round the Moon. The server welds you into the seat and hands the vehicle's
-- physics to this client; here the vehicle glides over the ground along the sphere: throttle
-- and steering, a turbo, hops off crater rims, spins and flips in the air (reported to the
-- server, which pays for them), a chase camera and the km/h readout.
-- Keys: W/S drive, A/D steer, Shift turbo, Space hop / flip in the air, F get out,
-- G dump the tank, Z suction dial, L headlights. Touch gets buttons.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Hud = require(script.Parent.Hud)
local Juice = require(script.Parent.Juice)
local Movement = require(script.Parent.Movement)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Driving = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local CENTRE = Config.Moon.Centre
local GRAVITY = Config.Moon.Gravity
local intent = Remotes.get("VehicleIntent")
local report = Remotes.get("VehicleReport")

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { Workspace.Terrain }

local function down(a: Enum.KeyCode, b: Enum.KeyCode?): boolean
	return UserInputService:IsKeyDown(a) or (b ~= nil and UserInputService:IsKeyDown(b))
end

type Sim = {
	model: Model,
	body: BasePart,
	def: Config.VehicleDef,
	look: Vector3,
	speed: number,
	alt: number, -- height of the body above its rest height
	vy: number,
	air: number,
	spin: number,
	flips: number,
	flipT: number,
	camLook: Vector3,
}

local sim: Sim? = nil
local touchThrottle, touchSteer, touchTurbo = 0, 0, false

local function groundAt(pos: Vector3, up: Vector3): (Vector3?, Vector3?)
	local hit = Workspace:Raycast(pos + up * 30, -up * 90, groundParams)
	if hit then
		return hit.Position, hit.Normal
	end
	return nil, nil
end

local function stats(): Loadout.VehicleStats?
	local s = State.get()
	local cur = sim
	if not cur then
		return nil
	end
	local ups = s.vehicles and s.vehicles[cur.def.id]
	return Loadout.vehicleStats(cur.def, ups, s.fx, s.dial)
end

local function finishAir(cur: Sim)
	local spins = math.floor(math.abs(cur.spin) / (2 * math.pi) + 0.15)
	if cur.air >= Config.Stunts.MinAirTime and (spins > 0 or cur.flips > 0 or cur.air > 1.2) then
		report:FireServer(math.min(cur.flips, 3), math.min(spins, 6), math.min(cur.air, 8))
	end
	cur.air, cur.spin, cur.flips, cur.flipT = 0, 0, 0, 0
end

local function step(dt: number)
	local cur = sim
	if not cur or not cur.model.Parent then
		return
	end
	local st = stats()
	if not st then
		return
	end
	local body = cur.body
	local pos = body.Position
	local up = (pos - CENTRE).Unit
	-- input
	local throttle, steer = 0, 0
	if not UserInputService:GetFocusedTextBox() and not Hud.isMenuOpen() then
		if down(Enum.KeyCode.W, Enum.KeyCode.Up) then
			throttle += 1
		end
		if down(Enum.KeyCode.S, Enum.KeyCode.Down) then
			throttle -= 1
		end
		if down(Enum.KeyCode.A, Enum.KeyCode.Left) then
			steer -= 1
		end
		if down(Enum.KeyCode.D, Enum.KeyCode.Right) then
			steer += 1
		end
		for _, g in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
			if g.KeyCode == Enum.KeyCode.Thumbstick1 and g.Position.Magnitude > 0.2 then
				steer += g.Position.X
			elseif g.KeyCode == Enum.KeyCode.ButtonR2 then
				throttle += g.Position.Z
			elseif g.KeyCode == Enum.KeyCode.ButtonL2 then
				throttle -= g.Position.Z
			end
		end
		throttle += touchThrottle
		steer += touchSteer
	end
	throttle = math.clamp(throttle, -1, 1)
	steer = math.clamp(steer, -1, 1)
	local turbo = touchTurbo or down(Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR1)
	local top = st.speed * (if turbo and throttle > 0 then st.turbo else 1)
	local target = throttle * (if throttle < 0 then top * 0.5 else top)
	local accel = st.accel * (if cur.alt > 0.6 then 0.2 else 1)
	cur.speed += math.clamp(target - cur.speed, -accel * dt * 1.6, accel * dt)
	-- steering: turn rate grows with speed, flips when reversing
	local rate = st.turn * steer * math.clamp(math.abs(cur.speed) / 8, 0.25, 1) * (if cur.speed < -0.5 then -1 else 1)
	local airborne = cur.alt > 0.6
	if airborne then
		rate = st.turn * steer * 1.6
		cur.spin += rate * dt
	end
	local look = (cur.look - up * cur.look:Dot(up)).Unit
	look = CFrame.fromAxisAngle(up, -rate * dt):VectorToWorldSpace(look)
	-- move along the surface
	local nextPos = pos + look * cur.speed * dt
	local nextUp = (nextPos - CENTRE).Unit
	look = (look - nextUp * look:Dot(nextUp)).Unit
	local rest = cur.def.size.Y * 0.45 + 0.5
	local ground, normal = groundAt(nextPos, nextUp)
	local function heightAt(p: Vector3): number
		return if ground then (p - ground):Dot(nextUp) - rest else 0
	end
	local height = heightAt(nextPos)
	if cur.vy ~= 0 or height > 0.6 then
		-- in the air: fall under the Moon's gravity until the ground comes up
		cur.vy -= GRAVITY * dt
		nextPos += nextUp * cur.vy * dt
		height = heightAt(nextPos)
		if height <= 0 and cur.vy <= 0 then
			if ground then
				nextPos = ground + nextUp * rest
			end
			if cur.air > 0.2 then
				finishAir(cur)
				Juice.shakeCamera(0.12)
			end
			cur.vy = 0
			height = 0
		end
	elseif ground then
		-- on the ground: follow it
		nextPos = ground + nextUp * rest
		height = 0
	end
	cur.alt = math.max(0, height)
	if cur.alt > 0.6 then
		cur.air += dt
	end
	cur.look = look
	-- tilt to the ground under the wheels
	local tiltUp = nextUp
	if normal and cur.alt < 1 then
		tiltUp = (nextUp + (normal - nextUp) * 0.6).Unit
	end
	local right = look:Cross(tiltUp).Unit
	local fwd = tiltUp:Cross(right).Unit
	local cf = CFrame.fromMatrix(nextPos, right, tiltUp, -fwd)
	if cur.flipT > 0 then
		local f = 1 - cur.flipT / 0.7
		cf *= CFrame.Angles(-f * 2 * math.pi, 0, 0)
		cur.flipT = math.max(0, cur.flipT - dt)
		if cur.flipT == 0 then
			cur.flips += 1
		end
	end
	cur.model:PivotTo(cf)
	body.AssemblyLinearVelocity = fwd * cur.speed + nextUp * cur.vy
	body.AssemblyAngularVelocity = Vector3.zero
	-- brush dust
	local roller = cur.model:FindFirstChild("Roller")
	local dust = roller and roller:FindFirstChild("Dust") :: ParticleEmitter?
	if dust then
		dust.Rate = if math.abs(cur.speed) > 2 and cur.alt < 0.5 and cur.def.cleans then 40 else 0
	end
	-- HUD
	Hud.vehicleSpeed.Text = string.format("%d", math.floor(math.abs(cur.speed) * 0.28 * 3.6 + 0.5))
end

local function chase(dt: number): CFrame?
	local cur = sim
	if not cur then
		return nil
	end
	local pos = cur.body.Position
	local up = (pos - CENTRE).Unit
	local k = 1 - math.exp(-dt * 4)
	cur.camLook = (cur.camLook + (cur.look - cur.camLook) * k).Unit
	local size = cur.def.size
	local back = math.max(14, size.Z * 1.3)
	local height = math.max(6, size.Y * 1.1)
	local eye = pos - cur.camLook * back + up * height
	local shake = if GuiService.ReducedMotionEnabled
		then Vector3.zero
		else up * math.sin(os.clock() * 30) * 0.02 * math.abs(cur.speed) / 10
	return CFrame.lookAt(eye + shake, pos + up * 2 + cur.camLook * 6, up)
end

local function start(model: Model)
	local body = model.PrimaryPart
	local id = model:GetAttribute("Vehicle") :: string?
	local def = id and Loadout.vehicle(id)
	if not body or not def then
		return
	end
	sim = {
		model = model,
		body = body,
		def = def,
		look = body.CFrame.LookVector,
		speed = 0,
		alt = 0,
		vy = 0,
		air = 0,
		spin = 0,
		flips = 0,
		flipT = 0,
		camLook = body.CFrame.LookVector,
	}
	Movement.setDriving(true)
	Movement.setCameraOverride(chase)
	RunService:BindToRenderStep("MoonDrive", Enum.RenderPriority.Input.Value + 1, step)
end

local function stop()
	if not sim then
		return
	end
	sim = nil
	RunService:UnbindFromRenderStep("MoonDrive")
	Movement.setDriving(false)
	Movement.setCameraOverride(nil)
end

-- Find the vehicle the server seated us in.
local function watch()
	local folder = Workspace:WaitForChild("Vehicles")
	local function check()
		local mine: Model? = nil
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:GetAttribute("Driver") == player.UserId then
				mine = m
			end
		end
		if mine and (not sim or sim.model ~= mine) then
			stop()
			start(mine)
		elseif not mine and sim then
			stop()
		end
	end
	folder.ChildAdded:Connect(function(m)
		m:GetAttributeChangedSignal("Driver"):Connect(check)
		task.defer(check)
	end)
	folder.ChildRemoved:Connect(check)
	for _, m in folder:GetChildren() do
		m:GetAttributeChangedSignal("Driver"):Connect(check)
	end
	check()
end

-- Headlight beams and beacon blink for every vehicle (all clients).
local function lights()
	local folder = Workspace:WaitForChild("Vehicles")
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		for _, m in folder:GetChildren() do
			local on = m:GetAttribute("Lights") == true
			for _, d in m:GetDescendants() do
				if d:IsA("SpotLight") and d.Name == "Beam" then
					d.Enabled = on
				elseif d:IsA("BasePart") and d:GetAttribute("Blink") then
					d.Transparency = if (t * 2) % 1 < 0.5 then 0 else 0.7
				end
			end
		end
	end)
end

local function touchControls()
	local gui = Theme.screen("DriveControls", player:WaitForChild("PlayerGui"), 3)
	gui.Enabled = false
	local pad = Theme.frame(UDim2.fromOffset(240, 120), UDim2.new(0, 16, 1, -140), Theme.SLATE, 1)
	pad.Parent = gui
	local function hold(text: string, pos: UDim2, size: UDim2, on: () -> (), off: () -> ())
		local b = Theme.button(text, size, "Dark")
		b.Position = pos
		b.Parent = pad
		b.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then
				on()
			end
		end)
		b.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then
				off()
			end
		end)
		return b
	end
	hold("◀", UDim2.fromOffset(0, 50), UDim2.fromOffset(70, 70), function()
		touchSteer = -1
	end, function()
		touchSteer = 0
	end)
	hold("▶", UDim2.fromOffset(80, 50), UDim2.fromOffset(70, 70), function()
		touchSteer = 1
	end, function()
		touchSteer = 0
	end)
	local right = Theme.frame(UDim2.fromOffset(200, 220), UDim2.new(1, -16, 1, -240), Theme.SLATE, 1)
	right.AnchorPoint = Vector2.new(1, 0)
	right.Parent = gui
	local function rbtn(text: string, y: number, style: Theme.ButtonStyle?): TextButton
		local b = Theme.button(text, UDim2.fromOffset(96, 56), style or "Dark")
		b.Position = UDim2.fromOffset(104, y)
		b.Parent = right
		return b
	end
	local gas = rbtn("GO", 160, "Orange")
	gas.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			touchThrottle = 1
		end
	end)
	gas.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			touchThrottle = 0
		end
	end)
	local rev = Theme.button("BACK", UDim2.fromOffset(96, 56), "Dark")
	rev.Position = UDim2.fromOffset(0, 160)
	rev.Parent = right
	rev.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			touchThrottle = -1
		end
	end)
	rev.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			touchThrottle = 0
		end
	end)
	local boost = rbtn("TURBO", 96)
	boost.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			touchTurbo = true
		end
	end)
	boost.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			touchTurbo = false
		end
	end)
	rbtn("DUMP", 32).Activated:Connect(function()
		intent:FireServer("dump")
	end)
	local exit = Theme.button("EXIT", UDim2.fromOffset(96, 56), "Red")
	exit.Position = UDim2.fromOffset(0, 32)
	exit.Parent = right
	exit.Activated:Connect(function()
		intent:FireServer("exit")
	end)
	local hop = Theme.button("HOP", UDim2.fromOffset(96, 56), "Dark")
	hop.Position = UDim2.fromOffset(0, 96)
	hop.Parent = right
	hop.Activated:Connect(function()
		Driving.hop()
	end)
	RunService.Heartbeat:Connect(function()
		gui.Enabled = sim ~= nil
	end)
end

function Driving.hop()
	local cur = sim
	if not cur then
		return
	end
	if cur.alt < 0.3 then
		cur.vy = 18
		cur.alt = 0.7
	elseif cur.flipT == 0 and cur.alt > 2 then
		cur.flipT = 0.7
	end
end

function Driving.start()
	task.spawn(watch)
	task.spawn(lights)
	if Hud.touch then
		touchControls()
	end
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		local key = input.KeyCode
		if sim then
			if key == Enum.KeyCode.F or key == Enum.KeyCode.ButtonY then
				intent:FireServer("exit")
			elseif key == Enum.KeyCode.G or key == Enum.KeyCode.ButtonX then
				intent:FireServer("dump")
			elseif key == Enum.KeyCode.Space or key == Enum.KeyCode.ButtonA then
				Driving.hop()
			elseif key == Enum.KeyCode.L then
				intent:FireServer("lights")
			elseif key == Enum.KeyCode.Z then
				local s = State.get()
				local ups = s.vehicles and sim and s.vehicles[sim.def.id]
				local max = if ups then ups.SuctionDial or 0 else 0
				if max > 0 then
					intent:FireServer("dial", ((s.dial or 0) + 1) % (max + 1))
				end
			end
		elseif key == Enum.KeyCode.F then
			intent:FireServer("enter")
		end
	end)
	State.onFeedback(function(kind: string, data: any)
		if kind == "Stunt" then
			local bits = {}
			if data.flips > 0 then
				table.insert(bits, string.format("%dx FLIP", data.flips))
			end
			if data.spins > 0 then
				table.insert(bits, string.format("%dx SPIN", data.spins))
			end
			table.insert(bits, string.format("%.1fs AIR", data.air))
			State.emit(
				"Toast",
				{ text = table.concat(bits, "  ·  ") .. "  +" .. Theme.money(data.amount), color = Theme.YELLOW }
			)
		end
	end)
end

return Driving
