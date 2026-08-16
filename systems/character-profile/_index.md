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
- **CharacterProfile 的字段（大局骨架，细节未定）。** `status`（**ongoing | defeated | completed**）、`chapter`（当前篇章）、**`realm` + `level`（境界与境界内等级，见 `systems/game-progression.md`）**、`Status`（**`lifeTotal`（单值，无上限字段）**、`currentMana / manaLimit`、`experiencePoint`，以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan）、**`pastEvent`（修行历程，`IReadOnlyList<PastEventEntry>`）**、**`activeCombat`（可空，进行中战斗的中间态）**、**`disabledAbility`（本轮回禁用表，见下）**、角色级道具（见 `item/`）、角色能力 `List<CharacterPower>`（见 `power/`）、轮回货币 jade（见 `currency.md`），以及 **AdventurePlot key points**（剧情进度锚点；剧本正文不落存档，作为本地内容条目经 ContentRegistry 读取——**key point 必须可独立解析、其剧本节点缺失时可安全跳过**，见 `systems/services/plot-manager.md`）。
- **`realm` + `level` 是角色的修行位置。** 二者合成**全局等级序**上的位置，是敌人赋级 `±2` 带与 `baseMomentum` 起跑线的判据；篇章突破后 `level` 归位为新境界的初期。**`manaLimit` 不随境界自动成长**，由事件 cost / reward 推拉（见 `mana.md`）。
- **决策点存档。** 事件推进过程中（含战斗内）在**决策点**落存档，使退出重进恢复到同一局面与同一份 RNG 状态；`selectCost` **不回滚**。存档点清单见 `systems/services/life-cycle-service.md`；**战斗内的 D0–D6 决策点清单见 `systems/services/combat-service.md`**。
- **`activeCombat`：进行中战斗的中间态（CharacterProfile 上的可空块）。** 战斗开始时创建、`eventEnd` 收口时**置空**；**不进 `pastEvent`**（历史事件只留定稿快照），也不与 `Rng.Streams[]` 混住——它是**事件内的中间态，寿命短于一次事件**。
  - **为什么挂 CharacterProfile 而非独立的战斗存档实体**：与「每篇章至多一个 ongoing」自洽，且 diff 天然落在 `CharacterProfile` 粒度（sync-service 的既定 diff 单位），**无需新增同步单元**。
  - 内容 = 遭遇参数 + 回合 / 步状态 + 战斗子流 RNG + 两个参战方（含三区 `Id` 序列与 `CardInstance` 运行态）+ 战场条目 + 栈条目 + 挂起态。**完整 schema 与读档校验归 `systems/services/combat-service.md`**（本文件只登记它是 CharacterProfile 的一个字段）。
  - 随 `activeCombat` 一起 **bump schema 版本**（当前无线上存档 → 空迁移）。
- **`pastEvent`：修行历程 = `IReadOnlyList<PastEventEntry>`。** 元素**不是 `Resource`**——存的是**定稿实例快照 + 本次结算的最终账**，这是物化模型的直接推论（`AdventureEventData` 是 ContentRegistry 的共享只读单例，痕迹要记的是「这一次走过的那个实例」）。
  - **条目形态 `PastEventEntry`（13 字段）、判据「重算不出来的存」、未选项轻摘要 `UnchosenOptionRef`、`EventOutcome` 四值枚举与加载时校验，权威在 `systems/adventure-event/common-properties.md`**（本文件只登记它是 CharacterProfile 的一个字段）。
  - **只追加、不修改既有条目**（不变式）；体积护栏与 diff 友好性见 `systems/services/sync-service.md`。
  - **写入经 life-cycle-service 组装 → `profile-service.ProfileManager`**，与「档案写入的唯一入口」一致。
  - 随本次结构落定 **bump schema 版本**（当前无线上存档 → 空迁移）。
- **`chapterRetry`：篇章重试计数器。** 一个**类**，计数第一 / 第二 / 第三篇章各自的重试次数——**因为 ch2 与 ch3 有重试上限**（无限 / 3 / 1，持 premium bundle 为 无限 / 9 / 3，见 ADR-0004）。**它是计数器容器，不是上限持有者**：上限仍按 ADR-0004 的既定纪律读取（可被账号级持有状态改写、凡读取处不得硬编码常量），`chapterRetry` 只答「用掉了几次」。**推论：篇章解锁 / 重新锁定与「剩余重试次数展示」有了确定的数据源。**
  - **形态 = 三个具名字段**，第一 / 第二 / 第三篇章各一，**不是字典也不是按索引的数组**。**与「四境三篇章」这条硬事实对齐**（篇章数是游戏结构，不是可扩展列表）：具名字段让存档 schema 显式、读取处不必处理「键不存在」的分支，也免去按索引访问的越界校验。**代价是新增篇章需改 schema——但篇章数不是设计变量。**
  - **通关后保留计数，不清零** ⇒ **它是历史，不只是配额**。一个通关角色身上留着「我在筑基段挣扎了 3 次」的记录，可供元进程界面的角色履历展示；**同时它简化实现**——没有清零时机就没有「何时清零」的边界情形。
  - **ch1 的角色级计数恒为 0，这不是缺陷。** ch1 重试 = 随机生成新角色，故角色级 ch1 计数对每个新角色恒为 0。**「你在炼气段重开了多少次」目前没有字段回答**——账号级统计的首批只有 `TotalCyclesCompleted` / `TotalCyclesDefeated`，后者不区分篇章（见 `systems/player-profile/_index.md`）。这是一个**展示需求**，需要时在 `PlayerStatistics` 上纯加法补一项即可（统计层新增字段零迁移、零后端配合）。**两层口径不同，不是同一个数的两份拷贝**：角色级参与闸门判定，账号级只被读来看。
  - **连带：`attemptIndex` 派生层整层删除**（篇章重试 = 换一套随机流，见 `systems/common-properties.md`）。
- **`disabledAbility`：本轮回禁用表**（与 `pastEvent` / `chapterRetry` / `activeCombat` 平级）。**法则不被强制剥夺，其余一律降级为本轮回禁用**——本字段是这条语义的承载面，覆盖**四类**能力条目（神通 / 法则 / 法宝 / 古宝）。
  - **不落 `Status` 内。** `Status` 装的是**数值型运行状态**（`lifeTotal` / `currentMana` / `experiencePoint` / 隐藏属性），禁用表是**集合型 build 状态**，与 deck、神通持有列表同层。

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
  - **写入并入 `eventEnd` 那一次 `TryApply`**（band 在组装 spec 时按「前值 + `AppliedChange`」算出**绝对值**，不是相对增量）⇒「一个事件 = 一次事务 = 一个存档点」原样成立，**不新增存档点、不新增结算阶段**。
  - **不进 `PastEventEntry`**：band 设值已在 `AppliedChange` 内、可重放，按判据「重算得出来的不存」⇒ 快照不加字段。
  - **`ChapterLifeSpanBudget` 随该篇章起始存档带回**（篇章重试时同理），故它对读档与重试都是确定值。
  - 档位表本身、阈值 / 回滞 δ 与跨档叙事规则归 `systems/services/plot-manager.md`。
  - 随本次落定 **bump schema 版本**（当前无线上存档 → 空迁移）。
- **RNG 状态与内容版本落在 CharacterProfile 上。** 新增三组字段，随本次存档 **schema bump**（当前无线上存档 → 空迁移，但迁移骨架就此立起）：

  | 字段 | 类型 | 语义 |
  |------|------|------|
  | `StartContentVersion` | `string` | 轮回开始时生效的内容版本，**写一次不再变** |
  | `LastContentVersion` | `string` | **每个自动存档点**更新为当时生效的版本；与上一字段不等 = 该轮回跨过内容更新（数值突变类反馈的第一判据） |
  | `Rng.CycleSeed` | `ulong` | 轮回开始时生成，不变 |
  | `Rng.Streams[]` | `Name` / `Seed` / `State` / `DrawCount`（`string` / `ulong` / `ulong` / `int`） | 具名子流状态；`State` 为恢复权威字段，`DrawCount` 为诊断与迁移保险 |

  schema 形态：

  ```jsonc
  "rng": {
    "CycleSeed": 12345678901234567890,        // u64，轮回开始时生成，不变
    "streams": [
      { "name": "map",    "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "combat", "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "shop",   "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "reward", "seed": 0, "state": 0, "drawCount": 0 }
    ]
  }
  ```

  派生规则与恢复语义见 `systems/common-properties.md`；双 `contentVersion` 的诊断用途见 `systems/services/content-service.md`。
- **角色状态是终态收敛的状态机。** `status` 收敛为 `ongoing | defeated | completed`（`defeated` 的三种原因：discarded / 寿元归 0 / lifeTotal 归 0）；`defeated` 与 `completed` 数据都会在轮回结束时被清理。→ 见 `systems/services/life-cycle-service.md` 与 `decisions/ADR-0004-realm-checkpoint-retry-model.md`。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md`

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
- **CharacterProfile 字段结构细节：** 各字段的具体 schema、**隐藏属性完整清单是否还有第四项**、AdventurePlot key points 粒度仍待定。（**隐藏属性的取值域、档位表与阈值已定案**，见 `systems/services/plot-manager.md`。）→ 见 `systems/services/life-cycle-service.md`、`systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/_index.md`（待建）。
