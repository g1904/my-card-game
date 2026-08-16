---
type: solution-draft
date: 2026-08-14
question: `openapi.yaml` / `schemas/*.json` 何时落笔，以及 markdown 字段表与 spec 的一致性由谁在什么时机核对？
source: open-questions/01-contracts.md → 第 5 条「`openapi.yaml` / `schemas/*.json` 尚未落笔」
targets: contracts/envelope.md §1、contracts/_index.md（## 约定）、operations/_index.md（错误码台账登记流程一段）、contracts/profile-sync.md §6（向量数值权威回链）
status: distilled
decided: 2026-08-14（用户裁决：形态收到 spec 单点；其余按推荐定案）
reviewed: 2026-08-14（/analyze-new-ideas interview 两项：① 字段表瘦身范围 → **随 spec 覆盖面逐步瘦身**，推翻本稿第 2 条「四份同批完成」的措辞；② CDN 域端点 → **进 `openapi.yaml` 的 `paths`，以 `contentRoot` 为独立 server**，断言③ 措辞随之放宽）
distilled-to: handoffs/2026-08-14-openapi-spec-timing-and-consistency.md
---

# 方案 — spec 的落笔时机与 markdown ↔ spec 的一致性核对

> **本文件已定案**，等待 `/analyze-new-ideas` 提炼进上方 `targets` 所列文档并移出 `open-questions/01-contracts.md` 第 5 条。
> 全部条款为已裁决内容，不再是提案。余下的两处留白（见文末）是**工程承载**，不是设计未决。

## 问题

`envelope.md` §1 已定契约的表达形式（OpenAPI 3.1 + JSON Schema 单点，落点 `contracts/openapi.yaml` + `contracts/schemas/*.json`），也已定 **markdown 承载语义、spec 承载形态**，冲突时**字段形态以 spec 为准、语义以 markdown 为准**。但三件事悬着：

1. **触发点的措辞含糊。** 定案是「首个端点进入实现时同时落地」——没说**哪一侧**的实现（客户端已开工、后端栈未定，后端很可能不是先动的那一侧），也没说是**一次性全量**落还是**逐端点增量**落。
2. **一致性核对方式未定。** 冲突裁决规则已定，但「谁在什么时机核对」未定——而裁决规则只在**发现**冲突后才起作用，发现机制才是缺的那一环。
3. **这是 `contracts/` 齐备后的最后一项结构性欠账**（`open-questions.md` 当前焦点第 3 条）。四份契约的 markdown 已经密集地写满字段表，spec 一旦落笔，同一份形态就有了两处真值——而本库对「两份真值」的态度在别处已经非常明确（`envelope.md` §8 拒绝把 Profile schema 抄进契约、`profile-sync.md` §7 拒绝把平衡分档表复制到后端，理由都是「第二份真值 + 必然漂移」）。

## 约束（来自既有设计）

- **表达形式已封定**：OpenAPI 3.1（JSON Schema 2020-12 方言）+ 拆分的 `schemas/*.json`，明确否决共享 DTO 代码。→ `envelope.md` §1、`decisions/_index.md` ADR 候选③。
- **代码生成不强制**：两侧可生成也可手写 DTO，契约不规定实现手段。→ `envelope.md` §1。
- **先有设计再建文件、不预先建空壳**。→ `README.md`「维护约定」。
- **只保留最新契约，历史归 git；兼容性靠版本化字段，不靠在文档里留旧形态**。→ `contracts/_index.md`「约定」。
- **契约变更是跨库事件**：两侧各写一份 handoff 并互相回链。→ 同上、pillar #3。
- **新增 / 变更 `code` 必须先改 `envelope.md` §6 台账、再改服务端实现**——已存在的「文档先于实现」流程先例。→ `operations/_index.md`。
- **Profile 的字段表不得抄进本库**（后端对 Profile 半透明，其结构权威在客户端）。→ `envelope.md` §8。
- **透明字段的 JSON path 本身是契约的一部分**，移动 / 重命名 = 破坏性变更。→ `profile-sync.md` §5。
- **后端技术栈未定**，本方案不指定语言 / 框架 / 库。→ `.claude/rules/design-library-routing.md`。

## 定案

### 1. 触发点 = **任一侧**的首个端点进入实现；首落范围 = **全部共有层 + 该一个端点**

现行措辞「首个端点进入实现时」在两侧节奏不同的现实下会失效：客户端已开工、后端栈未定，`HttpProfileBackend` 很可能先于任何后端服务写出真实请求。若把触发点绑在后端实现上，客户端会在**没有 spec** 的情况下按 markdown 草案编码——而 markdown 明确不是形态的权威。

- **触发点 = 任一侧的首个端点进入实现**（哪一侧先动都算），由**动手的那一侧**发起落笔，另一侧在同一次跨库 handoff 中确认。
- **首次落笔范围 = 全部共有层 + 该一个端点**；其余端点路径在各自进入实现时逐个追加。

「共有层一次性落全」不是例外而是必然：`envelope.md` 的错误体、错误码台账、四个请求头 / 五个应答头、`class` 枚举、序列化约定，**没有一条是某个端点独有的**——第一个端点要在 spec 里成立就必须把它们全带上。端点路径彼此独立，逐个追加符合「不预先建空壳」。

### 2. 形态收到 spec 单点：markdown 字段表删除规范性形态列（承重）

**spec 落笔后，markdown 契约文档中的字段表不再承载规范性形态列（类型 / 必填 / 枚举取值），降级为「字段名 + 语义 / 用途 / 承重纪律」；形态由 spec 单点承载。示例报文 JSON 保留**——它是说明性的，不是规范性的：读者靠它建立直觉，工具靠 spec 建立约束。

依据是本库自己的判据。`envelope.md` §8 拒绝把 Profile schema 抄进契约、`profile-sync.md` §7 拒绝把平衡分档表复制到后端，理由**逐字相同**：第二份真值 + 必然漂移。markdown 字段表与 spec 的关系正是同一个模式——只是这一次两份真值都在本库内，反而更容易被默认为「顺手同步一下就好」。而契约文档是**两侧唯一的耦合点**，它漂移的代价高于上述任何一处。

**代价（已接受）：** markdown 单独读时不再自足，读者需跳到 spec 才知道某字段的类型与必填性。缓解是保留示例报文（形状仍有直觉），且类型是查一次就够的信息、语义才是反复读的。

**连带的一次性改动：** 四份契约 markdown 的字段表瘦身**必须与首次 spec 落笔同批完成**——中途状态就是两份真值，正是本条要消除的东西。

### 3. 三条可机检断言 + 一份人工检查清单

即使形态收到单点，markdown 与 spec 之间仍有**必然重叠的三处标识符**——它们是键，不是形态，无法只留一处（markdown 讲不清语义就没有存在意义）。三处恰好都机器可提取：

| # | 断言 | 提取方式 | 漂移后果 |
|---|---|---|---|
| ① | spec 自身合法（OpenAPI 3.1 + 全部 `$ref` 可解析） | 任一 OpenAPI 3.1 校验器 | 两侧工具链读不了契约 |
| ② | `envelope.md` §6 台账的每个 `code` ⇔ spec 中错误码枚举的每个取值，**双向且一一对应** | markdown 表格首列 vs spec 枚举 | 客户端映射表漏一条 → 该错误走「未知 `code` 按 `class` 降级」，静默走错处置分支 |
| ③ | markdown 中出现的每个 `METHOD /v1/…` ⇔ spec 的 `paths` 键，**双向** | 正则 vs `paths` | 端点集与契约不符 |

②是投入产出比最高的一条：错误码台账是全库**最容易漏项**的表（15 条且仍在增长，`compliance.*` 清单待 `02` 补入），而它的漂移形态恰好是**静默**的——客户端对未知 `code` 有兜底，因此漏登记不会报错，只会让某条错误一直走降级路径。

**不可机检的部分走人工检查清单**（落 `contracts/_index.md` 的「约定」段，作为契约变更的完成判据）：

- `detail` 的形状与 `message` 必含项（台账后两列）——语义约束，spec 只能表达 `detail` 是个对象。
- 承重纪律段落是否随形态变更而失效（典型：`profile-sync.md` §5 的 JSON path 白名单、§6 的 `stream` 取值冻结）。
- 该次变更是否需要 bump `schemaVersion` / URL 主版本，以及**另一侧的 handoff 是否已写**（pillar #3 已定契约变更是跨库事件，此处把它变成可勾选项）。

### 4. 核对时机 = 变更内原子，不设周期性对账

**spec 与 markdown 在同一次契约变更内同批更新；只改了一边的变更视为未完成。** 不设「每月 / 每里程碑对账一次」之类的周期性任务。

依据是 `operations/_index.md` 已立的先例：新增 / 变更 `code` **须先改台账、再改服务端实现**，不允许实现先跑在文档前面。本条是同一条纪律往前挪一格——文档内部的两处表达也不允许彼此落后。周期性对账的问题在于它**允许漂移存在一段时间**，而契约漂移的窗口期正是两侧按不同真值编码的窗口期。

**责任人 = 发起该次契约变更的那一侧**（谁改谁负责补齐两处 + 写跨库 handoff）；机检承担①②③，人工清单承担其余。

### 5. `schemas/*.json` 的拆分判据与首批文件

**判据：被两个及以上端点引用的类型进 `schemas/`，端点独有的内联在 `openapi.yaml` 里。** 不一开始就把每个 request / response body 拆成一个文件——那会造出一堆只被引用一次的文件，`$ref` 跳转成本高于收益。

按当前四份契约，首批拆出的只有这几个：

| 文件 | 承载 | 来源 |
|---|---|---|
| `schemas/error.json` | 错误体（`code` / `class` / `message` / `detail` / `requestId`），含 `class` 四值枚举与 `code` 全量枚举 | `envelope.md` §5 §6 |
| `schemas/profile-visible-subset.json` | 后端可见字段子集的逐 path 约束（见第 6 条） | `profile-sync.md` §5 |
| `schemas/session.json` | 双 token 对（access + refresh + 过期时间） | `auth.md` §2 §8 |
| `schemas/manifest.json` | manifest schema（`manifestSchema: 1`） | `content-manifest.md` |

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

## 具体形态（可 derive 的落地面）

**`contracts/` 落笔后的目录形态：**

```
contracts/
  _index.md
  envelope.md            语义 · 承重纪律 · 错误码台账（含 detail 形状与 message 必含项）
  auth.md                语义 · 端点用途 · 示例报文
  profile-sync.md        语义 · CAS/幂等/复算协议 · 白名单 path 的理由
  content-manifest.md    语义 · 三版本号分工 · 签名与 flags
  openapi.yaml           ← 形态单点：paths · parameters · headers · 内联 schema
  schemas/
    error.json
    profile-visible-subset.json
    session.json
    manifest.json
  vectors/
    splitmix64.json      ← 测试向量数值的权威（第 7 条）
```

**契约变更的完成判据（并入 `contracts/_index.md` 的「约定」段）：**

一次契约变更**未完成**，除非以下全部为真：

1. markdown 的语义 / 理由 / 承重纪律已更新；
2. `openapi.yaml`（及涉及的 `schemas/*.json`）的形态已在**同一次变更内**更新；
3. 若涉及新增 / 变更 `code`：`envelope.md` §6 台账已登记 `class` · `OpError` · 客户端处置 · `detail` 形状 · `message` 必含项五列；
4. 三条机检断言通过（①spec 合法 ②`code` 双向一一对应 ③端点集双向一致）；
5. 人工清单四项已过（`detail` 形状 / `message` 必含项 / 承重纪律是否失效 / 是否需 bump 版本）；
6. 另一侧的跨库 handoff 已写并互相回链。

**`envelope.md` §1 的两行改写：**

| 项 | 改写后 |
|---|---|
| **markdown ↔ spec 分工** | **markdown 承载语义、理由与承重纪律；spec 单点承载字段名、类型、必填性、枚举值。**markdown 中的形态性文字（示例报文等）**均为说明性，不具规范性**。冲突裁决规则保留为兜底：字段形态以 spec 为准，语义以 markdown 为准 |
| **落地时机** | 不预先建空壳。**任一侧**（客户端或后端）的首个端点进入实现时，由动手的那一侧落 `openapi.yaml`，范围 = **全部共有层 + 该端点**；其余端点路径在各自进入实现时逐个追加。落笔同批完成四份 markdown 的字段表瘦身。在某端点的 spec 落笔前，其 markdown 字段表视为草案 |

## 后果

- **`contracts/envelope.md` §1** 改写上表两行。
- **`contracts/_index.md`** 的「约定」段新增「契约变更的完成判据」六条与人工检查清单。
- **`contracts/` 四份 markdown** 在 spec 落笔时做一次**字段表瘦身**（一次性批量改动，与首次 spec 落笔同批）。
- **`contracts/profile-sync.md` §6** 补一句「向量数值的权威在 `vectors/splitmix64.json`，markdown 表格为人类可读对照」。
- **`operations/_index.md`** 的「错误码台账的登记流程」一段补入断言②，使该段从「先文档后实现」扩展为「先文档后 spec 后实现」。
- **不影响任何已定报文形状**，不需要 bump `schemaVersion` 或 URL 主版本——全部是文档工程层面的约定。
- **机检的承载位置待定**（见「留白」）：若设计库暂无自动化承载，三条断言退化为人工清单的前三项，其余条款不受影响。

## 备选方案（已考虑并否决）

- **保留双份形态 + 只加三条弱断言机检** — 形态仍有两份真值，且字段级漂移（类型改了、必填变了）机检**测不到**，只能靠人工。它保留的正是本库前两次裁决（`envelope.md` §8、`profile-sync.md` §7）所拒绝的东西，且代价不可缓解。
- **保留双份形态 + 全量逐字段机检** — 需要一个把 markdown 表格解析成 schema 的解析器，等于自造一套更弱的 schema 语言；解析器本身会成为新的失败点。
- **spec 单点、markdown 由 spec 自动生成** — 生成出的文档只能承载 spec 里有的东西（字段 + description），而本库 markdown 的价值恰恰是 spec **表达不了**的部分：承重纪律、否决过的备选方案、「为什么传输信封走头而非 body」这类论证。生成会把它们碾平。
- **markdown 单点、spec 由 markdown 生成** — 需给 markdown 表格定一套严格语法（即上上条的问题）；且已定案是「字段形态以 spec 为准」。
- **周期性对账（每月 / 每个里程碑核对一次）** — 允许漂移窗口存在，而窗口期正是两侧按不同真值编码的时期。与 `operations/_index.md` 已立的「先文档后实现」纪律不同向。
- **首次落笔即全量四份契约进 spec** — 违反「先有设计再建文件、不预先建空壳」：`compliance.*` 码清单、`reasonKey` 取值集合、`bundleGrantOrdinal` 白名单行都还待 `02` / 客户端，全量落会在 spec 里留下一批 `TODO` 枚举，而枚举缺项恰恰是最不该被写成占位的东西。
- **把 Profile 的完整 schema 写进 `schemas/`** — 直接违反 `envelope.md` §8 与 pillar #1；Profile 的结构权威在客户端。
- **把 SplitMix64 向量表只留在 markdown** — 两侧测试各抄一份，漂移即静默作弊窗口，而这张表是该条纪律**唯一**的可执行检查点。

## 与既有决策的张力

**一处收紧，不构成推翻。** `envelope.md` §1 已定「冲突时字段形态以 spec 为准，语义以 markdown 为准」——该措辞预设了两份形态并存并可能冲突。第 2 条把形态收到 spec 单点后，该规则不再是日常依赖，降为防手滑的兜底。

**处置：规则原样保留不删**（markdown 里难免残留形态性描述，规则仍需在），在 §1 补一句「markdown 的形态性文字均为说明性，不具规范性」——见上方改写表。

其余无张力：不改任何报文形状、不动 ADR 候选③、不与四份契约的任何承重纪律相抵。

## 前置依赖

- **`06-platform-stack.md`（技术栈 · 托管 · 运维）** —— 只挡三条机检断言的**承载位置**（设计库有没有自动化流水线、跑在哪里），不挡其余任何一条。断言本身与后端栈无关（校验的是 markdown 与 YAML / JSON，不是后端代码）。**已定不等 `06`**：先把六条完成判据与人工清单写进 `contracts/_index.md`，承载位置落定后再把前三项从人工提升为自动。
- **首个端点进入实现** —— spec 的实际落笔仍以此为触发点。本方案定的是**规则**，不是现在就落 spec；规则先定的价值在于触发点到来时不必再讨论一次，且第 2 条的字段表瘦身必须与首次落笔同批。
- **不依赖 `02`** —— `compliance.*` 码清单与 `reasonKey` 取值集合待 `02`，但它们进的是 spec 的枚举取值，属「该端点落笔时填」，不挡规则定案。

## 留白（工程承载，非设计未决）

- **三条机检断言的承载位置** —— 设计库侧的自动化流水线是否存在、跑在哪里，随 `06` 落定。在此之前三条以人工清单形式执行。
- **具体校验工具不点名** —— 属工程选型，与「后端栈未定前不指定语言 / 框架 / 库」的纪律同向。只立能力要求：**能校验 OpenAPI 3.1 / JSON Schema 2020-12，且能在设计库侧运行**。
