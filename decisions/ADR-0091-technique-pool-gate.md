# ADR-0091 — `CultivationTechniqueData` 增必填 `Pool : CardPool`，两侧对称设闸

- **状态：** Accepted
- **日期：** 2026-08-25
- **来源：** handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md

## 背景

敌我共用同一个功法类型与同一个注册表（→ `ADR-0090`）之后，立刻出现一个问题：敌方专用的功法（为难度设计、不适合玩家持有）会出现在玩家的奖励池与 Research 候选里。

`CardData` 早已有 `Pool : CardPool` 解决卡牌层的同一问题；功法层是它的同构上移。

## 决策

给 `CultivationTechniqueData` 加 **`Pool : CardPool { Character, Enemy, Both }`**，**必填、无默认值、缺失即 `PushError`**（同 `CardType` / `UsableScene`）。与 `CardData.Pool` 同构同枚举。

**两侧对称设闸：**
- 玩家侧四处功法取池各叠一层 `Pool != Enemy`；
- `EnemyData` 引用的功法**不得 `Pool == Character`**；
- 加「功法 ↔ 成员卡 `Pool` 相容性」校验；
- `LearnTechnique` / `UpgradeTechnique` 目标 `Pool == Enemy` 即拒绝。

**「卡池划分」节是唯一权威** → `systems/character-profile/deck/_index.md`。

## 理由

**默认值会让漏填的敌方内容悄悄进入玩家奖励池**——这是「能上线、线上不可见」的一类错误：玩家拿到一门为敌人设计的功法，而没有任何报错。必填无默认使漏填在加载期就炸。

加载期闸与取池闸都要：取池闸挡运行期，加载期闸挡**编排错误**——「敌方套牌不过滤」讲的是取池，不覆盖编排校验。

## 备选方案

- **`Pool` 给默认值 `Both`** — 否决：漏填静默进玩家池。
- **敌人引用功法不加加载期闸** — 否决：`CardData.Pool` 在卡牌层本就是两侧各一条闸，功法层是同构上移。
- **`Pool` 定义上移到 `deck/common-properties.md`** — 否决：论证与枚举定义是同一条推理的两半，拆开即两处各半。

## 后果

- **已知代价正面写下**：敌方专用功法引用的共享卡会被一并排除出散牌产出侧。
- `Pool` 三值枚举现挂 `CardData` 与 `CultivationTechniqueData` 两个面：**共用体系、不共用卡池**。
- `TechniqueCodex` 照常收录 `Pool == Enemy` 的功法，完成度分母含它（→ `ADR-0096`）。
