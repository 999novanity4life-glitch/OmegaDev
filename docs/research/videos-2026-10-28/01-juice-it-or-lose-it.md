# Juice it or lose it - a talk by Martin Jonasson & Petri Purho
- Channel: grapefrukt | URL: https://www.youtube.com/watch?v=Fy0aCDmgnxg | Length: 15:38 | Upload: 2012-05-24 | Captions: manual

- [0:11] Juice means things that "wobble, squirt, bounce around or make cute noises": a catch-all for whatever makes the game feel good to interact with.
- [0:41] Definition (from the Gamasutra article "How to prototype a game in under 7 days"): a juicy game "feels alive and responds to everything you do", with cascading action and response for minimal input. Aim for maximum output from minimum input.
- [1:13] Juice does not have to be visual or audio. Interactive fiction gets it from fun, unexpected responses when the player tries something they aren't supposed to do.
- [1:44] Their claim: adding juice makes a game better "100% of the time". Every effect in the demo leaves the gameplay unchanged.
- [2:14] Start with color. Make it easy to tell good guys from bad guys instead of making everything brown.
- [2:49] Tweening ("in-betweening", also called easing): give a start value, an end value, a duration and an easing equation, and it fills in the frames between. It works on any property.
- [3:49] A cheap fallback when no tween engine is available: every frame, move x 10% of the way to its target. It starts fast and slows down as it gets close.
- [4:19] Tween the blocks' positions when the level appears so they fall in. Easing upgrades in order: linear, then a slowdown (ease-out), then one that goes slightly past the target (overshoot/back), then a bounce equation.
- [4:49] Tween rotation and scale as well as position.
- [5:19] Give every block's intro tween a small random delay, so they arrive staggered instead of all at once.
- [5:52] "Squeeze and stretch": scale the paddle on x and y based on the offset between the mouse pointer and the paddle. No easing is needed for this.
- [5:52] On impact, scale the ball up, then ease it back down to normal size.
- [6:23] Rotate the ball toward its direction of travel and animate that rotation (very subtle). Stretch the ball along its velocity. They note this looks better with gravity and a round ball.
- [6:54] Animate the stretch after a hit so the ball wobbles for a moment. Also flash the ball white on every hit, then ease it back to its normal color.
- [6:54] When the ball hits anything, run a small scale tween on all the blocks, not just the one that was hit.
- [7:25] Bouncy lines: the wall lines wobble when the ball hits them.
- [7:25] Sound is "the most cost-effective" juice and is often ignored. In the Game Feel (Steve Swink) demo, two circles that pass through each other appear to bounce off each other once a sound is added.
- [8:28] Layer the sounds in: wall bounce, block hit, paddle hit, then music. With only sound added, it "feels almost like a real game".
- [9:31] Rule of thumb: "you can't ever have too many particles". Begin with a puff of smoke wherever the ball hits something.
- [10:03] Don't fall into the trap of building your own particle engine. Use one that already exists.
- [10:34] Stack simple effects to remove a hit block: fade it out (a tween), make it fall off the screen, push it in the ball's direction, spin it, and darken it so it stands out from the blocks still in play.
- [11:04] A complex shatter effect "no one can tell" apart from the simple version. It is another trap for programmers.
- [11:35] More particles on block hits, confetti on paddle hits ("confetti always works"), and a ball trail drawn by recording past positions and connecting them with a line.
- [12:07] Screen shake is one of the best effects for the effort: shake everything a little when the ball hits something. Use it carefully, because at high intensity it goes into "freight train mode".
- [12:41] Kyle Gabler's trick: add eyes to things. To blink, hide the eyes briefly. Have them look toward the ball, add a mouth that smiles on a hit (scale its y), and frown when the ball moves away. Bigger eyes work better. It costs almost nothing and adds a lot of personality.
- [14:18] Their final before-and-after: switching on every effect at once transforms the game, though it "still murders the framerate". Keep an eye on performance.

Applies to Roblox how (inferred): Use TweenService with EasingStyle Quad/Back/Bounce plus small random delays for spawn-in and UI entrance animations. Add squash and stretch and white-flash tweens to hit targets and buttons, attach SFX to every interaction, and add ParticleEmitter:Emit() bursts, Trails and a light Camera shake on impacts, while watching the frame rate.
