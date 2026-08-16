# adventure-event / explore / common-properties（Explore 子类型共有属性）

> Explore 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **遮罩引用（内容侧固定指定）。** Explore 条目在内容侧固定指向一个被遮罩的 AdventureEvent（真身），取值域限 Combat / Travel / Exchange。它是模板上的静态引用，不在物化时现掷。
- **`IsRevealed` / `RevealedEventId`（物化字段 · 沿用）。** 揭示状态与真身 `Id` 走既有的两个 `EventOption` 物化字段，痕迹侧走 `PastEventEntry.RevealedEventId`——**不新增字段**。见 `../common-properties.md`。
- 其余子类型专有字段待「揭示池权重」与「遮罩下的成本呈现」两问答定后补。

Source: `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **专有字段清单：** 遮罩引用与揭示两组字段已定；其余待 `_index.md` 的揭示池权重与成本呈现两问答定后补。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/explore.md`（待建）
