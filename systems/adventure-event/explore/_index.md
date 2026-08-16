# adventure-event / explore（AdventureEvent-Explore）

> **元类型「探索秘境」**：遮罩一个**固定的** Combat / Travel / Exchange 事件，进入后才揭示。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **探索秘境（Explore）= 元类型（meta-type）。** Explore 本身不是一种独立玩法，而是**遮罩另一个 AdventureEvent**；玩家在批次里选中一个 Explore，等于「选了一个未知」，进入后才揭示其真实类型与内容。语义上「探索一处秘境」——秘境里有什么，进去才知道。
- **遮罩的是一个固定的 AdventureEvent。** Explore 揭示的是一个**预先确定的、固定的**事件，而**非在点击时临时生成**——遮罩层只隐藏类型与内容，被遮罩的具体事件在该 Explore 内容条目上已固定指定。**推论：既有的 `IsRevealed` / `RevealedEventId` 两个物化字段与 `PastEventEntry.RevealedEventId` 原样沿用，不新增机制。**
- **可被遮罩的真身取值域 = Combat / Travel / Exchange。**
  - **不含 Research**——卡组编辑是玩家主动规划的动作，把它藏在未知后面只制造挫败，不制造张力。
  - **不含 Explore 自身**（不嵌套）——元类型定义使然。
  - **Travel 可被遮罩，但揭示出的 Travel 必走随机那一档**：只给一个 seeded 随机邻接地域，玩家无从选择去哪（见 `../travel/_index.md` 的 80 / 20 掷定）。这与「秘境把人带到别处」的叙事同向。
- **一次选择仍只结算一个事件。** Explore 不是嵌套的二级菜单——进入即揭示即结算，`pastEvent` 上仍是**一条**痕迹（`EventType` 记当时呈现给玩家的 Explore，`RevealedEventId` 记真身）。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Explore 为五类分类法之一，且是唯一的元类型** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **遮罩一个固定 AdventureEvent（非点击时生成）；真身取值域 = Combat / Travel / Exchange**。

Source: `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **揭示池的权重。** 真身取值域已定；三者的出现权重、是否随 location / 篇章 / 剧本调制未定。→ `systems/services/future-event-service.md`、`systems/services/plot-manager.md`。
- **揭示时机与 UI。** 进入瞬间揭示已定；揭示的视觉呈现、被遮罩类型是否给部分线索（图标暗示 / 危险度提示）未定。→ `ux/screen-flow.md`。
- **与 location（地域）的关系。** 秘境是否只在特定 location 出现、是否与 location 的事件类型概率修正互相作用未定。→ `systems/game-progression.md`。
- **`selectCost` 的呈现。** `selectCost` 必须如实展示（让玩家算得出「这一步可能是最后一步」），但真身隐藏——遮罩下展示的成本是 Explore 条目自己的，还是真身的？两者若不一致会泄漏信息。→ `../common-properties.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/explore.md`（待建）
