# Phase A — costkey

输入：`game-design-documents/inbox/solution-draft-costkey-statkey-registry.md`（`status: decided`）
目标库：`game-design-documents/`（用户显式给定）
校验基准（已逐字读原文）：`systems/architecture.md`（共享核心类型 322–452）· `systems/services/profile-service.md`（全文）· `systems/player-profile/_index.md`(全文) · `systems/character-profile/_index.md`(1–120) · `systems/services/sync-service.md`（枚举名序列化 / 透明路径 / 体积估算）· `open-questions.md` · `open-questions/01-combat.md` · `terminology.md` · `README.md` · `handoffs/_TEMPLATE.md` · `.claude/rules/*`（Context / data-resource / state-save）· 同批 `inbox/solution-draft-bundle-grant-ordinal-authority.md`、`inbox/solution-draft-profile-change-spec-gaps.md`（仅做跨草稿核对，不处理）

## 一句话摘要

把 `CostKey` 资源族按两张已定案字段表**反向穷举**闭合为 15 个成员（轮回层 7 + `PlayerPowerFragment` 7 + `PlayerEntitlement` 1），顺带补上 `LastRoll` / `LastEffectiveChance` 两处真实缺口；`StatKey` 保持首批两项但成员名与字段名逐字对齐（`TotalCycles*`），两族靠「词缀规则 + 有无配表 + 失败口径」三条可机械核对的分野彼此隔离，不建 `StatFields` 配表、不加 `ElementSpec` 第七列。

## 已定案项（用户已裁决，不进 interview）

- **改名 1：`CostKey.Experience` → `ExperiencePoint`**（裁决 1 · 取 A）。落点已穷举完毕，全库仅 4 处：`architecture.md:377`（注释块）· `architecture.md:395`（枚举）· `profile-service.md:123`（表行）· `character-profile/_index.md:48`（写入通道列）。`terminology.md:53` 登记的是**字段名** `experiencePoint`、不含枚举名 ⇒ **无需改术语表**。
- **改名 2：`PowerFragmentWinOrdinal` → `PowerFragmentFinaleWinOrdinal`**（裁决 1 · 取 A）。落点：`profile-service.md:127`（表行）+ `profile-service.md:36`（首批具名 element 的散文 bullet）+ 新写进 `architecture.md` 枚举。
- **改名 3：`StatKey.CyclesCompleted / CyclesDefeated` → `TotalCyclesCompleted / TotalCyclesDefeated`**（裁决 2 · 取 A）。落点：`architecture.md:407`。**`PlayerStatistics` 的字段本就已是 `TotalCycles*`**（`player-profile/_index.md:77-78`）⇒ 本次改的只有枚举成员名，字段侧零改动，改后即逐字对齐。
- **裁决 3 已消解：`BundleGrantOrdinal` 不登记为 `CostKey` 成员**，账号层第 8 个成员换为 `BundleRedeemedOrdinal`（`AllowedOps = Set`、两修正列 `null`），**总数仍 15**。与同批 `solution-draft-bundle-grant-ordinal-authority.md`（其裁决段第 219 行 + 表行第 164 行给出完整六列 `0 / 无 / 无 / null / null / Set`）**逐字一致，无残留分歧**。
- **裁决 4：`ElementSpec` 保持六列，不加 `TargetPath`**；key 名 ⟸ 字段路径的对齐规则停在纪律阶梯第 4 级（评审）。退让位（成员数长到 30+ 时再议）照录。
- **跨草稿裁决：`ProfileChangeSpec` 由 7 列推到 11 列已接受**，四份草稿**单批收口、共用同一次 `schemaVersion` bump**。本方案不新增列、不给 `ChangeElement` 加字段——已核对 `solution-draft-profile-change-spec-gaps.md:263-264`，`Elements` / `ChangeElement(CostKey, int BaseValue, ApplyOp Op)` 形状确实原样保留，**跨方案假定成立**。
- **非取向项：补 `PowerFragmentLastRoll` / `PowerFragmentLastEffectiveChance` 两行**。已核实这确是两份已定案文档之间的真实不一致，非新设计：`player-profile/_index.md:95-96` 两字段只读、:98-100 明写「每一次 Finale 胜利都掷并写 `LastRoll`」「首胜写 `LastEffectiveChance = 10000`」「缺任一条即触发后端风控误报」，而 `profile-service.md:117-129` 的 `ResourceElements` 表无对应行，:72 又规定「无行 = `PushError` + 整批拒绝」⇒ 按字面那次 Finale 收口的 `TryApply` 会被自己拒绝。取值域 `[0,9999]` / `[0,10000]` 直接抄自字段表，非发明。

## 🔴 冲突

**无。**

逐项核对结论（供 orchestrator 复核）：与 `ResourceElements` 五列判据、两层通则、三级判据（分列 / 加 `Op` / 配表加列）、纪律阶梯、命名硬约定、`Op == Set` 恒不经 pipeline、`Set` 行两修正列恒 `null` 的启动期断言、枚举名逐字序列化通则、具名字段而非字典——**全部一致，未要求任何一条松动**。穷举结果与既有 7 个已声明成员**逐一对应、无缺无余**（`character-profile/_index.md:26` 的 `jade` + :46-51 的 `Status` 前六格），`PlayerPowerFragment` 确为 7 字段（`player-profile/_index.md:92-96`），账号层写入通道确写作 `Elements`（同文件 :25）。数据流、RNG、`AllEnabled()`、云端权威、竖屏诸条均不触及。

## 🟠 含糊

### 🟠-1（阻断度：高 — 决定三个**永久冻结**的契约名）三个首胜 key 是否带 `Done` 后缀

- 草稿正文（§二.2 表 · §具体形态 枚举 · `ResourceElements` 新增行）一律写 `PowerFragmentCh1FirstWin` / `Ch2` / `Ch3`；但标的字段是 `Ch1FirstWinDone` / `Ch2FirstWinDone` / `Ch3FirstWinDone`（`player-profile/_index.md:94`）。
- 与草稿自己的两条规则相抵：§四.3「key 名 = 标的字段可辨识路径的 PascalCase 拼接」只给了「**是否加容器前缀**」这一处判断余地，**没有给「截掉字段名尾部」的余地**；而 §二.1 改名 `Experience → ExperiencePoint` 的**全部理由**正是「它是全表唯一名不对齐的行，对齐后规则才**无例外**，而无例外正是可机械检查的前提」。按草稿正文落笔，规则开张当天就有三个例外。
- 裁决 1 只点名了两处改名，**未涉及这三个成员的形态**；`profile-service.md:128` 现记的是带参伪形态 `PowerFragmentFirstWin(chapter)`，无既有权威可直接照抄。
- 选项：
  - **(a) `PowerFragmentCh1FirstWinDone` / `Ch2` / `Ch3`** — 后果：`architecture.md` 枚举 + `ResourceElements` 三行用带 `Done` 的名；§四.3 的对齐规则当前**零例外**，与裁决 1 的立论一致；代价是成员名较长（26 字符）。
  - **(b) `PowerFragmentCh1FirstWin` / `Ch2` / `Ch3`（草稿正文原样）** — 后果：名字短、读起来更像「首胜这件事」；但 §四.3 需追加一句例外条款（「布尔字段可省略 `Done` 后缀」），且这三个名与 `TotalCycles*` / `ExperiencePoint` 的严格对齐口径并存，日后新增布尔型 key 时「省不省」重新要读上下文。
- **推荐：(a)**。依据：裁决 1 已认定「一条约定一旦开例外就从『可机械检查』降级为『要读上下文』」，并为此接受了一次改名；在同一份方案里给同一条规则一次性开三个例外，与该裁决的承重理由直接相抵。且成员名按 `sync-service.md:180` 的通则**落存档与上行契约、只可追加永不改名**，此刻选错的窗口在写下第一批存档时关闭。

### 🟠-2（阻断度：中 — 改动一句承重判据的措辞，且该措辞有两份副本）`Elements` 的「资源是量」概括是否改写

- 草稿 `## 与既有决策的张力` 第 1 条主张：三个 0/1 首胜标记**无量纲、不可加**，与既有概括「资源是量（可加、要钳制、按表决定是否走 pipeline）」有轻微张力；**建议顺手把概括改写**为「资源是**标量值**：可钳制、`Add` 时可加且带符号分向、`Set` 时为已算好的绝对值」，否则日后读者会拿原句当作「首胜标记放错了列」的依据。草稿自评这是**措辞层**改动、非决策层松动（六面判据仍成立于五面，「只差一面不足以分列」）。
- 该概括在库中有**两份副本**：`architecture.md:436`（承重判据段「为什么逐条按施加语义分列」）与 `profile-service.md:37`（`ProfileChangeSpec` 各列的散文列举）。用户未就此裁决。
- 选项：
  - **(a) 两处同改** — 后果：两份副本口径一致，「首胜标记放错列」的误读源被封死；代价是动了 `architecture.md` 一段承重判据的措辞（判据本身不变，只换概括词）。
  - **(b) 一处都不改，改为在 `ResourceElements` 三个首胜行的「依据」列里写清「0/1 无量纲承载，已按六面判据核对，不另开 `FlagChanges`」** — 后果：承重段一字不动，风险点就近说明；代价是原概括仍在两处摆着，读者先读到的是它。
  - **(c) 只改 `architecture.md`** — 后果：留下 `profile-service.md:37` 一份未改的旧概括，正是要防的那个误读源仍在。
- **推荐：(a)**，并**同时**执行 (b) 的依据列说明。依据：这句话有两份副本是既有事实，只改一份必然产生「两份表各自漂移而无机制发现」——正是本库 `content/` 硬边界那条纪律点名的坑；而否决 `FlagChanges` 的六面核对结论必须落在配表行上，否则它只活在被归档的草稿里。**(c) 明确不推荐。**

## 🔵 可推演（无需回答）

- **穷举法闭合性成立。** `CharacterProfile` 23 字段 + `Status` 12 格中标注 `Elements` 的恰为 `jade` + `Status` 前六格 = 7，与 `architecture.md:394-395` 已声明的 7 个成员双向满射；`PlayerProfile` 15 字段中标 `Elements` 的是第 13、14 行。7 + 7 + 1 = 15 闭合。（依据：两张字段表原文）
- **三处未决通道不阻塞本清单。** `pastEvent` / `activeCombat` / `rng` 按 `architecture.md:430` 的六面判据与 `EventStateChanges` 对齐、与 `Elements` 不对齐（无量纲 · 不钳制 · 不构成终态 · 恒不走 pipeline）；六个 Codex / `achievement` / `gameSetting` 是集合成员增补。**它们要的是一列，不是一个 key** ⇒ 不会往资源族加成员。已与同批 `solution-draft-profile-change-spec-gaps.md` 交叉验证：它给三者开的正是 `RngElements` / `TraceElements` 新列，而非新 `CostKey`。（依据：`architecture.md`「三级判据」）
- **`BundleRedeemedOrdinal` 的六列无残留含糊**，直接取同批 bundle 草稿第 164 行：`0 / 无 / 无 / null / null / Set`；词缀合规（`Ordinal` ⇒ 规则字段层，`CostKey` 允许）；key 名 ⟸ 字段名自明、不需容器前缀（与 `BundleGrantOrdinal` 同款判断）。
- **草稿一处算术口误，落笔时改掉、不需裁决：** §二.2 末段写「含 `Set` 的**五**行因此自动满足既有断言」——`PowerFragmentAccumulated` 的 `AllowedOps = Add | Set` 也含 `Set`，实为**六**行。结论不受影响（该 7 行两修正列一律 `null`），建议直接写成「这 7 行两个修正列一律 `null`，故含 `Set` 的各行自动满足断言」。
- **`sync-service.md:63`「估算随『`CostKey` 的 element 清单』答定需复核」的指针在本次后失去referent**，随手中性化即可（清单已闭合于 15）。**不在本次做任何体积数值复核**——那是体积 / 平衡口径的事，本草稿未提供也无人要求。
- **本次不跨库。** `LastRoll` / `LastEffectiveChance` 的 JSON path `/playerPowerFragment/lastRoll` · `/lastEffectiveChance` 已是既有透明路径（`player-profile/_index.md:101` 明写），后端复算口径不变；本方案只定客户端**怎么写**。（`BundleRedeemedOrdinal` 确实需要后端承接，但那是 bundle 分片的跨库义务，不在本分片。）
- **五步 / 三步登记清单的落点**：资源族五步 → `profile-service.md`「可加性」那条 bullet（:164，草稿明写要兑现它）；统计族三步 + 双向覆盖断言 + 不建 `StatFields` 的理由 → `player-profile/_index.md` 的 `PlayerStatistics` 小节；两条新断言与冻结纪律 → `profile-service.md` 既有断言群（:134 / :135 / :143）之后。
- **绝不写 `open-questions.md` 的「derive 就绪度」小节。** 草稿 `## 后果` 点名「全局结论『🟠 半处』中的这一半可移出」，但该小节由 `/assess-derive-readiness` **独占写入**（技能第 10 步 + `README.md:37`）。本次一并**不在任何主题文档里写「可 derive / 已解锁 derive」**；报告中也不给就绪度结论。
- **不建 ADR、不动 `decisions/`**（技能第 6 步：ADR 立档归 `/write-adr`）。本次也不推翻任何既有 ADR。
- 术语表无需改动（见「已定案项」第 1 条）。

## 拟改动文档清单与各自新增要点

| 文档 | 新增/修改要点（供跨草稿核对） |
|---|---|
| `systems/architecture.md`（共享核心类型 · 322–452） | ① `CostKey` 枚举由 7 → **15 成员**（含 `ExperiencePoint` 改名、7 个 `PowerFragment*`、`BundleRedeemedOrdinal`），去掉 `⟨待定：其余 element 清单⟩` 占位；② `StatKey` 两成员改名为 `TotalCycles*`，去掉 `⟨待定⟩` 占位；③ `ResourceElements` 注释块（:373-380）改 `Experience` 一行、补 8 行、删「⟨其余随…逐条补⟩」；④ 加一句「成员**序**不构成契约、成员**名**构成契约，只可追加」；⑤ **🟠-2 待裁**：:436 的「资源是量」概括是否改写为「标量值…」 |
| `systems/services/profile-service.md` | ① `ResourceElements` 表（:117-129）：`Experience`→`ExperiencePoint`、`PowerFragmentWinOrdinal`→`PowerFragmentFinaleWinOrdinal`、`PowerFragmentFirstWin(chapter)` 一行**拆成三具名行并填死 Min/Max = 0/1**、**新增** `PowerFragmentLastRoll` `[0,9999]` 与 `PowerFragmentLastEffectiveChance` `[0,10000]`（均 `Set` · 两修正列 `null`）；② 删 :131 悬挂句「末三行随各自的 `CostKey` 成员登记时同步生效」（清单已闭合）；③ :36 散文 bullet 的两处旧名改写；④ 新增两条启动期断言（`StatKey` ↔ `PlayerStatistics` 双向覆盖 · 两枚举词缀合规）+ 一条冻结纪律（只可追加、永不改名/复用）+ 「不给两枚举分配整数 code」的一句；⑤ :164「可加性」补五步清单；⑥ **待决问题移出两条**：「cost element 清单未定」(:243)、「`StatKey` 完整成员清单未定」(:244)；⑦ **🟠-2 若取 (a)**：:37 的列语义概括同步改写 |
| `systems/player-profile/_index.md` | ① 字段表第 13 行写入通道由 `Elements` 细化为「`Elements`（7 个 `CostKey`）」；② `PlayerStatistics` 小节补：`StatKey` 成员名 = 字段名逐字、三步登记、**明确不建 `StatFields` 配表**（六列逐列为空）、双向覆盖断言、未知 `StatKey` 宽松口径照旧；③ 补「元素键的分野 = 字段分层的投影」一句（`CostKey` = 规则字段层的键，`StatKey` = 统计计数层的键）+ 词缀规则由字段名扩到元素键名的表；④ **待决问题移出一条**：:171「`StatKey` 的完整成员清单未定」 |
| `systems/character-profile/_index.md` | `Status` 子表 :48 写入通道 `CostKey.Experience` → `CostKey.ExperiencePoint`（**全文唯一改动**） |
| `systems/services/sync-service.md` | ① 枚举名冻结纪律处（:180）补一处引用：`CostKey` / `StatKey` 随 `ProfileChangeSpec` 落 `PastEventEntry.SelectCost` / `AppliedChange`，同受「枚举名逐字序列化 ⇒ 改名即破坏性契约变更」；② :63「随 `CostKey` element 清单答定需复核」中性化（不做数值复核） |
| **新建** `handoffs/2026-08-19-costkey-statkey-registry.md` | Intent（15 + 2 成员清单 · 三条分野规则 · 五步/三步登记 · 七条校验闸表）+ Clarifications（🟠-1 / 🟠-2 的用户裁决）+ Open questions（应为空或仅剩远期未知） |
| **不改**（明确记录） | `terminology.md`（登记的是字段名）· `decisions/*`（不立 ADR、不推翻）· `open-questions.md` 的「derive 就绪度」小节（`/assess-derive-readiness` 独占）· `backend-design-documents/*`（本分片不跨库） |

### 交回 orchestrator 代笔的台账行（worker 不写）

- `handoffs/_index.md` 置顶新行：`2026-08-19-costkey-statkey-registry | 2026-08-19 | systems/architecture.md · systems/services/profile-service.md · systems/player-profile/_index.md · systems/character-profile/_index.md · systems/services/sync-service.md | distilled | <同左>`
- `open-questions/01-combat.md`：**删除** :16「`StatKey` 的完整成员清单（08-10c 新增 · 轻）」整条。
- `answer-logs/log-costkey-statkey-registry.md`（新建）：移出 **2** 条 —— ①「`CostKey` 资源族 element 清单」→ 闭合为 15 成员（归档去向 `systems/architecture.md` + `systems/services/profile-service.md`）；②「`StatKey` 完整成员清单与登记方式 / 与 `CostKey` 的书写分野」→ 首批两项改名对齐 + 三步登记 + 三条分野规则（归档去向 `systems/player-profile/_index.md`）。
- `answer-logs/_index.md` 追加：`log-costkey-statkey-registry.md | 2026-08-19 | inbox/solution-draft-costkey-statkey-registry.md | 2`
- `inbox/_index.md`：待处理表删 :28 行；已归档表补 `solution-draft-costkey-statkey-registry.md | solution-draft | 2026-08-19 | handoffs/2026-08-19-costkey-statkey-registry.md | log-costkey-statkey-registry.md`
- `open-questions/update-log.md` 顶部本次摘要（与其余分片合并成一条）。
- 草稿归档：front matter 补 `reviewed:` 与 `distilled-to:`，`status: decided → distilled`，`git mv` 进 `inbox/archive/`。

## 越界发现

**⚠ 跨分片写入面冲突（高优先 — 铁律 ③ 的直接命中项）。** 本分片与同批至少三份草稿写**同一批文件**，绝不可并行落笔：

| 文件 | 争用分片 | 具体撞点 |
|---|---|---|
| `systems/services/profile-service.md` · `ResourceElements` 表 | **costkey** · bundle-grant · spec-gaps | costkey 改 1 行 / 增 4 行（Fragment 侧）；bundle **删** `BundleGrantOrdinal` 行、**增** `BundleRedeemedOrdinal` 行；spec-gaps 改同文档的失败语义表与列清单 |
| `systems/architecture.md` · 共享核心类型 | **costkey** · spec-gaps（+ codex / game-setting 若开新列） | costkey 改两个枚举与 `ResourceElements` 注释块；spec-gaps 把 `ProfileChangeSpec` 由 7 列推到 11 列（:263-271）——**同一个代码块** |
| `systems/player-profile/_index.md` · 字段表 | **costkey**(行13) · bundle(行14 + `PlayerEntitlement` 类) · codex(行6-11) · game-setting(行15) | 四份各改自己那几行，但表体是同一块 |
| `systems/character-profile/_index.md` | **costkey**（Status 子表 1 格） · spec-gaps（行 15/17/21 的写入通道列） | 同一张表 |
| `systems/services/sync-service.md` | **costkey** · bundle · spec-gaps | 三份都要碰 schema bump / 冻结纪律段 |

**建议：** 把这几份合并给同一个 Phase B worker，或严格串行成波次（推荐序：`spec-gaps`（先定 11 列骨架）→ `bundle`（撤 `BundleGrantOrdinal` 行）→ **`costkey`**（在既定骨架上填 15 成员）→ `codex` / `game-setting`）。**理由：costkey 的 15 成员表依赖 bundle 已撤下的那一行，而 §二.4 归宿表要补的三行依赖 spec-gaps 的新列名。**

**⚠ 单批共用一次 `schemaVersion` bump 的硬要求。** 四份草稿都写「bump 一次、空迁移」。若各自落笔，`sync-service.md` / `profile-service.md` 会出现四句互相独立的 bump 表述。**建议由 orchestrator 收尾统一写一句**，各分片只回链。

**不处理的相邻问题（记录，不动手）：**
- `profile-service.md:80` 整条 bullet「具名 element `BundleGrantOrdinal`：置值语义，表中两个修正列均为空（承重）」在 bundle 草稿采纳后即整条失效 —— 归 **bundle 分片**的写入面。
- `player-profile/_index.md:26` 第 14 行写入通道「`Elements`（`BundleGrantOrdinal` 置值）」同上，归 bundle 分片。
- `profile-service.md` 待决问题里的 `activeCombat` / RNG / `pastEvent` / `Project(spec)` 四条 —— 归 **spec-gaps 分片**；本方案已论证它们不阻塞资源族闭合，但**不代本分片移出**。
- §二.4 归宿表的「⟨待定⟩」三行（六个 Codex / `achievement` / `gameSetting`）与「未明写」三行（`pastEvent` / `activeCombat` / `rng`）—— 本分片按草稿原样保留「形状上不是资源族」的论证，**不去填它们最终的列名**（那是 codex / game-setting / spec-gaps 分片的结论）。orchestrator 收尾时若三者已定，可统一把归宿表的列名补齐。
