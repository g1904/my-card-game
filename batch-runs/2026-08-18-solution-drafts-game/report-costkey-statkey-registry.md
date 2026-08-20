# report — costkey-statkey-registry

> worker 自身写入本文件被 harness 拦截，报告由 orchestrator 代为落盘。

- library: `game-design-documents`
- file: `game-design-documents/inbox/solution-draft-costkey-statkey-registry.md`
- 依据构成：**既有推演 14 · 通行做法 0 · 取向选择 4**
- 跨库：**否**（两个新 key 的 JSON path 已是既有透明路径，后端复算口径不变）

## 建议要点

- **方法取「反向穷举」而非「列举想得到的资源」**：`CostKey` 成员 = 两张已定案字段表中所有「写入通道 = `Elements`」的格子；闭合判据是该映射双向满射。
- **`CostKey` 建议共 15 个成员**：轮回层 7（`jade` + `Status` 前六格）· 账号层 8（`PlayerPowerFragment` 7 字段 + `BundleGrantOrdinal`）。
- **⚠ 发现两份已定案文档间的真实不一致（承重）：`PlayerPowerFragment.LastRoll` / `LastEffectiveChance` 没有任何 `CostKey`。** `player-profile/_index.md` 明写两条承重写入约定（每次 Finale 胜利必写 `LastRoll`、首胜写 `LastEffectiveChance = 10000`，「缺任一条即在正常账号上触发后端风控误报」），字段表通道标为 `Elements`；但 `ResourceElements` 无行，而缺行 = `PushError` + 整批拒绝 ⇒ **按当前字面，那次 Finale 收口的 `TryApply` 会被自己拒绝**。补两行即闭合，零结构增量。
- **`PowerFragmentFirstWin(chapter)` 的「形态未定」落为三个具名成员**（`PowerFragmentCh1/Ch2/Ch3FirstWin`）：C# `enum` 成员不能带参，参数化必然退化为给 `ChangeElement` 加可空字段（`architecture.md` 已否决的替代之一）；存档侧标的本就是三个具名布尔。
- **布尔以 `int 0/1` 进 `Elements`，`Min=0 / Max=1`**；否决另开 `FlagChanges` 列 —— 三级判据六面核对下它与 `Elements` 五面全对齐，只差「有无量纲」，不足以分列。
- **`StatKey` 不扩充清单**（`PlayerStatistics` 明写「首批就这两项」），只处理形态：建议改名 `TotalCyclesCompleted` / `TotalCyclesDefeated`。
- **明确不给统计族建 `StatFields` 配表**（`ResourceElements` 六列在统计层逐列为空 ⇒ 建全空表，违「按内容建不按对称建」）。替代 = 启动期 `StatKey ↔ PlayerStatistics` **双向覆盖断言**。
- **书写分野三条**：① 一句话判据（「这个数会被规则 / 闸门 / 幂等键读吗」，与两层通则同源）；② **词缀规则**（`StatKey` 必带 `Total` 前缀或 `Count` 后缀；`CostKey` 禁用二者、可带 `Ordinal` / `Used`）⇒ **两枚举成员名空间在构造上不相交**，当前零违例；③ key 名 ⟸ 标的字段路径（约定，非机械规则）。
- **分野的主体保障已在纪律阶梯第 1 级**（两独立 enum × 两独立 record struct × 两独立列表 ⇒ 塞错列写不出来）；词缀规则只防「新增时放错枚举」，第 3 级足够。
- **成员名冻结纪律（新增）**：两键随 `ProfileChangeSpec` 落进 `PastEventEntry.AppliedChange`，按 sync-service 通则以**成员名**序列化 ⇒ 与 `SavePointReason` 同受「重命名 = 破坏性契约变更」。**这给三处改名划出执行窗口：必须在写下第一批存档之前。**
- **不给两键分配整数 code**（`Source` 的名/code 双轨是通则的记名例外）。
- **五步可加性清单**：加字段 + 更新通道列 → 加枚举成员 → 加 `ResourceElements` 一行六列 → bump schema → 含 `Set` 则两修正列留空。

## 台账行

> `inbox/_index.md` 实际表头三列 `文件 | status | 说明`，与技能第 6b 步的五列不同。当前是占位行，需替换。

```
| `solution-draft-costkey-statkey-registry.md` | awaiting-review | `CostKey` 资源族 element 完整清单（15 成员，含新发现的 `LastRoll` / `LastEffectiveChance` 无通道缺口）+ `StatKey` 成员清单与增长登记方式 + 两者的书写分野规则。评审 4 项取向后 `/analyze-new-ideas` |
```

## 仍需用户决定（结构化）

### 决定 1 · `CostKey.Experience` → `ExperiencePoint`（连带 `PowerFragmentWinOrdinal` → `PowerFragmentFinaleWinOrdinal`）
- 15 个成员中两个与标的字段名不逐字对齐，其余 13 个全对齐。是否改名以使「key 名 ⟸ 字段路径」成为无例外规则？
- **A · 改名对齐（推荐）** — 全表逐字对齐、规则无例外；成本此刻为零，**窗口随第一批存档关闭**（按成员名序列化，改名后即破坏性契约变更）。
- **B · 保持现状** — 名字短；对齐规则退化为「大体如此，有两个例外」，此后每加一个成员都要人判断。
- 理由：约定一开例外即从「可机械检查」降级为「要读上下文」；且成本窗口正在关闭。

### 决定 2 · `StatKey` 两项 → `TotalCyclesCompleted` / `TotalCyclesDefeated`
- 既有硬约定「`Total` 前缀 / `Count` 后缀 ⇒ 统计层」是可机械检查的层标记，但 `StatKey.CyclesCompleted` 二者皆无。
- **A · 改名（推荐）** — 「读裸 key 名即知归属」成为真机械规则；双向覆盖断言可按同名匹配写出。
- **B · 保持现状** — 简洁；但裸 key 名无法自证层归属，分野表退化为只对 `CostKey` 单向生效的禁令。
- 改名窗口与决定 1 同时关闭。

### 决定 3 · `FinaleWinOrdinal`(`Add`) 与 `BundleGrantOrdinal`(`Set`) 的 `Op` 不对称
- 两个形状相同的账号级单调序号取了不同 `AllowedOps`，看似遗漏，实则各有成因（残卷序号客户端自增；礼包序号是后端验票后的已算定绝对值，且后端也会写这一格）。
- **A · 保持不对称 + 表内各补一句理由（推荐）** — 零改动，防日后「顺手统一」破坏其中一侧。
- **B · 统一为 `Set`** — `Add` 已被「序号自增即掷骰序列漂移」绑定，改动需重核残卷复算链。
- **C · 统一为 `Add`** — 后端验票时也 `+1` 写这一格，客户端改增量会让两侧写法分叉。

### 决定 4 · 是否给 `ElementSpec` 加第七列 `TargetPath`
- **A · 加列** — 命名对齐成为开发期大声失败（纪律阶梯第 3 级）；每行多一个字符串常量。
- **B · 不加（推荐）** — 表保持六列；写错 key 即写错字段、会被功能测试撞见，而命名不对齐本身不产生运行时错误，**连开发期错误都不是**。
- **翻转条件已写进草稿**：若预期 `CostKey` 成员数长到 30+，A 的性价比翻转。

## 前置依赖
- **无阻塞性前置依赖。** 草稿逐格论证：`activeCombat` / RNG / `pastEvent` 三处未定通道，以及六个 Codex / `achievement` / `gameSetting` 三处 `⟨待定⟩` 通道，**在形状上都不是资源族**（无量纲、不钳制、不构成终态、恒不走 pipeline）⇒ 它们要的是**一列**，不是**一个 key** ⇒ 无论最后落在哪一列都不会往资源族加成员。故资源族清单可独立闭合。
- 弱依赖：若并行的「三处通道」方案主张新开一列，`ProfileChangeSpec` 由 7 列变 8 列 —— 本方案全文**不引用列表数**，仅归宿表需补一行。

## 与既有决策的张力
1. **措辞层 ·「`Elements` 装的是量」 vs 三个 0/1 首胜标记。** 建议把这句改写为「资源是**标量值**：可钳制、`Add` 时可加且带符号分向、`Set` 时为已算好的绝对值」，否则日后读者会拿它当「首胜标记放错了列」的依据。**措辞改动，非决策松动。**
2. 两个序号的 `Op` 不对称（见决定 3），建议明写理由防「顺手统一」。
3. **非张力 · 明确挂起项被填上**：`profile-service.md` 把 `PowerFragmentFirstWin(chapter)` 的 Min 写作「形态未定」并注「归 cost element 清单那一问」——本方案正是在答那一问。

## 越界发现

### A. 假定的 `ProfileChangeSpec` 列结构（供与 W4 / W5 交叉核对）
1. **保留一列 `Elements`，元素类型 `ChangeElement(CostKey Key, int BaseValue, ApplyOp Op)`，三字段不变。** 15 个成员全落这一列，**不新增列、不给 `ChangeElement` 加字段**。若他方草稿主张给 `ChangeElement` 增字段，**会与本方案「布尔以 0/1 进 `Elements`、否决 `FlagChanges` 分列」的论证交叉**。
2. `ElementSpec` 保持六列（决定 4 选 A 则七列，只影响 `ResourceElements` 配表）。
3. **列表数不进任何承重表述** ⇒ 新开一列不冲突。
4. **`StatusKey` / `StatusFields` 作用域仍限于 `CharacterProfile.Status`。** 若他方主张把 `StatusChanges` 扩到 `PlayerProfile`，本方案五行落点需重新评估。

### B. 相邻发现（未处理）
1. `profile-service.md` 失败语义表缺一行对称说明（资源族「无对应行 → `PushError` 整批拒绝」vs 统计层「未知 `StatKey` → `PushWarning` 跳过」，不对称是有意的但读起来像遗漏）。
2. `PlayerProfile` 字段表第 5 行 `achievement` 通道填的是 `AchievementManager` 而非列名，与同表其余行口径不一致；第 6–11 行六个 Codex 与第 15 行 `gameSetting` 仍 `⟨待定⟩`。建议判断是否另立待答项。
3. **`architecture.md` 的 `ResourceElements` 注释块与 `profile-service.md` 的表已轻微漂移**（前者 7 行 + 「⟨其余随 cost element 清单逐条补⟩」，后者已列 11 行）。两处是同一张表的两份投影，落笔时须**同批改**。
