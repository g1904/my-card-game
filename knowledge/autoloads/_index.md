# Autoload（服务）索引

> **权威设计意图：`game-design-documents/20-systems/services/_index.md`**（七个服务 + 两级层次）与根级 `program-overview.md`（服务 / 管理器职责矩阵、启动顺序）。本索引描述这些意图的代码承载形式。

在 Godot 的 **Project Settings → Autoload** 下注册的长生命周期服务。**目前尚未注册任何 autoload**（全新脚手架；`project.godot` 无 `[autoload]` 段）。本文件列出预期的集合及其契约。

## 两级层次：service ⊃ manager（已定案）

- **service（服务）= 边界单元，以 autoload 形式存在。** 命中三条判据之一才值得成为服务：① 拥有自己的状态机或跨多帧的长流程；② 需要事务性地跨多个字段一致写入（全有或全无）；③ 坐在外部 I/O 边界上（网络、存档、平台 SDK）。服务**不持有独立数据**——只操作 `PlayerProfile` / `CharacterProfile` 两个核心「类」。**服务之间不互相读写字段**，只经编排顶点调用或经 EventBus 广播既成事实。
- **manager（管理器）= 服务内部的职能组件。** 共享宿主服务的事务边界与生命周期；**不被跨服务直接调用**，外部只看得见宿主服务的 API 面。manager 是服务持有的普通 C# 对象（**不是 `Node`**，除非确需 `_Process`）。

## 服务清单（规划中）

| 服务（autoload） | 判据 | 内含 manager | 职责 |
|------------------|------|-------------|------|
| **account-service** | ③ | AuthManager、ComplianceManager | 登录渠道（手机 / 邮箱 → 微信 / QQ）、token 刷新、会话；实名 / 防沉迷 / 注销。**已移除游客入口。** |
| **content-service** | ③ | ContentRegistry、ContentUpdateManager | 内容资产：`res://content/` 基线 + `user://overlay/` 热更，合并后按 `Id` 索引。**全游戏唯一内容读取入口。** |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager | 存档与云同步：启动全量 Pull、存档点 Push、冲突以云端为准；`user://cache/` 原子写；schema 迁移。 |
| **profile-service** | ② | ProfileManager、CapabilityManager、AchievementManager | **两个 Profile 的唯一写入面**（`TryApply(spec)` 全有或全无）；capability flag 聚合 + modifier pipeline；成就进度与发放。 |
| **life-cycle-service** | ① | RunStateManager、ChapterManager、SeedManager | Run 生命周期：`StartRun(seed, chapter)`、`AdvanceEvent(mode)`、胜 / 负判定、`TeardownRun()`；篇章边界与重试上限；具名 RNG 子流派生。 |
| **future-event-service** | ① | EventOptionManager、PlotManager | 依 `CharacterProfile` 产出 eventOptions（**唯一出口**）；PlotManager 按隐藏属性阈值与 key points 调制、向云端剧本服务请求分支文本。 |
| **combat-service** | ① | TurnManager、DeckManager、IntentManager | 回合循环、抽 / 弃 / 洗（seeded）、敌人意图与 AI。**Finale 复用同一状态机。** |

**非服务的横切件：**

| 组件 | 形态 | 职责 |
|------|------|------|
| **EventBus** | autoload | 广播既成事实，解耦跨系统通知。见 `standards/signal-eventbus.md`。 |
| **game-progression** | 屏幕流程编排层（非服务） | **编排顶点**——串联核心循环；服务不互相直呼。 |
| **ViewModel** | 呈现期对象（非 autoload） | `Data + 运行时状态 → 屏幕`；不落存档、不进云端负载。 |

## 注册顺序很重要

Godot 自上而下初始化 autoload。预期顺序：**EventBus → content-service → account-service → sync-service → profile-service → life-cycle-service → future-event-service → combat-service**——内容与档案必须在读取它们的系统之前就绪（见 `program-overview.md` 阶段 0 / 1）。实际顺序确定后在此记录。

## 两条唯一入口（强制）

- **内容读取** 一律经 `content-service.ContentRegistry`；代码中**不散落 `ResourceLoader.Load`**。
- **档案写入** 一律经 `profile-service.ProfileManager.TryApply(spec)`：全量校验 → 全有或全无 → 单点提交。life-cycle-service / combat-service / future-event-service 都只经它写档。

## 如何添加一条 autoload 说明

当你创建一个服务时，添加其公共 API 面（方法 / 信号）、内含 manager、初始化顺序依赖。游戏数据保留在两个 Profile 中，**不要分散到各服务**——服务不持有独立数据。
