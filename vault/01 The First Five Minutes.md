# 01 The First Five Minutes

Facts (Roblox docs): get new players to the fun in about 5 minutes or less ([retention](https://create.roblox.com/docs/en-us/production/analytics/retention)). Teach what to do and why, keep early thresholds low, give starter items, show short/mid/long goals, end the FTUE on a "moment of joy" ([onboarding](https://create.roblox.com/docs/en-us/production/game-design/onboarding)). Long tutorials do worse ([design for Roblox](https://create.roblox.com/docs/en-us/production/game-design/design-for-roblox)). First-play bounce under 60 s and 61–180 s is a negative discovery signal ([discovery](https://create.roblox.com/docs/discovery.md)).

Studio rules:
- **Second 0–5:** the spawn shot shows the landmark and the core activity. No black screen, no wall of text.
- **Second 5–20:** the core verb button is the biggest thing on screen and pulses; one tap does something satisfying.
- **First minute:** first reward. **Minutes 1–3:** first upgrade bought. **By minute 5:** first "wow" (rare drop, boss, unlock) + a visible next goal.
- Reveal UI one piece at a time: core verb → first reward → first menu → the rest. Ten tiles appearing at once looks like chaos.
- Guide with the world (glowing path, arrow, floating word) before adding text.
- Log every onboarding step with `AnalyticsService:LogOnboardingFunnelStepEvent` on the server ([funnels](https://create.roblox.com/docs/production/analytics/funnel-events)).

## Party games (added 2026-10-23, see chapter 14)
- A new joiner is playing within 60 s. Long rounds strand joiners for minutes ([DevForum](https://devforum.roblox.com/t/allow-developers-to-mark-servers-as-unpreferred-for-new-player-joins/3680997/1)); use short rounds, join-in-progress, or a lobby obby that pays a little.
- Keep any "get ready" card to 3-5 s ([DevForum](https://devforum.roblox.com/t/feedback-on-my-rising-lava/1215711)).
- Below 4 players, fill with bots or a solo score mode: empty round servers lose players instantly ([DevForum](https://devforum.roblox.com/t/feedbackproblem-hot-potato-slap-counter-game/4450393)).
