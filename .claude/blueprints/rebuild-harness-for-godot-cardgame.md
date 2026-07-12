# Blueprint — Rebuild `.claude` harness for the Godot card game

> Saved: 2026-07-11 · Status: PLAN (nothing executed yet) · Target project: **MyCardGame**

## 1. Goal & context

The current `./.claude` was cloned from an unrelated **Java microservices (OMS/WMS/ERP, "baozun")** project. We are repurposing the *harness mechanics* (workflow skills, edit-guard hooks, knowledge-index pattern, lazy-loaded rules) for a brand-new project and discarding all Java/business domain content.

**New project:** a Godot-compatible **2D roguelike deckbuilder** in the spirit of *Balatro* / *Slay the Spire*.
- **Engine:** Godot **4.7**, GL Compatibility renderer (mobile-friendly), **.NET / C#** enabled (`[dotnet]` in `project.godot`).
- **Platform:** **mobile-first**, **portrait** orientation; also ships to **desktop** and **web**.
- **Genre/feel:** casual card game, **fully offline** gameplay.
- **Tooling:** Godot + .NET + Rider + Claude Code (no Qoder — `.claude` may be hardcoded in knowledge files; the `$TOOL_DIR` placeholder indirection is dropped).

### Locked decisions (from clarification)
1. **Workspace model — keep three parallel branch folders.** Edits only in `game-feature-branch/`; `game-testing-branch/` and `game-production-branch/` are read-only reference. Edit-guard hooks are rewritten for the `-branch` suffix.
2. **Skill scope — core only.** `blueprint`, `implement`, `review-local-changes`, `review-feature`, `investigate`, `session-manager`. No `analyze-*` generators; knowledge is authored by hand.
3. **Freshness machinery — dropped.** Remove `check-knowledge-*.sh`, `backfill-knowledge-meta.sh`, `/refresh-knowledge`, `/git-dev2test`. Keep only `session-manager` scripts.

### Critical fix discovered during survey
The existing guard hooks (`check-version-dir.sh`, `check-bash-version-dir.sh`) parse stdin JSON with **`python`**. On this machine `python` resolves to the Windows Store app-execution-alias stub and fails — the hooks are **fail-closed**, so they currently **block every Edit/Write/Bash call** (this is why tool calls error out in this session). The rebuilt guards must be **python-free** — implemented in **PowerShell** (like the already-working `notify-toast.ps1`).

---

## 2. Target end-state layout

```
D:\MyCardGame\
├── .claude\                        (harness — rebuilt; NO nested .git / .idea)
│   ├── CLAUDE.md                   entry, one-line import of rules/Context.md
│   ├── settings.json               permissions + hooks wiring (PowerShell hooks)
│   ├── README.md                   rewritten for this project
│   ├── .gitignore                  trimmed (no hub-mock, no staleness baseline)
│   ├── blueprints\                 (this file lives here; git-ignored by default)
│   ├── hooks\
│   │   ├── check-branch-dir.ps1        Edit/Write guard (block testing/production)
│   │   ├── check-bash-branch-dir.ps1   Bash write guard (block writes to testing/production)
│   │   └── notify-toast.ps1            (kept as-is)
│   ├── rules\
│   │   ├── Context.md                  entry rules + knowledge navigation (<250 lines)
│   │   ├── environment-rules.md        this machine tools/PATH (godot/dotnet/rider/git; python note)
│   │   ├── csharp-godot-rules.md        C#<->Godot interop conventions
│   │   ├── scene-rules.md               scene/node composition and instancing
│   │   ├── data-resource-rules.md       Resource-driven data (.tres) conventions
│   │   ├── state-save-rules.md          run state, seeded RNG determinism, save atomicity
│   │   ├── ui-input-rules.md            mobile-first portrait layout + touch input
│   │   └── null-check-rules.md          validate GetNode / ResourceLoad / lookups (adapted data-check)
│   ├── knowledge\
│   │   ├── architecture.md              scene tree, autoloads, C# assembly, render/resolution
│   │   ├── dictionary.md                game glossary (run, ante, deck, relic/joker, blind...)
│   │   ├── systems\  (_index.md + one file per system)
│   │   ├── data\     (_index.md + card/relic/enemy/encounter/event schemas)
│   │   ├── scenes\   (_index.md + per-scene notes, authored by hand)
│   │   ├── autoloads\(_index.md + per-singleton notes)
│   │   └── standards\(coding/scene/signal/rng/save/mobile-ui conventions)
│   ├── scripts\
│   │   ├── session-manager  session-manager.cmd  session-manager.ps1  session-manager-impl.ps1
│   └── skills\
│       ├── blueprint\SKILL.md
│       ├── implement\SKILL.md
│       ├── review-local-changes\SKILL.md
│       ├── review-feature\SKILL.md
│       ├── investigate\SKILL.md
│       └── session-manager\SKILL.md
├── game-feature-branch\            Godot project — EDIT HERE (already scaffolded)
├── game-testing-branch\            read-only reference (currently empty)
├── game-production-branch\         read-only reference (currently empty)
└── .gitignore                      root: Godot/.NET/Rider artifacts
```

---

## 3. Keep / Remove / Rebuild inventory

### KEEP as-is (generic, project-agnostic)
- `hooks/notify-toast.ps1` — Windows silent toast notification.
- `scripts/session-manager*` (4 files) — session favorites/tags, fully generic.
- `skills/session-manager/SKILL.md` — matches the scripts.
- `.claude/blueprints/` directory (holds this plan).

### REMOVE (Java/baozun-specific or dropped machinery)
- **Nested VCS/IDE:** `.claude/.git/`, `.claude/.idea/` (cloned from the old config repo — must go).
- **Java tools:** `tools/hub-mock-testing/`, `tools/hub-mock-production/` (entire `tools/` tree).
- **Java knowledge:** all of `knowledge/` — `services/`, `controller-methods/`, `hub-route/`, `msg-queues/`, `scheduled-tasks/`, `file-processes/`, `mysql-tables/`, `erp-integration/`, `order-relations/`, `cross-service-processes/`, `base-config/`, `other-configs/`, `paradigms/`, `data-tracking/`, `architecture.md`, `dictionary.md`, all `standards/*`.
- **Java rules:** `rules/feign-rules.md`, `hub-rules.md`, `mapper-rules.md`, `response-rules.md`, `transaction-rules.md`, `data-check-rules.md` (concepts partially migrated — see section 5).
- **Domain/dropped skills:** `add-hub-tests/`, `add-hub-prod-mock/`, `build-and-release-dss/`, `git-dev2test/`, `refresh-knowledge/`, `analyze-controller-method/`, `analyze-hub-route/`, `analyze-msg-queue/`, `analyze-scheduled-task/`, `analyze-file-process/`, `analyze-call-paradigm/`, `analyze-new-service/`.
- **Dropped scripts:** `git-dev2test.sh`, `check-knowledge-staleness.sh`, `check-knowledge-anchor.sh`, `backfill-knowledge-meta.sh`.
- **Broken hooks:** `check-version-dir.sh`, `check-bash-version-dir.sh` (replaced by PowerShell versions).
- **Stray root file:** `D:\MyCardGame\session-manager.cmd` (loose copy at repo root; canonical copies live in `.claude/scripts/`).
- **Old metadata:** `session-tags.json` (old project session tags — start clean or leave; low priority).

### REBUILD (retarget mechanics to the game domain)
- `CLAUDE.md`, `settings.json`, `README.md`, `.claude/.gitignore`.
- `rules/Context.md` + the 7 game rule files.
- `knowledge/` skeleton (architecture, dictionary, systems, data, scenes, autoloads, standards).
- 5 core workflow skills (session-manager kept as-is).
- 2 PowerShell guard hooks.
- Root `.gitignore`.

---

## 4. Execution plan (phased)

### Phase 0 — Cleanup (destructive; do first)
1. Delete `.claude/.git/` and `.claude/.idea/`.
2. Delete `.claude/tools/`.
3. Delete `.claude/knowledge/` (entire tree — rebuilt fresh in Phase 4).
4. Delete removed skills, scripts, rules, and the two `.sh` hooks (section 3 REMOVE).
5. Delete stray root `session-manager.cmd`; optionally reset `session-tags.json`.
> Use PowerShell recursive delete. Note the Bash/Edit/Write tools are currently blocked by the broken hook, so use the PowerShell tool until Phase 1 replaces the hooks and Phase 2 re-wires `settings.json`.

### Phase 1 — Guard hooks (python-free) + wiring
- Write `hooks/check-branch-dir.ps1` and `hooks/check-bash-branch-dir.ps1` (specs in 6.1).
- They read stdin JSON via `$input | ConvertFrom-Json`, block writes whose path/command targets `game-testing-branch` or `game-production-branch`, allow everything else (including `.claude/` and `game-feature-branch/`). Fail-closed on parse error.

### Phase 2 — Core config
- Rewrite `settings.json` (6.2): keep permissions/model; point PreToolUse `Edit|Write` and `Bash` matchers at the new `.ps1` guards; update the `SessionStart:compact` reminder text to the `-branch` model; keep the Notification toast.
- Rewrite `CLAUDE.md` (6.3) — single import line, no `$TOOL_DIR` placeholder (hardcode `.claude`).
- Rewrite `.claude/.gitignore` (6.6).

### Phase 3 — Rules
- Rewrite `rules/Context.md` (6.4) and author the 7 game rule files (section 5).

### Phase 4 — Knowledge skeleton
- Create `knowledge/architecture.md`, `dictionary.md`, and `_index.md` for `systems/`, `data/`, `scenes/`, `autoloads/`, plus `standards/*` (section 5 detail). Seed with what is true today (Godot 4.7, GL Compatibility, portrait, C#), leave clearly-marked TODO stubs for systems not yet built. **Do not invent** systems that do not exist in code.

### Phase 5 — Skills
- Rebuild the 5 core skills (6.5). Keep `session-manager` untouched.

### Phase 6 — Repo hygiene & handoff
- Write root `.gitignore` (6.7).
- Rewrite `.claude/README.md` for this project.
- Leave git init/commit/push to the user already-created remote (only if the user asks).

---

## 5. Rule & knowledge content specs

### Rules (`rules/`)
- **Context.md** — entry file. Sections: (a) Project overview (Godot 4.7 / C# / mobile-first portrait / offline roguelike deckbuilder); (b) Environment — the three `-branch` folders, edit only in `game-feature-branch`; (c) Core conventions (logging via `GD.Print`/`GD.PrintErr` with a `[System-Method]` tag; C#/Godot type consistency across layers; read existing `using`s before editing; match existing node/scene naming; minimal-disturbance edits); (d) Knowledge navigation table linking every `knowledge/*` file. Keep under ~250 lines. Hardcode `.claude/...` paths (no `$TOOL_DIR`).
- **environment-rules.md** — this machine reality: available = `git`, `dotnet`, Godot editor, Rider, `chrome`; `python` is broken (Store alias stub) so hooks/scripts must not depend on it; Godot exports run from the editor unless a headless Godot binary is on PATH. Mark as machine-specific.
- **csharp-godot-rules.md** — `PascalCase` methods/properties, `_camelCase` private fields; `[Export]` for inspector-tunable fields; cache `GetNode` in `_Ready`, never per-frame; prefer `GetNodeOrNull` + null check; no LINQ/allocations in `_Process`/`_PhysicsProcess` hot paths; connect signals consistently; `QueueFree` ownership; avoid `async void`.
- **scene-rules.md** — one responsibility per scene; `PackedScene` instancing for cards/enemies/UI widgets; stable node paths / unique names (`%Node`) instead of brittle `../../` paths; scene-owns-its-children; keep data (Resources) out of scenes.
- **data-resource-rules.md** — cards/relics/enemies/encounters/events as custom `Resource` classes serialized to `.tres`; stable string `Id` per entry; central registry/loader autoload; balance/config in data not hardcoded; validate on load.
- **state-save-rules.md** — single `RunState` owns run data; seeded RNG per run (store seed; derive sub-streams) for reproducible roguelike runs; atomic save (temp file + rename), versioned with migration path; autosave points per system; offline-only (`user://`).
- **ui-input-rules.md** — portrait base resolution + `stretch/mode=canvas_items`, `aspect=expand` (already set); anchors/`Container`s for multiple aspect ratios; mobile safe areas; touch-first drag-and-drop cards, min touch-target size, no hover-only affordances; one input path for touch/mouse/pointer.
- **null-check-rules.md** — adapted from old `data-check-rules`: after `GetNodeOrNull`, `ResourceLoader.Load`, registry/dictionary lookup, or save-file read, explicitly validate. Required-missing -> `GD.PushError`/throw with locating context; optional-missing -> `GD.PushWarning` + safe default. No silent null pass-through.

### Knowledge (`knowledge/`)
- **architecture.md** — scene-tree overview, autoload list, C# assembly (`game-feature-branch`), renderer (GL Compatibility, `d3d12` on Windows editor), portrait display config, target platforms, high-level system map.
- **dictionary.md** — glossary: run, ante/floor, map node, encounter/combat, blind, deck/draw/discard piles, hand, energy/mana, gold, relic/joker, card upgrade/removal, scoring (chips x mult if Balatro-like), event, boss.
- **systems/** `_index.md` + one file per system: `run-manager`, `map-progression`, `encounter-combat`, `deck-hand`, `card-resolution`, `energy-economy`, `relics-jokers`, `scoring`, `shop-rewards`, `save-load`, `ui-screens`, `input-touch`, `audio`.
- **data/** `_index.md` + schemas for `cards`, `relics-jokers`, `enemies`, `encounters`, `events`, `blinds-antes`, `balance-config`.
- **scenes/** `_index.md` — hand-maintained scene catalog.
- **autoloads/** `_index.md` — singleton catalog (`Game`, `RunState`, `EventBus`, `DataRegistry`, `SaveManager`, `AudioManager`).
- **standards/** — `csharp-conventions.md`, `godot-scene-conventions.md`, `signal-eventbus.md`, `rng-determinism.md`, `save-format.md`, `mobile-portrait-ui.md`.

---

## 6. Concrete file specs

### 6.1 Guard hooks (PowerShell, python-free)
`hooks/check-branch-dir.ps1` (PreToolUse `Edit|Write`): read stdin JSON, take `tool_input.file_path`; if it matches `game-testing-branch|game-production-branch` write to stderr and exit 2 (block); empty/no-match -> exit 0; parse error -> stderr + exit 2 (fail-closed).
`hooks/check-bash-branch-dir.ps1` (PreToolUse `Bash`): read stdin JSON, take `tool_input.command`; block when a write redirection target (`>`,`>>`) or a write command (delete/`Set-Content`/`Out-File`/`mv`/`cp` destination/`New-Item`/`sed -i`) targets `game-testing-branch|game-production-branch`. Always allow `git`. Read-only access stays allowed. Fail-closed on parse error.
> Both matchers now run PowerShell, so the Python breakage is gone and normal Edit/Write/Bash use is unblocked.

### 6.2 `settings.json` (key changes)
- Keep `permissions.allow`, `defaultMode`, `model: opus`, `effortLevel: high`.
- PreToolUse: `Edit|Write` -> powershell.exe running check-branch-dir.ps1; `Bash` -> check-bash-branch-dir.ps1.
- `SessionStart:compact` reminder -> edit only in game-feature-branch; testing/production are read-only; read existing usings/node paths before editing.
- Keep the Notification toast hook unchanged.

### 6.3 `CLAUDE.md`
Single import line: `@.claude/rules/Context.md` (hardcoded, no placeholder).

### 6.4 `rules/Context.md` skeleton
Conventions -> Project (Godot 4.7 C# mobile-first portrait offline roguelike deckbuilder) -> Knowledge navigation (table of every `knowledge/*` file with a one-line "when to read"). English. <= ~250 lines.

### 6.5 Skill rewrites (core only)
- **blueprint** — read `knowledge/architecture.md` -> `systems/_index.md` -> relevant `systems/*` + `data/*` -> `scenes/_index.md`; explore only `game-feature-branch/`; up to 3 Explore agents (core scene/script, reusable nodes/resources, cross-system signal/event flow); clarification checkpoint; blueprint as scene + node + C# class + Resource plan with signal/event wiring, save/RNG touchpoints, mobile/touch UI notes; enforce null-check + save-atomicity. Remove Java-specific sections.
- **implement** — implement per blueprint in `game-feature-branch/`; follow C#/Godot + scene + data-resource rules; suggest updating relevant knowledge note afterward (by hand).
- **review-local-changes** — review uncommitted changes in `game-feature-branch/`; check null-safety, per-frame allocations, signal leaks, save/RNG determinism, portrait/touch regressions. Read-only.
- **review-feature** — review a named feature full scene/script/data chain for bugs. Read-only.
- **investigate** — symptom -> trace scene/signal/system chain -> ranked root causes + diagnostic steps. `env` arg maps to a branch folder (default `game-feature-branch`). Read-only.
- **session-manager** — unchanged.

### 6.6 `.claude/.gitignore`
Ignore OS files, editor files (.idea/, *.iml, swap), Claude scratch (plans/, blueprints/). Drop hub-mock and staleness-baseline entries. Remove the `blueprints/` line if you want blueprints committed.

### 6.7 Root `.gitignore`
Godot 4 .NET: `.godot/`, `.mono/`, `data_*/`; .NET: `[Bb]in/`, `[Oo]bj/`, `*.user`; Rider: `.idea/`, `*.sln.DotSettings.user`; OS: `.DS_Store`, `Thumbs.db`. Ensure `game-feature-branch/.godot/` is ignored.

---

## 7. Open items / follow-ups (not blocking)
- Empty reference branches are inert until you copy a stable snapshot into each; decide later whether to populate or collapse to feature-only.
- `session-tags.json` carries old project tags — harmless; reset for a clean slate.
- Harness-file language proposed as English; say if you prefer Chinese.
- Git init/commit/push to your new remote left to you unless you ask.
- Knowledge starts as TODO stubs; fills in as the game is built (no analyze-* auto-generation by decision).

---

## 8. Suggested next step
Run the rebuild in phase order (0->6). Phase 0-2 are prerequisite (cleanup + unblock hooks + rewire settings); after Phase 2 the harness is functional. Say **"execute the rebuild"** to proceed, or adjust any spec above first.
