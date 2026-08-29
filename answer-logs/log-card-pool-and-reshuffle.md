# Answer log card-pool-and-reshuffle

- 日期：2026-08-27
- 来源：`inbox/solution-draft-card-pool-and-reshuffle.md`（→ `handoffs/2026-08-27-card-pool-and-reshuffle.md`）
- 移出条数：2

- **`OutcomeRule.DeckOperation` 走池抽时「该 `Op` 对应的池」全库无定义** → 保留走池抽并收窄为**仅 `AddLooseCard`**，其余四个 `Op` 的 `TargetId` 必填非空；取池链逐字沿用商店 `Card` 族那一条（`AllEnabled()` → `Pool != Enemy` → 排除功法成员卡 → `CardTypeFilter` → `RarityFilter` → 加权 `PickMany` 无放回）；子流复用 `RngStream.Reward`；**抽取在物化时掷定并落存档**；新增 `CardTypeFilter` 一格（`RarityFilter` / `Count` 共用既有格）；`LearnTechnique` 不开池抽；池容量校验为清单式 `PushWarning`、不拒绝加载；短缺按物化期降级 + `PushWarning`(want / got)。（→ `systems/adventure-event/common-properties.md`、`systems/character-profile/deck/_index.md`）

- **卡牌效果重洗牌库是否开口、以何形态开** → **开口**，形态限定为 `MoveCard` 的目的地扩展：抽牌堆**顶 / 底**两个确定性插入位（`InsertPosition { Top, Bottom }`，仅目的地为抽牌堆时有意义），**首批不开随机位**；护栏落在**载体消耗性**与 `TurnLimit` 上，「整堆 / 全部」形态硬禁；触发式载体允许携带、不加配额闸。同批改写 `combat-service.md` 推论 ④ 与其前瞻注记、`deck/_index.md`「只减不增」（`⇄` 不动）。`ADR-0052` 的决策 / 理由 / 备选三节不动，只在后果补一条边界说明。无存档 schema 变更。（→ `systems/services/combat-service.md`、`systems/character-profile/deck/_index.md`、`decisions/ADR-0052-no-reshuffle-fatigue.md`）

**本次连带的定案与新增待答（记此备查）：**

- **`AddLooseCard` 池抽的稀有度权重表挂战后奖励池那一张**（族维度已含卡牌、同为轮回内用途），事件产出侧固定取一档、不按战斗优势档选表；**取值不动**，仍归 `open-questions/01-combat.md`「`RarityTier` 的分布与权重表」。（→ `systems/balance.md`）
- **`MoveCardEffect` 允许把对手抽牌堆的牌搬走**（不加校验）⇒ `balance.md` 那条「原子操作里没有削减对手抽牌堆的形态」的理由改写，其**重开判据随之触发**：「疲劳扣减是否进 `EncounterSpec` 覆写组」**重新登记为待答项**，本次不答定、不改任何数值。
