# 13 Building It Right

The engineering rules are in `CLAUDE.md` (strict Luau, server authority, RemoteGuard + Validate, pure tested logic, Config for numbers, ProfileStore for data). This chapter is how the team works:

- **One step at a time.** Builder implements one GUIDE step; code-reviewer reviews; Playtest proves it; then the next step.
- **Evidence or it didn't happen.** Check output, playtest screenshots, console logs. NOT RUN is never PASS.
- **Placeholder first.** The core verb must feel good with grey boxes before art goes in.
- **Fix the cause.** When the same bug returns, add a test or a vault rule so it can't come back.
- **Keep the human's time for decisions.** Pitches, art approval, publishing, real-device and two-account tests. Everything else the team does.
- **Quality gate:** `docs/QUALITY_CHECKLIST.md`, scored by Producer, before any build goes to the human.
