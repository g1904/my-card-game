# codex（图鉴族）

> **图鉴 = 账号级的知识收集面**，共**六个**：敌人 / **神通**（CharacterPower）/ **法则**（PlayerPower）/ **法宝**（CharacterItem）/ **古宝**（PlayerItem）/ **地域**（Location）。跨轮回持久，归 PlayerProfile。它是元进程的**第三条积累线**（与法则、Achievement 的「成就」并列）。中文定名见 `terminology.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 六个图鉴

| 图鉴 | 收录对象 | 详述 |
|------|---------|------|
| **EnemyCodex** | 已遭遇的敌人（`EnemyData` 条目） | [enemy-codex](enemy-codex.md) |
| **CharacterPowerCodex** | 角色（轮回级）能力 `CharacterPower` | ⟨待播种；对象定义见 `../../character-profile/power/`⟩ |
| **PlayerPowerCodex** | 账号级能力 `PlayerPower` | ⟨待播种；对象定义见 `../player-power/`⟩ |
| **CharacterItemCodex** | 角色（轮回级）道具 `CharacterItem` | ⟨待播种；对象定义见 `../../character-profile/item/`⟩ |
| **PlayerItemCodex** | 账号级道具 `PlayerItem` | ⟨待播种；对象定义见 `../player-item/`⟩ |
| **LocationCodex** | 已去过的地域（location 条目） | ⟨待播种；对象定义见 `../../game-progression.md`⟩ |

- **LocationCodex 是 `locationMap` 向玩家显影的唯一通道（承重）。** 地域图 **`locationMap` 在轮回内对玩家不可见**（进程不给俯瞰视图这条不变）；玩家只能看到**已经去过的地方**——与 EnemyCodex 的「遭遇即记」同构。**玩家的世界地图是在多次轮回中一格一格拼出来的，而不是一开始就发下来的。**
  - **词条记连边：跨轮回重建整张图是设计目标（承重）。** 词条**记录「它通向哪些地域」**；玩家因此能在多次轮回中**把整张 `locationMap` 重建出来**——这不是要规避的泄露，而是**设计目标（知识 = 力量）**。「去过即记」的完整语义 = **去过 A 就记下 A 及 A 的连边**。
  - **推论 ①：`locationMap` 的不可见是「初见不可见」，不是「永远不可见」。** 轮回内不给俯瞰图这条不变；变的是**跨轮回的知识可以逼近那张图**。两者不冲突——玩家的地图在图鉴里，不在 HUD 上。
  - **推论 ②：「中长期规划感 / 方位感的来源」的地理那一半由此落地。** 闸门给多个并列目的地，而图鉴告诉你每个目的地又通向哪里 ⇒ **玩家能提前两步规划路线**；第一次玩是盲选，玩多了就知道往哪走。（进度感那一半仍待答，见 `../../game-progression.md`。）
  - **推论 ③：它是六本图鉴里唯一一本词条之间有拓扑关系的。** 其余五本是平坦的条目集合，它是一张**逐步显影的图**——存档形态仍是 id 集合（连边随 location 条目静态给出），但**呈现形态必然不同**（其余五本是列表 / 网格，它是一张图）。
  - **推论 ④：它是失败侧产出的又一条通道**——输掉的轮回同样把去过的地域写进了图鉴。
  - **它的成立依赖 `locationMap` 不变**（三个篇章共用同一张图，见 `../../game-progression.md`）：图若每局重排，「记住地理」就没有意义。**记连边把这条前置约束抬成了对玩家的隐性承诺**——玩家花几十个轮回拼出来的图若被改版重排，积累当场归零。

### 共同形状

- **账号级、跨轮回持久，归 PlayerProfile。** 图鉴**不随轮回清理**——这正是它作为「知识资产」的意义：一次失败的轮回同样往图鉴里写了东西。
- **条目按对象的稳定 `Id` 索引。** 与全库「稳定 `Id` 是一切引用的键」一致。
- **条目内容是静态文案，挂在对应的内容 `Resource` 上；存档只记解锁状态。** 图鉴的存档负担因此**接近于一个 id 集合**——文案改版不触发存档迁移，也不撑大增量 push。
- **写入经 `profile-service.ProfileManager`。** 解锁是 `ProfileChangeSpec.CodexElements` 的变更目标，不绕过唯一写入面。
- **六本共用一条触发内核：接触即记，不要求你从中获益。** 遭遇 / 去过 / 进入持有列表，六行全部搭在一次已经存在的提交上（**零新增提交点**）；初始持有一并入图鉴，商店里见到但没买的不记。逐本触发表与依据见 `common-properties.md`。
- **给静态知识，不给动态情报。** 这条分层由 EnemyCodex 确立（图鉴说「这个敌人会做哪些事」，不说「它这回合做什么」），对整族适用：图鉴是**场外的知识面**，不是场内的情报面。**「词条正文不含阿拉伯数字」不在整族通用之列**——它是 EnemyCodex 独有的口径纪律，边界见 `common-properties.md`。
- **词条深度按本分野。** EnemyCodex 是五项结构化文案，四本能力 / 道具类只用内容条目自身已有的字段 + 一段可选的 `CodexFlavor` 风味文案；六本一律不分档解锁。

### 为何是一族而不是一个

- 六个图鉴形状相同、语义相同、存档形态相同——**差别只在收录对象**。把它们做成一族（共有属性一份、各自一份文档）避免六套并行的解锁 / 计数逻辑。**LocationCodex 的加入是这条设计的验证**：一个全新的收录对象只需加一行，不需要任何新机制。
- **它也给「收集」这条动机一个统一的落点：** 玩得越多，六本图鉴越厚；这与成就的「完成度」是两种不同的满足感（成就衡量做到了什么，图鉴衡量见过什么）。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-19-codex-entry-schema.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **图鉴共六个，构成一族；账号级、静态文案、存档只记解锁状态**。
- **图鉴不与成就 / 奖励挂钩**：收集完成度不发放 PlayerPower / PlayerItem，也不驱动后端的任何发放。**连带：六个 Codex 字段不进透明路径白名单、后端零配合**（见 `systems/services/sync-service.md`）。反向的代价是收集这条动机只靠「看着它变厚」自持——这正是它与成就「完成度」两种满足感的分野。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **「记连边」的显影粒度（承重）。** **记连边**（跨轮回重建整张图是设计目标）；仍待定：去过 A 之后，词条列出的是 **A 的全部邻接（含从未去过的 B，地名因此被提前看见）**，还是**只记已实际走过的那几条边**？前者才真正支持「提前两步规划路线」、也才让整张图在有限轮回内可重建；后者纯回溯、更保守。**本库现按前者理解，待确认。**
- **LocationCodex 的其余词条深度。** 除连边外还写什么（风物文案？该地域的事件类型倾向？敌人清单？`eventCountLimit`？）未定。**连带：它的呈现形态与其余五本不同**（一张逐步显影的图 vs 列表 / 网格），归 `ux/screen-flow.md`。
- **入口与浏览形态。** 六本图鉴在主菜单如何组织（一个「图鉴」入口下分六页？）、战斗内能否查阅（EnemyCodex 尤其相关）。→ `ux/screen-flow.md`、`ux/combat-ux.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/codex/_index.md`（待建）。
