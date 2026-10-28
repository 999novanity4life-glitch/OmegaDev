# The Art of Firewatch
- Channel: GDC Festival of Gaming | URL: https://www.youtube.com/watch?v=SdxQ3HlhTE8 | Length: 26:44 | Upload: 2019-11-20 (talk given at GDC 2015) | Captions: auto (description credits Jane Ng, Campo Santo)

- [6:15] Before translating 2D key art into 3D, analyze exactly why the image works. Three pillars for Firewatch: (1) bold colors in distinct depth layers, (2) flat shapes with strong silhouettes and abstracted internal detail, (3) narrative details hidden in small things.
- [7:48] Don't paint concept-art colors onto assets. The game has a day/night cycle, so a sunset orange would be wrong at night. Color has to come from a dynamic system.
- [8:19] Outdoors, the sky is the largest block of color, sometimes over half the screen. They built their own procedural sky tool that could change at runtime.
- [8:50] Make sky colors art-directable "like inside Photoshop", not a physically correct sky shader.
- [9:21] Get scene lighting from the sky: image-based lighting plus one shadow-casting directional light as the sun.
- [10:23] An interpolation manager on top of the dynamic lighting triggers color changes with trigger volumes as the player moves. Sky, sun and fog all shift together.
- [11:25] Hot tip 1: buy a tool if it saves real development time.
- [11:55] Standard global fog gives one color that just gets stronger with distance, which is not enough for layered depth.
- [12:25] "Stylistic fog": a post-process with additive blend that reads a strip texture to set fog color and intensity by distance.
- [13:27] Keep a debug "reference fog" strip with loud colors to see which part of the strip affects which part of the scene.
- [15:29] Colors drive mood and should match the story beat. Map the mood progression with a color script (as in film, e.g. Pixar's The Incredibles), early, and build each area around its most iconic moment's palette.
- [16:02] Work in passes: rough color script, rough gray box, playtest scale and pacing, paint over game screenshots for a detailed color script, then full production.
- [16:33] Hot tip 3: a color script keeps the team aligned. Making art once is cheap; reworking finished assets is what costs a small team.
- [17:37] With no landmarks such as towers or statues, use natural elements (trees, rocks) to funnel the player and guide the eye. Mark up rough sky and lighting even at the gray-box stage.
- [18:39] If the team naturally nicknames your big shapes (e.g. "Pride Rock"), "you are probably on the right track."
- [18:39] Trees were modeled for their silhouette at a distance; only the lower branches need up-close quality. Realistic heights of 20-30 m or taller.
- [19:40] Distant trees should look more simplified. Fog removes texture detail but does not simplify silhouettes.
- [20:11] Raise the foliage alpha cutoff with distance so far-off trees "puff out" into simpler silhouettes: a stylized LOD.
- [20:44] Rocks are angular modules designed for the shapes they make under harsh lighting, each distinct from all 360 degrees so it can be reused at different rotations. Almost no texture detail: edge highlights, baked AO and a good normal map.
- [21:15] Treat modules as "rock words" that combine into "rock sentences". Assemble scenes from a paint-over with composition notes.
- [22:18] Hot tip 4: make a small number of versatile modular assets. "If you only need three rocks don't make a fourth."
- [23:49] Flip the detail budget for narrative props: simple in shape but richly textured, so high texture detail means the object matters.
- [24:21] Hot tip 5: spend art bandwidth on the assets with the most player-experience payoff.
- [24:52] Embrace your limitations.

Applies to Roblox how (inferred): Drive Lighting/Atmosphere/Sky from per-zone presets that tween when the player enters a zone, with a color script per area. Keep terrain and rock kits small and silhouette-first. Save detailed textures for interactable story props.
