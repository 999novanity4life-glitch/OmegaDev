# Roblox engineering rules for Steal a Dream

Claude follows these when writing this game's code. Sources are in `../research/GITHUB_ROBLOX_DEV_SKILLS_2026-10-13.md`. Rules without a source are labeled.

*Verified 2026-10-23 against the official docs (ProfileStore API + devproducts pages, Roblox remote-events guide, DataStore limits, Random datatype, paid-random-items policy, BindToClose forum quotes of the docs). Every number below held up; the two UNVERIFIED labels were resolved as noted.*

## 1. Structure
1. **Use plain ModuleScripts, no framework.** Knit is archived. Each system (DataService, DreamlingService, StealService, EggService, ShopService) is one module with one owner and a small public API. No circular requires.
2. **Don't yield inside a module body.** A single bootstrap Script requires every module, then calls `Init()` on all of them, then `Start()` on all of them.
3. **Location:** game logic, data and odds tables live in `ServerScriptService`/`ServerStorage`. `ReplicatedStorage` holds only shared types, display-only config and remotes, because anything there can be decompiled.
4. **Style:** put `--!strict` at the top of every script. File order is services, requires, `LOUD_SNAKE` constants, locals, `return`. `PascalCase` for classes, `camelCase` for functions. Use `task.wait/spawn/delay/defer`, never `wait/spawn/delay`. Always give `WaitForChild` a timeout.
```luau
--!strict
local Players = game:GetService("Players")
local Types = require(game.ReplicatedStorage.Shared.Types)
local SHELF_START = 8
```
5. **Shared types** live in `ReplicatedStorage.Shared.Types` using `export type`.

## 2. The server is in charge
6. Flow: **client asks, server validates, server acts, server replicates.** Dust, inventory, prices, odds, timers and pity counters live only on the server. The client only displays them.
7. The client never sends a price, an amount, a rarity or a result. It sends an **ID** of what it wants (`"CloudEgg"`, a shelf slot number), and the server looks up everything else in its own tables.
8. Touched, ProximityPrompts and client positions can be faked. **Check distance on the server** for buying, cashing the jar, hatching, grabbing and tagging.

## 3. Remotes
9. **Every handler validates in this order:** type, NaN/infinity, range, ownership, game state (asleep or awake, in a room), distance, cooldown. Reject quietly, and count suspicious attempts; never kick for a single bad packet.
```luau
local function isFiniteNumber(x: any): boolean
	return typeof(x) == "number" and x == x and math.abs(x) ~= math.huge
end
```
10. **Rate-limit each remote for each player**, and still validate.
```luau
local last: {[Player]: number} = {}
local function allow(p: Player, gap: number): boolean
	local now = os.clock()
	if (last[p] or 0) > now - gap then return false end
	last[p] = now
	return true
end
-- clear last[p] on PlayerRemoving
```
11. Use RemoteEvents. Avoid `InvokeClient`, because a client can make the server wait forever. Use UnreliableRemoteEvent only for VFX you can afford to lose (messages over 1,000 bytes are dropped without resend; neither delivery nor order is guaranteed).
12. Payloads are plain tables of IDs: no functions, metatables, mixed keys or nil holes. Send a full snapshot on join, then only changes.

## 4. Saving data (ProfileStore)
13. **Use ProfileStore for all player data.** Its session lock stops item duplication, which matters a lot because Dreamlings change owners. Don't use ProfileService or DataStore2.
14. Load pattern:
```luau
local store = ProfileStore.New("PlayerData_v1", TEMPLATE)
if RunService:IsStudio() then store = store.Mock end -- Studio never touches live data (verified: `.Mock` is a property on the store object; its data is discarded on shutdown)
local profile = store:StartSessionAsync(`Player_{player.UserId}`, {
	Cancel = function() return player.Parent ~= Players end,
})
if profile == nil then player:Kick("Data failed to load, please rejoin") return end
profile:AddUserId(player.UserId)
profile:Reconcile()
profile.OnSessionEnd:Connect(function()
	profiles[player] = nil
	player:Kick("Session ended, please rejoin")
end)
if player.Parent ~= Players then profile:EndSession() return end
profiles[player] = profile
```
15. **Never treat a nil profile as a new player.** Never call `Steal`. A custom `Cancel` turns off ProfileStore's timeout, so `Cancel` must eventually return true.
16. The template has a `Version` field. On load, migrate old data first, then `Reconcile()`.
17. Before saving, make sure values are clean: no NaN or infinity, check strings with `utf8.len`, no Instances. One bad value fails the whole save.
18. Keys look like `Player_<UserId>`, never hashed, so automated right-to-be-forgotten erasure works. One key per player, under 4 MB (docs: 4,194,304 characters of serialized JSON per key; key names max 50 characters).
19. Call `profile:EndSession()` on PlayerRemoving. On shutdown, end every session **in parallel** (`task.spawn` for each player); doing them one at a time can run past the 30-second limit.
20. `profile:IsActive()` is only true until the next yield. Do critical writes straight after the check, with no yield in between. Leaderboards and global state don't go in ProfileStore.

## 5. Stealing (moving an item between players)
22. Both players are on the same server, so both profiles are locked here. Do the steal as **one server function with no yield** between removing the Dreamling from the victim's profile and adding it to the thief's. Check both profiles are active first. Re-check everything on the server: the thief is asleep, the dream timer is still running, the thief is within reach of the item, the item is still on that shelf, and the thief has carry capacity. *(Applies the session-lock and IsActive rules; there's no ready-made library for this.)*
```luau
local function transfer(fromP, toP, uid: string): boolean
	if not (fromP:IsActive() and toP:IsActive()) then return false end
	local d = fromP.Data.Dreamlings[uid]
	if d == nil then return false end
	fromP.Data.Dreamlings[uid] = nil
	toP.Data.Dreamlings[uid] = d
	return true
end
```

## 6. Robux purchases
24. Grant developer products **only in `ProcessReceipt`**. Never trust `PromptProductPurchaseFinished`.
25. Keep a `PurchaseIdCache` in the profile, capped at about 100 entries. If the ID is already there, return `PurchaseGranted` and grant nothing. Otherwise grant, store the ID, and return `PurchaseGranted` **only after the save is confirmed**. On any failure, or if the player has no active profile, return `NotProcessedYet`, and Roblox redelivers when they rejoin. Follow ProfileStore's devproducts page.
26. Check gamepasses on the server, and check again after a purchase. Multipliers and luck live in server data; never take them from a client-set attribute.

## 7. Eggs: weighted RNG with pity
27. Roll on the **server** with one `Random.new()` (it seeds itself from entropy). Decide the result **first**; the wheel animation only shows it.
28. **Roll the rarity first, then the Dreamling inside that rarity.** Weights on individual creatures make the odds on the sign wrong, which is a real bug in a popular template.
```luau
local rng = Random.new()
local function rollRarity(odds: {{rarity: string, weight: number}}): string
	local total = 0
	for _, o in odds do total += o.weight end
	local r = rng:NextNumber(0, total)
	for _, o in odds do
		r -= o.weight
		if r <= 0 then return o.rarity end
	end
	return odds[#odds].rarity -- floating-point fallback only
end
```
29. **Pity:** keep a counter for each egg in the profile (`Pity.CloudEgg`). Add one on every egg without a Legendary or better, reset it to 0 when one lands, and force Legendary when `count + 1 >= threshold` (100 for Cloud, 40 for Star). Send the counter to the UI.
30. Take the Dust, roll and insert inside one server function with no yield. Check that the shelf has room **before** taking the Dust.
31. **Odds disclosure** (Roblox policy for anything bought directly or indirectly with Robux): show every outcome as a percentage, adding to 100%, before purchase. Show the boosted odds while Lucky Boost or Server Luck is active. Check `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted`, and don't sell luck items to restricted players. Pity counts as a probability modifier under this policy when it is paid for. The policy explicitly covers currency bought with Robux and then spent on a random outcome. *(Still unaddressed by the docs: whether Dust earned faster under a Robux multiplier gamepass counts as "indirect"; we show odds anyway.)*

## 8. Offline earnings *(not from a library: this follows rule 6)*
32. Save `LastSeen = os.time()` on the server whenever data saves. On join: `elapsed = math.clamp(os.time() - LastSeen, 0, cap)`, where `cap` is 7200, or 28800 with Long Sleep. Add `elapsed * incomePerSecond`, computed on the server.

## 9. Number formatting
33. Luau numbers are doubles. Integers are exact up to 2^53 (about 9e15), and our economy stays well below that, so **we don't need a big-number library**. Keep Dust as a whole number (`math.floor`) and format it only for display:
```luau
local SUFFIX = {"", "K", "M", "B", "T", "Qa", "Qi"}
local function fmt(n: number): string
	if n ~= n or math.abs(n) == math.huge then return "?" end
	local i = 1
	while math.abs(n) >= 1000 and i < #SUFFIX do n /= 1000; i += 1 end
	return (i == 1 and tostring(math.floor(n)) or string.format("%.1f", n)) .. SUFFIX[i]
end
```

## 10. Cleanup
34. Whoever creates a connection, instance, task or tween cleans it up. Give each player one **Trove** (RbxUtil) and each Dreamling or ghost model one too. Call `trove:Clean()` on PlayerRemoving or Destroy. Use only Trove; don't mix in Janitor or Maid.
35. Remove a player's entries from every per-player table (`profiles`, `last`, cooldowns, pity caches) on PlayerRemoving.

## 11. Performance
36. Don't do game logic in Heartbeat or RenderStepped. Income ticks once a second on the server, and the Stream spawns on a timer. Clients play VFX, tweens and the spin wheel themselves.
37. Anchor static parts, use Box/Hull collision for decor, reuse one mesh per Dreamling type, pool Stream Dreamlings, and turn on StreamingEnabled.

## 12. Working through the Studio MCP
38. Discover, inspect, edit in small batches, **read back**, start play, check live in a Server or Client VM, collect evidence (`get_console_output` + `screen_capture`), stop play. `execute_luau` is stateless, so look up instances again on every call. Edit-mode code can't reach a running playtest.
39. Split large scripts across several `multi_edit` calls, then `script_read` the whole file back. Call `wait_job_finished` before using any `generate_*` output.
40. Unsure about an API? Fetch the official reference with `http_get` or the `skill` tool instead of guessing.
