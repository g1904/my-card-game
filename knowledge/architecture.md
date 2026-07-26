# 架构

MyCardGame 项目的高层地图。在深入某个系统之前，先加载本文件以获得宏观视角。

> 设计意图（人类视角的“做什么/为什么”）**以及技术结构**位于 `game-design-documents/`（`design` 分支）——本库是**游戏内容 + 技术结构的双重事实来源**（技术结构总览的权威在 `20-systems/architecture.md`）。本知识库已降为**指向该库的引用层**——当意图与代码出现分歧时，以设计文档为准。方向来源：`game-design-documents/10-handoffs/2026-07-24-docs-restructure-class-model.md`。
>
> **关键的事实来源文件（知识 ↔ 设计文档对照）：**
> | 知识文件 | 权威设计文档 |
> |----------|--------------|
> | `architecture.md`（本文件） | `game-design-documents/20-systems/architecture.md`（结构与边界的权威） |
> | `architecture.md` 的运行链路 | `game-design-documents/program-overview.md`（根级；端到端运行时视角） |
> | `dictionary.md` | `game-design-documents/terminology.md`（根级术语表） |
> | `systems/*` | `game-design-documents/20-systems/`（类模型化结构） |
> | `data/*` | `game-design-documents/20-systems/`（内容即各系统的字段 / 内嵌类型——见 `data/_index.md` 的映射表） |
> | `scenes/*`（屏幕流程） | `game-design-documents/40-ux/` |
> | 已定案的决策 | `game-design-documents/50-decisions/ADR-*` |
> | 待答问题 | `game-design-documents/open-questions.md` |
> | 可构建的功能规格 | `game-design-documents/60-requirements/FR-*` |

## 引擎与平台
- **Godot 4.7**，启用 **.NET/C#**。程序集名称：`game-feature-branch`。
- 渲染器：**GL Compatibility**（`renderer/rendering_method = gl_compatibility` 以及 `.mobile`）。Windows 编辑器使用 `d3d12` 设备驱动；运行时使用 GL Compatibility，以广泛支持移动端/网页端。
- 显示：`stretch/mode = canvas_items`，`stretch/aspect = expand`，**竖屏**，移动优先。
- 3D 物理引擎设为 Jolt（脚手架默认值；本作是 2D 游戏——3D 物理未使用）。
- 目标平台：**Android / iOS（主要），桌面，网页**。**强制在线**——进度实时同步云端、以云端为权威；`user://` 仅作本地缓存。见 `game-design-documents/00-vision/scope.md`。

## 当前状态（全新脚手架）
`game-feature-branch/` 目前仅包含 Godot 脚手架：`project.godot`、`icon.svg`、编辑器 `.godot` 缓存以及 git 属性文件。**尚不存在任何游戏场景、C# 脚本、autoload 或数据资源。** 下文“预期架构”中的一切都是待构建的规划，而非对现有代码的描述。

## 预期架构

### 两级层次：service ⊃ manager（已定案）
代码里只有两级职能层次，不设第三级。**service = 边界单元**，命中三条判据之一才成立：① 拥有自己的状态机 / 跨多帧长流程；② 需事务性跨多字段一致写入（全有或全无）；③ 坐在外部 I/O 边界上（网络、存档、平台 SDK）。服务以 **autoload** 形式存在，**不持有独立数据**，且**服务之间不互相读写字段**——只经编排顶点调用或经 EventBus 广播既成事实。**manager = 服务内部的职能组件**，共享宿主服务的事务边界与生命周期，不被跨服务直接调用；是服务持有的普通 C# 对象（非 `Node`，除非确需 `_Process`）。

**拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务（会撕碎事务、横切生命周期层、退化为贫血 CRUD）；同理不为九类 AdventureEvent 各开服务——只有 Combat 真有状态机，其余差异在**数据**而非**代码**（Finale 复用 combat-service；Mystery 揭示后落到真实 `eventType`）。

### Autoload（服务）——见 `autoloads/_index.md`
七个服务及其内含 manager（权威：`20-systems/services/_index.md`）：

| 服务（autoload） | 判据 | 内含 manager |
|------------------|------|-------------|
| **account-service** | ③ | AuthManager、ComplianceManager |
| **content-service** | ③ | ContentRegistry、ContentUpdateManager |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager |
| **profile-service** | ② | ProfileManager、CapabilityManager、AchievementManager |
| **life-cycle-service** | ① | RunStateManager、ChapterManager、SeedManager |
| **future-event-service** | ① | EventOptionManager、PlotManager |
| **combat-service** | ① | TurnManager、DeckManager、IntentManager |

外加非服务的横切件：**EventBus**（autoload，广播既成事实）、**game-progression**（屏幕流程编排层，非服务）、**ViewModel**（呈现期对象）。

**两条唯一入口 + 一个编排顶点：**
- **内容读取唯一入口 = `content-service.ContentRegistry`** —— 代码中不散落 `ResourceLoader.Load`。
- **档案写入唯一入口 = `profile-service.ProfileManager`** —— `TryApply(spec)` 全量校验 → 全有或全无 → 单点提交；modifier pipeline 在此生效，故消费层不写 `if (hasPowerX)`。
- **编排顶点 = game-progression** —— 串联核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEvent → 重算`。

### 游戏系统——见 `systems/_index.md`
类模型化结构：核心「类」为 **character-profile**（run 级：deck / item / currency / life / mana）与 **player-profile**（账号级：player-item / player-power），`PlayerProfile ⊃ List<CharacterProfile>`；services/ 下的七个服务对其提供 API。game-progression（编排顶点，含 location / travel 路由）→ adventure-event（9 子类型：combat / finale / mystery / practice / exchange / research / explore / social / travel）→ scoring（去向待定）。此外还有横切的 UI/屏幕、输入/触摸、音频（见 autoloads / scenes / standards）。

### 展示层契约：Data / 运行时 / ViewModel 三层（已定案）
1. **静态展示文本留在数据资源上**（`XxxData : Resource` 直接携带显示名 / 描述 / 图标）。
2. **运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本——文案变更不触发存档迁移。
3. **组合展示走 UI 层轻量 ViewModel**（`Data + 运行时状态 → 屏幕`），只存在于呈现期，**不落存档、不进云端负载**。

ViewModel 因此是架构中的显式一层，位于服务 / 核心「类」与屏幕场景之间，单向依赖、不被服务反向依赖。

### 数据——见 `data/_index.md`
内容即各系统的字段 / 内嵌类型（cards→deck、relics→player-power、enemies→combat、剧本→services/plot-manager、blinds/antes→game-progression、平衡→balance），以自定义 `Resource` 类的 `.tres` 文件形式编写，由 **content-service 的 ContentRegistry** 合并后按 `Id` 索引。

**内容三层存储（已定案）：**
```
res://content/**.tres     基线内容，随包发布，只读（保证首启可用 / 离线可读）
user://overlay/**.tres    云端下发的增量，可热更，按 Id 覆盖基线
      ↓ 合并（overlay 优先，res:// 兜底）→ 合并后统一校验（重复 / 悬空 Id → PushError 早失败）
ContentRegistry（内存）    按 Id 索引，唯一内容读取入口
```
`res://content/manifest.json` 携带 `contentVersion` 与逐条目 hash。**本地 / 云端分界的判据：** 有稳定 `Id`、被存档引用、需启动期校验 → 本地内容层（含静态展示文案）；按进度动态请求、一次性呈现、不被存档引用 → 云端剧本服务（AdventurePlot 分支文本，不进 ContentRegistry、不落存档）。

### 场景——见 `scenes/_index.md`
流程：**登录屏（应用首屏，强制账号登录）→ 主菜单（切换篇章）→ run**。屏幕场景（LoginScreen、MainMenu、Run、EventOptions、Combat、Settings）以及实例化的控件场景（卡牌、敌人、玩家能力图标、事件选项条目）。run 内主导航是**月圆之夜式横向滑动的 eventOptions 菜单**，而非传统地图屏。

## 数据 / 控制流（目标）
> 端到端的分阶段运行链路（启动 → 登录 → 主界面 → 开 run → 核心循环 → 结算）见 `game-design-documents/program-overview.md`。

```
启动 ──▶ content-service (manifest 版本比对 → overlay 增量 → 合并 → 校验)
登录 ──▶ account-service ──▶ sync-service.Pull ──▶ profile-service.Hydrate
                                                     └─▶ CapabilityManager 聚合
                                                           ──▶ EventBus: CapabilitiesChanged

Input (touch, 横向滑动选择)
   ──▶ Screen scene  ◀── ViewModel (呈现期组装 Data + 运行时状态; 不落存档)
        ──▶ game-progression (编排顶点)
             ──▶ future-event-service (依 CharacterProfile 产出 eventOptions; 唯一出口)
             │      └─▶ PlotManager (隐藏属性阈值 → 调制; key points ↔ 云端剧本服务)
             ──▶ life-cycle-service.AdvanceEvent (mode = Select | Skip)
                   ├─▶ profile-service.ProfileManager (唯一写入面; 原子施加成本 / 产出)
                   ├─▶ combat-service (Combat / Finale: 回合循环状态机)
                   ├─▶ content-service.ContentRegistry (按 Id 读内容)
                   └─▶ EventBus (广播既成事实) ──▶ 其他系统 / UI
   sync-service ◀── 自动存档点 ── PlayerProfile ⊃ CharacterProfile ──▶ 云端 (权威; user:// 仅缓存)
                                   (SeedManager 的具名子流驱动全部随机性)
```

## 三条贯穿纪律
1. **确定性。** 一切玩法随机性经 SeedManager 从 run seed 派生的**具名子流**（map / combat / shop / reward 互不干扰）；同一 seed 复现同一 run；不用未加种子的 `GD.Randi()`。
2. **写入唯一入口。** 两个 Profile 的一切变更经 `ProfileManager.TryApply(spec)`：全量校验 → 全有或全无 → 单点提交。
3. **呈现决策归呈现层。** capability flag 由 CapabilityManager 聚合，**由受影响的 UI 组件自己订阅并查询**；业务逻辑层不知道任何 PlayerPower 存在。
