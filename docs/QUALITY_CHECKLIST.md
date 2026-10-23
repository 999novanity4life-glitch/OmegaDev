# OmegaDev quality checklist

Score every build before shipping. Each line is PASS / FAIL / NOT TESTED with
evidence (screenshot, log line, test output). "Looks fine" is not evidence.
Sources are linked so nobody has to trust this list on faith.

## 1. Technical gate (all must pass, automated in CI)
- [ ] `stylua --check`, `selene`, `luau-lsp analyze` (strict), `lune run tests/run`, `rojo build` all green.
- [ ] Every remote goes through `RemoteGuard` + `Validate`; no client-trusted prices, damage, positions or cooldowns. ([client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary))
- [ ] Spamming any remote 1,000x/second does nothing harmful. ([security tactics](https://create.roblox.com/docs/scripting/security/security-tactics))
- [ ] Player data is session-locked (ProfileStore or UpdateAsync lock), saved on leave and in `BindToClose`; a failed load never overwrites saved data and blocks purchases. ([player data guide](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing))
- [ ] `ProcessReceipt` is idempotent: check PurchaseId, grant, record, save, then `PurchaseGranted`; save failure returns `NotProcessedYet`. (same guide)
- [ ] Zero errors/warnings from our scripts in a full playtest console log.
- [ ] Works with StreamingEnabled: client code tolerates parts streaming out. ([streaming](https://create.roblox.com/docs/en-us/workspace/streaming))
- [ ] MicroProfiler on a phone-class device stays under 33.3 ms/frame (30 FPS) in the busiest scene; aim for 16.7 ms. ([MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler))

## 2. First five minutes (FTUE)
- [ ] A new player reaches the core fun in 5 minutes or less. ([retention](https://create.roblox.com/docs/en-us/production/analytics/retention))
- [ ] Onboarding teaches what to do and why, without a long tutorial wall. ([onboarding](https://create.roblox.com/docs/en-us/production/game-design/onboarding))
- [ ] Short, mid and long-term goals are visible on screen early.
- [ ] Early levels/upgrades come fast (low early XP thresholds; starter item).
- [ ] FTUE ends on a designed "moment of joy" (big reward, reveal, unlock).
- [ ] Each onboarding step is logged with `AnalyticsService:LogOnboardingFunnelStepEvent` (server-side). ([funnels](https://create.roblox.com/docs/production/analytics/funnel-events))
- [ ] No first-play bounce traps: no long loading, no unexplained black screen, no unskippable cutscene. (first-play bounce is a discovery signal: [discovery](https://create.roblox.com/docs/discovery.md))

## 3. Game feel (juice)
- [ ] Every player action has same-frame client feedback: visual + sound at minimum. ([UI/UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design))
- [ ] Every button has hover, pressed and released states.
- [ ] Rewards feel like rewards: pop-in tween with overshoot, particles, sound, number count-up.
- [ ] Impacts have weight: camera shake / flash / debris scaled to importance. ([Juice it or lose it, GDC 2013](https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-))
- [ ] Movement and combat respond with no visible input delay (cosmetics on client, outcomes on server).
- [ ] Music and SFX have separate volume controls. ([accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility))
- [ ] Reduced Motion setting disables shakes and long tweens. (same page)

## 4. UI polish (mobile first: most Roblox players are on mobile, [design for Roblox](https://create.roblox.com/docs/en-us/production/game-design/design-for-roblox))
- [ ] Tested at phone, tablet and desktop sizes; Scale-based sizing with `UIAspectRatioConstraint`. ([size modifiers](https://create.roblox.com/docs/en-us/ui/size-modifiers))
- [ ] Tappable UI uses `ScreenInsets = CoreUISafeInsets`; nothing hidden by notch or top bar. ([ScreenInsets](https://create.roblox.com/docs/en-us/reference/engine/enums/ScreenInsets.md))
- [ ] Nothing important under the default thumbstick (bottom-left) or jump button (bottom-right). ([cross-platform](https://create.roblox.com/docs/ui/cross-platform-design))
- [ ] Text min size 9+, high contrast, consistent colors for meanings (e.g. can't-afford is always red).
- [ ] Color is never the only signal (icons/labels too).
- [ ] One visual style: consistent fonts, corner radius, stroke, palette, icon set.

## 5. Loops and progression
- [ ] Core loop is clear and repeatable in 10-30 s; there is a progression engine that changes the next loop. ([core loops](https://create.roblox.com/docs/en-us/production/game-design/core-loops))
- [ ] A reason to come back tomorrow (dailies, collection, upgrades, events).
- [ ] A social reason to play with friends (co-play days are a discovery signal). ([discovery](https://create.roblox.com/docs/discovery.md))
- [ ] Economy has both sources and sinks; time-to-first-upgrade and time-to-level-10 written down and playtested.

## 6. Monetization (fair and policy-compliant)
- [ ] Passes for permanent perks, Developer Products for repeatables. ([monetize](https://create.roblox.com/docs/monetize-experiences))
- [ ] No pay-to-win against other players; free players can reach the fun.
- [ ] Purchase moments are contextual (offered when the player feels the need), with a sound and confirmation on success.
- [ ] Paid random items show all outcomes with numeric odds summing to 100% before purchase, and `ArePaidRandomItemsRestricted` users get an alternative. ([paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items))
- [ ] Subscriptions (if any) are honored for the full term; no tiered subs. ([subscriptions](https://create.roblox.com/docs/production/monetization/subscriptions))

## 7. Store page and discovery
- [ ] Custom thumbnail(s) uploaded (required for homepage recommendations). ([discovery](https://create.roblox.com/docs/discovery.md))
- [ ] Icon and thumbnails show the game's actual fun moment, readable at phone size.
- [ ] Update cadence planned: small updates every 2-4 weeks, big ones every 2-3 months. ([retention](https://create.roblox.com/docs/en-us/production/analytics/retention))
- [ ] After launch, read D1/D7, session length and the onboarding funnel in Creator Analytics; Roblox publishes no target numbers, so compare against your own previous build and the benchmark set. ([analytics](https://create.roblox.com/docs/production/analytics))
