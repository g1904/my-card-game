# MyCardGame — 设计文档

本分支（`design`，在此检出为 `game-design-documents/`）是**设计意图的事实来源**：驱动游戏的人工 handoff、决策以及持续更新的设计笔记。

它**只包含文档**——独立的孤儿历史，不含游戏代码，永远不会合入 `feature → testing → production`。Godot 项目位于其他分支目录中（见 `../main/README.md`）。

## 设计意图 vs. Claude 知识库
- **`game-design-documents/`（此处）** = 原始的人工意图与 handoff。由你掌管。设计在此*起源*。
- **`.claude/knowledge/*`** = 从这些文档**提炼**而来、面向 Claude 的参考资料。Claude 在此阅读以进行规划；只有在被要求时才会编辑*这些*设计文档。

## 流水线
```
90-inbox (draft)
   └─▶ 10-handoffs/<date>-<slug>.md      raw intent, one entry per handoff   (status: raw)
          └─▶ distilled into 20/30/40 topical living docs                    (status: distilled)
                 └─▶ settled choice?  record 50-decisions/ADR-####
                        └─▶ once a doc is fully detailed:  /derive-requirements
                               └─▶ 60-requirements/FR-*.md   buildable feature specs + acceptance criteria
                                      └─▶ Claude reads knowledge + FR → /blueprint → /implement
```
`90-inbox → 10-handoffs → 20/30/40` 由 `/analyze-new-ideas` 承接。从详细设计到代码的**桥梁**是 `/derive-requirements`，它产出 `60-requirements/FR-*`——即 `/blueprint` 的输入。

## 根级关键文件
| 文件 | 内容 |
|------|------|
| `terminology.md` | **术语事实来源**：中文领域词 ↔ 英文/代码标识符。横跨所有主题文档，故置于根级。提炼至 `.claude/knowledge/dictionary.md`。 |
| `open-questions.md` | 跨 session 的待答清单；主题文档的 `## Open questions` 是权威归属，此处是导航。 |

## 文件夹图例
| 文件夹 | 内容 | 可变性 |
|--------|-----------------|------------|
| `00-vision/` | 北极星：pillars、scope、references。 | 稳定，极少编辑。 |
| `10-handoffs/` | 原始的时间线输入——大多是你的文字，每个 handoff 一个文件。 | **仅追加**（用新条目取代，不重写）。 |
| `20-systems/` | 各玩法系统的设计意图。文件名与 `.claude/knowledge/systems/` 对应。 | 持续更新。 |
| `30-content/` | 内容设计意图（卡牌、relic、敌人……）——即“做什么”，先于 `.tres`。 | 持续更新。 |
| `40-ux/` | 屏幕、流程、手感（文本线框图）。 | 持续更新。 |
| `50-decisions/` | ADR 风格的已定决策。 | **一旦 Accepted 即不可变**（用新的 ADR 取代）。 |
| `60-requirements/` | 从详细设计推导出的功能需求规格（`FR-*`）——通往 `/blueprint` 的桥梁。由 `/derive-requirements` 生成；用户签核（`draft → ready`）。 | 持续更新；随设计深化而重新生成/扩展。 |
| `90-inbox/` | 未整理的草稿，待分流到 handoff/主题中。 | 自由发挥。 |

## 状态词汇（handoff）
- `raw` — 已捕获，尚未处理。
- `triaged` — 已阅读并分流到正确的主题，但尚未撰写成文。
- `distilled` — 已折叠进某个主题文档（和/或某个 ADR）；`distilled-to:` 指明去向。

## 数字前缀
文件夹带编号，使 vision 与 handoff 排序在主题文档之上。主题文件名与 `.claude/knowledge/` 一一对应，因此一个 handoff 能干净地映射到它最终喂入的那份知识笔记。
