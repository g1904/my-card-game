# adventure-event / explore / common-properties（Explore 子类型共有属性）

> Explore 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **子类型专有字段只有一个，清单闭合（承重）：**

  | 字段 | 类型 | 必填 | 语义 | 校验 |
  |---|---|---|---|---|
  | `RevealedEventId` | `string`（`[Export]`） | **是**（`eventType == Explore` 时） | 被遮罩的真身条目 `Id`，内容侧静态指定 | 加载期四条，见 `_index.md`「取池与校验」 |

  遮罩引用是模板上的静态引用，**不在物化时现掷**，取值域限 Combat / Travel / Exchange。除它之外 Explore 没有任何专有字段——分布不需要权重字段（见 `_index.md`「真身类型的分布」），呈现不需要线索字段（同页「不给部分线索」）。
- **模板侧与物化侧同名（`RevealedEventId`），物化时直拷、不做任何变换。** 取不同的名字（如模板侧叫 `MaskedEventId`）会诱使读者以为中间发生了转换，而实际上没有。
- **`IsRevealed` 只存在于物化侧**，模板上没有对应字段（模板恒为「未揭示」）。揭示状态与真身 `Id` 走既有的两个 `EventOption` 物化字段，痕迹侧走 `PastEventEntry.RevealedEventId`——**不新增字段**。见 `../common-properties.md`。
- **`DestinationLocationId` 不是 Explore 的专有字段**，但真身为 Travel 时该字段在壳实例上一并填好（必为随机那一档）；它与 `RevealedEventId` 同属揭示前不得进入呈现层的字段，见 `_index.md`。

Source: `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- 无。专有字段清单闭合，仅剩的数值项（定价表 Explore 行、真身占比初值）见 `_index.md` 的待决问题。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/explore.md`（待建）
