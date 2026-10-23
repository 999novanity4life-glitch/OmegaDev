"""Three calmer floor options for the slime lab (same palette, light, bevels).

A  Deck plates   - large bevelled steel plates, plum seams, corner bolts. Calmest.
B  Plates + drain - solid plates with ONE grated drain channel softly lit green.
C  Lab composite - dark slate tiles in a steel frame, thin dim slime light seams.
Each tile repeats seamlessly; a preview shows 2x2 of each.
"""
import numpy as np
from PIL import Image, ImageDraw
from textures import N, PAL, canvas, mask, paint, rrect, finish, bolt


def floor_deck():
    h, c = canvas()
    c[:] = PAL["seam"]
    half = N // 2
    for i in range(2):
        for j in range(2):
            x0, y0 = i * half, j * half
            plate = mask(rrect((x0 + 10, y0 + 10, x0 + half - 10, y0 + half - 10), 22), blur=7)
            paint(c, plate, (128, 136, 160))
            h += plate
            inner = mask(rrect((x0 + 46, y0 + 46, x0 + half - 46, y0 + half - 46), 16), blur=9)
            paint(c, inner, (116, 124, 150))
            h += inner * 0.15
            for bx, by in ((x0 + 34, y0 + 34), (x0 + half - 34, y0 + 34), (x0 + 34, y0 + half - 34), (x0 + half - 34, y0 + half - 34)):
                bolt(h, c, bx, by, 12)
    # A thin plum inlay line through the middle of each plate pair ties it to the walls.
    for k in (half / 2, half + half / 2):
        line = mask(lambda d, k=k: d.line((k, 70, k, N - 70), fill=255, width=6), blur=2)
        paint(c, line * 0.5, PAL["plum_hi"])
    return finish("floorA_deck", h, c, strength=40)


def floor_drain():
    h, c = canvas()
    c[:] = PAL["seam"]
    for y0, y1 in ((10, 400), (624, N - 10)):
        plate = mask(rrect((10, y0, N - 10, y1), 22), blur=7)
        paint(c, plate, (124, 132, 156))
        h += plate
        for bx in (40, N - 40):
            for by in (y0 + 30, y1 - 30):
                bolt(h, c, bx, by, 12)
    # One drain channel across the tile: steel frame, bars, faint green underglow.
    frame = mask(rrect((10, 420, N - 10, 604), 18), blur=4)
    paint(c, frame, (92, 98, 122))
    h += frame * 0.4
    pit = mask(rrect((40, 450, N - 40, 574), 12), blur=3)
    paint(c, pit, (16, 20, 28))
    h -= pit
    glow = mask(rrect((60, 520, N - 60, 566), 16), blur=18)
    paint(c, glow * 0.45, PAL["slime_dk"])
    for k in range(22):
        x = 60 + k * 42
        bar = mask(rrect((x, 455, x + 18, 569), 8), blur=2)
        paint(c, bar, (150, 158, 182))
        h += bar * 0.9
    return finish("floorB_drain", h, c, strength=45)


def floor_composite():
    h, c = canvas()
    c[:] = (88, 96, 120)
    half = N // 2
    for i in range(2):
        for j in range(2):
            x0, y0 = i * half, j * half
            frame = mask(rrect((x0 + 6, y0 + 6, x0 + half - 6, y0 + half - 6), 18), blur=5)
            paint(c, frame, (110, 118, 142))
            h += frame * 0.6
            tile = mask(rrect((x0 + 28, y0 + 28, x0 + half - 28, y0 + half - 28), 14), blur=6)
            paint(c, tile, (52, 60, 86))
            h += tile * 0.3
            sheen = mask(lambda d, x0=x0, y0=y0: d.polygon(
                [(x0 + 60, y0 + half - 140), (x0 + half - 140, y0 + 60), (x0 + half - 110, y0 + 60), (x0 + 60, y0 + half - 110)], fill=255), blur=14)
            c += (sheen * 14)[..., None]
    # Dim slime light seams on two edges only, so repeats read as a grid of lit joints.
    for seg in (lambda d: d.line((0, 3, N, 3), fill=255, width=8), lambda d: d.line((3, 0, 3, N), fill=255, width=8)):
        paint(c, mask(seg, blur=4) * 0.55, PAL["slime_dk"])
    return finish("floorC_composite", h, c, strength=35)


if __name__ == "__main__":
    outs = [("A  Deck plates", floor_deck()), ("B  Plates + drain", floor_drain()), ("C  Lab composite", floor_composite())]
    cell = 360
    sheet = Image.new("RGB", (cell * 3 + 80, cell + 70), (20, 18, 30))
    d = ImageDraw.Draw(sheet)
    for i, (label, im) in enumerate(outs):
        tiled = Image.new("RGB", (1024, 1024))
        for x in (0, 512):
            for y in (0, 512):
                tiled.paste(im, (x, y))
        sheet.paste(tiled.resize((cell, cell), Image.LANCZOS), (20 + i * (cell + 20), 20))
        d.text((24 + i * (cell + 20), cell + 30), label, fill=(230, 230, 240))
    sheet.save("floors_preview.png")
    print("done")
