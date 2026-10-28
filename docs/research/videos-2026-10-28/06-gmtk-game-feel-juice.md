# Secrets of Game Feel and Juice
- Channel: Game Maker's Toolkit (Mark Brown) | URL: https://www.youtube.com/watch?v=216_5nu4aVQ | Length: 5:19 | Upload: 2015-02-17 | Captions: manual (en-GB)

- [0:00] Contrast test: the same genre (run-and-gun) can feel "limp and lifeless" or alive. Game feel is what makes the difference, not the genre.
- [0:32] Game feel lives in the core second-to-second action. It is "mostly abstract, largely invisible" but players notice it the moment they touch the controls.
- [0:55] Strip-down test: remove the points, story, graphics, music and level design. Is the game still fun to interact with? If not, fix that first.
- [1:06] Mario 64: Miyamoto reportedly spent the first few months tuning only Mario's movement in an empty room before building anything else. Friction, momentum and weight come first.
- [1:36] The level design and enemies exist to let players express and master the core moveset.
- [2:40] Screen shake on firing, hitting and killing gives instant feedback that the player is "touching the world" (Vlambeer).
- [2:50] Hit pause: freeze the game for a split second on a hit or kill to make impacts land. Street Fighter, God of War and Zelda all do this.
- [3:10] Make damage unmistakable: a white flash, knockback, a blood spray, an animation change and a satisfying sound. "Anything you can add… is worth it."
- [3:25] Tie the player character into the world with dust particles on landing and recoil when shooting.
- [3:31] Sound effects should be "bassy and loud". Randomize them to avoid repetition.
- [3:41] Rising pitch on a combo (Mario stomps, Peggle) sells a streak.
- [3:54] Be creative with the camera. Luftrausers frames the action and nearby threats rather than locking onto the player. Hotline Miami pushes the camera far ahead in the aim direction.
- [4:05] "Make stuff big. Really big." Bullets the size of your face (Nuclear Throne), atom-bomb explosions (Super Time Force), geysers of blood (Hotline Miami).
- [4:14] Permanence: bodies and blood stay where they fall, which makes fights feel hard-won.
- [4:30] Juice should double down on what the game is about. In a shooting game the gun kicks, the fire rate is fast and the camera shudders each shot. In a jumping game the character has friction and the camera stays still so jumps can be landed.
- [4:44] Polish should "speak to what the game is really about". Don't stack effects at random.

Applies to Roblox how (inferred): Tune the Humanoid's WalkSpeed, JumpPower and acceleration on an empty baseplate before building content. Then layer hit pause, Camera shake through a CFrame offset, a white Highlight flash, ParticleEmitter:Emit() bursts and pitch-randomized Sounds. Leave debris and decals in place for a while instead of destroying them right away.
