# 两层 Profile 的完整字段 schema：一张总表 + 五格新字段 + 集合命名单数通则

- id: 2026-08-17h-profile-field-schema
- date: 2026-08-17
- topic: systems/character-profile/_index.md · systems/player-profile/_index.md · systems/architecture.md · systems/services/sync-service.md · systems/services/combat-service.md · systems/services/life-cycle-service.md · systems/player-profile/game-setting.md · systems/player-profile/achievement/_index.md · ux/screen-flow.md
- status: distilled
- distilled-to: systems/character-profile/_index.md, systems/player-profile/_index.md, systems/architecture.md, systems/services/sync-service.md, systems/services/combat-service.md, systems/services/life-cycle-service.md, systems/services/profile-service.md, systems/player-profile/game-setting.md, systems/player-profile/achievement/_index.md, ux/screen-flow.md

## Intent（distilled）

`CharacterProfile` 与 `PlayerProfile` 的字段在库内已被逐条定过十余处，却从未汇成一处。缺这张表，三件事悬着：sync 的上行负载字段面定不了稿、主菜单五入口有几格指不到真实字段、元进程层无从推进。

**本次的性质是收拢而非发明**：主体是一次全量采集 + 按层归位 + 逐字段回链，只对确实空白的格给形态。

### 1. 落笔形态：两张只有形态列的总表

在两份 `_index.md` 各补一张完整字段表，每行只写 **字段名 / 类型 / 写入通道 / 权威回链**，不写语义、取值域与校验——那些留在各自的专题文档里。只有形态列的索引表不触「同一字段名在两份文档中同时出现枚举成员表 / 数值 code / 完整校验语义」那条第二权威硬边界，而它正是当前缺的那样东西。代价明写：表随字段增长、需要维护。

### 2. `CharacterProfile` 补五格

- **`id`（`string`）** —— 轮回创建时由客户端生成的 GUID（"N" 格式）。它已被四个 EventBus 负载、`RetryChapter` 与三处读档校验的定位上下文消费，只是从未登记。客户端生成而非向后端申请：`CharacterProfileDiff` 的键值以下对后端不透明，而轮回开始是自动存档点、不是阻塞点，插一次网络往返即把它变成阻塞点。不用序号（要一个账号级计数器 + 一条幂等问题），不用模板 id（同一模板可在不同篇章各有一个 ongoing 角色）。
- **`characterDataId`（`string`）** —— 指向 `CharacterData.Id`，写一次不变。「同一个角色每一局手感相同」这条设计要成立，存档必须记住这一局是哪个模板；`PlotNodeData.CharacterIds` 也需要一个可比对的字段。
- **`defeatReason`（`DefeatReason?`）** —— 三值原因已由 `ResourceElements` 产出、已进 `CharacterDefeated` 负载，却无字段保存；消费方是角色履历与轮回结束屏。不设 `None` 哨兵：枚举是三值封闭的，加一个不该出现的成员会让每个消费点多一个分支。
- **`technique` / `looseCard`** —— 卡组落存档的是 build 层，直接给出这两格。

### 3. `PlayerProfile` 补六个 Codex 字段与四类持有条目形态

六本图鉴各一个具名字段，元素 `CodexEntry(string Id)`。不落字典（增删一本图鉴本就要加 UI 页与收录触发，字典只换来一层查找与一处可空）；不落裸 `string`（计数字段与首次解锁元数据两组候选已在册，而改元素形状从标量到对象是 diff 序列化的破坏性变更——**这一处的加法窗口在写下第一批存档时关闭**）。条目存在 ⟺ 已解锁，不需要 `IsUnlocked`。

四类持有条目并成 record：`CharacterItem` / `CharacterPower` / `PlayerItem` / `PlayerPower`，四者共有 `SourceCode`，`Charges` 只在 item 两类上（允许 `0`，无限法宝恒 `-1`），`Status` 落 `bool`。

### 4. 集合字段名恒为单数（跨边界通则）

**一切集合字段名取单数，类型名同样恒为单数。** 适用边界 = **两层 Profile 及其子对象的存档字段名**。

- 它是**跨边界通则**：客户端字段名经 camelCase 单点策略机械映射为 JSON path，故 Profile 透明段字段改名 = 破坏性契约变更。
- 后端透明路径白名单随之改为单数形态，并同批把条目键名收口为 `powerId` / `itemId`——四类持有条目由此命名全族一致。这是一次破坏性契约变更，成立的三个前提：线上无真实账号数据 · 两侧同批落笔 · 一次性不设兼容期。
- 不受本通则约束的两类：diff 报文的结构键（`characterDiffs` / `playerDiff` 是后端自己解析的信封结构，不经字段映射产生）；运行时与内容侧的集合属性（`EventOptionBatch.Options`、`PlotNodeData.CharacterIds`）。
- `rng` 的 schema 片段同批对齐：`cycleSeed` / `stream`。

### 5. 三条澄清 + 两处订正

- **`schemaVersion` 不进 Profile** —— 它的落点是存档 / 传输的信封（三处既有形态已一致这么写）。把版本号塞进被版本化的对象会自指，且会被卷进它自己的迁移路径。理由与 `baseRevision` 逐字相同。
- **JSON 序列化取 camelCase，配置在一处** —— 多于一处必然出现「一部分转了、另一部分没转」的半配置态。推论承重：C# 字段名与 JSON path 机械对应，故重命名任一透明段字段自动落进既有的透明路径稳定性纪律。
- **`contentVersion` 统一为 `int`** —— 它的用途是判等与有序比较（manifest 防回放），字符串比较会在 `"9"` vs `"10"` 上给出错误答案；传输侧与门面属性本就是 `int`。
- **`currentMana` 不落 `Status`** —— 每回合刷满、回合内消耗、战斗外无意义，属战斗内运行态，落 `activeCombat`。连带把 combat-service 里「战斗内不变，落它只为读档自洽」那句括注拆开：不变的是 `manaLimit`，`currentMana` 恰恰是决策点存档必须恢复的那一格。
- **`chapterRetry` 三字段取 `Ch1RetryUsed` / `Ch2RetryUsed` / `Ch3RetryUsed`** —— 避开 `Ordinal`（位置 / 幂等键）与 `Count`（统计层）两个已被占用的词缀，命名硬约定表因此多一行：规则层的「数量」用 `Used` 后缀。

### 6. 共享核心类型两项登记

`Realm` 枚举（已被 `ChapterCompleted` 负载使用却未登记）· `StatusFields` 补 `ChapterLifeSpanBudget → (Int, 0, null)`（`StatusKey` 已含该成员，而「启动期断言表覆盖全部成员」是硬要求，缺行即启动期报错）。

## Clarifications（interview 产物）

- **单数通则的适用边界？** → 边界 = 两层 Profile 及其子对象的存档字段名。`rng.streams → rng.stream` 同批改；`characterDiffs` / `playerDiff` 不动；运行时与内容侧属性不受约束。原草稿只写「库内命名风格全库自洽」，未划边界。
- **条目键名是否随本次破坏性改名一并收口？** → 收口为 `powerId` / `itemId`。原草稿 §3.14 末段建议「客户端字段直接命名 `Id`，不引入改名层」，其论据的前提是契约已冻结 `id`、动它要付破坏性变更的代价——而该代价本批已经付掉，故原论据不再成立；错过这次则两种风格永久并存。
- **rng schema 片段的大小写？** → 一并对齐 camelCase（`cycleSeed`）。库内第一个示例若违反自己刚立的策略，那条策略无法被读者信任。
- **`currentMana` 移位是否连带修 combat-service 的措辞？** → 修。那句括注对 `manaLimit` 成立、对 `currentMana` 是错的，留着即是权威文档里的一句错话。
- **持有一组角色的字段名？** → 照通则取 `characterProfile`，不开复数例外、不另起容器名。`achievement` / `pastEvent` 已是同款形态（类型单数、字段单数），开例外会让刚立的通则失去可机械检查性。
- **后端 counterpart 是否同批？** → 同批。跨库纪律要求对称落笔，不允许只改一侧就宣称收口；两侧不一致的症状是后端复算按既定语义「不报错、只产生风控噪声」，不会被自动发现。

## Open questions

- **`[采纳推荐 — 待复核]` `currentMana` 移入 `activeCombat`**（`Status` 只留 `manaLimit`）。
- **`[采纳推荐 — 待复核]` 两份 `_index.md` 各补一张只有形态列的总表**（本次的落笔形态本身）。
- **`GameSetting` 的字段清单** —— 须先答「设备本地项 vs 账号级项的切分」，那一条决定哪些字段进 `PlayerProfile`、哪些留本地。
- **`achievement` 条目的 schema。**
- **`Status` 的隐藏属性是否还有第四项。**
- **`characterDataId` 的取值面**（池中几个角色、是否逐步解锁）—— 字段形态不依赖它，只有内容侧取值面依赖。
- **六个 Codex 的计数字段是否要**（遭遇 / 击败 / 败于其手 / 使用次数）与首次解锁元数据。
- **`eventOption` / `activeEvent` 的形状** · **`looseCard` 的入组通道** · **`plotKeyPoint` 的集合型载体形状** · **`activeCombat` 内的 `EnemyInstance` 形态** —— 各归同批其余专场。

## Notes / triage

来源草稿：`inbox/solution-draft-profile-field-schema.md`（`/provide-solution-draft` 产物，用户已评审：六项裁决，其中集合命名一项为逆推荐裁决——用户明确选择改契约对齐库内单数风格）。对侧承接：`backend-design-documents/contracts/profile-sync.md` 的白名单改名与 `schemaVersion` bump，同批落笔。
