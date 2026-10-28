--!strict
-- Moon Mop: walk all the way round the round Moon.
-- Prototype for the map (lives in StarterPlayerScripts as a LocalScript); it moves to src/client
-- when the game itself is scaffolded from template/.
--
-- How it works (APIs checked against create.roblox.com/docs):
-- * workspace.Gravity is 0 in the place; this script pulls the character toward the Moon's centre
--   with a VectorForce, so "down" is always toward the centre.
-- * Humanoid.EvaluateStateMachine = false hands movement to a ControllerManager. Its UpDirection
--   is set to the radial up every frame (GroundController levitates and balances along it,
--   AirController aligns to it). The ground sensor is Manual: we raycast toward the centre and
--   write SensedPart / HitNormal / HitFrame ourselves.
-- * The camera is Scriptable and carries its own up vector, parallel-transported as you walk, so
--   the horizon stays level anywhere on the sphere.
-- * Animations: the default Animate script listens to Humanoid states, which no longer run, so it
--   is disabled and its idle / walk / run / jump / fall animations are played from here.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CENTRE = Vector3.new(0, -2000, 0) -- must match MoonMapData.Radius (centre is (0, -R, 0))
local GRAVITY = 50 -- studs/s^2, floaty Moon feel
local JUMP_SPEED = 28
local WALK_SPEED = 16
local CAM_DIST = 14
local CAM_MIN, CAM_MAX = 0.5, 40
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

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		dragging = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
		zoom = math.clamp(zoom * (1 - input.Position.Z * 0.12), CAM_MIN, CAM_MAX)
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		if dragging or zoom < 1 then
			yaw -= input.Delta.X * 0.004
			pitch = math.clamp(pitch - input.Delta.Y * 0.004, PITCH_MIN, PITCH_MAX)
		end
	end
end)
-- Touch: drags that the thumbstick or buttons did not claim turn the camera.
UserInputService.TouchMoved:Connect(function(touch, processed)
	if processed then
		return
	end
	yaw -= touch.Delta.X * 0.006
	pitch = math.clamp(pitch - touch.Delta.Y * 0.006, PITCH_MIN, PITCH_MAX)
end)

local function setup(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- animations from the default Animate script, played by us
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
	cm.BaseMoveSpeed = WALK_SPEED
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

	-- Move input in camera space (x right, z back), like ControlModule:GetMoveVector(). This place
	-- has no PlayerModule in PlayerScripts, so keys and gamepad are read directly; touch (and any
	-- other device) falls back to undoing the camera-relative Humanoid.MoveDirection Roblox sets.
	local function moveInput(): Vector3
		local x, z = 0, 0
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

	local physConn = RunService.PreSimulation:Connect(function()
		local up = (root.Position - CENTRE).Unit
		cm.UpDirection = up
		pull.Force = -up * root.AssemblyMass * GRAVITY

		local hit = Workspace:Raycast(root.Position, -up * (reach + 1.2), rayParams)
		local grounded = hit ~= nil and (root.Position - hit.Position):Dot(up) <= reach + 0.8
		if hit and grounded then
			sensor.SensedPart = hit.Instance
			sensor.HitNormal = hit.Normal
			sensor.HitFrame = CFrame.new(hit.Position)
		else
			sensor.SensedPart = nil
		end

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
		end

		if jumpQueued and grounded then
			cm.ActiveController = air
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = flatten(v, up) + up * JUMP_SPEED
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

	local camConn = RunService.RenderStepped:Connect(function()
		local up = (root.Position - CENTRE).Unit
		frame = rotationBetween(frame.UpVector, up) * frame
		camera.CameraType = Enum.CameraType.Scriptable
		local view = frame * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local focus = root.Position + up * 1.5
		local dist = zoom
		local back = -view.LookVector
		local block = Workspace:Raycast(focus, back * dist, rayParams)
		if block then
			dist = math.max(0.5, (block.Position - focus).Magnitude - 0.5)
		end
		camera.CFrame = CFrame.lookAt(focus + back * dist, focus, view.UpVector)
		-- hide the body in first person
		local fp = dist < 1.2
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") and d ~= root then
				d.LocalTransparencyModifier = if fp then 1 else 0
			end
		end
		UserInputService.MouseBehavior = if fp then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	end)

	humanoid.Died:Once(function()
		physConn:Disconnect()
		camConn:Disconnect()
		jumpConn:Disconnect()
	end)
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			physConn:Disconnect()
			camConn:Disconnect()
			jumpConn:Disconnect()
		end
	end)
end

if player.Character then
	task.spawn(setup, player.Character)
end
player.CharacterAdded:Connect(setup)
