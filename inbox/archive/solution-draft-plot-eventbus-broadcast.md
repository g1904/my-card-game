---
type: solution-draft
date: 2026-09-03
question: plot 分支揭示 / 选择、key point 推进是否走 EventBus？若走，事件名与负载形状为何。
source: open-questions/04-hidden-attributes-plot.md → 隐藏属性 / 剧本机制（焦点）
targets: systems/services/plot-manager.md（「事件面」一段）· systems/architecture.md（EventBus 负载契约表下的注解）· systems/services/future-event-service.md（API 面）· ux/screen-flow.md
status: distilled
reviewed: 2026-09-03 — 批量评审：送达通道取选项 A（门面新增只读投影 TryGetPlotSegment）；「事件面」现文裁定为占位表述、可改写。合并 interview 追加：PlotArcAdvanced 的完整签名住 plot-manager.md、architecture.md 只留不含签名的结论。落笔时证伪本稿三处自述——需松动的措辞是三处 + 一处计数句（非两处）· ux/screen-flow.md 并非无需改动 · 负载纪律 1 的原话语境不适用于本题
distilled-to: handoffs/2026-09-03-plot-eventbus-broadcast.md
---

# 方案草稿 — plot 分支揭示 / 选择 / key point 推进的广播面

## 问题

`systems/services/plot-manager.md`「事件面」现文写：

> 剧情线触发经宿主服务广播 `PlotThresholdReached(...)`；分支揭示 / 选择、key point 推进**同样由宿主服务代为广播**（manager 不直接持有 EventBus 通道）。

但 `systems/architecture.md` 的 **EventBus 负载契约表**里剧本相关只有 `PlotThresholdReached` 一行，**没有分支揭示 / 选择 / key point 推进的对应行**，事件名与负载 schema 两侧都不写。两份文档一份说「广播」、一份不登记，实现时必然各造一个事件名与一份负载。

同一个空位还牵出一条**至今无明文的链路**：结算面板的「剧本段」要渲染 `PlotSegment`（正文 + 分支按钮），但 `TryResolvePlot` 是 manager 内部方法、不上门面（`plot-manager.md`：「只有 `ChooseBranch` 投影到服务门面上」），而 `AdvanceResult` 里也没有它 —— **呈现侧目前没有任何拿到剧本段的合法通道**。这条链路走不走 EventBus，正是本题的实质内容。

## 约束（来自既有设计）

| 约束 | 来源 |
|---|---|
| **负载纪律 1：负载只带 `Id` + 值类型，绝不带 `Resource` / 完整实例引用；需要完整实例的订阅者按 `Id` 向 future-event-service 取** | `systems/architecture.md`「EventBus 负载契约」 |
| **负载纪律 3：广播 = 既成事实，不可否决；EventBus 不承载「请求 / 询问」，需要返回值的一律是直接方法调用** | 同上 |
| 负载为 `readonly record struct`，广播在热路径上不分配（总则 5） | `systems/architecture.md` 总则 5 |
| **manager 不被跨服务调用**；PlotManager `internal sealed`，跨服务代码写不出它的类型名 | `plot-manager.md`「API 面」· `architecture.md` 总则 3 |
| 剧本段的呈现时点 = `eventEnd` 那一次 `TryApply` **提交之后**，落在事件结算面板内 | `plot-manager.md` · `ux/screen-flow.md`「事件结算面板的剧本段」 |
| `ChooseBranch` 不触发 `RefreshAfterEvent`、终态判定恒 no-op、不计软阻塞闸门、不新增存档点 | `plot-manager.md` · `handoffs/2026-09-02-plot-branch-choice-ui.md` |
| key point 写入是 `ProfileManager` 的一次 `TryApply`（`PlotKeyPointAssignment`）；sync 的 diff 单位是 `CharacterProfile` 本身 | `plot-manager.md` · `systems/services/profile-service.md` |
| 「不预留冻结结构，但把正确做法记一句」（路标而非结构） | `systems/services/content-service.md` |
| 成就进度采集面（EventBus 被动订阅 vs 各服务主动上报）**尚未定** | `systems/player-profile/achievement/_index.md` |

## 建议方案

### ① 剧本相关的 EventBus 事件保持**恰好一条**（`PlotThresholdReached`），分支揭示 / 选择 / key point 推进**一条都不新增**

`[既有推演]`

三条依据逐条对上既有纪律，没有一条依赖新判据：

- **分支揭示写不进负载（纪律 1）。** 揭示要送达的是 `PlotSegment(ArcId, NodeId, Body, Branches, Modulation)` —— `Body` / `Label` 是 `LocalizedText`、`Branches` 是列表、`Modulation` 是 `Resource`。按纪律 1 全部不得进负载。退化成只传 `(ArcId, NodeId)` 后，订阅者必须回查才能渲染，**而唯一能回查的实现体是 `internal sealed` 的 PlotManager**（跨服务写不出类型名）—— 于是这条事件对任何订阅者都不可消费：广播了等于没广播，UI 仍旧要一条直接查询通道。**先建一条不可消费的事件，再补一条查询方法，是把一件事做两遍。**
- **分支揭示在语义上是「询问」（纪律 3）。** 它的全部目的是**等玩家输入**并据此推进 arc；纪律 3 明写 EventBus 不承载请求 / 询问，需要返回值的一律直接方法调用。这条不是风格偏好，它挡的正是「广播出去、然后等某个订阅者回调回来」这种反向依赖。
- **选择与 key point 推进当前零跨系统消费方。** 逐条核过：`ChooseBranch` **不触发 `RefreshAfterEvent`**（明写禁令）· 终态判定**恒 no-op** · **不新增存档点**、不计软阻塞闸门 · sync-service 的 diff 单位是 `CharacterProfile`，key point 变化随档案自然进 diff，**不需要事件通知** · 调用方（结算面板）拿的是同步 `OpResult`。**订阅者列表为空的事件不是解耦，是一处必然漂移的死契约**（它没有任何一处消费点会在它被改坏时报错）。

**故建议把 `plot-manager.md`「事件面」那句改写为明确的否定 + 各自的真实通道**（改写文本见「具体形态」）。现文那句是一处**占位表述而非决策**——它把三件性质不同的事（阈值触发 / 玩家询问 / 档案写入）一并说成「同样由宿主服务代为广播」，而后两件在既有纪律下都不该走 EventBus。

### ② `PlotThresholdReached` 的既有行不动，只补写它的广播时点

`[既有推演]`

负载 `(string CharacterId, HiddenStat Stat, int BandIndex)` 与广播者 `future-event（代 PlotManager）` **原样保留**，一个字不改。补一句时点：**在 `eventEnd` 五步组装的 ⑤「一次 `TryApply` → 终态判定 ② → EventBus 广播」那一批里广播，与 `EventResolved` 同批**，不在组装中途广播。依据是纪律 3 的直接推论：**广播 = 既成事实，而事务提交前跨档这件事还不是事实**（`TryApply` 全有或全无，中途广播会在回滚时留下一条已发出的假事实）。

### ③ 剧本段的送达 = 宿主服务门面上的一次**只读查询**（形态 A）

`[既有推演]`

纪律 1 的后半句已经把形态写死了：**「需要完整实例的订阅者按 `InstanceId` 向 future-event-service 取」**。剧本段正是「完整实例」那一类，取法照抄这条既定通道即可：

```csharp
// future-event-service 门面（形态 A · 纯只读）
bool TryGetPlotSegment(CharacterProfile character, out PlotSegment segment);
```

- **纯只读、可重入、无副作用**：内部即一次 `PlotManager.TryResolvePlot(character, out segment)` 的转发 —— **不消耗任何随机子流、不写存档、不推进 key point、不重算 eventOptions**，故重复调用（面板重绘、退出重进）安全。
- **失败语义原样继承 `TryResolvePlot`**：全部 arc 惰性 / 无 `Active` arc → 返 `false` + 已有的 `PushWarning`，呈现侧**不渲染剧本段**、面板照常出「继续」，轮回继续（**不是失败路径**）。
- **参数取 `CharacterProfile`**：与同门面的 `ComputeEventOptions(CharacterProfile)` / `RefreshAfterEvent(CharacterProfile, ...)` 同形，且与 `TryResolvePlot` 的既有签名逐字对齐，零转换。
- **调用时点**：`AdvanceEventAsync` 返回、`Success == true` 且 `StatusAfter` 非终态之后（终态时整段不渲染，直接走轮回结束屏 —— 既定）。这与「呈现时点 = `eventEnd` 那一次 `TryApply` 提交之后」逐字重合。
- **代价明写**：它是 PlotManager 在服务门面上的**第二处投影**，需松动 `plot-manager.md`「只有 `ChooseBranch` 投影到服务门面上」与 `future-event-service.md`「PlotManager 的**唯一对外投影**」两处措辞。见「与既有决策的张力」与「仍需用户决定」。

### ④ 若日后确需广播：预留的是**路标，不是结构**

`[通行做法]` + `[既有推演]`

唯一可预见的未来消费方是 **AchievementManager**（若其采集面定为「EventBus 被动订阅」，且真的存在剧本相关成就条件）。按 content-service 既定的「不预留冻结结构，但把正确做法记一句」，**本次不建**，只在 `architecture.md` 负载契约表下方留一句路标，形状与 `PlotThresholdReached` 同型：

```
PlotArcAdvanced | (string CharacterId, string ArcId, string NodeId, PlotArcState State) | future-event（代 PlotManager）
```

- 全部是 `Id` + 值类型（`PlotArcState` 是既有枚举，声明在「共享核心类型」），满足纪律 1；广播时点同 ②（收口 ⑤ 那一批），`ChooseBranch` 那一次独立提交后同样发一条。
- **不进负载契约表**（表里只登记真的会被 `Emit` 的事件），只作为一句注解存在；成就采集面定案且确有剧本条件时，把这一行搬进表内即可，**届时零形状讨论**。

## 具体形态（可 derive 的落地面）

**（1）`systems/architecture.md` EventBus 负载契约表：新增 0 行、改 0 行。** 表下补一句注解：

> **剧本层只广播 `PlotThresholdReached` 一条。** 分支揭示走宿主服务门面的只读查询 `TryGetPlotSegment`（纪律 1 的「按 `Id` 向 future-event-service 取」+ 纪律 3 的「询问不走广播」）；分支选择与 key point 推进当前零跨系统消费方，不广播。日后成就采集面若定为 EventBus 被动订阅且确有剧本条件，按 `PlotArcAdvanced(string CharacterId, string ArcId, string NodeId, PlotArcState State)`（广播者 future-event 代 PlotManager）补一行。

**（2）`systems/services/plot-manager.md`「事件面」改写为：**

> **事件面：** 剧情线触发经宿主服务广播 `PlotThresholdReached(string CharacterId, HiddenStat Stat, int BandIndex)`，时点在 `eventEnd` 五步组装 ⑤ 提交之后那一批（与 `EventResolved` 同批）—— 提交前跨档还不是既成事实。**剧本层只有这一条 EventBus 事件。**
> - **分支揭示不走 EventBus**：`PlotSegment` 含 `LocalizedText` 与 `Resource`，按负载纪律 1 写不进负载；退化成只传 `Id` 后订阅者无从回查（本 manager `internal sealed`）；且它的目的是等玩家输入 = 纪律 3 的「询问」。送达通道是宿主服务门面的只读查询 `TryGetPlotSegment`。
> - **分支选择与 key point 推进不广播**：`ChooseBranch` 同步返 `OpResult`；key point 变化随 `CharacterProfile` 进 sync 的 diff；不触发 `RefreshAfterEvent`、终态判定恒 no-op ⇒ 零跨系统消费方。

**（3）`systems/services/future-event-service.md` API 面新增一行：**

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 剧本段 | A | `bool TryGetPlotSegment(CharacterProfile character, out PlotSegment segment)` | 全部 arc 惰性 / 无 `Active` arc → `false` + `PushWarning`（`TryResolvePlot` 既有语义），呈现侧不渲染剧本段、轮回继续；**非失败路径** |

并把「`ChooseBranch` 是 PlotManager 的**唯一对外投影**」改为「PlotManager 的两处对外投影之一（另一处是只读的 `TryGetPlotSegment`）」。

**（4）呈现侧时序（无新增存档点、无新增结算阶段）：**

```
AdvanceEventAsync → ⑤ 一次 TryApply（含 PlotElements 的 key point 推进）
   → 终态判定 ② → EventBus 广播（EventResolved · 必要时 PlotThresholdReached）→ 自动存档点
   → 返回 AdvanceResult
   → 呈现侧渲染结算面板 → TryGetPlotSegment(character, out segment)
        false → 只出「继续」
        true  → 追加剧本段（跨档叙事行在上、剧本段在下）
                 Branches 空 → 正文 +「继续」
                 Branches 非空 →「继续」不出现，全宽分支按钮取代它
                     → 玩家点选 → ChooseBranch(branchId) → OpResult → 面板收起
```

## 后果

- **EventBus 负载契约表零新增行**；`architecture.md` 只多一句注解，`plot-manager.md` 改写一段，`future-event-service.md` API 面 +1 行、改一处措辞。
- **存档 schema 零改动、零迁移**；不新增存档点、不新增结算阶段、不新增子流、不新增条件编译处（仍 5 处）。
- **`AdvanceResult` 形状不变**（仍是全值类型 `readonly record struct`）。
- 呈现侧多一次跨服务只读调用；因其无副作用，面板重绘 / 退出重进都安全。
- 影响面文档：`systems/architecture.md` · `systems/services/plot-manager.md` · `systems/services/future-event-service.md`。`ux/screen-flow.md`「事件结算面板的剧本段」**无需改动**（本方案填的是它下面那条数据通道，呈现结论一字不动）。

## 备选方案（已考虑并否决）

- **建 `PlotSegmentRevealed(string CharacterId, string ArcId, string NodeId, bool HasBranches)` 广播揭示。** 否决：订阅者拿不到正文与分支标签，仍须一条查询通道 ⇒ 一件事做两遍；且揭示在语义上是询问（纪律 3）。
- **把 `PlotSegment` 直接塞进负载。** 否决：正面违反纪律 1（带 `Resource` / 完整实例引用），且每次广播都要分配。
- **剧本段挂在 `EventOptionBatch` 上随 `RefreshAfterEvent` 返回。** 否决：`EventOption` / 批次是**落存档**的定稿实例，把 `LocalizedText` 正文挂上去等于让剧本正文进存档，与「快照 / 结构里不存字符串正文」及「剧本内容不落存档」两条正面冲突。
- **剧本段随 `AdvanceResult` 由 life-cycle 转交。** 见「仍需用户决定」——它是一个成立的备选，不是被否决项。
- **现在就把 `PlotArcAdvanced` 建进负载契约表。** 否决：当前零订阅者，违「不预留冻结结构」；改为留一句路标（③④）。
- **让 PlotManager 自己持有 EventBus 通道。** 否决：manager 纪律明写「manager 不直接持有 EventBus 通道」，且本 manager `internal sealed`。

## 与既有决策的张力

1. **`plot-manager.md`「事件面」现文与本方案相反**（现文称分支揭示 / 选择、key point 推进「同样由宿主服务代为广播」）。本方案主张那句是**占位表述而非决策**——它没有对应的事件名、负载与订阅者，且把三件性质不同的事一并归为广播。**需要用户确认可以改写它**；若用户认为那句是已决策的意图，则本方案的 ①③ 需整体重做（届时必须回答「谁订阅、拿到 `Id` 后向谁回查」两问）。
2. **「只有 `ChooseBranch` 投影到服务门面上」 / 「PlotManager 的唯一对外投影」两处措辞需松动**（若采纳方案 A，见下）。松动的是**数量表述**、不是纪律本身：`TryGetPlotSegment` 仍是宿主服务代为转发的只读查询，PlotManager 类型仍 `internal sealed`、仍不被跨服务直接调用。
3. **与成就采集面的未定项相邻**（见「前置依赖」）：本方案主动选择「不预留」，若日后采集面定为 EventBus 被动订阅，需要补一次 ④ 的路标落表。这是一次**加行**、不改任何既有形状，代价被明确接受。

## 前置依赖

- **AchievementManager 的进度采集面（EventBus 被动订阅 vs 各服务主动上报）尚未定**（`systems/player-profile/achievement/_index.md`）。它**不阻塞本方案定稿**——本方案的 ①②③ 在两种采集面下都成立；只有 ④ 那句路标是否兑现为真事件取决于它。
- **每条剧情线的具体内容**（煞气反噬 / 心魔滋生）仍待答，但它是内容编排，与广播面无关，不构成阻塞。

## 仍需用户决定

**（1 项）剧本段送达呈现侧的通道形态。** 两个选项都不走 EventBus（那一半由 ① 的推演定死），差别只在由谁把 `PlotSegment` 交到面板手里：

- **选项 A（推荐）—— future-event-service 门面新增只读投影 `bool TryGetPlotSegment(CharacterProfile character, out PlotSegment segment)`。**
  - 后果：PlotManager 在门面上从一处投影变成两处，需松动两处「唯一投影」措辞；呈现侧需要同时与 life-cycle（推进）和 future-event（剧本段）两个服务对话；`AdvanceResult` 形状不变。
- **选项 B —— 保持单一投影，剧本段由 life-cycle 在收口后向 future-event-service 取一次、随 `AdvanceResult` 交回呈现侧。**
  - 后果：门面投影数不变、呈现侧只与 life-cycle 一个服务对话；但 `AdvanceResult` 从**纯值类型 `readonly record struct`** 变成携带引用字段（`PlotSegment` 含 `LocalizedText` / `Resource`）的载体，且 life-cycle 就此承担剧本呈现的转发职责——它当前对剧本层零认知（收口只经 `PlotElements` 一列，不解析剧本图）。

  **推荐 A，理由三条：** ① 它**逐字就是**纪律 1 后半句规定的做法（「需要完整实例的订阅者按 `Id` 向 future-event-service 取」），选 B 等于为剧本段单独发明第二种取法；② `AdvanceResult` 保持纯值类型，与总则 5「负载 / 结果不装箱」的整体口径一致；③ 让 life-cycle 认识 `PlotSegment` 会把剧本层的呈现知识扩散到第二个服务，而 A 只在**已经认识剧本的那个服务**上加一个只读转发。选 B 的唯一实质收益是「唯一投影」这句措辞不用改——它是一句描述，不是一条承重纪律。

  → **已裁决（2026-09-03 · 批量评审）：选项 A —— future-event-service 门面新增只读投影 `bool TryGetPlotSegment(CharacterProfile character, out PlotSegment segment)`。** 两处「唯一对外投影」措辞随之松动（松动的是数量表述，不是纪律）。

## 张力 1 的裁决（2026-09-03 · 批量评审）

→ **`plot-manager.md`「事件面」现文（三者「同样由宿主服务代为广播」）经用户裁定为占位表述，可改写。** 本方案的 ①②③ 全部成立，无需重做；剧本层的 EventBus 事件保持恰好一条 `PlotThresholdReached`，负载契约表零改动。
