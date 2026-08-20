# report — profile-change-spec-gaps

> worker 自身写入本文件被 harness 拦截，报告由 orchestrator 代为落盘。

- library: `game-design-documents`
- file: `game-design-documents/inbox/solution-draft-profile-change-spec-gaps.md`
- 依据构成：**既有推演 9 · 通行做法 0 · 取向选择 5**
- 覆盖：`05-service-contracts.md` 三条 + `02-event-options.md` 一条；同名条目另登记在 `profile-service.md`（3 条）与 `life-cycle-service.md`（2 条）。

## 建议要点

- **`activeCombat` → 收进既有 `EventStateChanges`，不另开列。** 按三级判据 ① 六面逐面核对与 `EventStateChanges` **全部对齐** ⇒ 判据明文要求不分列。`EventStateKey` 追加成员 `ActiveCombat`，`EventStateAssignment` 加第三个具名可空载荷格；`ActiveCombat` 与 `ActiveEvent` 同档允许置空（`EventOption` 不许置空原样保留）。写入方 = combat-service，D0–D5 每决策点一次 `TryApply`，D6 并入 `eventEnd`。
- **RNG 子流状态 → 另开一列 `RngElements`**（`RngStateAssignment(RngStream Stream, ulong State, int DrawCount)`，按子流键绝对置值 upsert）。分列依据：第六面与既有各列均不对齐（多键 upsert vs 固定键整块置值；枚举键 vs 内容 `Id` 键）。**不配表**；`Seed` 不进 spec（可重算）。机械保证 = `SeedManager.AttachRngState(spec)` 单点组装 + `#if DEBUG` 清账断言。**否决「`TryApply` 自动捕获」**（要求 profile-service 反向读 life-cycle-service，且 `AppliedChange` 重放不出 `State`）。
- **连带（改既有 schema）：`ActiveCombat.rng` 与 `Rng.Stream[Combat]` 是同一条子流的二份真值**，而 `common-properties.md` 已明写「战斗内随机不在 `combat` 子流上再派生一层」⇒ 建议删 `ActiveCombat.rng` 三格。
- **`pastEvent` 追加 → 另开一列 `TraceElements`**（`IReadOnlyList<PastEventEntry>`，序列尾部只追加）。分列依据：**不幂等**（第四面）+ 序列尾部追加大结构块（第六面）。建议**直接复用 `PastEventEntry` 不建镜像**。新增不变式：**`AppliedChange` 恒不含 `TraceElements` / `RngElements`**（防自指），落为入口断言。
- **直接收益：「记入 pastEvent」并入收口那一次 `TryApply`**，三份流程图里画在事务外的那一步消失；`Aborted` 那一路由失败流程一次提交承载「痕迹 + 清 `activeEvent`」，不新增存档点。
- **`Project` = `Evaluate` 的第三个门面，三者共用唯一一段施加代码。** `TryApply = Evaluate + 提交/广播/存档点`，`Project = Evaluate 取投影`，`CanAfford = Evaluate 取 Ok`；签名 `bool TryProject(spec, out PlayerProfile projected)`。
- **投影做钳制，不做终态判定。** 钳制：截断本就发生在「施加到 Profile 字段」那一刻，不做即两段代码分叉。终态判定本就不在 `Evaluate` 内。**「已判负」的投影照常重算、照常提交**。
- **投影是一次性值**：不缓存、不存字段、不跨 `await` 持有；机械保证 = 视图带投影时刻的 `commitOrdinal`，跨提交读取 `#if DEBUG` `PushError`。
- **收口组装顺序（四条问题在此咬合）：** ① 组装含 `TraceElements` 的收口 spec（`LifeSpanAfter` 由「前值 + 本次账」纯函数算出并钳制）→ ② `Project(spec)` → ③ `RefreshAfterEvent(投影)`（消耗 map 子流）→ ④ **只补两列**（`EventStateChanges[EventOption = 新一批]` 与 `RngElements`）→ ⑤ 一次 `TryApply`。**新增承重纪律「闭合性条件」：`Project` 之后只允许追加不构成重算依据的列**，落为 `#if DEBUG` 列指纹断言。**`PastEventEntry` 必须在投影之前进入 spec** —— 今天把痕迹画在事务外，等于新一批依据一份**少一条**的历程，这是当前缺口最实际的后果。
- **存档 schema：除 `ActiveCombat.rng` 收敛项外零字段变动、零迁移。**

## 台账行

```
| `solution-draft-profile-change-spec-gaps.md` | awaiting-review | `ProfileChangeSpec` 三处载体缺口（`activeCombat` → `EventStateChanges` · RNG → 新列 `RngElements` · `pastEvent` → 新列 `TraceElements`）+ `Project(spec)` 语义面（与 `Evaluate` 同一段施加代码 · 做钳制不判终态 · 一次性值）。评审 5 项取向后 `/analyze-new-ideas` |
```

## 仍需用户决定（结构化）

### ① RNG 状态的通道形态（承重 · 阻断落地形状）
- **A · 另开 `RngElements` 列（推荐）** → +1 列；不变式获机械保证；`AppliedChange` 带 RNG 终态可完整重放。
- **B · 收进 `EventStateChanges`** → 一次提交常需更新多条子流，撞承重校验「同批两条同 `Key` → 整批拒绝」；要么放松它，要么每次整块重写四条子流（让账说谎、重放时覆盖）。
- **C · 维持现状** → 不变式永远只是约定；`AppliedChange` 重放不出 `State`。
- 理由：三级判据 ① 第六面不对齐 ⇒ 判据要求分列；且它是唯一能让「忘了带 RNG」被机械检出的形态。

### ② `ActiveCombat.rng` 是否收敛到 `Rng.Stream[Combat]`（承重 · 改既有 schema）
- **A · 收敛（删三格）（推荐）** → 二份真值消失；改一份已定稿 schema（无线上存档 ⇒ 空迁移）。
- **B · 保留两处 + 写回规则** → schema 不动，但相等关系只能靠约定——与本轮四条同一种病。

### ③ `TraceElements` 的载荷类型
- **A · 直接复用 `PastEventEntry`（推荐）** → 零镜像维护。
- **B · 建镜像** → 与 `PlotKeyPointAssignment` 先例对称，但 13 字段镜像 = 两张须同步增删的字段表，而快照判据明写字段表还会增长。

### ④ 投影判负时的处置
- **A · 照常重算、照常提交（推荐）** → 白算一批（纯内存），随失败流程拆解，无后果。
- **B · 短路 + 置空 `eventOption`** → 须把「`Key == EventOption` 置空 → `PushError`」改为条件合法，并新增第三处终态判定。

### ⑤ `ActiveCombat.EventInstanceId` 一致性校验的落点
- **A · `ProfileManager` 入口 `PushError` + 整批拒绝（推荐）** → 与读档校验两侧口径一致；与「`PlotElements` 拓扑校验不在本入口」略有张力。
- **B · combat-service `#if DEBUG` 断言** → 分层更纯，但读档侧 `PushError`、施加侧只在 Debug 生效，会造出唯一一处反向不对称。

## 前置依赖
- `CostKey` 资源 element 清单 —— 不阻塞、也不被阻塞；本方案不新增任何 `CostKey` 成员。
- `EventOutcomeSpec` 内部字段面 —— 不阻塞。
- 战斗之外四类事件的决策点清单 —— 不阻塞第 1 节。
- `Project` 的第二个消费点 —— 目前恒为一个；「一次性值」纪律在单消费点下代价为零。

## 与既有决策的张力
1. **三级判据第六面措辞需一句澄清（承重 · 必须与取向 ① 一并裁决）。** 按字面 `RngElements` 与 `PlotElements` 六面**全部对齐**（都是「带载荷的键值 upsert」），判据会推出「把 RNG 塞进 `PlotElements`」这个荒谬结论。建议补：「形状包含**键的取值空间**（内容 `Id` / 固定枚举 / 无键的序列位置）与**载荷的字段集合**」。**不改它，取向 ① 的 A 就没有判据支撑。**
2. `AppliedChange` 恒不含两列 —— 对「复用 `ProfileChangeSpec` 不引入新类型」的一处收窄。
3. 入口做 `EventInstanceId` 一致性校验与「拓扑校验不在本入口」略有张力（= 取向 ⑤）。
4. `ActiveCombat.rng` 收敛推翻一份已定稿 schema 的三格（= 取向 ②）。
5. **三份结算流程图必须同改**（`architecture.md` · `adventure-event/common-properties.md` · `life-cycle-service.md`），把「记入 pastEvent」移入事务内。**这是 `/analyze-new-ideas` 落笔时最容易漏的一处。**

## 越界发现
1. **与 W3 的交叉点：本方案对 `CostKey`/`StatKey` 成员枚举无任何隐含要求，不新增任何成员。** 唯一需核对：`ApplyResult.MissingElement` 类型仍是 `CostKey`、语义「只对资源列有意义」不受两条新列影响 —— 若对侧提议泛化它，须一并复核。
2. `inbox/_index.md` 表头（三列）与 SKILL 第 6b 步（五列）不一致。
3. **一条尚未登记进任何待答清单的同类缺口。** 消掉三行后，剩余「写入通道 = `—`」的例外面是 `status` / `defeatReason` / `realm` / `level` / `chapter` / `chapterRetry` / `lastContentVersion` —— **它们仍由 life-cycle-service 直接赋值，形状与本轮三条完全相同（有纪律、无通道），却不在任何清单里**。建议记一条新待答项。
4. `EventStateAssignment` 变四字段后，「双字段单列表的浪费是每条一个空引用」这句既有辩护的量级变为「每条两个空引用」。当前仍近零；日后再加第四个事件态字段需复核。
