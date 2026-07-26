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

## API 面（意图草图 · 签名待定）

- `RunCombat(character, encounter)` → 驱动一场完整战斗，产出 `CombatResult`（胜 / 负、剩余 life、战利品）。跨多帧，以 `await ToSignal(...)` / 信号推进，不阻塞。
- `PlayCard(cardInstance, target)` → 玩家出牌入口（由战斗屏幕的触控 / 拖拽调用）。
- `EndTurn()` → 玩家结束回合，移交 IntentManager。
- **事件面：** 回合开始 / 结束、卡牌结算、伤害 / 治疗、敌人意图揭示、战斗结束，经 EventBus 广播给 UI 与成就采集。

## 与其他服务的关系

```
life-cycle-service.AdvanceEvent(character, chosenEvent)
   └─ event.eventStart()
        └─▶ combat-service.RunCombat(character, encounter)   [eventType == Combat | Finale]
              ├─▶ content-service.ContentRegistry  按 Id 取 CardData / EnemyData
              ├─▶ profile-service.ProfileManager   一切状态写入
              └─▶ CombatResult
   └─ event.eventEnd()  → 由 life-cycle-service 收口结算
```

## 决策(-> ADR)

- **战斗模型 life + mana** → 见 `20-systems/adventure-event/combat/`、`20-systems/character-profile/mana.md`。
- **Finale 为独立事件类型（第七类）但复用战斗状态机** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题

- **与 `eventStart` / `eventEnd` 的职责边界。** Combat 事件的 `eventStart` 是直接把控制权交给本服务，还是本服务由 life-cycle-service 直接驱动？谁持有 `CombatResult` 并把它翻译成 Profile 变更未定。→ `20-systems/adventure-event/common-properties.md`、`life-cycle-service.md`。
- **Finale 的独立结算规则。** 复用回合循环已定，但区别于 Combat 的境界突破胜负条件 / 奖励结构未定。→ `20-systems/adventure-event/finale/`。
- **战斗内容全部未设计。** 卡牌定义与起始卡组、敌人与意图目录、遭遇战（encounter）编排、回合内的效果 / 状态系统、战斗中途存档是否支持 —— 均为空白。→ `20-systems/adventure-event/combat/`、`20-systems/character-profile/deck/`。
- **mana 逐步恢复速率 / 上限成长。** 每回合恢复量、`manaLimit` 随境界成长、更高境界 life / mana 基线未定。→ `20-systems/balance.md`。
- **enemies 归属。** 当前归 `adventure-event/combat/`；若 Practice 等也用敌人，是否升为共享内容层待确认。
- **战斗中途断线 / 退出的处理。** 强制在线下战斗过程是否落存档点，还是以事件为最小原子单位（中途退出 = 事件未结算）。→ `sync-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/combat-service.md`（引用层，待建）。
