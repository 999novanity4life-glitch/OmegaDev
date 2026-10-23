# Slime Rise: spec (v0.1 prototype)

**One sentence a kid gets:** Climb out of the slime lab before the slime gets you.

Chosen by Sharman on 2026-10-23 from pitch 6 (Goo Rise), retheme: slime. Research: `docs/research/PARTY_GAMES_2026-10-23.md`, playbook `vault/14 Round-Based Party Games.md`.

## Core loop (round-based)
| Phase | Length | What happens |
|---|---|---|
| Lobby | until ≥ 1 player (prototype; launch: 2 + bots) | Players wait on a balcony that overlooks the tower |
| Intermission | 15 s | Countdown; tower regenerates from a new seed |
| Round | 75 s (3 s head start, then slime rises) | Climb the spiral to the Exit Pad at the top |
| Results | 6 s | Escapes, places and crowns earned |

- **Slime height** is a pure function of server time: `height = baseY + (topY - baseY) * t ^ 1.25` (slow start, fast finish). The server stores the start time and numbers as attributes; every client draws the slime locally, the server checks contact every 0.2 s (`shared/SlimeCurve.luau`).
- **Touching slime** drains 50 HP/s (about 2 s to be slimed). Bubble Shield blocks it.
- **Escape** = reach the Exit Pad. Escaped players go back to the lobby balcony to watch.

## Crowns (earned only, never sold)
- Escape: +1. Escape within 45 s (Speedy): +1. Top 3 to escape: +1 (`shared/Crowns.luau`).
- Crowns unlock powers permanently.

## Powers (one active on the button, Double Jump is passive)
| Power | Unlock | Cooldown | Effect |
|---|---|---|---|
| Slime Dash | 0 | 6 s | 22 studs in 0.22 s, slime afterimages |
| Double Jump | 5 | passive | Second jump in the air |
| Bubble Shield | 12 | 20 s | 2.5 s slime-proof bubble |
| Sticky Grapple | 20 | 10 s | Slime rope pulls you to a point within 45 studs |

Server validates every use (unlocked, cooldown, alive in the round, grapple range). The client moves its own character for instant feel.

## Look (needs Sharman's approval)
- Slime: bright lime `#6BFF3D` body, glossy, bubbling surface, soft green glow.
- Lab tower: dark plum metal pillar, teal and purple pads, neon slime-green trims, pipes.
- UI: chunky cartoon style (Stud Cartoon family), slime-green accents, round panels, thick dark strokes.

## Acceptance test (prototype)
1. Join → lobby balcony; intermission counts down; teleported to the tower base.
2. Slime rises visibly and smoothly; standing in it kills in ~2 s; dying returns you to the lobby.
3. Reaching the Exit Pad: "ESCAPED!" banner, crowns added, back to the lobby.
4. Q uses the selected power; E switches power; locked powers show the crowns needed.
5. Zero errors in Output across two full rounds.

## Not in v0.1
Saving crowns (ProfileStore), bots, gumdrop collectibles, shop and cosmetics, mobile layout polish, sounds.
