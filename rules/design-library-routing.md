# 设计库路由规则（双库入参）

项目有**两个彼此独立的设计库**，形态同构、内容互不覆盖：

| 库 | 本地文件夹 | 分支 | 承载 |
|---|---|---|---|
| 客户端设计库 | `game-design-documents/` | `game-design` | Godot 客户端的设计意图（含客户端侧的边界服务门面） |
| 后端设计库 | `backend-design-documents/` | `backend-design` | 云端服务的设计意图 + 客户端 ↔ 后端协议契约 |

设计流水线技能（`/analyze-new-ideas`、`/provide-solution-draft`、`/summarize-open-questions`、`/assess-derive-readiness`、`/derive-requirements`、`/breakdown-requirements`）对两库**通用**。本文件定义它们如何确定「这一次作用于哪个库」。

## 记法

技能正文中出现的 **`<LIB>/`** 一律指本次运行选定的库根（`game-design-documents/` 或 `backend-design-documents/`）。技能正文里写死的 `game-design-documents/` 路径，在选定后端库时**一律读作** `backend-design-documents/` 下的同名路径。

## 解析顺序（强制，逐级下降）

**① 显式库参数** —— `$ARGUMENTS` 中出现下列任一 token（大小写不敏感），取之并从参数中剔除，剩余部分作为技能本身的参数：

| token | 解析为 |
|---|---|
| `--lib=game` · `game` · `game-design` · `client` · `客户端` | `game-design-documents/` |
| `--lib=backend` · `backend` · `backend-design` · `server` · `后端` | `backend-design-documents/` |

**② 参数中的路径前缀** —— 参数是一个以 `game-design-documents/` 或 `backend-design-documents/` 开头的路径 → 取该库。

**③ 相对路径落地探测** —— 参数是一个不带库前缀的相对路径（如 `inbox/draft-0812.md`、`open-questions/01-contracts.md`）→ 在**两个库**中分别探测该文件是否存在：
- 只在一个库中存在 → 取该库；
- 两个库都存在 → **停下询问**，列出两个候选完整路径；
- 都不存在 → 停下报告，不要凭猜测创建文件。

**④ 无法判定** —— 参数为空、或只有主题词 / 粘贴文本 → **询问用户作用于哪个库**，并列出两库的在办入口（`<LIB>/inbox/` 顶层草稿 + `<LIB>/open-questions.md` 的分片导航）供选择。

**绝不静默默认。** 走到 ④ 就问——猜错会把后端意图写进客户端库（或反之），而这两库的内容是互不覆盖的，写错即污染事实来源。

## 跨库纪律

- **一次运行只作用于一个库。** 不要在同一次运行里同时写两库。
- **跨边界的意图不跨库承载。** 若一份输入同时改动客户端与后端（典型：协议契约变更），**不要**把它一并写进某一侧：产出选定库的 handoff / 文档，并在报告中明确点名「另一侧需要一份对应的 handoff」，由用户再跑一次。
- **回链而非复述。** 需要另一侧的语义时，写指向另一库的路径引用，不把对方的设计抄过来。
- **归属判据**（写在哪一侧）：由客户端代码实现、后端不感知 → 客户端库；由后端实现或需两侧约定报文 → 后端库；客户端语义已定、只剩服务端如何兑现 → 后端库（注明「客户端侧已定」+ 日期 + 回链）。权威表见两库各自 README。

## 两库的结构差异（技能必须按库调整的部分）

同名同形的部分：`handoffs/`、`inbox/`（含 `archive/`）、`decisions/`、`requirements/`（父 + 子模板 + `_index.md`）、`open-questions.md`（索引）+ `open-questions/`（分片 + `update-log.md`）、`answer-logs/`。**这些在两库中的约定完全一致**，技能无需分支处理。

差异：

| | `game-design-documents/` | `backend-design-documents/` |
|---|---|---|
| 主题文档区 | `vision/` · `systems/` · `art/` · `ux/` | `vision/` · `contracts/` · `systems/` · `operations/` |
| 根级横切文件 | `terminology.md` · `program-overview.md` · `system-overview.md` | 无（术语沿用客户端库的 `terminology.md`） |
| 需求模板差异 | `Data & state touchpoints` | 另有 `Contract touchpoints` 与**强制**的 `Failure & retry semantics` |
| 验收标准的可验证方式 | 在 Godot 编辑器里运行游戏观察 | 请求 → 应答 / 存储状态（后端栈未定前，只写可验证的断言形态，不指定测试工具） |
| ADR 编号 | 各自独立 —— 引用另一侧一律写全路径 | 同左 |
| 知识引用层 | `.claude/knowledge/*` 覆盖 | **无**——后端尚无引用层，技能不要去 `knowledge/` 找后端背景 |
| 代码落地分支 | `game-feature-branch/` | `backend-feature-branch/`（尚未开工，无技术栈） |

> **本表是「路由用副本」（显式例外 · 已裁定 2026-08-14）。** 两库结构的权威在各自 README；此处保留一份是因为它是技能路由的前置信息，
> 换成回链等于每次跑设计流水线技能都要先读两份 README，而路由判错的代价是把一侧的意图写进另一侧的库。
> **两库结构变更时此表须同改**，由 `/sync-knowledge` 对账兜底。

**扫描主题文档时**（`/summarize-open-questions`、`/assess-derive-readiness`、`/derive-requirements` 的候选枚举）按上表取该库的主题文档区，不要去找另一库才有的文件夹。

## 不在双库范围内的技能

下列技能**仍然只面向客户端**，不接受库参数：

| 技能 | 原因 |
|---|---|
| `/blueprint` · `/implement` | 产出面向 `game-feature-branch/` 的 Godot / C# 实现；后端技术栈未定，无从设计实现形态。 |
| `/review-feature` · `/review-local-changes` · `/investigate` | 审查 / 追踪 Godot 客户端代码。 |
| `/scaffold-content-type` · `/author-content` · `/audit-content` | 内容条目层 `content/` 只存在于 `game-design-documents/`；后端库没有这一分区。 |
| `/sync-knowledge` | `.claude/knowledge/*` 只覆盖客户端。 |

后端进入实现阶段（技术栈落定 + `contracts/` 成文）时再扩展这几项。`/update-readme` 本就按路径参数分发，不走本文件的库解析。
