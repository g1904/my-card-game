# Data index

Game content is **data**, authored as custom `Resource` classes serialized to `.tres`, indexed at startup by the **DataRegistry** autoload. Rules: `.claude/rules/data-resource-rules.md`. Nothing is authored yet (fresh scaffold); this lists the intended content types and the schema conventions.

## Content types (intended)

| Type | Resource class (planned) | Key fields |
|------|--------------------------|-----------|
| Card | `CardData` | `Id`, `Name`, `Description`, cost, rarity, effect definition, art. |
| Relic / Joker | `RelicData` | `Id`, `Name`, `Description`, trigger(s), effect, rarity. |
| Enemy | `EnemyData` | `Id`, `Name`, HP, intent/behavior table, art. |
| Encounter | `EncounterData` | `Id`, enemy id list, blind/reward config, ante range. |
| Event | `EventData` | `Id`, prompt text, choice list (each with outcome). |
| Blind / Ante | `BlindData` / ante config | `Id`, requirement, reward, ante scaling. |
| Balance config | `BalanceData` | tunable global numbers (energy/turn, ante scaling curves, drop weights). |

## Schema conventions (enforced)
- **`Id`** is a stable, unique string and the only cross-reference key. Never reference content by name, array index, or scene path.
- Display strings are separate fields (localizable, changeable without breaking references).
- Cross-type references use ids (e.g. `EncounterData.EnemyIds : string[]`). DataRegistry validates them on load — dangling ids are a startup `GD.PushError`.
- Tunable numbers live in exported fields / `BalanceData`, never hardcoded in system logic.

## Where `.tres` files live
Decide a folder convention when authoring begins (suggested: `res://data/cards/`, `res://data/relics/`, …). Record the final layout here so DataRegistry's load globs and this note stay in sync.
