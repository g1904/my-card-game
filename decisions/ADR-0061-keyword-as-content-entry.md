# ADR-0061 — 效果关键字是内容层的注册表条目 `KeywordData`，不是呈现层的文案简写

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** handoffs/2026-08-16c-effect-keywords-and-targeting.md

## 背景

「灼烧 2」「护体 3」这类关键字，最省事的实现是把它当成卡牌描述里的一个文案简写——UI 层遇到就展开成完整说明。这样零数据结构、零注册表。

代价在三处显形：按关键字筛选效果时没有键可查；关键字的放量开关（`ContentEnabled`）与使用它的卡牌不原子；关键字的定义无处校验。

## 决策

**关键字 = 一个内容层的注册表条目，形态与次类型同构**：`[GlobalClass] partial class KeywordData : Resource`。

两种 `KeywordKind { Action, State }`，单个 `Amount` 参数，**不挂 `Rarity`**。

字段面与消费点 → `systems/character-profile/deck/common-properties.md`；术语 → `terminology.md`。

## 理由

有条目就有 `Id`，有 `Id` 就能被引用、被筛选、被校验、被图鉴收录。文案简写三样都没有。

`Amount` 单参数是有意的收窄：多参数会立刻把关键字推向「一门小语言」，而那正是被否决的方向（见备选）。不挂 `Rarity` 是因为关键字本身不进任何抽取池——它是卡牌的组成部分，稀有度归卡牌。

## 备选方案

- **纯呈现层的文案简写方案** — 否决（三条理由）：效果筛选无键 · `ContentEnabled` 不原子 · 不可一处校验。
- **通用表达式参数化（带求值器的效果小语言）** — 否决：会拖回需要求值器与沙箱的小语言，而 overlay 可热更 ⇒ 热更脚本的风险面过大。

## 后果

- `KeywordRef.Amount` 落战场条目独立的 `amount` 一格，**不进 `counters`**（→ `ADR-0075`）：`counters` 的语义是计数，`Amount` 是参数。
- 关键字首批清单为空，属内容充实面。
- 关键字定义在战斗内的呈现后置到详情页（→ `ADR-0083`）。
