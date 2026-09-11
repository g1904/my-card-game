# Answer log lifespan-item-supply-guardrail

- 日期：2026-09-09
- 来源：`inbox/solution-draft-lifespan-item-supply-guardrail.md` → `handoffs/2026-09-09e-lifespan-item-supply-guardrail.md`
- 移出条数：**3 条**（其中 2 条为部分移出，剩余半条仍留在待答清单）

## 从待答清单移出（3 条）

**回寿法宝的总量护栏在内容编排面的口径未定（`open-questions/01-combat.md` · 承重）** —— 原句：「储物袋不设容量上限后，回寿法宝能囤多少完全交给内容编排面承接——出现频率 / 商店库存深度 / 定价三者的口径都还空着。……连带需一并评估的还有道具整体的获取频率、商店库存深度与置换对价。」
→ **结论：** 三格口径全部给出 —— **L-1** 逐池逐档条目占比 ≤ 6%（首批每池每档至多 1 条）· **L-2** 单个 Exchange 条目内 `CharacterItem` 族 Σ`SlotCount` ≤ 3、不为回寿法宝单设 stock rule 或专属 `RarityFilter` 编排位 · **L-3** 回寿档 ↔ `RarityTier` 一一绑定（50/100/200 ↔ Tier2/3/4 ↔ 40/80/160 灵石，单位价恒 0.80 灵石 / 点）。另补一条取池侧排除 **L-0**：含 `(CostKey.LifeSpan, BaseValue > 0)` 产出的 `ItemData` 不进战后奖励池、也不进开局强制事件的法宝三选一池（加载期反建索引 + 两处取池点共用，不新增字段 / 不落存档 / 不计数），把四条获取通道里两条免费通道一并封上。归档去向：`systems/character-profile/item/_index.md`、`systems/services/combat-service.md`、`systems/adventure-event/common-properties.md`、`systems/balance.md`、`decisions/ADR-0066-lifespan-gain-outcome-side-only.md`。
→ **部分留存：** 尾句「道具**整体**的获取频率、商店库存深度与置换对价」**未答**，该条已改写为只保留这一半，仍在 `open-questions/01-combat.md`。

**回寿法宝的总量护栏在内容编排面的具体口径未定（`systems/character-profile/item/_index.md` · 承重）** —— 原句：「规则层不设持有上限后，出现频率 / 商店库存深度 / 定价共同承接这条护栏，而三者的口径都还空着——它是寿元这条压力线的唯一剩余数量闸。」
→ **结论：** 整条答定，内容同上；已从该文档 `## 待决问题` 删除，口径正文落该文档「补天丹一类的回寿法宝」条。

**回复的幅度与来源分布（`systems/character-profile/life-span.md`）** —— 原句：「「通过 outcome 侧恢复」已定；三档的绝对点数（按本章可用预算的 5% / 10% / 20% 折算，ch1 即 50 / 100 / 200）仍待定案，归内容扩充后的统计校准。」
→ **结论（部分）：** 「**来源分布**」这一半答定 —— `R_c` 按事件侧 / 道具侧分账（50+50 / 58+58 / 159+158，Σ 不变 ⇒ λ 与 21 格 `lifeSpanCost` 定价表零改动），事件侧每章 1 次小档、道具侧由商店购入承担，道具侧的三格编排口径见 `systems/character-profile/item/_index.md`。
→ **部分留存：** 「三档的绝对点数」仍待实测校准，该条已收窄改写后留在该文档 `## 待决问题` 与 `systems/balance.md` 的对应待决项。

## interview 裁决（合并 interview · 与本草稿相关的 4 项）

**道具侧回寿的预算，从 `R_c` 分账还是另加？** → **分账，Σ 不变**（选项 A）。λ 与 21 格定价表零改动；接受的代价是回寿事件由「每章 2 次小档」降为「每章 1 次小档」，在事件流中更罕见（`systems/balance.md`）

**是否采纳 L-0（战后奖励池排除含 `LifeSpan` 产出的道具）？** → **采纳**（选项 A），落成取池侧排除：加载期反建索引 + 取池时过滤，形态照「成员卡不从散牌产出侧发放」。接受的代价：内容侧编排不出「打赢一场硬仗掉一颗补天丹」这一风味（`systems/services/combat-service.md`、`systems/adventure-event/common-properties.md`）

**开局强制事件的法宝三选一是否也套用 L-0 的排除索引？** → **同样排除**。推翻草稿「通道 ① 有天然硬上限、不需要闸」的判断：「一轮回至多一件」只封次数不封量级，抽到大档 = 免费 200 点寿元，是 ch1 道具侧整章预算（50 点）的 4 倍。复用同一份索引、零额外结构；代价是开局三选一不再出补天丹（`systems/character-profile/item/_index.md`、`systems/services/combat-service.md`）

**`ADR-0066` 的「三道软闸 + 一条结构性禁令」这句怎么处理？** → **删掉计数词「一条」**（直读裁定）。补「后果」一行后若保留计数，该 ADR 会出现「决策说一条、后果说两条」的自相矛盾；禁令的逐条清单本就由 ADR 推给 `systems/adventure-event/common-properties.md` 持有，ADR 侧持有计数即造第二权威。**决定本体不改、不新增编号**（`decisions/ADR-0066-lifespan-gain-outcome-side-only.md`）

## 标准默认（未出题，直接采纳）

**L-1 的分母口径** → 商店库存与战后奖励池均按篇章分池后，机械改写为「逐**池**逐档」；首批等价形态「每池每档至多 1 条」不变

**`R_item,c` 的「来源」一格** → 由「商店购入 + 池抽产出」收窄为「商店购入」；L-0 已把池抽归零、事件产出并入 `R_event,c`。数值一格不动

**「一章约 33 个免费候选位」** → 该数隐含「每场战斗都开奖励面板」，而面板不是每场都开；活文档一律不写这个数，改写为「≈ 4–5 次奖励面板 / 章 × 3 项候选」，具体数字回链战斗侧的挂池占比口径。L-0 的四条依据逐条复核后结论不变

**Exchange 事件数** → 由 10 / 10.4 / 12.4 校正为 ≈ 10.0 / 10.0 / 11.9（权重 0.32 × 管线事件数），`R_item,3` 随之 ≈ 145（偏差 −8%，仍在 ±20% 内）

**首批 3 条回寿法宝的字段取值表** → 属条目层，本次不落 `content/`（`item` 类型尚未开张）；类型级口径落 `systems/character-profile/item/_index.md`，条目本体待 `/scaffold-content-type character-item` → `/author-content` × 3
