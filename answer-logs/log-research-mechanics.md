# Answer log research-mechanics

- 日期：2026-08-17
- 来源：`inbox/archive/solution-draft-research-mechanics.md` → `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md`
- 移出条数：5

---

**Research 的卡组操作清单与代价、是否另有产出、开局构筑事件的候选生成**（`open-questions/03-adventure-event-types.md`「各类型的结算 / 机制细化」的 Research 一项）
→ **整段收口。** 结算形态 = **构筑面板**，模板持 N 个决策槽，物化时逐槽预先掷定候选，玩家逐槽择一，全部选择与 `lifeSpanCost` 合并为 `eventEnd` 的一次 `TryApply`（既有决策点面板的第三个实例，零新增结构）。操作清单**闭合为六类**：`LearnTechnique` / `UpgradeTechnique` / `ForgetTechnique` / `RemoveLooseCard` / `GrantItem` / `Recuperate`；`manaLimit ±1` 是附带产出而非独立操作。产出面收窄为**卡组 + `manaLimit` + `lifeTotal` + 全类型共有的隐藏属性推拉**，此外不给（不产灵玉、不给法则、暂不给神通）。候选生成**零新增抽取代码**：法宝三选一直接复用 `GrantPoolPicker`，功法三选一走 `CultivationTechniqueData` 仓储的 `AllEnabled()` / `DrawPool<T>`（第五个调用方），随机源均为 `RngStream.Reward`，候选池不接 modifier pipeline。代价不另收资源，全部由 `lifeSpanCost` 的 Research 行承载。开局构筑事件 = 该形态的一个内容条目（`eventPriority = 1` · 两槽 · 两槽 `AllowDecline = false` · `lifeSpanCost` 取 0 的条目级覆盖），无任何专属规则。
（归档去向：`systems/adventure-event/research/_index.md` · `research/common-properties.md` · `systems/services/future-event-service.md` · `systems/services/content-service.md`）

**`manaLimit` 下降（−1）的承载点**（`open-questions/03-adventure-event-types.md`）
→ **改挂 Research，且做成玩家自选的风险档。** 玩家可选一个高风险候选，成功 `manaLimit +1` / 失败 `−1`；掷定发生在**物化阶段**并随 `EventOption` 落存档（退出重进不改变结果）。四条依据：叙事轴与 mana 分档表天然对齐（Research 已是推高主通道，走火入魔是同一条轴的反面）· 它补上 Research 唯一缺失的张力（否则「最贵且必然赚」的事件会成为批次无脑首选）· 取消下降会让「不设下界护栏」「不做死牌转化」「高费卡成死牌可接受」三条既有决策成为无消费方的决策债 · **自选而非随机惩罚**是关键的一半。载体：`CostKey` 增成员 `ManaLimit`，`ResourceElements` 增一行 `(0, 无, 无终态, null, null)`——两个修正列留空是硬要求，任一列开放即可把 ±1 放大为 ±2。
（归档去向：`systems/character-profile/mana.md` · `systems/architecture.md` · `systems/services/profile-service.md` · `systems/adventure-event/research/_index.md` · `terminology.md`）

**候选里出现已持有功法怎么办**（`open-questions/01-combat.md`）
→ **排除，不折算为升阶。** 与 `GrantPoolPicker` 的「排除已持有」同构；折算会模糊「学新」与「升阶」的边界——二者在构筑面板里是两类各自可被限定的槽内操作。
（归档去向：`systems/character-profile/deck/_index.md` · `systems/adventure-event/research/common-properties.md`）

**功法 / 法宝三选一的 RNG 子流归属**（`open-questions/01-combat.md`）
→ **复用 `RngStream.Reward`，不新开子流。** `Reward` 已承载「候选预先掷定 + 落存档 + 绝不重抽」这一完全同构的用途，而奖励候选与构筑候选**从不并发**（一次只结算一个事件）；新开一条换来零隔离收益。
（归档去向：`systems/character-profile/deck/_index.md` · `systems/adventure-event/research/common-properties.md`）

**卡组被弃空的内容侧态度**（`open-questions/01-combat.md`）
→ **不做内容侧回避。** 规则层已由疲劳规则表达后果，且「输是正常出口」是既定取向；构筑面板的槽默认 `AllowDecline = true`，玩家不会被迫弃空，再加一层「只剩一门功法时不提供弃置选项」的特判只是把一条已有出口重复实现一遍。
（归档去向：`systems/character-profile/deck/_index.md`）

---

## 未答结、仍留在待答清单的部分

- **`Recuperate` 的回复量 · 走火入魔候选的出现权重 · 开局条目 `lifeSpanCost = 0` 的覆盖登记** —— 三个数值格，形态已定、取值归 ch1 数值标杆专场（`open-questions/03-adventure-event-types.md`）。
- **构筑面板的竖屏呈现与风险档的视觉标注** —— 方向已定（与战后奖励面板同构），形态未设计（同上分片）。
- **功法的层数上限** —— `UpgradeTechnique` 的候选过滤条件与 `ResearchCandidate.Amount` 的取值域待它答定；仍留在「功法的规模参数」条目下（`open-questions/01-combat.md`）。
