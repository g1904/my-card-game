# backend-design —— 后端设计意图

本分支（`backend-design`，在此检出为 `backend-design-documents/`）是**后端设计意图的事实来源**：驱动云端服务的人工 handoff、决策以及持续更新的设计笔记。

它**只包含文档**——独立的孤儿历史，不含后端代码，永远不会合入 `backend-feature → backend-testing → backend-production`。后端工程位于 `backend-feature-branch/`（见 `../main/README.md`）。

游戏客户端（Godot 4.7 / .NET）是**强制在线、云端权威**的：进度实时同步云端，本地 `user://` 仅作缓存。本库承载云端那一侧的设计——账号鉴权、档案存储、内容分发（CDN）、协议契约。

## 为什么与 `game-design` 分开

`game-design` 是**客户端**的设计事实来源。客户端的七个「服务」全部是同一个 Godot 进程内的模块单例，彼此为直接 C# 方法调用；**唯一真实的进程边界是客户端 ↔ 后端**。这条边界两侧的部署节奏、技术栈与发布线都不同，因此文档也分线承载。

跨越这条边界的客户端成分有**三个**：`account-service`、`content-service`、`sync-service`——**全部是服务本身，没有任何 manager 跨边界**。它们在**客户端侧**的门面设计见 `game-design-documents/systems/services/`；**边界另一侧**的实现与报文归本库。剧本内容不跨边界（它是客户端本地内容层的一员，热更走 content-service 的 overlay 通道）。

## 设计意图 vs. Claude 知识库

- **`backend-design-documents/`（此处）** = 原始的人工意图与 handoff。由你掌管。后端设计在此*起源*。
- **`.claude/knowledge/*`** 目前**只覆盖客户端**；后端尚无对应的引用层。Claude 只有在被要求时才会编辑本库的文档。

## 流水线

```
inbox (draft)                          顶层 = 在办；提炼后移入 inbox/archive/
   └─▶ handoffs/<date>-<slug>.md      raw intent, one entry per handoff   (status: raw)
          └─▶ distilled into contracts / systems / operations 活文档       (status: distilled)
                 └─▶ settled choice?  record decisions/ADR-####
                        └─▶ once a doc is fully detailed:  推导需求
                               └─▶ requirements/FR-*.md   片区级 specs + acceptance criteria
                                      └─▶ 拆解
                                             └─▶ requirements/FR-*/   可执行子需求（一个 = 一次 blueprint）
                                                    └─▶ blueprint → implement (backend-feature-branch/)
```

**当前状态：后端尚未开工。** 推导就绪度以 `open-questions.md` 的「derive 就绪度」小节为唯一权威（由 `/assess-derive-readiness` 全量评估后写入），此处不另作断言。契约面**六份全部成文且再无取值留白**；下一步是**技术栈落定**（`open-questions/06-platform-stack.md`）——`systems/` 与 `operations/` 的展开、以及 `requirements/` 的推导都以它为前置。合规路线（`02-account-compliance.md`）余下的是运营口径与风控，可与之并行。见 `open-questions.md` 的「下一阶段」。

> `.claude/` 下的设计流水线技能（`/analyze-new-ideas`、`/provide-solution-draft`、`/summarize-open-questions`、`/assess-derive-readiness`、`/derive-requirements`、`/breakdown-requirements`）**对本库与客户端库通用**：调用时加 `--lib=backend`，或直接给 `backend-design-documents/` 开头的路径；判不出时技能会询问，不会静默默认。解析顺序、跨库纪律与两库结构差异见 `.claude/rules/design-library-routing.md`。
> `/blueprint` 与 `/implement` 仍只面向客户端（`game-feature-branch/`）——后端技术栈未定，无从设计实现形态。

## 根级关键文件

| 文件 | 内容 |
|------|------|
| `README.md` | 本文件：分线理由 + 布局导航 + 维护约定 |
| `open-questions.md` | 后端待答清单的**索引**：分片导航、当前焦点、归属判据、`## derive 就绪度`（由 `/assess-derive-readiness` 独占写入）、下一阶段。问题条目本身在 `open-questions/` 分片中。 |

**术语**不在本库另立一套：领域词（中文 ↔ 代码标识符）的权威在 `game-design-documents/terminology.md`；本库只补充纯后端的工程术语（若有需要，再在此建 `terminology.md`）。

## 文件夹图例

| 文件夹 | 内容 | 可变性 |
|--------|------|--------|
| `vision/` | 北极星：`scope.md`（范围与边界、in/out of scope、硬约束）、`pillars.md`（取舍原则）。 | 稳定，极少编辑。 |
| `contracts/` | **本库的核心产出**：客户端 ↔ 后端协议契约的单一事实来源。**六份全部成文**：`envelope.md`（边界层：表达形式 · 序列化约定 · `/v1/` 信封 · 错误码台账 · 版本协商）· `content-manifest.md`（内容分发、签名、flags）· `auth.md`（七端点、身份主体自建与 account↔identity 模型、双 token、渠道分形 credential、会话裁决与三处 `reasonKey` 取值表）· `profile-sync.md`（pull / push、diff 浅合并、CAS + 幂等、后端可见字段白名单与后端写入字段封闭表、SplitMix64 掷骰复算）· `purchase.md`（验票 + 收据幂等读、写入只由 verify 承担）· `compliance.md`（六端点、`complianceTicket`、拦截只在 `signin`、防沉迷复用 `session_revoked`）。另有 `vectors/`：机器可读的对表产物（当前 `splitmix64.json`）。契约表达形式为 **OpenAPI 3.1 + JSON Schema 单点**；`openapi.yaml` 与 `schemas/*.json` 待任一侧首个端点进入实现时落笔。 | 持续更新；**只保留最新契约**（兼容性靠版本化字段，不靠保留旧形态）。 |
| `systems/` | 各后端服务的内部设计意图，文件名与它所服务的客户端成分对齐。 | 持续更新；**只保留最新设计**。当前空置（栈未定）。 |
| `operations/` | 运行时形态：环境分层、部署与回滚、可观测性、合规运维。 | 持续更新。当前空置（栈未定）。 |
| `handoffs/` | 原始的时间线输入——大多是你的文字，每个 handoff 一个文件。 | 持续更新（时间线日志，最新置顶；可自由编辑 / 修正，非仅追加）。 |
| `decisions/` | ADR 风格的已定决策。**编号与客户端库各自独立**，引用另一侧一律写全路径。**唯一写入者是 `/write-adr`**；ADR 形状、台账约定与「ADR 候选」表见 `decisions/_index.md`。 | 可修改（后端开发尚未开始；直接更新 ADR，不必新开 ADR 取代）。 |
| `requirements/` | 从详细设计推导出的功能需求规格（`FR-*`）——通往实现的桥梁。含 `_index.md` 与两份骨架模板；**当前尚无 FR**。 | 持续更新；随设计深化而重新生成 / 扩展。 |
| `inbox/` | 未整理的草稿，待分流到 handoff / 主题中。**分两层：顶层只放在办草稿，已提炼的移入 `inbox/archive/`**（判据：有无对应 `status: distilled` 的 handoff）。 | 顶层自由发挥；`archive/` 只作溯源。 |
| `open-questions/` | 待答清单的**分片**：`01-contracts.md`（协议契约横切项）、`02-account-compliance.md`（账号与合规，现焦点之首）、`04-content-delivery.md`（内容分发）、`06-platform-stack.md`（技术栈 · 托管 · 运维）、`cross-boundary.md`（**客户端已定案、本库尚未承接**的条目；不带编号，与客户端库同名同形），外加 `update-log.md`（逐次更新摘要）。**编号即优先级；`03` 与 `05` 已作废空缺，不回填、不重排**（原分片随 `profile-sync.md` 成文与云端剧本服务撤销而整片删除）。**只跟踪仍待答的问题**（无「已解决」区）。 | 持续更新。分片过长可再拆、过短可并回，同步更新索引导航表。 |
| `answer-logs/` | 已答定问题从待答清单移出的归档台账，一次移出一份 `log-<draftSuffix>.md`。 | 历史台账；与本库其余文档一样可编辑修正，非仅追加。 |

## 跨库约定：一个东西写在哪一侧

| 判据 | 归属 |
|------|------|
| 由客户端代码实现、后端不感知 | `game-design-documents/` |
| 由后端实现，或需要两侧约定报文 | 本库 |
| 客户端语义已定、只剩服务端如何兑现 | 本库（注明「客户端侧已定」+ 日期 + 回链） |

- **跨边界的意图允许同批写两侧，但一份文档只描述一侧。** 若一次意图同时改动两侧，两侧各写一份 handoff 并互相回链，不要一份文档同时描述两侧。**不允许只改一侧就宣称收口**——被拆成两半的跨边界意图，第二半经常不会发生。
- **不复述另一侧的设计。** 需要客户端语义时回链，只在本库写「后端如何兑现它」。
- **对侧已定案、本库尚未承接的条目落 `open-questions/cross-boundary.md`**，不要散进按主题编号的普通分片——那里的条目等的是设计裁决，而承接项**答案已经有了、等的只是落笔**，混在一起会被一起无限期搁置。

## 维护约定：一切皆可改，只保留最新设计

后端开发尚未开始——本库**没有任何文档是「仅追加」或「一旦定案即不可变」的**（`handoffs/`、`inbox/`、`decisions/` ADR 均可自由编辑 / 重写 / 重构）。要改一份 ADR 的决定，就**直接改这份 ADR**，不必新开一个 ADR 去取代它。

活文档**只保留最新的设计与决策**：当内容被取代 / 重命名 / 迁移时，**直接重写替换**，删除「取代 X / 并入 Y / 原 X / 旧文件保留待清理」等考古与对已删文件的引用。溯源以指向当前 `handoffs/*` 的简短 `Source:` 承载即可；历史 / 回溯归 **git**。

**先有设计再建文件。** `systems/` 与 `operations/` 的计划文档在其 `_index.md` 中登记，但**不预先创建空壳**——避免一堆只有标题的占位文件冒充设计。

## 状态词汇（handoff）

- `raw` — 已捕获，尚未处理。
- `triaged` — 已阅读并分流到正确的主题，但尚未撰写成文。
- `distilled` — 已折叠进某个主题文档（和/或某个 ADR）；`distilled-to:` 指明去向。

## 文件夹命名

顶层文件夹用**纯语义名**（`vision/`、`contracts/`、`systems/` …），不带数字前缀——阅读顺序以上方的文件夹图例为准，而非文件系统排序。与客户端库共有的文件夹（`handoffs/`、`inbox/`、`decisions/`、`requirements/`、`open-questions/`、`answer-logs/`）沿用同名同形，使两库的导航习惯一致。

## 相关

| 分支 | 本地文件夹 | 内容 |
|------|-----------|------|
| `game-design` | `game-design-documents/` | 客户端设计意图（含客户端侧的边界服务门面） |
| `backend-feature` | `backend-feature-branch/` | 后端活跃开发（尚未开工） |
