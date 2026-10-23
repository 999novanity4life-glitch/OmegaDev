# 09 Shops and Monetization

Facts: Passes = one-time, Developer Products = repeatable ([monetize](https://create.roblox.com/docs/monetize-experiences)). `ProcessReceipt` must be idempotent: record PurchaseId, save, then return `PurchaseGranted`; on save failure return `NotProcessedYet` ([guide](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)). Subscriptions must honor the full term; no tiered subs ([subscriptions](https://create.roblox.com/docs/production/monetization/subscriptions)). Premium Payouts were replaced by Creator Rewards in 2025 ([creator rewards](https://create.roblox.com/docs/creator-rewards)).

Studio rules:
- Offer at the moment of need (out of rolls → "+10 rolls"), never as a pop-up on join.
- Starter pack: cheap, clearly great value, shown after the first session's "wow".
- Typical passes: x2 currency, auto-verb, extra storage, VIP cosmetic. Never pay-to-win against other players.
- Every purchase gets a sound, a pop and an immediate visible effect.
- Odds for anything random are on the purchase screen (chapter 03).
