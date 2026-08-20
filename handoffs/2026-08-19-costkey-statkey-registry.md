# `CostKey` 资源族清单闭合 与 `StatKey` 成员清单 / 两族的书写分野

- id: 2026-08-19-costkey-statkey-registry
- date: 2026-08-19
- topic: systems/architecture.md · systems/services/profile-service.md · systems/player-profile/_index.md · systems/character-profile/_index.md · systems/services/sync-service.md
- status: distilled
- distilled-to: systems/architecture.md, systems/services/profile-service.md, systems/player-profile/_index.md, systems/character-profile/_index.md, systems/services/sync-service.md

## Intent（distilled）

两条紧耦合的待答项一并收口：**`CostKey` 资源族的完整 element 清单**，与 **`StatKey` 的成员清单 / 增长登记方式 / 它与 `CostKey` 的书写分野**。后者的核心难点正是「与 `CostKey` 的分野」，而分野规则只有在前者的清单落定后才能验证两个枚举的成员名空间是否真的不相交——两份完整清单同时在手才看得出来。

### 一、方法：清单不靠枚举「想得到的资源」，靠对字段表做一次穷举

`ProfileChangeSpec.Elements` 的唯一职责是写 Profile 上的资源型字段，而两层 Profile 的字段表已逐格定案并标注了写入通道。因此正确的推演方式是**反向枚举**：遍历两张字段表，取出所有「写入通道 = `Elements`」的格子，每一格恰好对应一个 `CostKey` 成员；闭合的判据是这个映射**双向满射**。

这次穷举同时产出了一处**真实缺口**（见第三节），正是穷举法相对「列举想得到的资源」的价值。

### 二、`CostKey` = 15 个成员

**轮回层 · `CharacterProfile`（7 个）**：`LifeSpan` · `Jade` · `LifeTotal` · `ManaLimit` · `ExperiencePoint` · `Faith` · `Bloodlust`。穷举 23 字段 + `Status` 12 格，标为 `Elements` 的恰是 `jade` 与 `Status` 前六格，与已声明的 7 个成员逐一对应、无缺无余——**轮回层此刻已闭合，一个成员都不加**。

**账号层 · `playerPowerFragment`（7 个 ↔ 7 字段）**：`PowerFragmentAccumulated` · `PowerFragmentFinaleWinOrdinal` · `PowerFragmentCh1FirstWinDone` / `Ch2FirstWinDone` / `Ch3FirstWinDone` · `PowerFragmentLastRoll` · `PowerFragmentLastEffectiveChance`。七行的两个修正列**恒为 `null`**：它们是残卷的元进程计数与后端复算凭证，经 pipeline = 一条法则能加速自己被获得（自举回路），或一条法则能改写反作弊证据。

**账号层 · `entitlement`（1 个）**：`BundleRedeemedOrdinal`（兑现水位，`Set`）。授予序号 `BundleGrantOrdinal` 由后端在验票事务内推进、经 pull 下行，**不是 `CostKey` 成员、不在 `ResourceElements` 表**。

**三个首胜标记落三个具名成员，不落参数化 key。** C# 枚举成员不能带参数，参数化必然退化为给 `ChangeElement` 加一个可空载荷格，那正是被否决的替代之一；存档侧标的本就是三个具名布尔，与 `chapterRetry` 三字段、三个 band、六个 Codex 同款判据（篇章数是固定的游戏结构，不是可扩展列表）。代价明写：新增篇章要加三个枚举成员。

**布尔以 `int 0/1` 进 `Elements`，不另开 `FlagChanges` 列。** 按三级判据的六个面核对，它与 `Elements` 在五面全对齐（要钳制 · `Set` 下不走 pipeline · 失败阻断整批 · `Set` 幂等 · 键与载荷是标量），只在「有无量纲」一面不同——判据要求六面全对齐才不分列，其反面是**只差一面不足以分列**，否则每个 `Set` 型标量都要一列。

**闭合核对：** 非 `Elements` 的格子各有已定案的归宿（`AbilityElements` / `DeckElements` / `StatusChanges` / `PlotElements` / `EventStateChanges` / `RngElements` / `TraceElements` / `Stats` / 不经 spec），没有一格落在资源族而无 key。六个 Codex / `achievement` / `gameSetting` 是集合成员增补或一组设置项，**形状上不是资源族——它们要的是一列，不是一个 key**，故资源族清单可在那些通道定案之前独立闭合。

**两处改名**（成本此刻为零，窗口随第一批存档写下而关闭）：`Experience` → `ExperiencePoint`（全表唯一名不对齐的行，对齐后「key 名 ⟸ 字段路径」规则零例外）· `PowerFragmentWinOrdinal` → `PowerFragmentFinaleWinOrdinal`。

**新增一个资源 element 恰好五步**：加字段并更新字段表 → 加枚举成员 → 加配表一行六列 → bump schema → 若含 `Set` 则两修正列留空。不新增服务、不改任何调用方。

### 三、本次发现的真实缺口：`LastRoll` / `LastEffectiveChance` 无写入通道

`PlayerPowerFragment` 上两条承重的写入约定已定案——「每一次 Finale 胜利都掷这一骰并写 `LastRoll`，即使当次不发放」「首胜时 `LastEffectiveChance` 写 `10000`」，且明写「缺任一条即在正常账号上触发后端风控误报」；但两者在 `ResourceElements` 表里**没有行**，而无行 = `PushError` + 整批拒绝。**按两份文档的字面，那次 Finale 收口的 `TryApply` 会被自己拒绝。** 这是两份已定案文档之间的不一致，不是新设计：补两行即闭合，零结构增量。取值域 `[0, 9999]` / `[0, 10000]` 直接取自字段表已写死的区间。

### 四、`StatKey` = 首批两项，成员名 = 字段名逐字

`TotalCyclesCompleted` / `TotalCyclesDefeated`（由 `CyclesCompleted` / `CyclesDefeated` 改名对齐；`PlayerStatistics` 的字段本就已是 `TotalCycles*`，字段侧零改动）。**不扩充清单**——统计层新增字段的成本近乎为零，首批清单的价值在于小而无歧义。

**新增一个统计项恰好三步**，且**明确不建 `StatFields` 配表**：与 `ResourceElements` 对照六列逐列为空，建表等于建一张全空表。替代品是一条启动期**双向覆盖断言**（`StatKey` 成员 ↔ `PlayerStatistics` 字段），一行反射遍历、`#if DEBUG` 生效。

### 五、两族的书写分野（三条可机械核对的规则）

1. **有没有配表**：一个 key 若需要说清取值域 / 终态 / 修正准入，它按定义属于资源族。
2. **失败口径**：缺 `ResourceElements` 行 = `PushError` + 整批拒绝；未知 `StatKey` = `PushWarning` + 跳过。
3. **词缀**：`CostKey` 禁用 `Total` 前缀 / `Count` 后缀、允许 `Ordinal` / `Used`；`StatKey` 必须带 `Total` 或 `Count`、禁用 `Ordinal` / `Used` ⇒ **两个成员名空间在构造上不相交**，读到任意裸 key 名不查文档即可判族。

判据本身不是新的：**元素键的分野就是字段分层的投影**——`CostKey` 是规则字段层的键，`StatKey` 是统计计数层的键，一句话判据仍是「这个数会被规则 / 闸门 / 幂等键读吗」。分野的主体保障已在纪律阶梯第 1 级（两个独立 `enum` × 两个独立 record struct × 两个独立列表，塞错在语言层就写不出来）；词缀规则防的是**新增一项时放错枚举**，而该错误在开发期即显形，故第 3 级的启动期断言足够。

第四条「key 名 ⟸ 标的字段路径」停在纪律阶梯第 4 级（评审）：「是否自明」需要人判断。**`ElementSpec` 保持六列，不加 `TargetPath`**——命名不对齐连开发期错误都不是，为它付一列常量加一段反射断言正是「为对称而加」；留一条退让位：成员数长到 30+ 时性价比翻转，届时再议。

### 六、成员名冻结

两个枚举都随 `ProfileChangeSpec` 落进 `PastEventEntry.SelectCost` / `AppliedChange`，而枚举以成员名逐字序列化 ⇒ **成员名构成契约，只可追加、永不改名 / 复用**；成员**序**不构成契约。**不给两者分配显式整数 code**：`Source` 走名 / code 双轨是因为它在存档里以整数序列化，两个 element 键无此包袱，加一套 code 等于加一份必须一同冻结的第二真值而收益为零。

## Clarifications

- **三个首胜 key 是否带 `Done` 后缀** → **带**：`PowerFragmentCh1FirstWinDone` / `Ch2FirstWinDone` / `Ch3FirstWinDone`。这**推翻了原始输入正文**（§二.2 表 · 枚举声明 · `ResourceElements` 新增行一律写作不带 `Done` 的 `PowerFragmentCh1FirstWin`）。裁决理由：key 名 = 标的字段路径的 PascalCase 拼接，**规则零例外才可机械检查**；按原始措辞落笔，规则开张当天就有三个例外，与同一份输入里 `Experience → ExperiencePoint` 改名的全部立论直接相抵。成员名落存档与上行契约、只可追加永不改名，选错的窗口在写下第一批存档时关闭。
- **`Elements` 的「资源是量」概括是否改写** → **改写为「标量值：可钳制、`Add` 时可加且带符号分向、`Set` 时是已算好的绝对值」，且 `architecture.md` 与 `profile-service.md` 两份副本同改**。原始输入只把它列为「建议顺手改写」的张力项、未指定落笔范围。只改一份必然产生「两份表各自漂移而无机制发现」。同时把否决 `FlagChanges` 的六面核对结论写进配表行的依据列，使它不只活在被归档的草稿里。
- **`ElementSpec` 是否加第七列 `TargetPath`** → **不加**，保持六列，对齐规则停在评审级。
- **`LastRoll` / `LastEffectiveChance` 补两行** → 非取向项，照方案闭合（两份已定案文档之间的不一致，不是新设计）。
- **原始输入一处算术口误已订正**：§二.2 末段称「含 `Set` 的**五**行自动满足既有断言」，实为六行（`PowerFragmentAccumulated` 的 `Add | Set` 也含 `Set`）。结论不受影响，落笔时写成「含 `Set` 的各行」。

## Open questions

无。本次收口的两条待答项已闭合并移出待答清单。
