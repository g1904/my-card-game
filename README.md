# MyCardGame — Design Documents

This branch (`design`, checked out here as `game-design-documents/`) is the **source of truth for design intent**: the human handoffs, decisions, and living design notes that drive the game.

It is **docs only** — orphan history, no game code, never merged into `feature → testing → production`. The Godot project lives in the other branch folders (see `../main/README.md`).

## Design intent vs. the Claude knowledge base
- **`game-design-documents/` (here)** = raw human intent & handoffs. You own this. It's where design *originates*.
- **`.claude/knowledge/*`** = the **distilled**, Claude-facing reference derived from these docs. Claude reads here to plan; it edits *these* design docs only when asked.

## The pipeline
```
90-inbox (scratch)
   └─▶ 10-handoffs/<date>-<slug>.md      raw intent, one entry per handoff   (status: raw)
          └─▶ distilled into 20/30/40 topical living docs                    (status: distilled)
                 └─▶ settled choice?  record 50-decisions/ADR-####
                        └─▶ Claude reads these → .claude/knowledge/* → /blueprint → /implement
```

## Folder legend
| Folder | What lives here | Mutability |
|--------|-----------------|------------|
| `00-vision/` | North star: pillars, scope, references. | Stable, edited rarely. |
| `10-handoffs/` | Raw chronological input — mostly your text, one file per handoff. | **Append-only** (supersede, don't rewrite). |
| `20-systems/` | Design intent per gameplay system. Filenames mirror `.claude/knowledge/systems/`. | Living. |
| `30-content/` | Content design intent (cards, relics, enemies…) — the "what", pre-`.tres`. | Living. |
| `40-ux/` | Screens, flows, feel (text wireframes). | Living. |
| `50-decisions/` | ADR-style settled decisions. | **Immutable once Accepted** (supersede with a new ADR). |
| `90-inbox/` | Unsorted scratch, to be triaged into handoffs/topics. | Free-for-all. |

## Status vocabulary (handoffs)
- `raw` — captured, not yet processed.
- `triaged` — read and routed to the right topic, but not written up.
- `distilled` — folded into a topical doc (and/or an ADR); `distilled-to:` points where.

## Numeric prefixes
Folders are numbered so vision and handoffs sort above the topical docs. Topic filenames match `.claude/knowledge/` 1:1, so a handoff maps cleanly to the knowledge note it eventually feeds.
