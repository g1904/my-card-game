# spec 的落笔时机与 markdown ↔ spec 的一致性核对

- id: 2026-08-14-openapi-spec-timing-and-consistency
- date: 2026-08-14
- topic: contracts/envelope（§1 两行改写）· contracts/_index（约定：完成判据 + 人工清单 + 目录形态）· contracts/profile-sync（§6 向量数值权威）· operations（错误码台账登记流程扩展）
- status: distilled
- distilled-to: `contracts/envelope.md`、`contracts/_index.md`、`contracts/profile-sync.md`、`operations/_index.md`、`open-questions/01-contracts.md`、`open-questions.md`、`answer-logs/log-openapi-spec-timing-and-consistency.md`

## Intent（distilled）

**一句话：** `openapi.yaml` 由**任一侧**的首个端点进入实现时触发落笔（首落 = 全部共有层 + 该一个端点）；同时**把形态收到 spec 单点**——markdown 字段表随 spec 覆盖面逐步删除规范性形态列；一致性靠**变更内原子** + 三条机检断言 + 一份人工清单来保证，不设周期性对账。

`envelope.md` §1 已定表达形式（OpenAPI 3.1 + JSON Schema 单点，落点 `contracts/openapi.yaml` + `contracts/schemas/*.json`）与冲突裁决规则（形态以 spec 为准、语义以 markdown 为准）。悬着的是三件事：触发点的措辞含糊（没说哪一侧、也没说全量还是增量）、一致性的**发现机制**未定（裁决规则只在发现冲突后才起作用）、以及四份契约的 markdown 已写满字段表，spec 一旦落笔同一份形态就有两处真值。本次把这三件一并定死。

### 1. 触发点 = 任一侧的首个端点进入实现；首落范围 = 全部共有层 + 该一个端点

「首个端点进入实现时」在两侧节奏不同的现实下会失效：客户端已开工、后端栈未定，`HttpProfileBackend` 很可能先于任何后端服务写出真实请求。若把触发点绑在后端实现上，客户端会在**没有 spec** 的情况下按 markdown 草案编码——而 markdown 明确不是形态的权威。

- **触发点 = 任一侧的首个端点进入实现**（哪一侧先动都算），由**动手的那一侧**发起落笔（即使动手方是客户端，spec 仍落本库 `contracts/`），另一侧在同一次跨库 handoff 中确认。
- **首次落笔范围 = 全部共有层 + 该一个端点**；其余端点路径在各自进入实现时逐个追加。

「共有层一次性落全」不是例外而是必然：`envelope.md` 的错误体、错误码台账、四个请求头 / 五个应答头、`class` 枚举、序列化约定，**没有一条是某个端点独有的**——第一个端点要在 spec 里成立就必须把它们全带上。端点路径彼此独立，逐个追加符合「不预先建空壳」。

### 2. 形态收到 spec 单点：markdown 字段表随 spec 覆盖面逐步删除规范性形态列（承重）

**某端点的形态一旦进入 spec，其 markdown 字段表即删除规范性形态列（类型 / 必填 / 枚举取值），降级为「字段名 + 语义 / 用途 / 承重纪律」。示例报文 JSON 保留**——它是说明性的，不是规范性的：读者靠它建立直觉，工具靠 spec 建立约束。

依据是本库自己的判据。`envelope.md` §8 拒绝把 Profile schema 抄进契约、`profile-sync.md` §7 拒绝把平衡分档表复制到后端，理由**逐字相同**：第二份真值 + 必然漂移。markdown 字段表与 spec 的关系正是同一个模式——只是这一次两份真值都在本库内，反而更容易被默认为「顺手同步一下就好」。而契约文档是**两侧唯一的耦合点**，它漂移的代价高于上述任何一处。

**瘦身范围随 spec 覆盖面推进，不一次性做完四份**（见下方 Clarifications ①）：首落时只瘦身共有层与该端点的字段表，其余端点的 markdown 字段表**保留为草案**，各自 spec 落笔时同批瘦身。任何时刻**形态都只有一处权威**——已进 spec 的在 spec，未进的在 markdown 草案。过渡期四份 markdown 风格不齐（有的有类型列、有的没有）是**预期状态**，`contracts/_index.md` 须写明这一点，避免被当作漏改。

**代价（已接受）：** 瘦身后的 markdown 单独读时不再自足，读者需跳到 spec 才知道某字段的类型与必填性。缓解是保留示例报文（形状仍有直觉），且类型是查一次就够的信息、语义才是反复读的。

### 3. 三条可机检断言 + 一份人工检查清单

即使形态收到单点，markdown 与 spec 之间仍有**必然重叠的三处标识符**——它们是键，不是形态，无法只留一处（markdown 讲不清语义就没有存在意义）。三处恰好都机器可提取：

| # | 断言 | 提取方式 | 漂移后果 |
|---|---|---|---|
| ① | spec 自身合法（OpenAPI 3.1 + 全部 `$ref` 可解析） | 任一 OpenAPI 3.1 校验器 | 两侧工具链读不了契约 |
| ② | `envelope.md` §6 台账的每个 `code` ⇔ spec 中错误码枚举的每个取值，**双向且一一对应** | markdown 表格首列 vs spec 枚举 | 客户端映射表漏一条 → 该错误走「未知 `code` 按 `class` 降级」，静默走错处置分支 |
| ③ | markdown 中出现的每个 `METHOD 路径` ⇔ spec 的 `paths` 键，**双向**（含 CDN 域三端点，见 Clarifications ②） | 正则 vs `paths` | 端点集与契约不符 |

②是投入产出比最高的一条：错误码台账是全库**最容易漏项**的表（且仍在增长，`compliance.*` 清单待 `02` 补入），而它的漂移形态恰好是**静默**的——客户端对未知 `code` 有兜底，因此漏登记不会报错，只会让某条错误一直走降级路径。

**断言②的基准是台账当前登记的条目**：`compliance.*` 的具体码清单与 `reasonKey` 取值集合尚未进台账（待 `02`），因此它们不构成「spec 漏项」——断言校验的是两处**已有内容**的双向覆盖，不是对未定内容的完备性要求。

**不可机检的部分走人工检查清单**（落 `contracts/_index.md` 的「约定」段，作为契约变更的完成判据）：

- `detail` 的形状与 `message` 必含项（台账后两列）——语义约束，spec 只能表达 `detail` 是个对象。
- 承重纪律段落是否随形态变更而失效（典型：`profile-sync.md` §5 的 JSON path 白名单、§6 的 `stream` 取值冻结）。
- 该次变更是否需要 bump `schemaVersion` / URL 主版本，以及**另一侧的 handoff 是否已写**（契约变更是跨库事件，此处把它变成可勾选项）。

### 4. 核对时机 = 变更内原子，不设周期性对账

**spec 与 markdown 在同一次契约变更内同批更新；只改了一边的变更视为未完成。** 不设「每月 / 每里程碑对账一次」之类的周期性任务。

依据是 `operations/_index.md` 已立的先例：新增 / 变更 `code` **须先改台账、再改服务端实现**，不允许实现先跑在文档前面。本条是同一条纪律往前挪一格——文档内部的两处表达也不允许彼此落后。周期性对账的问题在于它**允许漂移存在一段时间**，而契约漂移的窗口期正是两侧按不同真值编码的窗口期。

**责任人 = 发起该次契约变更的那一侧**（谁改谁负责补齐两处 + 写跨库 handoff）；机检承担①②③，人工清单承担其余。

### 5. `schemas/*.json` 的拆分判据与首批文件

**判据（两条并列，满足其一即独立成文件）：**

1. 被**两个及以上端点**引用的类型；
2. 该类型是**独立可被签名 / 校验的产物**，两侧需要脱离 spec 单独引用它。

端点独有且不满足以上两条的类型，内联在 `openapi.yaml` 里——不一开始就把每个 request / response body 拆成一个文件，那会造出一堆只被引用一次的文件，`$ref` 跳转成本高于收益。

第 2 条判据存在的理由是 manifest：它是 ES256 detached 签名覆盖的**原始字节**，客户端在校验签名后要按 schema 独立校验它，而这条校验链并不经过 spec 的请求 / 应答路径（`content-manifest.md` 的端点表 + 发布顺序）。

按当前四份契约，首批拆出的只有这几个：

| 文件 | 承载 | 来源 | 依判据 |
|---|---|---|---|
| `schemas/error.json` | 错误体（`code` / `class` / `message` / `detail` / `requestId`），含 `class` 四值枚举与 `code` 全量枚举 | `envelope.md` §5 §6 | ① |
| `schemas/profile-visible-subset.json` | 后端可见字段子集的逐 path 约束（见第 6 条） | `profile-sync.md` §5 | ① |
| `schemas/session.json` | 双 token 对（access + refresh + 过期时间） | `auth.md` §2 §8 | ① |
| `schemas/manifest.json` | manifest schema（`manifestSchema: 1`） | `content-manifest.md` | ② |

请求头 / 应答头**不进 `schemas/`**——它们是 `components/parameters` 与 `components/headers`，不是 schema。

### 6. `profile-visible-subset.json` 是**部分 schema**，不是 Profile 的 schema

这是 spec 落笔时最容易出错的一处，形态先写死。`envelope.md` §8 禁止把 Profile 字段表抄进本库，而 `profile-sync.md` §5 又要求透明子集的 **JSON path 是契约的一部分**——两条看似冲突，收口方式是：

**该 schema 只列白名单里的那几条 path，`additionalProperties: true`，且透明字段一律非必填。** 它约束的是「若这些 path 存在，则形态必须如此」，而**不**声明 Profile 由哪些字段构成。

三条纪律必须在 spec 里成立：

- `additionalProperties: true` —— 不透明段照常通过，兑现「后端不得对不透明段做结构校验」（`envelope.md` §8）。
- **透明字段全部非必填** —— push 上行是**顶层键粒度的浅合并 diff**（`profile-sync.md` §3a），一次 diff 里绝大多数透明 path 本就不出现；标成必填会把正常的 diff 判成 `sync.payload_invalid`。
- **缺失的透明 path 走告警级台账，不走 schema 校验失败** —— `profile-sync.md` §5 已定「不拒绝上行」，因此这条检测**不能**由 spec 承担，必须留在服务端逻辑里。spec 中须为此写一条注释，否则实现者极易顺手把它标成必填。

### 7. SplitMix64 测试向量另落机器可读文件

`profile-sync.md` §6 定「测试向量表是本契约的验收物、是这条纪律唯一可执行的检查点」，但 markdown 表格要被两侧的测试消费就得各抄一份进各自的测试代码——又是两份真值，且**这一份的漂移直接等于作弊窗口**。

**向量表在填值时同批落 `contracts/vectors/splitmix64.json`（8 组，字段与 §6 表格一一对应），两侧测试直接读该文件；markdown 表格保留为人类可读的对照，并标注「数值权威在 `vectors/splitmix64.json`」。**

它不属于 OpenAPI spec（不是报文形态），因此单开 `vectors/` 而非塞进 `schemas/`。本条与向量数值本身无关——**数值仍待两侧首次实现 SplitMix64 时同批填入并逐位复核**（`01-contracts.md` 的独立待答项），此处只定它落在哪、由谁读。

### 8. `info.version` 与 `/v1/`、`schemaVersion` 三者互不复用

`envelope.md` §3 已定「URL 主版本与 `schemaVersion` 不复用一个数字，因为变更节奏完全不同」。spec 自身的 `info.version` 是**第三个**节奏（每次契约文档变更都动）：

- `info.version` = 契约文档的发布版本，semver；报文形态的破坏性变更 bump major，新增可选字段 / 新增端点 bump minor，纯描述修订 bump patch。
- 它**与 `/v1/` 无关**，也**与 `schemaVersion` 无关**；三者的分工在 spec 顶部注释里显式声明，避免实现者把 `info.version` 当成 URL 版本。

### 落笔后的 `contracts/` 目录形态

```
contracts/
  _index.md
  envelope.md            语义 · 承重纪律 · 错误码台账（含 detail 形状与 message 必含项）
  auth.md                语义 · 端点用途 · 示例报文
  profile-sync.md        语义 · CAS/幂等/复算协议 · 白名单 path 的理由
  content-manifest.md    语义 · 三版本号分工 · 签名与 flags
  openapi.yaml           ← 形态单点：paths（API 域 + CDN 域两个 server）· parameters · headers · 内联 schema
  schemas/
    error.json
    profile-visible-subset.json
    session.json
    manifest.json
  vectors/
    splitmix64.json      ← 测试向量数值的权威（第 7 条）
```

## Clarifications（interview 产物）

- **① markdown 字段表的瘦身范围** —— 原始草稿第 2 条写「四份契约 markdown 的字段表瘦身**必须与首次 spec 落笔同批完成**」，与同一份草稿给出的 `envelope.md` §1 改写表「在某端点的 spec 落笔前，其 markdown 字段表视为草案」直接互斥：首落范围只有「共有层 + 一个端点」，四份全瘦身会让尚未进 spec 的三个端点的形态**无处承载**。
  → **用户裁定：随 spec 覆盖面逐步瘦身。** 已进 spec 的瘦身、未进的保留为草案，各自落笔时同批瘦身；过渡期四份风格不齐是预期状态，写进 `contracts/_index.md`。本裁定**推翻了草稿第 2 条「同批完成」的措辞**，保留其「形态只有一处真值」的实质。

- **② CDN 域端点是否进 `openapi.yaml` 的 `paths`** —— 草稿把 `schemas/manifest.json` 列进首批，判据却是「被两个及以上端点引用」；而 `content-manifest.md` 的端点表显示 manifest 走的是 **CDN 域**（`<contentRoot>/manifest`、`manifest.sig`、`/blobs/<sha256>`，无鉴权、不在 `/v1/` 下），草稿未说这三个端点是否进 spec。断言③ 的原措辞也只写了 `METHOD /v1/…`。
  → **用户裁定：进 `paths`，以 `contentRoot` 为独立 server。** 依据：契约的价值是「两侧都从它派生」，CDN 端点同样是客户端要发的请求；排除它们会让那一侧的端点集漂移完全无检测。连带两处改动：断言③ 措辞放宽为「每个 `METHOD 路径` ⇔ spec `paths`，双向」，覆盖 CDN 端点集；spec 需处理两个 server 域与「CDN 域无鉴权」的安全声明差异。

- **③ `schemas/` 判据补第二条并列款（本库校验推演，非草稿原文）** —— 即使 CDN 端点进 `paths`，`manifest.json` 仍只被**一个** path 引用，不满足草稿的「两个及以上端点」判据。收口方式不是给 manifest 开例外，而是把判据写成两条并列款，第二条为「独立可被签名 / 校验、需脱离 spec 单独引用的产物」——依据是 `content-manifest.md` 已定的 ES256 detached 签名覆盖原始字节、客户端需独立校验 manifest 这条既有设计。

## Open questions

- **三条机检断言的承载位置** —— 设计库侧是否存在自动化流水线、跑在哪里，随 `06-platform-stack.md` 落定。在此之前三条以人工清单的前三项形式执行；**已定不等 `06`**：完成判据与人工清单先写进 `contracts/_index.md`，承载位置落定后再把前三项从人工提升为自动。
- **具体校验工具不点名** —— 属工程选型，与「后端栈未定前不指定语言 / 框架 / 库」同向。只立能力要求：**能校验 OpenAPI 3.1 / JSON Schema 2020-12，且能在设计库侧运行**。

## Notes / triage

- 与既有决策的关系：**一处收紧，不构成推翻。** `envelope.md` §1 的「冲突时字段形态以 spec 为准」预设了两份形态并存并可能冲突；形态收到单点后，该规则不再是日常依赖，降为防手滑的兜底。**规则原样保留不删**（markdown 里难免残留形态性描述），另补一句「markdown 的形态性文字均为说明性，不具规范性」。
- **不影响任何已定报文形状**，不需 bump `schemaVersion` 或 URL 主版本——全部是文档工程层面的约定。不动 ADR 候选③（契约表达形式 = OpenAPI 3.1 单点），本次是它的落地细则而非改动。
- 已否决的备选（理由见草稿 `inbox/archive/solution-draft-openapi-spec-timing-and-consistency.md`）：保留双份形态 + 弱 / 全量机检 · markdown 由 spec 生成 · spec 由 markdown 生成 · 周期性对账 · 首落即全量四份进 spec · 把 Profile 完整 schema 写进 `schemas/` · 向量表只留 markdown。
- 前置：**首个端点进入实现**是 spec 实际落笔的触发点；本 handoff 定的是**规则**，不是现在就落 spec。规则先定的价值在于触发点到来时不必再讨论一次。不依赖 `02`——`compliance.*` 码清单与 `reasonKey` 取值进的是 spec 枚举取值，属「该端点落笔时填」。

## 客户端侧影响

**改动的是文档工程约定，不改动客户端 ↔ 后端边界的任何报文语义**——不需要客户端侧另写一份 handoff 来承接语义。

但有**一条跨库操作约定**需要客户端侧知晓（涉及 `sync-service` / `account-service` / `content-service` 三个跨边界成分的实现启动时点）：若客户端先于后端进入某端点的实现（`HttpProfileBackend` 是最可能的第一处），**由客户端侧发起 `backend-design-documents/contracts/openapi.yaml` 的落笔**，并在同一次跨库 handoff 中由后端侧确认。这意味着客户端的第一次真实请求实现**不是**「按 markdown 草案编码」，而是「先落 spec、再按 spec 编码」。
