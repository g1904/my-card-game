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

- `draft-<suffix>.md` —— 手写的零散想法。**`<suffix>` = `MMDD` + 序列字母，从 `a` 起，同日依次 `a` · `b` · `c` …**（例：`draft-0816a.md` · `draft-0816b.md`）。
  **当天第一份也带 `a`，不写裸 `draft-MMDD.md`。** 序列位恒定存在，`ls` 与 `log-*` 后缀才能整齐排序、一眼看出同日批次的先后；裸日期与带字母混排时，同日第一份会脱离它自己的序列。
- `solution-draft-<slug>.md` —— 针对某个待答问题产出的**提案式**方案草稿。front-matter `status` 生命周期：`awaiting-review` → `reviewed` / `decided` → `distilled`（移入 `archive/`）。

## 在办清单

| 文件 | status | 说明 |
|------|--------|------|
| `solution-draft-client-flag-cache-and-binary-overlay.md` | decided | flags 缓存的报文侧对位（`no-cache` 的层次澄清 · 后端对客户端缓存零义务 · B 组第 7 条依赖登记 · 纠正「以支撑离线开局」的错误前提）+ **blob 通道不承载二进制**（对侧已裁「不开放」）、契约零改动。与 `game-design-documents/inbox/solution-draft-client-flag-cache-and-binary-overlay.md` 成对，**须同批提炼** |

清空即为「无在办草稿」。已提炼草稿 → handoff 的对应关系见 `archive/_index.md`。
