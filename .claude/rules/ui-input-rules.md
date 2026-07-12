# UI & input rules (mobile-first, portrait)

Deep-dive companion: `.claude/knowledge/standards/mobile-portrait-ui.md`.

## Layout
- **Portrait is the primary orientation.** Design every screen tall-first; landscape/desktop is a secondary adaptation, not the baseline.
- Project display is `stretch/mode = canvas_items`, `stretch/aspect = expand`. Build screens from `Container` nodes (`VBox`/`HBox`/`Margin`/`GridContainer`) with **anchors**, so layouts reflow across the wide range of mobile aspect ratios (18:9, 19.5:9, tablets) instead of pixel-positioning.
- Respect **safe areas** (notches, rounded corners, home indicators). Keep interactive elements out of the OS-reserved edges; use `DisplayServer.GetDisplaySafeArea()` where needed.
- Choose a fixed base resolution/viewport for authoring and let stretch handle the rest.

## Touch input
- **Touch-first.** Primary interactions (play a card, drag to target, tap a map node, buy in shop) must work with touch: drag-and-drop, taps, and swipes.
- Meet minimum **touch-target sizes** — buttons/cards must be comfortably tappable on a phone; don't rely on precise cursor placement.
- **No hover-only affordances.** Anything conveyed by mouse-hover on desktop must have a touch equivalent (long-press, tap-to-inspect, always-visible label).
- Handle both `InputEventScreenTouch`/`InputEventScreenDrag` and mouse/pointer without separate code paths — Godot emulates mouse↔touch, but verify drag-drop feels right on an actual device.

## Cross-platform
- One codebase serves mobile, desktop, and web. Don't fork input logic per platform; branch only where a capability genuinely differs (e.g. keyboard shortcuts as an optional desktop enhancement).
- Web export uses GL Compatibility already; keep shaders/effects within that renderer's limits.
