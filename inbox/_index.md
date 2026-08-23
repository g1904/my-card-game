# 收件箱（inbox）

未整理的想法草稿的暂存区。**顶层只放在办的草稿；已被 `/analyze-new-ideas` 提炼过的一律移入 `archive/`。**

## 两层结构

| 位置 | 含义 | 谁写入 |
|------|------|--------|
| `inbox/*.md`（顶层） | **在办**：尚未提炼进 `handoffs/` 与主题文档的草稿。 | 用户手写；`/provide-solution-draft` |
| `inbox/archive/*.md` | **已提炼**：已产出对应 `handoffs/<date>-<slug>.md`（`status: distilled`）的草稿，只作溯源留存。 | `/analyze-new-ideas` 处理完毕后移入 |
| `_TEMPLATE.md` | 新建草稿的空模板，不是在办条目。 | — |

归档的前置条件是**三条同时成立**：handoff 已写就且 `status: distilled` · 草稿 front matter 已改 `distilled` · **由它答定的问题已移出 `open-questions/` 并记入 `answer-logs/`**。
有任一条不成立 → 草稿**留在顶层**，并在下方「在办清单」的「下一步」列写清还差什么。

> **注意第三条。** 一份草稿可以既有 distilled handoff、又仍在顶层——典型情形是它含 `[采纳推荐 — 待复核]` 项：
> 设计已按推荐落笔，但那几项**不算用户拍板**，仍留在待答清单里，故「问题已移出」不成立。
> 顶层因此同时承载两类：**尚未提炼的**，和**已提炼但仍欠一次用户复核的**。两者的区别只在「下一步」列。

## 两类草稿

- `draft-<suffix>.md` —— 手写的零散想法。**`<suffix>` = `MMDD` + 序列字母，从 `a` 起，同日依次 `a` · `b` · `c` …**（例：`draft-0816a.md` · `draft-0816b.md`）。
  **当天第一份也带 `a`，不写裸 `draft-MMDD.md`。** 序列位恒定存在，`ls` 与 `log-*` 后缀才能整齐排序、一眼看出同日批次的先后；裸日期与带字母混排时，同日第一份会脱离它自己的序列。
  归档区 `archive/` 里 08-10 之前的裸日期命名是这条约定成文之前的历史，**不追溯重命名**。
- `solution-draft-<slug>.md` —— `/provide-solution-draft` 针对某个待答问题产出的**提案式**方案草稿。它有自己的 front-matter `status` 生命周期：`awaiting-review`（待人工评审）→ `reviewed` / `decided`（已裁决，可喂给 `/analyze-new-ideas`）→ `distilled`（已提炼，移入 `archive/`）。

## 在办清单

顶层现有 **14 份**，**全部属 B 类**（已提炼进设计库，只欠归档三前置条件的第三条——由它们答定的问题移出 `open-questions/`）。
A 类（尚未提炼）当前为空。

### B 类 · 已提炼待归档（14 份）

**上批 7 份（2026-08-22 第一轮批量提炼）。** 各含 `[采纳推荐 — 待复核]` 项，**那 14 个子项已于 2026-08-22 经批量评审逐项确认、无一推翻**（见各草稿的 `confirmed:` 行）。它们只欠把对应条目移出 `open-questions/` 并记入 `answer-logs/`。

| 文件 | status | 已提炼进 | 下一步 |
|------|--------|----------|--------|
| `solution-draft-event-outcome-spec-fields.md` | distilled | `handoffs/2026-08-22-event-outcome-spec-fields.md` | 2 项已确认 → 移出 `open-questions/02-event-options.md` 对应条目后归档 |
| `solution-draft-priority-elevation-conditions.md` | distilled | `handoffs/2026-08-22-priority-elevation-criterion.md` | 1 项已确认 → 移出 `open-questions/02-event-options.md` 对应条目后归档 |
| `solution-draft-remaining-event-decision-points.md` | distilled | `handoffs/2026-08-22-non-combat-decision-points.md` | 2 项已确认（含「每个决策点立即原子写」那句全称表述的连带改写）→ 移出 `open-questions/01-combat.md` 对应条目后归档 |
| `solution-draft-enemy-pool-chapter-scoping.md` | distilled | `handoffs/2026-08-22-enemy-pool-chapter-scoping.md` | 1 项已确认 → 移出 `open-questions/01-combat.md` 对应条目后归档 |
| `solution-draft-band-boundary-config-placement.md` | distilled | `handoffs/2026-08-22-band-boundary-config-placement.md` | 3 项已确认 → 移出 `open-questions/01-combat.md` 对应条目后归档 |
| `solution-draft-refresh-token-client-storage.md` | distilled | `handoffs/2026-08-22-refresh-token-client-storage.md` | 2 项已确认 → 移出 `open-questions/05-service-contracts.md` 对应条目后归档 |
| `solution-draft-flags-fetch-throttle.md` | distilled | `handoffs/2026-08-22-flags-fetch-throttle.md` | 2 项已确认 → 移出 `open-questions/05-service-contracts.md` 对应条目后归档 |

**本批 7 份（2026-08-22 第二轮批量提炼）。** 主问已答结、已提炼；各自仍带若干 `[采纳推荐 — 待复核]` 取向项，**尚未经用户复核**——按铁律 ① 不计作拍板，已作为待复核条目留在待答清单里。

| 文件 | status | 已提炼进 | 下一步 |
|------|--------|----------|--------|
| `solution-draft-singleton-balance-resource-registry.md` | distilled | `handoffs/2026-08-22-singleton-balance-resource-registry.md` | 4 项待复核（`open-questions/01-combat.md`「单例平衡资源的注册形态复核」）→ 复核通过后归档 |
| `solution-draft-card-counters-api-and-key-space.md` | distilled | `handoffs/2026-08-22-card-counters-api-and-key-space.md` | 4 项待复核（`01-combat.md`「counters 键空间的四项形态」）→ 复核通过后归档 |
| `solution-draft-enemy-deck-size-and-fatigue-knob.md` | distilled | `handoffs/2026-08-22-enemy-deck-size-and-fatigue-knob.md` | 3 项待复核（`01-combat.md`「敌人卡组规模与疲劳旋钮的三项形态」）→ 复核通过后归档 |
| `solution-draft-hidden-stat-grant-direction.md` | distilled | `handoffs/2026-08-22-hidden-stat-grant-direction.md` | 3 项待复核（`02-event-options.md` 三条 `HiddenStat*`）→ 复核通过后归档 |
| `solution-draft-locationcodex-edge-granularity.md` | distilled | `handoffs/2026-08-22-locationcodex-edge-granularity.md` | 2 项待复核（`02-event-options.md`「边缘顶点显示程度与显影半径」）→ 复核通过后归档 |
| `solution-draft-eventcountlimit-plot-modulation.md` | distilled | `handoffs/2026-08-22-eventcountlimit-plot-modulation.md` | 1 项待复核（`02-event-options.md`「只约束剧本层、overlay 照常可改」）→ 复核通过后归档 |
| `solution-draft-plot-tree-chapter-packaging.md` | distilled | `handoffs/2026-08-22-plot-tree-chapter-packaging.md` | 3 项待复核（`04-hidden-attributes-plot.md`「剧本树不分包的三项配套裁决」）→ 复核通过后归档 |

> 第 14 个待复核项（`lifeSpanCost` 一律定值）来自已归档的 `archive/solution-draft-event-option-materialized-fields.md`，同批确认；
> 该条目仍挂在 `open-questions/02-event-options.md`，随上批 7 份一并移出。归档区文件按约定不追溯改写。

清空即为「无在办草稿」。已提炼草稿 → handoff 的对应关系见 `archive/_index.md`。
