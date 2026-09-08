# ADR-0169 — 战后可选奖励候选池扩为四族，并对 `Practice` 档整族排除 `PowerData`

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-mechanism-contradiction-roundup.md · answer-logs/log-mechanism-contradiction-roundup.md

## 背景

神通（`PowerData`）的内容编排口径已定 `CombatReward` 是它的开放获取通道之一，但 `combat-service.md` 侧的战后奖励候选池只列三族（`CardData` / `ItemData` / `CultivationTechniqueData`）——两份文档对同一个池给出不同的族清单。这是机制矛盾，不是措辞问题：按前者写实现会取不到神通，按后者写会让最轻的一档也掉神通。

## 决策

**战后可选奖励候选池 = 四类混合**（`CardData` / `ItemData` / `CultivationTechniqueData` / **`PowerData`**）。

**加一个档位闸：`PowerData` 只在 `combatTier ∈ { Standard, Finale }` 时进候选族，`Practice` 档整族排除。** 这是**唯一**一处让三档生成路径产生族级差异的地方。

神通候选另带两条口径：**已持有的直接排除**；选中即产出一条 `AbilityChangeElement(Grant, Power, Character, id, Source.CombatReward)`。

候选族组装、取池链与 `Source` 落位 → `systems/services/combat-service.md`。

## 理由

- **四族是 `power/_index.md` 内容编排口径表的既定结论**（`ADR-0152` / `ADR-0153` 同批落地的那张表），`combat-service.md` 侧的三族清单是漏更新，矛盾裁给前者。
- **`Practice` 档整族排除**：最轻一档也掉神通会把这条获取面**稀释成常规掉落**——而神通的定性正是「稀有、单条强度显著」。
- **已持有直接排除**：神通无层数概念，重复授予没有语义。

## 备选方案

- **不加档位闸、三档一视同仁** — 否决：稀释神通的稀有定性。
- **撤回 `power/_index.md` 的编排口径、维持三族** — 否决：那要推翻一整批刚落地的、带承重论证的编排表。

## 后果

- **三档生成路径自此有且仅有这一处族级差异**——须在 `combat-service.md` 明写「唯一」，否则日后会被当成「档位可以随意差异化」的先例。
- **神通的获取频次因此挂在 `Standard` / `Finale` 的出现次数上**，与 `ADR-0161` 的频次预算共用同一批分母。
- 受约束的文档：`systems/services/combat-service.md` · `systems/character-profile/power/_index.md` · `systems/balance.md` · `content/character-power/`（内容侧后果）· `decisions/ADR-0152-cross-carrier-boundary-criterion.md`。
