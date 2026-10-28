# Visual QA: the reference-board review gate

No screen, zone, effect, model or UI kit reaches the human until it passes this gate.
It exists because self-review approves weak visuals: in the
[claude-roblox-gamedev-kit](imported/claude-roblox-gamedev-kit/README.md) project one
effect was rejected eight times while self-reviews kept passing it. "It follows the
rules" is not "it looks good" (same source, Lessons Learned > Feedback and taste).

Tags: **[DOC]** create.roblox.com, **[KIT]** the imported MIT kit, **[RULE]** studio rule
(our decision, not a fact).

## 1. Before building: the goal board
1. Collect references into `games/<slug>/art/refs/<item>/`: 8-12 images of the target
   style plus, for anything realistic, 6-10 real-world photos [KIT]. Prefer stills from
   shipped games the human named, Roblox showcase places, and real photos. Log each
   source URL in `refs/<item>/SOURCES.md`.
2. Write `refs/<item>/BRIEF.md`:
   - the goal in one sentence the human would agree with;
   - **MUST** (5-8 lines: what has to be visibly true, e.g. "lit exit is the brightest
     thing in frame", "button outline 3 px darker shade of fill");
   - **MUST NOT** (the failure looks: flat grey lighting, default Studio skybox, plastic
     everywhere, text under thumbstick, floating props, see-through mesh faces);
   - **measured targets** taken from the references, not invented: colours as hex,
     outline widths, corner radius, font, spacing; for worlds the palette, sun time,
     fog distance, light colour temperature.
3. Make one captioned board image (`refs/<item>/goal.png`) with the 4-6 best references.
   Show it to the human first when the ask is vague or a previous round was rejected [KIT].

## 2. Capture: shots the reviewer will see
Use the Studio MCP (`screen_capture` takes an optional camera position and look-at),
holding the studio lock. Capture in Play mode, not Edit, for anything with particles,
UI or lighting that scripts set [KIT: particles only simulate in the real camera view;
hold the camera 2-4 s before capturing].

| Item | Required shots |
|---|---|
| World zone | spawn shot (first frame a new player sees); usual play camera; a vista into the next area; one close-up of the hero prop; same set at a second time of day if the game has one |
| UI screen | each state (idle, hover/pressed, empty, error, reward) at phone landscape and desktop in the Device Emulator [DOC: [implement designs](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/implement-designs-in-studio)]; one with chat and player list open [DOC: [wireframe](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/wireframe-your-layouts)] |
| Model / prop | usual view at in-game distance; reveal close-up; from below [KIT]; next to a 5-stud avatar block for scale |
| Effect | a strip of 6-10 frames ~0.1 s apart from the game angle plus two others, in daylight [KIT] |

Save to `games/<slug>/playtests/<date>/visual/<item>/`. Reset the Edit camera at the end
(screenshots can leave it Scriptable [KIT]).

## 3. Scene audit (numbers, not opinions)
Run `scripts/studio/scene-audit.luau` with `execute_luau` (Edit or Server datamodel) and
save the output next to the shots. It reports lighting settings, post effects, part and
light counts, materials in use, transparent parts, SurfaceAppearance count and shadow
casters. The reviewer reads it with the shots. Thresholds live in the game's BRIEF, not
here; starting points are in `vault/15 Lighting and Realism.md`.

## 4. The blind review
Spawn the `visual-reviewer` agent fresh for every round. Give it ONLY:
- the goal board and BRIEF (goal, MUST, MUST NOT, measured targets);
- the captured shots and the scene audit.
Never give it the builder's reasoning, the previous round, or "what we changed" [KIT].

It returns, per shot: what it sees, cold (before reading the BRIEF); then each MUST and
MUST NOT as PASS/FAIL with the shot that proves it; then the single most important fix.
Overall verdict is PASS only if every MUST passes and no MUST NOT is visible.

## 5. Rounds
- Fix the top finding only, recapture, new reviewer. A fix to motion or layout must not
  change a look the human already liked [KIT].
- **Three rounds max.** If the same check still fails, stop and give the human options
  with the crops: switch approach, accept named flaws, or park it [KIT].
- PASS: `omega review add --game <slug> --agent <you> --kind image --title "<item>: passed visual QA" --file <goal-vs-ours.png>`
  with the reference board and our best shot side by side.

## 6. Record
- What worked and what was rejected (in the human's words) goes in `games/<slug>/docs/LOOK_LOG.md`.
- New failure modes go in `vault/15 Lighting and Realism.md` or the relevant chapter
  as a one-line rule with its why.
- When the human approves a look, freeze it: later changes touch only what they name [KIT].
