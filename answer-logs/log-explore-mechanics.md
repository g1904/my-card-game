# Answer log explore-mechanics

- 日期：2026-08-17
- 来源：`inbox/archive/solution-draft-explore-mechanics.md`（`status: decided`）→ `handoffs/2026-08-17c-explore-reveal-mechanics.md`
- 移出条数：4

## 逐条

**Explore 揭示池的权重（`open-questions/02-event-options.md` · `explore/_index.md`）** → **不设第二套权重机制。** 真身类型分布 = Explore 条目池的组成 × 既有的加权抽取，是涌现结果而非运行时旋钮——遮罩的是模板上写死的固定条目，运行时没有任何一个时刻可以掷这个权重。`AdventureEventData` / `LocationData` / `PlotModulation` 三处**一律不加字段**。三档调制能力因此不对称（location 只到类型级、剧本靠对单条 Explore 条目加权、篇章不设旋钮），明写接受。（归档去向：`systems/adventure-event/explore/_index.md`「真身类型的分布」、`systems/services/future-event-service.md`、`systems/game-progression.md`）

**揭示时机与 UI，含是否给部分线索（`explore/_index.md`）** → **揭示 = 一层全屏转场覆盖层**（非独立 `Screen`、不进屏幕栈、无返回路径）：≈ 1.2s、全屏任意触点跳过、无「确定进入」按钮、无二次揭示分层、零 hover 通道、一次短音效无震动。**遮罩态卡片与其余 eventOption 完全同构**（不做异形 / 加大 / 特效卡），卡面只取 Explore 模板自己的文案与图标，不标敌人等级。**部分线索完全不给**——机械的危险度档 / 类型图标等价于把真身类型印在卡上，会把已被封死两次的泄漏面从第三侧捅开；「这个秘境格外凶险」的表达位已让渡给文案与美术。（归档去向：`ux/screen-flow.md`、`systems/adventure-event/explore/_index.md`）

**与 location（地域）的关系（`explore/_index.md`）** → **秘境走既有的类型出现概率修正，不硬分池、不限特定 location；修正的粒度止于类型，及不到真身分布。** location 的修正表 Explore 一行只能表达「洞天多秘境」，表达不了「洞天的秘境多半是战斗」——不为它开条目级子权重行（那等于把第二套 `EventWeights` 塞进 `LocationData`，并立刻引出「PlotManager 能不能改它」而对侧无字段可填）。（归档去向：`systems/game-progression.md`、`systems/adventure-event/explore/_index.md`）

**Explore 子类型专有字段清单（`explore/common-properties.md`）** → **清单闭合：只有 `RevealedEventId` 一个字段。** 模板侧与物化侧同名、物化时直拷零变换；`IsRevealed` 只存在于物化侧（模板恒为「未揭示」）。分布不需要权重字段、呈现不需要线索字段，故没有其余专有字段。（归档去向：`systems/adventure-event/explore/common-properties.md`）

## 顺带处理（不计入移出条数）

- **一处措辞滞后已修：** `open-questions/03-adventure-event-types.md` 把「遮罩下的成本呈现」仍列为 Explore 的待答，而它已由成本侧收口那一场答结（只存在一份 `selectCost`、Band 2 如实展示）。本次删去该措辞。
- **两处字段数滞后已修：** `adventure-event/common-properties.md` 与 `open-questions/02-event-options.md` 仍写 `EventOption` 骨架「八字段」，实为九字段（`ResearchSlots` 已落定）。
- **新增待答 1 条**（落 `03-adventure-event-types.md`）：Explore 的两个待实测初值（真身占比 `5:3:2` · 转场时长 ≈ 1.2s）。
- **未替既有待答项「寿元告警是否伴随音效 / 震动」拍板**——揭示转场的音效是另一条独立问题，两者互不预设。
