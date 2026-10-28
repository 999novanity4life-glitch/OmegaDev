# Hearthstone: How to Create an Immersive User Interface
- Channel: GDC Festival of Gaming | URL: https://www.youtube.com/watch?v=axkPXCNjOh8 | Length: 30:35 | Upload: 2015-06-15 | Captions: auto | Speaker: Derek Sakamoto, senior UI designer on Hearthstone (GDC 2015)

- [0:52] The talk's three principles: "find your seed", "let's get physical", and "UI gets to sit at the big kids table".
- [1:01] A "seed" is a muse (an image, movie or song) the whole team can look at to understand where the game is headed. Without one you are "running around in the bushes". Early attempts (Tron-like visual target, world-map zone unlocking, hologram cards, an over-the-top matchmaking screen) all failed for lack of one.
- [2:03] Prototype cheaply first. The whole game was built in Flash first, with working single-player Adventures, before the final art direction existed.
- [3:34] The seed came out of a long artist/UI meeting and turned into a short 3D concept video: zoom into a box, pick a zone on a world map, the map rips open, you dive into a living world, then zoom out onto the game board.
- [4:35] Once the seed existed, the UI followed from it. The box was treated like a jewelry box or music box with trays and keys, and loading screens show diegetic motion such as hinges tightening.
- [5:07] Keep asking questions of the seed ("where is this table?"). The answer, an inn or tavern, gave the mobile splash screen, a loading screen that pushes open tavern doors with a warm glow, and a "table's full" sign when servers are full.
- [5:37] A strong seed can be handed off. A third party used it to build the tavern as the BlizzCon finals stage, and it shaped the key art.
- [6:38] How they found the seed, step by step: flat parchment, then 3D and more physical, then more magic, then a layer of charm, then "valuable and constructed". The path is never direct, so look for the seed actively and early. It makes everything "feel like it's one thing".
- [7:40] Go against trends when the project needs it. While the industry was moving to flat 2D UI, they committed to physical, 3D, tactile UI.
- [8:40] Physical materials (gold, gems) tell players what is valuable. In a free-to-play game this shows respect for players' time and money.
- [9:13] Recreate the core ritual with sight and sound. Opening a card pack was built to feel like a real pack (the crinkle, the foil), using only visuals and audio.
- [9:47] Use a shared motion language so separate screens feel like one product. The announcement screen, matchmaking spinner and store all use bounce and over-rotation.
- [10:19] Make objects respond to input: cards tilt and swoosh as you drag them, and dust flies up when you tap the board. Without being planned for it, this turned out to be very satisfying on touch devices.
- [11:19] Aim for "over the shoulder appeal". Someone walking past should be drawn in, not turned off by a wall of words and numbers.
- [11:49] Add "board clickables", props players can fidget with between turns (for example launching a rocket ship).
- [13:21] Downside 1, expandability. Hand-crafted layouts are hard to extend (for example, adding a tenth hero to a nine-slot screen). Their stance is to "design for now" because of tight deadlines and to give every element its own home.
- [14:23] Downside 2, cost. The collection manager alone took about two years. Their argument is that "our game is UI": there is no big world, only the board and the box, so that is where the investment goes.
- [14:54] Downside 3, navigation takes many clicks. Their rule is "flavor over efficiency": drawers slide and the box folds so you keep a sense of place, with no instant jumps. But "gameplay first" wins once it really hurts players, and they acknowledged they needed to fix it.
- [15:54] Downside 4, multiple platforms. Desktop and tablet are similar, but phone needs a complete overhaul. Some screens have to split into two.
- [16:26] If physicality is not right for your game, find the one trait that best defines it and take it as far as it will go.
- [16:57] Don't "slap a UI on" after the mechanics are done, and don't treat UI as second class (no dedicated programmer or artist). UI should have parity with game design.
- [17:27] UI mockups work like a canary in the coal mine. Designers hand over a loose spec of a couple of sentences, and if the mockup looks very complicated, the design probably needs simplifying.
- [17:57] "Nobody reads." They cut the play screen's mode, class and hero-power text and numbers, so players learn them by playing and the screen isn't scary.
- [18:27] They capped the board at 7 minions rather than shrinking cards as more are added. Changing scale hurts the sense of physicality and value, and the limit became a gameplay mechanic.
- [18:57] UI pushed back on design: decks went from 60 cards (three pages of scrolling) to 30. The old Priest hero power (+1 Attack/+1 Health) cluttered the board with numbers and was changed to a heal. The card-response "chain" mechanic was cut because it was too complex visually.
- [19:57] A third of the team worked on UI: design director, art director, a 3D artist, a designer and a tech artist. Pipeline: back-of-napkin wireframes (no Visio), then UI design with programming checks, then 2D mockup iteration until design requirements are met, then a 3D feasibility check (can parts slide under each other?), then 3D modeling and programming, then tech-art effects.
- [21:58] Expect requirements to change halfway through mockups (for example, the Naxxramas screen suddenly needed rewards and keys) and leave room in the process for it.
- [26:11] Q&A: on mobile performance, they don't cut effects on purpose. They design the coolest effects first and then engineers optimize them.
- [29:43] Q&A: no actions during the opponent's turn was mostly a design decision (with some UI influence), so that "my turn is my turn" and each turn feels like a single-player puzzle.

Applies to Roblox how (inferred): Choose one diegetic "seed" for the game's menus (for example a ship's log, map table or treasure chest) and build the shop, inventory and loading screens as physical objects that share one TweenService motion style (bounce, overshoot) and have satisfying click and hover feedback. Cut on-screen text, test UI mockups before locking mechanics, and simplify any mechanic whose UI comes out cluttered.
