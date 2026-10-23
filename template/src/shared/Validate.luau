--!strict
-- Payload checks for remotes. Pure (only `typeof` on Roblox values), so the
-- number/string checks run under Lune tests. NaN fails every comparison, so a
-- plain range check silently lets it through: always use `finiteNumber`.

local Validate = {}

function Validate.finiteNumber(value: any, min: number?, max: number?): boolean
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return false
	end
	if min and value < min then
		return false
	end
	if max and value > max then
		return false
	end
	return true
end

function Validate.integer(value: any, min: number?, max: number?): boolean
	return Validate.finiteNumber(value, min, max) and value % 1 == 0
end

function Validate.shortString(value: any, maxLength: number): boolean
	return type(value) == "string" and #value <= maxLength and utf8.len(value) ~= nil
end

function Validate.oneOf(value: any, allowed: { [any]: boolean }): boolean
	return value ~= nil and allowed[value] == true
end

-- Instance must exist and live under `container` (e.g. workspace.Shops).
function Validate.descendantOf(value: any, container: Instance): boolean
	return typeof(value) == "Instance" and value:IsDescendantOf(container)
end

return Validate
