# Animation Bootcamp: The First Person Animation of Overwatch
Note: picked as the closest official GDC Overwatch talk. It covers first-person animation, not Overwatch's art style.
- Channel: GDC Festival of Gaming | URL: https://www.youtube.com/watch?v=7t0hLZd_8Z4 | Length: 34:03 | Upload: 2017-04-28 (GDC 2017, Blizzard animator Matt Boehm) | Captions: auto

- [1:37] Keep the hero's personality when the character becomes hands, a gun and a camera.
- [2:38] "Gameplay first." The first-person animator must not add visual noise and should stay out of the player's way. Animation must be responsive, must not take too much control away, and must give both visceral and gameplay feedback.
- [4:09] Classic principles carry straight into first person: overlapping action, overshoots, squash and stretch, and snappy timing, "all building up to appeal".
- [5:40] First-person rigs are a pared-down third-person rig with unseen parts culled. Keep anything an ability needs.
- [6:10] Camera motion is animated mainly from the root. A separate camera bone adds only small accents, "nothing too heavy and extreme."
- [7:11] The classic weapon attachment bone sits under the hand, so the weapon follows the arm without IK, and the off hand can IK to it.
- [8:42] Downside: if a hand moves away, sub-frame interpolation makes the weapon drift. A quick fix is to reload with the other hand.
- [10:47] A better fix is a weapon attachment bone under the root plus hand control bones.
- [11:47] Use parent spaces built into the rig.
- [13:18] All of a character's first-person assets live in one Maya file, using animation layers: a base pose layer cascades into grouped layers (fire, run, jump), plus override layers.
- [14:49] Layer variants on top of base animations.
- [15:21] Start with a "golden pose" that the whole team piles onto. Consider negative space and lead the eye toward the vertical center where the gun aims.
- [16:24] Model and pose weapons for the first-person camera. Widowmaker's early rifle did not read as a rifle until they iterated on the camera FOV with the weapon modeler.
- [16:54] Separate the world FOV from the viewmodel FOV, so players can widen world FOV without stretching the authored pose.
- [18:59] With a fixed camera you can "cheat the hell out of" poses, because the broken side is never seen.
- [19:29] After the golden pose, add additive overlays: spring-based aim lag-and-lean and roll poses, with spring values tuned per hero. These give character, not just lag.
- [20:31] Per-hero spring feel: McCree is cocky and tight; Zenyatta "flows and snaps"; Roadhog is super loose; Bastion is a chunky old war bot.
- [22:04] Add run leans: tilt for side-to-side and forward/back running.
- [23:05] Balance physical feel against motion sickness. Overlays move the arm off-screen when you look up.
- [24:36] Add camera translation for weight, but avoid too much rotation, especially roll, which causes seasickness.
- [25:11] Pull character from collaboration and story.
- [26:43] Firing: don't export the idle first frame. The first shot frame is stretched far forward with the barrel scaled up, then snaps back the next frame and rocks up: "Push It Forward snap it back."
- [27:49] Automatic fire: a big single-shot fire, then smaller shots that ramp into a single "accumulate" pose, with an additive outro on release.
- [28:16] Reloads must tell the player they can't fire. Don't cover the reticle, but move or rotate the gun away from it.
- [29:17] Reloads should express personality.
- [31:20] Melee uses the same stretch-and-snap idea: weapon off-screen on frame 1, the hand comes in, a super stretch around frame 4, snap back, then a short hold.
- [31:53] Forward camera translation sells melee impact. Check player collision first: in alpha, McCree's face went through walls.

Applies to Roblox how (inferred): For first-person or over-the-shoulder combat, render a client-side viewmodel at its own FOV, layer spring-based sway and lean per character, and use stretch-and-snap keyframes for attack anticipation. Clamp camera roll and forward offsets, and raycast before pushing the camera so it doesn't clip into walls.
