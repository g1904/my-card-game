---
name: implement
description: Implement feature code from a blueprint or a description.
argument-hint: [blueprint name or feature description]
---

# Implement

Build feature code for the Godot/C# card game from a blueprint or description.

## Steps

### 1. Load the plan
From `$ARGUMENTS`:
- **A file name** (with/without `.md`) → read that blueprint from `.claude/blueprints/` as the plan.
- **A description** (no matching blueprint) → use it directly as the instruction.
- **Nothing, and no blueprint** → suggest running `/blueprint` first, or ask for a description.

### 2. Implement
Follow the blueprint's order (usually bottom-up: data resource → system logic → scene/UI → wiring).

**Coding rules — follow `Context.md` and the rule files:**
- **Edit only in `game-feature-branch/`.** Never write to the testing/production branch folders.
- **Read existing `using`s / node trees before editing.** Reuse existing short type names and node names; add a new `using` at the top rather than inlining fully-qualified names.
- **C#/Godot conventions** (`csharp-godot-rules.md`): `partial` classes, `[Export]` for tunables, cache `GetNode` in `_Ready`, no allocations/LINQ in `_Process`, `QueueFree` ownership, avoid `async void`.
- **Scenes** (`scene-rules.md`): one responsibility per scene, `PackedScene` instancing, stable references (`%Unique`/groups/exported), data kept out of scenes.
- **Data** (`data-resource-rules.md`): content as `Resource`/`.tres` with stable string `Id`, loaded via DataRegistry, validated on load; balance numbers in data, not code.
- **State/RNG/save** (`state-save-rules.md`): mutate through RunState; drive randomness from the seeded sub-stream; persist atomically and versioned.
- **UI/input** (`ui-input-rules.md`): portrait, containers + anchors, touch targets, no hover-only affordances.
- **Null/validation is mandatory** (`null-check-rules.md`): after every node lookup, resource load, registry/dictionary lookup, and save read — required-missing → `GD.PushError`/throw with locating context; optional-missing → `GD.PushWarning` + safe default. No silent null pass-through.
- **Logging**: `GD.Print($"[System-Method] ... {value}")` around key transitions.
- **Signals**: cross-system events go through EventBus with id/primitive payloads, not direct references.
- **Do not** auto-commit.

### 3. Change summary
List all created/modified files grouped by area (scene / script / data / autoload):
```
## Changed files
- [new]  game-feature-branch/systems/DeckSystem.cs
- [edit] game-feature-branch/autoload/RunState.cs
- [new]  game-feature-branch/data/cards/strike.tres
```

### 4. Verification note
Do **not** rely on CLI compile as the source of truth. Tell the user to verify by opening the project in the Godot editor and pressing Play (the editor drives the .NET build with correct references). `dotnet build` on the `.csproj` can catch C# syntax errors but isn't authoritative. No unit tests unless asked.

### 5. Knowledge update
If this introduced or changed a system/scene/data type, suggest the user (by hand) update the matching note:
- new/changed system → `.claude/knowledge/systems/<name>.md` (+ flip status in `systems/_index.md`)
- new/changed scene → `.claude/knowledge/scenes/_index.md`
- new/changed data type → `.claude/knowledge/data/_index.md`
- new autoload → `.claude/knowledge/autoloads/_index.md`

List the specific notes to touch. Don't rewrite them inline unless asked.
