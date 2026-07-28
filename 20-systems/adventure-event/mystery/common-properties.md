# adventure-event / mystery / common-properties（Mystery 子类型共有属性）

> Mystery 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **被遮罩事件引用。** 一个 Mystery 事件持有对其遮罩的**固定** AdventureEvent 的引用（以 `Id` 指向一个已确定的其余某类事件内容条目），而非生成参数。Source: `terminology.md`、`10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **揭示状态标记。** 记录该 Mystery 是否已揭示（进入前呈现为「未知」）。Source: `20-systems/adventure-event/_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **数据编码：** 遮罩引用如何落在存档中、揭示状态标记在一批 eventOptions 内如何随 `EventOption` 携带未定。→ `../common-properties.md`、`20-systems/services/future-event-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/mystery.md`（待建）
