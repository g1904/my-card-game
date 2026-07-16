# Feature Requirements — Index

详细设计意图与实现之间的**桥梁**。每个 `FR-*.md` 都是一个离散、可独立构建的功能，在设计文档（`00-vision/` + `20/30/40`）的 `## Intent` 充实、`## Open questions` 得到解决之后，从中推导而来。

需求由 `/derive-requirements`（它会执行就绪性门槛）**生成**，并由 `/blueprint` **消费**。它们是用户可评审的规格——在某个 FR 被 blueprint 之前先签核它（把 `draft → ready`）。

## 流水线位置
```
20/30/40 topical docs (detailed) → [readiness gate] → /derive-requirements
    → 60-requirements/FR-*.md (acceptance criteria) → /blueprint → /implement
```

## 状态词汇
- `draft` — 已推导，但仍有未解决的 Open questions 或等待你评审。
- `ready` — 你已签核；验收标准已定；可安全 `/blueprint`。
- `blueprinted` — 已存在一份 `.claude/blueprints/<slug>.md`（在 `blueprint:` 中链接）。
- `built` — 已在 `game-feature-branch/` 中实现并验证。

## 台账
> 最新的置顶。每个 FR 一行。

| id | system | title | status | blueprint | source-docs |
|----|--------|-------|--------|-----------|-------------|
| _(暂无)_ | | | | | |

## 约定
- **id** = `FR-<system>-<slug>`；`<system>` 与它所推导自的主题文档 / 知识笔记对应。
- 一个 FR = 一个可构建的增量，带自己的验收标准。把大型系统拆成数个通过 `depends-on` 相连的 FR。
- 每个 FR 都要能追溯回它的 `source-docs`；绝不断言源设计不支持的需求（未知项进入该 FR 的 `## Open questions`）。
