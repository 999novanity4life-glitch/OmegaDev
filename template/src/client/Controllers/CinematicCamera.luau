--!strict
-- Plays camera work on this client: shot lists relative to a subject (ability
-- cams, cutscenes, trailer shots), cameras bound to an animated part (the
-- battleground "camera rig in the animation" method), and baked per-frame
-- CFrame lists (Moon Animator style exports). One API, one guaranteed cleanup.
--
-- Rules it enforces (vault/18, docs/rulebooks/ANIMATION_CUTSCENE_RULEBOOK.md):
--   * camera work is client-only; the server only says "play cutscene X"
--   * CameraType goes back to Custom and CameraSubject to the Humanoid in a
--     path that always runs, even if a shot errors
--   * every cutscene can be skipped (except short in-combat ability cams)
--   * Reduced Motion: hard cuts to each shot's end pose, no shake
-- [DOC] Camera.CameraType Scriptable / Custom, Camera.Focus, FieldOfView:
--   https://create.roblox.com/docs/reference/engine/classes/Camera
-- [DOC] RunService:BindToRenderStep with Enum.RenderPriority.Camera:
--   https://create.roblox.com/docs/reference/engine/classes/RunService
-- Not yet run in Studio when written: see docs/VISUAL_QA.md.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CameraRig = require(Shared:WaitForChild("CameraRig"))

type Shot = CameraRig.Shot
type Vec = CameraRig.Vec

export type Subject = BasePart | Model | CFrame | () -> CFrame
export type PlayOptions = {
	letterbox: boolean?, -- default true for cutscenes
	skippable: boolean?, -- default true
	blendBack: boolean?, -- ease back to the gameplay camera at the end (default true)
	onShot: ((index: number, shot: Shot) -> ())?,
	seed: number?,
}
export type Handle = {
	stop: (self: Handle) -> (),
	wait: (self: Handle) -> (),
	playing: (self: Handle) -> boolean,
}

local CinematicCamera = {}

local RENDER_NAME = "OmegaCinematic"
local player = Players.LocalPlayer
local active: { stop: () -> () }? = nil
local cfg = Config.Cinematic

local function v3(v: Vec): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function subjectFrame(subject: Subject): CFrame
	if typeof(subject) == "CFrame" then
		return subject
	elseif typeof(subject) == "function" then
		return subject()
	elseif typeof(subject) == "Instance" and subject:IsA("BasePart") then
		return subject.CFrame
	elseif typeof(subject) == "Instance" and subject:IsA("Model") then
		return subject:GetPivot()
	end
	error("CinematicCamera: bad subject")
end

-- Facing angle about Y from a CFrame (pitch and roll ignored, so a falling or
-- spinning character doesn't flip the camera).
local function yawOf(cf: CFrame): number
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function poseToCFrame(origin: CFrame, pose: CameraRig.Pose, shake: Vec?): CFrame
	local p = origin.Position
	local o = { p.X, p.Y, p.Z }
	local yaw = yawOf(origin)
	local eye = v3(CameraRig.toWorld(o, yaw, pose.offset))
	local at = v3(CameraRig.toWorld(o, yaw, pose.look))
	if shake then
		eye += v3(shake)
	end
	local cf = CFrame.lookAt(eye, at)
	if pose.roll and pose.roll ~= 0 then
		cf *= CFrame.Angles(0, 0, math.rad(pose.roll))
	end
	return cf
end

-- Letterbox bars; a separate ScreenGui with CoreUISafeInsets holds Skip so it
-- never sits under a notch (CLAUDE.md rule 5).
local function makeOverlay(letterbox: boolean, skippable: boolean, onSkip: () -> ())
	local playerGui = player:WaitForChild("PlayerGui")
	local bars = Instance.new("ScreenGui")
	bars.Name = "OmegaLetterbox"
	bars.IgnoreGuiInset = true
	bars.ScreenInsets = Enum.ScreenInsets.None
	bars.DisplayOrder = 50
	bars.ResetOnSpawn = false
	local top = Instance.new("Frame")
	top.BackgroundColor3 = Color3.new(0, 0, 0)
	top.BorderSizePixel = 0
	top.Size = UDim2.fromScale(1, 0)
	top.Parent = bars
	local bottom = top:Clone()
	bottom.AnchorPoint = Vector2.new(0, 1)
	bottom.Position = UDim2.fromScale(0, 1)
	bottom.Parent = bars
	bars.Parent = playerGui

	local barTime = if GuiService.ReducedMotionEnabled then 0 else cfg.LetterboxTime
	local function setBars(scale: number)
		local info = TweenInfo.new(barTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(top, info, { Size = UDim2.fromScale(1, scale) }):Play()
		TweenService:Create(bottom, info, { Size = UDim2.fromScale(1, scale) }):Play()
	end
	if letterbox then
		setBars(cfg.LetterboxScale)
	end

	local skipGui: ScreenGui? = nil
	if skippable then
		local g = Instance.new("ScreenGui")
		g.Name = "OmegaSkip"
		g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
		g.DisplayOrder = 51
		g.ResetOnSpawn = false
		local button = Instance.new("TextButton")
		button.Name = "Skip"
		button.Text = "Skip"
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
		button.BackgroundTransparency = 0.3
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, -12, 0, 12)
		button.Size = UDim2.fromScale(0.12, 0.07)
		button.Visible = false
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 2.6
		aspect.Parent = button
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button
		local size = Instance.new("UITextSizeConstraint")
		size.MinTextSize = 12
		size.MaxTextSize = 22
		size.Parent = button
		button.Parent = g
		button.Activated:Connect(onSkip)
		g.Parent = playerGui
		skipGui = g
		task.delay(cfg.SkipAppearsAfter, function()
			if button.Parent then
				button.Visible = true
			end
		end)
	end

	return function()
		if letterbox and bars.Parent then
			setBars(0)
			task.delay(barTime + 0.05, function()
				bars:Destroy()
			end)
		else
			bars:Destroy()
		end
		if skipGui then
			skipGui:Destroy()
		end
	end
end

-- Core runner: takes a per-frame function that returns the camera CFrame and
-- FOV (or nil when done) and owns all setup and cleanup.
local function run(
	step: (elapsed: number) -> (CFrame?, number?),
	options: PlayOptions,
	defaultLetterbox: boolean
): Handle
	if active then
		active.stop()
	end
	local camera = workspace.CurrentCamera
	local saved = {
		cameraType = camera.CameraType,
		subject = camera.CameraSubject,
		fov = camera.FieldOfView,
	}
	local finished = false
	local doneSignal = Instance.new("BindableEvent")
	local started = os.clock()
	local closeOverlay: (() -> ())? = nil
	local stop: () -> ()

	local function finish(blend: boolean)
		if finished then
			return
		end
		finished = true
		pcall(RunService.UnbindFromRenderStep, RunService, RENDER_NAME)
		if closeOverlay then
			closeOverlay()
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		camera.CameraSubject = humanoid or saved.subject
		camera.CameraType = if saved.cameraType == Enum.CameraType.Scriptable
			then Enum.CameraType.Custom
			else saved.cameraType
		if blend and not GuiService.ReducedMotionEnabled then
			camera.FieldOfView = camera.FieldOfView
			TweenService:Create(camera, TweenInfo.new(cfg.BlendBackTime, Enum.EasingStyle.Sine), {
				FieldOfView = saved.fov,
			}):Play()
		else
			camera.FieldOfView = saved.fov
		end
		if active and active.stop == stop then
			active = nil
		end
		doneSignal:Fire()
		task.defer(function()
			doneSignal:Destroy()
		end)
	end
	stop = function()
		finish(false)
	end
	active = { stop = stop }

	local skippable = if options.skippable == nil then true else options.skippable
	local letterbox = if options.letterbox == nil then defaultLetterbox else options.letterbox
	closeOverlay = makeOverlay(letterbox, skippable, stop)
	camera.CameraType = Enum.CameraType.Scriptable

	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		local ok, cf, fov = pcall(step, os.clock() - started)
		if not ok then
			warn("CinematicCamera shot failed: " .. tostring(cf))
			finish(false)
			return
		end
		if cf == nil then
			finish(options.blendBack ~= false)
			return
		end
		-- The default camera scripts can flip CameraType back (seen in a Studio
		-- playtest 2026-11-19), so hold Scriptable every frame we own the camera.
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		camera.CFrame = cf
		camera.Focus = cf * CFrame.new(0, 0, -10)
		if fov then
			camera.FieldOfView = fov
		end
	end)

	local handle = {}
	function handle.stop(_self: Handle)
		stop()
	end
	function handle.wait(_self: Handle)
		if not finished then
			doneSignal.Event:Wait()
		end
	end
	function handle.playing(_self: Handle): boolean
		return not finished
	end
	return (handle :: any) :: Handle -- any: methods are attached above; the table matches Handle
end

-- Play a list of shots around a subject. Returns at once; use handle:wait().
function CinematicCamera.play(shots: { Shot }, subject: Subject, options: PlayOptions?): Handle
	local ok, err = CameraRig.validate(shots)
	assert(ok, err)
	local opts: PlayOptions = options or {}
	local reduced = GuiService.ReducedMotionEnabled
	local total = CameraRig.total(shots)
	local lastIndex = 0
	return run(function(elapsed: number)
		if elapsed >= total then
			return nil, nil
		end
		local index, alpha = CameraRig.locate(shots, elapsed)
		if index == nil then
			return nil, nil
		end
		local shot = shots[index]
		if index ~= lastIndex then
			lastIndex = index
			if opts.onShot then
				task.spawn(opts.onShot, index, shot)
			end
		end
		local pose = CameraRig.sample(shot, if reduced then 1 else alpha)
		local shake = if reduced or not shot.shake then nil else CameraRig.shake(elapsed, shot.shake, opts.seed)
		return poseToCFrame(subjectFrame(subject), pose, shake), pose.fov
	end, opts, true)
end

-- Bind the camera to a part that an animation moves (a "CameraBone" Motor6D'd
-- to the rig and keyframed with the body). Camera and body stay frame-locked,
-- which is how battleground ultimates sync camera and fighting animation
-- (DevForum: https://devforum.roblox.com/t/how-can-i-make-advanced-cut-scenes-like-battleground-games-61125/3686403).
function CinematicCamera.followPart(part: BasePart, duration: number, fov: number?, options: PlayOptions?): Handle
	local opts: PlayOptions = options or {}
	if opts.skippable == nil then
		opts.skippable = false -- ability cams are short; skipping mid-move breaks sync
	end
	duration = math.min(duration, Config.Cinematic.AbilityCamMaxSeconds)
	return run(function(elapsed: number)
		if elapsed >= duration or not part.Parent then
			return nil, nil
		end
		return part.CFrame, fov
	end, opts, false)
end

-- Play baked camera frames (one CFrame per frame at `fps`), optionally
-- relative to a subject: camera = subject * frame. This is the Moon Animator
-- export pattern (DevForum: https://devforum.roblox.com/t/camera-animations-for-cutscenes-and-gameplay/1181691).
function CinematicCamera.playFrames(
	frames: { CFrame },
	fps: number,
	relativeTo: Subject?,
	fovs: { number }?,
	options: PlayOptions?
): Handle
	assert(#frames > 0 and fps > 0, "need frames and fps")
	return run(function(elapsed: number)
		local i = math.floor(elapsed * fps) + 1
		if i > #frames then
			return nil, nil
		end
		local cf = frames[i]
		if relativeTo then
			cf = subjectFrame(relativeTo) * cf
		end
		return cf, if fovs then fovs[math.min(i, #fovs)] else nil
	end, options or {}, true)
end

function CinematicCamera.stop()
	if active then
		active.stop()
	end
end

function CinematicCamera.isPlaying(): boolean
	return active ~= nil
end

return CinematicCamera
