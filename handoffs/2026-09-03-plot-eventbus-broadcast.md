# 剧本层的广播面：不新增事件，剧本段走门面只读查询

- id: 2026-09-03-plot-eventbus-broadcast
- date: 2026-09-03
- topic: systems/services/plot-manager.md · systems/architecture.md · systems/services/future-event-service.md · ux/screen-flow.md
- status: distilled
- distilled-to: systems/services/plot-manager.md, systems/architecture.md, systems/services/future-event-service.md, ux/screen-flow.md

## Intent（distilled）

剧本层「分支揭示 / 选择、key point 推进是否走 EventBus」这个空位同时牵出一条至今无明文的链路：结算面板要渲染 `PlotSegment`（正文 + 分支按钮），但 `TryResolvePlot` 是 `internal sealed` manager 的内部方法、不上门面，`AdvanceResult` 里也没有它 —— **呈现侧没有任何拿到剧本段的合法通道**。本次一并收口。

### ① 剧本层的 EventBus 事件保持恰好一条 `PlotThresholdReached`

三条依据逐条对上既有的 EventBus 负载纪律，没有一条依赖新判据：

- **分支揭示写不进负载。** 要送达的是 `PlotSegment(ArcId, NodeId, Body, Branches, Modulation)` —— `Body` / `Label` 是 `LocalizedText`、`Branches` 是列表、`Modulation` 是 `Resource`，**完整实例一律不进负载**。退化成只传 `(ArcId, NodeId)` 后，订阅者必须回查才能渲染，而唯一能回查的实现体是 `internal sealed` 的 PlotManager（跨服务写不出类型名）—— 于是这条事件对任何订阅者都不可消费。**先建一条不可消费的事件、再补一条查询方法，是把一件事做两遍。**
- **分支揭示在语义上是「询问」。** 它的全部目的是等玩家输入并据此推进 arc；EventBus 不承载请求 / 询问，需要返回值的一律直接方法调用。这条挡的正是「广播出去、然后等某个订阅者回调回来」这种反向依赖。
- **分支选择与 key point 推进当前零跨系统消费方。** `ChooseBranch` 不触发 `RefreshAfterEvent` · 终态判定恒 no-op · 不新增存档点、不计软阻塞闸门 · key point 变化随 `CharacterProfile` 自然进 sync 的 diff · 调用方拿的是同步 `OpResult`。**订阅者列表为空的事件不是解耦，是一处必然漂移的死契约**（没有任何消费点会在它被改坏时报错）。

### ② `PlotThresholdReached` 的既有行不动，只补写广播时点

负载 `(string CharacterId, HiddenStat Stat, int BandIndex)` 与广播者 `future-event（代 PlotManager）` 原样保留。补一句时点：**在 `eventEnd` 五步组装 ⑤「一次 `TryApply` → 终态判定 ② → EventBus 广播」那一批里广播，与 `EventResolved` 同批**。依据：广播 = 既成事实，而事务提交前跨档这件事还不是事实（`TryApply` 全有或全无，中途广播会在回滚时留下一条已发出的假事实）。

### ③ 剧本段的送达 = 宿主服务门面上的一次只读查询（形态 A）

```csharp
// future-event-service 门面（形态 A · 纯只读）
bool TryGetPlotSegment(CharacterProfile character, out PlotSegment segment);
```

- **纯只读、可重入、无副作用**：内部即一次 `PlotManager.TryResolvePlot` 的转发 —— 不消耗随机子流、不写存档、不推进 key point、不重算 eventOptions，故面板重绘 / 退出重进都安全。
- **失败语义原样继承 `TryResolvePlot`**：全部 arc 惰性 / 无 `Active` arc → `false` + `PushWarning`，呈现侧不渲染剧本段、面板照常出「继续」，轮回继续（**不是失败路径**）。
- **调用时点**：`AdvanceEventAsync` 返回、`Success == true` 且 `StatusAfter` 非终态之后。与「呈现时点 = `eventEnd` 那一次 `TryApply` 提交之后」逐字重合。
- **代价**：PlotManager 在服务门面上从一处投影变成两处，数量表述随之松动 —— 松动的是数量，不是纪律：`TryGetPlotSegment` 仍由宿主服务代为转发，PlotManager 类型仍 `internal sealed`、仍不被跨服务直接调用。
- 备选「剧本段随 `AdvanceResult` 由 life-cycle 转交」被否决：`AdvanceResult` 会从纯值类型变成携带引用字段的载体，且 life-cycle 就此承担剧本呈现的转发职责（它当前对剧本层零认知）。

### ④ 若日后确需广播：预留路标，不预留结构

唯一可预见的未来消费方是 AchievementManager（若其采集面定为「EventBus 被动订阅」，且真的存在剧本相关成就条件）。按「不预留冻结结构，但把正确做法记一句」，本次不建事件，只在机制所有者的文档内留一句路标：

```
PlotArcAdvanced | (string CharacterId, string ArcId, string NodeId, PlotArcState State) | future-event（代 PlotManager）
```

全部是 `Id` + 值类型（`PlotArcState` 是既有共享枚举）；广播时点同 ②，`ChooseBranch` 那一次独立提交后同样发一条。采集面定案且确有剧本条件时，把这一行搬进负载契约表即可。

### 呈现侧时序（无新增存档点、无新增结算阶段）

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

## Clarifications

- **剧本段送达呈现侧的通道形态（A：门面新增只读投影 / B：随 `AdvanceResult` 由 life-cycle 转交）→ 用户裁决取 A。** `future-event-service` 门面新增 `bool TryGetPlotSegment(CharacterProfile character, out PlotSegment segment)`；两处「唯一对外投影」措辞随之松动（松动数量表述，不松纪律）。
- **`plot-manager.md`「事件面」现文（分支揭示 / 选择、key point 推进「同样由宿主服务代为广播」）→ 用户裁定为占位表述、可改写。** 故 ①②③ 全部成立、无需重做；剧本层 EventBus 事件保持恰好一条，负载契约表零改行。
- **`PlotArcAdvanced` 那句路标写在哪 → 采纳标准默认：拆两处写。** `architecture.md` 负载契约表下只写不含签名的结论，完整签名住 `plot-manager.md`「事件面」内。依据：库内「回链而非复述 · 单一权威」纪律 —— 两处都写完整签名会制造第二权威、各自漂移；且登记面下方并置一条非登记事件的完整签名，会被后来者读成已登记。
- **需松动的「唯一投影」措辞实为三处 + 一处计数句，不是原始记录说的两处**（按核实后的库中实况落笔）。除 `future-event-service.md` API 表 `剧本分支` 行与 `plot-manager.md`「只有 `ChooseBranch` 投影」外，还有 `future-event-service.md` 那条逐字点名「`TryResolvePlot` 不出现在服务门面上」的推演 bullet（不同改则同一份文档内两处自相矛盾）；另有「本服务的 API 面是**四个**方法」这句计数句 —— 按本库既有纪律「承重表述不写数字」去掉数字，其承重部分是「不设单项补位」，与方法数无关。
- **`ux/screen-flow.md` 需改一处，原始记录「无需改动」的判断不成立**（按核实后的实况落笔）。「事件结算面板的剧本段」从呈现侧直接点名了 `internal sealed` manager 的 `TryResolvePlot`，而新增门面方法的全部目的正是消除这条非法引用。改法：方法名换成 `TryGetPlotSegment`，呈现结论 / 排布 / 交互一字不动。
- **负载纪律 1 的原话是「按 `InstanceId` 向 future-event-service 取」，语境是 EventBus 订阅者回查已物化的 `EventOption`**（按核实后的实况落笔）。本题既无广播也无 `InstanceId`，故不写成「纪律 1 已规定剧本段用这条通道」；③ 的依据收窄为「完整实例不进负载」+「询问不走广播」两条。
- **门面签名的参数名取 `character`**（与 `ComputeEventOptions(CharacterProfile character)` / `RefreshAfterEvent` 同形），而非 manager 侧 `TryResolvePlot` 的 `c`；「与既有签名逐字对齐」在参数名上不成立，取门面侧通行写法。
- **不把「同名转发」写成通则** —— 它是对 `ChooseBranch` 那一例的描述；`TryGetPlotSegment` 的名字已由裁决写死。
- **呈现侧直接调 future-event-service 不违反编排顶点纪律** —— 编排顶点负责「谁在什么时机调谁」，但不是一切跨服务调用的必经中转。连带：备选 B 记的收益「呈现侧只与 life-cycle 一个服务对话」本就不成立（`ChooseBranch` 的既有门面投影已使呈现侧必须与 future-event 对话）。

## 后果

- **EventBus 负载契约表零新增行、零改行**；`architecture.md` 只多一句注解。
- **存档 schema 零改动、零迁移**；不新增存档点、不新增结算阶段、不新增 RNG 子流、不新增条件编译处。
- **`AdvanceResult` 形状不变**（仍是全值类型）。
- **无跨库承接**：本题全在客户端进程内（EventBus 是进程内 C# 事件、剧本内容属本地内容层、PlotManager 无后端接口），后端库零改动。
- 呈现侧多一次跨服务只读调用；因其无副作用，重绘 / 退出重进都安全。

## Open questions

- **AchievementManager 的进度采集面（EventBus 被动订阅 vs 各服务主动上报）尚未定**（`systems/player-profile/achievement/_index.md`）。它不阻塞本次结论 —— ①②③ 在两种采集面下都成立；只有 ④ 那句路标是否兑现为真事件取决于它。
- **每条剧情线的具体内容**（煞气反噬 / 心魔滋生）仍待答，属内容编排，与广播面无关。
