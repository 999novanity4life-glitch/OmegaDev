# Jan Willem Nijman - Vlambeer - "The art of screenshake" at INDIGO Classes 2013
- Channel: Dutch Game Garden | URL: https://www.youtube.com/watch?v=AJdEqssNZ-U | Length: 44:09 | Upload: 2013-12-16 | Captions: auto (garbled in places, e.g. "lurp" = lerp, "sleeves" = sleeps)

- [4:18] Model: the game reaches the player through visuals and sound, the player sends input back, and the game shows the change. Vlambeer focuses on that feedback loop ("I press a button and a bullet flies").
- [6:54] The talk is reframed as "30 tiny tricks that will make your action game better", applied step by step to a plain platform shooter.
- [8:25] Start with basic animations and sound. The sounds were made in sfxr, and sound alone makes shooting feel much better.
- [8:58] Lower enemy HP, raise the rate of fire, and use more enemies with less health each. The numbers come out about the same but it feels better.
- [9:59] Bigger bullets. Tiny dots are a beginner mistake; game bullets should be roughly "the size of your chest". Make them faster as well.
- [10:33] Muzzle flash: make the first frame of the bullet sprite a circle. It's a cheap trick Vlambeer always uses.
- [11:04] Lower accuracy (bullet spread) makes each shot look different and is more fun to watch.
- [11:34] Impact effects: play a small effect where a bullet hits a wall or an enemy, so bullets don't simply disappear.
- [12:06] Hit feedback: enemies flash white and switch to a slightly different pose when hit.
- [12:36] Enemy knockback: push enemies back a few pixels when hit. This creates dynamic combat situations, such as enemies ending up flanking you.
- [13:07] Permanence: leave corpses, debris and rubble after a fight so the player can see a battle happened there. Like a bar shootout in a film, missed shots should hit props.
- [14:37] Camera lerp: have the camera trail slightly behind the player and smooth into position.
- [15:07] Camera framing: the camera should show what you're shooting at, not center the player. Shift it ahead toward the aim. In Luftrausers it also dips toward the water and drifts toward the average position of the bullets.
- [16:41] Screen shake: the usual answer to "how do I improve this", because "nobody does it and it's super easy". Shake a little on shooting and more on impacts.
- [17:13] Player knockback when firing. If there's a fire button, give the player a reason not to press it; otherwise the game could just fire automatically.
- [17:44] Sleep (hit-stop): freeze the game for about 20 milliseconds on hits and kills. The brain gets more time to register the impact without consciously noticing the pause.
- [19:18] Gun delay and kick: let the gun trail slightly behind the character and recoil visibly when fired.
- [19:48] Strafing: let the player walk backwards while shooting. Turning around then costs a little time, which is another small reason to stop firing.
- [20:19] More permanence: spent shells that stay on the floor forever. "Computers nowadays can handle" it.
- [21:53] More bass in sound effects. A Raven Software designer "fixed" an unpopular gun by bass-boosting its sound by 12 dB, and it became one of the most popular guns in the game.
- [23:27] Exaggerate weapons, e.g. a triple-shot machine gun. Add random explosions: a 33% chance that enemies explode on death.
- [23:59] Rebalance as you go: faster enemies, more enemies, and an even higher rate of fire.
- [25:44] Camera kick: on firing, also move the camera slightly in the opposite direction to the shot, on top of the random shake.
- [26:45] Advice from Cactus: "make really big explosions". Vlambeer's explosions are just a circle that flashes from black to white. Add smoke that slowly fades so the aftermath stays visible.
- [28:18] Add meaning: real failure and game-over states, so enemies threaten you and there's something to fight for.
- [29:19] Fake slow motion by dropping the frame rate to 10 fps at a dramatic moment, then speeding back up.
- [32:27] Q&A: offer an option to turn screen shake off, since some players got nauseous in Nuclear Throne. Designers get used to their own shake, so playtest it on other people.
- [33:30] You are "the worst play tester in the world" for your own game, because you subconsciously avoid its problems. Watch other people play.
- [35:32] Process: Vlambeer prototypes a game in a couple of days, then spends about a year polishing it.
- [38:34] His claim: probably every game, even a puzzle game, would benefit from screen shake.

Applies to Roblox how (inferred): Use a Camera offset that springs or lerps toward the aim direction, with brief shake and recoil kick on shots. Add a short hit-stop (for example, pausing animations for about 20 ms), white-flash Highlights, knockback impulses, and debris and shells that persist within part budgets. Bass-heavy SFX help, and screen shake needs a settings toggle.
