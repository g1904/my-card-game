# adventure-event / finale / common-properties（Finale 子类型共有属性）

> Finale 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **境界跃迁标记。** 一个 Finale 事件对应一次境界突破（篇章边界），关联目标境界（筑基 / 金丹 / 元婴）。Source: `terminology.md`、`20-systems/adventure-event/_index.md`。
- **独立结算钩子。** Finale 走独立于 Combat 的境界突破结算。Source: `20-systems/adventure-event/_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Finale 数据 schema：** 独立结算机制未定，故字段清单（目标境界、检定条件、奖励 / 后果）尚不能定义。见 `_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/finale.md`（待建）
