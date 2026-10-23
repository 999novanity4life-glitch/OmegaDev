--!strict
-- Two cutscenes: the elevator ride down (doors close, lights flicker, floor
-- counter, shake, fade) and the map flyover (camera spirals down the shaft
-- to the leak with a title card). The camera always goes back to Custom.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local CutsceneController = {}

local player = Players.LocalPlayer
local FONT = Font.fromName("FredokaOne")
local DARK = Color3.fromRGB(14, 10, 22)

local gui: ScreenGui
local fader: Frame
local barTop: Frame
local barBottom: Frame
local caption: TextLabel
local subCaption: TextLabel
local playing = 0 -- token so a newer cutscene cancels an older one

-- Freeze the character during a cutscene. Uses the PlayerModule when this
-- place has one, and always zeroes the Humanoid's movement as a fallback.
local frozen = false
local savedSpeed, savedJump = 16, 7.2
local function controls(enabled: boolean)
	local scripts = player:FindFirstChild("PlayerScripts")
	local moduleScript = scripts and scripts:FindFirstChild("PlayerModule")
	if moduleScript and moduleScript:IsA("ModuleScript") then
		local ok, module = pcall(require, moduleScript)
		if ok and type(module) == "table" then
			local c = (module :: any):GetControls()
			if enabled then
				c:Enable()
			else
				c:Disable()
			end
		end
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if not enabled and not frozen then
		frozen = true
		savedSpeed, savedJump = humanoid.WalkSpeed, humanoid.JumpHeight
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
	elseif enabled and frozen then
		frozen = false
		humanoid.WalkSpeed = savedSpeed
		humanoid.JumpHeight = savedJump
	end
end

local function begin(): number
	playing += 1
	player:SetAttribute("Cutscene", true)
	controls(false)
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local info = TweenInfo.new(0.4)
	TweenService:Create(barTop, info, { Size = UDim2.fromScale(1, 0.11) }):Play()
	TweenService:Create(barBottom, info, { Size = UDim2.fromScale(1, 0.11) }):Play()
	return playing
end

local function finish(token: number)
	if token ~= playing then
		return
	end
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	camera.FieldOfView = 70
	local info = TweenInfo.new(0.4)
	TweenService:Create(barTop, info, { Size = UDim2.fromScale(1, 0) }):Play()
	TweenService:Create(barBottom, info, { Size = UDim2.fromScale(1, 0) }):Play()
	TweenService:Create(fader, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	caption.Visible = false
	subCaption.Visible = false
	player:SetAttribute("Cutscene", false)
	controls(true)
end

local function fade(to: number, seconds: number)
	TweenService:Create(fader, TweenInfo.new(seconds), { BackgroundTransparency = to }):Play()
end

local function showCaption(main: string, sub: string?, color: Color3?)
	caption.Text = main
	caption.TextColor3 = color or Config.Colors.Slime
	caption.Visible = true
	subCaption.Text = sub or ""
	subCaption.Visible = sub ~= nil
	local scale = caption:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = caption
	scale.Scale = 1.4
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- Elevator ride: camera at the back of the pod looking at the doors.
local function elevatorRide(podName: string, seconds: number, camFrom: Vector3, camTo: Vector3)
	local lobby = workspace:FindFirstChild("Lobby")
	local pod = lobby and lobby:FindFirstChild(podName) :: Model?
	if not pod then
		return
	end
	local token = begin()
	local camera = workspace.CurrentCamera
	local base = CFrame.lookAt(camFrom, camTo)
	camera.CFrame = base
	camera.FieldOfView = 70
	-- Light flicker on the ceiling strip (local only).
	local strip: BasePart? = nil
	for _, d in pod:GetDescendants() do
		if d:IsA("SurfaceLight") and d.Parent and d.Parent:IsA("BasePart") then
			strip = d.Parent :: BasePart
		end
	end
	local floors = { "B1", "B2", "B3", "B4", "B5", "B6", "B7" }
	local start = os.clock()
	task.delay(0.9, function()
		if token == playing then
			showCaption("GOING DOWN", "Containment level", Color3.new(1, 1, 1))
		end
	end)
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if token ~= playing then
			conn:Disconnect()
			return
		end
		local t = os.clock() - start
		-- Doors close in the first second, then the car shakes as it drops.
		local shaking = t > 1.1 and not GuiService.ReducedMotionEnabled
		local shake = if shaking
			then CFrame.new((math.noise(t * 9, 0) * 0.12), (math.noise(0, t * 11) * 0.16), 0)
			else CFrame.new()
		camera.CFrame = base * shake * CFrame.new(0, -math.max(0, t - 1.1) * 0.05, 0)
		if t > 1.1 then
			local idx = math.clamp(math.floor((t - 1.1) / ((seconds - 1.8) / #floors)) + 1, 1, #floors)
			subCaption.Text = if idx == #floors then "B7  ·  CONTAINMENT" else floors[idx]
			subCaption.Visible = true
		end
		if strip then
			local flicker = (t > 2.4 and t < 2.7) or (t > 3.3 and t < 3.4)
			strip.Transparency = if flicker then 0.85 else 0
		end
		if t >= seconds then
			conn:Disconnect()
		end
	end)
	task.wait(seconds - 0.6)
	if token ~= playing then
		return
	end
	fade(0, 0.5)
	task.wait(0.6)
	if strip then
		strip.Transparency = 0
	end
	-- Stay black until the flyover starts; finish anyway if it never comes.
	task.delay(4, function()
		finish(token)
	end)
end

-- Catmull-Rom through a list of points (smooth camera path).
local function catmull(points: { Vector3 }, t: number): Vector3
	local n = #points
	local f = math.clamp(t, 0, 1) * (n - 1)
	local i = math.clamp(math.floor(f) + 1, 1, n - 1)
	local u = f - (i - 1)
	local p0 = points[math.max(i - 1, 1)]
	local p1 = points[i]
	local p2 = points[i + 1]
	local p3 = points[math.min(i + 2, n)]
	local u2, u3 = u * u, u * u * u
	return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (-p0 + 3 * p1 - 3 * p2 + p3) * u3)
end

local function flyover(path: { { Vector3 } }, seconds: number, title: string)
	if #path < 2 then
		return
	end
	local token = begin()
	local camera = workspace.CurrentCamera
	local positions, targets = {}, {}
	for _, pair in path do
		table.insert(positions, pair[1])
		table.insert(targets, pair[2])
	end
	camera.CFrame = CFrame.lookAt(positions[1], targets[1])
	camera.FieldOfView = 65
	fade(1, 0.8)
	task.delay(0.6, function()
		if token == playing then
			showCaption(title, "The lab is flooding. Fix the leak. Climb out!", Config.Colors.Slime)
		end
	end)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if token ~= playing then
			conn:Disconnect()
			return
		end
		local t = (os.clock() - start) / seconds
		-- Ease in-out so the camera glides instead of starting with a jerk.
		local e = t * t * (3 - 2 * t)
		local pos = catmull(positions, e)
		local look = catmull(targets, math.min(1, e + 0.02))
		camera.CFrame = CFrame.lookAt(pos, look)
		if t >= 1 then
			conn:Disconnect()
		end
	end)
	task.wait(seconds - 0.5)
	if token ~= playing then
		return
	end
	fade(0, 0.35)
	task.wait(0.4)
	finish(token)
end

function CutsceneController.start()
	gui = Instance.new("ScreenGui")
	gui.Name = "Cutscene"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.Parent = player:WaitForChild("PlayerGui")
	fader = Instance.new("Frame")
	fader.Size = UDim2.fromScale(1, 1)
	fader.BackgroundColor3 = DARK
	fader.BackgroundTransparency = 1
	fader.BorderSizePixel = 0
	fader.ZIndex = 5
	fader.Parent = gui
	barTop = Instance.new("Frame")
	barTop.Size = UDim2.fromScale(1, 0)
	barTop.BackgroundColor3 = Color3.new(0, 0, 0)
	barTop.BorderSizePixel = 0
	barTop.ZIndex = 4
	barTop.Parent = gui
	barBottom = barTop:Clone()
	barBottom.AnchorPoint = Vector2.new(0, 1)
	barBottom.Position = UDim2.fromScale(0, 1)
	barBottom.Parent = gui
	caption = Instance.new("TextLabel")
	caption.AnchorPoint = Vector2.new(0.5, 1)
	caption.Position = UDim2.fromScale(0.5, 0.86)
	caption.Size = UDim2.fromScale(0.7, 0.09)
	caption.BackgroundTransparency = 1
	caption.TextScaled = true
	caption.FontFace = FONT
	caption.Visible = false
	caption.ZIndex = 6
	local captionStroke = Instance.new("UIStroke")
	captionStroke.Thickness = 4
	captionStroke.Color = DARK
	captionStroke.Parent = caption
	caption.Parent = gui
	subCaption = caption:Clone()
	subCaption.Position = UDim2.fromScale(0.5, 0.93)
	subCaption.Size = UDim2.fromScale(0.6, 0.05)
	subCaption.TextColor3 = Color3.new(1, 1, 1)
	subCaption.Parent = gui

	Remotes.get("Notify").OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "ElevatorRide" and type(data) == "table" then
			if typeof(data.camFrom) == "Vector3" and typeof(data.camTo) == "Vector3" then
				task.spawn(
					elevatorRide,
					tostring(data.pod),
					tonumber(data.seconds) or Config.Party.RideSeconds,
					data.camFrom,
					data.camTo
				)
			end
		elseif kind == "MatchIntro" and type(data) == "table" then
			task.spawn(flyover, data.path, tonumber(data.seconds) or Config.Party.FlyoverSeconds, tostring(data.title))
		end
	end)
	-- Safety: dying mid-cutscene must never leave the camera stuck.
	player.CharacterAdded:Connect(function()
		finish(playing)
	end)
end

return CutsceneController
