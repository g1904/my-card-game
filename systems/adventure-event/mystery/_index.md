# adventure-event / mystery（AdventureEvent-Mystery）

> 元类型：遮罩一个**固定的** AdventureEvent，进入后才揭示为其余某一类。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **Mystery = 元类型（meta-type）。** 未知（Mystery）本身不是一种独立玩法，而是**遮罩其余某一类 AdventureEvent**；玩家进入后才揭示其真实类型。Source: `systems/adventure-event/_index.md`、`terminology.md`。
- **遮罩的是一个固定的 AdventureEvent（已明确）。** Mystery 揭示的是一个**预先确定的、固定的** AdventureEvent，而**非在点击时临时生成**——即遮罩层只隐藏类型，被遮罩的具体事件在该 Mystery 内容条目上已固定指定。Source: `terminology.md`、`handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Mystery 为元类型，进入后揭示** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **Mystery = 遮罩一个固定 AdventureEvent（非点击时生成）。** Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **揭示时机与 UI：** 何时揭示（进入瞬间 / 结算前）、揭示的视觉呈现、被遮罩类型是否有部分线索（图标暗示）未定。
- **可被遮罩的子类型范围：** 是否任意九类之一都可被 Mystery 遮罩（含 Finale / Travel？），还是仅子集，未定。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/mystery.md`（待建）
