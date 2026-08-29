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

| 文件 | status | 说明 | 下一步 |
|------|--------|------|--------|
| `solution-draft-client-flag-cache-and-binary-overlay.md` | decided | flags 本地缓存的落盘纪律（`schemaVersion` / 三条失效语义 / 写入时点）+ **二进制资产不经 overlay 下发**（已裁）、`Artwork` overlay 收口。与后端库同名草稿成对 | `/analyze-new-ideas`（**须与 `backend-design-documents/inbox/solution-draft-client-flag-cache-and-binary-overlay.md` 同批**） |
| `solution-draft-character-template-pool.md` | decided | 角色模板池：**全池指定**（已裁，覆盖草稿推荐的随机 3 选 1）· 池规模 **4**（已裁）· 首批不做账号级解锁 | `/analyze-new-ideas`（须一并松动 `ADR-0055` 的「随机分配」引用句） |
| `solution-draft-realm-progression-artwork-basis.md` | decided | 境界晋升与 `Artwork` 基数：共有字段保持单格 · 敌人与其余五类不换相 · **玩家角色随境界换形象、按稀疏 `RealmArtwork` 落**（已裁） | `/analyze-new-ideas`（同批删 `common-properties.md:247` 的 ⚠ 行 ⇒ derive 第 1 步前置解除） |
| `solution-draft-exchange-barter-support.md` | decided | Exchange 以物易物：**落地定值以物易物**（已裁）· 支付侧 = 货币 **或** 轮回级持有物 · 含一条会白送商品的漏洞堵法（门面 `Holds` + 前置拒绝，强制项） | `/analyze-new-ideas` |
| `solution-draft-fatigue-in-encounter-tighten.md` | awaiting-review | 疲劳扣减不进 `EncounterSpec` 覆写组（三条理由重估 + 新增「方向不单调」第四条 + 重开判据 ① 收紧）；净落地面 = 文字改写，零字段零数值 | `/analyze-new-ideas`（**含 1 项 `[采纳推荐 — 待复核]`**：`FatigueAmount` 保持双向） |
| `solution-draft-stack-entry-kind-for-item-use.md` | awaiting-review | 用道具的栈条目类型：`StackEntryKind` 增 `UsedItem` · `CombatFeedKind` 增 `ItemUse` · 栈条目补一格 `itemId` | `/analyze-new-ideas`（**含 1 项 `[采纳推荐 — 待复核]`**：不开 `TimingIds.ItemUsed`） |

清空即为「无在办草稿」。已提炼草稿 → handoff 的对应关系见 `archive/_index.md`。
