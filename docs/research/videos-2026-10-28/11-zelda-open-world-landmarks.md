# How Nintendo Solved Zelda's Open World Problem
- Channel: Game Maker's Toolkit (Mark Brown) | URL: https://www.youtube.com/watch?v=CZzcVs8tNfE | Length: 9:31 | Upload: 2023-05-09 | Captions: manual (en). Source: Nintendo's 2017 CEDEC (Japan) lecture on Breath of the Wild, rebuilt by GMTK from translated write-ups and archived slides.

- [0:00] The core problem is giving the player total freedom while still leading them toward key story locations.
- [2:07] First attempt, "points and lines": about 15 Sheikah Towers act as points (visible from far away, and climbing one reveals a large chunk of the map), and the routes between them are lines with events placed along them.
- [2:37] It flopped because the guidance "worked too well". Testers felt stuck on an invisible guide rope, and those who left the line got lost or found little of interest.
- [3:08] Heat-map telemetry showed about 80% of testers followed the tower-to-tower route and about 20% wandered at random. Neither matched the intended experience.
- [3:30] The fix was to lure players with many varied landmarks (shrines, stables, enemy camps) instead of a few towers.
- [3:41] Every landmark type gives an obvious benefit. Shrines raise health or stamina, enemy bases hold weapons, and stables gained beds for healing, a shop and NPCs with rumours and side quests.
- [4:12] Resources pull players outward. Nintendo removed simple heart pickups, so healing comes from forest mushrooms or hunting. Rupees were made very rare, so players mine ore to sell.
- [4:42] Small landmarks must read from a distance or a vantage point. Shrines glow, campfires send up tall smoke columns, enemy bases sit around giant skull-shaped rocks, and stables are a huge wooden horse statue.
- [5:00] Too many visible options overwhelm the player. That is part of why Nintendo created the "triangle rule".
- [5:12] The triangle rule: the terrain is mostly triangles (hills, mountains, cones). Facing one forces a decision to climb it or go around, and the eye is drawn to the peak, which is a good spot for a point of interest.
- [5:42] Most importantly, triangles hide what is behind them, so only a couple of attractions are on screen at once. Moving reveals more terrain bit by bit, which keeps surprise and curiosity going.
- [6:15] This creates a chain reaction. On the way to one landmark, two or three new ones appear and pull the player off course: a breadcrumb trail of "ooh, what's that?" moments that eventually leads to the towers.
- [7:49] Different landmarks attract depending on the player's goal or mood. At night other locations become more visible and appealing.
- [7:55] The heat map afterwards showed no 80/20 split. Players explored freely, yet almost all of them reached the key locations.
- [8:52] For scale and density, Nintendo first imported Google Maps data of Kyoto and had Link run around it and climb Himeji Castle.

Applies to Roblox how (inferred): On a large map, hide the next areas behind cone- or pyramid-shaped hills and put a tall, distinctive silhouette on each point of interest (a lit beacon, a smoke column, a giant statue). Give each point of interest a clear reward, and log player positions to a heat map to check that players drift to the key spots.
