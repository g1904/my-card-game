---
name: review-local-changes
description: Review all uncommitted local changes in game-feature-branch before committing, to catch potential bugs.
allowed-tools: Read, Grep, Glob, Bash
---

# Review local changes

Review uncommitted changes in `game-feature-branch/` and report potential bugs before commit.

## Steps

### 1. Collect changes
From `game-feature-branch/`:
```bash
git -C game-feature-branch status --porcelain
git -C game-feature-branch diff
git -C game-feature-branch diff --cached
```
If there are **no changes** → report the tree is clean and stop.

### 2. Review each changed file
Check these categories:

#### C# / Godot correctness
- `partial` on Godot-derived classes? Compile-blocking `using`s present?
- `GetNode` cached in `_Ready`, not called per-frame? `GetNodeOrNull` + null check preferred?
- Any allocations/LINQ/string interpolation in `_Process`/`_PhysicsProcess` hot paths?
- Signals connected consistently; no leaked connections to freed nodes; instanced nodes freed (`QueueFree`).
- No `async void` (except necessary top-level handlers).

#### Null / result validation (mandatory — `null-check-rules.md`)
- After every node lookup, `ResourceLoader.Load`/registry get-by-id, dictionary/collection lookup, and save read: is there an explicit check?
- Required-missing → `GD.PushError`/throw **with locating context (id/path)**; optional-missing → `GD.PushWarning` + safe default. Flag any silent null/empty pass-through.

#### Data resources (`data-resource-rules.md`)
- New content keyed by stable string `Id` (not name/index/path)? Cross-references use ids and are validated on load?
- Balance numbers in data/exports, not hardcoded in logic?

#### State / RNG / save (`state-save-rules.md`)
- Randomness drawn from a **seeded** sub-stream, not `GD.Randi`/`Random`?
- Run data mutated through RunState (no stray globals, no leftover state between runs)?
- Save writes atomic (temp + rename) and version-aware? Content referenced by id and validated on load?

#### UI / input (`ui-input-rules.md`)
- Portrait-safe layout (containers + anchors, not absolute positions)? Touch targets adequate? No hover-only affordances?

#### Copy-paste / hygiene
- Duplicated blocks, unmodified names copied from a template, leftover TODO/FIXME, mismatched `[System-Method]` log tags.

### 3. Report ⏸️
Group findings by severity:
- 🔴 **Bug** (runtime/compile failure): missing `using`/`partial`, unchecked null deref, wrong signal signature, unseeded gameplay RNG, non-atomic save, dangling data id.
- 🟡 **Warning**: missing logs, inconsistent naming, suspicious null handling, per-frame allocation.
- 🔵 **Info**: large diffs, complex logic worth a manual look, reuse opportunities.

For each bug: file path, location, problem, and suggested fix. **Do not auto-fix.** If clean, confirm it's safe to commit.
