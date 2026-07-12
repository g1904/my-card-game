# MyCardGame — Branch Guide

**MyCardGame** is a Godot 4.7 (.NET/C#) 2D roguelike deckbuilder (Balatro / Slay the Spire feel), mobile-first, portrait, offline.

This `main` branch intentionally holds **only this guidance map**. All actual content lives in the branches below. Each working branch is checked out into its own sibling folder on the maintainer's machine.

## Branches

| Branch | Purpose | Local folder |
|--------|---------|--------------|
| `main` | This guidance map. No game code. | — |
| `feature` | Active development. Where new work happens. | `game-feature-branch/` |
| `testing` | QA / verification snapshot promoted from `feature`. | `game-testing-branch/` |
| `production` | Release-stable snapshot promoted from `testing`. | `game-production-branch/` |
| `claude-config` | The `.claude/` harness config (rules, knowledge, skills, settings). Not game code. | `.claude/` |

## Flow

```
feature  →  testing  →  production
(develop)   (verify)     (release)
```

`feature`, `testing`, and `production` were all seeded from the same Godot 4.7 project scaffold.
`claude-config` is independent and carries only the Claude Code harness configuration.

## Getting the game

Check out the branch you need — e.g. `git checkout feature` — then open the project in the Godot 4.7 editor (.NET build) and press Play. The game is fully offline; saves persist under `user://`.
