# combat-service（服务）

> 战斗驱动服务：回合循环、出牌结算、抽 / 弃 / 洗、敌人 AI 与意图（意图按**等级差三档揭示**）。**判据 ① —— 拥有自己的状态机与跨多帧的长流程。**
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **为何 Combat 需要独立服务，而其余八类不需要。** 九类 AdventureEvent 中**只有 Combat 真正拥有自己的状态机**——回合循环跨多帧推进、有独立的中间态（手牌、场上效果、敌人意图）。Practice / Research / Social / Explore / Exchange / Travel / Mystery 共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**，由通用结算器 + 数据驱动的 outcome / effect 定义承担。见 `_index.md` 的拆分轴。
- **Finale 复用本服务的状态机。** 境界突破是 Combat 的一个变体（独立的结算规则与胜负条件，但同一套回合循环），不另建服务。
- **战斗模型 = mana（出牌）+ 道念（计分与胜负）（已定案）。** 本服务维护**双方各自的道念（momentum）**作为胜负标尺：**道念高者胜**；`currentMana / manaLimit` 为出牌资源，mana **无曲线**、**每回合开始自动恢复至 `manaLimit`**。**`lifeTotal / lifeTotalLimit` 在战斗过程中不被读写**——失败时才在结算时刻按「角色道念 − 敌人道念」的差值扣减 lifeTotal。炼气基线 lifeTotal 10/10、mana 5/5。见 `20-systems/scoring.md`、`20-systems/character-profile/life-total.md`、`mana.md`、`20-systems/adventure-event/combat/`。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **战斗是定长的：固定 10 个回合（已定案 · 答结道念模型的首要缺口）。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，交替进行），随后比道念、高者胜。**不设提前终止**（无道念阈值胜利、不以卡组耗尽终止）。**推论：TurnManager 是一个固定长度的循环**（`for turn in 1..10`）而非动态终止判定——状态机形状因此确定，且每场战斗的时间开销可预测。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **平局 = 只发基础奖励（已定案）。** 10 回合打满后道念相等时：**不判负、不扣 lifeTotal**，玩家**只获得该事件的基础奖励**（道念差为 0，故无任何厚度加成）。因此 `CombatOutcome` 需要第三个胜负态 `Draw`，且它在结算上落在「胜利侧的最薄一档」——与「道念差是双向刻度」自洽：差值为 0 就是两侧都不加码的那个原点。Source: 同上。
- **道念的运行态骨架（已定案）。** 战斗开始时本服务为双方各置一个**起始道念 = `baseMomentum`（按各自全局等级，表见 `20-systems/balance.md`）**；此后道念**由打出的卡牌产出**，且卡牌**可削减对方道念**，**削减在 0 处截断**（无负道念）。**推论：等级差在开局即转化为道念差**，越级挑战的压力有了确切量纲。Source: 同上。
- **战斗内的一切写入经 ProfileManager。** 耗 mana、消耗道具、获得战利品、以及**结算时按道念差扣 lifeTotal** 都走 `profile-service.ProfileManager.TryApply(...)`——本服务不直接改 CharacterProfile 字段。**道念本身是战斗内的运行态**（活在 `CombatSnapshot` 里），战斗结束即消失，不落 CharacterProfile。
- **敌人意图三档揭示，分界值已给全（已定案）。** **默认揭示，越级才降级**——不是 Slay the Spire 式的常驻免费预告，也不是全盘隐藏。判据分两层：**先看是否越阶，再看同阶差值**（`diff` = 敌人全局等级 − 角色全局等级）：

  | 情形 | 玩家看到 |
  |---|---|
  | **越阶**（敌人境界高于角色） | **完全无信息** —— 不论 `diff` 多小 |
  | 同阶、`diff ≤ 0` | **完整意图**：动作类型 + 精确数值 |
  | 同阶、第一篇章 `diff` 1–2 | **仅类别**：攻击 / 防御 / 增益 / 特殊——有符号无数值 |
  | 同阶、第一篇章 `diff ≥ 3` | **完全无信息**，且**不提供任何替代线索** |
  | 同阶、第二 / 第三篇章 `diff = 1` | **仅类别** |
  | 同阶、第二 / 第三篇章 `diff ≥ 2` | **完全无信息** |

  **「越阶 = 黑箱」是一道硬门**：它把「境界鸿沟」从数值差提升为结构性规则——炼气十三层对上筑基初期（全局仅差 1）同样是彻底黑箱。**这推翻了先前的「篇章容差」表述**（ch1 差 > 3 才降级）：ch1 现在差 1 即降一档，差 3 即彻底黑箱。**不做「敌人状态可读」的补偿**。呈现侧见 `40-ux/combat-ux.md`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **探查（probe）是意图之外的第二条信息通道。** 意图揭示档位由等级差**被动**决定；**探查**则是玩家**主动付出代价换取当回合敌人意图**的效果。方向已定、定名已成，**具体形态（花费形式 / 授予途径 / 可探查档位）归卡牌与技能内容的横向扩展阶段，本阶段搁置**。「某些能力或道具授予窥视意图」即探查能力的授予形式。Source: 同上。
- **意图不单列 manager。** 意图生成隶属 **EnemyManager**，与敌人实例状态、AI 行为选择同属一个组件——三者共享同一份敌人运行态，拆开只会让它们互相伸手。**EnemyManager 内部不再细分职能（已定案）。** Source: `10-handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md` + `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **CharacterManager 与 EnemyManager 平级、共享接口、驱动方式相反（已定案）。** 两者管理战斗的两侧参战方，**共有大量接口定义**（生命 / mana、卡组、状态、出牌）；差异只在**谁驱动决策**——EnemyManager 含**代理操作**（AI 行为选择、意图生成），CharacterManager **监听玩家操作**。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **每个参战方各有一个 `DeckModule`（已定案）。** 卡组不是全局单件：**每个 character、每个 enemy 各持有一个**，由 CharacterManager / EnemyManager 各自持有。**敌人也出牌**，且可带定制卡组（例如 Finale 的天劫，以及 `EnemyTemplate` 的样本卡组经物化改写而来）。`DeckModule` 是**第三级抽象（module）**，不列入本服务的 manager 清单——层级词表见 `20-systems/architecture.md`。Source: 同上 + `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **Practice / Finale 复用本服务的参战方结构。** 两者都用 EnemyManager + CharacterManager，是 Combat 的**变体**（同一套回合循环与参战方模型，独立的胜负条件与奖励结构）。见 `20-systems/adventure-event/practice/`、`finale/`。Source: 同上。
- **事件过程按决策点落存档（已定案）。** 战斗**不是**存档盲区：事件过程中（含战斗内）在**决策点**落存档，使「退出重进」得到的是同一个局面与同一份 RNG 状态。**`selectCost` 不回滚**——选中事件时施加的成本（含 `lifeSpanCost`）一经施加即成事实。**决策点的具体粒度未定**，见待决问题。Source: 同上。
- **确定性。** 洗牌、敌人行为掷骰等一律用 `life-cycle-service.SeedManager` 派生的 **combat 子流**，与地图 / 商店 / 奖励子流隔离，避免 desync。同一 seed 必须复现同一场战斗。

## 管理器

| manager | 职责 |
|---------|------|
| **TurnManager** | **定长 10 回合**的状态机（双方各 5 个回合，交替）：回合开始（mana 恢复至上限）→ 抽牌 → 出牌 → 结算 → 交给另一方；10 回合打满后做**「道念高者胜」的胜负判定**（相等 = `Draw`，只发基础奖励） |
| **CharacterManager** | 玩家侧参战方：角色的对战状态、其卡组、出牌通道；**监听玩家操作** |
| **EnemyManager** | 敌人侧参战方：敌人实例与状态、其卡组、**AI 行为选择与意图（intent）生成**；**代理操作**。内部不再细分职能 |

**`DeckModule`（第三级）不是平级 manager。** 抽牌堆 / 手牌 / 弃牌堆的流转与 seeded 洗牌由 CharacterManager 与 EnemyManager 各自持有的 `DeckModule` 承担，**每个 character / enemy 一份**。它与那套共享的参战方接口是同一件事的两面。

## API 面（契约）

> 总则与共享类型见 `20-systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界；`RunCombatAsync` 是形态 C（跨多帧、由信号推进），其余为形态 A。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 打一场 | **C** | `Task<CombatResult> RunCombatAsync(EncounterSpec encounter, CancellationToken ct)` | 未知 `EncounterId` = 坏数据 → `PushError` + 抛；胜负是**结果**不是失败 |
| 出牌 | A | `PlayResult PlayCard(CardInstance card, TargetRef target)` | 业务失败（mana 不足、目标非法）→ `PlayResult`，绝不抛 |
| 结束回合 | A | `void EndTurn()` | — |
| 战斗态 | A | `CombatSnapshot Snapshot { get; }` | 只读视图，供 ViewModel 组装；**必含双方道念** |

```csharp
public readonly record struct EncounterSpec(string EncounterId, bool IsFinale);
public readonly record struct CombatResult(
    CombatOutcome     Outcome,            // Victory | Draw | Defeat | Fled（Draw = 道念相等，只发基础奖励）
    int               CharacterMomentum,  // 结算时角色道念（10 回合打满后）
    int               EnemyMomentum,      // 结算时敌方道念；二者之差：胜 → 奖励厚度，负 → lifeTotal 扣减
    int               RemainingLifeTotal, // 结算扣完之后剩余的 lifeTotal（非「战斗中掉剩的血」）
    ProfileChangeSpec Spoils);            // 战利品以 spec 形式回吐，由 life-cycle 经 ProfileManager 施加
// ⟨待定：EncounterSpec / CombatSnapshot / TargetRef / PlayResult 的完整字段——依赖「战斗内容全部未设计」⟩
```

- **`CombatSnapshot` / `PlayResult` 必须承载道念（已定案）。** 胜负标尺是道念，故战斗态视图与出牌结果**都要能表达道念的当前值与本次变化量**——否则 `40-ux/combat-ux.md` 的「双方道念对比」主视觉无数据可读。具体字段依赖战斗内容设计。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

- **`RunCombatAsync` 收 `EncounterSpec` 而非 `CharacterProfile`**：当前角色是 life-cycle-service 状态机的持有物，本服务经 `ProfileService.Instance` 读写，不接收角色参数。
- **`CardData` ↔ `CardInstance` 是「模板 ↔ 运行时实例」的另一半**（另一半是 `AdventureEventData` ↔ `EventOption`）：签名里**传实例，不传 `Resource`**；区别在于 `CardInstance` 运行态**可变**（手牌中的临时增益），而 `EventOption` 产出即定稿不可变。见 `20-systems/architecture.md` 总则 6。
- **`CombatResult.Spoils` 是 `ProfileChangeSpec` 而非「已写好的变更」（已定案）。** 本服务只**描述**结果；life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。战斗**过程中**的血 / mana 变更仍即时经 ProfileManager；`Spoils` 只承载收口产出。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CombatTurnStarted` / `CombatTurnEnded` | `(int TurnIndex)` |
| `CardResolved` | `(string CardInstanceId, string CardId)` |
| `CombatFinished` | `(CombatOutcome Outcome, int CharacterMomentum, int EnemyMomentum, int RemainingLifeTotal)` |

`CardResolved` 在战斗内每张牌都广播，是热路径——故负载为 `readonly record struct` 且**只带 `Id`**，不带 `CardInstance` 引用（EventBus 走 C# 泛型事件而非 Godot `[Signal]` 的直接动因，见总则 5）。

## 与其他服务的关系

```
life-cycle-service.AdvanceEventAsync(eventOption, mode, ct)
   ├─ 【eventStart 阶段】选 resolver
   ├─ CombatEventResolver.ResolveAsync(option, ct)          [eventType == Combat | Finale]
   │     └─▶ combat-service.RunCombatAsync(encounter, ct)
   │           ├─▶ content-service.ContentRegistry  按 Id 取 CardData / EnemyData
   │           ├─▶ profile-service.ProfileManager   战斗过程中的即时写入
   │           └─▶ CombatResult（Outcome + 双方道念 + RemainingLifeTotal + Spoils:ProfileChangeSpec）
   └─ 【eventEnd 阶段】Spoils + lifeSpanCost + 隐藏属性推拉 → **一次** TryApply → 一个存档点
```

## 决策(-> ADR)

- **战斗模型 = mana + 道念；胜负 = 道念高者胜；失败按道念差扣 lifeTotal** → 见 `20-systems/scoring.md`、`20-systems/adventure-event/combat/`、`20-systems/character-profile/life-total.md`、`mana.md`。**ADR 候选。**
- **战斗定长 = 10 个回合（双方各 5）；起始道念 = `baseMomentum`；道念可互削、下限 0** —— 已定案。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **意图分档 = 越阶硬门 + 同阶差值门槛** —— 已定案（推翻篇章容差表述）。Source: 同上。
- **Finale 为独立事件类型（第七类）但复用战斗状态机** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题

- **意图类别的枚举。** 第二档要展示的粒度是「攻击 / 防御 / 增益 / 特殊」，其正式枚举与敌人行为的映射未定。→ `20-systems/adventure-event/combat/`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **决策点的粒度。** 「事件过程按决策点落存档」已定，但战斗内的决策点具体指哪些位置（每回合开始？每次出牌后？每次目标选择后？）未定；粒度直接决定本地写入频率与 push 防抖压力。→ `sync-service.md`。Source: 同上。
- **`attemptIndex` 是否还需要。** 既定的战斗内 RNG 派生式 `Hash64(combatStreamSeed, eventId, attemptIndex)` 是为防「退出重进重掷」；**决策点存档 + RNG `State` 持久化已从根上关闭该窗口**。剩下的问题收窄为：篇章重试（ADR-0004）重开同一篇章时，同名事件是否应换一套战斗随机——若应则 `attemptIndex` 取「篇章重试的第几次」，若不应则该派生层可整个去掉。→ `20-systems/common-properties.md`、`life-cycle-service.md`。Source: 同上。
- **Finale 的独立胜负条件与奖励结构。** 「Finale 是战斗变体、天劫为带定制卡组的 Enemy」已定；区别于 Combat 的胜负判定与奖励结构未定，少部分非战斗形态的 Finale 亦待日后定制。→ `20-systems/adventure-event/finale/`。
- **`CombatSnapshot` / `PlayResult` 的道念字段形态。** 产出途径已定（卡牌，可互削，下限 0），但这两个类型该带什么（当前值 + 本次增量？分来源？对方的削减量？）仍依赖卡牌内容设计。→ `20-systems/character-profile/deck/`。Source: 同上。
- **道念差 → lifeTotal 损失 / 奖励厚度的换算公式。** 结算量由谁计算（本服务算好写进 `Spoils`，还是 life-cycle 依 `CombatResult` 的双方道念算）？公式本身归 `20-systems/balance.md`，**归属边界未定**。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + 同上。
- **`EncounterSpec` 如何承载物化后的敌人。** 敌人等级 / 卡组由 future-event-service 在物化时确定，故 `EncounterSpec` 需要携带**物化后的敌人实例**（或其引用），而非只带一个 `EncounterId` 让本服务回查模板——具体形态未定。→ `future-event-service.md`。Source: 同上。
- **战斗内容全部未设计。** 卡牌定义与起始卡组、敌人与意图目录、遭遇战（encounter）编排、回合内的效果 / 状态系统 —— 均为空白。→ `20-systems/adventure-event/combat/`、`20-systems/character-profile/deck/`。
- **`manaLimit` 的推拉分档。** 「每回合恢复至上限、`manaLimit` 由事件 cost / reward 推拉」已定；哪些事件推高 / 压低、幅度分档未定。→ `20-systems/balance.md`、`20-systems/character-profile/mana.md`。
- **enemies 归属。** 当前归 `adventure-event/combat/`；Practice 与 Finale 均已确认使用敌人（天劫即 Enemy），是否升为共享内容层待确认。

## 对应
提炼至：`.claude/knowledge/systems/combat-service.md`（引用层，待建）。
