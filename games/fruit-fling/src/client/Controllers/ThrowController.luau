--!strict
-- The 3-beat throw on the client (design doc section 3, Option A):
-- 1 hold THROW: a marker ping-pongs on the bar; let go inside the gold zone.
-- 2 a ring shrinks onto the THROW button; tap when it lines up.
-- 3 mid-flight the ring comes back; tap it again (air tap).
-- Every beat is graded locally the same frame for feedback (ThrowGrade is the
-- same pure module the server uses); the server's answer sets the real distance.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local ThrowGrade = require(Shared:WaitForChild("ThrowGrade"))
local UITokens = require(Shared:WaitForChild("UITokens"))
local Juice = require(script.Parent.Juice)
local UIKit = require(script.Parent.UIKit)

type Grade = ThrowGrade.Grade
type Phase = "Ready" | "Windup" | "Ring" | "Waiting" | "Flight"

local cfg = Config.Throw
local player = Players.LocalPlayer

local ThrowController = {}

local GRADE_COLOR: { [string]: Color3 } = {
	Perfect = Color3.fromRGB(255, 214, 64),
	Great = Color3.fromRGB(92, 214, 120),
	Good = Color3.fromRGB(120, 190, 255),
	Miss = Color3.fromRGB(255, 84, 84),
}

local function rgb(c: UITokens.RGB): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function circle(name: string, parent: Instance, color: Color3, thickness: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	s.Parent = f
	f.Parent = parent
	return f
end

function ThrowController.start()
	local throwRemote = Remotes.get("Throw")
	local airRemote = Remotes.get("AirTap")
	local stateChanged = Remotes.get("StateChanged")

	local gui = UIKit.screen("ThrowUI", player:WaitForChild("PlayerGui"))

	-- THROW button: right side, above the default jump button area.
	local button = UIKit.button("THROW", UDim2.fromScale(0.13, 0.13), "Primary", 1)
	button.Name = "ThrowButton"
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.fromScale(0.96, 0.42)
	button.Parent = gui
	local buttonCorner = button:FindFirstChildOfClass("UICorner")
	if buttonCorner then
		buttonCorner.CornerRadius = UDim.new(0.5, 0)
	end

	-- Ring layer sits on the button so the target ring frames it exactly.
	local ringHolder = Instance.new("Frame")
	ringHolder.Name = "Rings"
	ringHolder.BackgroundTransparency = 1
	ringHolder.Size = UDim2.fromScale(1, 1)
	ringHolder.Parent = button
	local target = circle("Target", ringHolder, Color3.new(1, 1, 1), 3)
	target.Visible = false
	local shrinking = circle("Shrinking", ringHolder, rgb(UITokens.Color.Accent), 5)
	shrinking.Visible = false

	-- Wind-up bar, left of the button.
	local bar = Instance.new("Frame")
	bar.Name = "WindupBar"
	bar.AnchorPoint = Vector2.new(1, 0.5)
	bar.Position = UDim2.fromScale(0.78, 0.42)
	bar.Size = UDim2.fromScale(0.03, 0.42)
	bar.BackgroundColor3 = rgb(UITokens.Color.Surface)
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = gui
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, UITokens.Radius.Small)
	barCorner.Parent = bar
	local barStroke = Instance.new("UIStroke")
	barStroke.Color = rgb(UITokens.Color.Stroke)
	barStroke.Thickness = 2
	barStroke.Parent = bar
	local zone = Instance.new("Frame")
	zone.Name = "Zone"
	zone.AnchorPoint = Vector2.new(0, 0.5)
	zone.Size = UDim2.fromScale(1, cfg.ZoneHalfWidth * 2)
	zone.BackgroundColor3 = GRADE_COLOR.Perfect
	zone.BackgroundTransparency = 0.25
	zone.BorderSizePixel = 0
	zone.Parent = bar
	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.new(1.6, 0, 0, 6)
	marker.BackgroundColor3 = Color3.new(1, 1, 1)
	marker.BorderSizePixel = 0
	marker.Parent = bar

	-- Grade pop-up and distance read-out, top centre.
	local gradeLabel = UIKit.label("", UDim2.fromScale(0.5, 0.1), UITokens.Text.Display)
	gradeLabel.Name = "Grade"
	gradeLabel.AnchorPoint = Vector2.new(0.5, 0)
	gradeLabel.Position = UDim2.fromScale(0.5, 0.12)
	gradeLabel.Font = Enum.Font.GothamBlack
	gradeLabel.TextScaled = true
	gradeLabel.Visible = false
	gradeLabel.Parent = gui
	local gradeStroke = Instance.new("UIStroke")
	gradeStroke.Thickness = 3
	gradeStroke.Parent = gradeLabel

	local infoLabel = UIKit.label("Hold THROW", UDim2.fromScale(0.4, 0.06), UITokens.Text.Title)
	infoLabel.Name = "Info"
	infoLabel.AnchorPoint = Vector2.new(0.5, 0)
	infoLabel.Position = UDim2.fromScale(0.5, 0.23)
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextScaled = true
	infoLabel.Parent = gui
	local infoStroke = Instance.new("UIStroke")
	infoStroke.Thickness = 2
	infoStroke.Parent = infoLabel

	local flash = Instance.new("Frame")
	flash.Name = "ImpactFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = gui

	local phase: Phase = "Ready"
	local windupStart = 0
	local zoneTimeOffset = 0
	local ringStart = 0
	local ringSeconds = cfg.RingSeconds
	local airShown = false
	local airDone = false

	-- Flight state
	local fruit: Part? = nil
	local flightStart = 0
	local flightTime = 1
	local distance = 0
	local targetDistance = 0
	local hitstopUntil = 0
	local pausedTime = 0
	local origin = CFrame.new()
	local savedCamera: CFrame? = nil

	local function showGrade(grade: string, big: boolean?)
		gradeLabel.Text = string.upper(grade) .. "!"
		gradeLabel.TextColor3 = GRADE_COLOR[grade] or Color3.new(1, 1, 1)
		Juice.popIn(gradeLabel)
		if grade == "Perfect" then
			Juice.shakeCamera(if big then cfg.MasterworkShake else cfg.PerfectShake)
		end
	end

	local function impactFlash()
		if GuiService.ReducedMotionEnabled then
			return
		end
		flash.BackgroundTransparency = 0.2
		TweenService:Create(flash, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
	end

	local function startRing(seconds: number)
		ringStart = os.clock()
		ringSeconds = seconds
		target.Visible = true
		shrinking.Visible = true
	end

	local function stopRing()
		target.Visible = false
		shrinking.Visible = false
	end

	local function ringOffset(): number
		return os.clock() - (ringStart + ringSeconds)
	end

	local function zoneRatioNow(t: number): number
		local m = ThrowGrade.pingPong(t, cfg.MarkerPeriod)
		local c = ThrowGrade.zoneCenter(t + zoneTimeOffset, cfg.ZoneDriftSpeed, cfg.ZoneHalfWidth)
		return (m - c) / cfg.ZoneHalfWidth
	end

	local pendingRatio = 0
	local waitingSince = 0

	local function releaseWindup()
		if phase ~= "Windup" then
			return
		end
		pendingRatio = zoneRatioNow(os.clock() - windupStart)
		showGrade(ThrowGrade.gradeZone(pendingRatio, cfg.ZoneGrades))
		bar.Visible = false
		phase = "Ring"
		infoLabel.Text = "Tap when the rings meet!"
		startRing(cfg.RingSeconds)
	end

	local function tapRelease(offset: number)
		stopRing()
		showGrade(ThrowGrade.gradeTiming(offset, cfg.TimingWindows))
		phase = "Waiting"
		waitingSince = os.clock()
		infoLabel.Text = ""
		throwRemote:FireServer(pendingRatio, offset)
	end

	local function tapAir(offset: number)
		airDone = true
		stopRing()
		local grade = ThrowGrade.gradeTiming(offset, cfg.TimingWindows)
		showGrade(grade)
		infoLabel.Text = ""
		airRemote:FireServer(offset)
	end

	local function press()
		if phase == "Ready" then
			phase = "Windup"
			windupStart = os.clock()
			zoneTimeOffset = math.random() * 10
			bar.Visible = true
			infoLabel.Text = "Let go in the gold zone!"
		elseif phase == "Ring" then
			tapRelease(ringOffset())
		elseif phase == "Flight" and airShown and not airDone then
			tapAir(ringOffset())
		end
	end

	local function release()
		if phase == "Windup" then
			releaseWindup()
		end
	end

	button.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			press()
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			release()
		end
	end)
	-- Keyboard: hold/tap F.
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.F then
			press()
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.F then
			release()
		end
	end)

	local function spawnFruit(): Part
		local p = Instance.new("Part")
		p.Name = "ThrownFruit"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(2.4, 2.4, 2.4)
		p.Color = Color3.fromRGB(128, 64, 200) -- test fruit: violet melon stand-in
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = true
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.9, 0)
		a0.Parent = p
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.9, 0)
		a1.Parent = p
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.35
		trail.LightEmission = 1
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 180, 90), Color3.fromRGB(255, 90, 40))
		trail.Transparency = NumberSequence.new(0.1, 1)
		trail.Parent = p
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 80)
		light.Range = 12
		light.Brightness = 2
		light.Parent = p
		p.Parent = workspace
		return p
	end

	local function splash(at: Vector3, masterwork: boolean)
		local ring = Instance.new("Part")
		ring.Name = "Splash"
		ring.Anchored = true
		ring.CanCollide = false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = if masterwork then GRADE_COLOR.Perfect else Color3.fromRGB(200, 240, 255)
		ring.Size = Vector3.new(0.4, 2, 2)
		ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace
		local grow = if masterwork then 40 else 22
		local tween = TweenService:Create(
			ring,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.4, grow, grow), Transparency = 1 }
		)
		tween.Completed:Once(function()
			ring:Destroy()
		end)
		tween:Play()
	end

	local landedInfo: { [string]: any }? = nil

	local function finishFlight()
		local f = fruit
		if f then
			local info = landedInfo
			splash(Vector3.new(f.Position.X, 0.2, f.Position.Z), info ~= nil and info.masterwork == true)
			f:Destroy()
		end
		fruit = nil
		stopRing()
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			if savedCamera then
				camera.CFrame = savedCamera
			end
		end
		task.delay(0.8, function()
			phase = "Ready"
			infoLabel.Text = "Hold THROW"
		end)
	end

	stateChanged.OnClientEvent:Connect(function(kind: string, data: any)
		if typeof(data) ~= "table" then
			return
		end
		if kind == "Launched" then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local start = if root then root.Position + Vector3.new(0, 1.5, -2) else Vector3.new(0, 10, -12)
			origin = CFrame.lookAt(start, start + Vector3.new(0, 0, -1))
			distance = data.distance
			targetDistance = data.distance
			flightTime = data.flight
			flightStart = os.clock()
			pausedTime = 0
			airShown = false
			airDone = false
			landedInfo = nil
			fruit = spawnFruit()
			phase = "Flight"
			if data.combo > 1 then
				infoLabel.Text = string.format("COMBO x%d", data.combo)
			end
			local camera = workspace.CurrentCamera
			if camera then
				savedCamera = camera.CFrame
				camera.CameraType = Enum.CameraType.Scriptable
			end
		elseif kind == "Landed" then
			landedInfo = data
			targetDistance = data.distance
			if data.masterwork then
				hitstopUntil = os.clock() + cfg.HitstopSeconds
				pausedTime += cfg.HitstopSeconds
				impactFlash()
				showGrade("Perfect", true)
				gradeLabel.Text = "MASTERWORK!"
			end
			infoLabel.Text = string.format("%d m   (best %d m)", data.distance, data.best)
		end
	end)

	RunService.RenderStepped:Connect(function(dt: number)
		local now = os.clock()
		if phase == "Windup" then
			local t = now - windupStart
			local m = ThrowGrade.pingPong(t, cfg.MarkerPeriod)
			local c = ThrowGrade.zoneCenter(t + zoneTimeOffset, cfg.ZoneDriftSpeed, cfg.ZoneHalfWidth)
			-- Bar is vertical: 0 at the bottom.
			marker.Position = UDim2.fromScale(0.5, 1 - m)
			zone.Position = UDim2.fromScale(0, 1 - c)
			if t >= cfg.WindupMaxHold then
				releaseWindup()
			end
		end

		if phase == "Waiting" and now - waitingSince > 2 then
			-- The server ignored the throw (rate limit or a dropped packet).
			phase = "Ready"
			infoLabel.Text = "Hold THROW"
		end

		if target.Visible then
			-- Shrinks from 2.6x to 1x at the hit moment, keeps going to show "late".
			local alpha = (now - ringStart) / ringSeconds
			local scale = math.max(0.4, 2.6 - 1.6 * alpha)
			shrinking.Size = UDim2.fromScale(scale, scale)
			if now - (ringStart + ringSeconds) > cfg.TimingWindows.Good then
				-- Too late: counts as a miss.
				if phase == "Ring" then
					tapRelease(ringOffset())
				elseif phase == "Flight" and airShown and not airDone then
					tapAir(ringOffset())
				end
			end
		end

		local f = fruit
		if phase == "Flight" and f then
			if now < hitstopUntil then
				return -- hitstop: freeze the fruit for a beat
			end
			local alpha = (now - flightStart - pausedTime) / flightTime
			if not airShown and alpha >= cfg.AirRingAt then
				airShown = true
				infoLabel.Text = "AIR TAP!"
				startRing(cfg.AirRingSeconds)
			end
			-- Ease toward the server's final distance once it arrives.
			distance += (targetDistance - distance) * math.min(1, dt * 6)
			local forward, height = ThrowGrade.arc(alpha, distance, cfg.FlightArcHeight)
			local pos = (origin * CFrame.new(0, height, -forward)).Position
			f.CFrame = CFrame.new(pos) * CFrame.Angles(alpha * 20, 0, 0)
			local camera = workspace.CurrentCamera
			if camera then
				local camPos = pos + Vector3.new(14, 8, 22)
				camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, pos), math.min(1, dt * 8))
			end
			-- Land once the server answered; past 1.6 assume its answer was lost
			-- so the player is never stranded.
			if (alpha >= 1 and landedInfo ~= nil) or alpha >= 1.6 then
				finishFlight()
			end
		end
	end)
end

return ThrowController
