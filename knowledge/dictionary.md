# 术语表 —— 游戏词汇

> **权威来源：`game-design-documents/terminology.md`**（设计分支根级）。所有**本作专有**的领域术语——中文领域词 ↔ 英文/代码标识符（修行事件/AdventureEvent、**九类分类法**（07-24 加入 Explore 探索秘境 / Travel 前往某处地点）、**location 地域**、境界阶梯、PlayerProfile/CharacterProfile 等）——以该文件为准，此处不再复制。改动术语时先改那里，再回来核对本表是否有过时的通用词。

本文件只保留**通用的 roguelike 卡组构建体裁词汇**（沿用 Balatro / Slay the Spire 惯例），供阅读代码/知识笔记时快速对照。凡与 `terminology.md` 冲突之处，以 `terminology.md` 为准。

| 术语 | 含义 |
|------|---------|
| **Cycle（轮回）** | 从开局到胜/负的一次完整游玩。可从存储的 **seed** 复现。体裁通称 *run*，本作定名为**轮回 / cycle**，与 life-cycle-service 同词根；权威见 `terminology.md`。 |
| **Seed** | 确定性地驱动整局轮回所有随机性的数字（本作 `CycleSeed`，u64）。**可复现性只在同一 `contentVersion` 内成立**——已明确放弃跨内容版本复现（overlay 热更即时生效，不冻结版本）。见 `standards/rng-determinism.md`。 |
| **Ante / Floor** | 轮回内部的一个进程层级（Balatro 称 *ante*；StS 称 *act/floor*）。难度随之提升。本作对应概念见 `terminology.md` 的「篇章 / Chapter」与境界阶梯。 |
| **Map / Node** | 轮回的分支路径；每个 **node** 是一次事件节点。本作的节点单元已定名为 **修行事件 / AdventureEvent**（原 encounter），见 `terminology.md`。地图路由与地域（**location**）切换由 **Travel** 修行事件驱动，归 `systems/game-progression.md`。 |
| **Blind** | 一场战斗的胜利条件 / 关卡门槛（Balatro 风格的 small/big/boss blind，或 StS 风格的 boss）。 |
| **Deck** | 玩家本局轮回拥有的全部卡牌。 |
| **Draw pile / Hand / Discard pile** | 运行时的卡牌区域。卡牌在 draw → hand → discard →（重洗）→ draw 之间流转。 |
| **Hand** | 本回合当前可打出的卡牌。 |
| **Energy / Mana** | 每回合用于打出卡牌的资源。 |
| **Jade（灵玉） / Currency** | **轮回级**货币，用于交易（Exchange）事件中购买。归 `character-profile/currency.md`，随轮回结束而清；跨轮回的账号级资产另归 player-profile。 |
| **Checkpoint / 重试** | 篇章通关后在所达**境界**落存档点；失败（`defeated`）清理该角色并扣减该篇章重试次数，耗尽则该篇章重新锁定。归 ChapterManager；**次数与规则的权威见 `decisions/ADR-0004`**。 |
| **Relic / Joker** | 一种持久的被动修饰器，通过触发式效果改变规则（Balatro 称 *joker*；StS 称 *relic*）。 |
| **Scoring (chips × mult)** | Balatro 风格的计分模型：一次打出的价值 = chips × 倍率。（若游戏偏 Balatro 风格则采用；偏 StS 风格的游戏改用伤害/HP 计分。） |
| **Upgrade / Remove** | 提升某张卡牌，或将其从 deck 中删除（通常在商店/事件处进行）。 |
| **Event** | 提供风险/回报选择的非战斗 node。本作分类见 `terminology.md` 九类（社交/交易/闭关/探索秘境/前往某处地点……）。 |
| **Boss** | 一个 ante/act 的收尾遭遇。 |
| **Reward** | 遭遇结束后的选择（卡牌、jade、relic）。 |
| **CycleState** | 所有 per-cycle 数据的内存持有者。**本作已定名为 `CharacterProfile`**（轮回级），由 `PlayerProfile ⊃ List<CharacterProfile>` 持有；状态机归 life-cycle-service 的 CycleStateManager。见 `terminology.md`。 |
| **ContentRegistry** | 启动时合并 `res://content/` 基线与 `user://overlay/` 热更、以 `Id` 为键的全部内容资源索引。隶属 content-service，是**全游戏唯一内容读取入口**。读取侧 `Get(id)` **不**按 `ContentEnabled` 过滤；**一切抽取走 `AllEnabled()`**。 |
| **Materialize（物化）** | `AdventureEventData` 模板 → future-event-service 依情境代入 → 定稿 `EventOption`。体裁无对应通称；**产出即定稿、不可改写、落存档**。权威见 `terminology.md`。 |

> 当设计确定采用 Balatro 风格计分还是 StS 风格 HP 战斗（或混合方案）时，在此处以及权威文档 `systems/scoring.md` / `systems/adventure-event/combat/` 中记录该决定。
