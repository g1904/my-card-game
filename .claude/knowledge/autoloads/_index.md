# Autoloads (singletons) index

Long-lived services registered under Godot's **Project Settings → Autoload**. **None are registered yet** (fresh scaffold). This lists the intended set and their contracts.

| Autoload (planned) | Responsibility | Notes |
|--------------------|----------------|-------|
| **Game** | App bootstrap and top-level screen flow (menu ↔ run). | Thin; delegates to systems. |
| **RunState** | Owns all per-run data: deck, relics, gold, map position, ante/floor, **seed**, RNG state. | Reset on run start; torn down on run end. Source of truth for a run. |
| **EventBus** | Decoupled cross-system signals (run started, encounter ended, gold changed, relic triggered…). | Systems emit/subscribe here instead of holding direct references. See `standards/signal-eventbus.md`. |
| **DataRegistry** | Loads every content `.tres` at startup, indexes by `Id`, validates cross-references. | Fail-loud on missing/duplicate/dangling ids. See `data/_index.md`. |
| **SaveManager** | Atomic, versioned save/load under `user://`. | Temp-file + rename; schema version + migration. See `standards/save-format.md`. |
| **AudioManager** | Music/SFX playback and bus control. | Reads audio settings; exposes simple `PlaySfx(id)` / `PlayMusic(id)`. |

## Registration order matters
`DataRegistry` and `SaveManager` should initialize before systems that read content/saved data. Record the actual autoload order here once set, since Godot initializes autoloads top-to-bottom.

## How to add an autoload note
When you create an autoload, add its public API surface (methods/signals), initialization order dependencies, and what state it owns. Keep gameplay data in **RunState**, not scattered across autoloads.
