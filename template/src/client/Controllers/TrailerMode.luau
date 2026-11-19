--!strict
-- Studio-only "director" for capturing trailer and store-video footage.
-- It cleans the frame (hides game UI, CoreGui and name plates), plays a
-- named shot list, and opens every take with a 0.5 s pure-black slate so the
-- edit script can find the exact start of each take in a long screen
-- recording (ffmpeg blackdetect, see trailer/README.md).
--
-- Drive it from the Studio MCP during a playtest:
--   execute_luau (client): require(game.Players.LocalPlayer.PlayerScripts.Client.Controllers.TrailerMode).take("ult_reveal", shots, subject)
-- Console lines "OMEGA_TAKE <name> <seconds>" give each take's shot timings.
--
-- [DOC] Store videos must show real gameplay; varied camera angles are fine,
--   added voice-over and misleading visuals are not:
--   https://create.roblox.com/docs/production/publishing/thumbnails
-- Not yet run in Studio when written: see docs/VISUAL_QA.md.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CameraRig = require(Shared:WaitForChild("CameraRig"))
local CinematicCamera = require(script.Parent.CinematicCamera)

type Shot = CameraRig.Shot

local TrailerMode = {}

local player = Players.LocalPlayer
local SLATE_SECONDS = 0.5
local hidden: { [Instance]: boolean } = {}
local hiddenHumanoids: { [Humanoid]: Enum.HumanoidDisplayDistanceType } = {}
local clean = false

local function assertStudio()
	assert(RunService:IsStudio(), "TrailerMode only runs in Studio")
end

-- Hide (true) or restore (false) everything that isn't the world.
function TrailerMode.setClean(on: boolean)
	assertStudio()
	if on == clean then
		return
	end
	clean = on
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not on)
	end)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if on then
		if playerGui then
			for _, g in playerGui:GetChildren() do
				if g:IsA("ScreenGui") and g.Enabled and not string.match(g.Name, "^Omega") then
					hidden[g] = true
					g.Enabled = false
				end
			end
		end
		for _, d in workspace:GetDescendants() do
			if d:IsA("Humanoid") then
				hiddenHumanoids[d] = d.DisplayDistanceType
				d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			elseif d:IsA("BillboardGui") and d.Enabled and d:GetAttribute("TrailerKeep") ~= true then
				hidden[d] = true
				d.Enabled = false
			end
		end
	else
		for g in hidden do
			if g.Parent then
				(g :: any).Enabled = true -- any: ScreenGui and BillboardGui both have Enabled
			end
		end
		table.clear(hidden)
		for h, kind in hiddenHumanoids do
			if h.Parent then
				h.DisplayDistanceType = kind
			end
		end
		table.clear(hiddenHumanoids)
	end
end

local function slate()
	local gui = Instance.new("ScreenGui")
	gui.Name = "OmegaSlate"
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = 1000
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	task.wait(SLATE_SECONDS)
	gui:Destroy()
end

-- One take: clean frame, black slate, the shots (no letterbox, no Skip), and
-- a printed shot log. Yields until the take ends.
function TrailerMode.take(name: string, shots: { Shot }, subject: CinematicCamera.Subject)
	assertStudio()
	TrailerMode.setClean(true)
	slate()
	local started = os.clock()
	print(string.format("OMEGA_TAKE %s start", name))
	local handle = CinematicCamera.play(shots, subject, {
		letterbox = false,
		skippable = false,
		blendBack = false,
		onShot = function(i: number, shot: Shot)
			print(string.format("OMEGA_TAKE %s shot=%d %s t=%.3f", name, i, shot.name, os.clock() - started))
		end,
	})
	handle:wait()
	print(string.format("OMEGA_TAKE %s end t=%.3f", name, os.clock() - started))
end

return TrailerMode
