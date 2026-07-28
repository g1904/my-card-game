# combat-service（服务）

> 战斗驱动服务：回合循环、出牌结算、抽 / 弃 / 洗、敌人意图。**判据 ① —— 拥有自己的状态机与跨多帧的长流程。**
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **为何 Combat 需要独立服务，而其余八类不需要。** 九类 AdventureEvent 中**只有 Combat 真正拥有自己的状态机**——回合循环跨多帧推进、有独立的中间态（手牌、场上效果、敌人意图）。Practice / Research / Social / Explore / Exchange / Travel / Mystery 共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**，由通用结算器 + 数据驱动的 outcome / effect 定义承担。见 `_index.md` 的拆分轴。
- **Finale 复用本服务的状态机。** 境界突破是 Combat 的一个变体（独立的结算规则与胜负条件，但同一套回合循环），不另建服务。
- **战斗模型 = life + mana**（参考 MTG / Hearthstone）：`currentHealth / healthLimit`、`currentMana / manaLimit`，mana **无曲线**，采用「上限 + 逐步恢复」。炼气基线 life 10/10、mana 5/5。见 `20-systems/character-profile/life.md`、`mana.md`、`20-systems/adventure-event/combat/`。
- **战斗内的一切写入经 ProfileManager。** 扣血、耗 mana、消耗道具、获得战利品都走 `profile-service.ProfileManager.TryApply(...)`——本服务不直接改 CharacterProfile 字段。
- **确定性。** 洗牌、敌人行为掷骰等一律用 `life-cycle-service.SeedManager` 派生的 **combat 子流**，与地图 / 商店 / 奖励子流隔离，避免 desync。同一 seed 必须复现同一场战斗。

## 管理器

| manager | 职责 |
|---------|------|
| **TurnManager** | 回合状态机：回合开始 → 抽牌 → 玩家出牌 → 结算 → 敌人行动 → 回合结束；胜 / 负判定 |
| **DeckManager** | 抽牌堆 / 手牌 / 弃牌堆的流转；seeded 洗牌；卡牌实例生命周期 |
| **IntentManager** | 敌人意图生成与展示、敌人 AI 行为选择 |

## API 面（契约）

> 总则与共享类型见 `20-systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界；`RunCombatAsync` 是形态 C（跨多帧、由信号推进），其余为形态 A。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 打一场 | **C** | `Task<CombatResult> RunCombatAsync(EncounterSpec encounter, CancellationToken ct)` | 未知 `EncounterId` = 坏数据 → `PushError` + 抛；胜负是**结果**不是失败 |
| 出牌 | A | `PlayResult PlayCard(CardInstance card, TargetRef target)` | 业务失败（mana 不足、目标非法）→ `PlayResult`，绝不抛 |
| 结束回合 | A | `void EndTurn()` | — |
| 战斗态 | A | `CombatSnapshot Snapshot { get; }` | 只读视图，供 ViewModel 组装 |

```csharp
public readonly record struct EncounterSpec(string EncounterId, bool IsFinale);
public readonly record struct CombatResult(
    CombatOutcome     Outcome,        // Victory | Defeat | Fled
    int               RemainingHealth,
    ProfileChangeSpec Spoils);        // 战利品以 spec 形式回吐，由 life-cycle 经 ProfileManager 施加
// ⟨待定：EncounterSpec / CombatSnapshot / TargetRef / PlayResult 的完整字段——依赖「战斗内容全部未设计」⟩
```

- **`RunCombatAsync` 收 `EncounterSpec` 而非 `CharacterProfile`**：当前角色是 life-cycle-service 状态机的持有物，本服务经 `ProfileService.Instance` 读写，不接收角色参数。
- **`CardData` ↔ `CardInstance` 是「模板 ↔ 运行时实例」的另一半**（另一半是 `AdventureEventData` ↔ `EventOption`）：签名里**传实例，不传 `Resource`**；区别在于 `CardInstance` 运行态**可变**（手牌中的临时增益），而 `EventOption` 产出即定稿不可变。见 `20-systems/architecture.md` 总则 6。
- **`CombatResult.Spoils` 是 `ProfileChangeSpec` 而非「已写好的变更」（已定案）。** 本服务只**描述**结果；life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。战斗**过程中**的血 / mana 变更仍即时经 ProfileManager；`Spoils` 只承载收口产出。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CombatTurnStarted` / `CombatTurnEnded` | `(int TurnIndex)` |
| `CardResolved` | `(string CardInstanceId, string CardId)` |
| `CombatFinished` | `(CombatOutcome Outcome, int RemainingHealth)` |

`CardResolved` 在战斗内每张牌都广播，是热路径——故负载为 `readonly record struct` 且**只带 `Id`**，不带 `CardInstance` 引用（EventBus 走 C# 泛型事件而非 Godot `[Signal]` 的直接动因，见总则 5）。

## 与其他服务的关系

```
life-cycle-service.AdvanceEventAsync(eventOption, mode, ct)
   ├─ 【eventStart 阶段】选 resolver
   ├─ CombatEventResolver.ResolveAsync(option, ct)          [eventType == Combat | Finale]
   │     └─▶ combat-service.RunCombatAsync(encounter, ct)
   │           ├─▶ content-service.ContentRegistry  按 Id 取 CardData / EnemyData
   │           ├─▶ profile-service.ProfileManager   战斗过程中的即时写入
   │           └─▶ CombatResult（Outcome + RemainingHealth + Spoils:ProfileChangeSpec）
   └─ 【eventEnd 阶段】Spoils + lifeSpanCost + 隐藏属性推拉 → **一次** TryApply → 一个存档点
```

## 决策(-> ADR)

- **战斗模型 life + mana** → 见 `20-systems/adventure-event/combat/`、`20-systems/character-profile/mana.md`。
- **Finale 为独立事件类型（第七类）但复用战斗状态机** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题

- **Finale 的独立结算规则。** 复用回合循环已定，但区别于 Combat 的境界突破胜负条件 / 奖励结构未定。→ `20-systems/adventure-event/finale/`。
- **战斗内容全部未设计。** 卡牌定义与起始卡组、敌人与意图目录、遭遇战（encounter）编排、回合内的效果 / 状态系统、战斗中途存档是否支持 —— 均为空白。→ `20-systems/adventure-event/combat/`、`20-systems/character-profile/deck/`。
- **mana 逐步恢复速率 / 上限成长。** 每回合恢复量、`manaLimit` 随境界成长、更高境界 life / mana 基线未定。→ `20-systems/balance.md`。
- **enemies 归属。** 当前归 `adventure-event/combat/`；若 Practice 等也用敌人，是否升为共享内容层待确认。
- **战斗中途断线 / 退出的处理。** 强制在线下战斗过程是否落存档点，还是以事件为最小原子单位（中途退出 = 事件未结算）。**这与 `RunCombatAsync` / `AdvanceEventAsync` 的 `CancellationToken` 取消语义是同一个问题的两面**：取消后已施加的 `SelectCost` 如何处置（回滚？视同结算？）。→ `sync-service.md`、`life-cycle-service.md`。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

## 对应
提炼至：`.claude/knowledge/systems/combat-service.md`（引用层，待建）。
