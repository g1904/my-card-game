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
| `solution-draft-echo-validation-scope.md` | awaiting-review | 上行整键回声校验的适用面（后端半）：**恒等式「受约束 path ≡ §5 后端写入字段表的行集合」** ⇒ 适用面结构性封闭、扩表自动连带，无需第二份清单 · 判据是**所有权**不是透明性 · 比较口径 = **类型感知的语义相等**（`createdAtUtc` 按时刻 · `identities` 有序逐元素）· 判定顺序 `schemaVersion` → CAS → 回声且拒绝不消耗 revision · **§4 拒绝清单由三类扩为四类**（上游草稿登记的「两类变三类」计数有误）· 新刚性「受约束键内追加字段 = 两侧同批」，`envelope.md` §8 须留一句指路。**跨库**，与 `game-design-documents/inbox/` 同名草稿**成对采纳**。**3 项取向已于 08-22 批量评审全部裁决**。**前置已解除**（2026-08-22）：`solution-draft-bundle-grant-ordinal-authority.md` 已提炼落笔（→ `contracts/profile-sync.md` §5c 回声规则本体 + §5 白名单行 + §8 读己所写、`contracts/purchase.md` §6 §7），本稿可直接 `/analyze-new-ideas`——它是在那之上的**通则化**（恒等式 · 比较口径 · §4 计数订正 · `envelope.md` §8 指路） |

清空即为「无在办草稿」。已提炼草稿 → handoff 的对应关系见 `archive/_index.md`。
