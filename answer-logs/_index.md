# Answer logs — 已答定问题的归档台账

`open-questions.md` 只跟踪**仍待答**的问题。一旦某个问题被拍板，它就从那份清单**移出**，并写入本文件夹的一份 `log-<draftSuffix>.md`。

## 命名：`log-<draftSuffix>.md`

`draftSuffix` = 触发本次移出的那份输入的后缀：

- 处理 `90-inbox/draft-<suffix>.md` → `log-<suffix>.md`（例：`draft-0725_2.md` → `log-0725_2.md`）。
- 无草稿来源（粘贴文本、或 `/summarize-open-questions` 独立运行）→ 用当天 `MMDD`；若同名已存在，追加 `_2`、`_3`。
- **每次移出新建一个文件**，不追加进旧 log。一次运行若没有任何问题被答定，则不建文件。

## 内容形态

每份 log 是一次移出的快照：日期、来源 handoff / 草稿、以及逐条「问题 → 结论（归档去向）」。log 是**只读的历史记录**，不是权威——结论的权威归属仍在各主题文档的 `## 决策` / `## 意图` 与 `50-decisions/ADR-*`。

## 台账

| Log | 日期 | 来源 | 移出条数 |
|-----|------|------|----------|
| `log-0801b.md` | 2026-08-01 | `90-inbox/draft-0801b.md`（战斗定长 10 回合 / 道念产出途径与起始 `baseMomentum` / 胜利侧读道念差 / `life` → `lifeTotal` 归 0 = defeated / 意图分界值 = 越阶硬门 + 同阶差值 / 敌人等级 = `EnemyTemplate` 物化产物 / 全局等级序基数无跳变 / 图鉴五项文案一次全解锁 / 抽象层级五级定名；追加：ch1 分档 1–2 / ≥3、`baseMomentum` 补齐、CharacterPower 定性、平局只发基础奖励、付费口径确认、`lifeTotal` 字段改名） | 15 |
| `log-0801.md` | 2026-08-01 | `90-inbox/draft-0801.md`（玩法循环整体评审后的逐条裁决：道念 = 计分 = 胜负判据 / 寿元定价按目标时长分档 + 跨篇章结转 / 跳过限可选事件 / `manaLimit` 不设护栏 / 隐藏属性跨档定性反馈 / 等级成长 = 事件产出 + 敌人等级精确标注 / 失败侧产出） | 6（另 3 条部分答定） |
| `log-0730b.md` | 2026-07-30 | `90-inbox/draft-0730b.md`（意图三档揭示取代「通常不揭示」/ 例外条件反转 / EnemyManager 不再细分 + CharacterManager 平级 / mana 每回合恢复至上限 / 决策点存档与 `selectCost` 不回滚 / Finale 为战斗变体） | 6 |
| `log-0730.md` | 2026-07-30 | `90-inbox/draft-0730.md`（`.claude` 工程层定位与主从关系 / 寿元红字倒数呈现细节 / IntentManager 并入 EnemyManager） | 3 |
| `log-0728.md` | 2026-07-28 | 直接对话（无草稿来源）：`.claude/knowledge` 引用层形态 → 薄引用，固化为 ADR-0005 | 1 |
| `log-service-api-contracts.md` | 2026-07-27 | `90-inbox/solution-draft-service-api-contracts.md`（七服务 API 契约总则 / 结算阶段名 / CombatResult 归属 / 跨服务调用措辞 / eventOptions 持久化形态） | 5 |
| `log-0727.md` | 2026-07-27 | `90-inbox/draft-0727.md`（内容放量开关 / 双 contentVersion / 增量下载与签名 / 断线韧性 / RNG 持久化 / 存档点频率） | 9 |
| `log-0726b.md` | 2026-07-26 | `90-inbox/draft-0726b.md`（事件优先级 / 跳过语义 / 热更范围 / player-profile 落位） | 8 |
| `log-0725c.md` | 2026-07-25 | 历史累积（07-16 ~ 07-25c 全部批次的一次性迁移） | 35 |
