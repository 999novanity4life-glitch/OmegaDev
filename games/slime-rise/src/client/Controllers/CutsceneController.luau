--!strict
-- Two cutscenes: the elevator ride down (doors close, lights flicker, floor
-- counter, shake, fade) and the map intro (IntroPath: per tier a wide shot
-- then a push-in on its puzzle, a quick dip to black between floors, and the
-- exit last). The camera always goes back to Custom.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local IntroPath = require(Shared:WaitForChild("IntroPath"))

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

-- The player list covers the shot; hide it while a cutscene plays.
local function playerList(enabled: boolean)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, enabled)
	end)
end

local function begin(): number
	playing += 1
	playerList(false)
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
	playerList(true)
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
	task.delay(20, function()
		finish(token)
	end)
end

local function hideCaptionLater(token: number, text: string, seconds: number)
	task.delay(seconds, function()
		if token == playing and caption.Text == text then
			caption.Visible = false
			subCaption.Visible = false
		end
	end)
end

local function toVector(origin: Vector3, p: { number }): Vector3
	return origin + Vector3.new(p[1], p[2], p[3])
end

local function validShots(shots: any): boolean
	if type(shots) ~= "table" or #shots < 1 then
		return false
	end
	for _, shot in shots do
		if type(shot) ~= "table" or type(shot.t) ~= "number" or type(shot.keys) ~= "table" or #shot.keys < 2 then
			return false
		end
		for _, k in shot.keys do
			if type(k) ~= "table" or type(k.t) ~= "number" or type(k.pos) ~= "table" or type(k.look) ~= "table" then
				return false
			end
		end
	end
	return true
end

local function flyover(data: { [string]: any })
	local origin = data.origin
	if not validShots(data.shots) or typeof(origin) ~= "Vector3" then
		return
	end
	local path: IntroPath.Path = {
		shots = data.shots,
		cuts = if type(data.cuts) == "table" then data.cuts else {},
		captions = {},
		seconds = tonumber(data.seconds) or 0,
	}
	local seconds = path.seconds
	local token = begin()
	local camera = workspace.CurrentCamera
	local pos, look = IntroPath.sample(path, 0)
	camera.CFrame = CFrame.lookAt(toVector(origin, pos), toVector(origin, look))
	camera.FieldOfView = 58
	fade(1, 0.9)
	local start = os.clock()
	local function at(t: number, fn: () -> ())
		task.delay(math.max(0, start + t - os.clock()), function()
			if token == playing then
				fn()
			end
		end)
	end
	if type(data.captions) == "table" then
		for _, c in data.captions do
			if type(c) == "table" and type(c.t) == "number" then
				at(c.t, function()
					local main = tostring(c.main)
					showCaption(main, tostring(c.sub), Config.Colors.Slime)
					hideCaptionLater(token, main, 2.6)
				end)
			end
		end
	end
	-- Floor changes: a quick dip to black, cut while dark, fade back in.
	for _, cut in path.cuts do
		if type(cut) == "number" then
			at(cut - Config.Intro.DipOut, function()
				fade(0, Config.Intro.DipOut)
			end)
			at(cut + 0.05, function()
				fade(1, Config.Intro.DipIn)
			end)
		end
	end
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if token ~= playing then
			conn:Disconnect()
			return
		end
		local t = os.clock() - start
		local p, l = IntroPath.sample(path, t)
		camera.CFrame = CFrame.lookAt(toVector(origin, p), toVector(origin, l))
		if t >= seconds then
			conn:Disconnect()
		end
	end)
	task.wait(math.max(0, seconds - 0.6))
	if token == playing then
		fade(0, 0.5)
		task.wait(0.6)
	end
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
			task.spawn(flyover, data)
		end
	end)
	-- Safety: dying mid-cutscene must never leave the camera stuck.
	player.CharacterAdded:Connect(function()
		finish(playing)
	end)
end

return CutsceneController
