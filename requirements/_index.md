# Feature Requirements — Index（后端）

详细设计意图与实现之间的**桥梁**。每个 `FR-*.md` 都是一个离散、可独立构建的后端能力，在设计文档（`vision/` + `contracts/` + `systems/`）充实、Open questions 得到解决之后，从中推导而来。

## 现状

**当前尚无 FR。** 各主题文档的推导就绪度以 `open-questions.md` 的「derive 就绪度」小节为唯一权威（由 `/assess-derive-readiness` 全量评估后写入）——此处不另作判断。

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
- `broken-down` — 已拆为子需求（文件夹在 `breakdown:` 中链接）；父 FR 自身不再直接进 blueprint，但仍是**覆盖核对的基准**。**只由 `ready` 或 `draft` 迁入**，迁入前的签核状态记在父 FR frontmatter 的 `signed-off-as` 一格。
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
- **签核语义：父 FR 签核即覆盖其子需求**——子需求继承父 FR 的**签核状态**，不再逐个签核（签核的实质对象是验收标准集合，而拆解只重排父 FR 已有的内容）。
- **唯一例外 —— Open-questions 闸：`## Open questions` 非空的子需求一律产出为 `draft`。** 否则会产出台账写着 `ready`、进 blueprint 却被当未签核拦下的子需求。
- **规则的判定对象是「签核状态」，不是 `status` 字面值。** 父 FR 拆解后 `status` 即为 `broken-down`，而增量补子需求是受支持的路径 ⇒ **`broken-down` 只由 `ready` 或 `draft` 迁入**，父 FR frontmatter 用一格 **`signed-off-as`** 记住迁入前的签核状态。
- **覆盖核对是强制的：** 父 FR 的每条验收标准都必须映射到至少一个子需求。

## 拆解粒度判据（后端）

**本节只约束子需求，不约束父 FR**（父 FR 是片区级，本就允许横跨契约、服务逻辑与存储）。

**机械处理 —— 软界，不硬拒：** 超过任一上界 ⇒ 应再切；触发下界 ⇒ 应并入兄弟子需求。两端都可豁免，但**必须在拆解文件夹的 `_index.md` 里写一行理由**，否则照判据再切 / 再并。硬性拒绝会在真有不可分的切片时逼出「为过闸而人为切碎」的假子需求。

### 软上界 —— 超过任一项 ⇒ 应再切

| # | 指标 | 上界 | 依据 |
|---|---|---|---|
| U1 | 验收标准条数 | 5 | 一次 blueprint 能一口吃下的量 |
| U2 | 触及的端点 / 报文 | 新端点 ≤ 1，或既有端点上 ≤ 1 组字段 | 端点是本库最稳定的可交付边界（技术栈未定，文件边界不存在） |
| U3 | 主写的持久化对象数 | 1（profile 记录 / `revision` 计数器 / `pushId` 窗口 / manifest 各计一处） | 主写两处以上通常意味着它其实是两条通路 |
| U4 | 新契约字段组 | 1，且**必须已在 `contracts/` 中定义** | FR 只引用契约、不发明报文；拆解同样不得自造 |
| U5 | 存储 schema / 版本迁移点 | 1 | 迁移承重且易错，一次一处 |
| U6 | 到达被验证状态所需的请求数 | 1（一次请求可达） | 「给定请求 / 状态 → 期望应答 / 存储结果」是本库「可验证」的形态 |

### 软下界 —— 任一触发项成立 ⇒ 应并入兄弟子需求

| # | 指标 | 触发条件 | 角色 |
|---|---|---|---|
| L1 | 可表述为「给定请求 / 状态 → 期望应答 / 存储结果」的验收标准条数 | < 1（「建好某层」不算） | **触发项** |
| L2 | 可观察的应答 / 存储状态变化 | 无 | **触发项** |
| L3 | 触及面 | 仅一处内部结构调整，不改变任何对外可观察结果 | 辅助信号 |
| L4 | 完成后服务是否仍可部署 | 否（半截状态） | 辅助信号 |

### 不可切约束（后端专有）

> 模板强制的 `## Failure & retry semantics` **必须在同一个子需求内完整**——不得把「正常路径」与「幂等 / 重试 / 冲突语义」切成两个子需求。

半个失败语义不可验证，而弱网下的幂等与重试是后端 FR 的承重设计；先做正常路径、后补重试的切法会产出一个**验收标准全通过但线上必炸**的中间状态。

### 两库对称

客户端库有它自己的一份同构判据（指标不同：改动文件数 / 涉及的服务数 / EventBus 信号 / 存档迁移点 / 编辑器验证前置步数，另有纯数据资源型子需求的三条闸），见 `game-design-documents/requirements/_index.md` 的「拆解粒度判据」。**两库的 FR 与其台账各自独立、永不合并**：本节只写后端指标，客户端指标不在此复述——两份表会各自漂移，而无机制能发现它们不一致。上表的阈值同属**待校准初值**（两库皆零实测），首批 FR 跑通后回看。

Source: `handoffs/2026-08-19-breakdown-granularity-and-signoff.md`

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
