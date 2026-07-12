---
name: blueprint
description: Explore the project, validate the request, clarify unknowns, and save an implementation blueprint.
argument-hint: <feature description>
---

# Blueprint

Given `<feature description>`, produce an implementation blueprint for the Godot/C# card game.

## Steps

### 1. Validate the request
Before touching code, sanity-check the description itself:
- Is it self-consistent (no contradictions or circular dependencies)?
- Are the data flow and state transitions plausible for a roguelike run?
- Any obvious missing edge cases (empty deck, run resume mid-encounter, seed reproducibility, save/version)?
- If something is logically off, raise it with the user now — don't proceed.

### 2. Knowledge exploration (read before searching code)
1. Read `.claude/knowledge/architecture.md` for the macro map.
2. Read `.claude/knowledge/systems/_index.md`; open the relevant `systems/<name>.md` notes (if they exist yet).
3. Read the relevant `.claude/knowledge/data/_index.md` schemas and `.claude/knowledge/autoloads/_index.md` (RunState, EventBus, DataRegistry, SaveManager…).
4. Skim the rule files that apply (scene, data-resource, state-save, ui-input, null-check).

Goal: understand the intended architecture and existing conventions before writing anything.

### 3. Code exploration
**Search only within `game-feature-branch/`.** The `game-testing-branch/` and `game-production-branch/` folders are read-only snapshots — searching them yields duplicates.

Dispatch up to 3 Explore agents **in parallel**, each scoped to `game-feature-branch/`:
- **Agent 1 — core**: find the exact scenes/scripts/nodes named in the description; read them to learn current state.
- **Agent 2 — reusable pieces**: existing autoloads, systems, data resources, widget scenes, and EventBus signals that can be wired together instead of rebuilt.
- **Agent 3 — cross-system flow** (only if the feature spans systems): the signals, RunState fields, save touchpoints, and data resources the feature interacts with.

Synthesize findings; cross-check the description against what exists. Remember the project is a fresh scaffold — much may not exist yet, which is fine; note what must be created.

### 4. Clarification checkpoint ⏸️
Present a structured summary:
- **Affected scenes / scripts / autoloads / data** (full paths).
- **Reusable existing pieces** (class + method / signal + file path).
- **Missing pieces** to create.
Ask targeted questions on anything ambiguous. **Wait for confirmation before designing.**

### 5. Design the blueprint
Produce, and save to `.claude/blueprints/<slug>.md`:
- Files to create/modify (full paths): scenes (`.tscn`), scripts (`.cs`), data (`.tres`), autoload registrations.
- The flow: **input/UI → system → RunState → EventBus → reacting systems/UI**, noting which parts exist vs. must be built.
- Class shapes: fields, `[Export]`s, methods, signals; data-resource fields and ids.
- **Signal/event wiring**: which EventBus signals are emitted/consumed (payloads as ids/primitives).
- **RNG touchpoints**: which seeded sub-stream drives any randomness (per `rng-determinism`).
- **Save touchpoints**: what run state is persisted, autosave points, version impact.
- **Null/validation plan** (mandatory): for every node lookup, resource load, registry/dictionary lookup, and save read — state whether it's required (error with context) or optional (warn + default). See `null-check-rules.md`.
- **Mobile/touch UI notes**: portrait layout, containers, touch targets for any new UI.
- **Implementation order** (usually bottom-up: data resource → system logic → scene/UI → wiring).

Finish by suggesting: run `/implement` to build the blueprint.
