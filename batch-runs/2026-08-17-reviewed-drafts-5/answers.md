# 合并 interview 裁决 — 2026-08-17 批（5 份客户端草稿 + 1 份后端 counterpart）

> 本文件是用户当面裁决的记录。**Phase B worker 视同用户答复，优先级高于草稿原文与本 worker 自己的 Phase A 推荐。**
> 28 问分 7 轮问齐，用户逐题选择，全部取推荐项。**这是用户拍板，不是「按推荐来」的授权**——除草稿评审阶段已标的 `[采纳推荐 — 待复核]` 项外，不另加待复核标记。

## 范围裁决

**R-01 · 后端 counterpart 纳入本批。** 新增后端分片 F，写 `backend-design-documents/contracts/profile-sync.md`（§5 白名单改名 + §7 字段引用 + 命名通则 + `schemaVersion` bump）。两侧同批落笔，对称回链。

## 逐条裁决

### 分片 A（两层 Profile 字段 schema）

- **A-R1 单数通则的适用边界 = 两层 Profile 及其子对象的存档字段名。** `rng.streams → rng.stream` 同批改（零迁移）；`characterDiffs` / `playerDiff` 属 diff 报文结构，**不动**；`EventOptionBatch.Options` / `PlotNodeData.CharacterIds` 等运行时与内容侧属性**不受约束**。
- **A-R2 条目键名同批收口为 `powerId` / `itemId`。** 四类持有条目命名全族一致（`CharacterItem.ItemId` / `CharacterPower.PowerId` / `PlayerItem.ItemId` / `PlayerPower.PowerId`）。对侧 §5 两行 + §7 字段引用随之改名；**算法与 §6a 的 8 组测试向量一字不动**。
- **A-O1 rng schema 片段一并改为 camelCase：`CycleSeed → cycleSeed`、`streams → stream`。**
- **A-O2 `currentMana` 从 `Status` 删除，并连带修正 combat-service 的错话**：括注改写为「`manaLimit` 战斗内不变，落它只为读档自洽；`currentMana` 是回合内消耗量，决策点存档必须恢复它」。
- **A-O3 `CostKey` 三行本批一次写完**：`Experience → (0, null, null, null, null, Add)`；`Faith` / `MaleficQi → (0, 100, null, null, null, Add)`（两个修正列留空——一条法则能伪造隐藏属性即等于伪造整条剧本线的触发条件）。`profile-service.md` 的「道心 / 煞气是否列入 `CostKey`（轻）」待答项随之移出。
  - **单写者：分片 D。** 整张 `ResourceElements` 表（含三个新行的全部六列与新增的第六列）由 D 一次落笔，A **不碰该表**。
- **A-O4 角色集合字段照通则取 `characterProfile`**（不开复数例外、不另起容器名）。

### 分片 B（`EventOption` 物化字段清单）

- **B-R1 不抄草稿的内部形态。** 活文档只写「按结算走向分侧的定稿产出 spec + 固化时点」，内部分解留 `⟨待定：归「效果关键字体系」那次 handoff⟩`。**不写 `int FailureRatio`**，既有 `0.5` 比率口径一字不动。
- **B-O1 不写 `HiddenStatPush` / `ReplacementOffer`** 这两个全库零定义的类型名。
- **B-O2 字段名取 `OutcomeSpec`**（类型仍 `EventOutcomeSpec`），避开与 `PastEventEntry.Outcome` / `Source.EventOutcome` 的三重撞名。
- **B-O3 明写结算映射表**：`CombatWon` / `Resolved → OnResolved`；`CombatLost → OnFailure`；`Draw → OnResolved`（对齐「平：只发 `baseReward`、不扣 `lifeTotal`」）；`Aborted → 两侧皆不施加`。
- **B-O4 明写产出边界**：Combat 类的 `OutcomeSpec` 只承载隐藏属性推拉 + 经验档 + 事件级产出；**战斗战利品恒不进 `OutcomeSpec`**，走 `EncounterSpec.BaseReward` / `RewardPoolId` → `Spoils`。
- **B-O5 删掉「`Priority` 非模板字段」的加载期校验**（不可实现），只保留物化后断言 `Priority ∈ {0,1}` + 文字纪律。`Priority` 保留 `int` 不变。
- **连带：`PlotModulation` 保持六字段**（见 E-R2），B 的「六字段不变」复核结论**原样成立**，不改为五字段。
- **额外裁决：顺手改掉 `decisions/ADR-0002` 尾部的待办**（`combatTier` 字段形态）——改写为已答定的正面陈述：tier 是模板常量，落 `EncounterSpec.Tier`，`EventOption` / `PastEventEntry` 两处都不加。

### 分片 C（派生实例承载与落盘）

- **C-R1 新增只读投影设施，先算后提交。** `profile-service` 明写形如 `Project(spec)` 的**只读投影**（不提交）；life-cycle-service 用它算新一批，再一并放进同一次 `TryApply`。**两条承重纪律都不改写**（「收口是一次事务、一个存档点」与「依更新后的 profile 重算、`pastEvent` 是一等输入」同时保住）。新增一条待答：投影语义与 `Evaluate(spec)` 的复用关系。
- **C-A1 当前批载体可空**：`EventOptionSave? eventOption`，`null` = 尚无批次（`StartCycle` 之前 / 迁移老档）。
- **C-A2 `activeEvent` 与 `SelectCost` 同一次 `TryApply` 创建**；判负短路那一路留下的非 `null` `activeEvent` 由失败流程明写清理。
- **C-A3 提交即本地原子写，只是不新增点位。** 揭示那条措辞校正为「不新增决策点 / 不新增存档点类型，本地写照常发生」；`sync-service.md` 补一句把 commit 与 push 的粒度对位写清。
- **C-A4 全链单数一致**：字段 `eventOption` · 类型 `EventOptionSave` · 枚举成员 `EventStateKey.EventOption`。

### 分片 D（element 层载体缺口）

- **D-O1 三级判据写进 `systems/architecture.md`「共享核心类型」**，形态 = 一段承重正文 + 一张「六面核对」判据卡（六面：要不要钳制 · 是否走 modifier pipeline · 失败是否阻断整批 · 是否幂等 · 有无量纲 · 键与载荷的形状）。含 ② 加 `Op` 与 ③ 配表加列的条件，以及反判据（逐次可变的必须逐条带；唯「谁有权改写它」永远配表）。
- **D-O2 `PlotArcState` 登记进 `architecture.md` 共享核心类型枚举清单**；`plot-manager.md` 与 `character-profile/_index.md` 两处改为回链、不复述。
- **D-O3 `BundleGrantOrdinal` 那一行保留 `AllowedOps = Set`，本批不动 `monetization.md`**；把「该 key 究竟由谁施加」的文档内部不一致登记为一条新待答（归 monetization / sync 专场，可能跨库）。

### 分片 E（抽取原语与物化实例形态）

- **E-R1 维持删除 `LocationData.EnemyTemplateIds`，并明写「叠加而非替代」**：本作不存在地域独占生态，通用敌人恒可在任何地域出现，地域 / arc 专属条目是叠加。须改写 `game-progression.md` 的「硬分池只发生在敌人那一侧」与「location 决定派谁来」两句承重表述、`terminology.md` location 词条（三组字段 → 两组，删「硬框定取池」）、`future-event-service.md` 的「选池」改「框定」。
- **E-R2 推翻第 4 项的「删」——`PlotModulation.EnemyPoolScope` 保留。** 注释改为「可框定任一 arc 的专属池，通常填本 arc 自己的 `Id`」+ 新增加载期悬空校验（非空且不在 `PlotArcData` 仓储 → `PushError`），把「静默换池」变成「大声报错」。**`PlotModulation` 维持六字段**，剧情线 boss 用例保住。
- **E-R3 交叉校验第 4 条降为 `EventType` 单维**（「某 `EventType` 下通用池为空 → 启动期 `PushError`」），并新增待答「敌人池的篇章框定载体未定」。**不臆造 `EnemyData` 的篇章字段。**
- **E-O1 `activeCombat` 的 `enemyRef` = `EnemyInstance.InstanceId`**（指向 `EventOption.Encounter.Enemy`，读档经既有 `eventInstanceId` 反查当前批）。
- **E-O2 保留「嵌套」结论，重写依据 2 + 明写结算期以 `activeEvent` 那一份为权威。** 新依据：嵌套让敌人实例在同一份定稿实例内只有一个落点；跨落点副本由 `activeEvent` 的既定快照语义统一管辖。
- **E-O3 对侧承接 = 确认对齐 + 顺手消歧一句**：后端落一条确认性承接项（两侧无需改动即认为已对齐），并在 `contracts/profile-sync.md` 的客户端伪码行把 `finaleWinOrdinal` 显式标注为「本次（自增后）序号」。

### 分片 F（后端 counterpart，本批新增）

- **F-1 切换时序取 A：线上无真实账号 ⇒ 直接切，不写迁移、不设兼容期。** §5 白名单一次性改名 + `schemaVersion` bump。
- **F-2 残卷 `ordinal` 口径：确认对齐**（§7 已蕴含自增后口径），无需改算法；只做 E-O3 的措辞消歧。
- **F-3 改名范围**（含 A-R2 的收口）：
  - `/playerPowers[*]/id` → `/playerPower[*]/powerId`
  - `/playerPowers[*]/sourceCode` → `/playerPower[*]/sourceCode`
  - `/playerPowers[*]/status`（排除项）→ `/playerPower[*]/status`
  - `/playerItems`（排除项）→ `/playerItem`
  - §5 补一句命名通则「集合字段恒为单数」+ 写明本次成立的三个前提（线上无数据 · 两侧同批 · 一次性不设兼容期）。
  - **`characterDiffs` 不动**（A-R1）。

## 跨草稿核对的落笔约束（编排，非设计裁决）

1. **`ResourceElements` 整张表由分片 D 单写**（含新增第六列 `AllowedOps` 与 `Experience` / `Faith` / `MaleficQi` 三行的全部六列）。A 不碰该表。
2. **`ProfileChangeSpec` 最终 7 列由分片 D 一次写全**（既有 5 列 + `PlotElements` + `EventStateChanges`），同段代码块内的 `ChangeElement` 第三字段与 `ElementSpec` 第六列一并落笔。C 只补 `EventStateChanges` 的语义、类型定义与失败语义行，**不重写该代码块**。
3. **`EventOption` record 11 → 13 格**：B 加 `EventOutcomeSpec OutcomeSpec`，E 加 `EncounterSpec Encounter`（可空）。B 先落，E 后补，**不互相重写**。
4. **`PastEventEntry` 注释「随两项答定后扩充」由 E 最终改写**为「+1 格 `EnemyTraceRef Enemy`」；B 只写自己那一半「本项不带来痕迹侧扩充」，不清掉敌人实例那一半。
5. **`terminology.md`**：D 补 `ProfileChangeSpec` 七列 + `ChangeElement` 第三字段；E 改 location 词条。两者不同段落，按波次串行。
6. **schema bump 合并为同一次**，统一措辞由分片 A 在 `sync-service.md` 落笔，其余分片只把自己的字段清单交给 A（已在各自 Phase A 报告中列出）。
7. **Phase B 全串行五波 + 后端一波**：D → A → B → C → E → F。
