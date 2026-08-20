# `ProfileChangeSpec` 的三处载体缺口与只读投影的语义面

- id: 2026-08-19-profile-change-spec-gaps
- date: 2026-08-19
- topic: systems/architecture · systems/services/profile-service · systems/services/life-cycle-service · systems/services/combat-service · systems/adventure-event/common-properties · systems/character-profile
- status: distilled
- distilled-to: `systems/architecture.md`、`systems/services/profile-service.md`、`systems/services/life-cycle-service.md`、`systems/services/combat-service.md`、`systems/adventure-event/common-properties.md`、`systems/character-profile/_index.md`

## Intent (distilled)

三处字段「有纪律、无通道」——纪律写着「一切写入经 `ProfileManager`」，而 `ProfileChangeSpec` 里没有一列装得下它们。补齐这三条通道，并把收口那一次事务的语义面定死。

### 一 · `activeCombat` 收进既有的 `EventStateChanges`，不另开列

按三级判据 ① 逐面核对，`ActiveCombat` 的写入与 `EventStateChanges` 在**六面上全部对齐**（不钳制 · 恒不走 modifier pipeline · 必需缺失即整批拒绝 · 绝对置值故幂等 · 无量纲 · 固定枚举键 → 整个结构块），判据明文要求不分列。

- `EventStateKey` 追加一员 `ActiveCombat`，`EventStateAssignment` 加第三个具名可空载荷格。
- `ActiveEvent` / `ActiveCombat` 允许置空，`EventOption` 仍不允许。
- **两个中间态字段不合并**，共用的只是写入通道——「两个同形的中间态不该各长一套写入纪律」正是本条要买的东西。
- 新增两条入口一致性校验：`Key == ActiveCombat` 且值非空时，施加后 `activeEvent` 不得为 `null`、且 `EventInstanceId` 必须相等（读档侧同款校验的施加侧对偶）。

### 二 · RNG 子流状态另开一列 `RngElements`

第六面不对齐（一次提交常需更新多条子流，而 `EventStateChanges` 有「同批两条同 `Key` 即缺陷」这条承重校验；`PlotElements` 的键是内容 `Id`、载荷是五格剧本状态）⇒ 分列。

- 载荷 `RngStateAssignment(RngStream Stream, ulong State, int DrawCount)`，按子流键的绝对置值 upsert。
- **不配表**（四条子流在取值域 / 终态 / 修正准入上完全相同）；**`Seed` 不进 spec**（可由 `CycleSeed` 重算）。
- 它买到的是「凡消耗了子流随机的提交，该子流状态必须在同一次原子写内更新」这条不变式的**机械保证**：SeedManager 记 `pending`、唯一组装路径 `AttachRngState(spec)` 清账、组装方在持久化前 `#if DEBUG` 比对。
- **`activeCombat.rng` 三格删除**：战斗内随机直接用 `combat` 子流、不再派生一层 ⇒ 第二个状态字段是纯冗余。当前无线上存档 ⇒ 空迁移。

### 三 · `pastEvent` 的追加另开一列 `TraceElements`

第四面（追加**不幂等**）与第六面（无键、序列尾部追加一个大结构块）均不对齐 ⇒ 分列；载荷**直接复用 `PastEventEntry`**，不建镜像类型（字段众多且随快照判据继续增长，镜像等于两张必须同步增删的字段表）。

**直接收益：「记入 `pastEvent`」并入收口那一次 `TryApply`**——三份结算流程图里画在事务之外的那一步就此消失，「收口是一次事务、一个存档点」由结构兑现而非由约定兑现。`Aborted` 那一路同样由失败流程组装**一次**提交（痕迹 + 两个中间态清空 + 轮回结束统计），不新增存档点。

### 四 · `Project(spec)` 的语义面

- **与 `TryApply` / `CanAfford` 共用同一段 `Evaluate(spec)`**。分叉的代价是玩家拿到一批依据一份从未存在过的历程算出的选项，且事后无从发现。
- **做钳制，不判终态**（终态判定本就在 `CycleStateManager`，是读取侧纯函数）。
- **判负照常重算、照常提交**，重算入口不多分支。
- **一次性视图**：不缓存、不存字段、不跨 `await` 持有。
- 收口的五步组装顺序与**闭合性条件**（`Project` 之后只允许追加「不构成重算依据」的列）落 `life-cycle-service.md`。

## Clarifications

interview 逐条裁决如下；每条注明它推翻或细化了原始输入的哪一句。

- **`Project` 的签名形态？** → 取**直返形态**的 `Project(spec)` + `PushError` + `throw`（投影失败 = 收口 spec 组装缺陷 = 必需缺失，落总则 2 第一档）。**推翻原始输入 §4a 末条与「具体形态」表里的 `bool TryProject(ProfileChangeSpec spec, out PlayerProfile projected)`**——那是可选缺失的签名形状，却配了必需缺失的严重度且不履行 `throw`，不落总则 2 的任何一档。
- **投影视图的一次性纪律落第几级？** → 跨 `await` 持有取**第 1 级**（`ref struct` 包装：C# 在语言层禁止存字段与跨 `await` 持有）；「`Project` 之后改了 ① 类列」取第 3 级（组装代码的静态形状，开发期必现）。**细化原始输入 §4c / §4d 把两条都自评为第 3 级**——前者可能只在线上时序下发生，按「能上线且线上不可见 → 必须第 1 或第 2 级」的判据第 3 级不够。与上一条合并落笔：方法形态仍是直返、不用 `out`，返回类型是包装 `PlayerProfile` 的投影视图。
- **`AppliedChange` 的「恒不含」断言覆盖哪几列？** → **只覆盖 `TraceElements`，`RngElements` 照常入账**。**推翻原始输入 §3 与「与既有决策的张力」2 的「恒不含 `TraceElements` / `RngElements` 两列」**——把 `RngElements` 断言为空，正好取消掉本方案用来击败「`TryApply` 自动捕获 RNG」的那条理由（账带上 RNG 终态、可完整重放），而「可直接重放的账」是已写进活文档的定性。
- **战斗内逐点提交的整块 `ActiveCombat` 会灌进 `AppliedChange` 吗？** → 明写**累加时的列剔除清单**：装的是「账本本身」的列（当前即 `EventStateChanges`）不累加，只累加变更。**这是原始输入完全未提及的后果**——它只处理了两列的自指，没处理 `EventStateChanges` 的累加；不剔除则一次战斗事件把约 31 份完整 `ActiveCombat`（单点 2–4 KB）灌进一条痕迹，与「战斗类痕迹只存 `EnemyId` + `Level` 轻摘要」的体积纪律正面相抵。
- **`SeedManager` 清账断言的检查点落在哪？** → 落**决策点持久化前的组装方**（life-cycle-service / combat-service）。**推翻原始输入 §2「不变式的机械保证形态」③ 的「任一 `Stream(...)` 取用前」**——敌人整个回合内部不落决策点，其间数十次随机消耗之间没有任何提交，按取用时刻判会在每一场战斗里连续误报；也不落 `ProfileManager` 入口，那要求 profile-service 反向读 life-cycle-service。
- **`ProfileChangeSpec` 在「投影后补两列」时如何被修改？** → 改 `sealed record` + `with` 派生，各列仍只读。**细化原始输入**——它的 §2 `AttachRngState(spec)` 与 4d 步骤 ④ 都要求修改一个已构造的 spec，而当时的 `sealed class` + 只读列表写不出来。否决 Builder（全部组装点改写）与可变列（与「服务不返回内部可变集合」相抵）。
- **`Seq` 的起始值？** → **0**，并在痕迹 schema 的 `Seq` 条目明写（此前空白）。原始输入取 0 未给依据；依据是 `PlotKeyPoint.EnteredAtSeq` 的既有下界校验写作 `< 0`，而它引用的正是本字段。
- **`DrawCount` 单调不减校验与新轮回 / 篇章重试时子流归零的冲突？** → 单调校验**只约束轮回进行中的 upsert**；`CycleSeed` 与子流初始化随 `StartCycle` 附带写入、不走本列。**细化原始输入**——它把字段表第 21 行整格改为 `RngElements` 却未区分这两条路径，照字面第一次提交即触发回退校验。不给承重校验开「整流重置例外」的口子。
- **`Aborted` 那一笔与轮回结束的统计计数是同一次提交还是两次？** → **同一次**（痕迹 + `ActiveEvent` / `ActiveCombat` 清空 + `StatDelta(+1)` + 已消耗子流的 `RngElements`）。**细化原始输入 §3 的「由失败流程组装一次 `TryApply`」**——它没说这一次与既有的「轮回结束顺带写统计计数」是不是同一次；拆成两笔就重新制造了本方案要消除的「同一逻辑事件两次提交」。
- **三级判据第六面的措辞。** → 补全为「访问形态 + 键的取值空间 + 载荷的字段集合，三样全部相同才算这一面对齐」。这是原始输入自己列为「必做连带项」的一条，按字面不补则 `RngElements` 与 `PlotElements` 会被判为六面全对齐，推出「把 RNG 塞进 `PlotElements`」的荒谬结论。

以下五项在输入进入本次提炼前已由用户裁定，按裁定写入，不再复议：RNG 另开一列 · `ActiveCombat.rng` 收敛 · `TraceElements` 直接复用 `PastEventEntry` · 投影判负照常重算并提交 · `ActiveCombat.EventInstanceId` 一致性校验落 `ProfileManager` 入口。

## Open questions

- **`Project` 的第二个消费点。** 目前恒为一个（收口重算）。「一次性视图」纪律在只有一个消费点时代价为零；若日后出现第二个消费点，须同批复核缓存问题。
- **战斗之外四类事件的决策点清单。** 不阻塞本次三条通道（战斗内 D0–D6 已定），但决定其余四类事件是否也在事件内提交除 `EventStateChanges[ActiveEvent]` 之外的中间态。该清单答定前，本次结论对非战斗类事件只覆盖已定的两处派生（Explore 揭示 · Exchange 刷新）。
