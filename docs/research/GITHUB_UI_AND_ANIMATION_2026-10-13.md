# GitHub + Roblox docs research: UI and animation (2026-10-13)
For *Steal a Dream*. Built by Claude Code through Roblox's **built-in Studio MCP** (execute_luau, multi_edit, start_stop_play, screen_capture). Nothing was installed, cloned or run. The two rulebooks distilled from this are in `reference_dev\UI_RULEBOOK.md` and `reference_dev\ANIMATION_CUTSCENE_RULEBOOK.md`.

Tags: **[DOC]** = official create.roblox.com / Roblox creator-docs, **[GH]** = GitHub repo page, **[FORUM]** = DevForum or secondary site, **UNVERIFIED** = not confirmed by a primary source.

---

## 1. The headline answers
1. **Build UI with plain Instances + TweenService**, wrapped in one small in-house helper module. No UI framework. Reasons below (section 3).
2. **The UI must be responsive by construction**: Scale sizes, AnchorPoint 0.5, UIAspectRatioConstraint on panels, UITextSizeConstraint on scaled text, offset-only grid cells inside auto-sized scroll frames (a known engine limitation).
3. **Dreamlings v1 should animate procedurally** (sine bob, squash-and-stretch via TweenService). Uploaded animations need an asset that the experience owner owns (or that's been shared to it), and Claude has no MCP tool to publish animation assets. `KeyframeSequenceProvider` IDs only work inside Studio.
4. **Cutscenes = Scriptable camera + TweenService / Bezier sampling**, letterbox + skip in UI, first-join flag saved server-side in a DataStore. The tooling is small enough that we write our own. CutsceneService (MIT) is the reference design if we ever need more.
5. The built-in MCP's `execute_luau` can run in the **Client** datamodel during a playtest, and `screen_capture` takes a custom camera position. So Claude can open a UI or play a cutscene, screenshot it, and fix it in one loop.

---

## 2. Studio MCP facts that shape how Claude builds [DOC]
Source: create.roblox.com/docs/studio/mcp (26 tools).
- `multi_edit` creates or edits a script and needs `datamodel_type = Edit`. Use it for all LocalScripts/ModuleScripts so the code lives in the place file.
- `execute_luau` runs in Edit, Client or Server. Use Edit to build Instances (ScreenGuis, camera-point parts). Use Client during play to trigger a UI or cutscene for testing.
- `screen_capture` captures the viewport and optionally takes a camera position and look-at target. That's useful for previewing cutscene shots without playing.
- `get_studio_state` reports the play state and which datamodels exist. `get_console_output` reads errors.
- `http_get` fetches allowed Roblox docs pages. `skill` returns Roblox best-practice material.
- `upload_image` uploads images from URLs and returns asset IDs. There's **no animation-upload tool**, so animation assets must be published by Sharman from the Animation Editor.
- The older open-source `Roblox/studio-rust-mcp-server` (MIT) was **archived 2026-04-03**; Roblox points to the built-in server [GH].

---

## 3. UI approach comparison
| Option | Status (as seen 2026-10-13) | License | Fit for Claude-via-MCP |
|---|---|---|---|
| **Plain Instances + TweenService** | Engine API, always current | n/a | **Best.** Zero dependencies, everything is inspectable with `inspect_instance`, every property is in the docs, and tweens are one call |
| **Fusion** (dphfox/Fusion) | Latest release "Fusion 0.3", tagged v0.3-beta, 30 Aug (year not shown on page; UNVERIFIED, likely 2024); ~800 stars | MIT | Possible but not worth it. API changed between 0.2 and 0.3, so generated code risks mixing versions (judgment). Adds an abstraction layer the MCP tools can't see into |
| **react-lua** (jsdotlua/react-lua, fork of roblox/react-lua) | Roblox's own UI uses it. Roblox's repo is a read-only mirror, and the jsdotlua fork is the community package. No releases listed | MIT | Poor fit. It's a multi-package translation of React 17 that expects Wally/Rojo/darklua tooling, which this project doesn't use |
| **Roact** (Roblox/roact) | **Archived 2023-12-13, deprecated** ("no longer maintained"), successor react-lua | Apache-2.0 | Don't use |
| **Vide** (centau/vide) | 0.4.1 released 2026-07-11, all releases marked pre-release; Solid-style, fully typecheckable | MIT | Pre-1.0 and small. Not worth it |

**Decision:** plain Instances, with a ~40-line `UIKit` ModuleScript we write ourselves (`make(class, props, children)` + style helpers + tween helpers). That gives the "declarative tree" readability of Fusion's `New` with no dependency. Optionally vendor **spr** (single file, MIT) for spring motion.

---

## 4. Responsive and mobile UI facts [DOC]
- **Scale vs Offset:** Scale = % of parent, Offset = pixels, and they add together. AnchorPoint (0.5, 0.5) centres the object on its Position. *(ui/position-and-size)*
- **Device corners:** keep important info and custom buttons out of the **bottom-left and bottom-right corners**, because mobile controls (thumbstick, jump) sit there. Put frequent buttons within thumb reach and show only essential UI during play. *(position-and-size)* Our reference HUD puts currency bottom-left, so on touch devices it must move up or sit above the thumbstick zone.
- **UIAspectRatioConstraint** keeps the shape when sizing by Scale. It **overrides** a UIListLayout/UIGridLayout's control of that object's size. Constraints must be children of the object. *(ui/size-modifiers)*
- **UIScale** multiplies the whole subtree, including UIStroke and UICorner. The docs suggest tweening it for hover enlargement. *(size-modifiers)*
- **TextScaled:** the TextLabel API says to avoid TextScaled and prefer AutomaticSize, never to use both on one label, and to add a **UITextSizeConstraint**. Minimum text size is **9**. *(TextLabel, size-modifiers)*
- **ScreenGui.ScreenInsets:** `CoreUISafeInsets` (default, keeps UI clear of the top bar), `DeviceSafeInsets`, `None`. Use `None` only for non-interactive content like backgrounds, because UI can end up under core UI or notches. `SafeAreaCompatibility` is legacy: "avoid for new work, use ScreenInsets". `IgnoreGuiInset = true` switches ScreenInsets to DeviceSafeInsets. `DisplayOrder`: higher draws on top. *(ScreenGui)*
- **UIListLayout:** FillDirection, SortOrder (LayoutOrder), Padding (between items only, so use UIPadding for edges), Wraps, HorizontalFlex/VerticalFlex, ItemLineAlignment. A layout **overrides the Position/Size of siblings**. Flex has a small performance cost. *(ui/list-flex-layouts)*
- **UIGridLayout:** CellSize, FillDirectionMaxCells, SortOrder. It overrides siblings' Position/Size. *(ui/grid-table-layouts)*
- **ScrollingFrame:** AutomaticCanvasSize grows the canvas to its children. Touch devices are elastic by default (`ElasticBehavior`). *(ui/scrolling-frames)*
- **Known bug [FORUM]:** AutomaticCanvasSize misbehaves when children/grid cells use **Scale**, and when a parent has a UIScale. Roblox staff guidance is to use **offset-only CellSize** and recompute it from `AbsoluteSize` in a script.
- **Buttons:** connect to `Activated` (click or tap). `SecondaryActivated` = right-click or long-press. ImageButton has HoverImage/PressedImage. *(ui/buttons)*

## 5. Styling facts [DOC]
- **Fonts:** `label.FontFace = Font.fromName("FredokaOne")`. Built-in families include **Fredoka One** and **Luckiest Guy** (also Bangers, Denk One, Permanent Marker, Press Start 2P, Creepster). Asset form is `rbxasset://fonts/families/<Name>.json`. Weights: Regular...Bold...Heavy. *(Font datatype)*
- **UIStroke** outlines text when parented to a text object. Thickness is in pixels by default, and `StrokeSizingMode = ScaledSize` scales the stroke with font size. **Don't tween Thickness on text strokes**: it re-renders glyph sizes every frame, which costs performance and can flicker. Give sibling strokes distinct ZIndex. *(appearance-modifiers)*
- **UICorner:** Scale 0.5 gives a pill or circle, and per-corner radii exist. *(appearance-modifiers)*
- **UIGradient:** Color, Transparency, Rotation, Offset, Scale, TileMode, and **Type = Linear / Radial / Conical**. Animate Offset/Rotation rather than rewriting Color often, and keep it to about 6 color stops or fewer for performance. *(UIGradient)* A Conical gradient with hard stops can draw the **spin-wheel pie** without image assets (UNVERIFIED in practice: test with screen_capture).
- **CanvasGroup:** tween `GroupTransparency` to fade a whole panel. Use it for clipping rotated or rounded containers, because normal clipping fails there. *(ui/animation, ui/frames)*

## 6. Tweening facts [DOC]
- `TweenService:Create(obj, TweenInfo.new(t, style, dir), goals):Play()`. The default is Quad Out. The **Back** style overshoots, which is the "pop".
- Tweenable types: number, boolean, CFrame, Rect, Color3, UDim, UDim2, Vector2, Vector2int16, Vector3, EnumItem.
- **Two tweens on the same property:** the earlier one is cancelled and overwritten.
- `RepeatCount = -1` for infinite loops (not math.huge). `TweenService:GetValue(alpha, style, dir)` returns an eased alpha, which is what we need for custom Bezier paths.
- DevForum note: destroy finished tween objects in repeated effects (egg hatch), or they leak memory [FORUM].

## 7. World UI [DOC]
- **BillboardGui:** Size Scale = **studs**, Offset = pixels. StudsOffset is camera-relative and StudsOffsetWorldSpace is global. AlwaysOnTop, MaxDistance. Buttons inside only work if the BillboardGui is under **PlayerGui** with an Adornee.
- **ViewportFrame:** create a Camera, set `CurrentCamera`, parent it to the frame, then orbit it each frame. Lighting comes from Ambient, LightColor and LightDirection. Put models inside a **WorldModel** child so they can be animated (it gives "limited physics"). Create the WorldModel only while it's shown.
- **Highlight:** at most 255 on the client; disabled ones still count, so destroy them instead. DepthMode AlwaysOnTop/Occluded.

---

## 8. Camera and cutscenes [DOC unless marked]
- `workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable` stops the default camera scripts. Then set or tween `camera.CFrame`.
- In Scriptable mode, update **Focus** every frame (it drives level-of-detail), via `RunService:BindToRenderStep` at `RenderPriority.Camera`.
- **Restore:** `CameraSubject` = the local Humanoid (it can't be nil), `CameraType = Custom`. Check the character still exists first [FORUM].
- `Camera:Interpolate` is **deprecated**; use TweenService.
- FieldOfView 1-120, default 70. It's tweenable, which makes push-ins.
- Shift-lock and AutoRotate can interfere with cutscenes; set `Humanoid.AutoRotate = false` during one [FORUM].
- Start-on-join pattern [FORUM]: a LocalScript in a ScreenGui with `ResetOnSpawn = false`, or in StarterPlayerScripts.
- **ContentProvider:PreloadAsync(list, cb)**: preload only the cutscene's own sounds and decals, never the whole Workspace. Let players skip.
- **Moon Animator 2** [FORUM]: exports a KeyframeSequence or camera "Frames/FOV" folders. Camera export only needs the values replayed on a Scriptable camera, not an AnimationController. It's now sold on BuiltByBit (UNVERIFIED pricing/licence). We don't need it for v1.

## 9. Character and creature animation [DOC]
- An **Animator** lives in the Humanoid, or in an AnimationController for non-humanoid rigs. `animator:LoadAnimation(animation)` returns an AnimationTrack.
- **Replication:** the Animator **must be created on the server**. Client-played tracks replicate only for the player's own character. For any other model (a Dreamling), load and play on the **server** to replicate, or on the client for a local-only cosmetic.
- AnimationTrack: `Play(fade=0.1, weight=1, speed=1)`, `Looped`, Priority (Core < Idle < Movement < Action < Action2-4), `AdjustSpeed`, `AdjustWeight`, `Stopped` (finished) vs `Ended` (fully faded), `GetMarkerReachedSignal(name)` for SFX timing.
- **Ownership rule:** "animations are locked to experiences owned by users who also own those animations" (Transfer animations doc). If the game later moves to a group, re-publish the animations to the group. Since **2025-08-21**, animations can also be shared with connections, groups and experiences via Creator Hub > Permissions [FORUM, Roblox staff announcement]. Public sharing isn't available yet.
- **KeyframeSequenceProvider:RegisterKeyframeSequence:** "The asset ID generated by this function is temporary and cannot be used outside of Studio." It's a test-only path.
- **Rigging (Blender to Roblox):** rig first, then skin in Blender. Max **4 bone influences per vertex**. Bones frozen (scale 1, rotation 0). Root bone at origin with no influences. Export **FBX** (Path Mode Copy, Embed Textures, Apply Scalings = FBX Unit Scale). Studio turns the armature into **Bone** instances. Bones don't change collision. Rig types: R1 (single rigged mesh, good for simple creatures) and R15. Mesh triangle budget: sources disagree (10k vs 20k per mesh), so check before export.
- **Animation Editor** has a Curve Editor (warning: converting quaternion tracks to Euler can't be undone) and keyframe optimization.
- **2026 features (secondary source, UNVERIFIED):** Animation Graph System **beta** announced around 2026-04-08. Adaptive Animation full release around 2026-05-03 (one animation across different rigs).

## 10. Effects [DOC]
- **ParticleEmitter:** `Emit(n)` for bursts. Live particle count ≈ Rate × Lifetime. `LightEmission = 1` for additive glow, `Squash` for stretch over life, flipbooks up to 30 fps. Parent it to an **Attachment** to emit from a point.
- **Post-processing:** Bloom, Blur, ColorCorrection (Brightness, Contrast, Saturation, TintColor), DepthOfField, SunRays, ColorGrading. **Under Lighting = everyone; under Camera = only that player.** Put cutscene and dream-mode effects in the Camera. Tweening them works through TweenService (number/Color3 types) but the docs don't show it explicitly.
- **Camera shake:** Sleitnick/RbxCameraShaker (MIT, port of EZ Camera Shake with permission). Presets: Bump, Explosion, Earthquake, Vibration...

---

## 11. Catalog
| Name | URL | What | License | Use it? |
|---|---|---|---|---|
| Fusion | github.com/dphfox/Fusion | Reactive UI library | MIT | No (plain Instances instead) |
| react-lua (jsdotlua) | github.com/jsdotlua/react-lua | React 17 port; Roblox's internal UI stack | MIT | No (tooling-heavy) |
| Roact | github.com/Roblox/roact | Old React-like UI | Apache-2.0, **archived 2023** | No |
| Vide | github.com/centau/vide | Solid-style reactive UI, 0.4.1 (Jul 2026) | MIT | No (pre-1.0) |
| **spr** | github.com/Fraktality/spr | Single-module spring animator: `spr.target(obj, damping, freq, props)` | MIT | **Maybe**: vendor for springy pops; keep the MIT notice |
| Ripple | github.com/littensy/ripple | Spring/tween motion library (react-spring style) | MIT | No (spr is simpler) |
| TopbarPlus | github.com/1ForeverHD/TopbarPlus | Custom top-bar icons, dropdowns | **MPL-2.0 + mandatory credit** | Later, only if we want a top-bar gift icon; credit in the game description |
| **CutsceneService** | github.com/Vaschex/CutsceneService | Bezier multi-point camera cutscenes + plugin (DevForum t/718571) | MIT | **Reference only**: our intro is short enough to hand-write; borrow the ideas (points folder, DisableControls, restore CoreGui) |
| **RbxCameraShaker** | github.com/Sleitnick/RbxCameraShaker | Camera shake presets | MIT | **Maybe**, for the Legendary hatch shake; a 10-line random offset may be enough |
| VisualTweens | github.com/text21/VisualTweens | Glow, pulse and button-press tweens | MIT (per search result, UNVERIFIED) | Read for ideas only |
| RobloxFormatNumber | github.com/Blockzez/RobloxFormatNumber | Number formatting/abbreviation | UNVERIFIED | No: a 10-line suffix formatter is enough |
| studio-rust-mcp-server | github.com/Roblox/studio-rust-mcp-server | Old Studio MCP | MIT, **archived 2026-04-03** | No: use the built-in MCP |
| Moon Animator 2 | (BuiltByBit / DevForum) | Animation + camera timeline plugin | Commercial (UNVERIFIED) | Not for v1 |
| Smooth Cutscenes, CineCam | DevForum | Paid cutscene plugins | Closed source | No |

No open-source **simulator UI kit** or **egg-hatch module** on GitHub with a clear licence was found. The available ones are paid (BuiltByBit, itch.io) or forum-pasted code with no licence. We build our own from the recipes in UI_RULEBOOK.

---

## 12. Sources
Official docs (fetched as .md where possible):
- https://create.roblox.com/docs/studio/mcp
- https://create.roblox.com/docs/ui/position-and-size.md
- https://create.roblox.com/docs/ui/size-modifiers.md
- https://create.roblox.com/docs/ui/appearance-modifiers.md
- https://create.roblox.com/docs/ui/animation.md
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ui/list-flex-layouts.md
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ui/grid-table-layouts.md
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ui/scrolling-frames.md
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ui/buttons.md
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ui/viewport-frames.md
- https://create.roblox.com/docs/reference/engine/classes/ScreenGui.md
- https://create.roblox.com/docs/reference/engine/classes/TextLabel.md
- https://create.roblox.com/docs/reference/engine/classes/UIGradient.md
- https://create.roblox.com/docs/reference/engine/datatypes/Font.md
- https://create.roblox.com/docs/reference/engine/classes/TweenService.md
- https://create.roblox.com/docs/reference/engine/classes/BillboardGui.md
- https://create.roblox.com/docs/reference/engine/classes/WorldModel.md
- https://create.roblox.com/docs/reference/engine/classes/Highlight.md
- https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter.md
- https://create.roblox.com/docs/workspace/camera.md
- https://create.roblox.com/docs/reference/engine/classes/Camera.md
- https://create.roblox.com/docs/reference/engine/classes/ContentProvider.md
- https://create.roblox.com/docs/animation/using.md
- https://create.roblox.com/docs/reference/engine/classes/Animator.md
- https://create.roblox.com/docs/reference/engine/classes/AnimationTrack.md
- https://create.roblox.com/docs/reference/engine/classes/KeyframeSequenceProvider.md
- https://create.roblox.com/docs/projects/transfer-animations
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/animation/index.md
- https://create.roblox.com/docs/en-us/art/modeling/rigging.md, /art/modeling/specifications, /art/modeling/export-requirements
- https://create.roblox.com/docs/en-us/environment/post-processing-effects.md
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/cloud-services/data-stores/index.md

GitHub: dphfox/Fusion (+releases), jsdotlua/react-lua, centau/vide (+releases), Roblox/roact, Fraktality/spr, littensy/ripple, 1ForeverHD/TopbarPlus (+LICENSE), Vaschex/CutsceneService, Sleitnick/RbxCameraShaker, Roblox/studio-rust-mcp-server.

Forum and secondary: devforum t/718571 (CutsceneService), t/3892540 (animation sharing, 2025-08-21), AutomaticCanvasSize threads (t/3571979, t/3659573, t/3788583), Pet System [Open Source] t/1141510 (tween leak note), Moon Animator threads (t/975405, t/1995906), creation.dev 2026 update roundups (Animation Graph beta, Adaptive Animation).
