# character-profile

> 角色信息 / **CharacterProfile** —— 单次轮回 / 单个角色的状态与历史（对齐 CycleState 概念）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterProfile = 单次轮回 / 单个角色的状态与历史。** 每个 CharacterProfile 对齐 **CycleState** 概念：一次轮回、一个角色所走过 / 可走的整段修行历程与当前状态。它由账号级的 **PlayerProfile** 持有（`List<CharacterProfile>`）。（+ `systems/services/life-cycle-service.md`、`terminology.md`）。
- **角色是有身份的模板，不是程序化生成的空白人（承重）。** 引入内容条目 **`CharacterData`**（区别于本文档的 `CharacterProfile` —— 前者是模板，后者是某一次轮回的角色状态）：
  - **开局随机分配一个角色**（与既定的「炼气起手 = 随机角色」一致，本次只是给「角色」以内容形态）。
  - **每个角色自带一个神通（`CharacterPower`）与两门绑定功法**，且**与角色绑定**——同一个角色的每一局，神通与这两门功法都相同。**推论：跨轮回的熟悉感有了载体**，「这个角色打起来是什么手感」成为玩家可积累的知识。
  - **绑定不等于不可动摇**：那两门功法**同样可被弃置**（见 `deck/_index.md`）——角色给的是**起手形状**，不是永久底盘。
  - 角色池的规模、是否账号级逐步解锁、能否重抽或指定，见待决问题。
- **CharacterProfile 的完整字段表。** 本表**只有形态列**（字段 / 类型 / 写入通道 / 权威）——字段的语义、取值域与读档校验一律留在权威列所指的文档里，本表只做索引与回链。**写入通道** = 该字段经 `ProfileChangeSpec` 的哪一列写入；`—` = 不经 spec，由 life-cycle-service 在轮回创建 / 篇章边界 / 结算收口时直接赋值。

  | # | 字段 | 类型 | 写入通道 | 权威 |
  |---|---|---|---|---|
  | 1 | `id` | `string` | — | 本文档「五格新字段」 |
  | 2 | `characterDataId` | `string` | — | 本文档「五格新字段」 |
  | 3 | `status` | `CycleStatus` | — | `decisions/ADR-0004-realm-checkpoint-retry-model.md` |
  | 4 | `defeatReason` | `DefeatReason?` | — | 本文档「五格新字段」 |
  | 5 | `chapter` | `int`（1–3） | — | `decisions/ADR-0004-realm-checkpoint-retry-model.md` |
  | 6 | `realm` | `Realm` | — | `systems/game-progression.md` |
  | 7 | `level` | `int`（境界内层号） | — | `systems/game-progression.md` |
  | 8 | `Status` | `CharacterStatus`（具名子类） | 见下方子表 | 见下方子表 |
  | 9 | `jade` | `int` | `Elements`（`CostKey.Jade`） | `currency.md` |
  | 10 | `technique` | `IReadOnlyList<TechniqueEntry>` | `DeckElements` | `deck/_index.md` |
  | 11 | `looseCard` | `IReadOnlyList<string>` | `DeckElements` | `deck/_index.md` |
  | 12 | `magicPack` | `IReadOnlyList<CharacterItem>` | `AbilityElements` | `item/common-properties.md` |
  | 13 | `characterPower` | `IReadOnlyList<CharacterPower>` | `AbilityElements` | `power/common-properties.md` |
  | 14 | `disabledAbility` | `IReadOnlyList<DisabledAbilityEntry>` | `AbilityElements`（`Disable`） | 本文档 |
  | 15 | `pastEvent` | `IReadOnlyList<PastEventEntry>` | —（life-cycle 追加） | `systems/adventure-event/common-properties.md` |
  | 16 | `plotKeyPoint` | `IReadOnlyList<PlotKeyPoint>` | `PlotElements` | `systems/services/plot-manager.md` |
  | 17 | `activeCombat` | `ActiveCombat?` | —（combat-service 回写） | `systems/services/combat-service.md` |
  | 18 | `eventOption` | `EventOptionSave?` | `EventStateChanges` | 本文档「两个事件态字段」 |
  | 19 | `activeEvent` | `ActiveEventState?` | `EventStateChanges` | 本文档「两个事件态字段」 |
  | 20 | `chapterRetry` | `ChapterRetry`（具名子类 · 三字段） | —（`RetryChapter`） | 本文档 |
  | 21 | `rng` | `RngState`（具名子类） | —（SeedManager） | `systems/common-properties.md` |
  | 22 | `startContentVersion` | `int` | — | `systems/services/content-service.md` |
  | 23 | `lastContentVersion` | `int` | — | `systems/services/content-service.md` |

  **`CharacterProfile.Status`（具名子类 · 数值型运行状态）**

  | 字段 | 类型 | 写入通道 | 取值域权威 |
  |---|---|---|---|
  | `lifeTotal` | `int` | `Elements`（`CostKey.LifeTotal`） | `ResourceElements` |
  | `manaLimit` | `int` | `Elements`（`CostKey.ManaLimit`） | `ResourceElements` |
  | `experiencePoint` | `int` | `Elements`（`CostKey.Experience`） | `ResourceElements` |
  | `faith` | `int` | `Elements`（`CostKey.Faith`） | `ResourceElements` |
  | `maleficQi` | `int` | `Elements`（`CostKey.MaleficQi`） | `ResourceElements` |
  | `lifeSpan` | `int` | `Elements`（`CostKey.LifeSpan`） | `ResourceElements` |
  | `FaithBand` | `sbyte` | `StatusChanges` | `StatusFields` |
  | `MaleficQiBand` | `sbyte` | `StatusChanges` | `StatusFields` |
  | `LifeSpanBand` | `sbyte` | `StatusChanges` | `StatusFields` |
  | `ChapterLifeSpanBudget` | `int` | `StatusChanges` | `StatusFields` |
  | `CurrentLocationId` | `string` | `StatusChanges` | `StatusFields` |
  | `LocationEventCount` | `int` | `StatusChanges` | `StatusFields` |

  - **`Status` 装数值型运行状态**；集合型 build 状态（deck / 神通 / 储物袋 / 禁用表 / 剧本锚点）与 `Status` **平级**，不落其内。
  - **`currentMana` 不在 `Status` 内。** 它每回合恢复到 `manaLimit`、回合内不结转，寿命短于一次事件 ⇒ 按「重算得出来的不存」它是战斗内运行态，落 `activeCombat`（见 `systems/services/combat-service.md`）。`Status` 只留 `manaLimit`。
  - 两张表的行随字段增长，维护成本明写；它们是索引 + 回链形态，与 `_index.md` 的既有职责一致。`ResourceElements` / `StatusFields` 两张封闭表的逐行取值见 `systems/services/profile-service.md`，枚举声明见 `systems/architecture.md`「共享核心类型」。
- **五格新字段的形态。**

  ```csharp
  string          Id;                // 轮回创建时由客户端生成的 GUID（"N" 格式，32 位小写十六进制无连字符）
  string          CharacterDataId;   // 指向 CharacterData.Id；轮回创建时写一次，此后不变
  DefeatReason?   DefeatReason;      // null ⟺ status != Defeated
  IReadOnlyList<TechniqueEntry> Technique;   // 卡组的 build 层：功法 + 层数
  IReadOnlyList<string>         LooseCard;   // 游离散牌，多重集：同一 CardData.Id 可出现多次

  public readonly record struct TechniqueEntry(
      string TechniqueId,   // 指向功法内容条目的稳定 Id
      int    Tier);         // 当前层数，>= 1
  ```

  - **`id` 由客户端生成、不向后端申请。** `CharacterProfileDiff` 的键值以下对后端完全不透明，后端从不解析它；向后端申请一个 id 会在轮回开始处插入一次网络往返，而轮回开始是**自动存档点而非阻塞点**。**不用「第 N 个角色」的序号**（要一个账号级计数器 + 一条幂等问题，而角色只增不删却可能并行创建于多篇章，GUID 零协调）；**不用 `characterDataId` 作键**（同一模板可在不同篇章各有一个 ongoing 角色）。它是 diff 的寻址键与全部日志 / 读档校验的定位上下文。
  - **`characterDataId` 是「同一个角色每一局手感相同」的存档载体**，也是 `PlotNodeData.CharacterIds` 比对的那一格。读档校验：解析不到 → **必需缺失** → `PushError` 带 `characterId` + `characterDataId`（角色模板是结构性内容，解析不到即坏档，不能像 `pastEvent` 那样降级）。
  - **`defeatReason` 不设 `None` 哨兵。** `DefeatReason` 是三值封闭枚举，加一个不该出现的成员会让每个消费点都要处理一个多余分支；可空是 C# 表达「这一维只在某状态下有意义」的既有形态。读档校验：`status == Defeated` 且为 null → **可选缺失** → `PushWarning`（履历少一行，不阻断）；`status != Defeated` 且非 null → 不可能态 → `PushWarning` + 按 null 处理。消费方是元进程界面的角色履历与轮回结束屏。
  - **`TechniqueEntry` 取 `readonly record struct`**（字段少、条目个位数、要落存档且进 diff），与 `StatusAssignment` / `DeckChangeElement` 同款；`PastEventEntry` 与 `EventOption` 字段多，才取引用型。
  - **`looseCard` 是裸 `string` 多重集而非 record 列表**：散牌没有任何随实例变化的状态（`CardInstance` 的运行态只存在于战斗内、随 `activeCombat` 走），一个 `Id` 就是全部信息。
  - 读档校验：`TechniqueId` / `looseCard` 元素解析不到 → **必需缺失** → `PushError`（与 `DeckChangeElement.Id` 的施加侧同口径——悬空 `Id` 写进 Profile 即污染存档）；`Tier < 1` → `PushError`。
- **`realm` + `level` 是角色的修行位置。** 二者合成**全局等级序**上的位置，是敌人赋级 `±2` 带与 `baseMomentum` 起跑线的判据；篇章突破后 `level` 归位为新境界的初期。**`manaLimit` 不随境界自动成长**，由事件 cost / reward 推拉（见 `mana.md`）。
- **决策点存档。** 事件推进过程中（含战斗内）在**决策点**落存档，使退出重进恢复到同一局面与同一份 RNG 状态；`selectCost` **不回滚**。存档点清单见 `systems/services/life-cycle-service.md`；**战斗内的 D0–D6 决策点清单见 `systems/services/combat-service.md`**。
- **`activeCombat`：进行中战斗的中间态（CharacterProfile 上的可空块）。** 战斗开始时创建、`eventEnd` 收口时**置空**；**不进 `pastEvent`**（历史事件只留定稿快照），也不与 `Rng.Streams[]` 混住——它是**事件内的中间态，寿命短于一次事件**。
  - **为什么挂 CharacterProfile 而非独立的战斗存档实体**：与「每篇章至多一个 ongoing」自洽，且 diff 天然落在 `CharacterProfile` 粒度（sync-service 的既定 diff 单位），**无需新增同步单元**。
  - 内容 = 遭遇参数 + 回合 / 步状态 + 战斗子流 RNG + 两个参战方（含三区 `Id` 序列与 `CardInstance` 运行态）+ 战场条目 + 栈条目 + 挂起态。**完整 schema 与读档校验归 `systems/services/combat-service.md`**（本文件只登记它是 CharacterProfile 的一个字段）。
  - 随 `activeCombat` 一起 **bump schema 版本**（当前无线上存档 → 空迁移）。
- **两个事件态字段：`eventOption`（当前批）与 `activeEvent`（正在结算的那一项）。** 前者是**当前批 eventOptions 的定稿快照**，后者是**结算期间的权威副本**，两者与 `pastEvent` / `activeCombat` / `disabledAbility` / `plotKeyPoint` 平级。

  ```csharp
  EventOptionSave?  eventOption;   // null = 尚无批次（StartCycle 之前 / 老档迁移）
  ActiveEventState? activeEvent;   // null = 当前没有事件在结算

  public sealed record EventOptionSave(
      string                     BatchId,
      IReadOnlyList<EventOption> Option,             // 本批定稿实例，1–5 项
      int                        EffectivePriority); // 0 或 1；产出侧算好，呈现层不自算

  public sealed record ActiveEventState(
      string      EventInstanceId,   // 被结算项的 InstanceId
      EventOption Option);           // 派生后的定稿实例
  ```

  - **`activeEvent != null` 时，本次结算涉及的 `EventOption` 一律读 `activeEvent.Option`**；批中的原实例只用于呈现尚未开始的那些选项与组装 `Unchosen` 轻摘要。**当前批里那份原实例一字不动**——两处派生（Explore 揭示 · Exchange 刷新）都是对 `activeEvent.Option` 的整体置值。派生形态见 `systems/adventure-event/explore/_index.md` 与 `exchange/_index.md`。
  - **另立承载而非原地替换当批实例。** 三条理由：「当前批里那份原实例不动」是既定明文；批的持有者 future-event-service 是无记忆的纯产出侧，原地替换等于给它加一个运行时写入面；**「有事件在结算」这个态必须能一次判空得知**，藏进批里就得遍历才知道，而可空块已是 `activeCombat` 立下的形状。**只存派生增量的散字段**同样否决——每新增一个可派生字段就要加一个散字段，而存整份快照对字段增删完全中立。
  - **两者可空、不设哨兵。** 「写一个空 `Option` 的批」要造一个语义上不存在的 `BatchId` 且 `EffectivePriority` 无意义；「迁移期直接重算一批」要在迁移里跑物化（读内容注册表、掷 map 子流），与「迁移只做结构搬运」相抵。
  - **`activeEvent` 与 `activeCombat` 并存、不合并**：前者是**事件级**中间态（哪一项在结算、它派生成什么样），后者是**战斗状态机**的中间态。把后者塞进前者是一次纯重构，牵动 `combat-service.md` 的整段 schema、收益为零。
  - **生命周期。** `eventOption` —— `StartCycle` 写第一批，此后每次 `RefreshAfterEvent` **整块替换**（新一批的写入并入 `eventEnd` 那一次 `TryApply`）。`activeEvent` —— 与 `TryApply(SelectCost)` **同一次**创建（值 = 当批那一项的原样拷贝），`eventEnd` 收口置空，与 `activeCombat` 同一处清空；**终态判定 ① 判负而短路的那一路，由失败流程一并清理它**。
  - **读档校验**（前六条 **必需缺失** → `PushError` 带 `characterId` + `instanceId`；末条可降级）：

    | # | 检查 | 时机 |
    |---|---|---|
    | 1 | `activeEvent.EventInstanceId` 能在 `eventOption.Option` 中按 `InstanceId` 找到 | 读档 |
    | 2 | `activeEvent.Option.InstanceId == EventInstanceId`，且 `EventId` 与批中原实例一致 | 读档 |
    | 3 | `activeEvent.Option.RerolledCount >= 批中原实例.RerolledCount`（单调不减是刷新价递增的前提） | 读档 |
    | 4 | `IsRevealed` 只允许 `false → true`（回落 = 重新遮罩，等于开一次重掷） | 运行时断言 |
    | 5 | `RerolledCount` 增加 ⇒ `ExchangeStock` 整批替换（不允许只涨计数不换库存，或反之） | 运行时断言 |
    | 6 | `activeCombat != null ⇒ activeCombat.eventInstanceId == activeEvent.EventInstanceId` | 读档（拒绝恢复该战斗，与 `combat-service.md` 既有第 ① 条同档同处置） |
    | 7 | `RerolledCount <= MaxRerollCount` | 读档 + 运行时 → `PushWarning` + 钳到上界（内容侧数值可被 overlay 调低，属可降级） |

  - **恢复即读结果、绝不重走取池链。** 恢复路径读 `activeEvent.Option` 的 `ExchangeStock` / `IsRevealed` 直接呈现，不重新抽取——与「奖励候选预先算定、恢复时读结果不重抽」是同一条纪律的又一个实例。`activeEvent == null` 时直接呈现 `eventOption` 的横滑选择区。
  - **痕迹侧零字段增量**：`PastEventEntry` 的定稿实例快照取自 `activeEvent.Option`，而 `ExchangeStock` / `RerolledCount` 收口后永无消费方 ⇒ 按「重算不出来**且有消费方**」的完整口径不进痕迹，与 `plotKeyPoint`「不记已走分支路径」同款处置。
  - 随本次落定 **bump schema 版本**（老档缺字段 → `null`，按「无进行中批次」处置，下一次 `RefreshAfterEvent` 重算一批；当前无线上存档 → 空迁移）。
- **`pastEvent`：修行历程 = `IReadOnlyList<PastEventEntry>`。** 元素**不是 `Resource`**——存的是**定稿实例快照 + 本次结算的最终账**，这是物化模型的直接推论（`AdventureEventData` 是 ContentRegistry 的共享只读单例，痕迹要记的是「这一次走过的那个实例」）。
  - **条目形态 `PastEventEntry`（13 字段）、判据「重算不出来的存」、未选项轻摘要 `UnchosenOptionRef`、`EventOutcome` 四值枚举与加载时校验，权威在 `systems/adventure-event/common-properties.md`**（本文件只登记它是 CharacterProfile 的一个字段）。
  - **只追加、不修改既有条目**（不变式）；体积护栏与 diff 友好性见 `systems/services/sync-service.md`。
  - **写入经 life-cycle-service 组装 → `profile-service.ProfileManager`**，与「档案写入的唯一入口」一致。
  - 随本次结构落定 **bump schema 版本**（当前无线上存档 → 空迁移）。
- **`chapterRetry`：篇章重试计数器。** 一个**类**，计数第一 / 第二 / 第三篇章各自的重试次数——**因为 ch2 与 ch3 有重试上限**（无限 / 3 / 1，持 premium bundle 为 无限 / 9 / 3，见 ADR-0004）。**它是计数器容器，不是上限持有者**：上限仍按 ADR-0004 的既定纪律读取（可被账号级持有状态改写、凡读取处不得硬编码常量），`chapterRetry` 只答「用掉了几次」。**推论：篇章解锁 / 重新锁定与「剩余重试次数展示」有了确定的数据源。**
  - **形态 = 三个具名字段 `Ch1RetryUsed` / `Ch2RetryUsed` / `Ch3RetryUsed`**，第一 / 第二 / 第三篇章各一，**不是字典也不是按索引的数组**。**`Used` 后缀**避开两个已被占用的词缀——`Ordinal` 表达「第几次」这个位置且要当幂等键用，`Count` 属统计计数层，而 `chapterRetry` 是规则字段层的一个数量（命名硬约定见 `systems/player-profile/_index.md`）。**与「四境三篇章」这条硬事实对齐**（篇章数是游戏结构，不是可扩展列表）：具名字段让存档 schema 显式、读取处不必处理「键不存在」的分支，也免去按索引访问的越界校验。**代价是新增篇章需改 schema——但篇章数不是设计变量。**
  - **通关后保留计数，不清零** ⇒ **它是历史，不只是配额**。一个通关角色身上留着「我在筑基段挣扎了 3 次」的记录，可供元进程界面的角色履历展示；**同时它简化实现**——没有清零时机就没有「何时清零」的边界情形。
  - **ch1 的角色级计数恒为 0，这不是缺陷。** ch1 重试 = 随机生成新角色，故角色级 ch1 计数对每个新角色恒为 0。**「你在炼气段重开了多少次」目前没有字段回答**——账号级统计的首批只有 `TotalCyclesCompleted` / `TotalCyclesDefeated`，后者不区分篇章（见 `systems/player-profile/_index.md`）。这是一个**展示需求**，需要时在 `PlayerStatistics` 上纯加法补一项即可（统计层新增字段零迁移、零后端配合）。**两层口径不同，不是同一个数的两份拷贝**：角色级参与闸门判定，账号级只被读来看。
  - **连带：`attemptIndex` 派生层整层删除**（篇章重试 = 换一套随机流，见 `systems/common-properties.md`）。
- **`disabledAbility`：本轮回禁用表**（与 `pastEvent` / `chapterRetry` / `activeCombat` 平级）。**法则不被强制剥夺，其余一律降级为本轮回禁用**——本字段是这条语义的承载面，覆盖**四类**能力条目（神通 / 法则 / 法宝 / 古宝）。
  - **不落 `Status` 内。** `Status` 装的是**数值型运行状态**（`lifeTotal` / `manaLimit` / `experiencePoint` / 隐藏属性），禁用表是**集合型 build 状态**，与 deck、神通持有列表同层。

    ```csharp
    IReadOnlyList<DisabledAbilityEntry> disabledAbility;   // 单数命名，沿用 pastEvent 的既有风格

    public sealed record DisabledAbilityEntry(
        AbilityKind     Kind,             // Power | Item —— 两个 Id 空间不同，必须显式区分
        AbilityScope    Scope,            // Character | Player —— 决定它抑制哪一层的持有列表
        string          AbilityId,        // PowerData / ItemData 的稳定 Id
        DisableDuration Duration,         // NextEvent | ThisChapter | ThisCycle
        int             AppliedAtSeq,     // 施加时的 pastEvent 时序坐标
        int             AppliedAtChapter, // 施加时的篇章
        string          SourceInstanceId  // 施加它的事件实例，供履历展示与诊断
    );
    ```
  - **存「施加时坐标 + 时长」，不存「到期坐标」。** 施加坐标是**重算不出来的原始事实**，到期判定是它的纯函数；篇章边界的 `Seq` 在施加当时还不知道，存到期坐标要么存不出来、要么要事后回写（回写破坏只追加的便利）。判据同「重算不出来的存」。
  - **三档时长与到期剔除**（`life-cycle-service` 在两个时点各跑一次纯函数式剔除，见该文件）：`NextEvent`（施加之后进入的**下一个** AdventureEvent 全程，`currentSeq >= AppliedAtSeq + 1` 时于 `eventEnd` 收口后剔除）· `ThisChapter`（`currentChapter > AppliedAtChapter` 时于篇章边界剔除）· `ThisCycle`（无需剔除，随 `CharacterProfile` 整体拆解）。
  - **去重键 = `(Kind, Scope, AbilityId)`；重复禁用不叠加，取时长较长的一条**（长短序 `NextEvent < ThisChapter < ThisCycle`）。叠加会造出「禁用三次到底禁到什么时候」这种无谓语义。
  - **禁用不影响持有，也不影响 `Charges`**；同 `Id` 多份的道具按 `Id` 整体禁用（储物袋本就按 `Id` 堆叠）。**禁用表条目不因失去持有而自动移除**——生效面按「持有 ∩ 未禁用」求交，空指向条目是无害的幂等残留。
  - **读档校验：** `AbilityId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `PushWarning` + 保留条目、不阻断读档（与 `pastEvent` 同类处置）；`Duration` 越界 / 缺失 → **必需缺失** → `PushError` 带 `characterId` + `abilityId`；`AppliedAtChapter` 大于当前 `chapter` → 不可能态 → `PushWarning` + 按已到期剔除；同键重复 → `PushWarning` + 合并为时长较长的一条。
  - **生效判据、可见性与施加通道归各自文档**：生效面（不入场 / 不进列表 / 不进聚合）见 `power/_index.md` 与 `item/_index.md`，施加的 element 形态见 `systems/services/profile-service.md`。
  - 随本字段落定 **bump schema 版本**（老档缺字段 → 空列表；当前无线上存档 → 空迁移）。
- **`Status` 上的隐藏属性档位与篇章寿元预算（四个字段）。** 隐藏属性的档位带**回滞**（进入阈值 / 退出阈值不同）⇒ **档位不再是当前值的纯函数，必须持久化**；寿元百分比需要一个**冻结的分母**。

  ```csharp
  // 当前所处档（索引 HiddenStatBandData.BandIndex；0 = 常态，|值| 越大越远离常态）
  sbyte FaithBand;             // 带符号 —— 道心是唯一的双臂属性，取值 -2..+2
  sbyte MaleficQiBand;         // 0..3
  sbyte LifeSpanBand;          // 0..2
  int   ChapterLifeSpanBudget; // 本篇章起始可用预算 = 本章增量 + 上章结转；ChapterManager 在篇章边界赋值
  ```

  - **三个 band 落成三个具名字段而非字典** —— 与 `chapterRetry` 的「篇章数是固定的游戏结构，不用字典 / 索引数组」同款判据：隐藏属性清单虽仍待答，但**增删属性本就要动 schema**，字典只换来一层查找与一处可空。
  - **写入并入 `eventEnd` 那一次 `TryApply`**（band 在组装 spec 时按「前值 + `AppliedChange`」算出**绝对值**，不是相对增量；载体是 `ProfileChangeSpec.StatusChanges` 的 `StatusAssignment`，`sbyte` 存档字段在 spec 内以 `int` 承载）⇒「一个事件的收口是一次事务、一个存档点」原样成立，**不新增存档点、不新增结算阶段**。
  - **不进 `PastEventEntry`**：band 设值已在 `AppliedChange` 内、可重放，按判据「重算得出来的不存」⇒ 快照不加字段。
  - **`ChapterLifeSpanBudget` 随该篇章起始存档带回**（篇章重试时同理），故它对读档与重试都是确定值。
  - 档位表本身、阈值 / 回滞 δ 与跨档叙事规则归 `systems/services/plot-manager.md`。
  - 随本次落定 **bump schema 版本**（当前无线上存档 → 空迁移）。
- **`Status` 上的地域位置与地域配额（两个字段）。** 图本身不落存档（全局不变、启动加载一次），落存档的只有「人在哪」与「在这儿做了几件事」：

  | 字段 | 类型 | 语义 | 生命周期 |
  |---|---|---|---|
  | `CurrentLocationId` | `string` | 当前所在地域（`LocationData.Id`） | **跨篇章持久**，仅由 Travel 结算改写；篇章重试时随该篇章起始存档一并回滚 |
  | `LocationEventCount` | `int` | 当前地域已结算事件数（**不计 Travel**） | 非 Travel 事件结算 `+1`；Travel 结算归 `0` |

  - **两者的更新并入 `eventEnd` 那一次 `TryApply`**，不新增结算阶段、不新增存档点——与三个 band 字段同款处理。**载体是 `ProfileChangeSpec.StatusChanges` 的 `StatusAssignment`，语义为绝对置值**：`+1` 与「归 0」都由 life-cycle-service 先算成绝对值再提交，`ProfileManager` 不做加减。字段的值类型与取值域逐行查 `StatusFields` 表，见 `systems/services/profile-service.md`。
  - **`LocationEventCount` 归 0 恒成立，包括由 Explore 揭示而来的 Travel**：该 Explore 的 `+1` 随即被归 0 覆盖，因为计数的语义是「在这个地域做了几件事」，换了地域即作废。
  - **`CurrentLocationId` 跨篇章不清零**，因为「篇章继承 = 全部继承」+「三章共用同一张图」⇒ 下一篇章从上一篇章结束时所在的地域继续，不需要「起始地域」这个概念。
  - **读档校验：** `CurrentLocationId` 经 `ContentRegistry` 解析不到 → **必需缺失** → `PushError` 带 `characterId` + `locationId`（location 是恒启用的结构性内容，解析不到即坏档，不能像 `pastEvent` 那样降级）；`LocationEventCount < 0` → `PushWarning` + 钳到 0。
  - 字段语义、图的载体与加载期校验归 `systems/game-progression.md`。
  - 随本次落定 **bump schema 版本**（当前无线上存档 → 空迁移）。
- **`plotKeyPoint`：AdventurePlot 的进度锚点 = 每条已激活 arc 一条**（与 `pastEvent` / `disabledAbility` 平级的集合型字段）。

  ```csharp
  IReadOnlyList<PlotKeyPoint> plotKeyPoint;   // 单数命名，沿用 pastEvent 的既有风格

  public sealed record PlotKeyPoint(
      string       ArcId,             // PlotArcData 的稳定 Id
      string       NodeId,            // 该 arc 当前所处节点（PlotNodeData 的 Id）
      PlotArcState State,             // 枚举声明见 systems/architecture.md「共享核心类型」
      int          EnteredAtChapter,  // 进入当前节点时的篇章
      int          EnteredAtSeq       // 进入当前节点时的 pastEvent 时序坐标
  );
  ```

  - **只有内容侧 `Id` 与两个整型坐标，没有任何 `InstanceId`** —— 内容条目不得隐式依赖存档的运行时标识空间；`EnteredAtSeq` 用 `pastEvent` 的 `Seq`，与 `DisabledAbilityEntry.AppliedAtSeq` 同款坐标。
  - **粒度由悬空降级规则反推**：每条记录自成一个可独立解析的单元，一条悬空只让**那一条剧本线**惰性化，其余 arc 照常调制、照常叙事。
  - **`Queued` 是排队中的 side arc**（触发时即写，出队时改 `Active`）：band 回落后「曾跨入触发档」这一事实重算不出来，按判据「重算不出来的存」它必须落存档。并发上限只数 `Active`。
  - **不记已走分支路径**：路径当前无消费方（调制 / 叙事 / 推进都只读当前节点），按判据的完整口径「重算不出来**且有消费方**」⇒ 不存。日后履历展示的落点是 `PastEventEntry`。
  - **写入并入 `eventEnd` 那一次 `TryApply`**（与三个 band 字段、两个 location 字段同款），不新增存档点、不新增结算阶段；一次结算每条 arc 至多前进一个节点。**载体 = `ProfileChangeSpec.PlotElements`，条目类型 `PlotKeyPointAssignment`**（本 record 的镜像，语义是按 `ArcId` 的整条 upsert）。
  - **读档校验**（悬空 → `PushWarning` + 该条惰性、保留条目；`State` 缺失 / 越界 → `PushError`）与推进规则归 `systems/services/plot-manager.md`。
  - 随本字段落定 **bump schema 版本**（老档缺字段 → 空列表；当前无线上存档 → 空迁移）。
- **RNG 状态与内容版本落在 CharacterProfile 上。** 新增三组字段，随本次存档 **schema bump**（当前无线上存档 → 空迁移，但迁移骨架就此立起）：

  | 字段 | 类型 | 语义 |
  |------|------|------|
  | `StartContentVersion` | `int` | 轮回开始时生效的内容版本，**写一次不再变** |
  | `LastContentVersion` | `int` | **每个自动存档点**更新为当时生效的版本；与上一字段不等 = 该轮回跨过内容更新（数值突变类反馈的第一判据） |
  | `Rng.CycleSeed` | `ulong` | 轮回开始时生成，不变 |
  | `Rng.Stream[]` | `Name` / `Seed` / `State` / `DrawCount`（`string` / `ulong` / `ulong` / `int`） | 具名子流状态；`State` 为恢复权威字段，`DrawCount` 为诊断与迁移保险 |

  schema 形态（JSON 侧一律 camelCase，见 `systems/services/sync-service.md`「JSON 序列化命名策略」）：

  ```jsonc
  "rng": {
    "cycleSeed": 12345678901234567890,        // u64，轮回开始时生成，不变
    "stream": [
      { "name": "map",    "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "combat", "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "shop",   "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "reward", "seed": 0, "state": 0, "drawCount": 0 }
    ]
  }
  ```

  派生规则与恢复语义见 `systems/common-properties.md`；双 `contentVersion` 的诊断用途见 `systems/services/content-service.md`。
- **角色状态是终态收敛的状态机。** `status` 收敛为 `ongoing | defeated | completed`（`defeated` 的三种原因：discarded / 寿元归 0 / lifeTotal 归 0）；`defeated` 与 `completed` 数据都会在轮回结束时被清理。→ 见 `systems/services/life-cycle-service.md` 与 `decisions/ADR-0004-realm-checkpoint-retry-model.md`。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-17h-profile-field-schema.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md`

## 子系统导航

| 子系统 | 文件 | 内容 |
|--------|------|------|
| 卡组 deck | `deck/_index.md`、`deck/common-properties.md` | 抽牌堆 / hand / 弃牌堆、seeded 洗牌、deck 变更；**功法（构筑单位，带层数、整组替换式升阶）**；卡牌 / CardData 定义（费用、目标、效果流水线、触发器）；起始卡组等内容设计。 |
| 法宝 item | `item/_index.md`、`item/common-properties.md` | **CharacterItem**：轮回级角色道具（含道具设计内容；细节待定）。 |
| 轮回货币 currency | `currency.md` | 轮回货币 jade 的获取 / 消耗。 |
| 神通 power | `power/_index.md`、`power/common-properties.md` | **CharacterPower**：轮回级角色能力，**对标账号级 PlayerPower（法则）**（同一概念的两层，分界是生命周期）；随轮回清理，**可承载战斗内触发式效果**。 |
| 生命总量 lifeTotal | `life-total.md` | **战斗外的耐久 / 失败惩罚承受量**（战斗内不参与，失败结算时按道念差扣减）；**归 0 → defeated**；经 AdventureEvent 恢复；炼气基线 10/10；无曲线。 |
| 法力 mana | `mana.md` | 每回合出牌资源；**每回合恢复至 `manaLimit`**，上限由事件推拉；炼气基线 5/5。 |

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **子系统结构。** `deck` / `item` / `power` 为**文件夹**——除规则外还要容纳**内容设计**（起始卡组 starter decks、道具设计 item designs、能力条目）；`life-total` / `currency` / `mana` 为**扁平 `.md`**——它们是系统性资源（systematic resource），预期规则足够短，暂以单文件承载。
- **境界存档 · 篇章重试模型**（CharacterProfile 状态机 `ongoing | defeated | completed`、全部继承、重试上限）→ `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **角色模板池的形态。** 池中有几个角色、是否账号级逐步解锁、**能否重抽或指定**——涉及元进程压力模型（既定的「炼气可无限重试」在「重开就换一个角色」下的手感与在「可指定角色」下完全不同）。→ 本文档、`systems/player-profile/`。
- **隐藏属性完整清单是否还有第四项。** `Status` 上目前是道心 / 煞气 / 寿元三项；取值域、档位表与阈值见 `systems/services/plot-manager.md`。→ 见 `systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/_index.md`（待建）。
