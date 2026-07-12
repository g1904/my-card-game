# Standard — signals & EventBus (deep dive)

Companion to `.claude/rules/csharp-godot-rules.md` (signals section).

## When to use what
- **Direct method call** — a parent driving its own child, or tightly-coupled nodes within one scene. Simplest; use it by default inside a scene.
- **Local `[Signal]`** — a child notifying its parent/owner without knowing who listens (e.g. a `Card` emits `Played`), within scene boundaries.
- **EventBus autoload** — cross-system, cross-scene, decoupled events where emitter and listeners shouldn't reference each other (run lifecycle, gold changed, relic triggered, encounter ended).

## EventBus design
- A single autoload exposing `[Signal]` declarations for global events. Systems `Connect` in `_Ready` and `Disconnect`/free appropriately.
- **Keep payloads Variant-simple:** pass ids and primitives (`string cardId`, `int newGold`), not rich C# objects — safer marshalling and looser coupling. Listeners resolve rich data via `DataRegistry`/`RunState`.
- Name events as past-tense facts: `RunStarted`, `CardPlayed`, `GoldChanged`, `EncounterEnded`, `RelicTriggered`.

## Pitfalls
- **Leaks:** connections to a scene node that gets freed can dangle. Prefer connecting from the longer-lived side, or disconnect on `_ExitTree`.
- **Ordering:** don't assume listener execution order. If order matters (relic trigger priority), model it explicitly (a priority list resolved by one system) rather than relying on connect order.
- **Feedback loops:** an event handler that emits the same event can recurse. Guard re-entrancy where effects can chain (relics reacting to relics).
