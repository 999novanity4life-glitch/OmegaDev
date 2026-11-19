--!strict
-- Plays a CombatFeel recipe on this client: hit-stop, camera shake, FOV kick,
-- impact frames, slow-mo, particle bursts, speed lines and a pitched hit sound.
-- Everything is cosmetic; the server already decided the hit.
--
-- [DOC] AnimationTrack:AdjustSpeed(0) pauses, positive resumes:
--   https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
-- [DOC] ParticleEmitter:Emit(n), ParticleEmitter.TimeScale (0..1):
--   https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
-- [DOC] post effects parented to the Camera affect only this player:
--   docs/rulebooks/ANIMATION_CUTSCENE_RULEBOOK.md rule 7
-- [COMMUNITY] VFX packs store burst sizes on each emitter as attributes
--   (EmitCount, EmitDelay) and "emit all" descendants; we follow that
--   convention so marketplace and Blender-made effects drop in unchanged.
-- Not yet run in Studio when written: see docs/VISUAL_QA.md.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CombatFeel = require(Shared:WaitForChild("CombatFeel"))
local Juice = require(script.Parent.Juice)

type Recipe = CombatFeel.Recipe
type Tier = CombatFeel.Tier

local ImpactFX = {}

local player = Players.LocalPlayer
local frozenTracks: { [AnimationTrack]: number } = {}

-- Freeze tracks for `seconds`, then restore each one's own speed. Overlapping
-- calls keep the original speed instead of restoring to 0.
function ImpactFX.hitStop(tracks: { AnimationTrack }, seconds: number)
	if seconds <= 0 then
		return
	end
	for _, track in tracks do
		if frozenTracks[track] == nil and track.IsPlaying then
			frozenTracks[track] = track.Speed
			track:AdjustSpeed(0)
		end
	end
	task.delay(seconds, function()
		for _, track in tracks do
			local speed = frozenTracks[track]
			if speed ~= nil then
				frozenTracks[track] = nil
				track:AdjustSpeed(speed)
			end
		end
	end)
end

-- Every playing track on a character or NPC (its Animator).
function ImpactFX.tracksOf(model: Model?): { AnimationTrack }
	if not model then
		return {}
	end
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	return if animator then animator:GetPlayingAnimationTracks() else {}
end

-- Burst every ParticleEmitter under `root`. Count = EmitCount attribute (or
-- `fallback`) * multiplier; EmitDelay attribute delays that emitter.
function ImpactFX.emitAll(root: Instance, multiplier: number?, fallback: number?)
	local mult = multiplier or 1
	for _, d in root:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			local count = d:GetAttribute("EmitCount")
			local n = math.max(1, math.floor((if type(count) == "number" then count else fallback or 12) * mult))
			local delay = d:GetAttribute("EmitDelay")
			if type(delay) == "number" and delay > 0 then
				task.delay(delay, function()
					if d.Parent then
						d:Emit(n)
					end
				end)
			else
				d:Emit(n)
			end
		end
	end
end

-- Clone an effect template at a CFrame, burst it, clean it up. Templates are
-- Parts/Models holding Attachments with emitters set Enabled = false.
function ImpactFX.spawnAt(template: Instance, at: CFrame, multiplier: number?, lifetime: number?): Instance
	local fx = template:Clone()
	if fx:IsA("BasePart") then
		fx.Anchored = true
		fx.CanCollide = false
		fx.CanQuery = false
		fx.CFrame = at
	elseif fx:IsA("Model") then
		fx:PivotTo(at)
	end
	fx.Parent = workspace
	ImpactFX.emitAll(fx, multiplier)
	task.delay(lifetime or 3, function()
		fx:Destroy()
	end)
	return fx
end

-- Quick FOV punch out and back (adds to whatever the camera has now).
function ImpactFX.fovKick(degrees: number, seconds: number?)
	if degrees == 0 or GuiService.ReducedMotionEnabled then
		return
	end
	local camera = workspace.CurrentCamera
	local base = camera.FieldOfView
	local t = seconds or 0.25
	camera.FieldOfView = math.clamp(base + degrees, 1, 120)
	TweenService:Create(camera, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = base,
	}):Play()
end

-- Impact frames: N rendered frames of a high-contrast, desaturated, inverted
-- look, the anime "freeze on the hit" beat. Uses a ColorCorrectionEffect under
-- the Camera so only this player sees it.
function ImpactFX.impactFrames(frames: number, style: ("Invert" | "Flash")?)
	if frames <= 0 or GuiService.ReducedMotionEnabled then
		return
	end
	local camera = workspace.CurrentCamera
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "OmegaImpactFrame"
	if style == "Flash" then
		cc.Brightness = 0.6
		cc.Contrast = 1
		cc.Saturation = -1
	else
		cc.Brightness = -0.1
		cc.Contrast = 3
		cc.Saturation = -1
		cc.TintColor = Color3.fromRGB(255, 235, 220)
	end
	cc.Parent = camera
	local count = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		count += 1
		if count == math.ceil(frames / 2) and style ~= "Flash" then
			cc.Brightness = 0.25 -- second half flips toward white, a two-tone hit frame
		end
		if count >= frames then
			connection:Disconnect()
			cc:Destroy()
		end
	end)
end

-- Slow motion on the world's effects for `seconds`: particle TimeScale and
-- the given tracks' speed. (Physics and other players keep real time.)
function ImpactFX.slowMo(seconds: number, scale: number, tracks: { AnimationTrack }?, root: Instance?)
	if seconds <= 0 or scale >= 1 or GuiService.ReducedMotionEnabled then
		return
	end
	local emitters: { ParticleEmitter } = {}
	for _, d in (root or workspace):GetDescendants() do
		if d:IsA("ParticleEmitter") and d.TimeScale >= 1 then
			d.TimeScale = scale
			table.insert(emitters, d)
		end
	end
	local saved: { [AnimationTrack]: number } = {}
	local list: { AnimationTrack } = tracks or {}
	for _, track in list do
		saved[track] = track.Speed
		track:AdjustSpeed(track.Speed * scale)
	end
	task.delay(seconds, function()
		for _, e in emitters do
			if e.Parent then
				e.TimeScale = 1
			end
		end
		for track, speed in saved do
			track:AdjustSpeed(speed)
		end
	end)
end

-- Radial speed lines for dashes and ultimates: thin bars around the screen
-- edge that streak and fade. Pure UI, no texture assets needed.
function ImpactFX.speedLines(seconds: number, color: Color3?, count: number?)
	if GuiService.ReducedMotionEnabled then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "OmegaSpeedLines"
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = 40
	gui.ResetOnSpawn = false
	local n = count or 28
	local rng = Random.new()
	for i = 1, n do
		local angle = (i / n) * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local line = Instance.new("Frame")
		line.BorderSizePixel = 0
		line.BackgroundColor3 = color or Color3.new(1, 1, 1)
		line.BackgroundTransparency = 0.2
		line.AnchorPoint = Vector2.new(0, 0.5)
		local r = rng:NextNumber(0.42, 0.55)
		line.Position = UDim2.fromScale(0.5 + math.cos(angle) * r, 0.5 + math.sin(angle) * r)
		line.Size = UDim2.new(rng:NextNumber(0.25, 0.45), 0, 0, rng:NextInteger(2, 5))
		line.Rotation = math.deg(angle)
		line.Parent = gui
		TweenService:Create(line, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5 + math.cos(angle) * (r - 0.12), 0.5 + math.sin(angle) * (r - 0.12)),
		}):Play()
	end
	gui.Parent = player:WaitForChild("PlayerGui")
	task.delay(seconds + 0.05, function()
		gui:Destroy()
	end)
end

-- One-shot sound at a pitch (combo hits climb).
function ImpactFX.sound(soundId: string, pitch: number, volume: number?)
	if soundId == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume or 0.6
	s.PlaybackSpeed = pitch
	s.Parent = SoundService
	s.Ended:Once(function()
		s:Destroy()
	end)
	s:Play()
end

export type HitContext = {
	attacker: Model?,
	victim: Model?,
	at: CFrame?, -- where the hit landed
	effect: Instance?, -- VFX template to spawn at `at`
	soundId: string?,
	isLocalAttacker: boolean?, -- camera effects only for the attacker and the victim
}

-- Play a whole hit. Call it from the client that should feel it.
function ImpactFX.hit(tier: Tier, combo: number, ctx: HitContext): Recipe
	local recipe = CombatFeel.forHit(Config.Feel, tier, combo, GuiService.ReducedMotionEnabled)
	local tracks = ImpactFX.tracksOf(ctx.attacker)
	for _, t in ImpactFX.tracksOf(ctx.victim) do
		table.insert(tracks, t)
	end
	ImpactFX.hitStop(tracks, recipe.hitStop)
	if ctx.effect and ctx.at then
		ImpactFX.spawnAt(ctx.effect, ctx.at, recipe.particles)
	end
	if ctx.soundId then
		ImpactFX.sound(ctx.soundId, recipe.pitch)
	end
	local localCharacter = player.Character
	local feelsIt = ctx.isLocalAttacker or (ctx.victim ~= nil and ctx.victim == localCharacter)
	if feelsIt then
		Juice.shakeCamera(recipe.shake)
		ImpactFX.fovKick(recipe.fovKick)
		ImpactFX.impactFrames(recipe.impactFrames)
		if recipe.slowMo > 0 then
			task.delay(recipe.hitStop, function()
				ImpactFX.slowMo(recipe.slowMo, recipe.slowMoScale, tracks)
			end)
		end
	end
	return recipe
end

return ImpactFX
