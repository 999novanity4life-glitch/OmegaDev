# Imported: claude-roblox-gamedev-kit (MIT)

Source: https://github.com/0CE4NS/claude-roblox-gamedev-kit, copied verbatim on 2026-10-28
from the default branch. Copyright (c) 2026 0CE4NS, MIT licence (see `LICENSE`, kept with the files).

Why it is here: it is the only public Obsidian game-dev vault we found with real craft
knowledge (see the 2026-10-28 quality study). Its core finding matches OmegaDev's
problem: an AI reviewing its own visual work keeps approving bad work, so quality needs
measured checks and a fresh reviewer judging against reference images.

| File | What it is | How OmegaDev uses it |
|---|---|---|
| `Lessons Learned.md` | ~90 rules from a real Roblox low-poly creature project | Search it before any mesh, VFX, texture or Studio-capture task |
| `skills/vfx-review.md` | Blind side-by-side effect review loop, max 3 rounds | Adapted into `docs/VISUAL_QA.md` and the `visual-reviewer` agent |
| `skills/mesh-qa.md` | Measured mesh gate (magenta back faces = see-through in Roblox) | Frame runs it on every imported or generated mesh |
| `Style Bible template.md` | Look rules template (models, UI kit, world kit, image briefs) | Template for each game's `docs/STYLE.md` |

These files reference scripts and vault notes from the original kit that are not copied
here (for example `references/checks.md`, `board.py`). Where OmegaDev needs them, they are
rewritten in `docs/VISUAL_QA.md` or noted as TODO. Edit our own docs, not these copies, so
the import stays a faithful record of the source.
