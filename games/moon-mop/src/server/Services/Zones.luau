--!strict
-- Named spots the server checks distance against before it accepts a request: supply walls,
-- Upgrade Boards, deposit drums, garages, teleport pads. World builders register them.

local Zones = {}

type Zone = { position: Vector3, radius: number, owner: number? }
local zones: { [string]: { Zone } } = {}

function Zones.add(kind: string, position: Vector3, radius: number, owner: number?)
	zones[kind] = zones[kind] or {}
	table.insert(zones[kind], { position = position, radius = radius, owner = owner })
end

function Zones.removeOwned(kind: string, owner: number)
	local list = zones[kind]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i].owner == owner then
			table.remove(list, i)
		end
	end
end

function Zones.list(kind: string): { Zone }
	return zones[kind] or {}
end

-- Is the player's character inside a zone of this kind (and, if the zone has an owner, theirs)?
function Zones.near(player: Player, kind: string): (boolean, Vector3?)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, nil
	end
	local list: { Zone } = zones[kind] or {}
	for _, z in list do
		if (z.owner == nil or z.owner == player.UserId) and (root.Position - z.position).Magnitude <= z.radius then
			return true, z.position
		end
	end
	return false, nil
end

return Zones
