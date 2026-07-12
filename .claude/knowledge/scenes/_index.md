# Scenes index

Hand-maintained catalog of Godot scenes. Update when you add/rename a scene. **Currently the project has no gameplay scenes** — only the scaffold (`icon.svg`; no main scene is set in `project.godot` yet).

## Intended scenes

### Screens (full-viewport)
| Scene (planned) | Purpose |
|-----------------|---------|
| `MainMenu.tscn` | Title, continue/new run, settings. |
| `Run.tscn` | Run shell hosting the current node's screen + persistent HUD (gold, relics, deck). |
| `Map.tscn` | Branching node map; tap a node to travel. |
| `Combat.tscn` | Encounter view: enemies, hand, energy, play area. |
| `Shop.tscn` | Buy cards/relics, remove/upgrade. |
| `Settings.tscn` | Audio, display, accessibility. |

### Instanced widgets (reusable, `PackedScene`)
| Scene (planned) | Purpose |
|-----------------|---------|
| `Card.tscn` | A single card view bound to a `CardData`; draggable. |
| `Enemy.tscn` | An enemy view bound to `EnemyData`; shows intent. |
| `RelicIcon.tscn` | A relic in the HUD. |
| `RewardTile.tscn` | A selectable post-encounter reward. |

## How to add a scene note
For non-trivial scenes, add a short per-scene section (or file) noting: node tree shape, script class, exported references, which system drives it, and the signals it emits. Set the main scene in `project.godot` once `MainMenu.tscn` (or a boot scene) exists.
