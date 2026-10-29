--!strict
-- Every purchase: supply wall (tools, Bigger Packs, belt slots, pod carry), the Upgrade Board,
-- the Garage (vehicles and their upgrades), the Build Tool and suit gear. The server checks the
-- catalog, the price, the requirements and that the player is standing at the right place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Loadout = require(Shared:WaitForChild("Loadout"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))
local Validate = require(Shared:WaitForChild("Validate"))

local Crew = require(script.Parent.Crew)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Zones = require(script.Parent.Zones)

local Shop = {}

local KINDS = {
	tool = true,
	beltSet = true,
	packUp = true,
	slot = true,
	carry = true,
	upgrade = true,
	garage = true,
	vehicle = true,
	vehicleUp = true,
	buildTool = true,
	gear = true,
}

local GEAR = { Jetpack = true, GravityBoots = true, NightVision = true }

local function needZone(s: Crew.Session, kind: string, label: string): boolean
	if Zones.near(s.player, kind) then
		return true
	end
	Crew.feedback(s.player, "Error", { text = "Go to " .. label .. " to buy that" })
	return false
end

local function bought(s: Crew.Session, what: string, extra: any?)
	s.dirty = true
	Crew.feedback(s.player, "Bought", { what = what, extra = extra })
end

local handlers: { [string]: (s: Crew.Session, a: any, b: any) -> () } = {}

handlers.tool = function(s, id)
	local def = Loadout.tool(id)
	if not def or s.data.tools[id] or not needZone(s, "supply", "a supply wall") then
		return
	end
	if not Crew.spend(s, Economy.price(def.price, s.fx), def.name) then
		return
	end
	s.data.tools[id] = true
	-- straight onto the belt: a free slot, else replace the equipped tool
	if #s.data.belt < s.data.slots then
		table.insert(s.data.belt, id)
		s.data.equipped = #s.data.belt
	else
		s.data.belt[s.data.equipped] = id
	end
	s.packKg = math.min(s.packKg, (select(2, Crew.equippedTool(s)) :: Loadout.ToolStats).pack)
	bought(s, "tool", id)
	if def.look ~= "Junk" then
		Crew.feedback(s.player, "Reveal", { kind = "tool", id = id })
	end
end

handlers.beltSet = function(s, id, slot)
	if not s.data.tools[id] or not Validate.integer(slot, 1, s.data.slots) then
		return
	end
	local belt = s.data.belt
	local at = table.find(belt, id)
	if at then
		belt[at], belt[slot] = belt[slot], belt[at]
		if belt[at] == nil then
			table.remove(belt, at)
		end
	elseif slot > #belt then
		table.insert(belt, id)
	else
		belt[slot] = id
	end
	s.data.equipped = math.clamp(table.find(belt, id) or 1, 1, #belt)
	s.dirty = true
end

handlers.packUp = function(s, id)
	local def = Loadout.tool(id)
	if not def or not s.data.tools[id] or s.data.packUps[id] or not needZone(s, "supply", "a supply wall") then
		return
	end
	if Crew.spend(s, Economy.price(Economy.packUpgradeCost(def), s.fx), "Bigger Pack") then
		s.data.packUps[id] = true
		bought(s, "packUp", id)
	end
end

handlers.slot = function(s)
	local nextSlot = s.data.slots + 1
	local price = Economy.slotPrice(nextSlot)
	if not price or not needZone(s, "supply", "a supply wall") then
		return
	end
	if Crew.spend(s, Economy.price(price, s.fx), "a belt slot") then
		s.data.slots = nextSlot
		bought(s, "slot", nextSlot)
	end
end

handlers.carry = function(s)
	local price = Economy.carryPrice(s.data.carryBought)
	if not price or not needZone(s, "supply", "a supply wall") then
		return
	end
	if Crew.spend(s, Economy.price(price, s.fx), "a pod strap") then
		s.data.carryBought += 1
		bought(s, "carry", s.data.carryBought)
	end
end

handlers.upgrade = function(s, id)
	if not needZone(s, "board", "an Upgrade Board") then
		return
	end
	local hasPackUp = next(s.data.packUps) ~= nil
	local ok, why, price = Upgrades.check(s.data.upgrades, id, { packUpgrade = hasPackUp })
	if not ok then
		Crew.feedback(s.player, "Error", { text = why })
		return
	end
	local def = Upgrades.get(id) :: Config.UpgradeDef
	if Crew.spend(s, price, def.name) then
		s.data.upgrades[id] = (s.data.upgrades[id] or 0) + 1
		Crew.refreshEffects(s)
		bought(s, "upgrade", id)
	end
end

handlers.garage = function(s)
	if s.data.garage then
		return
	end
	if Crew.spend(s, Economy.price(Config.GaragePrice, s.fx), "the Garage") then
		s.data.garage = true
		bought(s, "garage", nil)
	end
end

handlers.vehicle = function(s, id)
	local def = Loadout.vehicle(id)
	if not def or s.data.vehicles[id] or not s.data.garage then
		return
	end
	if not needZone(s, "garage", "your Garage") then
		return
	end
	if Crew.spend(s, Economy.price(def.price, s.fx), def.name) then
		s.data.vehicles[id] = {}
		bought(s, "vehicle", id)
		Crew.feedback(s.player, "Reveal", { kind = "vehicle", id = id })
	end
end

handlers.vehicleUp = function(s, id, upId)
	local def = Loadout.vehicle(id)
	local ups = s.data.vehicles[id]
	if not def or not ups or not needZone(s, "garage", "your Garage") then
		return
	end
	for _, u in Config.VehicleUpgrades.List do
		if u.id == upId then
			local level = (ups[upId] or 0) + 1
			if level > u.max then
				return
			end
			if Crew.spend(s, Economy.price(Economy.vehicleUpgradeCost(def.price, level), s.fx), u.name) then
				ups[upId] = level
				bought(s, "vehicleUp", { id, upId })
			end
			return
		end
	end
end

handlers.buildTool = function(s)
	if s.data.buildTool or not needZone(s, "supply", "a supply wall") then
		return
	end
	if Crew.spend(s, Economy.price(Config.BuildToolPrice, s.fx), "the Build Tool") then
		s.data.buildTool = true
		bought(s, "buildTool", nil)
		Crew.feedback(s.player, "Reveal", { kind = "buildTool" })
	end
end

handlers.gear = function(s, id)
	local spec = (Config.Gear :: any)[id]
	if not GEAR[id] or not spec or s.data.gear[id] or not needZone(s, "supply", "a supply wall") then
		return
	end
	if Crew.spend(s, Economy.price(spec.price, s.fx), id) then
		s.data.gear[id] = true
		bought(s, "gear", id)
	end
end

RemoteGuard.connect(Remotes.get("Buy"), function(kind: any, a: any, b: any)
	if not Validate.oneOf(kind, KINDS) then
		return false
	end
	if a ~= nil and not Validate.shortString(a, 40) then
		return false
	end
	if b ~= nil and not (Validate.shortString(b, 40) or Validate.integer(b, 1, 6)) then
		return false
	end
	return true
end, function(player: Player, kind: string, a: any, b: any)
	local s = Crew.get(player)
	if s then
		handlers[kind](s, a, b)
	end
end)

-- Suit and gear toggles (cosmetic or owned gear).
RemoteGuard.connect(Remotes.get("Customize"), function(visor: any, colour: any)
	return Validate.integer(visor, 1, Config.Gear.VisorStyles) and Validate.integer(colour, 1, #Config.Gear.SuitColours)
end, function(player: Player, visor: number, colour: number)
	local s = Crew.get(player)
	if s then
		s.data.suit = { visor = visor, colour = colour }
		s.dirty = true
		Crew.syncCharacter(s)
	end
end)

RemoteGuard.connect(Remotes.get("Gear"), function(id: any, on: any)
	return Validate.oneOf(id, GEAR) and type(on) == "boolean"
end, function(player: Player, id: string, on: boolean)
	local s = Crew.get(player)
	if s and s.data.gear[id] then
		s.data.gear[id .. "On"] = on
		s.dirty = true
		Crew.syncCharacter(s)
	end
end)

RemoteGuard.connect(Remotes.get("Story"), function(step: any)
	return step == "hired"
end, function(player: Player)
	local s = Crew.get(player)
	if s and not s.data.hired then
		s.data.hired = true
		s.dirty = true
	end
end)

return Shop
