--!strict
-- Shop + smart offers, server side. The server owns every decision: which
-- offer to show (SmartOffer, fed by game "moments"), what the player owns,
-- and when a purchase is granted. The client only sends intent.
--
-- Other services report outcomes with ShopService.moment(player, moment),
-- e.g. after a jump lands short of the next arc, after a lost fight, when the
-- fruit vault is full. Mark cutscenes / mid-jump with ShopService.setBusy.
--
-- Developer products are granted ONLY in ProcessReceipt and only through the
-- grant handler the player-data service registers (CLAUDE.md rule 6: it must
-- record the PurchaseId and save before returning true). Until one is
-- registered, receipts return NotProcessedYet and Roblox redelivers later.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local SmartOffer = require(Shared:WaitForChild("SmartOffer"))
local Validate = require(Shared:WaitForChild("Validate"))
local RemoteGuard = require(script.Parent.RemoteGuard)

type Item = SmartOffer.Item & { AssetId: number }
type Moment = SmartOffer.Moment

-- (player, item, receipt) -> true only once the grant is saved.
export type ProductGrant = (player: Player, itemId: string, receipt: { [string]: any }) -> boolean

local ShopService = {}

local catalog: { [string]: Item } = {}
local byPassId: { [number]: string } = {}
local byProductId: { [number]: string } = {}
for id: string, raw: Config.ShopItem in Config.Shop.Items do
	local item: Item = {
		Id = id,
		Kind = raw.Kind,
		Name = raw.Name,
		Price = raw.Price,
		Berries = raw.Berries,
		AssetId = raw.AssetId,
	}
	catalog[id] = item
	if raw.AssetId > 0 then
		if raw.Kind == "GamePass" then
			byPassId[raw.AssetId] = id
		else
			byProductId[raw.AssetId] = id
		end
	end
end

local rules: SmartOffer.Rules = Config.Shop.Offers
local states: { [Player]: SmartOffer.State } = {}
local pendingOffer: { [Player]: string } = {}
local productGrant: ProductGrant? = nil
local shopEvent: RemoteEvent

local INTENTS = { Buy = true, Dismiss = true, Mute = true, Unmute = true }

local function ownedList(state: SmartOffer.State): { string }
	local list = {}
	for id, owned in state.owned do
		if owned then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

local function sendOwned(player: Player)
	local state = states[player]
	if state then
		shopEvent:FireClient(player, "Owned", { owned = ownedList(state), muted = state.muted })
	end
end

local function refreshPasses(player: Player)
	local state = states[player]
	if not state then
		return
	end
	for passId, id in byPassId do
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		if ok and owns and states[player] == state then
			state.owned[id] = true
		end
	end
	sendOwned(player)
end

function ShopService.owns(player: Player, itemId: string): boolean
	local state = states[player]
	return state ~= nil and state.owned[itemId] == true
end

function ShopService.setBusy(player: Player, busy: boolean)
	local state = states[player]
	if state then
		state.busy = busy
	end
end

function ShopService.registerProductGrant(grant: ProductGrant)
	productGrant = grant
end

-- Report a game outcome. Shows at most one offer, only if it truly helps.
function ShopService.moment(player: Player, moment: Moment)
	local state = states[player]
	if not state or pendingOffer[player] then
		return
	end
	local now = os.clock()
	local offer = SmartOffer.decide(moment, state, catalog, rules, now)
	if not offer then
		return
	end
	SmartOffer.recordShown(state, now)
	pendingOffer[player] = offer.itemId
	shopEvent:FireClient(player, "Offer", { itemId = offer.itemId, reason = offer.reason })
end

-- Studio-only helper so playtests can see an offer without waiting 3 minutes.
function ShopService.skipGraceForTest(player: Player)
	assert(RunService:IsStudio(), "test helper is Studio-only")
	local state = states[player]
	if state then
		state.sessionStart -= rules.GraceSeconds
		state.lastOfferAt = nil
	end
end

local function onIntent(player: Player, action: string, itemId: string?)
	local state = states[player]
	if not state then
		return
	end
	if action == "Mute" or action == "Unmute" then
		state.muted = action == "Mute"
		pendingOffer[player] = nil
		sendOwned(player)
		return
	end
	local item = itemId and catalog[itemId]
	if not item then
		return
	end
	if action == "Dismiss" then
		if pendingOffer[player] == item.Id then
			pendingOffer[player] = nil
			SmartOffer.recordDismiss(state, item.Id, rules, os.clock())
		end
		return
	end
	-- Buy
	if pendingOffer[player] == item.Id then
		pendingOffer[player] = nil
	end
	if item.Kind == "GamePass" and state.owned[item.Id] then
		shopEvent:FireClient(player, "Result", { itemId = item.Id, status = "Owned" })
		return
	end
	if item.AssetId <= 0 then
		shopEvent:FireClient(player, "Result", { itemId = item.Id, status = "ComingSoon" })
		return
	end
	if item.Kind == "GamePass" then
		MarketplaceService:PromptGamePassPurchase(player, item.AssetId)
	else
		MarketplaceService:PromptProductPurchase(player, item.AssetId)
	end
end

local function validateIntent(action: any, itemId: any): boolean
	if not Validate.oneOf(action, INTENTS) then
		return false
	end
	if action == "Mute" or action == "Unmute" then
		return itemId == nil
	end
	return Validate.shortString(itemId, 32) and catalog[itemId] ~= nil
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local itemId = byProductId[receipt.ProductId]
	local grant = productGrant
	if not player or not itemId or not grant then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, saved = pcall(grant, player, itemId, receipt)
	if not ok or saved ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local state = states[player]
	if state then
		SmartOffer.recordPurchase(state, catalog[itemId], os.clock())
	end
	shopEvent:FireClient(player, "Result", { itemId = itemId, status = "Granted" })
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onPassFinished(player: Player, passId: number, purchased: boolean)
	local itemId = byPassId[passId]
	local state = states[player]
	if not itemId or not state or not purchased then
		return
	end
	-- Re-check with Roblox rather than trusting the event alone.
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
	if ok and owns then
		SmartOffer.recordPurchase(state, catalog[itemId], os.clock())
		shopEvent:FireClient(player, "Result", { itemId = itemId, status = "Granted" })
		sendOwned(player)
	end
end

local function onPlayerAdded(player: Player)
	states[player] = SmartOffer.newState(os.clock())
	task.spawn(refreshPasses, player)
end

function ShopService.start()
	shopEvent = Remotes.get("ShopEvent")
	RemoteGuard.connect(Remotes.get("ShopIntent"), validateIntent, onIntent)
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPassFinished)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		pendingOffer[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return ShopService
