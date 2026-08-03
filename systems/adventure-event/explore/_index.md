# adventure-event / explore（AdventureEvent-Explore）

> **新类型「探索秘境」**（07-24 加入的第八类）。具体机制未定——从 handoff 播种，细节见 ## 待决问题。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **探索秘境（Explore）= AdventureEvent 的新子类型（第八类）。** 语义：**探索一处秘境**。07-24 随本次重构从 handoff 播种。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。
- 目前仅有类型名与一句语义；玩法机制尚未设计（见待决问题）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Explore 作为第八类加入分类法**（ADR-0002 待补订）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **「探索秘境」的核心机制是什么？** 是逐格 / 逐层探索、随机遭遇、寻宝、还是嵌套子事件序列？未定。
- **风险 / 奖励结构？** 探索的产出（道具 / 卡牌 / 货币 / 隐藏属性）、风险（战斗 / 陷阱 / 失败退出）如何设计？未定。
- **与 location（地域）的关系？** 秘境是否是特定 location 才出现的事件、探索是否会改变 location？未定。→ `systems/game-progression.md`。
- **结算类型？** Explore 走事件式结算还是可能内嵌战斗结算？未定。
- **ADR-0002 补订：** 正式并入枚举待补。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/explore.md`（待建）
