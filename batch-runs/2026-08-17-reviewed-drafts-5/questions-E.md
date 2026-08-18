# Phase A 报告 — 分片 E：`solution-draft-draw-pool-and-instance-shapes.md`

目标库：`game-design-documents/`（主库）＋ `backend-design-documents/`（对侧，仅第 5 项承接）。

## 1. 意图要点（我的理解）

1. **抽取原语不新增第三级**：`DrawPool<T>`（content-service，不读 Profile 的过滤）+ `GrantPoolPicker`（profile-service，读 Profile 的排重）两级已足；分界判据 = 「这道过滤需不需要读 `Profile`」。
2. **唯一那段伪码**六步（`AllEnabled` → `(Kind,Scope)` → 去 `ExclusiveSource` → 排除已持有 → [锚定 `Rarity`] → 加权 `PickOne`/`PickMany`），并给出 9 行调用点参数化差异表。
3. **门面补一个具名方法** `TryPickReplacement`（拒绝可空 `anchorRarity` 形参，理由同「删掉中性诱饵名 `All()`」）。
4. **`ordinal` 先算后写**统一纪律（残卷侧此前未明写，后端 §7 复算依赖它）。
5. **`PoolScope` = 具名可空字段的内嵌 `Resource`**（`LocationId` / `PlotArcId`），逐维度与门、空维度恒真，剧情线一侧传全部 `Active` arc 的集合；六条交叉校验。
6. **敌人池单权威**：删 `LocationData.EnemyTemplateIds`；删 `PlotModulation.EnemyPoolScope`。
7. **战斗类 `EventOption` 加可空 `EncounterSpec Encounter`**，`EnemyInstance` 嵌其内；`PastEventEntry` 加轻摘要 `EnemyTraceRef(EnemyId, Level)`。
8. 用户已在评审中把 6 项取向**全部裁决**（一律取推荐项 A / 「删」），其中第 2、6 项标 `[采纳推荐 — 待复核]`。

## 2. 「已答定」断言的核实结果

| 草稿断言 | 核实出处 | 属实？ | 备注 |
|---|---|---|---|
| ①「两条渠道抽哪一条」已答定 | `answer-logs/log-ability-grant-draw-pool.md`（2026-08-12，2 条完整移出 + 2 条部分）；`systems/player-profile/player-power/_index.md:73–94`「授予候选池 = 三条渠道共用的一段抽取（承重）」含完整六步伪码 | **属实** | 草稿的伪码与 `_index.md:76–84` 逐行同构，只多标出 `⟦…⟧` 参数化点。**残留确为收口**：`01-combat.md:17` 的「一次合并收口的机会」条目仍在挂着（它引的 `07-codex-monetization.md` 那条已被 08-12e 移出，指路已悬空） |
| ③「`EnemyInstance` 嵌在 `EventOption` 上」已答定 | `answer-logs/log-combat-solutions.md` 第 8 条（2026-08-06，38 条移出）：「实例 = `EnemyInstance`（定稿不可变、**嵌在 `EventOption` 上随批次落存档**）」；`systems/enemies/_index.md:79` `## 决策(-> ADR)` 同文 | **属实** | 且 `enemies/_index.md:44` 给出三条依据。**漂移属实**：`systems/services/future-event-service.md:225` 仍把它列为待决（「`EnemyInstance` 是嵌在 `EventOption` 上还是只记引用？」），`open-questions/02-event-options.md:13` 同；`EventOption` record（`future-event-service.md:176–188`）十一字段确无任何敌人承载格 |
| ②「`PoolScope` 的数据形态」真未定 | `enemies/_index.md:88`、`enemies/common-properties.md:42`、`open-questions/01-combat.md:31` 三处均登记为待决 | **属实** | 三处都写「`LocationId?` / `PlotLineId?`」——草稿指出的命名问题（本库无 `PlotLine` 类型）**属实**，全库 grep 无 `PlotLineData` |
| 「结构性重复」此前未登记 | `systems/game-progression.md:86` `[Export] public string[] EnemyTemplateIds`（注释「硬框定：该地域的 `EnemyData` 取池」）；`terminology.md:113` location 词条「携带三组字段……一组特定的 `EnemyData`（硬框定取池）」；两侧均无交叉校验条目 | **属实** | 两处引文逐字对上 |
| 「`PlotModulation` 六字段、`EnemyPoolScope` 注释即『对上 `PoolScope`』」 | `plot-manager.md:253–277`，六个 `[Export]`，`:262` 注释逐字为「框定剧情线专属 `EnemyData` 池（对上 `PoolScope`）」 | **属实** | — |
| 残卷侧 `ordinal` 自增时点未明写 | `life-cycle-service.md:129` 只写 `AccountRng.For(AccountStream.PowerFragment, FinaleWinOrdinal)`；`player-profile/_index.md:39` 只说停摆时照常 `+1`；礼包侧 `monetization.md:63` 明写 `ordinal = …BundleGrantOrdinal + 1` | **属实** | 后端 `contracts/profile-sync.md:237–239`：「后端在 `finaleWinOrdinal` **递增的那一次 push** 上，自算 `roll' = SplitMix64(accountSeed, PowerFragment, finaleWinOrdinal)`」⇒ 后端用的是**自增后**的值。草稿的推论（不统一则每个正常账号稳定误报）**成立**，且这确是「补写既有意图」而非新决策 |
| 门面缺 `anchorRarity` 入口 | `profile-service.md:153–157` 四个方法均无该形参；`:138` `GrantPoolPicker` 职责行却写「+ 可选锚定 `Rarity`」；`player-power/_index.md:91`「置换候选池复用同一 picker，只多传一个 `anchorRarity`」 | **属实** | 缺口确实存在 |
| 五个 `DrawPool<T>` 调用方 | `content-service.md:212–226` + `future-event-service.md:141`「它是 `DrawPool<T>` 的第五个调用方」 | **属实** | 但 `content-service.md:214` 正文仍写「当前抽取逻辑散在 future-event-service 物化、商店库存、奖励掷骰**三处**」——已过时（见越界发现 5） |
| 越界发现 1（样本卡组规模自相矛盾） | `enemies/_index.md:19`「规模逐条编排、**不设硬限**」vs `enemies/common-properties.md:18`「**规模 15**」；另 `combat-service.md:104`「卡组规模：两侧皆不设硬限」 | **属实** | 且**两票对一票**——`common-properties.md` 的「15」是孤例 |
| 越界发现 2（三处意图残留） | `enemies/_index.md:27`（「持有道念、**意图**、行为」）· `:71`（「埋伏不进入**意图**的呈现」）· `:44`（依据③「**意图档位**在进入战斗之前即需可算」）；08-15d handoff 确为 `2026-08-15d-intent-removal-…` | **属实** | 依据③ 作废、结论不变、理由须重写——判断正确 |
| 越界发现 3（「图鉴是唯一信息来源」同源残留） | `enemies/common-properties.md:25` **有**；`future-event-service.md:106` **也有**；但 `enemies/_index.md:58` **已是新口径**（「图鉴就是事前知识的主通道」） | **部分不属实** | 草稿把落点写成「`common-properties.md` 与 `_index.md` 都写了」——实际是 `common-properties.md` + `future-event-service.md`。修正落点即可 |

**结论：草稿的核心断言全部属实，仅越界发现 3 的落点点错一处。**

## 3. 校验发现

### 🔴 冲突（必须 interview）

- **R1 — 删掉 `LocationData.EnemyTemplateIds` 会连带删掉「硬框定」这一能力本身，而用户裁第 1 项时看到的代价只有「反查」。**
  - 想法侧：待决第 1 项 A 的代价栏只写「『这个地域会遇到什么』需反查（那本是 `LocationCodex` 的职责）＋改两份文档」。
  - 既有权威：`game-progression.md:74`「事件侧**不是硬分池**，而是……修正；**硬分池只发生在敌人那一侧**。一软一硬是两种框定形态」；`:86` 字段注释「**硬框定**：该地域的 `EnemyData` 取池」；`terminology.md:113` 同。而草稿 2b 给出的 `Matches` 是**与门 + 空维度恒真**，`PoolScope == null` 的通用敌人**在任何地域恒进池** ⇒ 删掉 `EnemyTemplateIds` 之后，**「这个地域只出这几种敌人」在数据上不可表达**，location 侧从「硬分池」退化为「通用池 + 若干专属条目的并集」。草稿自己的 2c 第 4 行校验（通用池在任何 `(EventType, 篇章)` 组合下都不许为空）把这一点固化成硬要求。
  - 同一处还有一个方向问题：`future-event-service.md:88` 写「① **选池** + 选模板 ← `PoolScope`（通用 / 地点专属 / 剧情线专属）」——**「选池」（择一）与「与门过滤」（求并）是两种不同算法**，库内两处措辞并存，草稿只取了后者且未点名这是一次改写。
  - 选项与后果：
    (a) **维持第 1 项 A，并明写「本作不存在地域独占生态：通用敌人恒可在任何地域出现，地域专属条目是叠加而非替代」** ⇒ 改 `game-progression.md`（删 `EnemyTemplateIds` 那一行 + 改写 `:74` 的「硬分池只发生在敌人那一侧」为「敌人侧的框定是并集式的作用域，不是分池」）、`terminology.md:113`（三组字段→两组，同时删掉「硬框定取池」这个词）、`future-event-service.md:88`（「选池」改「框定」）、`enemies/_index.md` 取池段。不触后端库、不改 ADR。
    (b) **给 `PoolScope` 加一个排他位**（如 `bool ExclusiveToScope`：为 true 时该地域 / arc 只从本作用域取池）⇒ 保住「硬框定」表达力，仍是单权威。代价：`PoolScope` 变三字段，且要回答「同一地域两条条目排他位不一致怎么办」（→ 加载期 `PushError`）。
    (c) **改判为待决第 1 项 B**（`EnemyTemplateIds` 留、`PoolScope` 只留 `PlotArcId`）⇒ 保住硬框定，但两个同性质维度分居两侧（草稿已列代价）。
  - **推荐 (a)** —— 依据：`enemies/_index.md:57` 已把「共享敌人池 + 作用域字段，而非另立一批条目」立为承重论据，理由是内容成本与图鉴的「先遇见、再对上」路径；地域独占生态与这条正面相悖（独占即意味着每个地域都要一套自己的完整条目）。且 `game-progression.md:95` 说「敌人物化的两条轴至此正交：location 决定派谁来、赋级带决定有多强」——并集式作用域仍然满足「location 影响派谁来」，只是从「决定」弱化为「加权/加项」。**但这是对 `:74`/`:95` 两句承重表述的改写，必须由用户点头。**

- **R2 — 删掉 `PlotModulation.EnemyPoolScope` 会让 `plot-manager.md` 明写的「派心魔 / 煞气化身**而非常规敌人**」变得写不出来；且「隐式取当前 arc 的 `Id`」在并发 arc 下无定义。**
  - 想法侧：2b 末 + 待决第 4 项：「改为隐式取当前 arc 的 `Id`」，理由是「当前形态允许一条 arc 框定另一条 arc 的专属池，无用例」。
  - 既有权威：
    ① `plot-manager.md:287`「**替代形态 = 一场被 `PlotModulation` 拧过的 `Standard` 档 Combat（零新结构）**。六个字段刚好凑齐一个『剧情线 boss』：`EventWhitelist`……· **`EnemyPoolScope`（派心魔 / 煞气化身而非常规敌人）**……」——「**而非**常规敌人」是排他语义；同文 `2026-08-17e` handoff 第 37 行重复此表。删字段后，在与门语义下心魔条目只是**加进**通用池，玩家照样可能撞上普通山贼，「剧情线 boss」这个既定用例落空。
    ② `plot-manager.md:352–353`：`MaxConcurrentSideArcs`（初值 2）+ Story / Chapter 各恒有一条不占配额 ⇒ **同时最多 4 条 `Active` arc**；`:422`「`ModulateEventOptions` 的输入 = **全部 `Active` arc 的 `PlotModulation` 之并**」。**「当前 arc」在这个结构里没有定义**——草稿自己在 2b 里为敌人侧正确地写了「传全部 `Active` arc 的集合」，却在第 4 项里给调制侧写了单数的「当前 arc」，两处自相矛盾。
    ③ `plot-manager.md:253`「`PlotModulation` 的字段集合 = PlotManager 权力面的逐条投影，**不多一个字段**」+ `:284` 第 3 条理由「本 manager 在数据形态上够不着 Finale……**这条不需要新规则来禁止，它已经被数据形态禁止了**」——权力面的字段数是承重论证的一部分。
  - 选项与后果：
    (a) **不删，只把注释改写为「可框定任一 arc 的专属池，通常填本 arc 自己的 `Id`」**（待决第 4 项的「留」）⇒ `plot-manager.md` 六字段不变，`:287` 的剧情线 boss 用例保住，S2 分片原来的「六字段不变」复核结论也不必改。代价：内容侧多一个可填错的字段（填成别的 arc `Id` 只会静默换池 → 可加一条加载期校验「非空且不在 `PlotArcData` 仓储内 → `PushError`」把「静默」变「大声」）。
    (b) **删，且把语义降级为并集**（草稿原案）⇒ 五字段；必须同时改写 `plot-manager.md:287` 的剧情线 boss 段（承认它做不到排他），并明确「隐式」= 全部 `Active` arc 的 `Id` 集合。
    (c) **删字段，但把排他能力挪进 `PoolScope` 的排他位**（与 R1 (b) 合并解决）⇒ 两处都用同一个机制表达排他。
  - **推荐 (a)（推翻草稿第 4 项的「删」）** —— 依据：删除的唯一论据是「无用例」，而 `plot-manager.md:287` 与 `2026-08-17e` handoff 恰恰**写着一个用例**；「一条 arc 框定另一条 arc 的池」是这个字段能表达排他的副产品，代价可用一条悬空校验消化，而删字段的代价是撤掉一条已写进两份活文档的承重能力。**用户裁第 4 项时的说明只提到「收窄权力面需点头」，没有提到 `:287` 这个用例会落空。**

- **R3 — 用户已采纳的第 4 条交叉校验（「通用敌人池在某 `(EventType, 篇章)` 组合下为空 → 启动期 `PushError`」）在库内不可实现：没有任何字段表达「篇章框定」。**
  - 想法侧：2c 表第 4 行 + 「具体形态」校验清单第 3 行，草稿自称「本草稿新提的一条，且是三层框定叠加带来的必然要求」。
  - 既有权威：`enemies/_index.md:22–24` 的 `EnemyData` 字段表只有 `EncounterScopes` / `PoolScope` / `OverridesDeck` 三个作用域相关字段，**没有篇章字段**；取池伪码 `:54` 第三行只有一句注释「`// ③ 篇章框定照旧`」，`future-event-service.md:88`、`:110` 同样只写「+ 篇章」而不给载体。⇒ 该校验要枚举的 `(EventType, 篇章)` 组合中，**「篇章」这一维在数据上不存在**，这条校验今天写不出来。
  - 选项与后果：
    (a) **本次只落 `(EventType)` 单维枚举**（「某 `EventType` 下通用池为空 → `PushError`」），并把「篇章框定的载体」立为一条新的 open question 落 `01-combat.md`。⇒ 校验可立即实现；不臆造字段。
    (b) **本次一并定义篇章框定的载体**（例如 `EnemyData.ChapterScopes : int[]`，空 = 三章通用）⇒ 校验按原文两维成立；但这是给 `EnemyData` 新增字段，属内容 schema 决策，草稿未推演、`content/enemy/` 也尚未开张。
    (c) 撤下该条校验。
  - **推荐 (a)** —— 依据：草稿「范围外」自陈不答「`EnemyData` 其余字段清单」；(b) 会在本次落笔时臆造一个用户没看过的内容字段，违反第 7 步「不臆造」。**但用户已明确「六条交叉校验全部采纳」，降级为单维需要用户确认。**

### 🟠 含糊（必须 interview）

- **O1 — `activeCombat` 里的敌人承载形态：S1 分片把它显式 defer 给本分片，本草稿没有答。**
  - `solution-draft-profile-field-schema.md:373` 的前置依赖表逐字写着：`| activeCombat 内的 EnemyInstance 形态 | EnemyInstance / PoolScope 形态 | **S5 分片正在答** |`。
  - 而 `combat-service.md:130` 的既有 schema 里，参战方字段末尾是 `enemyRef`（仅敌方）——**这一格的确切类型与指向从未定义**。在嵌套形态下它有三种读法：(a) `EnemyInstance.InstanceId`（指向 `EventOption.Encounter.Enemy`，读档时经 `eventInstanceId` 反查当前批）· (b) `EnemyId`（模板 id，等级等物化产物另存）· (c) 整份 `EnemyInstance` 拷贝。
  - 后果：(a) 零重复、但读档要先解出当前批；(b) 会丢等级（等级重算不出来）⇒ 违反「重算不出来的存」；(c) 与草稿 3b 依据 2「敌人实例全库只有一份定稿副本」冲突。
  - **推荐 (a)** —— 依据：`combat-service.md:116` 已写 `eventInstanceId`「归属的 `EventOption.InstanceId`，**读档时校验一致**」，反查路径本就存在；且 `activeCombat` 的既定定位是「事件内的中间态、寿命短于一次事件」。落笔处：`combat-service.md` 的 `sides` 字段行补一句 `enemyRef = EncounterSpec.Enemy.InstanceId`。

- **O2 — 草稿 3b 依据 2「让『敌人实例只有一份』成为结构事实」在同批 S3 的裁定下不再成立，而它是选 A 的四条依据之一。**
  - 想法侧：3b 依据 2：「若 `EventOption` 平铺 `EnemyInstance` 而 `EncounterSpec` 也持 `Enemy`，则同一份敌人在存档里有两个落点、两条读取路径，**且没有任何机制保证它们相等**」。
  - 同批已裁：S3 定派生实例承载 = `CharacterProfile.activeEvent`（**持整份定稿实例快照**）⇒ 一个战斗类 `EventOption` 的 `Encounter` 会**同时存在于当前批与 `activeEvent` 两处**，正是依据 2 所反对的形状。草稿的连带段只承认了「存档体积上抬」，没有承认依据 2 已被削弱。
  - 选项与后果：(a) **保留结论、重写依据 2**（改为「相对平铺方案，嵌套让敌人实例在**同一份定稿实例内**只有一个落点；跨落点的副本由 `activeEvent` 的既定快照语义统一管辖，以 `activeEvent` 为结算期权威」）+ 在 `combat-service.md` / `character-profile` 侧明写主从；(b) 让 `activeEvent` 不复制 `Encounter`（只记引用）⇒ 与 S3 的「持整份快照」裁定相抵，需回头改 S3。
  - **推荐 (a)** —— 与越界发现 2（依据③ 已作废、结论不变、理由须重写）同一种处置，本批已有先例。**但「结算期以哪一份为权威」是新的一句话，须用户确认。**

- **O3 — 第 5 项的对侧承接项：请后端确认，还是请后端改写？**
  - 核实结果显示后端 `profile-sync.md:237–239` 的措辞（「在 `finaleWinOrdinal` **递增的那一次 push** 上，用 push 里的 `finaleWinOrdinal`」）**已经蕴含自增后口径**，客户端补写即与它一致。
  - 选项：(a) 对侧只落一条**确认性**承接项（`backend-design-documents/open-questions/cross-boundary.md`：「客户端已明写残卷 `ordinal` = 自增后值，请核对 §7 ① 的复算输入与之一致；两侧无需改动即认为已对齐」）；(b) 同时在 `contracts/profile-sync.md:234` 的客户端伪码那一行把 `finaleWinOrdinal` 显式标注为「本次（自增后）序号」。
  - **推荐 (a)+(b)** —— (b) 是一处零风险的措辞消歧，且落在对侧库的**契约本体**上，符合「主库写决策、对侧写承接 + 互相回链」。**但改动对侧契约正文需用户点头。**

### 🔵 可推演（不进 interview）

- `PoolScope` 允许为 `null`（既定「为空 = 通用池，不报错」）⇒ 既有取池伪码 `enemies/_index.md:53` 的 `e.PoolScope.Matches(...)` 会在通用条目上解引用 null。落笔时须写成 `e.PoolScope == null || e.PoolScope.Matches(...)`。依据：`.claude/rules/null-check-rules.md` 检查点 3。
- Godot `[Export] public string` 默认值是 `null` 而非空串 ⇒ 「空串 = 不限」的判据须写成 `string.IsNullOrEmpty(...)`，或字段初始化为 `= string.Empty`。依据：同上 + `data-resource-rules.md`。
- **`EncounterSpec` 实际是 8 个字段**（`combat-service.md:235–243`：`EncounterId` / `Tier` / `Enemy` / `TurnLimit` / `VictoryRule` / `FirstSide` / `RewardPoolId` / `BaseReward`）。草稿 3b 依据 1 写「六个物化产物」却列了 7 个名字，平铺代价应写作「加 7 格（除 `EncounterId` 外全部）」。落笔时用实际数字，不照抄「六个」。
- **枚举名要分清**：`EventType` 的战斗档成员是 `{ Practice, Combat, Finale }`（`enemies/common-properties.md:21`），`CombatTier` 是 `{ Practice, Standard, Finale }`（`combat-service.md:237`）。草稿在同一段里混用了 `Standard` 与 `Combat`；校验条文一律按 `EventType` 写。
- `EncounterSpec.EncounterId` 与 `EventOption.InstanceId` 同值这件事**已经写在库里**（`combat-service.md:236` 注释「战斗类事件下 = `EventOption.InstanceId`」）；本次要新增的只是「它是明写的例外，不是先例」这一句定性。
- 抽取原语两级分工、`GrantPoolPicker` 宿主、排重在取池阶段、无放回、加权表按用途分表——全部是既有结论的汇总，与 `player-power/_index.md:73–94`、`content-service.md:222–226`、`balance.md:294` 逐条对齐，落笔即可。
- `TryPickReplacement` 取具名方法而非可空形参：与 `content-service.md:208–210` 否决「保留 `All()` 但改语义」的论证同构（用错误的名字换安全 = 把 bug 挪到未来），可直接落笔。
- `EnemyTraceRef` 只存 `EnemyId` + `Level`：`adventure-event/common-properties.md:202` 的判据「重算不出来的存」+ `:222` `UnchosenOptionRef` 的先例（「只求可回溯，不求可重建」），推得出。
- 五份草稿的 schema bump 合并为一次：`adventure-event/common-properties.md:258` 已写「当前无线上存档 → 空迁移，走既有 MigrationManager 骨架」。
- 越界发现 3 的落点更正为 `enemies/common-properties.md:25` + `future-event-service.md:106`（`_index.md:58` 已是新口径）。

### ✅ 用户已在评审中定下（照定案处理，不进 interview）

- **第 1 项 A** → `PoolScope` 单权威，删 `LocationData.EnemyTemplateIds`（**但其未被告知的后果见 R1**）。
- **第 2 项 A** `[采纳推荐 — 待复核]` → 具名可空字段的内嵌 `Resource`；字段定名 `PlotArcId`；与门 + 空维度恒真；剧情线侧传全部 `Active` arc 集合；六条交叉校验采纳（**第 4 条的可实现性见 R3**）。
- **第 3 项 A** → `EventOption` 加可空 `EncounterSpec Encounter`；Explore 壳的 `Encounter` 物化时即填好；校验按**真身**类型判；`PastEventEntry` 加 `EnemyTraceRef(EnemyId, Level)`；`EncounterId` 冗余保留并明写为例外。
- **第 4 项「删」** → `PlotModulation.EnemyPoolScope` 删除（**但见 R2**）。
- **第 5 项 A** → 残卷 `ordinal` 补写「先算后写」+ 对侧落承接项（**形态见 O3**）。
- **第 6 项 A** `[采纳推荐 — 待复核]` → Exchange 能力族商品走 `TryPickGrantableMany`，其余三族直用第一级。
- 连带：`EventOption` 本轮共加两格（S2 的 `Outcome` + 本片的 `Encounter`）；S3 的 `activeEvent` 复制代价已知悉；第 4 项覆盖 S2 的「六字段不变」；五片 schema bump 合并。

## 4. 拟改动文档清单

| 文档 | 拟新增 / 修改的要点 |
|---|---|
| `systems/enemies/_index.md` | ① `EnemyData` 字段表 `PoolScope` 行填入类型：`PoolScope`（可 `null` = 通用池）。② 新增 `PoolScope` 类型定义块：`[GlobalClass] public partial class PoolScope : Resource { [Export] public string LocationId { get; set; } = string.Empty; [Export] public string PlotArcId { get; set; } = string.Empty; }`，附匹配语义 `Matches(string currentLocationId, IReadOnlyCollection<string> activeArcIds) => (LocationId 空 ‖ ==currentLocationId) && (PlotArcId 空 ‖ activeArcIds.Contains(PlotArcId))`。③ 取池伪码 `:51–54` 改为 `.Where(e => e.PoolScope == null \|\| e.PoolScope.Matches(currentLocationId, activeArcIds))`，参数由 `activePlotLineId`（单值）改为 `activeArcIds`（集合），并写明理由（最多 4 条并发 `Active` arc，取单值会让 side arc 专属敌人永不出现）。④ 删待决项「`PoolScope` 的数据形态」。⑤ 三处意图残留清理（`:27` 删「意图」· `:71` 改写埋伏那句 · `:44` 依据③ 整条替换）。⑥ `:19` 与 `common-properties.md:18` 的卡组规模矛盾（越界，只登记）。⑦ 若 R1 取 (a)：补一句「地域 / arc 专属条目是**叠加**而非替代，通用条目恒进池」。 |
| `systems/enemies/common-properties.md` | ① 字段表 `PoolScope` 行填入类型与两条悬空校验（`LocationId` 非空且不在 `LocationData` 仓储 → `PushError` + 敌人 `Id` + 悬空 `LocationId` + 抛；`PlotArcId` 对 `PlotArcData` 仓储同款）。② 新增「非 `null` 但两字段皆空 → `PushWarning`（空壳信号）」。③ `:25` 「图鉴在意图黑箱档位下是唯一的信息来源」→「图鉴是事前知识的主通道」。④ 删待决项「`PoolScope` 的数据形态」。 |
| `systems/services/future-event-service.md` | ① `EventOption` record（`:176–188`）加一格：`EncounterSpec Encounter,  // 战斗类真身（Practice / Combat / Finale）非空；其余为 null。EnemyInstance 嵌其内` —— **与 S2 的 `EventOutcomeSpec Outcome` 同批加入，共 13 格**。② 删待决项「物化后敌人实例的类型形态未定」（`:225`）。③ 五旋钮管线产出行（`:94`）补「随 `EncounterSpec` 嵌在 `EventOption` 上，不在战斗开始时二次展开」。④ `:82`、`:88`、`:110` 的「剧情线」参数改为「全部 `Active` arc」；若 R1 取 (a)，`:88` 的「选池」改「框定」。⑤ `:106` 「图鉴在意图黑箱档位下是唯一的信息来源」→ 新口径。⑥ 若 R2 取 (b)：`:112–113` 权力面段的六字段改五字段。⑦ Explore 壳：`Encounter` 在物化时即填好（与 `DestinationLocationId` 的既定处置同构，`:32` 那一段旁补一句）。 |
| `systems/adventure-event/common-properties.md` | ① `PastEventEntry`（`:205–220`）加一格 `EnemyTraceRef Enemy,  // 战斗类痕迹的敌人摘要；非战斗类为 null`；新增 `public sealed record EnemyTraceRef(string EnemyId, int Level);`。② 删注释里「随……敌人实例类型形态答定后扩充」那一句（`:219–220`，**与 S2 的同一句改写合并**）。③ 明写不存 `DeckCardIds` / `ItemIds` / `PowerIds` 及其三条理由 + 「日后做战斗回放需单独存」的如实代价。 |
| `systems/services/profile-service.md` | ① API 表加一行：`置换取池 \| A \| bool TryPickReplacement<TRng>(AbilityKind kind, AbilityScope scope, RarityTier anchorRarity, TRng rng, out string pickedId) where TRng : IRandomSource \| 可选缺失（池空）→ PushWarning，调用方置空操作`。② `:138` `GrantPoolPicker` 职责行补「置换经具名方法而非可空形参——可空默认值会让『忘了锚定稀有度』成为最短路径，而忘了锚定的置换会把 Tier1 换成 Tier5，能上线、线上不可见」。③ 顺带核对 `:90` 的 `PowerFragmentWinOrdinal` 与 `player-profile/_index.md:33` 的 `FinaleWinOrdinal` 撞名（越界，见第 7 节）。 |
| `systems/player-profile/player-power/_index.md` | ① `:91` 「只多传一个 `anchorRarity`」→ 「经具名方法 `TryPickReplacement`」+ 回链。② 新增一句「账号级授予的 `ordinal` 一律先算后写」的回链（不复述通则）。③ 伪码 `:76–84` 原样保留（已与草稿同构）。 |
| `systems/common-properties.md` | 「Seeded RNG 派生」的账号级小节加一条通则：**「账号级授予一律用**本次**的序号掷骰——先算 `ordinal = 旧值 + 1`，用它掷骰，再把同一个值随同一次 `TryApply` 写回；绝不用自增前的旧值。序号自增与是否抽中 / 是否发放无关（静默停摆时照常 +1，否则下一次复用同一 `ordinal`、掷出完全相同的序列，幂等键当场失效）。」** 附一句正面理由：后端以存档里的（自增后）序号复算 `roll'` 并要求与 `LastRoll` 相等，两侧口径不一致会在每一个正常账号上稳定误报。 |
| `systems/services/life-cycle-service.md` | `:129` 的 `AccountRng.For(AccountStream.PowerFragment, FinaleWinOrdinal)` 改为显式的 `ordinal = FinaleWinOrdinal + 1`（先算后写）+ 回链 `common-properties.md`。 |
| `systems/game-progression.md` | ① `LocationData`（`:78–90`）删 `EnemyTemplateIds` 那一行 ⇒ 字段由 8 格降为 7 格。② `:72` 的三组字段表删「一组特定的 `EnemyData`」行。③ `:74` 「硬分池只发生在敌人那一侧」按 R1 的裁决改写。④ `:95` 「location 决定派谁来」按 R1 改写（并集式作用域）。⑤ 明写「『这个地域会遇到什么』的反查归 `LocationCodex`（运行时统计），不是内容编写面」。 |
| `terminology.md` | `:113` location 词条：「携带三组字段」→「两组字段」，删「一组特定的 `EnemyData`（硬框定取池）」；同时把 `EnemyTemplateId` 措辞统一为 `EnemyId`（词表内若有）。 |
| `systems/services/plot-manager.md` | 按 R2 裁决二选一：**(a) 留** → `:262` 注释改为「框定剧情线专属 `EnemyData` 池（对上 `PoolScope.PlotArcId`）；通常填本 arc 自己的 `Id`」+ 新增加载期悬空校验；**(b) 删** → `:255–265` 六字段改五字段、`:268–277` 对照表删「框定用哪个敌人池」行、`:287` 剧情线 boss 段改写（承认排他做不到）、`:284` 第 3 条理由复核，并明写收窄权力面的理由。 |
| `systems/services/combat-service.md` | ① `:130` 参战方字段行给 `enemyRef` 定形（按 O1 裁决，推荐 `= EncounterSpec.Enemy.InstanceId`）。② `EncounterSpec` 定义块（`:235`）附一句：「`EncounterId` 与 `EventOption.InstanceId` 冗余是**明写的例外**（combat-service 只见 `EncounterSpec`、不见 `EventOption`，删掉它会让战斗侧日志与 `ActiveCombat` 存档失去溯源键），**不是先例**」——形态同 `LifeSpanAfter`。③ 若 O2 取 (a)：明写结算期以 `activeEvent` 那一份为权威。 |
| `systems/balance.md` | 权重表小节点明结构结论：**分表维度 = 按用途（授予 / 战后奖励），不按渠道（打 / 买）、不按 `(Kind, Scope)`**；不新增任何数值。 |
| `systems/services/content-service.md` | `:214` 「当前抽取逻辑散在……三处」→ 五个已登记调用方（物化 / 商店库存 / 奖励掷骰 / 能力授予池 / 闭关功法候选）。 |
| `systems/monetization.md` | 空池三道闸段保持不变；仅在 `:63` 的伪码旁补一句回链，指向 `common-properties.md` 新立的 `ordinal` 通则（不复述）。 |
| **对侧库** `backend-design-documents/` | ① `open-questions/cross-boundary.md` 新增承接条目：「客户端已明写残卷 `ordinal` = **自增后**（本次）序号；请核对 `contracts/profile-sync.md` §7 ① 的复算输入与之一致」+ 回链客户端 `systems/common-properties.md`。② 若 O3 取 (b)：`contracts/profile-sync.md:234` 的客户端伪码行把 `finaleWinOrdinal` 标注为「本次（自增后）序号」。**不复述客户端语义，只写引用。** |
| `handoffs/2026-08-17?-draw-pool-and-instance-shapes.md`（新建） | 承载本片全部意图 + `## Clarifications`（interview 裁决逐条）+ `## Open questions`。 |

**跨草稿核对要点（供 orchestrator）：**
- `EventOption` 本轮 11 → 13 格：`EventOutcomeSpec Outcome`（S2）+ `EncounterSpec Encounter`（本片）。两片已互相声明，**字段名与类型无冲突**，但 record 定义块只能由**一个** worker 落笔（写入面冲突：`future-event-service.md:176–188`）。
- `adventure-event/common-properties.md` 的 `PastEventEntry` 注释「随『EventOption 完整物化字段清单』与『敌人实例类型形态』两项答定后扩充」需**两片合并**改写：S2 主张 0 新增字段、本片加 `EnemyTraceRef Enemy` ⇒ 最终为「+1 格」。同一文件，须串行。
- `plot-manager.md` 的 `PlotModulation`：S2 复核结论「六字段不变」vs 本片第 4 项「删为五字段」。**R2 若推翻删除，S2 的原结论反而正确** —— orchestrator 须在 interview 后统一裁定，只由一个 worker 写该文件。
- S3 的 `CharacterProfile.activeEvent`（持整份快照）与本片的 `Encounter` 嵌套 ⇒ 见 O2。
- S1 的 `activeCombat.EnemyInstance 形态` 显式 defer 给本片 ⇒ 见 O1，**若不答，S1 与 S5 之间会留一个双方都以为对方在答的洞**。

## 5. 拟移出的 open-questions 条目

- `open-questions/01-combat.md:17` — **「一次合并收口的机会（非阻塞）」** → 答定为：两级抽取原语（`DrawPool<T>` + `GrantPoolPicker`）+ 唯一伪码 + 9 行调用点参数化差异表；门面补 `TryPickReplacement`。归档去向 `systems/player-profile/player-power/_index.md` · `systems/services/profile-service.md` · `systems/services/content-service.md`。
- `open-questions/01-combat.md:31` — **「`PoolScope` 的数据形态」** → 答定为：具名可空字段的内嵌 `Resource`（`LocationId` / `PlotArcId`）+ 与门匹配语义（剧情线侧传全部 `Active` arc 集合）+ 悬空校验。归档去向 `systems/enemies/_index.md` · `common-properties.md`。
- `open-questions/02-event-options.md:13` — **「物化后敌人实例的类型形态（08-09c）」** → 答定为：`EventOption` 加可空 `EncounterSpec Encounter`，`EnemyInstance` 嵌其内；`PastEventEntry` 加 `EnemyTraceRef(EnemyId, Level)`。归档去向 `systems/services/future-event-service.md` · `systems/adventure-event/common-properties.md` · `systems/enemies/_index.md`。
- **部分移出** `open-questions/01-combat.md:15` — **「`RarityTier` 的分布与权重表」** → 本次只答**结构面**（分表维度按用途，不按渠道 / 不按 `(Kind, Scope)`）；**数值仍待定**（战后奖励三表 + 内容侧每档条目数），条目留在清单并收窄措辞。同款收窄也适用于 `player-power/_index.md:117` 的同名待决项。
- （视 R2 裁决）`systems/services/future-event-service.md:225`、`enemies/_index.md:88`、`enemies/common-properties.md:42` 三处**主题文档内的**待决项一并删除——它们不是清单条目，但属同一次收口。

**answer log 文件名：** `answer-logs/log-draw-pool-and-instance-shapes.md`（输入是 `inbox/solution-draft-<slug>.md` ⇒ 取 `<slug>`）。台账行：`log-draw-pool-and-instance-shapes.md | 2026-08-17 | inbox/solution-draft-draw-pool-and-instance-shapes.md | 3 条完整 + 1 条部分`。

## 6. 拟新增的 open-questions 条目

- `open-questions/01-combat.md` — **「敌人池的篇章框定载体未定」**（R3 若取 (a) 则必增）：`EnemyData` 上没有任何字段表达篇章，而取池伪码的第三层写着「篇章框定照旧」；载体定下前，「通用池在某 `(EventType, 篇章)` 组合下为空」的启动期校验只能按 `EventType` 单维实现。→ `systems/enemies/`、`systems/services/future-event-service.md`。
- `open-questions/01-combat.md` — **「地域 / 剧情线专属池是叠加还是排他」**（仅当 R1 取 (a) 且用户希望保留日后加排他位的可能时登记；若取 (b)/(c) 则不增）。
- `open-questions/cross-boundary.md`（客户端侧）— **「残卷 `ordinal` 口径待对侧确认」**，与对侧库同名承接项互相回链；对侧确认后两侧一并移出。
- 已有条目**不新增**：`GrantPoolMargin` / `K` 取值（`07-codex-monetization.md:10`，本次未触及）· 战后奖励三表数值 · 敌人 AI 算法 · 敌人是否以功法构筑卡组 —— 全部原样留在清单。

## 7. 越界发现（不处理，仅记录）

1. **`enemies/_index.md:19`（「规模逐条编排、不设硬限」）vs `enemies/common-properties.md:18`（「规模 15」）自相矛盾**，且后者带 `PushError` 语义。第三票在 `combat-service.md:104`：「卡组规模：两侧皆不设硬限」——**两票对一票，`common-properties.md` 的「15」是孤例**。属 `enemies/` 内部数值面，归内容 / 数值侧。
2. **`enemies/_index.md` 三处意图机制残留**（`:27` · `:44` 依据③ · `:71`），意图已于 08-15d 整条移除。第 44 行尤其要紧：它是「`EnemyInstance` 嵌在 `EventOption` 上」的三条依据之一而该依据已作废——**结论不变（另两条仍成立），理由须重写**。本片在第 4 节已列入拟改（因为正是本次要落笔的那一段），其余两处只登记。
3. **「图鉴在意图黑箱档位下是唯一的信息来源」的落点更正**：残留在 `enemies/common-properties.md:25` 与 `future-event-service.md:106`；`enemies/_index.md:58` 已是新口径（「图鉴就是事前知识的主通道」）。草稿把落点写成了另外两份文件。
4. **`EnemyTemplateId` vs `EnemyId` 撞名**：`future-event-service.md:225`、`open-questions/02-event-options.md:13`、`adventure-event/common-properties.md` 用 `EnemyTemplateId`，而 `EnemyInstance` record 的实际字段名是 `EnemyId`（`enemies/_index.md:36`）。宜统一为后者。
5. **`content-service.md:214` 的调用方计数过时**（写「三处」，实为五个已登记调用方）。
6. **`profile-service.md:90` 写 `PowerFragmentWinOrdinal`，而 `player-profile/_index.md:33` 与全库其余处一律写 `FinaleWinOrdinal`** —— 同一字段两个名字。且 `player-profile/_index.md:62` 声称「当前库内只有 `FinaleWinOrdinal` 一个 `Ordinal`」，而 `BundleGrantOrdinal`（`:78`）明明也在，**这句话本身已过时**。属 profile 字段命名面（S1 分片邻域），本片不处理。
7. **`open-questions/01-combat.md:17` 的指路已悬空**：它指向 `07-codex-monetization.md` 的「授予渠道候选池」条目，而该条目已于 08-12e 被移出（`log-ability-grant-draw-pool.md`）。本片移出该条目时自然消解。
