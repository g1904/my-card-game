# MyCardGame — 设计文档

本分支（`game-design`，在此检出为 `game-design-documents/`）是**客户端设计意图的事实来源**：驱动游戏的人工 handoff、决策以及持续更新的设计笔记。

它**只包含文档**——独立的孤儿历史，不含游戏代码，永远不会合入 `game-feature → game-testing → game-production`。Godot 项目位于其他分支目录中（见 `../main/README.md`）。

**后端的设计意图不在本库**，而在 `backend-design-documents/`（`backend-design` 分支）。本库描述客户端，包括客户端侧那**三个**跨越客户端 ↔ 后端边界的服务——`account-service`、`content-service`、`sync-service`（**跨边界成分全部是服务本身，没有任何 manager 跨边界**）；边界另一侧的账号合规、协议契约、存档同步、内容分发归后端库。剧本内容**不跨边界**：它是客户端本地内容层的一员，热更走 content-service 的 overlay 通道。

## 设计意图 vs. Claude 知识库
- **`game-design-documents/`（此处）** = 原始的人工意图与 handoff。由你掌管。设计在此*起源*。
- **`.claude/knowledge/*`** = **指向本库的薄引用层**（导航表 + 代码现状 + 一句话承重纪律，设计内容不在那里复述）。Claude 由它导航到本库以进行规划；只有在被要求时才会编辑*这些*设计文档。形态权威：`decisions/ADR-0005-knowledge-thin-reference-layer.md`。

## 流水线
```
inbox (draft)                          顶层 = 在办；提炼后移入 inbox/archive/
   └─▶ handoffs/<date>-<slug>.md      raw intent, one entry per handoff   (status: raw)
          └─▶ distilled into systems / art / ux living docs        (status: distilled)
                 └─▶ settled choice?  record decisions/ADR-####
                        │
                        ├─ 系统行为 ─▶ once a doc is fully detailed:  /derive-requirements
                        │                └─▶ requirements/FR-*.md   片区级 feature specs + acceptance criteria
                        │                       └─▶ /breakdown-requirements
                        │                              └─▶ requirements/FR-*/   可执行子需求（一个 = 一次 blueprint）
                        │                                     └─▶ knowledge + FR → /blueprint → /implement
                        │
                        └─ 内容条目 ─▶ /scaffold-content-type ─▶ content/<类型>/_index.md（类型档案）
                                         └─▶ 你的草稿 → /author-content → content/<类型>/<id>.md
                                                └─▶ /blueprint → /implement → .tres
```
`inbox → handoffs → systems / art / ux` 由 `/analyze-new-ideas` 承接。

**两条从设计到代码的路，按「系统行为 vs 内容条目」分流：**

- **系统行为**的桥梁是两步：`/derive-requirements` 产出片区级的 `requirements/FR-*`，`/breakdown-requirements` 再把**一份** FR 拆成同名文件夹内的**可执行子需求**——后者才是 `/blueprint` 的直接输入。两层结构、id 形态、签核语义与拆解粒度判据见 `requirements/_index.md`。
- **内容条目**不经 FR，**直接喂 `/blueprint`**——内容最终落地就是一批 `.tres`，其可构建增量的边界天然就是条目本身。`systems/` 持有**这类内容怎么运作**（类定义），`content/` 持有**有哪些条目**（实例），二者是类 ↔ 实例关系，故平级。约定、类型登记表与依赖链见 `content/_index.md`。Source: `handoffs/2026-08-14c-content-authoring-layer.md`。

**derive 就绪度由 `/assess-derive-readiness` 单独评估**（全量扫描全部主题文档，写入 `open-questions.md` 的「derive 就绪度」小节），**由用户在时机成熟时手动调用**；它是该小节的**唯一写入者**。`/analyze-new-ideas` 与 `/summarize-open-questions` **均不**顺带评估或更新就绪度——逐次 handoff 顺带的判定会迅速过时且互相矛盾。**当前状态见 `open-questions.md` 的「derive 就绪度」小节**——已有少数文档整份判定 ready、另有一批带可独立成立的就绪切片（partial），该小节逐份给出判定与卡点，并列出建议的 derive 顺序（被依赖者在前、须同批处理的成组标出）。

## 根级关键文件
| 文件 | 内容 |
|------|------|
| `terminology.md` | **术语事实来源**：中文领域词 ↔ 英文/代码标识符。横跨所有主题文档，故置于根级。`.claude/knowledge/dictionary.md` 回链本文件，只另留通用的体裁词汇，不复制本作专有术语。 |
| `program-overview.md` | **程序运行总览**：层级词表（service ⊃ manager ⊃ module ⊃ processor ⊃ handler）、服务 / 管理器职责矩阵、启动→登录→核心循环→轮回结束的端到端调用链、内容与档案的加载路径。横跨所有系统，故置于根级。结构与边界权威在 `systems/architecture.md`。 |
| `system-overview.md` | **项目结构与落地形态**：进程边界（service = 进程内模块单例，**非**微服务）、Godot 工程文件夹布局、autoload 注册、service / manager 的代码形态。 |
| `open-questions.md` | 跨 session 待答清单的**索引**：说明、分片导航表、焦点判据、`## derive 就绪度`、`## 下一阶段`。问题条目本身在 `open-questions/` 分片中。 |

## 文件夹图例
| 文件夹 | 内容 | 可变性 |
|--------|-----------------|------------|
| `vision/` | 北极星：pillars、scope、references。 | 稳定，极少编辑。 |
| `handoffs/` | 原始的时间线输入——大多是你的文字，每个 handoff 一个文件。 | 持续更新（时间线日志，最新置顶；可自由编辑 / 修正，非仅追加）。 |
| `systems/` | 各玩法系统的设计意图，以**类概念**组织（每个系统一个「类」，其内容为字段/内嵌类型）。命名与 `.claude/knowledge/systems/` 沿用同一套系统名（知识侧的单系统笔记**在该系统于代码中落地后**才建，不预先占位）。**它持有「这类内容怎么运作」；具体条目归 `content/`。** | 持续更新；**只保留最新设计**（重写替换，见下）。 |
| `content/` | **内容条目（实例层）**：`content/<类型>/<id>.md` 一条内容一份文档，`content/<类型>/_index.md` 是该类型的**档案**（字段核对清单 + id 形态 + 交叉引用表 + 条目台账）。由 `/scaffold-content-type` 开张类型、`/author-content` 写条目、`/audit-content` 对账，产出**直接喂 `/blueprint`**（不经 FR，故完成度只在各类型档案的台账上追踪）。**硬边界：本层不定义字段**——对每个字段只写「填了什么值 + 权威回链」，字段的类型 / 取值域 / 枚举 / 校验语义一律在 `systems/` 那侧。未开张的类型不预先建空文件夹——**当前尚无已开张的类型**，本层只有 `_index.md`（登记表 + 依赖链）与两份骨架 `_TEMPLATE-type.md` / `_TEMPLATE-entry.md`。 | 持续更新；随内容创作滚动增长。 |
| `art/` | 美术与音频的设计意图与生成指导：**两个一级分区** `visuals/`（内含子分区 `animations/`，占位）与 `soundtracks/`，各含总方向 + `references/` + `guides/`。承载 vision 文本、参考登记与 art / audio guide（= 投喂生成工具的 prompt）；**生成出的二进制资产不入本库**，归 `game-feature-branch/`。 | 持续更新；**只保留最新设计**。当前为脚手架阶段。 |
| `ux/` | 屏幕、流程、手感（文本线框图）。 | 持续更新；**只保留最新设计**。 |
| `decisions/` | ADR 风格的已定决策。**唯一写入者是 `/write-adr`**；ADR 形状与台账约定见 `decisions/_index.md`。 | 可修改（软件开发尚未开始；直接更新 ADR，不必新开 ADR 取代）。 |
| `requirements/` | 从详细设计推导出的功能需求规格（`FR-*`）——通往 `/blueprint` 的桥梁。由 `/derive-requirements` 生成、用户签核（`draft → ready`），再由 `/breakdown-requirements` 拆成同名文件夹内的可执行子需求（`FR-*/`）。含 `_index.md`（两层结构 + 覆盖核对）与两份骨架 `_TEMPLATE.md` / `_TEMPLATE-sub.md`；**当前尚无 FR**。 | 持续更新；随设计深化而重新生成/扩展。 |
| `inbox/` | 未整理的草稿，待分流到 handoff/主题中。两类：手写的 `draft-<suffix>.md`（`<suffix>` = `MMDD` + 序列字母，**从 `a` 起**，例 `draft-0816a.md`）；`/provide-solution-draft` 针对某个待答问题产出的**提案式**方案草稿 `solution-draft-<slug>.md`（`status: awaiting-review`，经人工评审后再喂给 `/analyze-new-ideas`）。**分两层：顶层只放在办草稿，已提炼的移入 `inbox/archive/`**（判据：有无对应 `status: distilled` 的 handoff）；约定与在办清单见 `inbox/_index.md`，草稿骨架见 `_TEMPLATE.md`，草稿→handoff 对应表见 `inbox/archive/_index.md`。 | 顶层自由发挥；`archive/` 只作溯源，不再改动。 |
| `open-questions/` | 跨 session 待答清单的**分片**：`01-combat.md` … `07-codex-monetization.md`（焦点区，编号即优先级）、`cross-boundary.md`（**后端已定案、本库尚未承接**的条目；不带编号，与后端库同名同形）、`deferred-content.md`（已搁置的内容充实）、`update-log.md`（逐次更新摘要）+ `update-log-archive.md`（超出保留窗口的旧条目）。**只跟踪仍待答的问题**（无「已解决」区）；主题文档的 `## Open questions` 是权威归属，此处是导航。答定即移出到 `answer-logs/`。 | 持续更新；由 `/analyze-new-ideas` 与 `/summarize-open-questions` 写入。分片过长可再拆、过短可并回，同步更新索引导航表。 |
| `answer-logs/` | 已答定问题从待答清单移出的归档台账，一次移出一份 `log-<draftSuffix>.md`（`draftSuffix` = 对应 `inbox/draft-<suffix>.md` 的后缀 或 `solution-draft-<slug>.md` 的 `<slug>`，无草稿来源则用当天 `MMDD`）。由 `/analyze-new-ideas` 与 `/summarize-open-questions` 写入；`_index.md` 说明命名规则并汇总台账表。 | 历史台账，一次移出新建一份；与本库其余文档一样可编辑修正，非仅追加。 |

## 维护约定：一切皆可改，只保留最新设计
软件开发尚未开始——本库**没有任何文档是「仅追加」或「一旦定案即不可变」的**（`handoffs/`、`inbox/`、`decisions/` ADR 均可自由编辑 / 重写 / 重构）。要改一份 ADR 的决定，就**直接改这份 ADR**，不必新开一个 ADR 去取代它。

活文档**只保留最新的设计与决策**：当内容被取代 / 重命名 / 迁移时，**直接重写替换**，删除「取代 X / 并入 Y / 由 Z 拆出 / 迁入自 / 原 X / 重构说明 / 旧文件保留待清理」等考古与对已删文件的引用。溯源以指向当前 `handoffs/*` 的简短 `Source:` 承载即可；历史 / 回溯归 **git**（项目由 GitHub 版本控制，legacy 需要时可手动取回）。方向来源：`handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。

## 状态词汇（handoff）
- `raw` — 已捕获，尚未处理。
- `triaged` — 已阅读并分流到正确的主题，但尚未撰写成文。
- `distilled` — 已折叠进某个主题文档（和/或某个 ADR）；`distilled-to:` 指明去向。

## 文件夹命名
顶层文件夹用**纯语义名**（`vision/`、`handoffs/`、`systems/` …），不带数字前缀——阅读顺序以本 README 的文件夹图例为准，而非文件系统排序。主题文件名与 `.claude/knowledge/` 沿用同一套系统 / 场景名，因此一个 handoff 能干净地映射到知识层对应的那条引用条目。
