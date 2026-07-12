# Standard — mobile portrait UI (deep dive)

Companion to `.claude/rules/ui-input-rules.md`.

## Resolution & stretch
- Author against a fixed portrait base resolution (pick one, e.g. 1080×1920, and record it in `project.godot`/here). Current display config: `stretch/mode = canvas_items`, `stretch/aspect = expand`.
- `expand` means extra space appears on the long axis for taller/shorter devices — design with **anchored containers** so content reflows, not with absolute positions.

## Containers over coordinates
- Build with `MarginContainer` → `VBoxContainer`/`HBoxContainer`/`GridContainer`. Use `size_flags`, `custom_minimum_size`, and anchors. Avoid pixel-perfect placement that breaks on other aspect ratios.
- Test the extremes: tall phone (19.5:9+), classic 16:9, and tablet (4:3-ish). The hand of cards and HUD must stay usable on all.

## Safe areas
- Keep interactive/critical UI inside the safe area (notch, rounded corners, home indicator, camera cutouts). Query `DisplayServer.GetDisplaySafeArea()` and inset top-level margins accordingly.
- Don't put taps in the extreme corners/edges where the OS intercepts gestures.

## Touch targets & interaction
- Minimum comfortable tap size (~48dp equivalent). Cards and buttons should be finger-friendly.
- Core gestures: **drag** a card to play/target, **tap** a node/enemy/shop item, **swipe** to scroll a hand/map. Provide a **tap-to-inspect** for card/relic details (no hover on touch).
- Give visual/haptic feedback on press; make drag affordances obvious (lift/scale the dragged card).

## Cross-platform parity
- One input path. Godot emulates mouse↔touch; still verify drag-drop on a real device. Desktop keyboard/mouse and web pointer are enhancements layered on the same interactions, not separate flows.
- Stay within GL Compatibility renderer limits (also the web export target): simpler shaders, watch fill-rate on low-end mobile.
