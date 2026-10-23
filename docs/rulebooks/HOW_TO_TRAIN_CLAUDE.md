# How to train Claude on this game (2026-10-23)

Claude has no memory between sessions except this folder. "Training" means putting the right material in the vault, in a form Claude can act on, and closing the loop with verdicts on what it builds. The skill file (`~/.claude/skills/roblox-game-dev/SKILL.md`) sets the read order, so anything placed in the files below is loaded automatically next session.

## 1. How learning actually works here
| Layer | File | What goes in | Who writes |
|---|---|---|---|
| Taste | `STYLE_GUIDE.md`, `references/` + `INDEX.md` | What the game should look and feel like, with named examples | Sharman (Claude tidies) |
| Research | `research/*.md` | Sourced facts, catalogs, comparisons, each claim tagged [DOC]/[GH]/[FORUM]/UNVERIFIED | Claude |
| Rules | `reference_dev/*_RULEBOOK.md`, `ROBLOX_ENGINEERING_RULES.md` | Distilled, numbered rules Claude follows when building | Claude, from research + verdicts |
| Proven how-to | `ROBLOX_STUDIO_NOTES.md`, `BLENDER_NOTES.md` | Only things that worked in Studio or Blender | Claude, after a passing test |
| Log | `LEARNINGS.md` | Dated entries: built, worked, failed, next | Claude, every session |
| Decisions | `DESIGN/*.md` | PROPOSED until Sharman says yes, then DECIDED with a date | Both |

A rule moves up the table only with evidence: research gives a candidate, a Studio test or a verdict from Sharman confirms it, then it becomes a rule or a proven note. That is the anti-hallucination mechanism. Anything Claude cannot source stays labeled UNVERIFIED and gets tested before it is relied on.

## 2. What to give Claude, ranked by value per minute of your time

1. **Verdicts on screenshots.** After every build step Claude posts a `screen_capture`. Reply with one of: `yes`, `no: <one reason>`, `closer: <what to change>`. Each "no" reason becomes a rule. This is the highest-value input and costs you ten seconds.
2. **Named targets per area.** "Map like Pet Sim 99's spawn, bedrooms like Adopt Me houses, hatch like Steal an Egg, HUD like reference 01." A named target lets Claude research the exact thing instead of guessing a style. Put them in `STYLE_GUIDE.md` under "Three games it feels like".
3. **Screen recordings of moments you like.** For animation and cutscenes, a 10 to 30 second phone recording of a hatch, a menu opening, or a teleport transition beats any description. Drop the file in `references/` and add one line to `references/INDEX.md`: `file | game | what to copy (timing, motion, sound)`. Claude reads video frames and extracts timing and sequence.
4. **Screenshots of UI and maps you like, with one line each.** Same INDEX.md format. Three screenshots with reasons taught Claude the HUD layout in one session; thirty without reasons would not.
5. **The actions only you can do.** Claude cannot upload animations, import meshes to your account, enable API services, or accept Creator Store licenses. Batch these: Claude prepares a list (FBX files in `assets/models/`, animation names, settings to flip), you do them in one sitting, then Claude continues. Say when you are at the keyboard for this.
6. **Save the place.** After every session, File > Save to Roblox (or Save to File into this folder). Claude rebuilds from `src/`, but Studio-side imports and settings live only in the place.
7. **Phone playtest notes.** Play on your phone for five minutes and write what felt wrong: "buttons too small", "camera jerks at X". Claude cannot feel a phone.
8. **Style decisions when asked.** Claude will present two or three options (palette A/B/C, wheel slice rule). Pick one. An unpicked PROPOSED item blocks the features that depend on it.
9. **Assets you own.** UI kits, icon packs, fonts, sound packs you bought or downloaded under a clear license. Put them in `assets/` and add a line to `assets/SOURCES.md` with the license. Claude will not use assets whose license is unknown.

## 3. What not to give
- "Make it better" or "make it look pro" with no example. Claude will pick a direction you did not want.
- Large tutorial dumps or playlists without saying what to pull out of them. Say "extract the hatch timing" or "extract the modular kit grid size".
- Decompiled or ripped assets, free-model UI with unknown authors, or animations you do not own. They fail the license rule and risk moderation.
- Verdicts on code. Judge the result in Studio or on screen; Claude judges the code against the rulebooks.

## 4. Formats Claude reads best
```
# references/INDEX.md (one line per file)
ui_ref_04_hatch.mp4 | Steal an Egg | copy: 1.5 s shake build-up, rarity flash, name slams in with Back easing, sound hits on the flash

# A verdict (chat)
no: the room still reads as a box, the roof needs an overhang and the walls need trim at the top

# A decision (DESIGN/*.md)
DECIDED 2026-10-23: palette A (Moonlit Nursery); C reserved for the Nightmare zone
```

## 5. The loop every feature goes through
Research (sourced) -> rulebook entry -> blockout in Studio -> screenshot -> your verdict -> fix -> acceptance test in play mode with zero Output errors -> LEARNINGS entry -> proven how-to promoted to the notes files. Skipping the verdict step is how slop gets in: Claude will pass its own tests and never know the result looks cheap.

## 6. A good training session (about 30 minutes of your time)
1. Drop 3 to 5 references with one-line reasons (10 min).
2. Answer the PROPOSED items Claude lists at the start (5 min).
3. Do the keyboard-only actions Claude queued (10 min).
4. Give verdicts on the screenshots Claude posts while you are away (whenever).

## 7. What Claude does on its side
- Reads the whole folder in the skill's order before touching Studio.
- Researches with sources before building anything new, and labels what it could not verify.
- Builds in small steps with a screenshot after each, so a wrong direction costs one step.
- Writes every learned rule into the rulebooks with its source, and every failure into LEARNINGS, so the next session starts further along.
- Re-verifies the rulebooks against official docs on request (last full pass: 2026-10-23).

Current deep references for the three craft areas: `reference_dev/BUILD_RULEBOOK.md`, `reference_dev/UI_RULEBOOK.md`, `reference_dev/ANIMATION_CUTSCENE_RULEBOOK.md`, with the sourced research behind them in `research/`.
