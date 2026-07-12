# Systems — Design Intent Index

Living design docs per gameplay system. Filenames mirror `.claude/knowledge/systems/` 1:1, so each doc feeds exactly one knowledge note.

| Doc | Purpose | Feeds (knowledge) |
|-----|---------|-------------------|
| [run-manager](run-manager.md) | Run lifecycle: start (seed), advance, win/loss, teardown. | `systems/run-manager.md` |
| [map-progression](map-progression.md) | Branching node map per ante; position; routing. | `systems/map-progression.md` |
| [encounter-combat](encounter-combat.md) | Turn structure, enemy intents/AI, resolution. | `systems/encounter-combat.md` |
| [deck-hand](deck-hand.md) | Draw/hand/discard, seeded shuffle, deck mutations. | `systems/deck-hand.md` |
| [card-resolution](card-resolution.md) | Cost, targeting, effect pipeline, triggers. | `systems/card-resolution.md` |
| [energy-economy](energy-economy.md) | Per-turn energy; run currency (gold). | `systems/energy-economy.md` |
| [relics-jokers](relics-jokers.md) | Passive modifiers via event triggers. | `systems/relics-jokers.md` |
| [scoring](scoring.md) | Score model (chips×mult or folded into combat). | `systems/scoring.md` |
| [shop-rewards](shop-rewards.md) | Shop stock, buying, upgrades, rewards. | `systems/shop-rewards.md` |

> Add a new system doc here only when there's real design intent for it; keep names matching the knowledge index.
