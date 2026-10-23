--!strict
-- Screen3D: renders a full-screen SurfaceGui on an invisible part locked in front of the
-- camera, so 2D UI gets real perspective and can tilt toward the mouse.
-- Built from documented parts (SurfaceGui + Adornee in PlayerGui, Camera:ViewportPointToRay).
-- Lives at ReplicatedStorage.Screen3D. Tested in Studio 2026-10-23 (renders, tilts, no errors).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DIST = 3 -- studs in front of the camera (DepthOfField focuses here)
local SMOOTH = 8 -- higher = snappier tilt follow
local RES = 2 -- canvas pixels per screen pixel; 2 keeps text crisp after the tilt resamples it

local Screen3D = {}
Screen3D.__index = Screen3D

export type Screen3D = {
	part: Part,
	gui: SurfaceGui,
	tiltPower: number, -- degrees at the screen edge
	tiltEnabled: boolean,
	_yaw: number,
	_pitch: number,
	_conn: RBXScriptConnection?,
}

function Screen3D.new(name: string, tiltPower: number?): Screen3D
	local cam = workspace.CurrentCamera
	local part = Instance.new("Part")
	part.Name = name .. "_Screen3D"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 0.05)
	part.Parent = cam

	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = Enum.NormalId.Back -- the face pointing at the camera
	-- AlwaysOnTop stays false: AlwaysOnTop SurfaceGuis on a camera-locked part did not render
	-- in testing (2026-10-23). Background blur therefore uses DepthOfField, not BlurEffect,
	-- because BlurEffect would blur this surface too.
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false
	gui.Adornee = part
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 10)

	local self = setmetatable({
		part = part,
		gui = gui,
		tiltPower = tiltPower or 3,
		tiltEnabled = true,
		_yaw = 0,
		_pitch = 0,
		_conn = nil,
	}, Screen3D) :: any
	self._conn = RunService.RenderStepped:Connect(function(dt)
		Screen3D._step(self, dt)
	end)
	Screen3D._step(self, 1)
	return self
end

function Screen3D._step(self: Screen3D, dt: number)
	local cam = workspace.CurrentCamera
	local vp = cam.ViewportSize
	if vp.Y < 1 then
		return
	end
	-- SurfaceGui input needs a raycast hit on the part, so it is queryable only while shown
	-- (otherwise it would block world clicks and camera raycasts).
	self.part.CanQuery = self.gui.Enabled
	local h = 2 * DIST * math.tan(math.rad(cam.FieldOfView) / 2)
	local w = h * vp.X / vp.Y
	self.part.Size = Vector3.new(w, h, 0.05)
	self.gui.CanvasSize = vp * RES

	local ty, tp = 0, 0
	if self.tiltEnabled and self.tiltPower > 0 then
		local m = UserInputService:GetMouseLocation()
		local nx = math.clamp(m.X / vp.X * 2 - 1, -1, 1)
		local ny = math.clamp(m.Y / vp.Y * 2 - 1, -1, 1)
		ty = -nx * self.tiltPower -- side nearest the cursor comes toward the camera
		tp = -ny * self.tiltPower
	end
	local a = 1 - math.exp(-dt * SMOOTH)
	self._yaw += (ty - self._yaw) * a
	self._pitch += (tp - self._pitch) * a
	self.part.CFrame = cam.CFrame
		* CFrame.new(0, 0, -DIST)
		* CFrame.Angles(math.rad(self._pitch), math.rad(self._yaw), 0)
end

-- Screen pixel (GetMouseLocation space) -> canvas pixel on the tilted surface.
function Screen3D.screenToCanvas(self: Screen3D, p: Vector2): Vector2?
	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(p.X, p.Y)
	local cf = self.part.CFrame
	local n = cf.LookVector
	local denom = ray.Direction:Dot(n)
	if math.abs(denom) < 1e-6 then
		return nil
	end
	local t = (cf.Position - ray.Origin):Dot(n) / denom
	local l = cf:PointToObjectSpace(ray.Origin + ray.Direction * t)
	local s = self.part.Size
	local vp = self.gui.CanvasSize
	return Vector2.new((l.X / s.X + 0.5) * vp.X, (0.5 - l.Y / s.Y) * vp.Y)
end

Screen3D.DIST = DIST
Screen3D.RES = RES

function Screen3D.destroy(self: Screen3D)
	if self._conn then
		self._conn:Disconnect()
	end
	self.gui:Destroy()
	self.part:Destroy()
end

return Screen3D
