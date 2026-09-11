---
name: progress-sync
description: 一次会话把两个设计库的「台账层」整体推进到与事实同步：四个波次依次派发 8 个 subagent —— ① /write-adr 客户端 + 后端；② /assess-derive-readiness 客户端 + 后端；③ /sync-knowledge all + /summarize-open-questions 客户端 + 后端；④ 收尾提交并推送全部 worktree 分支（短提交信息）。全程无人工介入：worker 不 interview、不裁决，判不出的一律原样留下并写进报告，由 orchestrator 汇成一份总报告。
argument-hint: [all（默认）| adr | readiness | sync | push]（可只跑某一波；波次内不再细分）
---

# Progress Sync

四个**全量扫描 / 全量立档**形态的技能（`/write-adr`、`/assess-derive-readiness`、`/sync-knowledge`、`/summarize-open-questions`）各自只做一件事，但它们的产出**互为前提**：新立的 ADR 会改变就绪度判断，重估过的就绪度要落进 `open-questions.md`，而待答清单的重整必须在前两者写完之后做，否则重整完当场就过时。

本技能把这条固定链路一次跑完：**四个波次、8 个 subagent、波次内并行、波次间严格串行**。前三波推进台账，**第四波把这一整批落笔提交并推送到全部 worktree 分支**——不留提交边界的一批，落错了就没有可 diff / revert / bisect 的单元。

## 铁律

**① 全程无人工介入。** 本技能**不调用 `AskUserQuestion`**，worker 也不调用。四个底层技能里所有「停下询问」的分叉，在这里一律按下方「无人值守的口径」处理——**判不出就原样留下 + 写进报告**，绝不替用户拍板、绝不凭猜测落笔。这不是放松原技能的门，而是把「停下问」换成「停下不写、如实上报」。

**② 波次串行，不得重叠。** 后一波的输入是前一波写完的文件。任何情况下都不要为了省时间把两波合并成一次派发。

**③ 写入面按库分区（已预先算清，见下表）。** 同一波内的两个 worker 永不写同一份文件。这是本技能可以并行的全部依据；worker 越界写了分区外的文件 → 记录、报告，由 orchestrator 提请用户处理。

**④ orchestrator 自己不写设计库。** 它只派单、核对、出总报告。四个底层技能各自就是自己那批文件的唯一写入者（`decisions/_index.md` 归 `/write-adr`、「derive 就绪度」小节归 `/assess-derive-readiness`、`answer-logs/` 归 `/summarize-open-questions`），本技能不代笔、不修补。**提交与推送同理由波次 4 的 worker 独占**——orchestrator 自己不跑 git 写命令。

**⑤ 提交只在 Verify 通过之后。** 波次 4 排在收尾 Verify **之后**，因为越界检查要在改动进入历史之前跑完。Verify 报出越界或台账对不上 → **不提交**，停下报告由用户处理。

## 写入面分区表（派发前的依据，不要重算）

| 波次 | worker | 写入 |
|---|---|---|
| 1 | `/write-adr --lib=game` | `game-design-documents/`：`decisions/ADR-*.md`、`decisions/_index.md`、`open-questions.md` 的 `## 下一阶段`（仅删已固化条目）、`open-questions/update-log.md` |
| 1 | `/write-adr --lib=backend` | 同上，全部在 `backend-design-documents/` 下 |
| 2 | `/assess-derive-readiness --lib=game` | `game-design-documents/open-questions.md` 的「derive 就绪度」小节（整体重写，仅此一节） |
| 2 | `/assess-derive-readiness --lib=backend` | 同上，`backend-design-documents/` |
| 3 | `/sync-knowledge all` | 只写 `.claude/knowledge/*` 与 `.claude/rules/*` |
| 3 | `/summarize-open-questions --lib=game` | `game-design-documents/`：`open-questions.md`（索引）、`open-questions/*`、`answer-logs/*` |
| 3 | `/summarize-open-questions --lib=backend` | 同上，`backend-design-documents/` |
| 4 | commit-push | **不写任何文件内容**，只写 git 历史：逐 worktree `add -A` + `commit`，再经根级 `push-all.cmd` 推送 |

三点说明：

- 波次 1、2 都触碰各库 `open-questions.md`，但**是不同小节**（`## 下一阶段` vs 「derive 就绪度」）且**分属不同波次**，不并发。
- 波次 3 的 `/sync-knowledge` 与两个 `/summarize-open-questions` 并行安全：前者只写 `.claude`，读设计库时也不投影 `open-questions.md` / `answer-logs/`（知识层不承载待答清单）。
- 波次 4 **单个 worker、无并行**——git 索引不能并发写，且它要跨全部目录统一收口。

## 无人值守的口径（worker 遇到分叉时怎么办）

派单 prompt 里必须原样带上这几条：

- **库路由**：`--lib` 已由 orchestrator 显式给定，**不许再解析、不许询问**。`/sync-knowledge` 本就只面向客户端，无库参数。
- **`/write-adr`**：候选「查无实据」或「与主题文档矛盾」→ **不建档**，原样留在候选清单，写进报告的「未固化」区并附两处原文引用。绝不为了凑数建 `Proposed` 占位。
- **`/assess-derive-readiness`**：blocked / partial 如实判定即可——它本就只写结论、不裁决任何 Open question。
- **`/summarize-open-questions`**：只归集、去重、归拢与移出已答定项；**不裁决任何问题**。发现主题文档的 `## Open questions` 有错漏或与 `## 决策` 矛盾 → 只报告，不改主题文档。跨边界承接项在对侧库缺失时，按原技能允许在对侧库补登**待答形态**的一条（不拍板）——这仍是"不替用户决定"。
- **`/sync-knowledge`**：漂移就修；无法判定"代码现状 vs 设计意图哪边是真"时 → 不改，报告为待裁决项。
- **通用**：任何原技能写着「停下询问用户」的地方，一律改为**不写该项 + 在报告里单列**。
- **commit-push**：只提交 / 推送**既已存在的**改动，绝不为了让提交好看去改任何文件内容；遇到分叉、快进失败、push 重试耗尽 → 如实报告该目录失败，其余目录照跑。

## 步骤

### 1. 圈定波次范围
解析 `$ARGUMENTS`：空 / `all` → 四波全跑（默认）。`adr` / `readiness` / `sync` → 只跑对应的那一波**再加波次 4**（重跑失败波次时也要把结果提交掉）。`push` → **只跑波次 4**（前三波已在别处跑完、只差提交推送时用）。**波次内不细分**——两个库同跑是本技能的形态，只跑单库请直接调用底层技能。

开跑前用 `Glob` 确认两个设计库目录都在（`game-design-documents/`、`backend-design-documents/`）。某个库缺失 → 跳过它的 worker，在报告里点名，其余照跑。

### 2. 建 run 目录（过程档案）
建 `.claude/batch-runs/<YYYY-MM-DD>-progress-sync/`，worker 的报告落这里（`report-<worker>.md`）。它是**过程档案、不是事实来源**，设计库不得回链它，跑完可整目录删除。日期从 `date +%F` 取，不要臆造。

### 3. 波次 1 —— 立档（并行 2 个）
一条消息内发两个 `Agent` 调用，**省略 `model` 参数**让其继承本会话模型（承 `CLAUDE.md`「子代理分发」）。每个 prompt 包含：

- 执行哪个技能（读 `.claude/skills/write-adr/SKILL.md` 并逐步照做）与 `--lib=<库>`；
- 上方「无人值守的口径」全文要点 + **不得调用 `AskUserQuestion`**；
- 写入面（只许写分区表里属于它的那些文件；四个快照目录 `game-testing-branch/` `game-production-branch/` `backend-testing-branch/` `backend-production-branch/` 只读；代码只写 `game-feature-branch/` / `backend-feature-branch/`——本技能一行代码都不该写）；
- 报告写到 `.claude/batch-runs/<run>/report-write-adr-<库>.md`，并把同一份报告作为最终返回文本。

两个都返回后再往下走。**不做空转轮询**（不发 sleep / ls 去看进度）。

### 4. 波次 2 —— 就绪度重估（并行 2 个）
同上形态，执行 `/assess-derive-readiness`，`--lib=game` / `--lib=backend` 各一。派单 prompt 里点明**波次 1 刚刚新增了哪几份 ADR**（从波次 1 报告摘取编号与标题），让就绪度评估把新立的约束算进去。

### 5. 波次 3 —— 清单与知识层重整（并行 3 个）
- `/sync-knowledge all`（无库参数）；
- `/summarize-open-questions --lib=game`；
- `/summarize-open-questions --lib=backend`。

两个 summarize 的派单 prompt 里点明：本次运行中 `## 下一阶段` 已被 `/write-adr` 收口过、「derive 就绪度」小节刚被 `/assess-derive-readiness` 整体重写过，**这两节按现状原样保留**，只重整问题条目与分片导航。

### 6. 收尾 Verify（强制，出示证据）
宣告完成前依次核对并在报告中出示：

1. **台账对账**：`game-design-documents/decisions/` 与 `backend-design-documents/decisions/` 各报「ADR 文件数 ↔ `_index.md` 行数」两个数字；`open-questions/` 分片数 ↔ `open-questions.md` 索引导航条目数；`answer-logs/` 文件数 ↔ `answer-logs/_index.md` 行数。不一致 → **不自己改**（这些台账各有唯一写入者），把差额报回并建议重跑对应波次。
2. **越界检查**：确认没有 worker 写到分区外的文件（尤其是主题文档、`handoffs/`、`content/`、`game-feature-branch/`）。用 `git -C <库目录> status --porcelain` 逐库列出改动文件比对分区表。
3. **逐目标清单**：8 个 worker 逐条标 done / skipped / failed 及原因。有任何未闭合项即**不得宣告完成**。

某个 worker 失败 → 记录、不阻塞同波其余 worker；但**波次 1 或 2 整波失败时不要继续下一波**（后一波的输入不成立），停下报告。

### 7. 波次 4 —— 提交并推送（单个 worker）

Verify 的越界检查通过后，派**一个** `Agent`（同样省略 `model`）执行提交与推送。派单 prompt 里给它：

- **本次改动摘要**（从前三波报告摘取：各库新增 ADR 数、就绪度变化、待答条目增减、知识层修复处数）——这是它写提交信息的唯一素材，**不许它自己重新解读 diff 去编内容**；
- **两步顺序，不得颠倒**：
  1. **先逐 worktree 提交**本次实际触及的目录（典型是 `game-design-documents/`、`backend-design-documents/`、`.claude/`），每个目录一条**短提交信息**，形如
     `sync(game-design): ADR ×3 + 就绪度重估 + 待答清单重整`／`sync(backend-design): …`／`sync(config): 知识层与规则层对账`。
     一行、≤60 字、只讲**改了什么**，不写过程叙事、不回链 run 目录（它是过程档案，且 `.claude/batch-runs/` 已被 gitignore）。
     命令形态：`git -C <目录> add -A` → `git -C <目录> commit -m "<短信息>"`；**该目录无改动就跳过 commit**，不造空提交。
  2. **再从仓库根跑 `.\push-all.cmd`**（不带 `-Message`），由它统一 fetch --prune、判 ahead/behind、必要时 `merge --ff-only`、带重试推送全部十个 worktree 分支。剩余目录若有无关本次的零散改动，由该脚本自动生成信息性提交信息。
     > 为什么不直接 `push-all.cmd -Message`：`-Message` 会把同一条信息盖到所有目录，本次三个库的改动内容各不相同。先自己提交、再让脚本推送，既拿到分库的短信息，又完整复用脚本的分叉判定与 push 重试纪律。
- **红线**：四个只读快照目录（`game-testing-branch/` `game-production-branch/` `backend-testing-branch/` `backend-production-branch/`）**绝不 add/commit**（`push-all.cmd` 对它们本就是 push-only，worker 也不得手工绕过）；不 `push --force`、不 `rebase`、不 `reset --hard`；不改任何文件内容。
- 报告写到 `.claude/batch-runs/<run>/report-commit-push.md`，含**逐目录：分支 / 提交信息 / commit 短 hash / 推送结果**，并作为最终返回文本。

某个目录与上游分叉或推送失败 → 该目录记失败，其余照常，不做任何强制手段。

### 8. 总报告
```
## Progress sync：<all | adr | readiness | sync | push>

- run: .claude/batch-runs/<YYYY-MM-DD>-progress-sync/

### 波次 1 · 立档
- game: 新增 ADR <n> 份（ADR-#### <标题> …）；未固化 <k> 条（<各自原因>）
- backend: 同上

### 波次 2 · derive 就绪度
- game: ready <n> · partial <m> · blocked <k>（较上次的变化：<摘要>）
- backend: 同上

### 波次 3 · 清单与知识层
- game open-questions: 待答 <n> 条（分片 <s> 个）；移入 answer-logs <k> 条
- backend open-questions: 同上
- sync-knowledge: 修复漂移 <n> 处；压回薄引用 <m> 处；待裁决 <k> 项

### 需要用户裁决（本次一律未落笔）
- <条目> —— <矛盾/查无实据/无法判定的具体描述 + 两处原文路径>

### Verify
- 台账对账：<逐项两个数字>
- 越界：<无 / 清单>
- 逐目标：8/8 done（或逐条列 skipped / failed 及原因）

### 波次 4 · 提交与推送
| 目录 | 分支 | 提交信息 | hash | 推送 |
|---|---|---|---|---|
| game-design-documents | game-design | sync(game-design): … | abc1234 | ✅ |
| backend-design-documents | backend-design | … | … | ✅ |
| .claude | claude-config | … | … | ✅ |
| <其余 worktree> | … | <push-all 自动生成 / 无改动> | … | ✅ / 跳过(分叉) / 失败 |
```

**提交边界即本批次。** 一次 progress-sync 的落笔在每个 worktree 上收成一个提交，可 diff / revert / bisect；Verify 未通过则整批不提交，如实报告。
