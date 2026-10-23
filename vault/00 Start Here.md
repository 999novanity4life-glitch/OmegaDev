# 00 Start Here (for the human)

1. Setup once: see the repo README (Rokit tools, Rojo plugin, Studio MCP on, Claude Code logged in).
2. Start the dashboard: `node scripts/omega.mjs room` → http://localhost:4321
3. Ask for pitches: type "find me 4 game ideas" in the Ask box, then run a Lead cycle:
   `node scripts/omega.mjs lead`
4. Pick a pitch ("build pitch 2"), then let it run: `node scripts/omega.mjs lead --cycles 20 --sleep 120`
   Keep Studio open with `rojo serve` running for the game, so Playtest can work.
5. Come back to **Home** (what needs you) and **Review** (approve / changes / reject). Your verdicts are picked up next cycle.
6. **Pause all** stops agents after their current step.

The agents are only as good as this vault. When you see a mistake twice, add a rule to the right chapter.
