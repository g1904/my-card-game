# program-overview —— 程序运行总览

> **这份文档回答「代码跑起来是什么样」。** 从进程启动到轮回结束的端到端调用链、服务 / 管理器职责矩阵、内容与存档的加载路径。
>
> 结构与边界的**权威**在 `20-systems/architecture.md`；本文件是它的**运行时视角**对照面。工程落地形态（进程边界、文件夹布局、autoload 注册、代码形态）见 `system-overview.md`。术语权威在 `terminology.md`。
>
> **注意：** 下文的「服务」指**进程内模块单例**（同一 Godot 二进制、同一进程、直接 C# 方法调用），**不是**分布式微服务。见 `system-overview.md` 第一节。
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

---

## 一、两级层次：service ⊃ manager

代码里只有两级职能层次，判据明确、不再增设第三级。

### service（服务）—— 边界单元

一个职能值得成为服务，当且仅当命中以下**三条判据之一**：

1. 它拥有**自己的状态机或跨多帧的长流程**；
2. 它需要**事务性地跨多个字段一致写入**（全有或全无）；
3. 它坐在一个**外部 I/O 边界**上（网络、存档、平台 SDK）。

服务以 Godot **autoload** 形式存在。**服务之间不互相读写字段**——只经编排顶点调用，或经 EventBus 广播既成事实。

### manager（管理器）—— 服务内部的职能组件

多个 manager 生活在同一个服务里，**共享宿主服务的事务边界与生命周期**。manager **不被跨服务直接调用**：外部只看得见宿主服务的 API 面。manager 是服务持有的普通 C# 对象（不是 `Node`，除非确需 `_Process`）。

### 拆分轴：生命周期层 + 行为边界，**不是数据类型**

不按 `power` / `item` / `card` / `resource` 各开一个服务——那会撕碎事务（一次结算典型要同时改多种资源）、横切生命周期层（账号级 vs 轮回级的持久化与清理规则完全不同），且退化为无规则的贫血 CRUD。同理不为九类 AdventureEvent 各开一个服务：只有 Combat 真有状态机，其余差异在**数据**而非**代码**。

「同类内容的统一入口与标准操作接口」这个诉求由 **content-service 的 ContentRegistry + 泛型仓储接口**满足（见第四节），而不是按类型开服务。

---

## 二、服务 / 管理器职责矩阵

| 服务 | 判据 | 管理器 | 职责 |
|------|------|--------|------|
| **account-service** | ③ | AuthManager | 登录渠道（手机 / 邮箱 → 微信 / QQ）、token 刷新、会话 |
| | | ComplianceManager | 实名、防沉迷、注销 / 数据导出 |
| **content-service** | ③ | ContentRegistry | 合并后按 `Id` 索引全部内容；**全游戏唯一内容读取入口** |
| | | ContentUpdateManager | 比对云端 `contentVersion`，下载增量到 `user://overlay/` |
| **sync-service** | ②③ | ProfileSyncManager | Profile 上下行；冲突以云端为准 |
| | | LocalCacheManager | `user://` 原子写（临时文件 → rename） |
| | | MigrationManager | 存档 schema 版本迁移 / 清晰拒绝 |
| **profile-service** | ② | **ProfileManager** | **两个 Profile 的唯一写入面**；`TryApply(spec)` 原子施加成本 / 产出 |
| | | **CapabilityManager** | capability flag 聚合 + modifier pipeline |
| | | AchievementManager | 成就进度累计与奖励发放 |
| **life-cycle-service** | ① | CycleStateManager | `status` 状态机：`ongoing → completed \| defeated` |
| | | ChapterManager | 篇章边界、境界存档点、重试上限（∞ / 3 / 1） |
| | | SeedManager | cycle seed 与具名 RNG 子流派生 |
| **future-event-service** | ① | EventOptionManager | 依 CharacterProfile 产出 eventOptions；**唯一出口** |
| | | **PlotManager** | 隐藏剧本：key points ↔ 云端剧本服务、隐藏属性阈值 → 调制 |
| **combat-service** | ① | TurnManager | 回合循环 |
| | | DeckManager | 抽 / 弃 / 洗（seeded） |
| | | IntentManager | 敌人意图与 AI |

**非服务的横切件：**

| 组件 | 形态 | 职责 |
|------|------|------|
| **game-progression** | 屏幕流程编排层 | **编排顶点**——串联核心循环；服务不互相直呼 |
| **EventBus** | autoload | 广播既成事实，解耦跨系统通知 |
| **ViewModel** | 呈现期对象 | `Data + 运行时状态 → 屏幕`；不落存档、不进云端负载 |

---

## 三、端到端运行链路

### 阶段 0 —— 启动与内容就绪

```
main.tscn ─▶ autoload 就绪 (EventBus / account-service / content-service /
                            sync-service / profile-service / life-cycle-service /
                            future-event-service / combat-service)
   │
   └─▶ content-service.ContentUpdateManager
          ├─ 读 res://content/manifest.json          → 本地 contentVersion = v12
          ├─ 云端 GET /content/version               → v14
          ├─ 下载增量 .tres                          → user://overlay/
          └─ content-service.ContentRegistry.LoadAll()
                 for each Id:  user://overlay/  优先
                               res://content/   兜底
                 合并后统一校验：重复 Id / 悬空交叉引用
                   → GD.PushError 启动期早失败
```

> 断网时跳过更新、直接用 `res://` 基线 —— **首启不依赖网络下载内容**。但进入游戏仍需登录（强制在线）。

### 阶段 1 —— 登录与档案拉取

```
LoginScreen ─▶ account-service.SignIn(渠道)
                 └─▶ AuthManager → 后端：token / accountId
                 └─▶ ComplianceManager：实名 / 防沉迷校验
   │ 成功
   └─▶ sync-service.ProfileSyncManager.PullProfile(accountId)
          ├─ 云端 PlayerProfile（权威，⊃ List<CharacterProfile>）
          ├─ MigrationManager：校验 schema 版本 → 迁移或清晰拒绝
          ├─ 校验所引用的内容 Id 在 ContentRegistry 中存在
          └─ LocalCacheManager：原子写入 user://cache/（仅缓存，非权威）
   │
   └─▶ profile-service.Hydrate(profile)
          └─ CapabilityManager 聚合：
               遍历「拥有 且 status = 启用」的 PlayerPower
                 → 生效 capability flag 集 + 具名 modifier 表
                 → EventBus.Emit(CapabilitiesChanged)
```

### 阶段 2 —— 主界面（元进程层）

```
MainMenu ── 读 PlayerProfile ──▶ ViewModel ──▶ 角色列表 / 篇章 / 成就 / 设置
   │
   │  各 UI 组件自行订阅 CapabilitiesChanged，
   │  自查 Has(RevealHiddenStats) 等 flag 决定自身可见性——
   │  业务层完全不知道这些 PlayerPower 存在。
   │
   └─ 玩家操作（开关 PlayerPower / 领取成就奖励 / 使用 PlayerItem）
        ─▶ profile-service.ProfileManager.TryApply(...)
             ├─ CapabilityManager 重算并广播
             └─▶ sync-service.Push()
```

### 阶段 3 —— 开始一次轮回

```
玩家选「炼气 · 新角色」或「筑基存档角色 · 续章」
   └─▶ life-cycle-service.StartCycle(seed, chapter, characterSource)
          ├─ ChapterManager：校验「该篇章至多一个 ongoing」、检查重试次数
          ├─ 新建或读档 CharacterProfile，status = ongoing
          │    （续章 = 上一篇章全部继承）
          ├─ SeedManager：从 cycle seed 派生具名 RNG 子流
          │    （map / combat / shop / reward 互不干扰）
          └─ EventBus.Emit(CycleStarted) ─▶ sync-service 自动存档点
```

### 阶段 4 —— 核心循环（由 game-progression 编排）

```
┌────────────────────────────────────────────────────────────────────┐
│ ① future-event-service.ComputeEventOptions(characterProfile)       │
│      ├─▶ PlotManager：读隐藏属性(道心 / 煞气 / 寿元) + key points   │
│      │     └─ 需要时向云端剧本服务请求分支内容（不落存档）          │
│      ├─▶ location 框定候选池（由 Travel 事件刷新）                  │
│      └─▶ SeedManager 的 map 子流抽取                                │
│      ──▶ eventOptions（唯一出口）                                   │
│                          ↓                                          │
│ ② game-progression ─▶ ViewModel 组装                               │
│      静态文案(ContentRegistry) + 运行时数值 + capability 可见性     │
│      ──▶ 月圆之夜式菜单，横向滑动                                   │
│          每项显示 selectCost / skipCost / 是否 ifMandatory          │
│                          ↓                                          │
│ ③ 玩家触控：【选择】或【跳过】（ifMandatory 封死跳过通道）          │
│                          ↓                                          │
│ ④ life-cycle-service.AdvanceEvent(character, chosen, mode)          │
│      mode = Select | Skip  ← 跳过复用同一入口的分支                 │
│      │                                                              │
│      ├─ profile-service.ProfileManager.TryApply(selectCost/skipCost)│
│      │     全量校验所有 element → 全有或全无；付不起则拒绝，回 ②    │
│      │     （modifier pipeline 在此处生效，消费层零条件分支）        │
│      │                                                              │
│      ├─ event.eventStart()  ──────────────────┐                     │
│      │                                         │ 事件自身内部流程    │
│      │   ┌── eventType == Combat / Finale ────┤                     │
│      │   │   combat-service.RunCombat(character, encounter)         │
│      │   │     TurnManager  ↺ 抽牌 → 出牌结算 → 敌人意图 → 回合结束 │
│      │   │     DeckManager   用 combat RNG 子流洗牌                 │
│      │   │     IntentManager 敌人 AI                                │
│      │   │     战斗内所有写入 ─▶ ProfileManager                     │
│      │   │     └─▶ CombatResult（胜 / 负 / 剩余 life）              │
│      │   └── 其余七类 ────────────────────────┤                     │
│      │       通用结算器：数据驱动的 outcome / effect 定义            │
│      │       （DnD 式选分支时回查 PlotManager.ChooseBranch）         │
│      ├─ event.eventEnd() ─────────────────────┘                     │
│      │                                                              │
│      ├─ ProfileManager.TryApply(产出 + lifeSpanCost(默认 -1)         │
│      │                          + 隐藏属性推拉)                     │
│      ├─ 记入 CharacterProfile.List<AdventureEvent> 修行历程          │
│      └─ CycleStateManager 判定：                                       │
│           寿元 ≤ 0 或 life ≤ 0 ─▶ DefeatCharacter()  ─▶ 阶段 5      │
│           Finale 通关          ─▶ CompleteChapter() ─▶ 阶段 5      │
│           否则 ─▶ EventBus.Emit(EventResolved)                      │
│                          ↓                                          │
│ ⑤ sync-service 自动存档点：LocalCacheManager 原子写 + Push 云端     │
│                          ↓                                          │
│    回到 ①（依更新后的 CharacterProfile 重算下一批 eventOptions）    │
└────────────────────────────────────────────────────────────────────┘
```

### 阶段 5 —— 轮回结束

```
completed ─▶ ChapterManager：在所达境界落存档点
              解锁下一篇章的可挑战角色
defeated  ─▶ 清理该角色数据；扣减该篇章重试次数（ch1 ∞ / ch2 3 / ch3 1）
              无可挑战角色时该篇章重新锁定（隐藏）
   │
   ├─▶ life-cycle-service.TeardownCycle()
   │      断开信号、QueueFree 实例化节点、清空集合
   │      （防跨轮回残留：静态字段、未清集合、遗留卡牌 / 敌人节点）
   ├─▶ profile-service.AchievementManager：结算成就进度
   └─▶ sync-service.Push() ─▶ 回主界面（阶段 2）
```

---

## 四、内容资产：存储与访问

### 三层结构

```
res://content/**.tres        基线内容，随版本发布，只读
                             → 保证首启可用、离线可读
user://overlay/**.tres       云端下发的增量，可热更，按 Id 覆盖基线
       ↓ 合并（overlay 优先，res:// 兜底）
ContentRegistry（内存）       按 Id 索引，全游戏唯一读取入口
```

- `res://content/manifest.json` 携带 `contentVersion` 与逐条目 hash。
- **校验点在合并之后**：重复 `Id`、悬空交叉引用（如某遭遇战列出未知敌人 Id）→ `GD.PushError` 启动期早失败。热更没有削弱这条纪律，只是把校验点后移了一步。
- 收益：平衡数值、事件定义、卡牌数值**可热更而不发版**（规避渠道审核周期），同时保留启动期强校验与离线首启。

### 统一操作接口

ContentRegistry 为每种 `XxxData : Resource` 持有一个仓储，对外是**同一形状**：

```csharp
IContentRepository<T> where T : Resource
    T        Get(string id);              // 必需：缺失 → PushError + 抛出
    bool     TryGet(string id, out T v);  // 可选：缺失 → 调用方降级
    IReadOnlyList<T> All();
    IEnumerable<T>   Where(Func<T,bool> predicate);
```

**所有服务经此取内容；代码中不散落 `ResourceLoader.Load`。** 新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目，不新增服务、不改调用方。

### 本地 / 云端分界（一条判据）

| 判据 | 归属 | 内容 |
|------|------|------|
| 有稳定 `Id`、**被存档引用**、需启动期校验 | **本地内容层**（`res://` + overlay） | `AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表 —— **含静态展示文案** |
| 按进度**动态请求**、一次性呈现、**不被存档引用** | **云端剧本服务** | AdventurePlot 的剧本分支文本与揭示内容 |

因此 **AdventureEvent 的定义本身属本地内容层** —— ContentRegistry 的启动期强校验模型成立；云端剧本服务只下发文本，由 PlotManager 按 `CharacterProfile` 的 key points 请求，**只在呈现期存在，不进 ContentRegistry、不落存档**。

---

## 五、档案存储与同步

```
                云端（权威）
                     ↑ Push（每个自动存档点）
                     │ Pull（启动时全量一次）
                     ↓
   PlayerProfile ⊃ List<CharacterProfile>   ← 内存中的运行态
                     ↓ 原子写
   user://cache/     仅缓存 / 断线临时态，非权威
```

- **`PlayerProfile` 持有 `List<CharacterProfile>`** —— 因此由**单一 profile-service** 作为两层的唯一写入面。一次结算里「扣账号级 PlayerItem 次数 + 扣轮回级灵玉」天然落在同一事务内，存档提交点唯一。
- **冲突一律以云端为准**（ADR-0003）。
- **原子写**：先序列化到临时文件，再 rename 覆盖 —— 写入中途崩溃不损坏缓存。
- **schema 版本 + 迁移路径**：读取时校验版本、内容 `Id`、必需字段；不匹配则迁移或清晰拒绝，绝不静默 null。
- **运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本 —— 文案变更不触发存档迁移。

---

## 六、贯穿全程的三条纪律

1. **确定性。** 一切玩法随机性经 SeedManager 从 cycle seed 派生的**具名子流**取得（map / combat / shop / reward 互不干扰）；同一 seed 必须复现同一轮回。不用未加种子的 `GD.Randi()`。
2. **写入唯一入口。** 两个 Profile 的一切变更经 `ProfileManager.TryApply(spec)`：全量校验 → 全有或全无 → 单点提交。这同时是 modifier pipeline 的生效点。
3. **呈现决策归呈现层。** capability flag 由 CapabilityManager 聚合，**由受影响的 UI 组件自己订阅并查询**。业务逻辑层不知道任何 PlayerPower 的存在 —— 散落条件分支的根因是把呈现决策写进了业务层。

---

## 对应

- 结构与边界权威：`20-systems/architecture.md`
- 各服务详情：`20-systems/services/_index.md`
- 系统层共有约定：`20-systems/common-properties.md`
- 术语：`terminology.md`
