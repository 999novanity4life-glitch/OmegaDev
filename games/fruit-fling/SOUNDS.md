# Fruit Fling: throw sound list

Status 2026-11-19: **cue list only, no IDs yet.** From the cloud container the Roblox Creator Store and asset APIs are blocked, and the sites that list "Roblox sound IDs" are unverified SEO pages, so no ID goes in until it is checked in Studio (CLAUDE.md rule 8, "no hallucination"). When the Mac is back, a thread fills the IDs with the Studio MCP `search_asset` tool and proves each one with `tools/verify_sounds.luau`.

Rule for every ID: audio asset (AssetTypeId 3), public, made by the **Roblox** account (free, licence-safe, cannot be taken down by a third party), plays in a playtest with zero console errors.

| Cue | When (3-beat throw, design doc section 3) | What it should sound like | Search terms |
|---|---|---|---|
| windup_loop | Beat 1 hold | rising tension whoosh / string creak, loops | "tension rise", "wind up", "bow string" |
| zone_ping | marker inside the gold zone | soft high ping | "ui ping", "chime" |
| release_whoosh | Beat 2 release | fast heavy whoosh | "whoosh", "swing heavy" |
| perfect_chime | each Perfect beat, pitch up per streak | bright bell, short | "bell chime", "perfect" |
| air_tap_burst | Beat 3 air tap | punchy pop + power burst | "pop", "burst", "magic hit" |
| fruit_trail | in flight | airy loop | "wind loop", "air flow" |
| splash_small / splash_big | landing (big on Masterwork) | water splash | "splash", "water impact" |
| tier_stamp | GOOD / GREAT / MASTERWORK slam | heavy stamp thud | "stamp", "slam" |
| crowd_cheer | Masterwork | short crowd cheer | "crowd cheer" |
| dock_ambience | always, quiet | waves, gulls, rope creak | "harbor ambience", "seagulls", "waves" |

Once IDs are verified they go in `Config.Sounds` (one place, rule: every tunable in Config) and `Juice.playSound` plays them on the client in the same frame as the input (CLAUDE.md rule 4).
