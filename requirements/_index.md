# Feature Requirements — Index（后端）

详细设计意图与实现之间的**桥梁**。每个 `FR-*.md` 都是一个离散、可独立构建的后端能力，在设计文档（`vision/` + `contracts/` + `systems/`）充实、Open questions 得到解决之后，从中推导而来。

## 现状

**当前尚无 FR，且暂不具备推导条件。** 前置是 `contracts/` 的契约骨架与 `systems/` 的服务文档——两者都尚未建立（见 `open-questions.md` 的「下一阶段」）。

> **工具说明：** `.claude/` 下的设计流水线技能（`/analyze-new-ideas`、`/provide-solution-draft`、`/summarize-open-questions`、`/assess-derive-readiness`、`/derive-requirements`、`/breakdown-requirements`）**已支持本库**：调用时加 `--lib=backend`，或直接给 `backend-design-documents/` 开头的路径。解析规则见 `.claude/rules/design-library-routing.md`。
> `/blueprint` 与 `/implement` 仍只面向客户端——后端技术栈未定，无从设计实现形态。

## 流水线位置
```
contracts/ + systems/ (详细) → [readiness gate] → 推导
    → requirements/FR-*.md (片区级，带验收标准)
        → 拆解 → requirements/FR-*/  (可执行子需求)
            → blueprint → implement (backend-feature-branch/)
```

## 状态词汇
- `draft` — 已推导，但仍有未解决的 Open questions 或等待你评审。
- `ready` — 你已签核；验收标准已定；可安全拆解 / blueprint。
- `broken-down` — 已拆为子需求（文件夹在 `breakdown:` 中链接）；父 FR 自身不再直接进 blueprint，但仍是**覆盖核对的基准**。
- `blueprinted` — 已存在一份实现蓝图。
- `built` — 已在 `backend-feature-branch/` 中实现并验证。

## 两层结构（父 FR ↔ 子需求）
```
requirements/
├── _TEMPLATE.md                     ← 父 FR 形态
├── _TEMPLATE-sub.md                 ← 子需求形态
├── FR-<service>-<slug>.md           ← 父 FR（片区级，status: broken-down）
└── FR-<service>-<slug>/             ← 拆解产物
    ├── _index.md                    ← 子需求一览 + 父验收标准覆盖映射表 + 构建顺序
    └── FR-<service>-<slug>-01-<subslug>.md ...
```
- **子需求 id = `<父 id>-<两位序号>-<subslug>`**；序号即默认构建顺序，真实依赖写在 `depends-on`。
- **签核语义：父 FR 签核即覆盖其子需求**——父为 `ready` 时子需求直接产出为 `ready`。
- **覆盖核对是强制的：** 父 FR 的每条验收标准都必须映射到至少一个子需求。

## 台账
> 最新的置顶。每个 FR 一行。

| id | service | title | status | client-facing | source-docs |
|----|---------|-------|--------|---------------|-------------|
| _(暂无)_ | | | | | |

## 约定
- **id** = `FR-<service>-<slug>`；`<service>` 与它所推导自的服务 / 契约文档对应。
- 一个 FR = 一个可构建的增量，带自己的验收标准。
- **`client-facing: yes` 的 FR 必须先有契约。** 报文在 `contracts/` 定义，FR 只引用不发明；这类 FR 的改动同时是跨库事件，需在客户端侧留一份对应记录。
- **`## Failure & retry semantics` 段对后端 FR 是强制的**——弱网下的幂等与重试是承重设计，不是补充说明。
