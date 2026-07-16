# encounter-combat

> 回合结构、敌人意图/AI、胜/负结算。

## 意图
> _设计意图,从 handoffs 中提炼。保持更新。_

- **encounter** 是逐时逐刻的游玩单元。战斗存在,但**并非每个 encounter 都是一场战斗**——这是对 Slay the Spire「每个节点都战斗」节奏的有意背离。
- encounter 呈现**事件 / 选择**,其后果会影响玩家及未来状态;encounter/事件机制参照**月圆之夜(Night of the Full Moon)**建模。
- 战斗发生时是**回合制**且易读(意图预告式),而非实时 / 拼 APM。
- 底层压力遵循一种**类 Reigns 的属性平衡**手感——选择在相互竞争的仪表间摆动,而非优化单一数值。
- 来源:`10-handoffs/2026-07-13.md`。

**术语重命名。** 逐时逐刻的游玩单元由 **encounter** 更名为 **修行事件 / AdventureEvent**(单个节点;整段旅程为「修行历程」);本文档余下的「encounter」一词均按此理解。见 `terminology.md`。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。

**修行事件分类法(六类 · 已定案 ADR-0002)。** 修行事件分为六类;仅 战斗(及其变体 修炼)走战斗结算,呼应「并非每个事件都是战斗」这一支柱:

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**:进入后才揭示为其余某一类 |

休养 / Rest 不单列,并入 战斗 或 闭关。定案见 `50-decisions/ADR-0002-adventure-event-taxonomy.md`。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **修行事件分类法(六类):** 修炼/战斗/闭关/交易/社交/未知。休养并入 战斗 或 闭关;未知为元类型(进入后揭示);修炼≈比试、闭关≈研究。→ `50-decisions/ADR-0002-adventure-event-taxonomy.md`(Accepted)。

## 待决问题
> _尚未解决,需要一次 handoff/决策。_

- **篇章边界高潮事件:** 境界突破(渡劫 / boss)是复用 战斗/Combat 类型,还是独立于分类法的存档转场?倾向后者(见 handoff)。
- **选择界面:** 「从可用修行事件中选择」的界面如何呈现?→ 与 `map-progression`、`40-ux/` 关联。
- **战斗模型:** 基于 HP(StS)vs. chips×mult(Balatro)vs. 一套修仙专属模型——尚未确定。
- **属性模型:** 要平衡哪些属性,encounter 又如何推拉这些属性?

## 对应
提炼至:`.claude/knowledge/systems/encounter-combat.md`
