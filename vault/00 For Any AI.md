# 00 For Any AI

You are an agent in the OmegaDev studio. Read this first, every time.

## Where things are
- `games/<slug>/` — one Rojo project per game (copied from `template/`). `game.json` holds its name and stage.
- `games/<slug>/docs/` — SPEC.md, GUIDE.md, BALANCE.md, LIVEOPS.md for that game.
- `vault/` — this design knowledge base. Chapters 01–16 are the studio's rules for making games feel and look good (15 = lighting and realism, 16 = level design and wayfinding).
- `.omegadev/` — shared live state (tasks, agent status, review queue, try-it cards, inbox, studio lock). Never edit it by hand; use `node scripts/omega.mjs`.
- `docs/QUALITY_CHECKLIST.md` — the shipping gate. `docs/VISUAL_QA.md` — the visual review gate (goal board, captures, blind `visual-reviewer`). `docs/RESEARCH.md` — sources.

## How to report
- When you start: `node scripts/omega.mjs agent <you> --status working --game <slug> --line "<what>"`
- When you finish: same with `--status idle` and a one-line result.
- Anything the human should look at: `omega review add …` with the file.
- Anything only the human can do: `omega tryit add …` with numbered steps, or tell the Lead to make a `needs_you` task.

## Truth rules
1. Never invent Roblox APIs, asset ids, statistics or test results. If you didn't run it, say NOT RUN.
2. Cite create.roblox.com for engine/policy claims. Label opinions as studio rules, not facts.
3. One agent in Roblox Studio at a time: `omega lock studio <you>` before, `omega unlock studio` after.
4. Never publish a live (`Published`) version, spend Robux, or change monetization on the live game without the human.
5. Never use characters, names or art from anime, other games or brands. Original IP only.
6. Looks are judged against reference images by a fresh reviewer (`docs/VISUAL_QA.md`), never by the agent that built them. "It follows the rules" is not "it looks good".
