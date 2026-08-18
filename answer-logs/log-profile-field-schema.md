# Answer log profile-field-schema

- 日期：2026-08-17
- 来源：`inbox/solution-draft-profile-field-schema.md` → `handoffs/2026-08-17h-profile-field-schema.md`
- 移出条数：10

**`CharacterProfile` 的完整字段结构** → 补上一张只有形态列（字段 / 类型 / 写入通道 / 权威）的 23 行总表 + 12 行 `Status` 子表，并落定五格从未登记的字段：`id`（客户端生成的 GUID，"N" 格式）· `characterDataId`（指向 `CharacterData.Id`，写一次不变，解析不到 → `PushError`）· `defeatReason`（`DefeatReason?`，`null ⟺ status != Defeated`，不设 `None` 哨兵）· `technique`（`TechniqueEntry(TechniqueId, Tier)` 列表）· `looseCard`（裸 `string` 多重集）。剩余仍待答：隐藏属性是否有第四项、`characterDataId` 的取值面。（`systems/character-profile/_index.md`）

**`PlayerProfile` 的完整字段结构** → 补上一张 15 行只有形态列的总表；六本图鉴落六个具名字段、元素取 `CodexEntry(string Id)`（不落字典、不落单表 + `Kind`、不落裸 `string`——加法窗口在写下第一批存档时关闭）；四类持有条目定形为 `CharacterItem` / `CharacterPower` / `PlayerItem` / `PlayerPower` 四个 `readonly record struct`，共有 `SourceCode`，`Charges` 只在 item 两类上。剩余仍待答：`achievement` 条目 schema、`GameSetting` 清单、`StatKey` 完整成员、六 Codex 的计数字段。（`systems/player-profile/_index.md`、`systems/services/profile-service.md`）

**集合字段名取单数还是复数** → **恒为单数**，类型名同样恒为单数；后端透明路径白名单随之改名。适用边界 = **两层 Profile 及其子对象的存档字段名**：`rng.streams → rng.stream` 同批改；diff 报文的结构键（`characterDiffs` / `playerDiff`）与运行时 / 内容侧集合属性（`EventOptionBatch.Options`、`PlotNodeData.CharacterIds`）不受约束。持有一组角色的字段照通则取 `characterProfile`，不开复数例外。（`systems/player-profile/_index.md`、`systems/services/sync-service.md`、对侧 `backend-design-documents/contracts/profile-sync.md`）

**四类持有条目的键名** → 同批收口为 **`powerId` / `itemId`**（不保留契约侧的 `id`）。原草稿「不引入改名层、直接叫 `Id`」的论据前提是「契约已冻结 `id`、动它要付破坏性变更的代价」——该代价本批已由单数改名付掉，故前提不再成立；错过这次窗口则 `PlayerPower.Id` 与 `CharacterPower.PowerId` 两种风格永久并存。算法与既有测试向量不受影响。（`systems/player-profile/_index.md`、对侧 §5 / §7）

**`chapterRetry` 三个字段的名字** → `Ch1RetryUsed` / `Ch2RetryUsed` / `Ch3RetryUsed`；命名硬约定新增一条**规则字段层的「数量」用 `Used` 后缀**。避开 `Ordinal`（位置 / 幂等键）与 `Count`（统计计数层）两个已被占用的词缀，且不放宽 `Count` 的单义性——后者会让整条约定从「可机械检查」降级为「要读上下文」。（`systems/character-profile/_index.md`、`systems/player-profile/_index.md`）

**`contentVersion` 的类型在链路上不一致** → 统一为 **`int`**，改存档侧。它的用途是判等与有序比较（manifest 防回放），字符串比较会在 `"9"` vs `"10"` 上给出错误答案；传输侧 `ProfilePayload` 与 content-service 门面属性本就是 `int`。实际改写点是 `character-profile/_index.md` 的类型列一处——content-service 的双 `contentVersion` 表只有语义列、无类型列。（`systems/character-profile/_index.md`）

**`currentMana` 的归属** → 移入 `activeCombat`，`Status` 只留 `manaLimit`。它每回合刷满、回合内不结转，寿命短于一次事件 ⇒ 按「重算得出来的不存」它不属于跨事件持续的角色状态。连带修正 combat-service 参战方字段行的括注：不变的是 `manaLimit`，`currentMana` 恰恰是决策点存档必须恢复的那一格。`[采纳推荐 — 待复核]`（`systems/character-profile/_index.md`、`systems/services/combat-service.md`、`systems/services/life-cycle-service.md`）

**`Realm` 枚举与 `StatusFields` 的缺行** → `Realm { QiRefining, FoundationEstablishment, GoldenCore, NascentSoul }` 登记进共享核心类型枚举清单（它已被 `ChapterCompleted` 负载使用却从未登记）；`StatusFields` 补 `ChapterLifeSpanBudget → (Int, 0, null)` 并删除该占位（`StatusKey` 已含该成员，而「启动期断言表覆盖全部成员」是硬要求，缺行即启动期报错）。存 `realm` + `level`、不存全局序——全局序是二者的纯函数，而 `realm` 自身有四处独立消费点。（`systems/architecture.md`、`systems/character-profile/_index.md`）

**`schemaVersion` 是不是 `PlayerProfile` 的字段 · JSON 命名策略** → 不是，它的落点是存档 / 传输的信封（三处既有形态已一致）；把版本号塞进被版本化的对象会自指。JSON 序列化取 **camelCase、配置在一处**，推论承重：C# 字段名与 JSON path 机械对应 ⇒ 重命名任一透明段存档字段自动落进既有的透明路径稳定性纪律。（`systems/services/sync-service.md`）

**`GameSetting` 的形态** → **具名类，不是字典 / 键值表**（与 `CapabilityFlag` 用 `enum`、`PlayerEntitlement` 用具名字段同一条纪律）。**只答形态，清单不填**：两条在册待答项一条都不移出，且明写落笔顺序——先答「设备本地项 vs 账号级项的切分」，再一次性定清单。（`systems/player-profile/game-setting.md`）

**部分答定的说明：** `eventOption` / `activeEvent` 的形状、`looseCard` 的入组通道、`plotKeyPoint` 的集合型载体形状、`activeCombat` 内的 `EnemyInstance` 形态四项本次只在总表里占了行位与写入通道，形状归各自专场；`achievement` 条目 schema、`GameSetting` 清单、`StatKey` 成员、六 Codex 计数字段、隐藏属性第四项、角色模板池取值面六项原样留在待答清单。
