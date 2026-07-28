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
| `log-0728.md` | 2026-07-28 | 直接对话（无草稿来源）：`.claude/knowledge` 引用层形态 → 薄引用，固化为 ADR-0005 | 1 |
| `log-service-api-contracts.md` | 2026-07-27 | `90-inbox/solution-draft-service-api-contracts.md`（七服务 API 契约总则 / 结算阶段名 / CombatResult 归属 / 跨服务调用措辞 / eventOptions 持久化形态） | 5 |
| `log-0727.md` | 2026-07-27 | `90-inbox/draft-0727.md`（内容放量开关 / 双 contentVersion / 增量下载与签名 / 断线韧性 / RNG 持久化 / 存档点频率） | 9 |
| `log-0726b.md` | 2026-07-26 | `90-inbox/draft-0726b.md`（事件优先级 / 跳过语义 / 热更范围 / player-profile 落位） | 8 |
| `log-0725c.md` | 2026-07-25 | 历史累积（07-16 ~ 07-25c 全部批次的一次性迁移） | 35 |
