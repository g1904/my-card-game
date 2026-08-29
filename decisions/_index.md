# 决策台账（ADR，后端）

已敲定的方向性决策。**最新置顶。**

| id | 标题 | 状态 | 日期 | 影响文档 |
|---|---|---|---|---|
| `ADR-0017` | 零判定权字段的取值清单不是校验闸：未知取值宽容接收，清单增量不 bump 契约版本 | Accepted | 2026-08-28 | `contracts/profile-sync.md` |
| `ADR-0009` | flags 规则集不可变版本化：`flagsVersion` 严格单调 + 同版本结果恒定 | Accepted | 2026-08-23 | `contracts/content-manifest.md`, `operations/_index.md` |
| `ADR-0008` | 后端写入路径在上行侧只接受回声，不等即整批拒绝 | Accepted | 2026-08-22 · 08-23 | `contracts/profile-sync.md`, `contracts/envelope.md` |
| `ADR-0013` | `receiptId` 全局唯一 · 永久保留，且写入后的读路径必须读己所写 | Accepted | 2026-08-22 | `contracts/purchase.md`, `contracts/profile-sync.md` |
| `ADR-0014` | 透明路径的集合字段名恒为单数，改名做一次性切换不设兼容期 | Accepted | 2026-08-17 | `contracts/profile-sync.md`, `contracts/envelope.md` |
| `ADR-0016` | 免鉴权是一条判据，不是一份名单：调用者此刻不可能持有 access token | Accepted | 2026-08-16 | `contracts/envelope.md`, `contracts/auth.md`, `contracts/compliance.md` |
| `ADR-0015` | `reasonKey` 形态锁死为 PascalCase，二级文案键由 `code` + `reasonKey` 机械变换 | Accepted | 2026-08-16 | `contracts/auth.md`, `contracts/compliance.md`, `contracts/envelope.md` |
| `ADR-0011` | 单账号一条活跃会话：后登录挤下线 + `sid` 精确吊销 + `signin` 回放窗口 | Accepted | 2026-08-16 | `contracts/auth.md`, `contracts/compliance.md`, `contracts/envelope.md` |
| `ADR-0010` | 身份主体自建、`account ↔ identity` 一对多，绝不做隐式账号合并 | Accepted | 2026-08-16 | `contracts/auth.md`, `contracts/envelope.md`, `contracts/profile-sync.md` |
| `ADR-0007` | 购买写入只由 verify 端点承担，渠道回调降为对账通道 | Accepted | 2026-08-16 | `contracts/purchase.md`, `contracts/profile-sync.md` |
| `ADR-0012` | 授予来源 `Source` 的跨边界表示：契约走字符串枚举名，名与 code 双双冻结 | Accepted | 2026-08-14 | `contracts/profile-sync.md`, `contracts/envelope.md` |
| `ADR-0006` | 账号级掷骰的随机源 = 契约定义的纯函数 SplitMix64 | Accepted | 2026-08-14 | `contracts/profile-sync.md`, `contracts/vectors/splitmix64.json`, `contracts/envelope.md`, `contracts/purchase.md` |
| `ADR-0005` | 防作弊边界：可复算 `roll`、不复算阈值；不一致仅记账不拒绝 | Accepted | 2026-08-14 | `contracts/profile-sync.md`, `contracts/purchase.md` |
| `ADR-0004` | auth 域的幂等与 sync 域的幂等是同一条纪律 | Accepted | 2026-08-13 | `contracts/auth.md`, `contracts/envelope.md` |
| `ADR-0003` | 契约表达形式 = OpenAPI 3.1 单点，不共享 DTO 代码 | Accepted | 2026-08-11 | `contracts/envelope.md`, `contracts/_index.md` |
| `ADR-0002` | flags 第三层只覆盖 `ContentEnabled` | Accepted | 2026-08-11 | `contracts/content-manifest.md`, `contracts/envelope.md` |
| `ADR-0001` | 内容分发走内容寻址，`contentVersion` 严格单调递增 | Accepted | 2026-08-11 | `contracts/content-manifest.md` |

**编号与客户端库各自独立**：本库的 `ADR-0001` 与 `game-design-documents/decisions/ADR-0001` 无关。引用另一侧的 ADR 一律写全路径。

## 状态词汇

- `Proposed` — 已提出，尚未采纳。
- `Accepted` — 已采纳，约束后续设计。
- `Superseded` — 已被取代（**本库通常直接改原 ADR，很少用此状态**）。

## 约定

**ADR 可自由编辑。** 后端开发尚未开始 —— 要改一个决定，就**直接改这份 ADR**，不必新开一个 ADR 去取代它，也不设 `supersedes` / `superseded-by` 字段。历史归 git。承 `.claude/rules/Context.md` 的「一切皆可改」与「活文档只保留最新设计」。

**本台账与 `decisions/` 的唯一写入者是 `/write-adr`。** 编号从现有最大值 +1 递增，**不回收、不重排**。唯一例外：用户裁决推翻某条既定决策时，`/analyze-new-ideas` 直接改写那份 ADR（改写既有决定，不新增编号）。

**台账绝不领先于事实。** 一条决策只有在**已经写进权威主题文档**（`vision/` · `contracts/` · `systems/` · `operations/`）之后才建 ADR。ADR 是它的索引与理由留档，不是它的替代品 —— 细节留在主题文档，ADR 里**回链而非复述**（与 `game-design-documents/decisions/ADR-0005-knowledge-thin-reference-layer.md` 的副本判据同源）。

## ADR 形状

```markdown
# ADR-0001 — <决策标题>

- **状态：** Accepted
- **日期：** <YYYY-MM-DD>
- **来源：** handoffs/<id>.md

## 背景
<什么问题迫使我们做这个选择。>

## 决策
<我们选了什么。写成祈使句，含关键取值。>

## 理由
<为什么是它，而不是备选。引用主题文档的承重论证，不新造理由。>

## 备选方案
- <方案> — 否决理由。

## 后果
<它约束了什么、放弃了什么、哪些文档因此必须这么写。跨库的后果写全路径。>
```

## 已对后端构成约束的客户端决定

除上表本库自己的 ADR 外，下列客户端侧决定也限定了后端的设计空间：

| 客户端 ADR | 对后端的约束 |
|---|---|
| `game-design-documents/decisions/ADR-0003-online-cloud-authority.md` | 强制在线 · 云端权威 · 重账号（已删游客态）。后端必须承载账号、权威存档与冲突裁决。 |
| `game-design-documents/decisions/ADR-0004-realm-checkpoint-retry-model.md` | 境界存档 · 篇章重试模型 ⇒ 自动存档点频率与上行节奏的下界。 |
| 剧本内容属客户端本地内容层（**客户端侧 ADR 候选**，见 `game-design-documents/handoffs/2026-08-11-plot-content-localization.md`） | **撤销一整条边界**：后端无剧本服务、无剧本契约、无 `/v1/plot/…` 端点；剧本文本改由 `content-manifest.md` 通道以普通内容文件承接。跨边界的客户端成分共三个。本库侧落地见 `handoffs/2026-08-11-plot-service-retired.md`。 |
