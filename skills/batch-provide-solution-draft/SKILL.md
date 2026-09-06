---
name: batch-provide-solution-draft
description: /provide-solution-draft 的批量版：一次为一批待答问题并行推演方案草稿（每个 worker 一个问题 / 一组紧耦合问题），收尾把所有草稿的「仍需用户决定」与「张力 / 前置依赖」合并去重，开一场大 interview 由用户统一裁决，并把裁决写回各草稿。覆盖客户端与后端两库。不裁决问题本身、不改任何设计文档。
argument-hint: [--lib=game|backend|两库] <问题关键词清单（分号分隔）| 分片名 | 空（列出候选让用户圈选）>
---

# Batch Provide Solution Draft

编排规则见 `.claude/rules/batch-orchestration.md`（角色、铁律、run 目录、worker 契约）。worker 执行的单会话技能是 **`/provide-solution-draft`**——每份草稿怎么推演、怎么写，全部以它为准，本技能只管编排。

批量相对逐个跑的价值：一次评审会覆盖两库的一批问题；**前置依赖交叉**（草稿 A 依赖草稿 B 正在答的问题）在同一场 interview 里可见；重复 / 相似的取向选择合并成一问，不再让用户在多个 session 里答同一类问题。

## 步骤

### 1. 圈定批次（用户确认，强制）
- 解析库参数：`game` / `backend` / `两库`（默认两库都列候选）。
- **有问题清单** → 逐条在 `<LIB>/open-questions/` 分片与主题文档待决小节中定位；定位不到的列出报告，不猜。
- **给了分片名**（如 `01-combat`）→ 该分片全部条目为候选。
- **空** → 照 `/provide-solution-draft` 第 1 步的空参数逻辑，读两库分片，列出待答条目并标注「适合推演」vs「必须由用户取向决定」。
- 把候选清单（含库归属、权威文档指向、适合度标注）呈现给用户**圈选本批范围**。纯取向问题默认不入批——除非用户点名（此时草稿会以取向选择为主体，interview 负担更重，如实说明）。

### 2. 分组与分区
- **紧耦合、必须一起答的问题** → 并入同一 worker（与单会话技能「一次一个问题或一组紧耦合子问题」一致）。
- **跨库问题**（横跨客户端 ↔ 后端边界）→ 交给**一个** worker 按单会话技能第 6c 步在两侧各写一份草稿，不拆给两个 worker。
- orchestrator **预分配每份草稿的 `<slug>`**（互不相同、且与 `inbox/` 既有文件不撞），随派单下发——并行 worker 各自起名会撞名。
- 写入面检查：每个 worker 只写自己的 `inbox/solution-draft-<slug>.md`（跨库的多一份对侧草稿）；`inbox/_index.md` 台账由 orchestrator 收尾统一写（worker 契约 ②）。

### 3. 并行推演（worker）
按 worker 契约派单：执行 `/provide-solution-draft`，范围 = 分派的问题，slug = 预分配值，不写 `_index.md`，报告（含台账行、依据构成、「仍需用户决定」「张力」「前置依赖」摘录）落 run 目录。

worker 判定该问题**不适合推演**（纯取向 / 信息不足）→ 不建文件，报告原因（与单会话技能的收尾规则一致）。

### 4. 合并 interview ⏸️（本技能的核心）
收齐全部草稿后，orchestrator 汇总三类条目并按 `batch-orchestration.md` 的合并判据去重：
- 各草稿的 **`## 仍需用户决定`**（取向选择：选项 + 后果 + 推荐一并呈现）；
- **`## 与既有决策的张力`**（需要用户裁定是否松动某条既有决策）；
- **`## 前置依赖` 的交叉项**——草稿 A 依赖的前置问题恰好是草稿 B 在答的 → 点明「先裁 B 再看 A」，据此排问题顺序；两份草稿对同一对象给出矛盾提案 → 作为新增 🔴 进 interview。

出题前先按单会话技能的**分类纪律**复核一遍：被误归 `[取向选择]`、实际有通行做法 / 常识默认的项，直接按推荐采纳（写回草稿时在该条目下注明「已按标准默认采纳：<选择>」）并汇总进总报告，**不出题**——interview 只留真取向、张力与草稿间矛盾。用 `AskUserQuestion` 分轮问齐（每轮 ≤4，按阻断程度排序）。用户也可对某份草稿整体表态（「这份先搁置」「这份整体否决」）——照记。

### 5. 裁决写回草稿
对每条已裁决项，编辑对应草稿：在 `## 仍需用户决定` 的该条目下追加一行 `→ 已裁决（<日期> · 批量评审）：<用户的选择>`；整份被搁置 / 否决的草稿在 frontmatter `status` 改为 `on-hold` / `rejected` 并在报告点名。未裁决项原样保留。
> 这样 `/analyze-new-ideas`（或 `/batch-analyze-new-ideas`）消费草稿时，按其既有规则「用户已在评审中定下的按定下的处理，未定的仍按 Open question 搁置」即可，无需额外约定。

### 6. 收尾（orchestrator 统一写台账）
- 把各 worker 报告里的台账行写进对应库 `inbox/_index.md` 的「待处理」表（`下一步` 列：全部裁决完的写 `/analyze-new-ideas`，有剩余取向的写清还差几项）。
- **不**改 `open-questions.md` / `open-questions/` / 主题文档 / ADR / `handoffs/`（与单会话技能同一范围守则）。

## 输出形态
```
## 批量方案草稿：<N> 个问题 → <M> 份草稿

- 范围：game <n> 项 · backend <m> 项 · 跨库 <k> 项
- 草稿：<LIB>/inbox/solution-draft-<slug>.md ×M（均已登记台账）
- 不适合推演而跳过：<清单 + 原因>

### 合并 interview
- 原始待决 <X> 项 → 去重合并后 <Y> 问 · 已裁决 <Z> 项（逐条：<问题> → <裁决>）
- 前置依赖交叉 / 草稿间矛盾：<条目>

### 仍待用户
- <未裁决项，按草稿分组>

### 下一步（可直接复制运行）
/batch-analyze-new-ideas <详细提示词，见下方构造规则>
```

**「下一步」提示词的构造规则（强制）——不要只给一行裸命令**，要产出一段**可直接复制运行**的完整 `/batch-analyze-new-ideas` 提示词（草稿全部裁决完毕时；仅一份草稿就绪则给 `/analyze-new-ideas`），包含：

1. **全部就绪草稿的完整路径**（含库前缀，空格分隔）。**排除** `on-hold` / `rejected` 与仍有未裁决项的草稿——后者单列一句「<slug> 还差 <n> 项裁决，裁决后追加进本批或单独跑」。
2. **裁决状态前提**：点明「裁决已以『→ 已裁决（<日期> · 批量评审）』写回草稿，视同用户拍板」，让下一步不再重问已答定的项。
3. **counterpart 配对**：跨库成对的草稿点名「<n> 对 counterpart 草稿须成对提炼、两侧互相回链」。
4. **写库授权**：涉及哪几个库就写哪几个——「授权本次对 <库清单> 写入」。
5. **顺带事项**（有则写）：本批运行中浮出的、答案已定、纯机械的落笔项（待回链的台账行、待登记的跨库承接项等），逐条一句话：「顺带落笔：<事项>（纯机械落笔，答案已定）」。

示例形态：
```
/batch-analyze-new-ideas game-design-documents/inbox/solution-draft-a.md backend-design-documents/inbox/solution-draft-a.md game-design-documents/inbox/solution-draft-b.md — 三份均已批量评审（裁决已以「→ 已裁决（<日期> · 批量评审）」写回草稿，视同用户拍板）；solution-draft-a 为一对 counterpart 草稿，须成对提炼、两侧互相回链。授权本次对 game-design-documents/ 与 backend-design-documents/ 两库写入。顺带落笔：<跨库承接项 / 台账回链>（纯机械落笔，答案已定）。
```
