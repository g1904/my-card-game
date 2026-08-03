# adventure-event / practice / common-properties（Practice 子类型共有属性）

> Practice 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **对手 / 切磋对象引用。** Practice 事件引用一个（组）对手；沿用 Combat 的回合制战斗结构与 **mana + 道念**模型（胜负 = 道念高者胜，见 `systems/scoring.md`）。对手等级同样在 eventOptions 上**精确标注**。Source: `systems/adventure-event/_index.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **低风险标记。** Practice 与 Combat 的关键区别是风险等级（具体机制待定，见 `_index.md`）。Source: `systems/adventure-event/_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **风险与惩罚字段：** 「低风险」如何在数据中表达未定。见 `_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/practice.md`（待建）
