# MyCardGame — Claude Code harness

A lightweight, engineered `.claude` configuration (rules + knowledge + skills) that helps Claude Code work effectively on this project.

**Project:** a Godot **2D roguelike deckbuilder** (Balatro / Slay the Spire feel) — mobile-first, portrait, offline, casual.
**Stack:** Godot 4.7 (GL Compatibility) · .NET / C# · Rider · Claude Code.

---

## Design principle

`CLAUDE.md` loads one file every session: `rules/Context.md`. That file holds the always-on conventions plus a **Knowledge navigation** table. Deep detail lives in `knowledge/*` and is loaded on demand — keeping per-session context small.

Paths are hardcoded as `.claude/...` (this project targets Claude Code only; there is no Qoder/`$TOOL_DIR` indirection).

---

## Workspace layout — parallel branch folders

```
D:\MyCardGame\
├── .claude/                  — this harness
├── game-feature-branch/      — the Godot project; EDIT HERE
├── game-testing-branch/      — read-only reference snapshot (test)
└── game-production-branch/   — read-only reference snapshot (release)
```

- **Edit only in `game-feature-branch/`.** The other two are parallel snapshots for cross-comparing a stable build against work-in-progress (mirrors a dev/test/prod branch model without switching branches).
- This is a **convention, not an enforced hook.** The old edit-guard hooks were removed; discipline is on you (and on Claude via `Context.md`).

---

## Directory structure

```
.claude/
├── CLAUDE.md            — entry; imports rules/Context.md
├── settings.json        — permissions + model (no hooks)
├── README.md            — this file
├── .gitignore
├── rules/
│   ├── Context.md               — always-on conventions + knowledge nav (keep < ~250 lines)
│   ├── environment-rules.md     — this machine's tools/PATH
│   ├── csharp-godot-rules.md    — C#↔Godot interop conventions
│   ├── scene-rules.md           — scene / node composition & instancing
│   ├── data-resource-rules.md   — Resource-driven data (.tres)
│   ├── state-save-rules.md      — run state, seeded RNG, save atomicity
│   ├── ui-input-rules.md        — mobile portrait layout + touch input
│   └── null-check-rules.md      — validate GetNode / ResourceLoad / lookups
├── knowledge/
│   ├── architecture.md          — scene tree, autoloads, render/resolution
│   ├── dictionary.md            — game glossary
│   ├── systems/     (_index.md + one file per gameplay system)
│   ├── data/        (_index.md + data-resource schemas)
│   ├── scenes/      (_index.md + per-scene notes)
│   ├── autoloads/   (_index.md + per-singleton notes)
│   └── standards/   (deep-dive convention docs)
├── scripts/
│   └── session-manager*         — session favorites/tags helper
└── skills/
    ├── blueprint/        — explore + design an implementation blueprint
    ├── implement/        — implement per blueprint
    ├── review-local-changes/  — review uncommitted changes
    ├── review-feature/   — review a feature's full chain
    ├── investigate/      — trace a bug to ranked root causes
    └── session-manager/  — session favorites/tags
```

---

## Feature workflow

1. `/blueprint <feature>` — explore knowledge + code, clarify, save an implementation blueprint to `blueprints/`.
2. `/implement [blueprint]` — build it in `game-feature-branch/`.
3. `/review-local-changes` or `/review-feature` — catch bugs before committing.
4. `/investigate <symptom>` — trace a bug to ranked root causes + diagnostic steps.

Knowledge under `knowledge/` is authored by hand (there are no auto-generating `analyze-*` skills). Update the relevant `systems/`, `scenes/`, or `data/` note as you build.

---

## Extending

- **New convention** → add `knowledge/standards/<topic>.md`, link it from the `Context.md` navigation table. Prefer new knowledge files over growing `Context.md`.
- **New skill** → add `skills/<name>/SKILL.md`.
