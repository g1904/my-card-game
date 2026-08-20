# Feature Requirements — Index

详细设计意图与实现之间的**桥梁**。每个 `FR-*.md` 都是一个离散、可独立构建的功能，在设计文档（`vision/` + `20/30/40`）的 `## Intent` 充实、`## Open questions` 得到解决之后，从中推导而来。

需求由 `/derive-requirements`（它会执行就绪性门槛）**生成**、由 `/breakdown-requirements` **拆细**，并由 `/blueprint` **消费**。它们是用户可评审的规格——在某个 FR 被拆解 / blueprint 之前先签核它（把 `draft → ready`）。

## 流水线位置
```
20/40 topical docs (detailed) → [readiness gate] → /derive-requirements
    → requirements/FR-*.md (片区级，带验收标准)
        → /breakdown-requirements → requirements/FR-*/  (可执行子需求)
            → /blueprint → /implement
```

**为何多一环拆解：** `/derive-requirements` 的产出是**从设计文档整片切下来的**，粒度往往仍横跨数据资源、服务逻辑、场景与接线；直接喂 `/blueprint` 会得到一份过大的蓝图。`/breakdown-requirements` 把一份 FR 拆成一个**同名文件夹**内的若干子需求，每个都小到能被 `/blueprint` 一次吃下。

Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`

## 状态词汇
- `draft` — 已推导，但仍有未解决的 Open questions 或等待你评审。
- `ready` — 你已签核；验收标准已定；可安全拆解 / `/blueprint`。
- `broken-down` — 已由 `/breakdown-requirements` 拆为子需求（文件夹在 `breakdown:` 中链接）；父 FR 自身不再直接进 `/blueprint`，但仍是**覆盖核对的基准**。**只由 `ready` 或 `draft` 迁入**，迁入前的签核状态记在父 FR frontmatter 的 `signed-off-as` 一格（子需求的签核规则读它）。
- `blueprinted` — 已存在一份 `.claude/blueprints/<slug>.md`（在 `blueprint:` 中链接）。
- `built` — 已在 `game-feature-branch/` 中实现并验证。

## 两层结构（父 FR ↔ 子需求）
```
requirements/
├── _TEMPLATE.md                     ← 父 FR 形态（/derive-requirements 用）
├── _TEMPLATE-sub.md                 ← 子需求形态（/breakdown-requirements 用）
├── FR-<system>-<slug>.md            ← 父 FR（片区级，status: broken-down）
└── FR-<system>-<slug>/              ← 拆解产物
    ├── _index.md                    ← 子需求一览 + 父验收标准覆盖映射表 + 构建顺序
    └── FR-<system>-<slug>-01-<subslug>.md ...
```
- **子需求 id = `<父 id>-<两位序号>-<subslug>`**；序号即默认构建顺序，真实依赖写在 `depends-on`。
- **签核语义：父 FR 签核即覆盖其子需求**——子需求继承父 FR 的**签核状态**，不再逐个签核。签核的实质对象是**验收标准的集合**，而拆解不新增标准（拆解只重排父 FR 已有的内容，推不出的进子需求的 `## Open questions`）+ 覆盖核对强制每条父标准都被映射 ⇒ 该集合在拆解前后同一，逐个签核等于把同一批标准签第二遍。
- **唯一例外 —— Open-questions 闸：`## Open questions` 非空的子需求一律产出为 `draft`。** 这是父 FR 模板同一条规则（Open questions 非空 ⇒ 不是 `ready`）下沉一层：切分时被隔离出来的未决部分，父签核时不可能签过它；若仍继承为 `ready`，台账写着 `ready` 而 `/blueprint` 会把它当未签核拦下，状态词与下游行为不一致。闸可机械判定（看一个小节空不空），签核负担只落在真正未决的少数条目上。

  ```
  父 FR 签核状态 = ready  ∧  子需求 ## Open questions 为空   ⇒  子需求 = ready
  父 FR 签核状态 = ready  ∧  子需求 ## Open questions 非空   ⇒  子需求 = draft
  父 FR 签核状态 = draft                                     ⇒  子需求 = draft
  ```

- **规则的判定对象是「签核状态」，不是 `status` 字面值。** 父 FR 拆解后 `status` 即为 `broken-down`，而往既有拆解文件夹补新子需求（增量拆解）是受支持的路径——按字面值判定时三条规则一条都不匹配。故：**`broken-down` 只由 `ready` 或 `draft` 迁入**，父 FR frontmatter 用一格 **`signed-off-as`** 记住迁入前的签核状态，上表读它。
- **切分本身与 `depends-on` 依赖链不新增状态词**，它们是工程判断而非需求内容：评审面就是拆解文件夹的 `_index.md`（子需求一览 + 覆盖映射表 + 构建顺序），`/breakdown-requirements` 在报告中点名请用户过一眼即可。
- **覆盖核对是强制的：** 父 FR 的每条验收标准都必须映射到至少一个子需求，映射表在拆解文件夹的 `_index.md`。

## 拆解粒度判据

**本节只约束子需求，不约束父 FR。** 父 FR 是片区级切片，本就允许横跨数据资源、服务逻辑、场景与接线。

**归属：判据 = 用户的评审面在哪一侧。** 阈值与准入闸是可数的、且是用户的评审面 ⇒ 归本节；切法与顺序（先切骨架还是先切数据、依赖如何成链）是工程手法 ⇒ 归 `/breakdown-requirements` 技能。全局形态的归属裁决见 `decisions/ADR-0005-knowledge-thin-reference-layer.md`。

**机械处理 —— 软界，不硬拒：** 超过任一上界 ⇒ 应再切；触发下界 ⇒ 应并入兄弟子需求。**两端都可豁免，但必须在拆解文件夹的 `_index.md` 里写一行理由，否则照判据再切 / 再并。** 硬性拒绝会在真有不可分的切片时逼出「为过闸而人为切碎」的假子需求；软界拿到同样的约束力，且把判断留痕、可事后复核。

### 软上界 —— 超过任一项 ⇒ 应再切

| # | 指标 | 上界 | 依据 |
|---|---|---|---|
| U1 | 验收标准条数 | 5 | 一次 `/blueprint` 能一口吃下的量 |
| U2 | 新建 + 修改文件数 | 8（`.cs` / `.tscn` / `.tres` 合计；同一类型的多个 `.tres` 条目计为 1 处） | `/blueprint` 须逐文件列出并为每一次查找 / 加载给出 null 校验计划；文件一多，蓝图从计划退化为说明书 |
| U3 | 涉及的服务数 | 1（一个服务 + 它的 UI / 场景对端） | 七服务是唯一稳定的职责切面（`systems/services/_index.md`）；碰两个服务通常意味着它其实是两条通路 |
| U4 | 新引入 EventBus 信号数 | 1 | 信号是跨系统契约面，负载 schema 一旦定下即被多方消费；一次一条，蓝图才能把负载定死 |
| U5 | 新增存档 schema 迁移点数 | 1 | 迁移牵动原子写入与版本化，承重且易错 |
| U6 | 验证前置操作步数 | 3 | 验证靠人在编辑器里游玩；步数过多说明这片太靠链路末端，应先切出能更早观察到的骨架 |

- **U6 的起算点 = 该子需求所属系统的首个可交互屏**，全局启动链路（启动、登录、主菜单）的固定步骤不计。启动链路长度是全局常量，计入会让所有子需求同步超界、指标失去区分力。
- **U2 与 U6 是待校准初值**（本库尚无跑过的拆解，数字由 `/blueprint` 的逐文件义务外推而来）。在前三次 `breakdown → blueprint → implement` 完整跑通后回看一次实际值并调整；软界本就允许超界，初值偏了只多几行理由。

### 软下界 —— L1 或 L2 成立 ⇒ 应并入兄弟子需求

| # | 指标 | 触发条件 | 角色 |
|---|---|---|---|
| L1 | 真实可观察的验收标准条数 | < 1（「建好某层」不算） | **触发项** |
| L2 | 在 Godot 编辑器中可观察的结果（含启动期日志 / 报错） | 无 | **触发项** |
| L3 | 改动文件数 | 1 且该文件不能独立运行（典型：只加一个字段） | 辅助信号 |
| L4 | 完成后项目是否仍可运行 | 否（半截状态） | 辅助信号 |

L1 / L2 是「这片根本没有可观察产出」的直接判定，任一成立即触发；L3 / L4 是它的两种典型症状，作提示用、不单独触发。取析取而非合取：一个改三个文件、却零可观察产出的横向层子需求在合取下会漏网，而它正是「按可观察行为切，不按代码层切」要挡的东西。

### 纯数据资源型子需求 —— 允许独立成条，须过三条闸

一个不含任何 UI / 玩法行为的子需求可独立成条，**当且仅当**三条同时成立：

1. 定义了一个 `XxxData : Resource` 类**并**至少一个真实（非空壳）`.tres` 条目；
2. 该条目经 **DataRegistry 在启动期加载、并能按 `Id` 被查到**（不是只躺在磁盘上）；
3. 至少有**一条负向验收标准**：故意坏 id / 缺必填字段 ⇒ 启动期 `GD.PushError` 报出其 id 与路径。

缺任一条 ⇒ 不独立成条，**并入消费它的那个子需求**。

**过闸的数据型子需求仍是薄纵切片，不是横向层** —— 因为**启动期校验报错本身就是一种可观察行为**：玩家看不见一个 `.tres`，但开发者能在编辑器输出里看见它被加载与被校验，这就满足了「验证靠在编辑器里运行游戏观察」的形态，无需任何测试框架。反过来，②③ 缺失的「把所有数据类建好」正是「不按代码层切」要挡的那种东西。**这层区分不写清就会被读成「数据层可以横着切」。**

### 两库对称

后端库有它自己的一份同构判据（指标不同：触及端点 / 主写持久化对象 / 契约字段组 / 存储 schema 迁移，另加一条不可切约束），见 `backend-design-documents/requirements/_index.md`。**两库的 FR 与其台账各自独立、永不合并**：本节只写客户端指标，后端指标不在此复述——两份表会各自漂移，而本库没有任何机制能发现它们不一致。

Source: `handoffs/2026-08-19-breakdown-granularity-and-signoff.md`

## 台账
> 最新的置顶。每个 FR 一行。

| id | system | title | status | blueprint | source-docs |
|----|--------|-------|--------|-----------|-------------|
| _(暂无)_ | | | | | |

## 约定
- **id** = `FR-<system>-<slug>`；`<system>` 与它所推导自的主题文档 / 知识笔记对应。子需求 id 见上方「两层结构」。
- 一个 FR = 一个可构建的增量，带自己的验收标准。把大型系统拆成数个通过 `depends-on` 相连的 FR；单个 FR 内部仍过大时用 `/breakdown-requirements` 再拆一层——拆到多细见上方「拆解粒度判据」。
- 每个 FR 都要能追溯回它的 `source-docs`；绝不断言源设计不支持的需求（未知项进入该 FR 的 `## Open questions`）。
