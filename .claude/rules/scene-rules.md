# Scene & node rules

Deep-dive companion: `.claude/knowledge/standards/godot-scene-conventions.md`.

- **One responsibility per scene.** A card, an enemy, a screen, a popup — each is its own scene, instanced where needed.
- **Instance reusable things via `PackedScene`.** Cards, enemies, reward tiles, and UI widgets are authored once and instanced at runtime. Reference the `PackedScene` via `[Export]` or preload, never hardcode `res://` string paths scattered through logic (centralize scene paths).
- **A scene owns its children.** External code talks to a scene through its script's public API / signals, not by reaching into its internal node tree.
- **Stable references.** Use scene-unique names (`%Node`), groups (`AddToGroup`/`GetTree().GetNodesInGroup`), or exported node references. Avoid brittle index- or path-based traversal.
- **Keep data out of scenes.** Visual/structural composition lives in `.tscn`; gameplay numbers and definitions live in data resources (`.tres`) loaded through the registry (see `data-resource-rules.md`). A card scene is a *view* of a card resource.
- **Portrait-friendly composition.** Build screens from `Container` nodes with anchors so they reflow across aspect ratios (see `ui-input-rules.md`).
- **Naming.** Match the naming already used in sibling scenes. New nodes get descriptive PascalCase names.
