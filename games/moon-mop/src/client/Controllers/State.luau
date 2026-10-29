--!strict
-- The player's latest authoritative state from the server, and the server's feedback events.
-- Controllers read State.get() and subscribe with State.changed / State.onFeedback.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local State = {}

local current: { [string]: any } = { money = 0, pack = 0, packMax = 2, pods = 0, carry = 3, belt = { "Toothbrush" } }
local listeners: { (state: { [string]: any }, previous: { [string]: any }) -> () } = {}
local feedback: { (kind: string, data: any) -> () } = {}
local received = false

function State.get(): { [string]: any }
	return current
end

function State.ready(): boolean
	return received
end

function State.changed(fn: (state: { [string]: any }, previous: { [string]: any }) -> ())
	table.insert(listeners, fn)
	if received then
		task.spawn(fn, current, current)
	end
end

function State.onFeedback(fn: (kind: string, data: any) -> ())
	table.insert(feedback, fn)
end

-- Local events (menus opening, cutscenes) go through the same channel.
function State.emit(kind: string, data: any?)
	for _, fn in feedback do
		task.spawn(fn, kind, data)
	end
end

function State.start()
	Remotes.get("State").OnClientEvent:Connect(function(state: { [string]: any })
		local previous = current
		current = state
		received = true
		for _, fn in listeners do
			task.spawn(fn, state, previous)
		end
	end)
	Remotes.get("Feedback").OnClientEvent:Connect(function(kind: string, data: any)
		State.emit(kind, data)
	end)
end

return State
