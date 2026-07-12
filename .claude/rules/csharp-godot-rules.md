# C# ↔ Godot rules

Conventions for C# scripts attached to Godot nodes. Deep-dive companion: `.claude/knowledge/standards/csharp-conventions.md`.

## Naming & structure
- `PascalCase` for classes, methods, properties, signals, and exported fields. `_camelCase` for private fields. Match Godot's C# API casing (`_Ready`, `_Process`, `QueueFree`).
- One primary node script per file; the class name matches the file name and (usually) the node it drives.
- Use `[Export]` for values a designer should tune in the inspector (stats, speeds, prefab references). Don't hardcode balance numbers — those belong in data resources (see `data-resource-rules.md`).
- Prefer `partial class Foo : Node` (Godot 4 source generators require `partial`).

## Node access
- Resolve child nodes **once** in `_Ready` and cache them in fields. Never call `GetNode` every frame.
- Prefer `GetNodeOrNull<T>(...)` + an explicit null check over `GetNode<T>` (see `null-check-rules.md`). For scene-unique nodes use `%UniqueName`.
- Never build paths with long `../../` chains — use unique names, groups, or exported `NodePath`/node references.

## Lifecycle & performance
- No allocations, LINQ, or `string` concatenation in `_Process` / `_PhysicsProcess` hot paths. Precompute and reuse buffers/collections.
- Disconnect signals and free owned nodes deliberately (`QueueFree`); don't leak instanced cards/enemies between runs.
- Avoid `async void` (except top-level event handlers that truly need it). Prefer signals/`await ToSignal(...)` for Godot-flow async.
- Use `CallDeferred` when mutating the scene tree during physics/signal callbacks.

## Signals vs direct calls
- Intra-scene parent→child: direct method calls are fine.
- Cross-system / decoupled events (run events, encounter results, currency changes): go through the **EventBus** autoload, not direct references. See `.claude/knowledge/standards/signal-eventbus.md`.
- Connect signals **consistently** — pick code-connection or editor-connection per scene and don't mix arbitrarily.
