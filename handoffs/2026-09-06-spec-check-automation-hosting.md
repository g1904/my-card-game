# 三条机检断言的工程承载

- id: 2026-09-06-spec-check-automation-hosting
- date: 2026-09-06
- topic: contracts/_index（契约变更的完成判据 → 机检的工程承载）· contracts/envelope（§1 指路 · §3 端点全集与 P-3 · §6 台账 P-1 · Open questions）· operations/deployment · operations/_index
- status: distilled
- distilled-to: `contracts/_index.md`、`contracts/envelope.md`、`operations/deployment.md`、`operations/_index.md`、`answer-logs/log-spec-check-automation-hosting.md`

## Intent（distilled）

契约变更的完成判据、三条机检断言与人工清单四项都已成文，唯独**工程承载**空着：断言由什么跑、跑在哪条分支的什么事件上、失败时阻断什么、`openapi.yaml` 尚未落笔期间怎么执行、何时从人工迁到自动。悬着的后果是完成判据第 4 条「三条机检断言通过」**没有可勾选的兑现物**——只能靠人记得读一遍两张表并对一遍集合，而断言②守的漂移形态恰恰是静默的。

### 1. 承载 = 设计库分支自带的一条独立检查，不引第二套 CI

断言的校验对象是 markdown + YAML + JSON，**零云资源依赖**；镜像构建则需云侧镜像仓库凭据，且跑在后端实现分支上——那条分支没有 `contracts/`。就近原则：校验挂在代码托管方自带的 CI 上，与镜像构建各自独立，不为一条纯文本检查再引入第二套 CI 系统。

「可作为普通检查步骤挂在同一条流水线上」应读作**承接能力的陈述**（这类检查在任何 CI 上都是一个普通步骤），不构成「必须与镜像构建同处一条流水线」的要求——事实上不可能同处，`contracts/` 只存在于设计库分支。`operations/deployment.md` 的该句因此改写为「设计库分支上的独立 workflow，与镜像构建无依赖」。

### 2. 跑在哪：设计库分支，push + 手动，带路径过滤

| 项 | 形态 |
|---|---|
| workflow 落点 | 设计库分支根的 `.github/workflows/contract-spec-check.yml` |
| 触发 | `push`（该分支）+ `workflow_dispatch` |
| 路径过滤 | `contracts/**` · 校验脚本目录 · 该 workflow 自身 |
| runner | 通用 Linux runner，不需要 .NET / Godot |
| 脚本落点 | 库根的 `tools/spec-check/`，**不放进 `contracts/`** |

两点理由：**workflow 必须与被校验对象同分支**（`push` 事件读取被推送那个 commit 自身的 workflow 文件；放在别的分支会退化成一次跨分支检出，多一个可漂移的引用）；**脚本不放 `contracts/`**（那里每个文件都登记为契约产物，混入脚本会破坏这个读法，也会让断言③把工具文档里的示例路径当成端点）。后端实现分支不挂本检查——它没有 `contracts/`。

### 3. 失败时阻断什么：阻断「变更被视为完成」，不阻断 push

当前工作流是直推、没有 PR 环节，CI 在物理上无法阻断一次推送，只能在推送之后判定。故：绿灯 = 完成判据第 4 条的兑现物；红灯 = 该次契约变更未完成，须**前滚一次修复提交**，红灯期间不得据该契约推进实现或跨库 handoff。**无条件触发、不设跳过开关**（与 `operations/content-delivery-ops.md` C3 同构）。但 C5 的「阻断 = 什么都还没发生」在此不成立——那道闸拦在产物生成之前，这里提交已进入历史；差异须写明，避免读者按 C5 的心智以为红灯等于回滚。通知走托管方默认，不进 `operations/observability.md` 的告警面。

### 4. spec 未落笔期间的降级：②③ 收缩为 markdown 内部双向核对，①报 `skipped`

`openapi.yaml` 与 `schemas/*.json` 尚未落笔，三条断言原样理解则全部无对象，「以人工清单前三项执行」在这个阶段是人对着不存在的 spec 勾三个框。降级形态取 markdown 内部的双向核对：②比对 `envelope.md` §6 台账首列 ⇔ 六份契约正文的 `code` 字面量；③比对 `envelope.md` §3 端点全集 ⇔ 六份契约正文的 `METHOD 路径`（含 CDN 域三端点）。①输出 `skipped: no spec yet` 而非 `pass`——把「没有对象」记成「通过」会让判据 4 在 spec 落笔那天从绿变绿，看不出承接面变了。markdown 内部那一半在 spec 落笔后**不删**：它与 spec 那一半校验的对象不同，同时保留才能定位漂移出在哪一侧。人工清单四项不受影响，永远保持人工。

### 5. 切换判据 = 文件存在性驱动

`contracts/openapi.yaml` 在被检出的树中存在 → 三条全跑且必须全绿；不存在 → ①报 `skipped`，②③跑 markdown 内部那一半。这样「从人工迁到自动」不是一个需要有人记得执行的动作，而是首落 spec 那次提交的自动后果。用开关表达则必然出现「spec 已落、开关忘了开」的静默窗口。`schemas/*.json` 逐个新增时由①的 `$ref` 解析自动纳入。

### 6. 工具形态

契约文档继续只立能力要求（能校验 OpenAPI 3.1 / JSON Schema 2020-12、能在设计库侧运行），并把「不点名」的约束面讲清楚：被约束的是**契约文档**不得把某个具体工具写成契约的一部分；脚本里出现具体包名不违反它，工具选择是工程实现、可随时替换而不构成契约变更。追加一条硬要求：**同一套检查必须能在本地以一条命令跑完**，CI 只是它的无人值守执行。脚本以 runner 预装的解释器写成、零第三方依赖安装（提取逻辑只是正则 + 集合比较），唯一需要装的是 OpenAPI 3.1 校验器且只在 spec 存在时才装；语言不在此定死。

### 7. 三条提取护栏

②③是正则提取 + 集合比较，最常见的失败模式不是漏检而是假阳性与提不出来。

- **P-1**：`envelope.md` §6 台账首列必须是裸 `code` 字面量（反引号包裹、无附加文字、无换行、无合并单元格），自此是机器读取面，改表结构须同批改脚本。
- **P-3**（本次新增）：`envelope.md` §3 端点全集展开为逐条 `METHOD 路径` 的完整表并升为机器读取面；新增 / 删除 / 改名端点须在同一次契约变更内同批改该表。
- **P-2**：排除清单落在校验脚本的配置里、每条带一行理由，新增排除项须在该次契约变更中显式提及，不得静默追加——排除清单是消灭断言的最省事路径。已知条目：`compliance.md` 的 `downloadUrl`（外部对象 URL，非本 API 端点）· 同文件「备选方案」段残留的 `DELETE /v1/compliance/deletion`（被否决的形态，现行端点是 `POST .../cancel`）· 本库索引与 README 内的端点字面量（非契约正文）。②的扫描面另排除 §6 台账本身（它是基准侧，含进来会让第二个方向自指恒真）。

## Clarifications

- **契约变更是否引入 PR 门 → 保持直推 + 事后红灯**（用户裁决）。红灯 = 该次契约变更未被视为完成，须前滚一次修复提交。依据：`operations/content-delivery-ops.md` A4 已就同类问题裁定「不设强制第二人审批——当前单人维护，四眼原则是纯摩擦」；设计库当前无下游消费者，PR 门的唯一增量（阻断在合并前而非提交后）价值近零而摩擦每次都付。**复议触发点**：后端进入实现、`contracts/` 出现真实消费者时重估。
- **断言③的比较基准 → 展开 `envelope.md` §3 为完整 `METHOD 路径` 清单并升为机器读取面（P-3）**（用户裁决）。原方案写「⇔ §3 端点清单」，而 §3 当时是前缀 + 省略号、不带方法的形态：auth / compliance / purchase 三域的全部端点会被报成「§3 缺失」，断言落地当天即全红。备选是把基准改为各契约自己的端点小节，但那会让断言退化为同文档自检、跨文档漂移检不出，且基准散在五处。保留跨文档双向核对，与断言②「台账 ⇔ 各契约正文」同构。
- **本次是否同批建出 workflow 与脚本 → 只落设计**（用户裁决，授权范围仅为设计库写入）。`.github/workflows/contract-spec-check.yml` 与 `tools/spec-check/` **尚未落地**；在落地之前，三条断言以人工清单的前三项形式执行。
- **②的扫描面须排除 `envelope.md` §6 台账本身 → 采纳标准默认**。否则「markdown → 台账」这个方向自指恒真，断言退化为半向。核实：台账每一条 `code` 都至少在一份非 `envelope.md` 的契约正文中出现，降级期的②落地当天即可全绿，不是空转。
- **排除清单的第二、第三条 → 按直读实测补入**（`compliance.md` 备选方案段的 `DELETE /v1/compliance/deletion`、索引与 README 内的端点字面量）。原方案只列了 `downloadUrl` 一条。
- **不新建 ADR → 采纳**。这是工程承载的落位，不与任何既有架构决策相抵，权威落 `contracts/_index.md` 与 `operations/deployment.md` 即可。

## Open questions

- **workflow 与校验脚本尚未落地。** 形态已定（第 2 / 6 / 7 节），但 `.github/workflows/contract-spec-check.yml` 与 `tools/spec-check/` 两处文件本次未创建，落地是一次独立的动手——脚本须实跑验证，而未验证的脚本一进分支就会产生一次与「红灯 = 契约变更未完成」撞车的红灯。落地前三条断言按人工清单前三项执行。
- **脚本语言与 OpenAPI 3.1 校验器的具体选型**留给落地那次，契约文档不点名。

## Notes / triage

- 无跨库对侧义务：断言校验的是本库 `contracts/`，客户端侧无承接项，本次不写客户端 counterpart。
- 无报文改动、无新增 `code`、不涉及 `schemaVersion` / `/v1/` / `info.version` 的任何 bump。
- 本条自此与 `open-questions/06-platform-stack.md` 脱钩——断言与后端栈无关，`06` 余下各条不受影响。

## 客户端侧影响

**无。** 三条机检断言校验的是本库 `contracts/` 下的 markdown 与（将来的）spec，不改动客户端 ↔ 后端边界的任何语义、报文或错误码。`game-design-documents/` 侧无需同步更新。
