# content-service（服务）

> 内容资产服务：`res://` 基线 + `user://overlay/` 热更层的合并、按 `Id` 索引、统一仓储接口。**判据 ③ —— 外部 I/O 边界（内容版本比对与下载）+ 启动流程。**
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 存储形态：三层（已定案）

```
res://content/**.tres        基线内容，随版本发布，只读
                             → 保证首启可用、离线可读
user://overlay/**.tres       云端下发的增量，可热更，按 Id 覆盖基线
       ↓ 合并（overlay 优先，res:// 兜底）
ContentRegistry（内存）       按 Id 索引，全游戏唯一内容读取入口
```

- `res://content/manifest.json` 携带 **`contentVersion`** 与逐条目 hash。启动时 ContentUpdateManager 比对云端版本，有更新则下载增量到 `user://overlay/`。
- **校验点在合并之后。** 重复 `Id`、悬空交叉引用（如某遭遇战列出未知敌人 `Id`）→ `GD.PushError` **启动期早失败**。热更并未削弱这条纪律，只是把校验点从「加载 `res://` 后」后移到「合并完成后」。
- **断网降级：** 跳过更新，直接使用 `res://` 基线 —— **首启不依赖网络下载内容**（但进入游戏仍需登录）。
- **收益：** 平衡数值、事件定义、卡牌数值**可热更而不发版**，规避微信 / App Store 审核周期；同时保留启动期强校验与离线首启能力。

### 统一操作接口（已定案）

ContentRegistry 为每种 `XxxData : Resource` 持有一个仓储，对外是**同一形状**：

```csharp
IContentRepository<T> where T : Resource
    T                Get(string id);              // 必需：缺失 → PushError + 抛出
    bool             TryGet(string id, out T v);  // 可选：缺失 → 调用方降级
    IReadOnlyList<T> All();
    IEnumerable<T>   Where(Func<T,bool> predicate);
```

**所有服务经此取内容；代码中不散落 `ResourceLoader.Load`。** 新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目，**不新增服务、不改调用方**——这正是「同类内容的统一入口与标准操作接口」这一诉求的正确落点（而非按内容类型各开一个服务，见 `_index.md` 的拆分轴）。

### 本地 / 云端内容分界（已定案）

一条判据划清：

| 判据 | 归属 | 内容 |
|------|------|------|
| 有稳定 `Id`、**被存档引用**、需启动期校验 | **本地内容层**（`res://` + overlay） | `AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表 —— **含静态展示文案** |
| 按进度**动态请求**、一次性呈现、**不被存档引用** | **云端剧本服务** | AdventurePlot 的剧本分支文本与揭示内容（见 `plot-manager.md`） |

因此 **AdventureEvent 的定义本身属本地内容层**，ContentRegistry 的启动期强校验模型成立；云端剧本服务只下发文本，不进 ContentRegistry、不落存档。

## 管理器

| manager | 职责 |
|---------|------|
| **ContentRegistry** | 合并 overlay + 基线，按 `Id` 建立索引，暴露泛型仓储接口；合并后统一校验 |
| **ContentUpdateManager** | 读本地 manifest、比对云端 `contentVersion`、下载增量到 `user://overlay/`、断网降级 |

## API 面（意图草图 · 签名待定）

- `CheckAndUpdate()` → 比对版本并下载增量；返回是否有更新、失败原因。
- `LoadAll()` → 合并加载并校验；失败以 `GD.PushError` + 定位 `Id` 早失败。
- `Repo<T>()` → 取某内容类型的仓储；玩法代码经它按 `Id` 查内容。
- **事件面：** 内容更新完成 / 失败、校验失败明细，经 EventBus 广播给启动流程 / UI。

## 决策(-> ADR)

- **内容载体形态（随包基线 + user:// 覆盖层 + 云端版本校验）** → 已定案，**ADR 候选**（待固化）。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- 云端下发依赖 **强制在线 · 云端权威** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **热更范围边界。** overlay 可覆盖哪些字段？允许热更**新增** `Id`（新卡 / 新事件）还是仅允许改既有条目的数值 / 文案？新增 `Id` 会让旧版本客户端的存档引用到未知内容，需要一条兼容规则。
- **overlay 与存档的版本耦合（确定性张力）。** 若某个 run 进行中 overlay 被更新（数值变了），进行中的 CharacterProfile 是否需要**冻结其 `contentVersion`** 以保证 seed 可复现？「同一 seed 复现同一 run」的要求与热更存在张力。→ `20-systems/common-properties.md`。
- **增量下载的粒度与失败恢复。** 逐文件 hash 比对还是整包版本？下载中断后的续传 / 回滚（避免半套 overlay）未定。
- **overlay 的完整性校验与防篡改。** `user://` 可被玩家改写；是否需要签名校验，还是 PvE-only 下可容忍。

## 对应
提炼至：`.claude/knowledge/systems/content-service.md`（引用层，待建）。
