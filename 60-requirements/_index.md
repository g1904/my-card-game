# Feature Requirements — Index

详细设计意图与实现之间的**桥梁**。每个 `FR-*.md` 都是一个离散、可独立构建的功能，在设计文档（`00-vision/` + `20/30/40`）的 `## Intent` 充实、`## Open questions` 得到解决之后，从中推导而来。

需求由 `/derive-requirements`（它会执行就绪性门槛）**生成**、由 `/breakdown-requirements` **拆细**，并由 `/blueprint` **消费**。它们是用户可评审的规格——在某个 FR 被拆解 / blueprint 之前先签核它（把 `draft → ready`）。

## 流水线位置
```
20/40 topical docs (detailed) → [readiness gate] → /derive-requirements
    → 60-requirements/FR-*.md (片区级，带验收标准)
        → /breakdown-requirements → 60-requirements/FR-*/  (可执行子需求)
            → /blueprint → /implement
```

**为何多一环拆解：** `/derive-requirements` 的产出是**从设计文档整片切下来的**，粒度往往仍横跨数据资源、服务逻辑、场景与接线；直接喂 `/blueprint` 会得到一份过大的蓝图。`/breakdown-requirements` 把一份 FR 拆成一个**同名文件夹**内的若干子需求，每个都小到能被 `/blueprint` 一次吃下。Source: `10-handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。

## 状态词汇
- `draft` — 已推导，但仍有未解决的 Open questions 或等待你评审。
- `ready` — 你已签核；验收标准已定；可安全拆解 / `/blueprint`。
- `broken-down` — 已由 `/breakdown-requirements` 拆为子需求（文件夹在 `breakdown:` 中链接）；父 FR 自身不再直接进 `/blueprint`，但仍是**覆盖核对的基准**。
- `blueprinted` — 已存在一份 `.claude/blueprints/<slug>.md`（在 `blueprint:` 中链接）。
- `built` — 已在 `game-feature-branch/` 中实现并验证。

## 两层结构（父 FR ↔ 子需求）
```
60-requirements/
├── _TEMPLATE.md                     ← 父 FR 形态（/derive-requirements 用）
├── _TEMPLATE-sub.md                 ← 子需求形态（/breakdown-requirements 用）
├── FR-<system>-<slug>.md            ← 父 FR（片区级，status: broken-down）
└── FR-<system>-<slug>/              ← 拆解产物
    ├── _index.md                    ← 子需求一览 + 父验收标准覆盖映射表 + 构建顺序
    └── FR-<system>-<slug>-01-<subslug>.md ...
```
- **子需求 id = `<父 id>-<两位序号>-<subslug>`**；序号即默认构建顺序，真实依赖写在 `depends-on`。
- **签核语义：父 FR 签核即覆盖其子需求**——父为 `ready` 时子需求直接产出为 `ready`，不再逐个签核（避免签核负担；若需逐个签核，让 `/breakdown-requirements` 一律产出 `draft`）。
- **覆盖核对是强制的：** 父 FR 的每条验收标准都必须映射到至少一个子需求，映射表在拆解文件夹的 `_index.md`。

## 台账
> 最新的置顶。每个 FR 一行。

| id | system | title | status | blueprint | source-docs |
|----|--------|-------|--------|-----------|-------------|
| _(暂无)_ | | | | | |

## 约定
- **id** = `FR-<system>-<slug>`；`<system>` 与它所推导自的主题文档 / 知识笔记对应。子需求 id 见上方「两层结构」。
- 一个 FR = 一个可构建的增量，带自己的验收标准。把大型系统拆成数个通过 `depends-on` 相连的 FR；单个 FR 内部仍过大时用 `/breakdown-requirements` 再拆一层。
- 每个 FR 都要能追溯回它的 `source-docs`；绝不断言源设计不支持的需求（未知项进入该 FR 的 `## Open questions`）。
