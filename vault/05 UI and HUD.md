# 05 UI and HUD

Facts: Roblox's default touch controls sit bottom-left (thumbstick) and bottom-right (jump) ([cross-platform](https://create.roblox.com/docs/ui/cross-platform-design)). Use `ScreenInsets = CoreUISafeInsets` for tappable UI ([ScreenInsets](https://create.roblox.com/docs/en-us/reference/engine/enums/ScreenInsets.md)). Buttons need hover/pressed/released states and actions need feedback ([UI/UX](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)).

## Layout map — PC
```
[Roblox topbar]            [ OBJECTIVE / STEP / TIMER ]        [Roblox menu]
                                                                [ CURRENCY 1 ]
[Tile][Tile]   <- menu grid, middle-left                         [ CURRENCY 2 ]
[Tile][Tile]                                                     [ quest/boost ]
[Tile][Tile]                                   [toasts]          [ offer tile  ]

[luck/friend boost chip]     [Menu] [  CORE VERB 1.5x  ] [Menu]
```
## Layout map — phone landscape (design for ~800x360 short and ~844x390 notched)
```
[Roblox] [grid 2x3 compact]   [ OBJECTIVE one line ]   [ CURRENCIES ]
                                                       [ 1-line quest ]
| THUMBSTICK |      [flank][ CORE VERB ][flank]          [ JUMP (Roblox) ]
```
Rules:
- Left edge, vertically centred: 4–6 menu tiles in a 2-column grid (Shop, Index, Rebirth, Teleport, Rewards, Settings).
- Top-right: currencies, biggest number first, icon as tall as the digits.
- Bottom-centre: the core verb, largest button, with its two most-used actions flanking it.
- Bottom corners belong to Roblox's controls on phones. Nothing tappable there.
- Draw this map for PC and phone before building any screen.
- **No-HUD-clutter rule:** when a player is confused, the fix is never a new permanent widget. Try, in order: something already on screen, the world (glow, arrow, floating word), a contextual hint, and only then a new widget, saying what it replaces.

## Party games (added 2026-10-23, see chapter 14)
- Round HUD: timer, players left, crowns, one power button. Hazard state readable at a glance: bomb holder outline + timer above the head, lava height bar.
- Color games ship a colorblind mode with symbols on tiles; color sets include confusable pairs ([earnaldo, unverified](https://earnaldo.com/blog/color-block-free-robux-guide)).
- Musical Chairs sells a "Music Timer" information edge and sits at 66.4% likes (games votes API, universe 6688157118): never sell HUD information.

## Look and motion (added 2026-10-28, notes in `docs/research/videos-2026-10-28/`)
- **Build from tokens, not one-off colors.** `template/src/shared/UITokens.luau` holds palette, radii, strokes, spacing, text sizes and motion times; `Controllers/UIKit.luau` builds panels, buttons and labels from them with Juice wired in. Every text/background pair is tested for WCAG 4.5:1 contrast ([WCAG 2.2](https://www.w3.org/TR/WCAG22/#contrast-minimum)). A game re-skins by editing tokens, never by restyling screens one by one [RULE].
- **Measure, don't invent.** Before styling a screen, take 3-5 reference stills (shipped games the human likes), and write the measured style sheet into the item's VISUAL_QA BRIEF: hex colors, outline width, corner radius, font, padding. UI passes review against those stills, not against taste [RULE, from the imported kit's Lessons Learned].
- **Find a seed.** Pick one physical metaphor for all menus (a ship's log, a toolbox, a cockpit panel) and let every screen answer "what would this be in that world?" It makes the UI "feel like it's one thing" [VIDEO 8 @1:01, @6:38].
- **One shared motion language**: the same bounce and overshoot on every screen (UITokens.Motion), objects that respond to touch (tilt, dust, squash) [VIDEO 8 @9:47, @10:19].
- **Nobody reads.** Cut text and numbers players will learn by playing; if a mockup looks complicated, simplify the mechanic, not just the screen [VIDEO 8 @17:27, @17:57].
- **Phones need their own layout**, sometimes a screen split in two [VIDEO 8 @15:54]. Capture both in the Device Emulator for VISUAL_QA.
- **One owner per piece of UI state**, so lists (inventory, shop) can't desync from the server [VIDEO 23 @4:02].
