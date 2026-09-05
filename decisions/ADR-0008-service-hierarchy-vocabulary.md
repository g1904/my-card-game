# ADR-0008 — 五级层次词表 service ⊃ manager ⊃ module ⊃ processor ⊃ handler，拆分轴 = 生命周期层 + 行为边界

- **状态：** Accepted
- **日期：** 2026-08-01
- **来源：** handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md · handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md · handoffs/2026-08-06d-combat-open-questions-mass-closure.md · handoffs/2026-09-02-architecture-services-reconcile.md

## 背景

代码组织需要回答两个正交的问题：**抽象层次到几级为止**，以及**按什么轴切分**。前者若不定，各处会自造层级词（「system」「controller」「helper」）并互相直呼；后者若不定，最诱人的答案是「按数据类型各开一个服务」（power / item / card / resource 各一个），而那会撕碎事务。

## 决策

**抽象层次不封顶在两级，但每一级都有固定的层级词——名字的后缀即宣告它在第几层：**

| 层级 | 名称 | 说明 |
|------|------|------|
| 第一级 | **service** | 边界单元，autoload；三判据命中其一 |
| 第二级 | **manager** | 服务内部的职能组件 |
| 第三级 | **module** | manager 内部的可复用部件 |
| 第四级 | **processor** | 无状态的处理阶段（现有实例：`EffectProcessor`） |
| 第五级 | **handler** | 按 kind 分派的叶子（现有实例：效果 kind handler，一个 kind 一个） |

- **service 的三判据（命中其一）：** ① 有自己的状态机或跨多帧的长流程；② 需事务性地跨多字段一致写入；③ 坐在外部 I/O 边界上。据此定为**七个服务**。
- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。**
- **纪律不随层数放宽：** 服务之间不读写对方字段、不伸手进对方 manager；不得跨层直呼——外部只看得见宿主服务的 API 面。
- **module 以下的下沉判据把轴从「职责」换成「形态」**，且带三条反判据（只是文件太长 / 只被调用一次且无变体 / 为了让层级看起来完整——一律不拆）。**先有判据、后有实例。**
- **下沉判据的宿主口径 = 宿主恰一个（manager 或 module）**：判据管的是「调用入口是否唯一」，不是「宿主住在第几层」。**层级链允许跳过中间级**——要求 processor 的宿主必须是 module，会为凑层数逼出一个只被调用一次、无变体的中间 module，正撞三条反判据的 ②③。

七服务清单、manager 归属、下沉判据的三条与门与校准样本见 `systems/architecture.md`「服务层」；层级词表与服务清单另见 `systems/services/_index.md`。

## 理由

- **命名即层级声明**，故不需要额外的登记表来回答「这个组件在第几层」，也堵死日后各处自造词。
- **按数据类型开服务会撕碎事务**：一次结算典型要同时改多种资源，而 `selectCost` 复合成本类型的天然消费者是**一个**统一施加点；它还**横切生命周期层**（`PlayerItem` 账号级跨轮回 vs `CharacterItem` 轮回级即清，持久化与清理规则完全不同），并退化为无规则的贫血 CRUD。
- 「同类内容的统一入口与标准操作接口」这一诉求由 **content-service 的 ContentRegistry + 泛型仓储**满足，不需要按类型开服务。
- **判据先于实例更安全。** 已知代价是判据偏严可能出现「该拆没拆」的巨型 module——**接受**：巨型 module 是**局部**问题（宿主 manager 之外看不见），而层级滥用是**全局**问题（词表失去意义、每个人自造层）。

## 备选方案

- **只设 service / manager 两级，不设第三级** — 已被本决策推翻：`DeckModule` 每个参战方各持一份，「同一形状被实例化多次」正是第三级的成立依据。
- **按数据类型各开一个服务**（power / item / card / resource） — 否决：撕碎事务、横切生命周期层、贫血 CRUD。
- **为五类 AdventureEvent 各开一个服务** — 否决：只有 Combat 真有状态机，其余差异在数据而非代码。
- **把 BattlefieldManager 提为参战方之上一层** — 否决：会变成 god object、把 `DeckModule` 压到第四级、且战场与两个参战方的生命周期完全同长（拆分轴不成立）。

## 后果

- 约束了每一次「这块代码放哪」的裁决，且新增组件的命名必须显式声明层级。
- 七个服务的边界、内含 manager 与 autoload 注册顺序因此可以逐一钉死（见 `systems/architecture.md`）。
- **层数不封顶也不封底**：五级各有现有实例，但一条链不必走满五级——第四级 `EffectProcessor` 的宿主是第二级 `StackManager`，中间不插 module。层级词表约束的是「叫什么名字就意味着在第几层」，不是「每一层都必须被填满」。
- 影响文档：`systems/architecture.md`（权威）· `systems/services/_index.md` · `systems/services/combat-service.md`（`DeckModule` 的层级归属）· `program-overview.md`。
