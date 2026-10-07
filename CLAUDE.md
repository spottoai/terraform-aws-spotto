@AGENTS.md

## Claude Code notes
- Put guidance both tools need in `AGENTS.md` (Codex reads it directly; this file imports it). Keep only Claude-specific notes in `CLAUDE.md`.
- Repo skills live in `.agents/skills/`. Claude Code loads them from `.claude/skills/`, which holds local links created by `node ../core/scripts/link-agent-skills.mjs` (gitignored; never edit there).
- Cross-repo skills come from the `spotto-core` plugin enabled in `.claude/settings.json`; invoke them as `/spotto-core:<skill>`.
