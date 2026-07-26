# MyCardGame —— Claude Code 工具配置

一套轻量、经过精心设计的 `.claude` 配置（规则 + 知识 + 技能），帮助 Claude Code 在本项目上高效工作。

**项目：** 一款 Godot **2D roguelike 卡牌构筑游戏**（Balatro / Slay the Spire 的手感）—— 移动优先、竖屏、强制在线（云端权威）、休闲。
**技术栈：** Godot 4.7（GL Compatibility）· .NET / C# · Rider · Claude Code。

---

## 设计原则

`CLAUDE.md` 每个会话只加载一个文件：`rules/Context.md`。该文件承载常态约定以及一张**知识导航**表。深入细节位于 `knowledge/*` 并按需加载 —— 让每个会话的上下文保持精简。

路径硬编码为 `.claude/...`（本项目仅面向 Claude Code；没有 Qoder/`$TOOL_DIR` 那样的间接层）。

---

## 工作区布局 —— 并行的分支文件夹

```
D:\MyCardGame\
├── .claude/                     — this harness
├── main/                        — branch guidance map only (git: main)
├── game-feature-branch/         — the Godot project; EDIT HERE (git: game-feature)
├── game-testing-branch/         — read-only reference snapshot (git: game-testing)
├── game-production-branch/      — read-only reference snapshot (git: game-production)
├── game-design-documents/       — client design intent, SOURCE OF TRUTH (git: game-design)
├── backend-feature-branch/      — the backend; EDIT HERE (git: backend-feature)
├── backend-testing-branch/      — read-only reference snapshot (git: backend-testing)
├── backend-production-branch/   — read-only reference snapshot (git: backend-production)
├── backend-design-documents/    — backend design intent, SOURCE OF TRUTH (git: backend-design)
├── push-all.cmd                 — commit + push every branch checkout at once
└── session-manager.cmd          — session favorites/tags entry point
```

- **两条彼此独立的提升线：** `game-feature → game-testing → game-production`（Godot 客户端）与 `backend-feature → backend-testing → backend-production`（云端后端）。从不互相合并——唯一真实的进程边界就在这两侧之间，两者的部署节奏与技术栈都不同。
- **只在两个 feature 文件夹中编辑。** 四个 testing/production 文件夹是并行快照，用于把一个稳定构建与进行中的工作交叉对比（在不切换分支的情况下映射 dev/test/prod 分支模型）。
- `settings.json` 的 permission **deny 规则**会拦截对这四个快照目录的 Edit/Write（无需钩子、不依赖 python）。Bash 写入不在拦截范围内——那部分仍是 `Context.md` 约束的约定。
- 后端目前**尚未开工**：`backend-feature-branch/` 只有一份 README，技术栈待定。客户端的边界服务先以离线 stub 实现。

### 设计意图
`game-design-documents/`（`game-design` 分支 —— 仅文档，孤儿历史）承载**客户端**的人工设计交接：游戏*应该*是什么样的事实来源。这里的 `knowledge/*` 是它的**提炼后**、面向 Claude 的视图。规划一个功能时，先阅读相关的设计文档。

`backend-design-documents/`（`backend-design` 分支 —— 同为仅文档、孤儿历史）承载**后端**的设计意图：账号合规、协议契约、存档同步、内容分发、剧本下发。

两个设计库都归用户所有 —— Claude 读它们以做规划，只有在被要求时才编辑。

---

## 目录结构

```
.claude/
├── CLAUDE.md            — entry; imports rules/Context.md
├── settings.json        — permissions (deny 保护四个只读快照目录) + model + effortLevel (no hooks)
├── settings.local.json  — 本机的设置覆盖
├── session-tags.json    — session 收藏/标签存储 (session-manager 写入)
├── blueprints/          — 实现蓝图 + _index.md 台账 (gitignored, 本机)
├── README.md            — this file
├── .gitignore
├── rules/
│   ├── Context.md               — always-on conventions + knowledge nav (keep < ~250 lines)
│   ├── environment-rules.md     — this machine's tools/PATH
│   ├── csharp-godot-rules.md    — C#↔Godot interop conventions
│   ├── scene-rules.md           — scene / node composition & instancing
│   ├── data-resource-rules.md   — Resource-driven data (.tres)
│   ├── state-save-rules.md      — run state, seeded RNG, save atomicity
│   ├── ui-input-rules.md        — mobile portrait layout + touch input
│   └── null-check-rules.md      — validate GetNode / ResourceLoad / lookups
├── knowledge/
│   ├── architecture.md          — scene tree, autoloads, render/resolution
│   ├── dictionary.md            — game glossary
│   ├── systems/     (_index.md; per-system notes appear as systems land)
│   ├── data/        (_index.md — 内容已并入设计库 20-systems/，此处为引用层)
│   ├── scenes/      (_index.md; per-scene notes appear as scenes land)
│   ├── autoloads/   (_index.md; per-singleton notes appear as autoloads land)
│   └── standards/   (csharp-conventions, godot-scene-conventions,
│                     mobile-portrait-ui, rng-determinism, save-format, signal-eventbus)
├── scripts/
│   ├── session-manager*         — session favorites/tags helper
│   └── push-all-impl.ps1        — 批量 commit/push 全部分支检出目录（经根级 push-all.cmd 调用）
└── skills/
    ├── analyze-new-ideas/     — raw idea → clean handoff → distill into design docs
    ├── summarize-open-questions/ — rebuild open-questions.md; answered items → answer-logs/log-<draftSuffix>.md
    ├── assess-derive-readiness/ — full sweep: is any design doc ready to derive? (manual)
    ├── derive-requirements/   — detailed design → buildable feature requirements (FR-*)
    ├── blueprint/        — explore + design an implementation blueprint (from an FR or free text)
    ├── implement/        — implement per blueprint
    ├── review-local-changes/  — review uncommitted changes
    ├── review-feature/   — review a feature's full chain
    ├── investigate/      — trace a bug to ranked root causes
    ├── sync-knowledge/   — reconcile knowledge/* against code + design docs
    ├── update-readme/    — realign every README.md with what it describes
    └── session-manager/  — session favorites/tags
```

---

## 功能工作流

设计 → 需求 → 代码：

1. `/analyze-new-ideas <raw>` —— 把原始意图捕获为整洁的 handoff，并提炼进 `game-design-documents/`（`20-systems/`、`40-ux/`）。无参数运行则扫描 `90-inbox/` 列出待处理草稿。
2. `/assess-derive-readiness` —— **由用户手动调用**。全量扫描全部主题文档，逐份判定 ready / partial / blocked，并整体重写 `open-questions.md` 的「derive 就绪度」小节（它是该小节的**唯一写入者**）。`/analyze-new-ideas` 与 `/summarize-open-questions` **均不评估就绪度**。**当前：全库尚未进入可 derive 的阶段。**
3. `/derive-requirements <doc>` —— 一旦某份设计文档已充分详尽（真实意图、无遗留问题），就把可构建的功能规格产出到 `game-design-documents/60-requirements/FR-*`。用户签署确认（`draft → ready`）。
4. `/blueprint FR-<id>` —— 探查知识 + 代码、澄清、把一份实现蓝图保存到 `blueprints/`（其验收标准驱动设计）。自由文本 `/blueprint <feature>` 仍然可用。
5. `/implement [blueprint]` —— 在 `game-feature-branch/` 中构建它。
6. `/review-local-changes` 或 `/review-feature` —— 在提交前捕获 bug。
7. `/investigate <symptom>` —— 把一个 bug 追溯到按可能性排序的根因 + 诊断步骤。

`knowledge/` 下的知识是设计文档的提炼后、面向 Claude 的视图 —— `/implement` 会在构建时就地更新相关的 `systems/`、`scenes/`、`data/`、`autoloads/` 笔记；怀疑知识与代码/设计脱节时运行 `/sync-knowledge` 做整体对账。术语的权威在 `game-design-documents/terminology.md`（提炼至 `knowledge/dictionary.md`）。

台账闭环：`/blueprint` 把 FR 翻为 `blueprinted` 并登记 `blueprints/_index.md`；`/implement` 在验证通过后把 FR 翻为 `built`。

---

## 扩展

- **新约定** → 新增 `knowledge/standards/<topic>.md`，从 `Context.md` 的导航表中链接它。优先新增知识文件，而非让 `Context.md` 膨胀。
- **新技能** → 新增 `skills/<name>/SKILL.md`。
