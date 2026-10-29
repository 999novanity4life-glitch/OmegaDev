--!strict
-- The belt network on a Mop Base. Pods ride belts from Collector Pads, Pod Packers and Dot Bot
-- docks, through splitters, mergers, lifts, Glass Ovens and Gem Presses, to a Pod Cannon that
-- sells them. Pure module: the server builds a net from a plot's buildings and ticks it, and
-- clients draw the pods it reports.
--
-- Linking rules (plot space, 4-stud tiles):
--   a conveyor hands its pod to whatever is just past its front edge (a splitter uses its left and
--   right edges, a lift jumps over the next tile so belts can cross);
--   a source or machine feeds any conveyor whose back edge touches it, and anything that accepts
--   pods just past its own front edge.

local Config = require(script.Parent.Config)
local Factory = require(script.Parent.Factory)
local Plot = require(script.Parent.Plot)

type Effects = { [string]: number }

export type Kind = "Dust" | "Stardust" | "Glass" | "Gem"
export type Item = { id: number, kind: Kind, kg: number }
export type Node = {
	uid: number,
	id: string,
	x: number,
	z: number,
	r: number,
	w: number,
	d: number,
	item: Item?, -- conveyors carry one pod at a time
	progress: number, -- 0..1 along the conveyor
	store: { [string]: number }, -- sources and machines: kg waiting, by kind ("out" = made)
	outs: { Node },
	turn: number,
	cool: number,
}
export type Net = { nodes: { [number]: Node }, list: { Node }, nextItem: number }
export type Sold = { kind: Kind, kg: number }
export type PodView = { id: number, x: number, z: number, h: number, kind: Kind }

local A = Config.Automation
local BUFFER_KG = 40 -- how much a machine holds waiting to be worked

local CONVEYOR = { Belt = true, Lift = true, Splitter = true, Merger = true }
local SOURCE = { CollectorPad = true, PodPacker = true, DotBotMk1 = true, DotBotMk2 = true }
local MACHINE = { GlassOven = true, GemPress = true }

local Belts = {}
Belts.BUFFER_KG = BUFFER_KG

function Belts.isConveyor(id: string): boolean
	return CONVEYOR[id] == true
end

function Belts.isSource(id: string): boolean
	return SOURCE[id] == true
end

-- Half the node's extent along a plot-space direction.
local function halfAlong(n: Node, fx: number, fz: number): number
	return if fx ~= 0 then n.w / 2 else n.d / 2
end

local function contains(n: Node, px: number, pz: number): boolean
	return math.abs(px - n.x) * 2 < n.w and math.abs(pz - n.z) * 2 < n.d
end

local function nodeAt(net: Net, px: number, pz: number, not_: Node): Node?
	for _, n in net.list do
		if n ~= not_ and contains(n, px, pz) then
			return n
		end
	end
	return nil
end

-- The point just past one edge of a node, `extra` studs further out. 1.5 studs reaches across the
-- one-stud gap left between a 4-stud belt on the 2-stud grid and an odd-sized building.
local function edgePoint(n: Node, r: number, extra: number): (number, number)
	local fx, fz = Plot.facing(r)
	local h = halfAlong(n, fx, fz) + 1.5 + extra
	return n.x + fx * h, n.z + fz * h
end

local function addOut(from: Node, to: Node)
	if not table.find(from.outs, to) then
		table.insert(from.outs, to)
	end
end

local function accepts(n: Node, item: Item): boolean
	if CONVEYOR[n.id] then
		return n.item == nil
	elseif n.id == "PodCannon" then
		return true
	elseif n.id == "GlassOven" then
		return item.kind == "Dust" and (n.store.Dust or 0) < BUFFER_KG
	elseif n.id == "GemPress" then
		return (item.kind == "Dust" or item.kind == "Glass") and (n.store[item.kind] or 0) < BUFFER_KG
	end
	return false
end

local function receive(n: Node, item: Item, sold: { Sold })
	if CONVEYOR[n.id] then
		n.item = item
		n.progress = 0
	elseif n.id == "PodCannon" then
		table.insert(sold, { kind = item.kind, kg = item.kg })
	else
		n.store[item.kind] = (n.store[item.kind] or 0) + item.kg
	end
end

-- Hand an item to the next output that takes it, round robin. True if it went.
local function push(n: Node, item: Item, sold: { Sold }): boolean
	local count = #n.outs
	for k = 0, count - 1 do
		local i = (n.turn + k - 1) % count + 1
		local to = n.outs[i]
		if accepts(to, item) then
			receive(to, item, sold)
			n.turn = i % count + 1
			return true
		end
	end
	return false
end

-- Build the net for a plot's buildings. Pass the previous net to keep pods and stores of
-- buildings that are still there.
function Belts.build(buildings: { Plot.Building }, previous: Net?): Net
	local net: Net = { nodes = {}, list = {}, nextItem = if previous then previous.nextItem else 1 }
	for _, b in buildings do
		local def = Plot.def(b.id)
		if not def or not (CONVEYOR[b.id] or SOURCE[b.id] or MACHINE[b.id] or b.id == "PodCannon") then
			continue
		end
		local w, d = Plot.footprint(def, b.r)
		local old = previous and previous.nodes[b.uid]
		local n: Node = {
			uid = b.uid,
			id = b.id,
			x = b.x,
			z = b.z,
			r = b.r,
			w = w,
			d = d,
			item = if old then old.item else nil,
			progress = if old then old.progress else 0,
			store = if old then old.store else {},
			outs = {},
			turn = 1,
			cool = 0,
		}
		net.nodes[b.uid] = n
		table.insert(net.list, n)
	end
	for _, n in net.list do
		if CONVEYOR[n.id] then
			local fronts: { number } = if n.id == "Splitter" then { n.r + 3, n.r + 1 } else { n.r }
			for _, r in fronts do
				local px, pz = edgePoint(n, r, if n.id == "Lift" then Plot.TILE else 0)
				local to = nodeAt(net, px, pz, n)
				if to and not SOURCE[to.id] then
					addOut(n, to)
				end
			end
			local bx, bz = edgePoint(n, n.r + 2, 0)
			local from = nodeAt(net, bx, bz, n)
			if from and (SOURCE[from.id] or MACHINE[from.id]) then
				addOut(from, n)
			end
		elseif SOURCE[n.id] or MACHINE[n.id] then
			local px, pz = edgePoint(n, n.r, 0)
			local to = nodeAt(net, px, pz, n)
			if to and (MACHINE[to.id] or to.id == "PodCannon") then
				addOut(n, to)
			end
		end
	end
	-- two belts facing each other would pass a pod back and forth forever
	local headOn: { [Node]: { Node } } = {}
	for _, n in net.list do
		for _, to in n.outs do
			if CONVEYOR[n.id] and CONVEYOR[to.id] and table.find(to.outs, n) then
				headOn[n] = headOn[n] or {}
				table.insert(headOn[n], to)
			end
		end
	end
	for n, bad in headOn do
		for _, to in bad do
			table.remove(n.outs, table.find(n.outs, to) :: number)
		end
	end
	return net
end

-- True when a source has somewhere to send pods.
function Belts.connected(net: Net, uid: number): boolean
	local n = net.nodes[uid]
	return n ~= nil and #n.outs > 0
end

-- Put dust into a source (a Collector Pad being emptied, a Pod Packer, a Dot Bot dock).
-- Returns how much it took: nothing if the source isn't connected or (for docks) is full.
function Belts.feed(net: Net, uid: number, kind: Kind, kg: number): number
	local n = net.nodes[uid]
	if not n or not SOURCE[n.id] or #n.outs == 0 or kg <= 0 then
		return 0
	end
	local room = if n.id == "DotBotMk1" or n.id == "DotBotMk2"
		then math.max(0, A.BotStoreKg - (n.store[kind] or 0))
		else kg
	local took = math.min(kg, room)
	n.store[kind] = (n.store[kind] or 0) + took
	return took
end

-- kW the base's machines want right now (only machines with something to work on).
function Belts.demand(net: Net): number
	local kw = 0
	for _, n in net.list do
		if MACHINE[n.id] and ((n.store.Dust or 0) > 0) then
			local def = Plot.def(n.id)
			kw += if def and def.power then def.power else 0
		end
	end
	return kw
end

-- Release a pod from a store if there is enough for one (or `partial` is set and some is left).
local function emit(net: Net, n: Node, key: string, kind: Kind, partial: boolean, sold: { Sold })
	local have = n.store[key] or 0
	if n.cool > 0 or have <= 1e-6 or #n.outs == 0 then
		return
	end
	if have < A.PodValueKg - 1e-6 and not partial then
		return
	end
	local kg = math.min(A.PodValueKg, have)
	local item: Item = { id = net.nextItem, kind = kind, kg = kg }
	if push(n, item, sold) then
		net.nextItem += 1
		n.store[key] = have - kg
		n.cool = A.BeltSpacing / A.BeltSpeed
	end
end

-- Advance the whole base by dt seconds. `satisfied` is the share of machine power met (0..1).
-- Returns the pods the cannon sold this tick.
function Belts.tick(net: Net, dt: number, satisfied: number, fx: Effects?): { Sold }
	local sold: { Sold } = {}
	local speed = A.BeltSpeed * (1 + (if fx then fx.beltSpeedPct or 0 else 0) / 100)
	for _, n in net.list do
		n.cool = math.max(0, n.cool - dt)
		if CONVEYOR[n.id] then
			local item = n.item
			if item then
				local length = if n.id == "Lift" then Plot.TILE * 2 else Plot.TILE
				n.progress = math.min(1, n.progress + dt * speed / length)
				if n.progress >= 1 and #n.outs > 0 and push(n, item, sold) then
					n.item = nil
					n.progress = 0
				end
			end
		elseif SOURCE[n.id] then
			local bulk = n.id == "CollectorPad" or n.id == "PodPacker"
			emit(net, n, "Dust", "Dust", bulk, sold)
			emit(net, n, "Stardust", "Stardust", bulk, sold)
		elseif n.id == "GlassOven" then
			local made, left = Factory.oven(n.store.Dust or 0, dt, satisfied, fx)
			n.store.Dust = left
			n.store.out = (n.store.out or 0) + made
			emit(net, n, "out", "Glass", left <= 1e-6, sold)
		elseif n.id == "GemPress" then
			local made, dust, glass = Factory.press(n.store.Dust or 0, n.store.Glass or 0, dt, satisfied, fx)
			n.store.Dust, n.store.Glass = dust, glass
			n.store.out = (n.store.out or 0) + made
			emit(net, n, "out", "Gem", dust <= 1e-6 or glass <= 1e-6, sold)
		end
	end
	return sold
end

-- Where every pod on a conveyor is, in plot space, for drawing.
function Belts.pods(net: Net): { PodView }
	local out = {}
	for _, n in net.list do
		local item = n.item
		if item then
			local fx, fz = Plot.facing(n.r)
			local reach = if n.id == "Lift" then Plot.TILE * 1.5 else Plot.TILE / 2
			local along = -Plot.TILE / 2 + n.progress * (reach + Plot.TILE / 2)
			local h = if n.id == "Lift" then math.sin(n.progress * math.pi) * 6 else 0
			table.insert(out, { id = item.id, x = n.x + fx * along, z = n.z + fz * along, h = h, kind = item.kind })
		end
	end
	return out
end

return table.freeze(Belts)
