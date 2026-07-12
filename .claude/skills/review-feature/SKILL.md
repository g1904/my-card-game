---
name: review-feature
description: Review a feature's full chain (scene, script, data, wiring) to find potential bugs. Existing or new.
argument-hint: <feature description, class name, scene name, or file path>
allowed-tools: Read, Grep, Glob, Bash
---

# Review feature

Review the full chain of a feature in `game-feature-branch/` for potential bugs.

## Steps

### 1. Scope
From `$ARGUMENTS`:
- **Class/scene name** → locate it in `game-feature-branch/`.
- **File path** → read it, identify the entry point.
- **Description** → search `game-feature-branch/` for related scenes/scripts/data.
- **Nothing** → collect uncommitted changes and review those:
```bash
git -C game-feature-branch status --porcelain
git -C game-feature-branch diff
```
If nothing is specified and there are no changes → ask for a target and stop.

### 2. Trace the full chain
From the entry point, read the **full code of each layer** (not just diffs). Follow both directions:

| Entry | Upstream | Downstream |
|-------|----------|-----------|
| UI/screen scene | what opens/hosts it | system calls → RunState → EventBus |
| System/manager | callers (UI, other systems, EventBus subscribers) | RunState mutations, DataRegistry reads, save writes |
| Autoload (RunState/EventBus/DataRegistry/SaveManager) | all emitters/consumers | the data/services it owns |
| Data resource | systems that read it by id | validation on load |
| EventBus signal | emitters | all subscribers |

A feature may span several chains — cover them all.

### 3. Review each chain
- **Chain completeness**: is every layer implemented? Signals both emitted and handled? Scenes wired to the systems that drive them? Data ids actually resolved somewhere?
- **Type consistency**: parameter/return types aligned input → system → RunState → data → save. Signal payloads Variant-simple.
- **C#/Godot correctness**: `partial`, cached nodes, no hot-path allocations, freed instances, no leaked signal connections, no `async void`.
- **Null / validation** (`null-check-rules.md`): every node lookup / resource load / registry-dictionary lookup / save read is explicitly checked; required→error-with-context, optional→warn+default; no silent pass-through.
- **Data** (`data-resource-rules.md`): stable ids, id-based cross-refs validated on load, balance in data.
- **State/RNG/save** (`state-save-rules.md`): seeded sub-stream randomness, RunState-owned mutation, clean run teardown, atomic versioned saves, id-based save refs.
- **UI/input** (`ui-input-rules.md`): portrait containers/anchors, touch targets, no hover-only.
- **Event/signal design** (`signal-eventbus.md`): decoupled cross-system via EventBus; no re-entrancy loops; no order assumptions where order matters (e.g. relic trigger priority).
- **Business logic** (if context allows): branch coverage (empty deck, resume mid-run, boss vs normal), state-machine sanity, no double-apply of effects.
- **Copy-paste/hygiene**: duplicated blocks, stale template names, leftover TODO/FIXME, mismatched log tags.

### 4. Report
Group by severity:
- 🔴 **Bug**: broken chain (missing layer), type mismatch, missing `using`/`partial`, unchecked null deref, unseeded gameplay RNG, non-atomic/unversioned save, dangling data id, signal signature mismatch, re-entrant event loop.
- 🟡 **Warning**: missing logs, inconsistent naming, null-safety doubts, suspicious transaction of run-state between runs, per-frame allocation.
- 🔵 **Info**: complex logic to double-check manually, reuse suggestions, potential perf hot spots.

For each bug: file path, location, problem, suggested fix. **Do not auto-fix.** If clean, confirm the chain looks sound.
