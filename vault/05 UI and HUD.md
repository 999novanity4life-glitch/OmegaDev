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
