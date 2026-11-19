# Showcase helpers: Studio playtest evidence (2026-11-19)

Run on Pranay's Mac, Roblox Studio, blank Baseplate (unsaved Place1), modules
loaded from this branch, Studio MCP `execute_luau` on the Client.
The avatar in the shots is the Studio account's own; nothing of it ships.

| Check | Result |
|---|---|
| Ultimate cam: pushIn 2.5 → heroOrbit 3 → whipToFront 1.2 → craneOut 2.5 | all 4 shots fired on time (0.04 / 2.51 / 5.51 / 6.71 s), done at 9.24 s |
| Hit on shot 3, tier Ultimate | recipe hitStop 0.12, shake 0.90, FOV +10, 4 impact frames, slow-mo 0.80 s |
| After the cutscene | CameraType Custom, subject Humanoid, FOV easing back to 70, bars removed |
| Skip mid-shot | Skip visible after 1 s; after stop: Custom, Humanoid, FOV 70.0, letterbox and Skip GUIs gone |
| TrailerMode.take | game ScreenGui hidden during the take and restored after; console printed `OMEGA_TAKE` start / 3 shots / end |
| Console | zero errors or warnings from our scripts. Studio's assistant logged "execute_luau changed camera type" resets, which is the MCP tool itself |

Screens: 1 push-in with letterbox, 2 hero orbit from the front (after the fix),
3 crane-out, 4 burst + sparks + speed lines (particles frozen with TimeScale 0
for the shot), 5 impact frame (ColorCorrection, held long for the shot),
6 frames from the rendered Remotion demo trailer (stand-in footage).

Fixed during the test: heroOrbit started behind the character (now front-left);
CinematicCamera now re-asserts Scriptable each frame.
Tuning note: the burst core blows out at 3x; lower `Core` size or EmitCount
per game. Not yet run: a real recording through capture-mac.sh (needs a
Remote Control session and Screen Recording permission on the Mac).
