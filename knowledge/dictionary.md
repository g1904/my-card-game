# 术语表 —— 游戏词汇

> **权威来源：`game-design-documents/terminology.md`**（设计分支根级）。所有**本作专有**的领域术语——中文领域词 ↔ 英文 / 代码标识符——以该文件为准，此处不复制。改动术语时先改那里，再回来核对本表是否有过时的通用词。

本文件只保留**通用的 roguelike 卡组构筑体裁词汇**（沿用 Balatro / Slay the Spire 惯例），供阅读代码 / 知识笔记时快速对照：每行 = 体裁通称 + 本作对应词的**指路**，不展开本作的机制说明。凡与 `terminology.md` 冲突之处，以 `terminology.md` 为准。

| 体裁术语 | 体裁含义 | 本作对应 |
|------|---------|---------|
| **Run** | 从开局到胜 / 负的一次完整游玩，可从 seed 复现。 | **轮回 / Cycle**；状态持有者 `CharacterProfile`，状态机归 life-cycle-service。→ `terminology.md` |
| **Seed** | 确定性驱动整局随机性的数字。 | `CycleSeed`；**复现只在同一 `contentVersion` 内成立**。→ `standards/rng-determinism.md` |
| **Ante / Act / Floor** | 轮回内部的进程层级，难度随之提升。 | **篇章 / Chapter** 与境界阶梯。→ `terminology.md` |
| **Map / Node** | 分支路径与其上的事件节点。 | **修行事件 / AdventureEvent**；地图路由由 Travel 事件驱动，`locationMap` 对玩家不可见。→ `terminology.md`、`systems/game-progression.md` |
| **Blind** | 一场战斗的胜利条件 / 关卡门槛。 | `combatTier` 遭遇档位——**借难度分档、不借出现节律**。→ `terminology.md`、`systems/adventure-event/combat/` |
| **Deck** | 玩家本局拥有的全部卡牌。 | 构筑单位是**功法 `CultivationTechnique`**（整组入组 / 整组替换）。→ `systems/character-profile/deck/` |
| **Draw pile / Hand / Discard pile** | 运行时卡牌区域，体裁通常是「弃牌重洗回流」的环流。 | **本作没有重洗**——抽空即**疲劳**。→ `terminology.md`、`systems/services/combat-service.md` |
| **Energy / Mana** | 每回合用于打出卡牌的资源。 | 法力，归 `systems/character-profile/mana.md`。 |
| **Currency** | 局内货币。 | **两层**：灵石 `spiritStone`（基础）· 仙玉 `immortalJade`（高阶），均轮回级、随轮回清；**不可兑换**。旧词 `jade` **整体退役、不改派**。→ `terminology.md`、`systems/character-profile/currency.md` |
| **Checkpoint** | 进度存档点与失败重试规则。 | 篇章通关后在所达境界落点，归 ChapterManager。→ `decisions/ADR-0004-realm-checkpoint-retry-model.md` |
| **Relic / Joker** | 持久的被动修饰器，以触发式效果改变规则。 | 账号级**法则 PlayerPower** → `systems/player-profile/player-power/`；轮回级**神通 CharacterPower** → `systems/character-profile/power/`。 |
| **Scoring** | 体裁两路：chips × mult（Balatro）或伤害 / HP（StS）。 | **两路都不采用**——计分模型 = **道念 / momentum**。→ `terminology.md`、`systems/scoring.md` |
| **Upgrade / Remove** | 提升某张卡牌或将其移出 deck。 | 归闭关（Research）事件的构筑面板。→ `systems/adventure-event/research/` |
| **Event** | 提供风险 / 回报选择的非战斗节点。 | 五类分类法之一，见 ADR-0002（Combat / Exchange / Research / Explore / Travel）。→ `terminology.md` |
| **Boss** | 一个 act 的收尾遭遇。 | **Finale（境界突破 / 天劫）**——复用 combat-service，全部 Finale 均为战斗。→ `systems/adventure-event/combat/` |
| **Reward** | 遭遇结束后的选择（卡牌 / 货币 / relic）。 | 强制自动计入项 + 候选项**逐项领取 / 跳过**（不是三选一）；**每一次领取 / 跳过都是决策点**。→ `decisions/ADR-0082-itemized-combat-rewards.md` |
| **CycleState** | 所有 per-run 数据的内存持有者。 | **`CharacterProfile`**（轮回级），由 `PlayerProfile` 持有。→ `systems/character-profile/_index.md` |
| **Content registry** | 按 id 索引全部内容资源的启动期注册表。 | `ContentRegistry`，隶属 content-service，**全游戏唯一内容读取入口**。→ `data/_index.md` |
| **Materialize（物化）** | 体裁无对应通称：模板 → 依情境代入 → 定稿实例。 | `AdventureEventData` → future-event-service → `EventOption`，**产出即定稿、不可改写、落存档**。→ `terminology.md` |

> **本作大量借用 MTG 术语**（栈 / 结算 / 触发 / 永久物 / 卡牌类型 / 次类型），但**只借结算模型与词汇，不借其胜负模型、mana 曲线、交互与优先权**。借词的中英定名权威在 `terminology.md`。
