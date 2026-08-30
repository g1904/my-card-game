# Answer log stack-entry-kind-for-item-use

- 日期：2026-08-30
- 来源：`inbox/archive/solution-draft-stack-entry-kind-for-item-use.md` → `handoffs/2026-08-30-stack-entry-kind-for-item-use.md`
- 移出条数：1

## 移出的条目

**用道具产生的栈条目落在 `StackEntryKind` 的哪个成员上** → **新增第五个成员 `UsedItem`，不复用 `ActivatedAbility`**（复用会让 `sourceEntryId` 与 `abilityId` 两格同时变可空，抹掉该成员的全部不变式）。连带：栈条目**新增 `itemId` 一格**（与 `kind == UsedItem` 互为双向不变式，三个来源格对道具恒空）· `CombatFeedKind` 增 `ItemUse`（战报因果树要读得出「喝药」与「启动异能」之别）· 读档校验 ② 的强解析清单扩入栈条目的 `itemId`，并写明 ②/⑥ 分档（`CombatItemSave.ItemId` 仍走 ⑥ 且丢弃不影响该栈条目结算）· `UseItem` 段补齐 mana 扣费与 `InsufficientMana`（`ItemData.ManaCost` 早已存在，是一处既有缺口）· `card.played` 不由 `UseItem` 广播。存档面为空迁移（`kind` 增员不加字段，`itemId` 一格量级可忽略）。（归档去向：`systems/services/combat-service.md`、`systems/character-profile/deck/common-properties.md`）

## 同批裁决（本身不在待答清单上，故不计入移出条数）

- **是否同批开 `TimingIds.ItemUsed`** → **不开**（用户确认，此前为「采纳推荐 — 待复核」）。时点表随广播点一同增长，当前无内容需要它；开它要连带给 `SubjectKind` 增一档并扩 `TriggerFilter` 相容校验矩阵。日后要开是纯加法。

## 承接项（未随本次处理）

- `ADR-0121` 末行的「待答：用道具产生的栈条目落在 `StackEntryKind` 哪个成员上」已失效，应由下一次 `/write-adr` 在固化本决策时清理。`decisions/` 本次零改动。
