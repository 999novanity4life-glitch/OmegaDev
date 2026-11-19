# Thumbnail rulebook: the gold-standard teardown (2026-11-19)

Source: two thumbnails Sharman picked as the bar, both made with **Forge GUI**
(forgegui.net). Images: `docs/references/thumbnails-2026-11-19/`.
Hex values below were **sampled from the images with Pillow** (saturated pixels
binned by hue, brightest 20% averaged), not guessed. Layout numbers are measured
on the frames; "likely prompt" sections are reconstruction, marked as guesses.

Rule before using this: **show Sharman the reference and get their OK before
generating anything from it** (see `docs/VISUAL_QA.md`). Forge credits are
free-tier only; never spend credits without Sharman's OK.

---

## 1. The two references

| | A: "Castle Siege" | B: "Abyss Station" |
|---|---|---|
| File | `ref-A-castle-dragon.png` (714x392 crop) | `ref-B-manta-station.png` (1074x604) |
| Story in one glance | Heroes charge into a battle while a dragon burns the castle | Two crew members freeze as a giant glowing manta stares in through the glass |
| Emotion | Rage / battle cry | Terror / awe |
| Hook question | "Can I fight that dragon?" | "What is that thing and what happens next?" |
| Text on image | None | None |

### A: Castle Siege (combat, ensemble)
- **Composition:** a big X. The sword (up-left) and fire stream (down-left from the
  dragon) cross over the hero; the archer and mage form a triangle base under him.
  The hero's face sits in the top-middle cell just right of the left third line
  (about x 0.47, y 0.43). The dragon's head sits on the upper-right third
  intersection.
- **Focal order:** 1 hero face, 2 dragon + fire, 3 blue magic burst, 4 side heroes,
  5 crowd and castle.
- **Characters:** 3 heroes, 3 roles that read by silhouette (sword + shield,
  bow, staff). Hero head is about 18% of frame height; side heroes about 12%.
  Every face is **angry with an open mouth or gritted teeth**, anime-style brows.
  Roblox block bodies keep the proportions but get bevelled edges, cloth and
  armour detail.
- **Camera:** low angle (looking up at the hero), wide lens (about 24 to 28 mm
  feel). The hero's front boot is huge at the bottom: forced perspective.
- **Lighting:** two opposite sources. Warm fire upper-left/back
  (`#DD8850` orange, `#F4CA6D` gold highlights, centroid x 0.41) and cool magic
  right (`#75CBF5` cyan core, `#578FEA` blue, `#6D60CC` violet edge, centroid
  x 0.88). Faces get a warm fill (skin about `#D4AC7C`). Rim light on every
  silhouette.
- **Depth layers (5):** dark cropped knights in both bottom corners (foreground
  frame) / 3 heroes / soldier crowd / castle walls and towers / dragon and night
  sky. Embers float through all layers.
- **Detail:** repeated lion emblem (shield, banners, tunic) as a brand motif,
  stone texture, armour plates, cobblestones, sparks. High density everywhere.
- **Small-size read (squint test):** weakest of the two. At 128x72 the hero face
  and shield still read but the busy crowd turns to noise; the blurred value map
  has no single big shape. Fine for a battle game, but our version should
  simplify the crowd.

### B: Abyss Station (mystery, scale)
- **Composition:** frame inside a frame. The station window fills the right
  two-thirds; a dark vertical mullion splits "inside" (characters) from "outside"
  (threat). Main face on the upper-left third intersection (x 0.27, y 0.40).
  Manta eyes along the top third line, centred.
- **Focal order:** 1 scared face, 2 manta's glowing eyes and belly, 3 flashlight,
  4 neon coral bottom-right, 5 control console.
- **Characters:** 2, staggered in depth (second one about 60% the size). Main head
  about 25% of frame height. Expression: **wide eyes, raised brows, mouth wide
  open**. Bodies turn away from the threat while heads look at it: tension.
- **Scale contrast:** the manta is roughly 10x a character's size and is cropped by
  the frame edges, so it feels bigger than the image.
- **Camera:** near eye level, wide lens, the main character very close to the lens
  (flashlight arm pushes toward the viewer).
- **Lighting:** cool ambient from the water (`#6ACAF0` cyan, `#3673BE` blue,
  deep `#081A3A` navy) against warm practicals inside (`#DF823E` orange strip
  lights, flashlight hot core `#FDFCEF`). Warm centroid x 0.29, cool x 0.67.
  The manta has bioluminescent cyan spots and glowing eyes.
- **Depth layers (5):** station interior and characters / console / glass and frame
  / manta / fish, coral, reef haze.
- **Small-size read:** strongest of the two. The bright manta belly is one clean
  shape against dark blue, and the face pops off dark suits. At 128x72 the story
  still reads.

---

## 2. The shared formula (why they work)

1. **One sentence of story, no text.** A player reacting to something huge.
   Emotion plus threat equals a question the viewer wants answered.
2. **Warm vs cool split.** Warm (orange/gold) on the characters and skin, cool
   (cyan/blue) on the threat or world. In both images the warm cluster sits left
   and the cool cluster right.
3. **Low-key overall, bright where it matters.** Mean brightness is low (69/255 for
   A, 59/255 for B). Darkness makes the glow and faces pop. Edges and the bottom
   are darker than the centre (vignette).
4. **Big faces, loud expressions.** Main head 18% to 25% of frame height, anime
   brows, open mouth. Never the default Roblox smile.
5. **Wide lens, close camera.** Forced perspective makes limbs and props punch out.
6. **At least two light sources plus a rim on every silhouette.** Practical lights
   inside the scene (fire, magic, flashlight, lamps) justify the colours.
7. **4 to 5 depth layers,** with a dark, cropped foreground element or frame.
8. **Scale contrast.** The threat is far bigger than the player and cropped by
   the edges.
9. **Dense micro detail** (embers, emblems, coral, fish, panel lines) that rewards a
   full-size look but does not change the small-size silhouette.
10. **Roblox identity kept.** Blocky heads and bodies are always readable as Roblox
    avatars; only the rendering is cinematic.

### Why these beat typical AI Roblox thumbnails
| Typical AI thumbnail | These |
|---|---|
| One character centred, staring at the camera, no story | A reaction to a threat: a story |
| Flat, even, daylight lighting | Low-key, two coloured sources, rim lights |
| Random rainbow palette | Two-hue warm/cool split |
| Default smile or blank face | Exaggerated emotion |
| Front-on, eye-level, normal lens | Low or close camera, wide lens |
| 1 or 2 layers, plain background | 4 to 5 layers, foreground framing |
| Big text, arrows, emojis | No text; the image is the hook |

### Weak spots to beat (honest critique)
- A is cluttered at small size; both are "promise art", not gameplay. Our game must
  really contain the moment we show.
- Typical AI tells to check for: warped props (bow string, staff), merged hands,
  nonsense UI on screens, repeated faces in crowds, emblems that change shape.

---

## 3. Checklist (score every candidate; ship at 12/14 or better)

Read at full size **and** at 256x144 and 128x72 (run the squint test below).

- [ ] Story readable in one second with no text
- [ ] Main face 18% to 25% of frame height, on a third line or intersection
- [ ] Expression is extreme (rage, terror, shock, triumph); brows and mouth do the work
- [ ] A threat, rival or reward that is much bigger than the player
- [ ] Warm/cool split: characters warm, threat or world cool (or the reverse, but only 2 hues)
- [ ] Image is mostly dark; brightest pixels are on the face and the threat
- [ ] At least 2 visible light sources + rim light on every main silhouette
- [ ] 4+ depth layers including a dark foreground frame
- [ ] Wide-angle camera, low or close, with one prop pushing toward the lens
- [ ] Clear silhouette per character (role readable from the outline)
- [ ] At 128x72 the main face and threat are still two distinct shapes
- [ ] Glow VFX (fire, magic, bioluminescence, energy) present and motivated
- [ ] Blocky Roblox avatars, no AI tells (hands, props, text, duplicate faces)
- [ ] The moment shown exists in the game

### Squint test (no credits, run locally)
```python
from PIL import Image, ImageFilter, ImageOps
im = Image.open("thumb.png").convert("RGB")
im.resize((128, 72), Image.LANCZOS).resize((512, 288), Image.NEAREST).save("thumb_128.png")
ImageOps.grayscale(im).resize((256, 144)).filter(ImageFilter.GaussianBlur(4)).save("thumb_value.png")
```
Pass if `thumb_value.png` shows one or two big bright shapes (face, threat),
not an even grey mush.

---

## 4. Forge GUI prompt template

What Forge publicly states (mcpservers.org listing, read 2026-11-19): you pick a
**platform style** (Roblox, Minecraft, Unity, Fortnite-style) and a **theme**
(examples: Horror Escape, Fantasy Adventure, Anime Battle, Pet Rescue, Tycoon
Upgrade), describe the scene, and get **1 to 4 outputs** you can edit with
further instructions or **reference images**, then download in HD. It says
"Mobile-friendly 16:9 composition". Its example prompts are short scene
sentences ("a dragon catching a scared player", "Two players running from a smile
monster in the backrooms"). Not stated publicly: the model, the per-image credit
cost, negative prompts, and the MCP tool parameters. Check the MCP's tool list on
the Mac before the first run.

### Likely settings for the two references (guess)
- Platform: Roblox. Theme: Fantasy Adventure (A), Horror Escape or similar (B).
- Prompts were probably short, Forge-style scene sentences, for example:
  - A: "three roblox heroes charging into battle while a giant dragon burns the
    castle, knight with sword and shield shouting, archer, mage with blue magic"
  - B: "two scared roblox players in an underwater station watching a giant
    glowing manta ray through the window"
- The cinematic lighting, low-key grading and detail most likely come from
  Forge's Roblox style itself, since both images share it.

### Template (fill the brackets; keep to one or two sentences for Forge)
```
[N] roblox [characters, with clear roles/props], [extreme emotion: shouting in rage /
screaming in terror / shocked], [action verb] [a giant THREAT/REWARD, much bigger than
them] in [SETTING]. Low wide-angle cinematic shot, faces close to the camera,
[WARM source e.g. fire / flashlight / orange lamps] lighting the characters and
[COOL source e.g. blue magic / glowing water / cyan energy] on the [threat], dark
vignette, rim light, glowing [VFX: embers / sparks / bioluminescence], dark
foreground framing, highly detailed, no text.
```
Settings: platform Roblox, the closest theme, 16:9, ask for 4 outputs, attach the
approved reference image when Forge allows it.

### Edit pass prompts (Forge "continue editing")
- "make the main character's face bigger and more [angry/scared]"
- "darken the background and edges, keep the glow"
- "simplify the crowd behind the heroes"
- "make the [threat] bigger and crop it at the frame edge"

### Filled examples for Sharman's taste (text only, nothing generated)
No IP names in prompts or titles (Roblox and store rules; we do not own One
Piece or Wukong).
1. Combat transform: "a roblox fighter mid-transformation into a white-haired sun
   god form, laughing wildly, swinging a glowing golden staff at a giant stone
   golem in a ruined temple, low wide-angle shot, gold and white energy on the
   hero, cold purple storm light on the golem, glowing sparks, dark vignette,
   rim light, no text."
2. Throw game: "a roblox player winding up to throw a flaming meteor ball while a
   rival gapes in shock, stadium at night, low wide-angle shot, orange fire on the
   ball and faces, cyan stadium lights behind, motion streaks, dark foreground
   crowd, no text."

---

## 5. Workflow
1. Pick the moment from the game (must exist in the build).
2. Post the reference(s) + filled prompt to Sharman; wait for OK.
3. Generate in Forge (free credits only, 4 outputs), or render the moment in Studio
   with `docs/VISUAL_QA.md` look presets.
4. Score each output on the checklist + squint test; keep 12/14+.
5. Edit pass for the misses; A/B test 3 winners on the Creator Dashboard.
