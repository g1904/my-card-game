---
type: draft
date: 2026-08-16
topic: 活文档收口（三）—— open-questions.md 索引瘦身
scope: open-questions.md（索引，唯一写入目标）· open-questions/update-log.md（接收下沉内容）
status: awaiting-execution
batch: 3 of 3
order: **完全独立，随时可跑**——与 `draft-0816a.md` / `draft-0816b.md` 无依赖，改动面只有两个文件
effort: 小（预计一个 session 内完成，且风险低——见下方「已核实：是纯双写」）
---

# 收口批次三 — open-questions.md 索引瘦身

## 现状

`open-questions.md` 自称是**索引**，文件头写着「本文件是待答清单的**索引**；问题条目本身按主题拆在 `open-questions/` 下的分片里」。

但它的实际形态是：

| 行 | 内容 | 体量 |
|---|---|---|
| 1 | `# Open questions — 跨 session 待答清单（索引）` | 57 字符 |
| 3–5 | 说明块（本文件是什么 / 流程） | 683 字符 |
| **7–39** | **19 条历史更新摘要**（`最近更新` + `上一次更新` + 17 条 `更早`） | **约 33,000 字符** |
| 41– | `## 分片导航`（**这才是索引的本体**） | — |

单条摘要最长 **3,957 字符**（08-15d 那条），次长 2,751（08-16）。这些是 markdown 单行，行数只算 1，但渲染出来每条都是半页到一页。

**结果：索引的本体 `## 分片导航` 被推到第 41 行、约 34,000 字符之后。** 一份「用来快速拾起上次进度」的文件，变成了全库最难读的一份——要找分片列表，得先滚过 19 屏裁决摘要。

## 已核实：是纯双写，不是唯一副本

逐条核对过索引顶部的 19 条摘要与 `open-questions/update-log.md` 的条目：

```
索引 08-16    ↔ update-log ## 2026-08-16（体检 12 项逐条裁决 · 手牌上限 9 → 7）
索引 08-15d   ↔ update-log ## 2026-08-15d（敌人意图整条移除 · 寿元成本按告警档展示 · 全库过度设计体检）
索引 08-15c   ↔ update-log ## 2026-08-15c
索引 08-15b   ↔ update-log ## 2026-08-15b
索引 08-14b   ↔ update-log ## 2026-08-14b
索引 08-14    ↔ update-log ## 2026-08-14
索引 08-13    ↔ update-log ## 2026-08-13
索引 08-12f…b ↔ update-log ## 2026-08-12f … ## 2026-08-12b
索引 08-12    ↔ update-log ## 2026-08-12
索引 08-11c/b/↔ update-log ## 2026-08-11c / 11b / 11
索引 08-10    ↔ update-log ## 2026-08-10c（solution-draft-ability-deprivation-and-player-statistics）
```

**19 条全部一一对应**，且 `update-log.md` 覆盖更完整（一直回溯到 `## 2026-08-01`，共 38 条）。`update-log.md` 的文件头也明写它就是这些内容的归宿：「每次运行后在此**顶部**追加一条更新摘要」。

⇒ **索引顶部的 19 条摘要删掉，零信息损失。** 它们是在两个地方各写一遍造成的重复。

## 执行

### 1. 逐条核对（唯一需要小心的一步）

**不要凭日期匹配就删。** 逐条比对索引版本与 `update-log.md` 对应条目的**内容**：

- 索引版本的每一个结论、数值、裁决，`update-log.md` 里是否都有？
- 索引版本里有而 update-log 没有的细节 ⇒ **先把它补进 `update-log.md` 对应条目**，再删索引里的。

已核对过日期一一对应，但**内容级的逐条核对必须在执行时重做一遍**——索引版本可能在某次更新时被单独扩写过。

### 2. 重写索引

目标形态（全文控制在 60 行以内，说明块 ≤ 15 行、每行 ≤ 200 字）：

```markdown
# Open questions — 跨 session 待答清单（索引）

> 本文件是**客户端**（Godot 项目）待答清单的**索引**：问题条目按主题拆在 `open-questions/` 下的分片里。
> 后端侧的清单在 `backend-design-documents/open-questions.md`。
>
> 本清单**只跟踪仍待答的问题**（无「已解决」区）。答定即移出分片、归档进对应主题文档的
> `## 决策` / `## 意图`，并记入 `answer-logs/`。清单是导航 / 拾取用，**权威归属在各主题文档**。
>
> 最近更新：2026-08-16 — 体检 12 项逐条裁决 · 手牌上限 9 → 7
> （逐次变更摘要见 `open-questions/update-log.md`；逐条移出记录见 `answer-logs/`）

## 分片导航
<原表原样保留>

## 当前焦点：各系统机制细节
<原样保留>

## derive 就绪度
<原样保留 —— 该小节由 /assess-derive-readiness 独占写入，本批不得改动>

## 下一阶段
<原样保留>
```

### 3. 顺带清理正文里的超长行

`## 当前焦点` 的焦点判据行（439 字符）、`## 下一阶段` 的 ADR 状态行（747 字符）也超过 200 字上限。**拆成多个短行或子弹**，内容一字不改——只改断行。

`## derive 就绪度` 小节的两行（259 / 288 字符）**原样不动**：该小节由 `/assess-derive-readiness` 独占写入，本批不得改动（含断行）。

## 验收

```bash
cd game-design-documents

# ① 说明块 ≤ 15 行
awk '/^# /,/^## 分片导航/' open-questions.md | wc -l

# ② 说明块无超长行（应无输出；derive 就绪度小节不在此范围内）
awk '/^# /,/^## 分片导航/' open-questions.md | awk 'length>200 {print NR": "length}'

# ③ 全文行数
wc -l open-questions.md          # 目标 ≤ 60

# ④ 全文字符数（这是真正的体量指标）
wc -c open-questions.md          # 当前 ≈ 36,000 → 目标 ≈ 3,000

# ⑤ 「最近更新」只剩一条，无「上一次更新 / 更早」
grep -c "更早：\|上一次更新" open-questions.md    # 应为 0

# ⑥ derive 就绪度小节逐字未变
git diff open-questions.md | grep -A20 "derive 就绪度"   # 应无该小节的增删行

# ⑦ 分片与 answer-logs 未被动过
git diff --stat -- open-questions/0*.md open-questions/deferred-content.md answer-logs/   # 应为空
```

## 不要做

- **不改任何分片文件**（`open-questions/0*.md` · `deferred-content.md`）——本批只动索引与 `update-log.md`。
- **不裁决、不移出、不新增任何待答问题。** 那是 `/summarize-open-questions` 与用户的事。
- **不动 `## derive 就绪度` 小节**（含断行）——它由 `/assess-derive-readiness` 独占写入。
- **不删 `update-log.md` 的任何内容**，只往里补（如果发现索引版本有独有细节）。

## 完成后

已由 `/summarize-open-questions` 第 5 步与 `/analyze-new-ideas` 第 8a 步固化为写入纪律：「最近更新」只写一行 + 链接，说明块 ≤ 15 行且每行 ≤ 200 字，超限内容下沉 `update-log.md`。两个技能都被授权**就地下沉**超限内容（索引是派生的导航文件，非事实来源），所以不会再长回来。

**后端库已核实，无需同批处理（2026-08-16）：** `backend-design-documents/open-questions.md` 全文 94 行 / 6,682 字符，`## 分片导航` 在第 15 行，说明块无超长行——唯二超 200 字的两行都在 `## derive 就绪度` 小节内，那是 `/assess-derive-readiness` 的独占地盘，本就不该动。**该库不需要跑本批次。**
