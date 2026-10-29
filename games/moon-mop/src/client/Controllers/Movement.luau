--!strict
-- Walking all the way round the round Moon, plus the camera. Promoted from the map prototype
-- (tools/studio/MoonGravity.client.luau).
--
-- How it works (APIs checked against create.roblox.com/docs):
-- * workspace.Gravity is 0; a VectorForce pulls the character toward the Moon's centre.
-- * Humanoid.EvaluateStateMachine = false hands movement to a ControllerManager whose UpDirection
--   is the radial up every frame. The ground sensor is Manual: we raycast toward the centre.
-- * The camera is Scriptable and carries its own up vector, parallel-transported as you walk, so
--   the horizon stays level anywhere on the sphere. Third person by default, V for first person.
-- * The default Animate script listens to Humanoid states, which no longer run, so it is
--   disabled and its idle / walk / jump / fall animations are played from here.
-- * Speeds come from the server (character attributes WalkSpeed / JumpSpeed).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Movement = {}

local CENTRE = Config.Moon.Centre
local GRAVITY = Config.Moon.Gravity
local CAM_DIST = 14
local CAM_MIN, CAM_MAX = 0.5, 60
local PITCH_MIN, PITCH_MAX = math.rad(-75), math.rad(60)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local function rotationBetween(a: Vector3, b: Vector3): CFrame
	local axis = a:Cross(b)
	if axis.Magnitude < 1e-6 then
		return CFrame.identity
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(a:Dot(b), -1, 1)))
end

local function flatten(v: Vector3, up: Vector3): Vector3
	return v - up * v:Dot(up)
end

-- Camera state survives respawns.
local frame = CFrame.identity -- orientation only; UpVector is the local up
local yaw, pitch, zoom = 0, math.rad(-15), CAM_DIST
local dragging = false
local firstPerson = false
local brushing = false

-- Something else (a cutscene, a vehicle chase camera, the map) can take the camera.
export type CameraOverride = (dt: number) -> CFrame?
local override: CameraOverride? = nil
-- While driving, the vehicle controller owns the character.
local driving = false
local jetpackHeld = false
Movement.fuel = 1

function Movement.setCameraOverride(fn: CameraOverride?)
	override = fn
end

function Movement.setDriving(on: boolean)
	driving = on
end

function Movement.setBrushing(on: boolean)
	brushing = on
end

function Movement.toggleFirstPerson()
	firstPerson = not firstPerson
	zoom = if firstPerson then CAM_MIN else CAM_DIST
end

function Movement.isFirstPerson(): boolean
	return firstPerson
end

-- The camera's frame: up is the local up, look is where the player faces the view.
function Movement.viewFrame(): CFrame
	return frame * CFrame.Angles(0, yaw, 0)
end

function Movement.yawDelta(d: number)
	yaw += d
end

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		dragging = true
	elseif input.KeyCode == Enum.KeyCode.V then
		Movement.toggleFirstPerson()
	elseif input.KeyCode == Enum.KeyCode.Space then
		jetpackHeld = true
	end
end)
UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		dragging = false
	elseif input.KeyCode == Enum.KeyCode.Space then
		jetpackHeld = false
	end
end)
UserInputService.InputChanged:Connect(function(input: InputObject, processed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
		zoom = math.clamp(zoom * (1 - input.Position.Z * 0.12), CAM_MIN, CAM_MAX)
		firstPerson = zoom < 1
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		if dragging or zoom < 1 then
			yaw -= input.Delta.X * 0.004
			pitch = math.clamp(pitch - input.Delta.Y * 0.004, PITCH_MIN, PITCH_MAX)
		end
	end
end)
-- Touch: drags that the thumbstick or buttons did not claim turn the camera.
UserInputService.TouchMoved:Connect(function(touch: InputObject, processed: boolean)
	if processed then
		return
	end
	yaw -= touch.Delta.X * 0.006
	pitch = math.clamp(pitch - touch.Delta.Y * 0.006, PITCH_MIN, PITCH_MAX)
end)

function Movement.setJetpackHeld(on: boolean)
	jetpackHeld = on
end

local function setup(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	local animate = character:WaitForChild("Animate", 5)
	local animator = humanoid:WaitForChild("Animator") :: Animator
	local tracks: { [string]: AnimationTrack } = {}
	if animate and animate:IsA("LocalScript") then
		animate.Enabled = false
		for _, name in { "idle", "walk", "run", "jump", "fall" } do
			local holder = animate:FindFirstChild(name)
			local anim = holder and holder:FindFirstChildWhichIsA("Animation")
			if anim then
				tracks[name] = animator:LoadAnimation(anim)
			end
		end
		for _, t in animator:GetPlayingAnimationTracks() do
			t:Stop(0)
		end
	end
	local current: string? = nil
	local function play(name: string, speed: number?)
		local t = tracks[name]
		if current ~= name then
			if current and tracks[current] then
				tracks[current]:Stop(0.2)
			end
			current = name
			if t then
				t:Play(0.2)
			end
		end
		if t and speed then
			t:AdjustSpeed(speed)
		end
	end

	humanoid.EvaluateStateMachine = false

	local cm = Instance.new("ControllerManager")
	cm.RootPart = root
	cm.BaseMoveSpeed = Config.Moon.WalkSpeed
	cm.BaseTurnSpeed = 8
	local ground = Instance.new("GroundController")
	ground.GroundOffset = humanoid.HipHeight
	ground.Friction = 2
	ground.Parent = cm
	local air = Instance.new("AirController")
	air.MoveMaxForce = 600
	air.Parent = cm
	local sensor = Instance.new("ControllerPartSensor")
	sensor.Name = "GroundSensor"
	sensor.SensorMode = Enum.SensorMode.Floor
	sensor.UpdateType = Enum.SensorUpdateType.Manual
	sensor.SearchDistance = humanoid.HipHeight + 3
	sensor.Parent = root
	cm.GroundSensor = sensor
	cm.ActiveController = air
	cm.Parent = character

	local att = Instance.new("Attachment")
	att.Name = "MoonGravityAttachment"
	att.Parent = root
	local pull = Instance.new("VectorForce")
	pull.Attachment0 = att
	pull.RelativeTo = Enum.ActuatorRelativeTo.World
	pull.ApplyAtCenterOfMass = true
	pull.Parent = root

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	-- Move input in camera space (x right, z back). This place has no PlayerModule, so keys and
	-- gamepad are read directly; touch falls back to undoing the camera-relative MoveDirection.
	local function moveInput(): Vector3
		local x, z = 0, 0
		if UserInputService:GetFocusedTextBox() then
			return Vector3.zero
		end
		local function down(a: Enum.KeyCode, b: Enum.KeyCode): boolean
			return UserInputService:IsKeyDown(a) or UserInputService:IsKeyDown(b)
		end
		if down(Enum.KeyCode.W, Enum.KeyCode.Up) then
			z -= 1
		end
		if down(Enum.KeyCode.S, Enum.KeyCode.Down) then
			z += 1
		end
		if down(Enum.KeyCode.A, Enum.KeyCode.Left) then
			x -= 1
		end
		if down(Enum.KeyCode.D, Enum.KeyCode.Right) then
			x += 1
		end
		for _, st in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
			if st.KeyCode == Enum.KeyCode.Thumbstick1 and st.Position.Magnitude > 0.2 then
				x += st.Position.X
				z -= st.Position.Y
			end
		end
		if x ~= 0 or z ~= 0 then
			return Vector3.new(x, 0, z)
		end
		local m = humanoid.MoveDirection
		if m.Magnitude < 0.01 then
			return Vector3.zero
		end
		local rf = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
		local lf = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		local det = rf.X * lf.Z - rf.Z * lf.X
		if math.abs(det) < 0.05 then
			return Vector3.zero
		end
		local a = (m.X * lf.Z - m.Z * lf.X) / det
		local b = (rf.X * m.Z - rf.Z * m.X) / det
		return Vector3.new(a, 0, -b)
	end

	local jumpQueued = false
	local jumpConn = UserInputService.JumpRequest:Connect(function()
		jumpQueued = true
	end)

	frame = rotationBetween(Vector3.yAxis, (root.Position - CENTRE).Unit)
	local reach = humanoid.HipHeight + root.Size.Y / 2

	local physConn = RunService.PreSimulation:Connect(function(dt: number)
		local up = (root.Position - CENTRE).Unit
		if driving then
			cm.Parent = nil
			pull.Enabled = false
			play("idle")
			return
		end
		if cm.Parent ~= character then
			cm.Parent = character
			pull.Enabled = true
		end
		local walk = (character:GetAttribute("WalkSpeed") :: number?) or Config.Moon.WalkSpeed
		local jumpSpeed = (character:GetAttribute("JumpSpeed") :: number?) or Config.Moon.JumpSpeed
		cm.BaseMoveSpeed = walk * (if brushing then Config.Moon.BrushSpeedFactor else 1)
		cm.UpDirection = up
		local force = -up * root.AssemblyMass * GRAVITY

		local hit = Workspace:Raycast(root.Position, -up * (reach + 1.2), rayParams)
		local grounded = hit ~= nil and (root.Position - hit.Position):Dot(up) <= reach + 0.8
		if hit and grounded then
			sensor.SensedPart = hit.Instance
			sensor.HitNormal = hit.Normal
			sensor.HitFrame = CFrame.new(hit.Position)
			Movement.fuel = math.min(1, Movement.fuel + dt * Config.Gear.Jetpack.refill)
		else
			sensor.SensedPart = nil
		end

		-- Jetpack: hold jump in the air.
		if not grounded and jetpackHeld and character:GetAttribute("Jetpack") and Movement.fuel > 0 then
			force += up * root.AssemblyMass * Config.Gear.Jetpack.thrust
			local fuelMax = Config.Gear.Jetpack.fuel
				* (1 + ((character:GetAttribute("JetpackFuelPct") :: number?) or 0) / 100)
			Movement.fuel = math.max(0, Movement.fuel - dt / fuelMax)
		end
		pull.Force = force

		local move = Vector3.zero
		local mv = moveInput()
		if mv.Magnitude > 0.01 then
			local look = frame * CFrame.Angles(0, yaw, 0)
			local fwd = flatten(look.LookVector, up)
			local right = flatten(look.RightVector, up)
			if fwd.Magnitude > 1e-3 and right.Magnitude > 1e-3 then
				move = right.Unit * mv.X - fwd.Unit * mv.Z
				if move.Magnitude > 1 then
					move = move.Unit
				end
			end
		end
		cm.MovingDirection = move
		if move.Magnitude > 0.05 then
			cm.FacingDirection = move.Unit
		elseif firstPerson then
			local f = flatten((frame * CFrame.Angles(0, yaw, 0)).LookVector, up)
			if f.Magnitude > 1e-3 then
				cm.FacingDirection = f.Unit
			end
		end

		if jumpQueued and grounded then
			cm.ActiveController = air
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = flatten(v, up) + up * jumpSpeed
		elseif grounded and root.AssemblyLinearVelocity:Dot(up) < 1 then
			cm.ActiveController = ground
		elseif not grounded then
			cm.ActiveController = air
		end
		jumpQueued = false

		local vel = root.AssemblyLinearVelocity
		local speed = flatten(vel, up).Magnitude
		if not grounded then
			play(if vel:Dot(up) > 2 then "jump" else "fall")
		elseif speed > 0.5 then
			play("walk", speed / 14.5)
		else
			play("idle")
		end
	end)

	RunService:BindToRenderStep("MoonCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local up = (root.Position - CENTRE).Unit
		frame = rotationBetween(frame.UpVector, up) * frame
		camera.CameraType = Enum.CameraType.Scriptable
		local custom = override and override(dt)
		if custom then
			camera.CFrame = custom
			return
		end
		local view = frame * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local focus = root.Position + up * 1.5
		local dist = if firstPerson then 0.5 else zoom
		local back = -view.LookVector
		local block = Workspace:Raycast(focus, back * dist, rayParams)
		if block then
			dist = math.max(0.5, (block.Position - focus).Magnitude - 0.5)
		end
		camera.CFrame = CFrame.lookAt(focus + back * dist, focus, view.UpVector)
		local fp = dist < 1.2
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") and d ~= root then
				d.LocalTransparencyModifier = if fp and not d:GetAttribute("ShowInFirstPerson") then 1 else 0
			end
		end
		UserInputService.MouseBehavior = if fp then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	end)

	local function cleanup()
		physConn:Disconnect()
		jumpConn:Disconnect()
		RunService:UnbindFromRenderStep("MoonCamera")
	end
	humanoid.Died:Once(cleanup)
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cleanup()
		end
	end)
end

function Movement.start()
	if player.Character then
		task.spawn(setup, player.Character)
	end
	player.CharacterAdded:Connect(setup)
end

return Movement
