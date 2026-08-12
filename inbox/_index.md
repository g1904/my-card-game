# 收件箱（inbox · 后端）

未整理的想法草稿的暂存区。**顶层只放在办的草稿；已被提炼进 `handoffs/` 与主题文档的一律移入 `archive/`。**

## 两层结构

| 位置 | 含义 | 谁写入 |
|------|------|--------|
| `inbox/*.md`（顶层） | **在办**：尚未提炼进 `handoffs/` 与主题文档的草稿。 | 用户手写；`/provide-solution-draft` |
| `inbox/archive/*.md` | **已提炼**：已产出对应 `handoffs/<date>-<slug>.md`（`status: distilled`）的草稿，只作溯源留存。 | 提炼完毕后移入 |
| `_TEMPLATE.md` | 新建草稿的空模板，不是在办条目。 | — |

判据只有一条：**这份草稿有没有对应的 distilled handoff**。有 → `archive/`；没有 → 留在顶层。

## 两类草稿

- `draft-<suffix>.md` —— 手写的零散想法（`<suffix>` 为 `MMDD`，同日多份追加 `b`、`c`）。
- `solution-draft-<slug>.md` —— 针对某个待答问题产出的**提案式**方案草稿。front-matter `status` 生命周期：`awaiting-review` → `reviewed` / `decided` → `distilled`（移入 `archive/`）。

## 在办清单

| 文件 | status | 说明 |
|------|--------|------|
| `draft-combat-system.md` | 未标注 | 战斗回合结构、起手 / 抓牌 / 法力、10 回合 momentum 胜负判定。**内容是客户端玩法，疑似误投本库**——下一步：确认后移交 `game-design-documents/inbox/`，或说明其后端侧诉求。 |

清空即为「无在办草稿」。已提炼草稿 → handoff 的对应关系见 `archive/_index.md`。
