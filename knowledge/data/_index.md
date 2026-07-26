# 数据索引（引用层）

> **内容即系统的字段 / 内嵌类型**（class-concept 化）——不单列内容层。本索引是**指向内容所在位置的引用**。Source: `game-design-documents/10-handoffs/2026-07-24-docs-restructure-class-model.md`。
>
> **权威设计意图（`20-systems/` 内的位置）：**
> | 内容类型 | 权威设计文档 |
> |----------|--------------|
> | Card（卡牌） | `20-systems/character-profile/deck/` |
> | Relic / Joker（玩家能力） | `20-systems/player-profile/player-power/` |
> | Enemy（敌人） | `20-systems/adventure-event/combat/` |
> | AdventureEvent（修行事件） | `20-systems/adventure-event/`（拆入各子类型） |
> | Event / 剧本 | `20-systems/services/plot-manager.md`（manager，隶属 future-event-service） |
> | Blind / Ante | `20-systems/game-progression.md` |
> | 可购道具 | `20-systems/player-profile/player-item/` |
> | 平衡配置 | `20-systems/balance.md` |

游戏内容即**数据**，以自定义 `Resource` 类的形式编写并序列化为 `.tres`，在启动时由 **content-service 的 ContentRegistry** 合并并按 `Id` 索引。规则：`.claude/rules/data-resource-rules.md`。目前尚未编写任何内容（全新脚手架）；本文件列出预期的内容类型与 schema 约定。

## 内容类型（预期）

| 类型 | Resource 类（规划中） | 关键字段 | 权威设计位置 |
|------|--------------------------|-----------|--------------|
| Card | `CardData` | `Id`、`Name`、`Description`、cost、rarity、效果定义、美术。 | `character-profile/deck/` |
| Relic / Joker（PlayerPower） | `RelicData` | `Id`、`Name`、`Description`、trigger(s)、效果、rarity。 | `player-profile/player-power/` |
| Enemy | `EnemyData` | `Id`、`Name`、HP、intent/行为表、美术。 | `adventure-event/combat/` |
| AdventureEvent | `AdventureEventData`（按子类型） | `Id`、类型、敌人 id 列表 / 选项、blind/奖励配置、ante 范围。 | `adventure-event/<子类型>/` |
| Event / 剧本 | `EventData` / plot | `Id`、提示文本、选项列表（每个含结果）、剧本 key points。**注意剧本分支文本不属本地内容层**——见下方分界。 | `services/plot-manager.md` |
| Blind / Ante | `BlindData` / ante 配置 | `Id`、要求、奖励、ante 缩放。 | `game-progression.md` |
| 平衡配置 | `BalanceData` | 可调的全局数值（每回合 mana、ante 缩放曲线、掉落权重）。 | `balance.md` |

## Schema 约定（强制）
- **`Id`** 是稳定、唯一的字符串，也是唯一的交叉引用键。绝不按名称、数组下标或场景路径引用内容。
- 显示字符串是**资源上的字段**（可本地化、可在不破坏引用的前提下变更）。**静态展示文案就留在 `XxxData` 上**——不为「充血模型」另建并行展示类；动态组合走呈现期 ViewModel。
- 跨类型引用使用 id（例如 `EncounterData.EnemyIds : string[]`）。**校验点在合并之后**（overlay + 基线合并完再统一校验）——重复 `Id`、悬空交叉引用是启动期的 `GD.PushError`，早失败。
- 可调数值存放于导出字段 / `BalanceData`，绝不硬编码在系统逻辑中。
- **运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本——文案变更不触发存档迁移。

## 存储三层与访问入口（已定案）

```
res://content/**.tres        基线内容，随版本发布，只读 → 保证首启可用 / 离线可读
user://overlay/**.tres       云端下发的增量，可热更，按 Id 覆盖基线
       ↓ 合并（overlay 优先，res:// 兜底）→ 合并后统一校验
ContentRegistry（内存）       按 Id 索引，全游戏唯一读取入口
```

- `res://content/manifest.json` 携带 `contentVersion` 与逐条目 hash；启动时 ContentUpdateManager 比对云端版本，有更新则下载增量到 `user://overlay/`。断网时跳过更新、直接用基线。
- **统一仓储接口**——ContentRegistry 为每种 `XxxData : Resource` 持有一个仓储，对外同一形状：

```csharp
IContentRepository<T> where T : Resource
    T        Get(string id);              // 必需：缺失 → PushError + 抛出
    bool     TryGet(string id, out T v);  // 可选：缺失 → 调用方降级
    IReadOnlyList<T> All();
    IEnumerable<T>   Where(Func<T,bool> predicate);
```

  所有服务经此取内容，**代码中不散落 `ResourceLoader.Load`**。新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目，不新增服务、不改调用方。

## 本地 / 云端分界（一条判据）

| 判据 | 归属 | 内容 |
|------|------|------|
| 有稳定 `Id`、**被存档引用**、需启动期校验 | **本地内容层**（`res://` + overlay） | `AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表——**含静态展示文案** |
| 按进度**动态请求**、一次性呈现、**不被存档引用** | **云端剧本服务** | AdventurePlot 的剧本分支文本与揭示内容；由 PlotManager 按 key points 请求，**不进 ContentRegistry、不落存档** |

因此 **AdventureEvent 的定义本身属本地内容层**——启动期强校验模型成立。

> 待决（见 `game-design-documents/20-systems/services/content-service.md`）：overlay 是否允许**新增 `Id`**（旧客户端存档会引用未知内容）；run 进行中 overlay 更新时是否需**冻结该 run 的 `contentVersion`** 以保证 seed 可复现。
