# Phase A — profile-change

- 输入草稿：`game-design-documents/inbox/solution-draft-profile-change-spec-gaps.md`（`status: decided`）
- 目标库：`game-design-documents/`（orchestrator 已给定）
- 本文件只读产出，未写入设计库任何文件。

## 一句话摘要

把三处「有纪律、无通道」的缺口补齐——`activeCombat` 收进既有 `EventStateChanges`（`EventStateKey` 加一员 + 载荷加第三格）、RNG 子流状态另开 `RngElements` 列、`pastEvent` 追加另开 `TraceElements` 列（`ProfileChangeSpec` 7 → 9 列），并把只读投影 `Project(spec)` 定为「与 `TryApply` / `CanAfford` 共用同一段 `Evaluate`、做钳制、不判终态、一次性视图」，从而让「收口是一次事务、一个存档点」由结构而非约定兑现。

## 已定案项（用户已裁决，不进 interview）

草稿 `## 用户裁决（2026-08-19 · 全部定案）` 五项，落笔时按定案写，不再问：

| # | 取向 | 定案 |
|---|---|---|
| ① | RNG 状态的通道形态 | 另开 `RngElements` 列（**连带必做**：`architecture.md` 三级判据第六面须补写「形状包含**键的取值空间**与**载荷的字段集合**」，必须与 ① 同批落笔，否则 ① 无判据支撑） |
| ② | `ActiveCombat.rng` 是否收敛 | 收敛：删 `ActiveCombat` schema 的 `"rng": { seed, state, drawCount }` 三格，战斗内随机状态由 `Rng.Stream[Combat]` 承载 |
| ③ | `TraceElements` 的载荷类型 | 直接复用 `PastEventEntry`，不建镜像类型 |
| ④ | 投影判负时的处置 | 照常重算新一批、照常提交；`RefreshAfterEvent` 不多分支 |
| ⑤ | `ActiveCombat.EventInstanceId` 一致性校验落点 | `ProfileManager` 入口 `PushError` + 整批拒绝 |

另有一条**跨草稿裁决已定**：本批四份草稿合计 `ProfileChangeSpec` 7 → 11 列（本片 `RngElements` + `TraceElements`，另加 codex 片 `CodexElements`、game-setting 片 `SettingChanges`），**必须单批收口、共用同一次 `schemaVersion` bump**。这是对 orchestrator 的硬约束，不是待答项。

以下 🔴 / 🟠 **均不属于上述五项**，是校验中新发现的、草稿未裁决的点。

---

## 🔴 冲突

### 🔴-1 `AppliedChange` 恒不含 `RngElements` ✗ 与本草稿 ① 的承重理由自相矛盾

- 草稿 §2 裁决 ① 的承重理由：「`AppliedChange` 由此**天然带上 RNG 终态、可完整重放**」。
- 草稿 §3 与「与既有决策的张力」2：「**`AppliedChange` 恒不含 `TraceElements` / `RngElements` 两列**（新增不变式）……落为入口断言：`spec.TraceElements[i].AppliedChange.TraceElements` 与 `.RngElements` 必须为空 → 否则 `PushError`」。
- 两句直接对立：把 `RngElements` 从 `AppliedChange` 中断言为空，正好取消掉 ① 用来击败「备选方案：`TryApply` 自动捕获 RNG」的那条理由（该备选被否决的理由之一即「spec 里没有 RNG 条目 ⇒ `AppliedChange` 重放不出同一份 `State`」）。
- `TraceElements` 那一半没有问题（自指防呆，论证成立）；有问题的只有 `RngElements` 那一半。

选项：
- **(a) 断言只覆盖 `TraceElements`，`AppliedChange` 保留 `RngElements`。** 后果：① 的承重理由成立，账可完整重放；代价是 `PastEventEntry.AppliedChange` 每条多带若干 `(Stream, State, DrawCount)` 三元组（每条 ≤ 4 条 × 约 20 B，量级可忽略）。
- **(b) 维持双列断言，改写 ① 的承重理由。** 后果：`RngElements` 分列的理由退回到「唯一能让『忘了带 RNG』被检出的形态」这一条（仍然成立，但 ①「可完整重放」那句必须删，且要在文档里明写「`AppliedChange` 重放不恢复 RNG 状态」）。
- **推荐：(a)** —— 依据 `systems/adventure-event/common-properties.md`「`AppliedChange` 是核心……一条**可直接重放的账**」与「可重放性不受影响」两处明文；(b) 要动的是一条已写进活文档的承重定性，而 (a) 只需把断言写窄一格。

### 🔴-2 战斗内 D0–D5 的逐点提交会把整块 `ActiveCombat` 灌进 `AppliedChange` ✗ 痕迹侧的体积纪律

- 既有：`PastEventEntry.AppliedChange` = 本次事件的最终账 = **收口那一次 spec + 事件内逐笔已提交的 spec 累加**（`adventure-event/common-properties.md`、`profile-service.md` 均明写）。
- 本草稿 §4d 末条新增：战斗内**每个决策点各一次** `TryApply(EventStateChanges[ActiveCombat = 当前局面] + RngElements[combat 子流])`。
- 两条相乘 ⇒ 一次战斗事件的 `AppliedChange` 将累加进 **约 31 份完整 `ActiveCombat` 块**（`combat-service.md` 明写单点 diff 量级 **2–4 KB**），即单条痕迹 60–120 KB。
- 这与既有纪律正面相抵：`adventure-event/common-properties.md` 明写战斗类痕迹**只存 `EnemyId` + `Level` 轻摘要**，否决存 `DeckCardIds` 的理由正是「它们是本作最胖的物化产物，而痕迹侧本就有体积护栏与增量 push 的顾虑」；`sync-service.md` 另有 `pastEvent` 的体积护栏。
- 草稿完全未提及这一后果（它只处理了 `TraceElements` / `RngElements` 的自指，没处理 `EventStateChanges` 的累加）。

选项：
- **(a) 明写「累加进 `AppliedChange` 的只包含记账有意义的列」，`EventStateChanges` 与 `RngElements`（若取 🔴-1 (b)）在累加时被剔除。** 后果：需在 `adventure-event/common-properties.md` 的 `AppliedChange` 段落新增一条剔除清单，并落为入口断言；`AppliedChange` 与逐笔入参的「不再逐字段相等」范围再扩一点（既定代价的延伸）。
- **(b) 改判据为「只累加事件级提交，战斗内决策点提交不进账」。** 后果：与既有「把逐笔已提交的 spec 累加进来」的措辞冲突较大，且会把古宝次数、战斗内血/mana 这些**本来就要记账**的条目一起漏掉。
- **(c) 战斗内决策点不走 `TryApply`，另辟通道。** 后果：直接推翻「一切写入经 `TryApply`」，与本草稿的立意相反。
- **推荐：(a)** —— 它是最小改动，且与既有「`AppliedChange` 记的是变更、不记账本本身」的方向同源；(b) 会丢掉已定要记的账，(c) 自毁立意。

### 🔴-3 `SeedManager` 清账断言 ③ 的字面语义会在正常游玩中持续误报（内部矛盾）

- 草稿 §2「不变式的机械保证形态」③：「`#if DEBUG`：任一 `Stream(...)` 取用前，若上一次 `TryApply` 之后仍有未清账的 `pending` → `PushError`」。
- 按字面：一次提交之后的**第二次**取用即命中（第一次取用后 `pending != 0`）。而战斗内一个回合就有多次抽牌、`combat-service.md` 明写「**敌人回合内部不落点**，D5 一个点即覆盖整个敌人回合，它是一段可确定性重放的区间」——敌人整回合数十次随机消耗之间没有任何 `TryApply`。断言会在每一场战斗里连续 `PushError`。
- 与草稿自己第 4d 节「战斗内的每个决策点是一次独立提交」「D0–D5 本就是既定存档点」直接打架。
- 存在第二种读法：「**发生了一次 `TryApply`，而它没带上未清账的 pending**」→ `PushError`。这一读法语义正确，但检查点应落在 `TryApply`（或决策点持久化）那一刻，**不是 `Stream(...)` 取用前**。两种读法导出完全不同的机制与落点。

选项：
- **(a) 检查点改在提交侧：`ProfileManager.TryApply` 入口（或 life-cycle/combat 的决策点持久化前）比对 `SeedManager` 的 `pending` 与 `spec.RngElements`，不一致 → `PushError`。** 后果：断言语义正确、零误报；但要求 profile-service 侧知道 SeedManager 的存在 —— **与既定服务依赖方向相反**，故实际落点应在**决策点持久化的组装方**（life-cycle-service / combat-service）而非 ProfileManager 入口。
- **(b) 保留 `Stream(...)` 取用前的检查，但判据改为「距上一次取用之间是否发生过一次未带 RNG 的 `TryApply`」。** 后果：语义等价于 (a)，但状态机更绕（要记「上次取用之后有没有提交过」）。
- **推荐：(a)，落点取组装方（决策点持久化前）而非 ProfileManager 入口** —— 依据 `architecture.md`「服务之间不读写对方字段」与草稿自己否决「`TryApply` 自动捕获 RNG」的同一条理由（profile-service 不得读 life-cycle-service）。

### 🔴-4 `bool TryProject(spec, out PlayerProfile projected)` + `PushError` 不落入总则 2 的任何一档

- 既有硬约束 `systems/architecture.md`「总则 2 —— 失败语义三分，与 null-check 规则一一对应」：**必需缺失** → `PushError` + `throw`；**可选缺失** → `bool TryXxx(..., out T)` + `PushWarning`；**业务失败** → 返回 `OpResult` / `ApplyResult`，**绝不抛**、不 `PushError`。
- 草稿的 profile-service API 面新行：`bool TryProject(...)`，失败时「`PushError`（收口 spec 组装缺陷）」、不抛。它借用了**可选缺失**的签名形状，却用**必需缺失**的严重度，且不履行必需缺失要求的 `throw`。
- 全库无先例：`TryGetActiveCharacter` / `ContentRegistry.TryGet` / `TryPickGrantable` / `TryPickReplacement` 全部是 `PushWarning` 的可选缺失。
- 连带：既有 `profile-service.md` API 表现写 `PlayerProfile Project(ProfileChangeSpec spec)`，本次要改写这一行 —— 改成什么形状取决于本题裁决。

选项：
- **(a) 取必需缺失的标准形状：`PlayerProfile Project(spec)`，失败 `PushError` + `throw`。** 后果：与总则 2 完全对齐；调用方（`RefreshAfterEvent` 前的收口组装）不需要写失败分支——组装缺陷本就该崩在开发期。签名与既有 API 表那一行**一字不改**，只补失败语义列。
- **(b) 保留 `TryProject` 形状，把失败降级为 `PushWarning`（可选缺失）。** 后果：与总则 2 对齐，但「收口 spec 组装失败」被当成可降级，与草稿自己「必须大声失败」的定性相反。
- **(c) 保留 `TryProject` + `PushError` + 不抛，并在 `architecture.md` 总则 2 里写明这是一处写明的例外。** 后果：动一条贯穿七服务的承重总则，收益仅为一个方法的签名偏好。
- **推荐：(a)** —— 依据总则 2 与草稿自身定性（组装缺陷 = 必需缺失），且它是唯一**不改任何既有文本**的选项。

---

## 🟠 含糊

### 🟠-1 `ProfileChangeSpec` 在「投影后补两列」时如何被修改（4d 步骤 ④ 的机制未定）

- `architecture.md` 现声明 `public sealed class ProfileChangeSpec`，各列为 `IReadOnlyList<T> { get; }`（只读、无 `record`、无 `with`）。
- 草稿 4d 步骤 ④「**补齐两列**」与 §2 的 `SeedManager.AttachRngState(spec)`（「把……写进 `spec.RngElements`」）都要求在 `Project` 之后修改一个已构造的 spec，而当前类型形态写不出来。
- 三种可信解读，导出不同的共享核心类型形状：(a) 引入 `ProfileChangeSpecBuilder`（组装期可变、`Build()` 冻结）；(b) 把 `ProfileChangeSpec` 改成 `sealed record` 并用 `with` 产生新实例（`AttachRngState` 改为**返回**新 spec 而非就地写）；(c) 让两列可变（破坏只读契约，与「服务不返回内部可变集合」同源纪律相抵）。
- 它同时决定 4d 那条 `#if DEBUG`「列指纹」断言怎么写（比对的是同一对象还是前后两个实例）。

选项与后果：
- (a) Builder：改动面最大（所有 spec 组装点改写），但组装/冻结边界最清晰。
- (b) `record` + `with`：改 `architecture.md` 一行类型声明；`AttachRngState(spec) → spec'` 是纯函数，与「element 只承载已定稿值、账可重放」同向；`sealed class` 改 `sealed record` 对落存档形态无影响。
- (c) 可变列：**不推荐**，与既定只读契约相抵。
- **推荐：(b)** —— 最小改动且保持不可变；`EventOption` 用 `record` + `with` 处理「定稿后确需派生」已是本库的现成惯用法（`architecture.md` 总则 6）。

### 🟠-2 `TraceElements` 的 `Seq` 起始值与「`Seq + 1` 连续性」入口断言

- 草稿新增入口校验：「`Seq != 现有 pastEvent 末条 Seq + 1`（**空列表时 `!= 0`**）→ `PushError` + 整批拒绝」。
- 全库未定义 `Seq` 的起始值：`adventure-event/common-properties.md` 只说「角色内单调递增、不复用、不因迁移重排」；`profile-service.md` 对 `PlotKeyPointAssignment` 的校验是 `EnteredAtSeq < 0 → PushError`（暗示 0 合法）而 `EnteredAtChapter < 1 → PushError`（1 起）。两处基准不同，草稿取 0 未给依据。
- 判错的代价不小：起始值取错会让**每个角色的第一个事件**在入口被整批拒绝。

选项：(a) 首条 `Seq = 0`（与 `EnteredAtSeq >= 0` 一致）；(b) 首条 `Seq = 1`（与 `chapter` 的 1 起同风格）。
- **推荐：(a)** —— `EnteredAtSeq` 引用的正是 `pastEvent` 的 `Seq`，而它的既有下界校验写作 `< 0`。裁决后须在 `adventure-event/common-properties.md` 的 `Seq` 条目明写起始值（当前是空白）。

### 🟠-3 `DrawCount` 单调不减的入口校验 vs 新轮回 / 篇章重试时子流的归零

- 草稿把 `character-profile/_index.md` 字段表第 21 行 `rng` 的写入通道由 `—（SeedManager）` 改为 `RngElements`（`CycleSeed` 仍为 `—`），同时新增「`DrawCount` 回退（小于 profile 现值）→ `PushError` + 整批拒绝」。
- 既有：`StartCycle` 附带写入「生成 `Rng.CycleSeed`、派生四条子流」；`RetryChapter` 换一套全新随机流、角色状态从该篇章起始存档带回。两处都会把 `State` / `DrawCount` 归零。
- 若归零也走 `RngElements`，第一次提交即触发回退校验；若归零仍走 `—`（SeedManager 直写），则字段表第 21 行的写入通道不能整格改为 `RngElements`。草稿没有区分这两条路径。

选项：
- (a) 第 21 行写作 `RngElements`（`CycleSeed` 与**子流初始化**仍为 `—`），单调校验只约束轮回进行中的 upsert。
- (b) 全部经 `RngElements`，单调校验加一条「`State == 0 且 DrawCount == 0` 的整流重置例外」。
- **推荐：(a)** —— 与既有「`StartCycle` 附带写入」的既定形态一致，且不给一条承重校验开例外口子（例外口子正是本草稿处处在消掉的东西）。

### 🟠-4 `Project` 的两条一次性纪律落在纪律阶梯第 3 级，是否满足选级判据

- 草稿 4c 与 4d 各落一条 `#if DEBUG` 断言（`commitOrdinal` 失效检查、`Project` 前后的列指纹比对），均自评为阶梯第 3 级。
- 既有承重判据 `architecture.md`「纪律的可执行化」：**「能上线且线上不可见 → 必须做到第 1 或第 2 级」**，判据是「违反后测试期能不能被发现」。
- 缓存一份过期投影的症状是「新一批依据一份从未存在过的历程算出」——草稿自己明写这**「事后无从发现」**。按判据字面，这恰恰是「能上线且线上不可见」，第 3 级不够。草稿未就这一条做选级论证。
- 存在现成的第 1 级手段：把投影视图做成 `ref struct` 包装 —— C# 在语言层禁止把 `ref struct` 存进字段、也禁止跨 `await` 持有，正是 4c 要求的两条纪律的**逐字对应**，且零运行时成本。

选项：
- (a) 投影视图取 `ref struct` 包装（第 1 级），`commitOrdinal` 断言保留为兜底。后果：`Project` 的返回类型不再是裸 `PlayerProfile`（与 🔴-4 的签名裁决联动）。
- (b) 维持第 3 级 `#if DEBUG`，并在文档里补一句选级论证（论点可取「唯一消费点在同一段同步代码内，越界写法在评审中显而易见」）。
- (c) 只对 4c 那条上第 1 级，4d 的列指纹断言仍留第 3 级（它比对的是组装方自己的顺序，开发期必现）。
- **推荐：(c)** —— 两条断言的暴露特性不同：跨 `await` 持有可能只在线上时序下发生（须第 1 级），而「`Project` 之后改了 ① 类列」是组装代码的静态形状，开发期必现（第 3 级够）。

### 🟠-5 `Aborted` 那一笔与轮回结束的统计计数是同一次提交还是两次

- 草稿 §3：「`Aborted` 那一路……由失败流程组装**一次** `TryApply`，同时承载 `TraceElements[Aborted 条目]` + `EventStateChanges[ActiveEvent = null]`。**不新增存档点**。」
- 既有 `life-cycle-service.md`：「轮回结束时顺带写账号级统计计数……`SavePointReason.CycleEnded` / 角色 `defeated` 那一次 `TryApply` 带上 `StatDelta(+1)`，**与规则字段同批、同事务**」。
- 终态判定 ① 判负 ⇒ 痕迹写入与 `defeated` 收尾发生在同一路径上。两处各自说「一次 `TryApply`」，但没说是不是**同一次**。若是两次，就出现了草稿要消除的那类「同一逻辑事件两笔提交」。

选项：(a) 合并为**同一次** `TryApply`（`TraceElements` + `EventStateChanges[ActiveEvent = null]` + `StatDelta(+1)` + 可能的 `RngElements`）；(b) 明写为两笔并给出理由。
- **推荐：(a)** —— 与「一个事件的收口是一次事务、一个存档点」同向，且既有文本已把 `StatDelta` 描述为「与规则字段同批、同事务」。

---

## 🔵 可推演（无需回答）

- **`ActiveCombat` 六面与 `EventStateChanges` 全部对齐 ⇒ 不分列。** 依据：`architecture.md` 三级判据 ①「任一既有列在这六面上与新语义全部对齐 ⇒ 不分列」+ `combat-service.md` / `character-profile/_index.md` 均已把 `activeCombat` 定性为「事件内的中间态，寿命短于一次事件」。逐面核对与草稿一致，无异议。
- **`ActiveCombat?` 作为第三个载荷格的类型名与既有一致。** `character-profile/_index.md` 字段表第 17 行的类型即 `ActiveCombat?`，与 `ActiveEventState?` / `EventOptionSave?` 并列不冲突。
- **`TraceElements` 分列成立。** `PastEventEntry` 的追加**不幂等**（第四面）且是**序列尾部追加大结构块**（第六面），既有九列无一对齐；`DeckElements.AddLooseCard` 形状同类但载荷是三标量且须解析注册表。
- **直接复用 `PastEventEntry`、不建镜像类型（③ 已裁）与既有判据自洽**：`PlotKeyPointAssignment` 用镜像的成本近零（五个标量），`PastEventEntry` 有 13 字段且随快照判据继续增长。
- **`Project` 必须与 `Evaluate` 复用同一段施加代码。** 与既有「`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`，正是为了防两条路径算出不同结果」同构，且投影的分叉风险更重（新一批已落存档）。
- **投影做钳制、不做终态判定。** 钳制：既定「截断只发生在施加到 Profile 字段那一刻」，投影正是施加；终态判定本就在 `CycleStateManager`（`life-cycle-service.md` 的两处判定表），不在 `Evaluate` 内，故「不做」是既有分层的自然结果、不需要新写一条规则。
- **`ActiveCombat.rng` 收敛（② 已裁）消掉的是一处既存相抵。** `systems/common-properties.md` 明写「战斗内随机直接用 `combat` 子流，**不在其上再派生一层**」⇒ 不存在第二个随机源 ⇒ `ActiveCombat.rng` 是纯冗余的第二份真值。
- **`RngElements` / `TraceElements` 在 `SelectCost` 内恒为空，各自独立成行。** 沿用 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 四条已各自独立成行的既定形态（`profile-service.md` 明写「不要合并成通则」）。
- **`PastEventEntry` 必须在 `Project` 之前进入 spec。** 既定「整批重算的依据 = 角色的整体历程，**重度依赖 `pastEvent`**」⇒ 新一批必须看得见刚走完的这个事件。
- **三份结算流程图必须同改**（`architecture.md` 总则 8 · `adventure-event/common-properties.md`「结算阶段」· `life-cycle-service.md`「固定结算流程」），三处画的是同一条流程。这是落笔时最易漏的一处。
- **`ProfileChangeSpec` 增列 ⇒ bump 存档 schema 版本**（`PastEventEntry.AppliedChange` 复用该类型），与 `DeckElements` / `PlotElements` / `EventStateChanges` 三次先例同款；当前无线上存档 ⇒ 空迁移。本批四份共用同一次 bump（跨草稿裁决已定）。

---

## 拟改动文档清单与各自新增要点

| 文档 | 新增 / 修改要点（供跨草稿核对） |
|---|---|
| `systems/architecture.md` | ①「共享核心类型」`ProfileChangeSpec` 由 7 列扩为 **9 列**（新增 `RngElements` / `TraceElements`）；②新增 `public readonly record struct RngStateAssignment(RngStream Stream, ulong State, int DrawCount)`；③`EventStateAssignment` 加第三格 `ActiveCombat? ActiveCombat`、`EventStateKey` 追加成员 `ActiveCombat`，并把「两格恒为 null = 置空，仅 ActiveEvent 合法」改写为三格/两个可置空键；④**三级判据第六面措辞补全**（形状包含「键的取值空间」与「载荷的字段集合」）—— **承重、与 ① 同批**；⑤总则 8 结算流程图把「记入 pastEvent」移进 `eventEnd` 那一次 `TryApply`；⑥「分列理由」段落补两列的语义；⑦（视 🟠-1 裁决）`ProfileChangeSpec` 由 `sealed class` 改 `sealed record` |
| `systems/services/profile-service.md` | ①两列各一段承重说明（`RngElements` / `TraceElements`）；②`EventStateChanges` 段落删除「**`activeCombat` 不在本列内**……这一处不对称是已知的」整句，改为已收进本列；③施加失败语义表新增约 **8–10 行**（`Key == ActiveCombat` 的两条一致性校验、载荷三格不匹配、同批两条 `ActiveCombat`；`RngElements` 未知子流 / 同批同 `Stream` / `DrawCount` 回退；`TraceElements` 的 `Seq` 连续性 / `InstanceId` 空 / 三个 `Id` 悬空 / 同批两条 / 自指防呆）；④「只读投影」段落补齐语义面（复用 `Evaluate`、做钳制、不判终态、一次性视图）；⑤API 表「只读投影」行改写（形状取 🔴-4 裁决）；⑥**待决问题移除 4 条**：`activeCombat` 写入通道 · RNG 写入通道 · `pastEvent` 无 spec 列 · `Project(spec)` 语义面 |
| `systems/services/life-cycle-service.md` | ①`eventEnd` 收口的**五步组装顺序**（组装重算依据列 → `Project` → `RefreshAfterEvent` → 只补两列 → 一次 `TryApply`）+ **闭合性条件**（`Project` 之后只允许追加「不构成重算依据」的列）；②RNG 不变式的机械保证形态（`SeedManager` pending 清账 + `AttachRngState` + 断言落点，形状取 🔴-3 裁决）；③`Aborted` 痕迹路径（合并笔数取 🟠-5 裁决）；④「固定结算流程」图把「记入 pastEvent」移进事务内；⑤「凡消耗了子流随机的提交……暂由组装方自律兑现，形态收口见待决问题」改写为已有载体；⑥**待决问题移除 2 条**：RNG 状态写入通道 · `Project(spec)` 语义面 |
| `systems/services/combat-service.md` | ①`ActiveCombat` 的写入通道明写为 `EventStateChanges`；②**删 `ActiveCombat` schema 的 `"rng": { seed, state, drawCount }` 三格**（②已裁），并在附近说明 combat 子流状态由 `Rng.Stream[Combat]` 承载；③D0–D5 每点的提交形态（`EventStateChanges[ActiveCombat] + RngElements[combat]`），D6 并入 `eventEnd` 原样成立；④「不新增存档点类型、不计软阻塞闸门」原样重申 |
| `systems/adventure-event/common-properties.md` | ①「结算阶段」流程图把「记入 pastEvent」移进 `eventEnd` 的那一次 `TryApply`；②`AppliedChange` 不含 `TraceElements`（及 `RngElements` —— 取 🔴-1 裁决）的不变式；③（取 🔴-2 裁决）累加进 `AppliedChange` 的列剔除清单；④「写入点不新增」段落把「经 ProfileManager 写入」具体化为 `TraceElements` 列；⑤（取 🟠-2 裁决）`Seq` 条目补写起始值 |
| `systems/character-profile/_index.md` | 字段表三行的「写入通道」列：**15 `pastEvent`** `—（life-cycle 追加）` → `TraceElements`；**17 `activeCombat`** `—（combat-service 回写）` → `EventStateChanges`；**21 `rng`** `—（SeedManager）` → `RngElements`（`CycleSeed` 与子流初始化仍为 `—`，取 🟠-3 裁决）；`activeCombat` 段落顺带回链新通道 |

**共享台账（worker 不写，交 orchestrator 代笔）：**

- `open-questions/05-service-contracts.md` —— **删 3 条**：「`activeCombat` 的写入通道未明写」「RNG 状态的写入通道形态未定」「`pastEvent` 的追加同样没有 `ProfileChangeSpec` 列」。
- `open-questions/02-event-options.md` —— **删 1 条**：「收口时的只读投影设施形态」。
- `answer-logs/log-profile-change-spec-gaps.md`（`draftSuffix` = `profile-change-spec-gaps`）—— 移出 4 条 + interview 新答定项。
- `answer-logs/_index.md` 追加一行台账；`open-questions/update-log.md` 顶部追加本次摘要；`handoffs/_index.md` 新增 handoff 行；`inbox/_index.md` 待处理 → 已归档。
- 新 handoff：建议 `handoffs/2026-08-19-profile-change-spec-carrier-gaps.md`（本 worker 未创建）。

---

## 越界发现

1. **`ProfileChangeSpec` 列面在本批被四份草稿同时改写。** 本片 `RngElements` + `TraceElements`；`solution-draft-codex-entry-schema.md` 的 `CodexElements`；`solution-draft-game-setting-schema.md` 的 `SettingChanges`。**四份必须单批收口、共用同一次 `schemaVersion` bump**（草稿已裁）。orchestrator 须把 `systems/architecture.md`「共享核心类型」与 `systems/services/profile-service.md` 的**列清单 / 失败语义表**当作单写者文件串行处理，不得并行分派。
2. **`systems/architecture.md` 有四份草稿的写入面重叠**：本片（共享核心类型 + 三级判据第六面 + 总则 8 流程图）、`solution-draft-architecture-structural-residuals.md`（待决问题三条残留 + ViewModel 文档落位）、`solution-draft-costkey-statkey-registry.md`（`CostKey` / `StatKey` 枚举 + `ResourceElements` 注释块）、`solution-draft-game-setting-schema.md`（共享核心类型）。**建议串行，且本片的「三级判据第六面措辞补全」应排在最前**——codex / game-setting 两片的分列结论很可能依赖同一条判据的措辞。
3. **`systems/services/profile-service.md` 有六份草稿的写入面重叠**（本片 + bundle-grant-ordinal + codex + costkey-statkey + game-setting + pickmany），其中**施加失败语义表**是同一张表，四份都要往里加行。必须单写者。
4. **`systems/character-profile/_index.md` 与 `solution-draft-costkey-statkey-registry.md` 重叠**：本片改字段表第 15 / 17 / 21 行的写入通道列，该片改「两张字段表的写入通道列」。同一张表，须串行。
5. `systems/services/life-cycle-service.md` / `combat-service.md` / `systems/adventure-event/common-properties.md` **本批仅本片写入**（据各草稿 frontmatter 的 `targets`），可与其余分片并行。
6. 本片**不触及** `.claude/` 与后端库；无跨库承接项。
