# Standard — RNG & determinism (deep dive)

Companion to `.claude/rules/state-save-rules.md` (RNG section). A roguelike's integrity depends on this.

## Core rule
Every run has a stored **seed**. All gameplay randomness derives from it. The same seed + same player choices ⇒ the same run. This enables seeded/daily runs, bug reproduction, and fair leaderboards.

## Sub-streams
- Don't pull all randomness from one global generator — unrelated systems would desync each other (drawing an extra card would shift map generation).
- Give each domain its **own** seeded generator derived from the master seed, e.g. via a per-domain offset/hash: `map`, `combat`, `shop`, `rewards`, `events`.
- Godot's `RandomNumberGenerator` (`Seed`, `State`) is the natural choice; create one instance per sub-stream and store them on RunState.

## What NOT to do
- No unseeded `GD.Randi()`, `GD.Randf()`, or `System.Random()` for anything that affects gameplay outcomes. Those are acceptable only for pure cosmetic jitter that never needs reproducing.

## Persistence
- Save the master seed **and** each sub-stream's `State` (position), so a resumed run continues the exact sequence rather than restarting a stream.
- On load, restore states before any random draw happens.

## Verification tip
A cheap determinism test: run the same seed twice with scripted inputs and assert identical resulting RunState. Add this if/when a test harness exists (not required by default).
