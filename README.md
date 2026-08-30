# MyCardGame —— Claude Code 工具配置

一套轻量、经过精心设计的 `.claude` 配置（规则 + 知识 + 技能），帮助 Claude Code 在本项目上高效工作。

**项目：** 一款 Godot **2D roguelike 卡牌构筑游戏**（Balatro / Slay the Spire 的手感）—— 移动优先、竖屏、强制在线（云端权威）、休闲。
**技术栈：** Godot 4.7（GL Compatibility）· .NET / C# · Rider · Claude Code。

---

## 设计原则

**`.claude` 是工程层。** 它只承载两类东西：**① 工程相关的配置与规则**（harness 配置、C#/Godot 互操作与场景 / 数据 / 存档 / UI / null 校验纪律）与 **② 可复用的技能**（推进项目的流程封装）。**一切设计相关的知识与细节归设计分支**，在此只被**引用与轻描述**。它的目的是**帮助实现设计意图**；愿景的内核活在 `game-design-documents/`。

**主从关系：** 设计性内容（机制、数值、字段、契约、流程）冲突 → **以设计库为准**，`.claude` 跟着改；工程性约束（命名、生命周期、热路径、工具 / PATH、目录纪律）冲突 → **以 `rules/*` 为准**（设计库对此无权威）。权威：`game-design-documents/decisions/ADR-0005-knowledge-thin-reference-layer.md`。

`CLAUDE.md` 每个会话只加载一个文件：`rules/Context.md`。该文件承载常态约定以及一张**知识导航**表。深入细节位于 `knowledge/*` 并按需加载 —— 让每个会话的上下文保持精简。

路径硬编码为 `.claude/...`（本项目仅面向 Claude Code；没有 Qoder/`$TOOL_DIR` 那样的间接层）。

---

## 工作区布局 —— 一个仓库中枢 + 十个 worktree

**拓扑（2026-08-16 起）：** 十个目录**不再是十份独立 clone**，而是同一个裸仓库中枢
`.repo.git` 的十个 **git worktree**，每个钉在一个分支上。

- **一份对象库、一份 fetch 状态。** 从任意一个目录 `git fetch` 都会更新全体的
  remote-tracking 引用；`push-all.cmd` 因此只 fetch 一次（此前是十次）。
- **worktree 的 `.git` 是一个文件、不是目录**（内容为 `gitdir: …/.repo.git/worktrees/<name>`）。
  任何判断「这是不是 git 目录」的脚本都必须用 `git rev-parse --git-dir`，
  **不能**用「`.git` 是否为目录」——仓库里的脚本已按此写。
- **一个分支只能被一个 worktree 检出。** 想在别处再看同一分支，用 `git worktree add --detach`。
- 各目录照常 `git status` / `commit` / `push`，上游跟踪逐分支设好（`origin/<branch>`）。
- **根目录 `D:\MyCardGame\` 本身不是仓库**，也没有根级 `.gitignore`（git 从不向仓库根以上查找忽略规则；
  客户端的忽略面在 `game-feature-branch/.gitignore`）。根级三个 `.cmd` 包装脚本不受任何分支版本控制。

```
D:\MyCardGame\
├── .repo.git/                   — bare hub: 全部对象与引用都在这里（唯一的 fetch 状态）
├── .claude/                     — this harness (worktree: claude-config)
├── main/                        — branch guidance map only (worktree: main)
├── game-feature-branch/         — the Godot project; EDIT HERE (worktree: game-feature)
├── game-testing-branch/         — read-only reference snapshot (worktree: game-testing)
├── game-production-branch/      — read-only reference snapshot (worktree: game-production)
├── game-design-documents/       — client design intent, SOURCE OF TRUTH (worktree: game-design)
├── backend-feature-branch/      — the backend; EDIT HERE (worktree: backend-feature)
├── backend-testing-branch/      — read-only reference snapshot (worktree: backend-testing)
├── backend-production-branch/   — read-only reference snapshot (worktree: backend-production)
├── backend-design-documents/    — backend design intent, SOURCE OF TRUTH (worktree: backend-design)
├── push-all.cmd                 — commit + push every branch checkout at once
├── promote.cmd                  — merge one branch into its downstream (feature→testing→production)
└── session-manager.cmd          — session favorites/tags entry point
```

- **两条彼此独立的提升线：** `game-feature → game-testing → game-production`（Godot 客户端）与 `backend-feature → backend-testing → backend-production`（云端后端）。从不互相合并——唯一真实的进程边界就在这两侧之间，两者的部署节奏与技术栈都不同。提升用根级 `promote.cmd -Line game -To testing`（在目标分支自己的目录里 `--no-ff` 合并 + push；目标工作区不干净就拒绝执行，绝不 force-push）。
- **只在两个 feature 文件夹中编辑。** 四个 testing/production 文件夹是并行快照，用于把一个稳定构建与进行中的工作交叉对比（在不切换分支的情况下映射 dev/test/prod 分支模型）。
- `settings.json` 的 permission **deny 规则**会拦截对这四个快照目录的 Edit/Write（无需钩子、不依赖 python）。Bash 写入由 PreToolUse 钩子 `hooks/check-bash-readonly-dir.sh` 拦截（依赖 python）。
- 后端目前**尚未开工**：`backend-feature-branch/` 只有一份 README，技术栈待定。客户端的边界服务先以离线 stub 实现。
- **`.claude/` 自身也是一个 worktree**（分支 `claude-config`，分支根 = 本文件夹根）。它与其余九个目录一样受 `push-all.cmd` 覆盖。`.gitignore` 排除 `.idea/`、`plans/`、`blueprints/`、`batch-runs/`、`session-tags.json`。

### 设计意图
`game-design-documents/`（`game-design` 分支 —— 仅文档，孤儿历史）承载**客户端**的人工设计交接：游戏*应该*是什么样的事实来源。这里的 `knowledge/*` 是**指向它的薄引用层**（导航 + 代码现状 + 一句话承重纪律，不复述设计内容）。规划一个功能时，先阅读相关的设计文档。

`backend-design-documents/`（`backend-design` 分支 —— 同为仅文档、孤儿历史）承载**后端**的设计意图：账号合规、协议契约、存档同步、内容分发。跨边界的客户端成分只有三个服务（`account-service` / `content-service` / `sync-service`）——剧本内容不跨边界，随 content-service 的 overlay 通道下发。

两个设计库都归用户所有 —— Claude 读它们以做规划，只有在被要求时才编辑。

---

## 目录结构

```
.claude/
├── CLAUDE.md            — entry; imports rules/Context.md
├── settings.json        — permissions (allow + deny 保护四个只读快照目录 + defaultMode)
│                          + statusLine + model + effortLevel + outputStyle + hooks + attribution
├── statusline.sh        — statusLine 脚本（bash；由 settings.json 的 statusLine 调用）
├── hooks/
│   └── check-bash-readonly-dir.sh — PreToolUse(Bash) 守卫：拦截 Bash 写入四个只读快照目录
├── session-tags.json    — session 收藏/标签存储 (session-manager 写入; gitignored)
├── blueprints/          — 实现蓝图 + _index.md 台账 (gitignored, 本机)
├── batch-runs/          — batch-* 技能的过程档案 <date>-<slug>/ (plan / questions / answers / report)
│                          (gitignored, 本机) 不是任何事实来源，跑完即可整目录删除；
│                          契约见 rules/batch-orchestration.md
├── README.md            — this file
├── .gitignore
├── .gitattributes
├── rules/
│   ├── Context.md               — always-on conventions + knowledge nav (keep < ~250 lines)
│   ├── design-library-routing.md — 设计技能的双库入参解析 (game-design ↔ backend-design)
│   ├── environment-rules.md     — this machine's tools/PATH
│   ├── csharp-godot-rules.md    — C#↔Godot interop conventions
│   ├── scene-rules.md           — scene / node composition & instancing
│   ├── data-resource-rules.md   — Resource-driven data (.tres)
│   ├── state-save-rules.md      — cycle state, seeded RNG, save atomicity
│   ├── ui-input-rules.md        — mobile portrait layout + touch input
│   ├── null-check-rules.md      — validate GetNode / ResourceLoad / lookups
│   └── batch-orchestration.md   — batch-* 技能的公共契约（两阶段、合并 interview、共享台账单写者）
├── knowledge/
│   ├── architecture.md          — scene tree, autoloads, render/resolution
│   ├── dictionary.md            — game glossary
│   ├── systems/     (_index.md; per-system notes appear as systems land)
│   ├── data/        (_index.md — 引用层；内容权威在设计库 systems/)
│   ├── scenes/      (_index.md; per-scene notes appear as scenes land)
│   ├── autoloads/   (_index.md; per-singleton notes appear as autoloads land)
│   └── standards/   (csharp-conventions, godot-scene-conventions,
│                     mobile-portrait-ui, rng-determinism, save-format, signal-eventbus)
├── scripts/
│   ├── session-manager          — bash 入口（子命令语法）
│   ├── session-manager.cmd      — PowerShell 入口（与根级 session-manager.cmd 等价）
│   ├── session-manager-impl.ps1 — 实现；上面两个入口都转发到它
│   ├── push-all-impl.ps1        — 批量 commit/push 全部工作区（经根级 push-all.cmd 调用）
│   ├── promote-impl.ps1         — 沿提升线合并 + 推送（经根级 promote.cmd 调用）
│   └── index-size-guard.ps1     — PostToolUse 钩子：台账超阈值告警（一般 20KB，
│                                   open-questions/update-log.md 放宽到 48KB；只告警，绝不拦截）
└── skills/
    ├── analyze-new-ideas/     — raw idea → consistency/compat review → interview → clean handoff → distill into design docs
    ├── provide-solution-draft/ — one open question → proposed solution → inbox/solution-draft-<slug>.md (human review)
    ├── summarize-open-questions/ — rebuild open-questions.md (index) + open-questions/ shards; answered items → answer-logs/log-<draftSuffix>.md
    ├── write-adr/            — settled decisions → decisions/ADR-####-<slug>.md + _index.md ledger
    ├── assess-derive-readiness/ — full sweep: is any design doc ready to derive? (manual)
    ├── derive-requirements/   — detailed design → 片区级 feature requirements (FR-*)
    ├── breakdown-requirements/ — one FR → a folder of executable sub-requirements (one = one blueprint)
    ├── scaffold-content-type/ — 就绪度闸门 + 开张 content/<类型>/_index.md（类型档案）
    ├── author-content/   — 内容条目草稿 → 校验/interview → content/<类型>/<id>.md（直接喂 blueprint）
    ├── audit-content/    — 内容条目全量对账（Id/引用/字段/池分布/文案覆盖/台账）
    ├── blueprint/        — explore + design an implementation blueprint (from an FR, a content entry, or free text)
    ├── implement/        — implement per blueprint
    ├── review-local-changes/  — review uncommitted changes
    ├── review-feature/   — review a feature's full chain
    ├── investigate/      — trace a bug to ranked root causes
    ├── sync-knowledge/   — reconcile knowledge/* + rules/* against code + design docs
    ├── update-readme/    — realign every README.md with what it describes
    ├── session-manager/  — session favorites/tags
    └── batch-*/          — 批量编排版（provide-solution-draft / analyze-new-ideas / author-content /
                            derive-requirements / breakdown-requirements / blueprint / implement /
                            review-feature）：并行 worker + 一场合并 interview；契约见 rules/batch-orchestration.md
```

---

## 功能工作流

设计 → 需求 → 代码：

> **双库入参：** 前 5 步（`/analyze-new-ideas`、`/provide-solution-draft`、`/assess-derive-readiness`、`/derive-requirements`、`/breakdown-requirements`）与 `/summarize-open-questions`、`/write-adr` 对**两个设计库**通用——`game-design-documents/`（客户端）与 `backend-design-documents/`（后端）。用 `--lib=game` / `--lib=backend` 显式指定，或直接给带库前缀的路径；判不出时技能会**询问，不静默默认**。解析顺序、跨库纪律与两库结构差异见 `rules/design-library-routing.md`。第 6 步起（`/blueprint` 及其后）仍只面向客户端。

1. `/analyze-new-ideas [--lib=…] <raw>` —— 先校验想法的**逻辑自洽性**与**同既有 ADR / 主题文档 / 承重纪律的兼容性**；有冲突或含糊即**停下来发起 interview 让用户澄清**，拿到答复后才把意图捕获为整洁的 handoff 并提炼进选定设计库的主题文档。无参数运行则扫描该库 `inbox/` 列出待处理草稿。
2. `/provide-solution-draft <问题>` —— 取 `open-questions.md` 的**一个**待答项，基于既有决策推演 + 行业通行做法给出**提案式**方案，写到 `inbox/solution-draft-<slug>.md`。**人类评审后**再喂回 `/analyze-new-ideas` 提炼（human-in-the-loop）。它只写这一个草稿文件，不裁决问题、不动主题文档。
3. `/assess-derive-readiness` —— **由用户手动调用**。全量扫描全部主题文档，逐份判定 ready / partial / blocked，并整体重写 `open-questions.md` 的「derive 就绪度」小节（它是该小节的**唯一写入者**）。`/analyze-new-ideas` 与 `/summarize-open-questions` **均不评估就绪度**。**当前结论以各库 `open-questions.md` 的「derive 就绪度」小节为准**（两库各一份，互不合并）。
4. `/derive-requirements <doc>` —— 一旦某份设计文档已充分详尽（真实意图、无遗留问题），就把**片区级**功能规格产出到选定库的 `requirements/FR-*`。用户签署确认（`draft → ready`）。
5. `/breakdown-requirements FR-<id>` —— 把**一份** FR 拆成同名文件夹 `requirements/FR-<id>/` 内的若干**可执行子需求**（每个小到能被 `/blueprint` 一次吃下），带**父验收标准 → 子需求覆盖映射表**。父 FR 翻为 `broken-down`；**父 FR 的签核即覆盖其子需求**。
6. `/blueprint FR-<id>` —— 探查知识 + 代码、澄清、把一份实现蓝图保存到 `blueprints/`（其验收标准驱动设计）。首选输入是**子需求 id**；**内容条目文档**（`content/<类型>/<id>.md`）与自由文本 `/blueprint <feature>` 同样可用。
7. `/implement [blueprint]` —— 在 `game-feature-branch/` 中构建它。
8. `/review-local-changes` 或 `/review-feature` —— 在提交前捕获 bug。
9. `/investigate <symptom>` —— 把一个 bug 追溯到按可能性排序的根因 + 诊断步骤。

> **批量版：** 上述多数阶段各有 `batch-*` 编排版（`/batch-provide-solution-draft`、`/batch-analyze-new-ideas`、`/batch-author-content`、`/batch-derive-requirements`、`/batch-breakdown-requirements`、`/batch-blueprint`、`/batch-implement`、`/batch-review-feature`）：一次覆盖一批输入，并行 / 波次分派 worker（worker 执行对应的单会话技能），把所有 🔴/🟠/取向问题**合并去重成一场大 interview**再落笔——批量提效，但**不吞掉任何人工决策**。公共契约（两阶段、共享台账单写者、写入面分区）见 `rules/batch-orchestration.md`。`/assess-derive-readiness`、`/summarize-open-questions`、`/write-adr`、`/audit-content`、`/sync-knowledge`、`/update-readme` 本就是全量扫描 / 全量立档形态，无需批量版。

**内容创作是并行的第二条路（不经 FR）：** `/scaffold-content-type <类型>` 为一个内容类型开张（带**就绪度闸门**：类定义不足以写出可实现的条目时就把话说清楚）→ `/author-content <类型> <草稿>` 把你的条目草稿校验 / interview 后写成 `game-design-documents/content/<类型>/<id>.md` → 你签核 `draft → ready` → **直接 `/blueprint`** → `/implement` → `.tres`。条目一多用 `/audit-content` 做全量对账。**字段清单的权威在设计库的类型档案里，不在技能里**——这正是「一个通用技能 + 十几份类型档案」而非「每类一个技能」的理由（ADR-0005：`.claude` 不承载设计内容）。约定见 `game-design-documents/content/_index.md`。

`knowledge/` 是**指向设计库的薄引用层**（导航表 + 代码现状 + 一句话承重纪律；设计内容不在此复述，见 `decisions/ADR-0005`）—— `/implement` 会在构建时就地更新相关的 `systems/`、`scenes/`、`data/`、`autoloads/` 笔记；怀疑知识与代码/设计脱节时运行 `/sync-knowledge` 做整体对账——它的对账面是**整个 `.claude` 的设计投影面**（`knowledge/*` + `rules/*`）对两个事实来源（`game-feature-branch/` 的代码现状、`game-design-documents/` 的设计意图），并把偷偷长回来的副本压回薄引用。术语的权威在 `game-design-documents/terminology.md`；`knowledge/dictionary.md` 只保留通用的 roguelike 卡组构建体裁词汇，不复制本作专有术语。

**决策立档（与上面的流水线并行、随时可跑）：** `/write-adr [--lib=…]` 把各库的**已定方向**（`open-questions.md`「下一阶段」的 ADR 候选、后端库 `decisions/_index.md` 的「ADR 候选」表、以及散落在 handoff 里的定案）逐条落成 `<LIB>/decisions/ADR-####-<slug>.md` 并更新 `decisions/_index.md`。它是 `decisions/` 的**唯一写入者**（唯一例外：用户裁决推翻某条决策时，`/analyze-new-ideas` 直接改写那份 ADR），且严守「**台账绝不领先于事实**」：一条定案没写进权威主题文档就不建档，只在报告里点名。**不接受跨库运行**——两库 ADR 编号各自独立、永不合并。

台账闭环：`/blueprint` 把 FR 翻为 `blueprinted` 并登记 `blueprints/_index.md`；`/implement` 在**端到端验证通过后**把 FR 翻为 `built`。台账各有**唯一写入者**：`decisions/_index.md` 归 `/write-adr`，`answer-logs/` 归 `/summarize-open-questions`，`blueprints/_index.md` 归 `/blueprint` 与 `/implement`，「derive 就绪度」小节归 `/assess-derive-readiness`。

## 验证

**`dotnet build` 成功不是验收标准。** 验证 = 在 Godot 编辑器中打开项目 → 按 Play（编辑器会用正确的引用驱动 .NET 构建）→ 逐条走 FR 的验收标准。详见 `rules/environment-rules.md`。

---

## 扩展

- **新约定** → 新增 `knowledge/standards/<topic>.md`，从 `Context.md` 的导航表中链接它。优先新增知识文件，而非让 `Context.md` 膨胀。
- **新技能** → 新增 `skills/<name>/SKILL.md`。
