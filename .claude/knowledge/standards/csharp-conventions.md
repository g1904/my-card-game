# Standard — C# conventions (deep dive)

Companion to `.claude/rules/csharp-godot-rules.md`. The rule file is the enforced summary; this is the reasoning and detail.

## Style
- `PascalCase`: types, methods, properties, public fields, signals, `[Export]` fields, enum members.
- `_camelCase`: private/internal fields. Local vars `camelCase`.
- Godot C# API is `PascalCase` (`_Ready`, `QueueFree`, `GetTree`); match it.
- Classes deriving from Godot types must be `partial` (source generators emit the other half).
- Prefer explicit types for public API; `var` is fine for locals where the type is obvious.

## Godot interop
- `[Export]` exposes a field to the inspector — use for designer-tunable references and (sparingly) values. Content numbers belong in data resources, not exported per-node.
- `[Signal] public delegate void FooEventHandler(...)` for scene-local signals; cross-system events go through EventBus.
- Marshalling: only Godot-Variant-compatible types cross the C#/engine boundary cleanly (int, float, string, bool, Godot types, arrays/dictionaries of those). Keep signal args simple; pass ids, not rich objects, across the bus.

## Performance
- `_Process`/`_PhysicsProcess` are hot: no per-frame `GetNode`, no LINQ, no `new`, no string interpolation. Cache in `_Ready`.
- Reuse collections; clear-and-refill instead of reallocating.
- Free instanced nodes with `QueueFree`; null out cached references you no longer own to avoid disposed-object access.
- Prefer object pooling for high-churn instances (cards, damage numbers) if profiling shows GC pressure.

## Async / flow
- Avoid `async void`. For engine-timed waits use `await ToSignal(GetTree().CreateTimer(t), SceneTreeTimer.SignalName.Timeout)` or animation/tween signals.
- Don't block the main thread; there is no separate game thread by default.

## Nullability
- Enable nullable reference types where practical and honor `null-check-rules.md` at the four checkpoints (node lookup, resource load, collection lookup, save read).
