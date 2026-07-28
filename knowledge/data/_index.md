# 数据索引（引用层）

> **内容即系统的字段 / 内嵌类型**——不单列内容层。**权威在 `game-design-documents/20-systems/`**（各内容类型的字段、schema、平衡数值）与 `20-systems/services/content-service.md`（管线、仓储接口、增量下载与签名的完整形状）。此处只留导航与承重纪律。规则：`.claude/rules/data-resource-rules.md`。

## 代码现状

**尚未编写任何内容。** `game-feature-branch/` 无 `.tres`、无 `XxxData : Resource` 类、无 `res://content/` 目录。下表是**规划**。

## 内容类型 → 权威位置

| 类型 | Resource 类（规划） | 权威设计位置（`20-systems/`） |
|------|--------------------|------------------------------|
| Card（卡牌） | `CardData` | `character-profile/deck/` |
| Relic / Joker（玩家能力） | `PlayerPowerData` | `player-profile/player-power/` |
| Enemy（敌人） | `EnemyData` | `adventure-event/combat/` |
| AdventureEvent（修行事件） | `AdventureEventData` | `adventure-event/`（拆入九个子类型） |
| 可购道具 | `ItemData` / `PlayerItemData` | `player-profile/player-item/`、`character-profile/item/` |
| Blind / Ante | `BlindData` | `game-progression.md` |
| 平衡配置 | `BalanceData` | `balance.md` |
| 剧本分支文本 | —（**不是**本地内容） | `services/plot-manager.md`——云端下发，不进 ContentRegistry、不落存档 |

## 承重纪律

1. **`Id` 是稳定唯一的字符串，也是唯一的交叉引用键。** 绝不按名称、数组下标或场景路径引用内容。
2. **抽取走 `AllEnabled()`。** 每个条目带共有字段 `ContentEnabled: bool`（默认 `true`），是线上灰度 / 分批放量 / 秒关开关。**关键的不对称**：**产出侧**（eventOptions 物化、商店库存、奖励掷骰）只从 `AllEnabled()` 抽；**读取侧** `Get(id)` / `TryGet` **不过滤**——存档引用到刚被关闭的条目仍须正确解析。不要自己写 `All().Where(x => x.ContentEnabled)`；漏写过滤即线上事故。
3. **`XxxData : Resource` 是模板不是成品，运行时绝不写它。** 它是注册表里的**共享只读单例**、可被 overlay 覆写；写回会污染同一轮回的后续批次与其他角色。
4. **「内容定义 + 情境 / 轮回内状态」= 两个类型：** `AdventureEventData` ↔ `EventOption`（物化定稿，**不可变**，落存档）、`CardData` ↔ `CardInstance`（运行态**可变**）。共享纪律：**服务签名里传实例，不传 `Resource`**。
5. **静态展示文案就留在 `XxxData` 上**（可本地化、可改而不破坏引用），不为「充血模型」另建并行展示类；动态组合走呈现期 ViewModel。**运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本——文案变更不触发存档迁移。
6. **校验点在合并之后。** overlay + 基线合并完再统一校验：重复 `Id`、悬空交叉引用 → 启动期 `GD.PushError`，早失败。**`ContentEnabled == false` 的条目照常参与全量校验**——它们是完整内容，只是不进抽取池。
7. **可调数值存导出字段 / `BalanceData`**，绝不硬编码在系统逻辑里。
8. **不散落 `ResourceLoader.Load`** ——一切内容经 ContentRegistry。

## 三层存储与热更边界（形状见 `services/content-service.md`）

```
res://content/**.tres     基线，随包发布，只读（保证首启可用 / 离线可读）
user://overlay/**.tres    云端下发的增量，可热更，按 Id 覆盖基线
      ↓ 合并（overlay 优先，res:// 兜底）→ 合并后统一校验
ContentRegistry（内存）    按 Id 索引，全游戏唯一读取入口
```

- **热更范围 = 只改不增。** overlay 只改既有条目的数值 / 文案，**不得新增 `Id`**——「存档引用未知内容」的风险从根上消失；代价是新内容只能随版本发布，放量靠翻 `ContentEnabled`。（**已否决**「预埋空壳 `Id` 日后填充」：与合并后强校验冲突，且属商店审核灰区。）
- **不冻结轮回的 `contentVersion`** ——overlay 更新对进行中的轮回立即生效，**放弃跨内容版本的 seed 可复现**。存档记 `StartContentVersion` / `LastContentVersion` 两个版本号以便归因。→ `standards/rng-determinism.md`、`standards/save-format.md`。
- **增量下载 = 文件级事务 + manifest 签名。** `overlay.staging/` 下载落地 → 全集校验通过 → 搬入 `overlay/` → **原子写 `overlay.manifest.json`（rename）= 提交点**；任一步失败即视为本次更新未发生。**永不存在半套 overlay**，与存档原子写同构。完整四步流程、重试退避、`failReason` 分类见 `services/content-service.md`。

## 本地 / 云端分界（一条判据）

| 判据 | 归属 |
|------|------|
| 有稳定 `Id`、**被存档引用**、需启动期校验 | **本地内容层**（`res://` + overlay），**含静态展示文案** |
| 按进度**动态请求**、一次性呈现、**不被存档引用** | **云端剧本服务**（AdventurePlot 分支文本），不进 ContentRegistry、不落存档 |

因此 **AdventureEvent 的定义本身属本地内容层**——启动期强校验模型成立。

> 仍待决（→ `open-questions.md`）：`ContentEnabled` 单一布尔不携带分桶信息，**灰度所需的分桶配置放哪**未定；disabled 条目被存档引用时是否提示玩家未定；`AllEnabled()` 纪律在代码评审外如何强制未定。
