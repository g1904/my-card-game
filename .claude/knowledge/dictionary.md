# Dictionary — game glossary

Shared vocabulary for the roguelike deckbuilder. Terms follow Balatro / Slay the Spire conventions; the exact set the game uses is finalized as systems are built.

| Term | Meaning |
|------|---------|
| **Run** | One playthrough from start to win/loss. Reproducible from a stored **seed**. |
| **Seed** | The number that deterministically drives all run randomness. |
| **Ante / Floor** | A progression tier within a run (Balatro: *ante*; StS: *act/floor*). Difficulty scales with it. |
| **Map / Node** | The branching path of a run; each **node** is an encounter, shop, event, rest, or boss. |
| **Encounter** | A single combat/challenge instance. |
| **Blind** | A combat's win condition / gate (Balatro-style small/big/boss blind, or an StS-style boss). |
| **Deck** | The full set of cards the player owns this run. |
| **Draw pile / Hand / Discard pile** | Runtime card zones. Cards move draw → hand → discard → (reshuffle) → draw. |
| **Hand** | The cards currently playable this turn. |
| **Energy / Mana** | Per-turn resource spent to play cards. |
| **Gold / Currency** | Meta-currency spent in shops for cards/relics/removal/upgrades. |
| **Relic / Joker** | A persistent passive modifier that alters rules via triggered effects (Balatro: *joker*; StS: *relic*). |
| **Scoring (chips × mult)** | Balatro-style score model: a play's value = chips × multiplier. (Use if the game is Balatro-like; StS-like games score via damage/HP instead.) |
| **Upgrade / Remove** | Improving a card or deleting it from the deck (usually at shops/events). |
| **Event** | A non-combat node offering choices with risk/reward. |
| **Boss** | The capstone encounter of an ante/act. |
| **Reward** | Post-encounter choice (card, gold, relic). |
| **RunState** | The in-memory owner of all per-run data. |
| **DataRegistry** | The startup-loaded index of all content resources, keyed by `Id`. |

> When the design settles on Balatro-style scoring vs StS-style HP combat (or a hybrid), record the decision here and in `systems/scoring.md` / `systems/encounter-combat.md`.
