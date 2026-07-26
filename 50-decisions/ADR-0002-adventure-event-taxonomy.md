# ADR-0002 — 修行事件分类法（九类）

- status: Accepted
- date: 2026-07-15
- supersedes:
- superseded-by:

## Context
逐时逐刻的游玩单元 **修行事件 / AdventureEvent** 需要一套稳定的类型分类，以驱动内容设计、选择界面与「并非每个事件都是战斗」这一支柱。备选的粒度可粗可细；风险在于类型间语义重叠（如自我精进类彼此含混）以及漏掉常见节点（休整、随机事件）。此决定级联影响 `20-systems/adventure-event/`（各子类型文件夹）、内容 schema（每个 `.tres` 事件带一个类型）与选择 UX。参见 `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。

## Decision
修行事件分为**九类**：

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 修炼 | Practice | 比试 / 切磋——低风险的战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**：遮罩一个**固定的**其余某类事件，进入后才揭示 |
| 境界突破 | Finale | **篇章边界高潮**：渡劫 / 突破至下一境界，**独立于 Combat 的结算形态** |
| 探索秘境 | Explore | 探索一处秘境 |
| 前往某处地点 | Travel | **地图路由选择**——刷新角色所在的 `location`（地域），由此框定下一批 eventOptions（归属逻辑落在 `20-systems/game-progression.md`） |

- **休养 / Rest 不作为顶层类型**——休整 / 恢复并入 **战斗** 或 **闭关** 之中发生。
- **未知 / Mystery 是元类型**：遮罩一个固定的其余（非 Finale）某类事件，入场时才揭示，而非一种独立的结算形态、也非点击时临时生成。
- **修炼 与 闭关 的边界**：修炼 ≈ **比试**（对练），闭关 ≈ **研究**（潜修），以此消除自我精进类的重叠。
- **境界突破 / Finale 独立于 Combat**：篇章边界的境界突破（渡劫 / boss）作为**独立类型**，而非复用 Combat；它是篇章高潮 / 存档转场式的特殊结算。
- **Travel 是地图路由**：功能上是换地点——刷新 `location`，从而换掉下一批 eventOptions（由 future-event-service 产出，见 `20-systems/services/future-event-service.md`）。
- **location / 地域** 是与 Travel 一同引入的抽象概念，**框定 eventOptions**；Travel 通过它换图。

## Consequences
- 内容 schema：每个 `AdventureEvent` 数据条目带一个类型枚举（**九值**）。`Mystery` 需要一个「揭示」机制，在进入时映射到其余（非 Finale）类之一。
- 仅 `Combat`（以及作为其变体的 `Practice`）走**战斗结算**流程；`Finale` 走**独立的境界突破结算**；其余类型是事件 / 抉择流程——落实了「并非每个事件都是战斗」。
- 无独立的休整节点类型；恢复必须由 Combat/Research 事件承载，或由其它系统（法宝 / 属性）提供。
- 待办：`Mystery` 的揭示权重、`Practice` 与 `Combat` 的风险 / 回报差异、`Finale` 的独立结算规则（区别于 Combat 的具体机制），属平衡与内容设计范畴。
- Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`、`10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`（Finale）、`10-handoffs/2026-07-24-docs-restructure-class-model.md`（Explore / Travel）。
