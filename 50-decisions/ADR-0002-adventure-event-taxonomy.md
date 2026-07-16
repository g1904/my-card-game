# ADR-0002 — 修行事件分类法（六类）

- status: Accepted
- date: 2026-07-15
- supersedes:
- superseded-by:

## Context
逐时逐刻的游玩单元 **修行事件 / AdventureEvent** 需要一套稳定的类型分类，以驱动内容设计、选择界面与「并非每个事件都是战斗」这一支柱。备选的粒度可粗可细；风险在于类型间语义重叠（如自我精进类彼此含混）以及漏掉常见节点（休整、随机事件）。此决定级联影响 `20-systems/encounter-combat.md`、内容 schema（每个 `.tres` 事件带一个类型）与选择 UX。参见 `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。

## Decision
修行事件分为**六类**：

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 修炼 | Practice | 比试 / 切磋——低风险的战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**：进入后才揭示为其余某一类 |

- **休养 / Rest 不作为顶层类型**——休整 / 恢复并入 **战斗** 或 **闭关** 之中发生。
- **未知 / Mystery 是元类型**：入场时才解析为其它某一类，而非一种独立的结算形态。
- **修炼 与 闭关 的边界**：修炼 ≈ **比试**（对练），闭关 ≈ **研究**（潜修），以此消除自我精进类的重叠。

## Consequences
- 内容 schema：每个 `AdventureEvent` 数据条目带一个类型枚举（六值）。`Mystery` 需要一个「揭示」机制，在进入时映射到其余五类之一。
- 仅 `Combat`（以及作为其变体的 `Practice`）走战斗结算流程；其余类型是事件 / 抉择流程——落实了「并非每个事件都是战斗」。
- 无独立的休整节点类型；恢复必须由 Combat/Research 事件承载，或由其它系统（法宝 / 属性）提供。
- 待办：`Mystery` 的揭示权重、`Practice` 与 `Combat` 的风险 / 回报差异，属平衡与内容设计范畴。
- 篇章边界的境界突破（渡劫 / boss）是否复用 `Combat` 仍待确认（见 handoff Open questions），不在本 ADR 裁定范围内。
