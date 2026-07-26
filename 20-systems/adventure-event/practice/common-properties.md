# adventure-event / practice / common-properties（Practice 子类型共有属性）

> Practice 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **对手 / 切磋对象引用。** Practice 事件引用一个（组）对手；沿用 Combat 的回合制战斗结构与 life + mana 模型。Source: `20-systems/adventure-event/_index.md`。
- **低风险标记。** Practice 与 Combat 的关键区别是风险等级（具体机制待定，见 `_index.md`）。Source: `20-systems/adventure-event/_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **风险与惩罚字段：** 「低风险」如何在数据中表达未定。见 `_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/practice.md`（待建）
