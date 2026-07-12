---
name: investigate
description: Given a symptom, trace the processing chain and list ranked potential root causes with diagnostic steps.
argument-hint: [env: feature/testing/production], <symptom: expected vs actual, logs/data>
allowed-tools: Read, Grep, Glob, Bash
---

# Investigate

Trace the code chain for a reported symptom, find where state is wrongly set or lost, and rank likely root causes.

## Steps

### 0. Pick the environment
Parse **env** from `$ARGUMENTS`. It selects which branch folder to trace in:

| env | folder | when |
|-----|--------|------|
| `feature` (default) | `game-feature-branch/` | dev-time repro, work in progress |
| `testing` | `game-testing-branch/` | issue seen in the test snapshot |
| `production` | `game-production-branch/` | issue in the release snapshot |

If unspecified, default to `feature` and say so. Limit all reading/searching to the chosen folder so you reason about the matching code.

### 1. Parse the symptom
Extract (ask if missing): **expected** behavior, **actual** behavior, **key clues** (log lines, save data, seed, on-screen values), **entities involved** (card/relic id, system, scene, signal).

### 2. Fix trace endpoints
- **Start**: the last point the state is known correct (a save value, an upstream log, the data resource).
- **End**: where it goes wrong (a downstream log, wrong UI value, crash site).

### 3. Trace the chain (read full code at each hop)
Watch these transformation points common to this game:

- **Data resolution**: a `DataRegistry` get-by-id — was the id correct? Was a null result checked (`null-check-rules.md`)?
- **RunState mutation**: which system wrote the field? Was it overwritten later by another system/EventBus handler?
- **EventBus flow**: is the signal emitted? Are all intended subscribers connected? Any ordering/re-entrancy issue (a handler re-emitting, relics reacting to relics)?
- **Seeded RNG** (`rng-determinism.md`): is the outcome drawn from the right seeded sub-stream? Did an unrelated draw desync the stream? Was RNG state restored on load?
- **Save/load** (`save-format.md`): version mismatch, missing migration, unknown/dangling content id, non-atomic write corrupting the file, RNG state not persisted.
- **Signal payloads**: an id/primitive marshalled across the bus vs a rich object that lost data.
- **Node lifecycle**: a freed node still referenced, an instanced card/enemy leaking across runs, `GetNode` on a not-yet-ready tree.
- **Swallowed errors**: an empty `catch`, or a null that was neither `PushError`'d nor `PushWarning`'d, hiding the real failure.

### 4. Annotate state at each hop
Show the value of the target field flowing hop-by-hop, marking where it diverges:
```
[start] save: run.seed=12345, deck=[strike,strike,bash]
  ↓ DeckSystem.Draw() (map RNG vs combat RNG?)
[hand] expected 5 cards, actual 4  ← divergence
  ↓ EventBus.CardDrawn subscribers
[UI] HandView shows 4
```

### 5. Rank root causes
High→low likelihood. For each: **likelihood**, **transformation point** (`file:method`), **mechanism** (how state is corrupted/lost), **evidence** (code for/against), **how to verify** (log keyword, breakpoint, seed to replay, save field to inspect).

Ordering: code-provable issues first, runtime-data issues next, environment/config issues last.

### 6. Diagnostic steps
Concrete, prioritized checks: exact `GD.Print` tags to search and what each value implies; the seed + scripted inputs to replay for determinism bugs; which save field/version to inspect; which scene to open in the editor to reproduce.

### 7. Output format
```
## Investigation: <one-line symptom>

### Symptom
- env: <feature/testing/production>
- expected / actual / key clues

### State trace
<arrow diagram of the field across hops>

### Root causes
#### #1 [high] <title>
- point / mechanism / evidence / how to verify
#### #2 [med] ...

### Diagnostic steps
<prioritized checks; what to look for and what each result means>
```
