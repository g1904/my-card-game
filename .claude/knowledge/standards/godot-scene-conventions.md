# Standard — Godot scene conventions (deep dive)

Companion to `.claude/rules/scene-rules.md`.

## Composition
- One scene = one cohesive unit (a screen, a card, an enemy). Compose big screens from smaller instanced scenes rather than one giant `.tscn`.
- The root node type reflects the scene's role: `Control` for UI screens/widgets, `Node2D` for world/board elements, `Node` for pure logic containers.

## References between nodes
- **Scene-unique names** (`%Name`, "Access as Unique Name" in the editor) for important nodes a script needs — stable across tree edits.
- **Groups** for "all of a kind" (e.g. all `Card` nodes in hand): `AddToGroup("hand")`, `GetTree().GetNodesInGroup("hand")`.
- **Exported `NodePath`/node references** when a node needs a sibling/cousin — wire it in the inspector, don't hardcode `../../`.
- Centralize `res://...tscn`/`.tres` string paths (a constants class or preloaded `[Export] PackedScene`), so a moved file breaks in one place.

## Instancing
- Author reusable elements once (`Card.tscn`), instance at runtime: `_cardScene.Instantiate<Card>()`.
- The instancing parent owns lifetime; `QueueFree` instances when a run/encounter ends. Don't let old cards/enemies linger across runs.

## Data binding
- Scenes are **views**. A `Card` node binds to a `CardData` resource (set via an `Initialize(CardData)` method) and renders it. No gameplay numbers live in the `.tscn`.

## Main scene
- Set the boot/main scene in `project.godot` once it exists (currently unset). A dedicated boot scene that initializes autoloads/loading then hands off to `MainMenu` is a clean pattern.
