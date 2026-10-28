# Game Feel: Why Your Death Animation Sucks
- Channel: GDC Festival of Gaming | URL: https://www.youtube.com/watch?v=pmSAG51BybY | Length: 22:37 | Upload: 2015-10-16 | Captions: auto (speaker is Nicolae Berbece, game: Move or Die)

- [1:33] Feedback means the physical response to input, the way a controller button feels better than a touchscreen.
- [2:05] Game feel goes beyond games. Phone keyboards pop the letter above your finger and play a click or vibrate. This is functional, not just cosmetic: you don't have to look away to confirm the input registered.
- [3:05] A bad example: a shotgun with no muzzle flash, a smoke asset that lasts about 3 frames, and a cheap sound that makes it feel like a toy with no weight. Bulletstorm's flail gun is the good counter-example.
- [4:07] Game feel is noticed only when it's missing: "This game feels good, but I don't know why."
- [4:37] He builds a satisfying death in Move or Die without any hand-drawn frame-by-frame explosions. The baseline (the character vanishes instantly) "feels bad" and isn't rewarding.
- [6:41] First add animations. Split the character into many small parts and animate those parts (he uses Adobe Flash).
- [7:43] "Asset sheets" instead of sprite sheets: export each body part once, plus the animation as a text file of per-frame x, y, scale, rotation and alpha. The sprite sheet would be 5700x3100 px; the asset sheet is 460x210 px, under 1% of the pixels.
- [8:44] Asset sheets give you individual control: for example, change one limb's scale in code at runtime without re-exporting.
- [9:15] Keyframes stored as data can be interpolated, so slow motion stays smooth instead of choppily repeating sprite frames.
- [10:50] Sound changes the whole feel and shouldn't be left until last. The same footage given to different sound designers felt completely different (one moodier, echoey, "a bigger environment").
- [12:30] Movement SFX should be subtle with a lot of variation. Turn the volume down, then randomize the pitch on every play: "one line of code" instead of multiple files.
- [13:30] Skip footsteps when characters are tiny and very fast; with 4 players it would be "suicidal".
- [13:30] Layer the death sound: a strong impact, a smaller impact, and a "satisfying squishy sound" combined into one.
- [14:00] Environment SFX add context and weight, e.g. disappearing blocks get a sound, and a knocked-over chair should be heard hitting the floor.
- [15:01] "Death paint": spawn a splatter in the player's color in the background where they died, as a reward and a record of the kill. Vary its rotation and scale.
- [15:32] Render the splatter behind everything except the background. Add a second paint layer in the foreground, masked by an alpha mask of the ground and tiles and set to additive blend, so the paint looks like it lands on the surfaces.
- [16:33] Add particles that fly out of the dead player and leave splatters wherever they touch ground or tiles. Splatters fade over time, which shows when each death happened.
- [17:34] Final touches: screen shake on death, toned down from the exaggerated demo version.
- [17:34] Chromatic aberration: split the color channels, offset them, and animate the offset on death. He calls it "the new lens flare of 2015" and shows it exaggerated.
- [18:05] Shockwave: a growing white donut used as a full-screen displacement map, creating a ripple on death.
- [18:05] Haptic feedback: the controller vibrates on death.
- [19:07] Screen-wide effects also act as "peripheral vision": players know someone died elsewhere without having to look.
- [19:38] Other details: kickable props on the ground give the world weight and depth. Landing dust is so readable that one mode, where every player is invisible, relies on it.
- [19:38] Eyes give characters personality: they look at each other, are happy when they win, cry when they lose, and give each other mean looks when tied.
- [20:08] Rhythm: background elements pulse to the beat of the music.

Applies to Roblox how (inferred): Layer death and hit SFX with randomized Sound.PlaybackSpeed, decal splatters with random rotation and size that fade via TweenService, ParticleEmitter bursts, and Camera shake. Use a short ColorCorrection or Blur pulse as a stand-in for chromatic aberration or shockwaves, and HapticService vibration on gamepad. Pulse UI or lights to the music beat.
