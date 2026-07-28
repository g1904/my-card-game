# MyCardGame — 设计文档

本分支（`game-design`，在此检出为 `game-design-documents/`）是**客户端设计意图的事实来源**：驱动游戏的人工 handoff、决策以及持续更新的设计笔记。

它**只包含文档**——独立的孤儿历史，不含游戏代码，永远不会合入 `game-feature → game-testing → game-production`。Godot 项目位于其他分支目录中（见 `../main/README.md`）。

**后端的设计意图不在本库**，而在 `backend-design-documents/`（`backend-design` 分支）。本库描述客户端，包括客户端侧那四个跨越客户端 ↔ 后端边界的成分——`account-service`、`content-service`、`sync-service` 三个服务，以及 `future-event-service` 内部的 `PlotManager`；边界另一侧的账号合规、协议契约、存档同步、内容分发、剧本下发归后端库。

## 设计意图 vs. Claude 知识库
- **`game-design-documents/`（此处）** = 原始的人工意图与 handoff。由你掌管。设计在此*起源*。
- **`.claude/knowledge/*`** = 从这些文档**提炼**而来、面向 Claude 的参考资料。Claude 在此阅读以进行规划；只有在被要求时才会编辑*这些*设计文档。

## 流水线
```
90-inbox (draft)
   └─▶ 10-handoffs/<date>-<slug>.md      raw intent, one entry per handoff   (status: raw)
          └─▶ distilled into 20-systems / 40-ux living docs                  (status: distilled)
                 └─▶ settled choice?  record 50-decisions/ADR-####
                        └─▶ once a doc is fully detailed:  /derive-requirements
                               └─▶ 60-requirements/FR-*.md   buildable feature specs + acceptance criteria
                                      └─▶ Claude reads knowledge + FR → /blueprint → /implement
```
`90-inbox → 10-handoffs → 20-systems / 40-ux` 由 `/analyze-new-ideas` 承接。内容即系统的字段 / 内嵌类型，故**没有独立的内容文件夹**——内容写在 `20-systems/` 内。从详细设计到代码的**桥梁**是 `/derive-requirements`，它产出 `60-requirements/FR-*`——即 `/blueprint` 的输入。

**derive 就绪度由 `/assess-derive-readiness` 单独评估**（全量扫描全部主题文档，写入 `open-questions.md` 的「derive 就绪度」小节），**由用户在时机成熟时手动调用**；它是该小节的**唯一写入者**。`/analyze-new-ideas` 与 `/summarize-open-questions` **均不**顺带评估或更新就绪度——逐次 handoff 顺带的判定会迅速过时且互相矛盾。**当前状态：全库尚未进入可 derive 的阶段。**

## 根级关键文件
| 文件 | 内容 |
|------|------|
| `terminology.md` | **术语事实来源**：中文领域词 ↔ 英文/代码标识符。横跨所有主题文档，故置于根级。提炼至 `.claude/knowledge/dictionary.md`。 |
| `program-overview.md` | **程序运行总览**：两级层次（service ⊃ manager）、服务 / 管理器职责矩阵、启动→登录→核心循环→轮回结束的端到端调用链、内容与档案的加载路径。横跨所有系统，故置于根级。结构与边界权威在 `20-systems/architecture.md`。 |
| `system-overview.md` | **项目结构与落地形态**：进程边界（service = 进程内模块单例，**非**微服务）、Godot 工程文件夹布局、autoload 注册、service / manager 的代码形态。 |
| `open-questions.md` | 跨 session 的待答清单，**只跟踪仍待答的问题**（无「已解决」区）；主题文档的 `## Open questions` 是权威归属，此处是导航。答定即移出到 `answer-logs/`。 |

## 文件夹图例
| 文件夹 | 内容 | 可变性 |
|--------|-----------------|------------|
| `00-vision/` | 北极星：pillars、scope、references。 | 稳定，极少编辑。 |
| `10-handoffs/` | 原始的时间线输入——大多是你的文字，每个 handoff 一个文件。 | 持续更新（时间线日志，最新置顶；可自由编辑 / 修正，非仅追加）。 |
| `20-systems/` | 各玩法系统的设计意图，以**类概念**组织（每个系统一个「类」，其内容为字段/内嵌类型）。文件名与 `.claude/knowledge/systems/` 对应。 | 持续更新；**只保留最新设计**（重写替换，见下）。 |
| `40-ux/` | 屏幕、流程、手感（文本线框图）。 | 持续更新；**只保留最新设计**。 |
| `50-decisions/` | ADR 风格的已定决策。 | 可修改（软件开发尚未开始；直接更新 ADR，不必新开 ADR 取代）。 |
| `60-requirements/` | 从详细设计推导出的功能需求规格（`FR-*`）——通往 `/blueprint` 的桥梁。由 `/derive-requirements` 生成；用户签核（`draft → ready`）。 | 持续更新；随设计深化而重新生成/扩展。 |
| `90-inbox/` | 未整理的草稿，待分流到 handoff/主题中。两类：手写的 `draft-<suffix>.md`；`/provide-solution-draft` 针对某个待答问题产出的**提案式**方案草稿 `solution-draft-<slug>.md`（`status: awaiting-review`，经人工评审后再喂给 `/analyze-new-ideas`）。 | 自由发挥。 |
| `answer-logs/` | 已答定问题从 `open-questions.md` 移出的归档台账，一次移出一份 `log-<draftSuffix>.md`（`draftSuffix` = 对应 `90-inbox/draft-<suffix>.md` 的后缀 或 `solution-draft-<slug>.md` 的 `<slug>`，无草稿来源则用当天 `MMDD`）。由 `/analyze-new-ideas` 与 `/summarize-open-questions` 写入。 | 历史台账，一次移出新建一份；与本库其余文档一样可编辑修正，非仅追加。 |

## 维护约定：一切皆可改，只保留最新设计
软件开发尚未开始——本库**没有任何文档是「仅追加」或「一旦定案即不可变」的**（`10-handoffs/`、`90-inbox/`、`50-decisions/` ADR 均可自由编辑 / 重写 / 重构）。要改一份 ADR 的决定，就**直接改这份 ADR**，不必新开一个 ADR 去取代它。

活文档**只保留最新的设计与决策**：当内容被取代 / 重命名 / 迁移时，**直接重写替换**，删除「取代 X / 并入 Y / 由 Z 拆出 / 迁入自 / 原 X / 重构说明 / 旧文件保留待清理」等考古与对已删文件的引用。溯源以指向当前 `10-handoffs/*` 的简短 `Source:` 承载即可；历史 / 回溯归 **git**（项目由 GitHub 版本控制，legacy 需要时可手动取回）。方向来源：`10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。

## 状态词汇（handoff）
- `raw` — 已捕获，尚未处理。
- `triaged` — 已阅读并分流到正确的主题，但尚未撰写成文。
- `distilled` — 已折叠进某个主题文档（和/或某个 ADR）；`distilled-to:` 指明去向。

## 数字前缀
文件夹带编号，使 vision 与 handoff 排序在主题文档之上。主题文件名与 `.claude/knowledge/` 一一对应，因此一个 handoff 能干净地映射到它最终喂入的那份知识笔记。
