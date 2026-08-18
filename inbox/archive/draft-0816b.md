---
type: draft
date: 2026-08-16
topic: 活文档收口（二）—— 正文去坐标化 + Source 合并到小节级
scope: vision/ · systems/ · art/ · ux/ · content/ · decisions/ · requirements/ · 根级三个横切文件
status: obsolete
closed: 2026-08-16 — 核查后无实质待办，未执行即关闭。活文档正文日期戳实测 7 处（草稿声称 1,408），且 7 处全在 `open-questions.md` —— 那是本草稿自己明令不动的过程档案，是验收脚本 ① 误把根级 `*.md` 纳入范围所致；1,408 接近**全库含过程档案**的口径（1,510），即统计范围与声明范围不一致。`handoffs/` 路径残留 4 处全在 `README.md`（讲文件夹图例）；考古动词残留 2 处是 `ADR-0003` 与 `decisions/_index.md` 里「决策可被推翻 / 不必新开 ADR 取代」的治理原则正面陈述。`Source:` 硬规则（每 `##` 小节 ≤1 条 handoff Source）逐文件核对无违规 —— 115 的计数混入了行内 `Source: .claude/rules/*.md` 工程规则回链，那是另一类引用，`systems/common-properties.md` 第 97 行已解释其含义。
batch: 2 of 3
order: 在 `draft-0816a.md`（删「已定案」）**之后**跑——那批先清掉与坐标缠在一起的空戳，本批的判断面才干净
note: 本批工作量最大，**按下方四个子批分多个 session 执行**，不要一次吃完
---

# 收口批次二 — 正文去坐标化

## 为什么

活文档要**独立可读**：读者理解当前设计时，**永远不需要打开一份 handoff**。现状离这个目标很远：

| 症状 | 数量 |
|---|---|
| 正文中的 handoff 日期戳（`08-12` / `07-27b` / `08-15d` 这类） | **1,408 处** |
| 指向 `handoffs/` 的 `Source:` 链接 | **658 处**（而 handoff 只有 57 份 ⇒ 同一份被重复引用十余次） |
| 「推翻 / 取代 / 作废 / 原方案 / 由 X 降为」 | **约 80 处** |

活文档正文合计约 7,176 行 ⇒ 平均**每 11 行一个 handoff 回链**。典型句子长这样：

> **`OpResult.Detail` 是诊断串（已定案 · 08-12 · 推翻 07-27b 的「面向玩家的原因串」）。**

读者要理解「Detail 是什么」，得先在脑内解析一段变更史。这**直接违反根约定**「活文档只保留最新设计，删除『取代 X / 原 X』等考古」——约定一直写着，但从没有一次收口去执行它，于是每次 handoff 提炼都往上叠一层。

## 核心判据：保留理由，删除坐标

这是本批**唯一需要动脑的地方**，也是最容易做错的地方。

被推翻的旧方案，如果它的**否决理由仍然承重**（不写下来，日后会有人重新提出同一个方案），把**理由本身**写成正面陈述留在正文——但**不写它推翻了谁、在哪一天**。

> **判据：删掉这段话之后，未来的读者（包括未来的你、以及下一个 session 的模型）会不会重新提出那个已被否决的方案？**
> 会 ⇒ 理由承重，改写保留。
> 不会 ⇒ 纯坐标，直接删。

### 承重 —— 改写保留

```
✗ 手牌上限 7（08-15d · 推翻 balance.md 原写的否决论据「取 7 会让上限成为常态惩罚」）
✓ 手牌上限 7 —— 上限会成为常态咬合的紧约束，这个后果是被接受的设计取向，不是待修的副作用。
```
理由承重：不写，下次有人看到「7 太紧」就会提议改回 9。
但**「推翻了 balance.md 原论据」「08-15d」这两个坐标不承重**——它们不阻止任何人重提，只是告诉你这事发生过。

```
✗ **`OpResult.Detail` 是诊断串（08-12 · 推翻 07-27b 的「面向玩家的原因串」）。**
✓ **`OpResult.Detail` 是诊断串，UI 永不直接渲染它。**
   它不兼「可展示」身份——一旦可能被渲染，英文调试串就随时可能漏到屏上，且三条承重纪律一条也无法机械检查。
```

### 不承重 —— 直接删

```
✗ 由四个降为三个（08-11）：`IPlotBackend` 整套作废，条件编译清单同步由 6 处降为 5 处。
✓ 三个后端接口全部落在服务身上，`manager` 没有跨边界的例外。条件编译共 5 处，不得扩张。
```
「曾经是四个 / 6 处」不承重——当前是三个 / 5 处，这就是全部需要知道的。谁也不会因为不知道曾有四个而做错事。

```
✗ combat-service 的战场与栈各自一个 manager（08-03）。
✓ combat-service 的战场与栈各自一个 manager。
```

### 边界情形

- **「不再 / 改为」**（100 + 14 处）：多数是纯坐标（「不再走 X」= 现在走 Y，写清 Y 即可）。但有一类承重：**「不再」是在挡住一条看起来很自然的做法**（「PlotManager 不再持有后端接口」——不写，下次有人会给它加一个）。这类改写为正面禁令 + 理由：「后端接口只落在服务上；manager 不跨边界，否则边界纪律出现例外，无法机械检查。」
- **`decisions/ADR-*` 的 `Superseded by` / 状态字段**：ADR 有自己的状态机，**本批不动 ADR 的 frontmatter**，只清正文里的日期戳。
- **`answer-logs/` / `update-log.md` 的链接**：若正文指向它们（而非 handoff），保留——那是「这个问题的答定过程在哪里」，与设计正文是不同层的信息，且不构成阅读障碍。

## `Source:` 的处置

**规则：一个 `##` 小节最多一条 `Source:`，放在小节末尾。** 整份文档由单一 handoff 承载时上提到文档头部。

同一个 handoff 在一份文档里出现两次以上 ⇒ 合并。多个 handoff 共同承载一个小节 ⇒ 一行里并列（`Source: handoffs/a.md · handoffs/b.md`）。

目标：658 → **约 85**（每份活文档 1–3 条）。

```bash
# 每份文档的自查：Source 数应 ≤ 该文档的 ## 小节数
grep -c "^Source:\|Source: \`handoffs" <文件>
grep -c "^## " <文件>
```

## 四个子批（按引用密度排序，一批一个 session）

| 子批 | 范围 | Source 链接 | 日期戳 |
|---|---|---|---|
| **2a** | `systems/architecture.md` · `systems/balance.md` · `systems/common-properties.md` · `systems/services/` | 246 | 593 |
| **2b** | `systems/adventure-event/` | 106 | 207 |
| **2c** | `systems/character-profile/` · `systems/player-profile/` · `systems/enemies/` | 159 | 319 |
| **2d** | `ux/` · `vision/` · `art/` · `content/` · `decisions/` · `requirements/` · `terminology.md` · `program-overview.md` · `system-overview.md` | 166 | 320 |

**先跑 2a，然后停下来让人读一遍 `systems/services/combat-service.md`**，确认读感确实变清爽、且没有丢掉承重理由。确认无误再铺开 2b–2d。**2a 是验证批，不要和 2b 连着跑。**

## 每份文档的执行流程

1. **通读全文**（不是只看 grep 命中行）——判断「理由是否承重」需要上下文。
2. `grep -nE "\b0[0-9]-[0-3][0-9][a-e]?\b|handoffs/|推翻|取代|作废|原方案|由.*降为|不再|改为"` 列出候选。
3. 逐处按上面的判据分类：**纯坐标（删）/ 承重理由（改写）/ Source 行（合并）**。
4. 改写时**只动措辞，不动设计**：新句子表达的机制、数值、约束必须与原句完全一致。
5. `Source:` 合并到小节末。
6. 自查两条 grep（见下）。

## 验收

```bash
cd game-design-documents

# ① 正文无日期戳（Source: 行本身允许出现 handoff 文件名，故排除）
grep -rn --include="*.md" -E "\b0[0-9]-[0-3][0-9][a-e]?\b" vision systems art ux content requirements *.md | grep -v "^[^:]*:[0-9]*:Source:"

# ② 正文无 handoffs/ 路径（同样排除 Source: 行）
grep -rn --include="*.md" "handoffs/" vision systems art ux content requirements *.md | grep -v "Source:"

# ③ 考古动词归零（承重的已改写为正面陈述）
grep -rn --include="*.md" -E "推翻|取代|作废|原方案|由.*降为" vision systems art ux content decisions requirements

# ④ Source 总数
grep -rc "Source:" --include="*.md" vision systems art ux content decisions requirements | awk -F: '{s+=$2}END{print "Source 总数:", s}'   # 目标 ≈ 85

# ⑤ 过程档案未被动过
git diff --stat -- handoffs/ inbox/ answer-logs/ open-questions/   # 应为空
```

**人工复核（必做）：** 逐条列出走「承重理由改写」的处置（预计 15–30 处），给用户过一遍。这是本批唯一可能出错且 grep 查不出来的地方——**删掉一条承重理由，代价是几个月后重新讨论一个已经讨论过的问题**。

## 不要做

- **不改任何设计取值、机制、数值。** 本批只改「怎么说」，不改「说了什么」。
- **不重排小节顺序、不合并 / 拆分文档。**
- **不动过程档案**：`handoffs/` · `inbox/` · `answer-logs/` · `open-questions/`。它们记录当时状态，日期戳在那里是正当的；git 也保留着完整历史。
- **不删 handoff 文件。** 本批切断的是**活文档对它们的依赖**，不是它们本身——它们仍是 `/analyze-new-ideas` 流水线的活输入。
- **拿不准是否承重就保留并标记**，在报告里列出来问用户。误删一条承重理由，比多留一句话贵得多。

## 完成后

已由 `/analyze-new-ideas` 第 6b 步「溯源三条」第 ①②  条固化为写入纪律（`author-content` / `derive-requirements` / `breakdown-requirements` / `scaffold-content-type` 各有精简版回链，`audit-content` 检查项 I 可机械复查 `content/`），未来不会再长回来。

若本批做完读感确实改善，考虑把这套流程封装成 `/consolidate-design` 技能——每积累 10 份 handoff 跑一次收口。
