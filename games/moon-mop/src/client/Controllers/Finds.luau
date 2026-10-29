--!strict
-- How the Moon's flags and probes look to you: flags you have untangled stand up straight with the
-- cloth flying, probes stay buried (only the dish pokes out of the dust) until their hex is
-- swept, and prompts you have already done are hidden. The server keeps the real lists.

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local State = require(script.Parent.State)

local Finds = {}

local function setFlag(model: Model, done: boolean)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			if p.Name == "Tangle" or p.Name == "Pole" then
				p.Transparency = if done then 1 else 0
			elseif p.Name == "Straight" or p.Name == "Cloth" then
				p.Transparency = if done then 0 else 1
			end
		end
	end
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = not done
	end
end

local function setProbe(model: Model, done: boolean)
	local uncovered = model:GetAttribute("Uncovered") == true
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "Body" or p.Name == "Panel") then
			p.LocalTransparencyModifier = if uncovered then 0 else 1
		end
	end
	local beacon = model:FindFirstChild("Beacon") :: BasePart?
	if beacon then
		beacon.Color = if done then Color3.fromRGB(80, 230, 130) else Color3.fromRGB(255, 132, 28)
	end
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt and done then
		prompt.Enabled = false
	end
end

local function refresh()
	local folder = Workspace:FindFirstChild("Finds")
	if not folder then
		return
	end
	local s = State.get()
	for _, m in folder:GetChildren() do
		if m:IsA("Model") then
			local key = tostring(m:GetAttribute("Index"))
			if m:GetAttribute("Find") == "flag" then
				setFlag(m, s.flags ~= nil and s.flags[key] == true)
			else
				setProbe(m, s.probes ~= nil and s.probes[key] == true)
			end
		end
	end
end

function Finds.start()
	task.spawn(function()
		local folder = Workspace:WaitForChild("Finds", 60)
		if not folder then
			return
		end
		State.changed(refresh)
		folder.ChildAdded:Connect(function()
			task.defer(refresh)
		end)
		for _, m in folder:GetChildren() do
			m:GetAttributeChangedSignal("Uncovered"):Connect(refresh)
		end
		folder.ChildAdded:Connect(function(m)
			m:GetAttributeChangedSignal("Uncovered"):Connect(refresh)
		end)
	end)
	-- the flag pops upright with a little shake of the cloth
	State.onFeedback(function(kind: string, data: any)
		if kind ~= "Find" or data.kind ~= "flag" then
			return
		end
		local folder = Workspace:FindFirstChild("Finds")
		local m = folder and folder:FindFirstChild("Flag" .. tostring(data.index)) :: Model?
		if not m or GuiService.ReducedMotionEnabled then
			return
		end
		for _, p in m:GetChildren() do
			if p:IsA("BasePart") and p.Name == "Cloth" then
				local base = p.CFrame
				p.CFrame = base * CFrame.Angles(0, math.rad(50), 0)
				TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Elastic), { CFrame = base }):Play()
			end
		end
	end)
end

return Finds
