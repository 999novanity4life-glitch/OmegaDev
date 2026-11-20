--!strict
-- The throw on the client, reworked 2026-11-20 after Throw Food For Animals
-- (TFFA; frames and timings in project files fruit-throw/tffa-ref-2026-11-20):
-- 0 walk up to the dock edge: a short cutscene (letterbox + camera swoop)
--   puts you into the throw.
-- 1 power meter: a marker bounces on a vertical bar (green at the top),
--   "+N" rides beside it; tap once. The top (+20) is PERFECT.
-- 2 release ring (Forge-style bonus): tap when the rings meet. The swing plays.
-- 3 air tap (bonus): the ring comes back mid-flight.
-- The follow camera locks behind the fruit, a touch faster than TFFA, and
-- slower with slow motion the rarer the fruit (Config.Rarity.Pace).
-- Every beat is graded locally the same frame for feedback (ThrowGrade is the
-- same pure module the server uses); the server's answer sets the real result.

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
local PremiumHUD = require(script.Parent.PremiumHUD)
local ThrowAnimator = require(script.Parent.ThrowAnimator)
local ThrowFX = require(script.Parent.ThrowFX)
local UIKit = require(script.Parent.UIKit)

type Grade = ThrowGrade.Grade
type Phase = "Roam" | "Cutscene" | "Meter" | "Locked" | "Ring" | "Waiting" | "Flight" | "Landing"

local cfg = Config.Throw
local player = Players.LocalPlayer

local ThrowController = {}

local GRADE_COLOR: { [string]: Color3 } = {
	Perfect = Color3.fromRGB(92, 230, 110), -- TFFA: the locked marker turns green
	Great = Color3.fromRGB(255, 214, 64),
	Good = Color3.fromRGB(120, 190, 255),
	Miss = Color3.fromRGB(255, 84, 84),
}

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function outlined(label: TextLabel, thickness: number)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.Parent = label
end

-- Where the player stands to throw, and which way the lane runs (-Z).
local function throwSpot(): Vector3
	local dock = Config.Dock
	if dock.Enabled then
		return Vector3.new(0, dock.DeckHeight + 3, dock.ThrowEdgeZ + cfg.EdgeSpotBack)
	end
	return Vector3.new(0, Config.Lane.DeckHeight + 3, -12)
end
local LANE = Vector3.new(0, 0, -1)

-- Over-the-shoulder aim shot (TFFA: low, behind and a bit right of the player).
local function aimCamera(): CFrame
	local spot = throwSpot()
	local eye = spot + Vector3.new(3.2, 2.2, 9)
	return CFrame.lookAt(eye, spot + Vector3.new(0, 1.2, -40))
end

local function rarityRank(rarity: string): number
	return table.find(Config.Rarity.Order, rarity) or 1
end

function ThrowController.start()
	local throwRemote = Remotes.get("Throw")
	local airRemote = Remotes.get("AirTap")
	local stateChanged = Remotes.get("StateChanged")

	local gui = UIKit.screen("ThrowUI", player:WaitForChild("PlayerGui"))

	-- Letterbox bars for the cutscene (outside the safe-area screen so they
	-- reach the screen edges).
	local cinema = Instance.new("ScreenGui")
	cinema.Name = "ThrowCinema"
	cinema.ResetOnSpawn = false
	cinema.IgnoreGuiInset = true
	cinema.DisplayOrder = -1
	cinema.Parent = player:WaitForChild("PlayerGui")
	local function bar(top: boolean): Frame
		local f = Instance.new("Frame")
		f.Name = if top then "Top" else "Bottom"
		f.AnchorPoint = Vector2.new(0, if top then 0 else 1)
		f.Position = UDim2.fromScale(0, if top then 0 else 1)
		f.Size = UDim2.fromScale(1, 0)
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.Parent = cinema
		return f
	end
	local topBar, bottomBar = bar(true), bar(false)
	local function letterbox(amount: number, seconds: number)
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(topBar, info, { Size = UDim2.fromScale(1, amount) }):Play()
		TweenService:Create(bottomBar, info, { Size = UDim2.fromScale(1, amount) }):Play()
	end
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = cinema
	local function screenFlash(strength: number)
		if GuiService.ReducedMotionEnabled then
			return
		end
		flash.BackgroundTransparency = 1 - strength
		TweenService:Create(flash, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	end

	-- THROW button (taps anywhere also count): right side, above the jump
	-- button. Premium 3D build: chrome bezel, sinking face (PremiumHUD).
	local throwHud = PremiumHUD.button(gui, "THROW", 0.2)
	local button = throwHud.root
	button.Position = UDim2.fromScale(0.96, 0.42)
	button.Visible = false
	local target = throwHud.target
	local shrinking = throwHud.shrinking

	-- LEAVE button: back out of the throw (left side, clear of the thumbstick).
	local leave = UIKit.button("LEAVE", UDim2.fromScale(0.12, 0.06), "Secondary", 2.6)
	leave.Name = "LeaveButton"
	leave.AnchorPoint = Vector2.new(0, 0)
	leave.Position = UDim2.fromScale(0.02, 0.2)
	leave.Visible = false
	leave.Parent = gui

	-- Power meter (TFFA layout: bar beside the player, green top, "+N" on the
	-- marker) in the premium glass + chrome finish (PremiumHUD.meter).
	local meterHud = PremiumHUD.meter(gui)
	local meter = meterHud.root
	meter.Position = UDim2.fromScale(0.58, 0.45)
	local marker = meterHud.marker
	local plusLabel = meterHud.plus
	local tapLabel = UIKit.label("TAP TO THROW!", UDim2.fromScale(0.3, 0.06), UITokens.Text.Title)
	tapLabel.Name = "TapToThrow"
	tapLabel.AnchorPoint = Vector2.new(0.5, 0)
	tapLabel.Position = UDim2.fromScale(0.58, 0.76)
	tapLabel.Font = Enum.Font.GothamBlack
	tapLabel.TextScaled = true
	tapLabel.Visible = false
	tapLabel.Parent = gui
	outlined(tapLabel, 3)

	-- "+20 POWER" pop and grade word.
	local powerPop = UIKit.label("", UDim2.fromScale(0.22, 0.07), UITokens.Text.Title)
	powerPop.Name = "PowerPop"
	powerPop.AnchorPoint = Vector2.new(0, 0.5)
	powerPop.Font = Enum.Font.GothamBlack
	powerPop.TextScaled = true
	powerPop.TextXAlignment = Enum.TextXAlignment.Left
	powerPop.Visible = false
	powerPop.Parent = gui
	outlined(powerPop, 3)

	local gradeHud = PremiumHUD.gradeText(gui) -- extruded PERFECT / MASTERWORK text

	local infoLabel = UIKit.label("", UDim2.fromScale(0.4, 0.06), UITokens.Text.Title)
	infoLabel.Name = "Info"
	infoLabel.AnchorPoint = Vector2.new(0.5, 0)
	infoLabel.Position = UDim2.fromScale(0.5, 0.41)
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextScaled = true
	infoLabel.Parent = gui
	outlined(infoLabel, 2)

	-- Flight banner (TFFA: big number top-centre, fruit + rarity under it) as a
	-- chrome plate with rolling digits; the fruit reveal plays after landing.
	local plate = PremiumHUD.distancePlate(gui)
	local banner = plate.root
	local reveal = PremiumHUD.reveal(gui)

	-- State ---------------------------------------------------------------
	local phase: Phase = "Roam"
	local armed = true -- false until the player walks away from the edge
	local meterStart = 0
	local lockedPower = 0
	local ringStart = 0
	local ringSeconds = cfg.RingSeconds
	local airShown = false
	local airDone = false
	local waitingSince = 0
	local savedWalk: { speed: number, jump: number }? = nil

	-- Flight
	local fruit: BasePart? = nil
	local launch: { [string]: any }? = nil
	local releasePos = Vector3.zero
	local flightStart = 0
	local distance = 0
	local targetDistance = 0
	local hitstopUntil = 0
	local landedInfo: { [string]: any }? = nil
	local releaseReady = false

	local function camera(): Camera?
		return workspace.CurrentCamera
	end

	local function humanoid(): Humanoid?
		local character = player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end

	local function rootPart(): BasePart?
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root else nil
	end

	local function showGrade(text: string, color: Color3, big: boolean?)
		gradeHud.show(text, color, big)
		if big then
			Juice.shakeCamera(cfg.MasterworkShake)
		end
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

	local function freeze(on: boolean)
		local h = humanoid()
		if not h then
			return
		end
		if on then
			savedWalk = savedWalk or { speed = h.WalkSpeed, jump = h.JumpHeight }
			h.WalkSpeed = 0
			h.JumpHeight = 0
			h.AutoRotate = false
		elseif savedWalk then
			h.WalkSpeed = savedWalk.speed
			h.JumpHeight = savedWalk.jump
			h.AutoRotate = true
			savedWalk = nil
		end
	end

	local function showMeter()
		phase = "Meter"
		meterStart = os.clock() + cfg.MeterAppearDelay
		marker.BackgroundColor3 = Color3.new(1, 1, 1)
		plusLabel.TextColor3 = Color3.new(1, 1, 1)
		powerPop.Visible = false
		gradeHud.root.Visible = false
		infoLabel.Text = ""
		banner.Visible = false
		button.Visible = true
		leave.Visible = true
		task.delay(cfg.MeterAppearDelay, function()
			if phase == "Meter" then
				meter.Visible = true
				tapLabel.Visible = true
				Juice.popIn(meter)
			end
		end)
		local cam = camera()
		if cam then
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = aimCamera()
		end
	end

	-- 0: dock-edge cutscene. Letterbox in, camera swoops from wherever it is
	-- around the side of the player to the over-shoulder aim shot.
	local function startCutscene()
		local root = rootPart()
		local cam = camera()
		if not root or not cam then
			return
		end
		phase = "Cutscene"
		armed = false
		freeze(true)
		local spot = throwSpot()
		root.CFrame = CFrame.lookAt(spot, spot + LANE)
		letterbox(0.11, 0.35)
		cam.CameraType = Enum.CameraType.Scriptable
		local from = cam.CFrame
		local finish = aimCamera()
		if GuiService.ReducedMotionEnabled then
			cam.CFrame = finish
			task.delay(0.3, function()
				letterbox(0.05, 0.3)
				showMeter()
			end)
			return
		end
		-- quadratic Bezier through a swoop point off the side of the pier
		local swoop = spot + Vector3.new(14, 5, -6)
		local seconds = cfg.CutsceneSeconds
		local start = os.clock()
		local connection: RBXScriptConnection
		connection = RunService.RenderStepped:Connect(function()
			local t = math.clamp((os.clock() - start) / seconds, 0, 1)
			local k = t * t * (3 - 2 * t)
			local a = from.Position:Lerp(swoop, k)
			local b = swoop:Lerp(finish.Position, k)
			local pos = a:Lerp(b, k)
			local look = (spot + Vector3.new(0, 1.5, 0)):Lerp(finish.Position + finish.LookVector * 40, k * k)
			cam.CFrame = CFrame.lookAt(pos, look)
			if t >= 1 then
				connection:Disconnect()
				letterbox(0.05, 0.3)
				showMeter()
			end
		end)
	end

	local function exitThrow()
		phase = "Roam"
		meter.Visible = false
		tapLabel.Visible = false
		powerPop.Visible = false
		button.Visible = false
		leave.Visible = false
		banner.Visible = false
		gradeHud.root.Visible = false
		infoLabel.Text = ""
		stopRing()
		letterbox(0, 0.3)
		freeze(false)
		ThrowAnimator.reset(player.Character)
		local cam = camera()
		if cam then
			cam.CameraType = Enum.CameraType.Custom
		end
	end

	-- 1: lock the meter.
	local function lockMeter()
		if phase ~= "Meter" or os.clock() < meterStart then
			return
		end
		phase = "Locked"
		lockedPower = ThrowGrade.meterPower(ThrowGrade.meterValue(os.clock() - meterStart, cfg), cfg)
		local grade = ThrowGrade.gradePower(lockedPower, cfg)
		local color = GRADE_COLOR[grade]
		marker.BackgroundColor3 = color
		plusLabel.TextColor3 = color
		plusLabel.Text = "+" .. lockedPower
		tapLabel.Visible = false
		-- "+20 POWER" pops in beside the bar and drifts up (TFFA)
		powerPop.Text = string.format("+%d POWER", lockedPower)
		powerPop.TextColor3 = color
		powerPop.Position = UDim2.fromScale(0.63, 0.55)
		Juice.popIn(powerPop)
		TweenService:Create(powerPop, TweenInfo.new(0.8), { Position = UDim2.fromScale(0.63, 0.48) }):Play()
		showGrade(string.upper(grade) .. "!", color)
		if grade == "Perfect" then
			Juice.shakeCamera(cfg.PerfectShake)
		end
		leave.Visible = false
		task.delay(cfg.MeterLockHold, function()
			if (phase :: Phase) ~= "Locked" then -- phase changes while we wait
				return
			end
			meter.Visible = false
			powerPop.Visible = false
			phase = "Ring"
			infoLabel.Text = "BONUS: tap when the rings meet!"
			startRing(cfg.RingSeconds)
		end)
	end

	-- 2: release ring tap -> swing; the fruit leaves the hand on the release frame.
	local function tapRelease(offset: number)
		stopRing()
		local grade = ThrowGrade.gradeTiming(offset, cfg.TimingWindows)
		showGrade(string.upper(grade) .. "!", GRADE_COLOR[grade])
		phase = "Waiting"
		waitingSince = os.clock()
		infoLabel.Text = ""
		releaseReady = false
		launch = nil
		throwRemote:FireServer(lockedPower, offset)
		ThrowAnimator.swing(player.Character, function(handPos: Vector3)
			releasePos = handPos
			releaseReady = true
		end)
	end

	local function tapAir(offset: number)
		airDone = true
		stopRing()
		local grade = ThrowGrade.gradeTiming(offset, cfg.TimingWindows)
		showGrade(string.upper(grade) .. "!", GRADE_COLOR[grade])
		infoLabel.Text = ""
		airRemote:FireServer(offset)
	end

	local function press()
		if phase == "Meter" then
			lockMeter()
		elseif phase == "Ring" then
			tapRelease(ringOffset())
		elseif phase == "Flight" and airShown and not airDone then
			tapAir(ringOffset())
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
	leave.Activated:Connect(function()
		if phase == "Meter" then
			exitThrow()
		end
	end)
	-- TFFA: "tap to throw" means a tap anywhere. Keyboard: F or Space.
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if
			input.KeyCode == Enum.KeyCode.F
			or (phase ~= "Roam" and input.KeyCode == Enum.KeyCode.Space)
			or (
				phase ~= "Roam"
				and (
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
			)
		then
			press()
		end
	end)

	-- Flight -----------------------------------------------------------------
	local function beginFlight()
		local data = launch
		if not data then
			return
		end
		local rarity: string = data.rarity
		local rarityColor = rgb(Config.Rarity.Color[rarity] or { 255, 255, 255 })
		local glow = Color3.new(1, 1, 1)
		for _, f in Config.Fruits do
			if f.key == data.fruit then
				glow = rgb(f.glow)
			end
		end
		ThrowFX.releaseBurst(releasePos, rarityColor, LANE, lockedPower / cfg.MeterMax)
		screenFlash(if rarityRank(rarity) >= 4 then 0.5 else 0.25)
		fruit = ThrowFX.makeFruit(data.fruit, glow, rarityColor)
		flightStart = os.clock()
		distance = data.distance
		targetDistance = data.distance
		airShown = false
		airDone = false
		landedInfo = nil
		hitstopUntil = 0
		phase = "Flight"
		banner.Visible = true
		plate.setTarget(0, true)
		plate.setSub(string.format("%s  •  %s", string.upper(data.fruitName), string.upper(rarity)), rarityColor)
		Juice.popIn(banner)
		if data.combo > 1 then
			infoLabel.Text = string.format("COMBO x%d", data.combo)
		end
	end

	local function finishFlight()
		local f = fruit
		local data = launch
		local info = landedInfo
		local revealSeconds = 0
		phase = "Landing"
		stopRing()
		if f and data then
			local waterY = if Config.Dock.Enabled then Config.Dock.WaterY else 0
			local at = Vector3.new(f.Position.X, waterY + 0.2, f.Position.Z)
			ThrowFX.splash(
				at,
				rgb(Config.Rarity.Color[data.rarity] or { 255, 255, 255 }),
				rarityRank(data.rarity),
				info ~= nil and info.masterwork == true
			)
			revealSeconds = reveal.play(data.fruitName, data.rarity, f)
			f:Destroy()
			-- TFFA cuts to a low shot by the landing and dollies in slowly.
			local cam = camera()
			if cam and not GuiService.ReducedMotionEnabled then
				cam.CFrame = CFrame.lookAt(at + Vector3.new(9, 4, 12), at)
				TweenService:Create(cam, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
					CFrame = CFrame.lookAt(at + Vector3.new(5, 2.5, 7), at),
				}):Play()
			end
		end
		fruit = nil
		if info then
			plate.setTarget(info.distance)
			infoLabel.Text = string.format("BEST %d m", info.best)
		end
		-- Wait for the fruit reveal card if it runs longer than the landing beat.
		task.delay(math.max(1.6, revealSeconds + 0.2), function()
			if phase == "Landing" then
				screenFlash(0.6)
				showMeter() -- stay at the edge for the next throw
			end
		end)
	end

	stateChanged.OnClientEvent:Connect(function(kind: string, data: any)
		if typeof(data) ~= "table" then
			return
		end
		if kind == "Launched" then
			launch = data
		elseif kind == "Landed" then
			landedInfo = data
			targetDistance = data.distance
			if data.masterwork then
				hitstopUntil = os.clock() + cfg.HitstopSeconds
				flightStart += cfg.HitstopSeconds
				screenFlash(0.6)
				showGrade("MASTERWORK!", GRADE_COLOR.Great, true)
			end
		end
	end)

	-- Every frame -------------------------------------------------------------
	RunService.RenderStepped:Connect(function(dt: number)
		local now = os.clock()

		if phase == "Roam" then
			local root = rootPart()
			if root then
				local offset = root.Position - throwSpot()
				local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flat > cfg.EdgeTriggerRadius + 2 then
					armed = true
				elseif armed and flat <= cfg.EdgeTriggerRadius then
					startCutscene()
				end
			end
			return
		end

		if phase == "Meter" and now >= meterStart then
			local v = ThrowGrade.meterValue(now - meterStart, cfg)
			marker.Position = UDim2.fromScale(0.5, 1 - v / cfg.MeterMax)
			plusLabel.Text = "+" .. ThrowGrade.meterPower(v, cfg)
			ThrowAnimator.charge(player.Character, v / cfg.MeterMax)
		end

		if phase == "Waiting" then
			if releaseReady and launch then
				beginFlight()
			elseif now - waitingSince > 2.5 then
				-- The server ignored the throw (rate limit or a dropped packet).
				showMeter()
			end
		end

		if target.Visible then
			-- Shrinks from 2.6x to 1x at the hit moment, keeps going to show "late".
			local alpha = (now - ringStart) / ringSeconds
			local scale = math.max(0.4, 2.6 - 1.6 * alpha)
			shrinking.Size = UDim2.fromScale(scale, scale)
			if now - (ringStart + ringSeconds) > cfg.TimingWindows.Good then
				if phase == "Ring" then
					tapRelease(ringOffset())
				elseif phase == "Flight" and airShown and not airDone then
					tapAir(ringOffset())
				end
			end
		end

		local f = fruit
		local data = launch
		if phase == "Flight" and f and data then
			if now < hitstopUntil then
				return -- hitstop: freeze the fruit for a beat
			end
			local pace = Config.Rarity.Pace[data.rarity] or Config.Rarity.Pace.Epic
			local alpha = ThrowGrade.flightAlpha(now - flightStart, data.base, pace)
			if not airShown and alpha >= cfg.AirRingAt then
				airShown = true
				infoLabel.Text = "AIR TAP!"
				startRing(cfg.AirRingSeconds)
			end
			distance += (targetDistance - distance) * math.min(1, dt * 6)
			local forward, height = ThrowGrade.arc(alpha, distance, cfg.FlightArcHeight)
			local start = releasePos
			local pos = start + LANE * forward + Vector3.new(0, height, 0)
			f.CFrame = CFrame.new(pos) * CFrame.Angles(alpha * 20, alpha * 7, 0)
			plate.setTarget(forward)
			-- Follow cam: high behind the fruit looking down the lane (TFFA),
			-- catch-up rate from the rarity (rarer = lazier, more dramatic).
			local cam = camera()
			if cam then
				local camPos = pos + Vector3.new(0, 5, 15)
				local goal = CFrame.lookAt(camPos, pos + LANE * 12)
				local k = 1 - math.exp(-pace.camSpeed * dt)
				cam.CFrame = cam.CFrame:Lerp(goal, k)
			end
			-- Land once the server answered; past 1.6 assume its answer was lost.
			if (alpha >= 1 and landedInfo ~= nil) or alpha >= 1.6 then
				finishFlight()
			end
		end
	end)

	player.CharacterAdded:Connect(function()
		savedWalk = nil
		if phase ~= "Roam" then
			exitThrow()
		end
		armed = false
	end)
end

return ThrowController
