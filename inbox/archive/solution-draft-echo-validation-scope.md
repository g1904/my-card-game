---
type: solution-draft
date: 2026-08-22
question: 上行整键回声校验的适用面未穷举 —— 后端在哪些 JSON path 上执行回声校验、如何比较、拒绝清单如何登记
source: game-design-documents/open-questions/05-service-contracts.md → 「上行整键回声校验的适用面未穷举（08-19 新增 · 承重）」（客户端库待答项，跨边界承接）
targets: contracts/profile-sync.md（§4 拒绝清单 · §5 白名单与后端写入封闭表 · 新增回声校验通则一节）
counterpart: game-design-documents/inbox/solution-draft-echo-validation-scope.md
status: distilled
distilled-to: handoffs/2026-08-23c-echo-validation-scope.md
reviewed: 2026-08-22 — 三项取向经批量评审全部裁决（`createdAtUtc` 按时刻相等 · `identities` 有序逐元素相等 · 接受「受约束键内追加字段 = 两侧同批」刚性）。**前两项系 `[采纳推荐 — 待复核]`**：按 `.claude/rules/batch-orchestration.md` 铁律①，采纳推荐不等于用户拍板，**提炼落笔前须先由用户确认这两项比较口径**。第三项与 `counterpart` 同项同裁，无待复核。**⚠ 与 `counterpart` 成对采纳，客户端半已于 08-22 落笔（`game-design-documents/handoffs/2026-08-22-echo-validation-scope-client-half.md`），本侧未落 ⇒ 成对采纳尚未完成**
---

# 方案草稿 — 上行整键回声校验的适用面（后端侧）

> **本文件只写后端这一半**：受回声校验约束的 JSON path 封闭清单、比较口径、拒绝语义与其在拒绝清单中的登记、扩表时的自动连带。
> **客户端如何组装 diff、回声值取自哪里、push 前自检、老档补默认值的例外 → 见 `counterpart`，本文件不复述。**
> 技术栈未定 ⇒ 全文停在协议与语义层，不指定语言 / 框架 / 存储实现。

## 问题

`inbox/solution-draft-bundle-grant-ordinal-authority.md`（status `decided`，Q1 取 A）已裁决新增回声校验，措辞是：

> 凡 `playerDiff` 含顶层键 `entitlement`：其中 `bundleGrantOrdinal` 必须与当前云端值逐位相同，否则整批拒绝，回 `sync.conflict`，`detail.field` 给该 JSON path，并打一条风控事件。

该草稿的「越界发现」同时点出：`/accountInfo` 是**第二处同形**（含后端写的 `accountSeed` / `createdAtUtc` / `identities` 与客户端写的 `nickname`），需逐条登记哪些路径受约束。悬着的正是这一份**封闭清单**与两件它带出来的事：

1. **比较口径未定。** `bundleGrantOrdinal` 是 `int`，「逐位相同」无歧义；但 `identities` 是**数组**、`createdAtUtc` 是**时间串**、`accountSeed` 是 **hex 串**——「相同」是指解析后的语义相等，还是原始字节相等？选错会让**正常客户端**被整批拒绝，而整批拒绝在客户端侧的既定处置是丢弃本地缓冲 = 丢玩家进度。
2. **拒绝清单未扩。** 该草稿已明写「§4 的『后端何时拒绝上行』清单由两类变三类，须同批登记」，但清单本体尚未改。

**并且：回声校验规则本身尚未进 `contracts/profile-sync.md`**——它目前只存在于那份已裁决的 inbox 草稿里，而客户端库 `systems/services/sync-service.md` 的正文已在回链「权威在 `backend-design-documents/contracts/profile-sync.md`」。**该回链当前指向一处不存在的内容**（见「前置依赖」）。

## 约束（来自既有设计）

- **后端写入字段表封闭四行**，措辞是「后端只读，**除表内四项外**」；扩表须显式引用护栏并逐条通过「够格进表」两条判据（§5）。
- **diff 是顶层键粒度的浅合并，后端不递归、不比对、不逐元素合并**不透明段（§3a）。
- **`sync.payload_invalid` 明写「不透明段内部的任何结构问题都不得触发这一条」**（§4）。
- **复算不一致仅记账 + 上报风控，不拒绝、不改写**（§7a）；`purchase.md` §5「不为购买单开更严的处置」。
- **拒绝上行的代价是客户端丢弃本地缓冲**（`game-design-documents/systems/services/sync-service.md`），故任何新增拒绝条件必须**在正常账号上零误报**。
- **不新增错误码**：复用 `sync.conflict`，可观测性由风控事件承担（已裁决）。
- **本库不复制 Profile 字段表**（`envelope.md` §8）；白名单只列 path，不声明 Profile 由哪些字段构成。

## 建议方案

### 1. 封闭清单 = 后端写入字段表的全部行，**不另立第二张表**（承重）

`[既有推演]` 这是本方案的核心，且它把「适用面」从一份需维护的清单变成一条**恒等式**：

> **受回声校验约束的 JSON path 集合 ≡ §5 后端写入字段表的行集合。**

这不是巧合，是「够格进表」两条判据的直接推论：一条路径够格进写入表 ⟺ ① 真值只可能在服务端产生 且 ② 客户端无任何其他通道取到它 ⟺ **客户端提交的任何值都只能是它 pull 到的那个值**。

- **推论 A（承重）：写入表加一行，该路径自动进入回声约束。** 不需要第二次决定、不需要第二份清单、扩表的护栏无需加强——它已经覆盖了这件事。
- **推论 B：写入表封闭 ⇒ 回声约束面封闭。** 「适用面未穷举」这个问题由此**结构性地关闭**，而不是靠这一次把清单列全。
- **推论 C：不属写入表的透明路径一律不受回声约束。** `/accountInfo/nickname`（客户端是写入方）· `/playerPowerFragment/*` · `/playerPower[*]/*` · `/entitlement/bundleRedeemedOrdinal` 全部**照旧**：客户端有权写，越界走 §7a 的「记账 + 风控、不拒绝」。**判据是所有权，不是透明性。**

**当前的具体面（随写入表自动同步，本节不单独维护）：**

| 受约束 JSON path | 所在顶层键 | 触发该顶层键提交的客户端常规路径 |
|---|---|---|
| `/accountInfo/accountSeed` | `accountInfo` | **改昵称** |
| `/accountInfo/createdAtUtc` | `accountInfo` | 同上 |
| `/accountInfo/identities` | `accountInfo` | 同上 |
| `/entitlement/bundleGrantOrdinal` | `entitlement` | **兑现** |

**受约束的顶层键因此恰有两个。** 两者的共同形状是「同一顶层键内混有后端写入路径与客户端写入路径」——这正是整键替换把覆写窗口变成常规路径的充要条件。

### 2. 比较口径：**类型感知的语义相等**，不是原始字节相等

`[既有推演]` + `[通行做法]` 这是本方案的第二个承重点，误判的代价是**在正常账号上丢玩家进度**。

| path 的类型 | 比较口径 |
|---|---|
| 整数（`bundleGrantOrdinal`） | 数值相等 |
| 定长 hex 串（`accountSeed`） | **逐字相等**（形态已被 §2 钉死为 16 位小写 hex，两侧无归一化自由度） |
| RFC 3339 时间串（`createdAtUtc`） | **按时刻相等**，不按字面相等 |
| 对象数组（`identities`） | **有序逐元素**，元素内**逐字段**按上述口径递归 |

- **`createdAtUtc` 必须按时刻比较。** 客户端持有的是强类型时间值，反序列化 → 再序列化会在 `Z` / `+00:00`、小数秒位数上产生合法但不同字面的表示。按字面比较等于要求客户端的时间序列化器与后端逐字一致——**那是一条无人声明、无处校验、且一次库升级就会静默破坏的隐含契约**，而它破坏时的症状是「所有玩家改昵称都丢一次进度」。
- **不按原始字节比较**，同理并追加一条：JSON 对象的键序与空白不稳定，字节比较把序列化器实现细节抬成契约。
- **`identities` 取有序比较**（而非集合相等）：顺序由后端产出、客户端原样回声，要求有序既更严格也更便宜；若日后确有重排需求，那是后端自己的变更，不构成客户端义务。
- **⚠ 连带（须写进契约）：向 `identities` 元素追加字段时，客户端的强类型往返会静默丢掉它 ⇒ 回声当场失败。** 故 **向受约束顶层键内的对象追加字段，是需要两侧同批落笔的变更**——与「重命名跨边界枚举值」同档。这条对不透明段不成立（§8 已定「客户端加字段不需要后端配合」），**受约束路径是它的例外**，须明写。

### 3. 处置：整批拒绝 · 复用 `sync.conflict` · 风控事件（沿用已裁决，本节只补两处形态）

`[既有推演]` 处置本体已由 `solution-draft-bundle-grant-ordinal-authority.md` Q1 定案，本方案不重开。两处补充：

- **`detail.field` 给**第一条**不匹配的 JSON path**（不给全部）。给全部会把一次拒绝的 `detail` 形状做成不定长数组，而客户端对该情形不新增分支、根本不消费它；单条 path 足够定位，且与 `sync.payload_invalid` 的 `detail.field` 形状一致。
- **判定顺序：`schemaVersion` 闸门 → CAS → 回声校验。** CAS 失败即整批拒绝，无须再检字段；回声校验通过后才进入写入。**回声校验必须在 `cloudRevision += 1` 之前**——拒绝的一次不得消耗 revision（与 `schemaVersion` 闸门「判定发生在 CAS 之前，版本不兼容不应消耗一次 revision」同一条理由）。
- **风控事件字段**：账号 · 违规 path · 云端值 · 客户端提交值 · `requestId`。与 §7a 的复算风控事件同形，**落地形态仍归 `02` / `06`**，契约层只声明必须上报。

### 4. §4 拒绝清单由两类扩为三类（已登记的连带，本节给出形态）

`[既有推演]`

`profile-sync.md` §4 目前的拒绝面是：CAS 三分支（`sync.conflict` / `sync.revision_ahead`）· 信封与顶层形状（`sync.payload_invalid`）· `schemaVersion` 闸门（`sync.payload_schema_unsupported`）。新增第三类**所有权类拒绝**：

| 类 | 触发 | code | 是否消耗 revision |
|---|---|---|---|
| 版本闸门 | `schemaVersion` 越出兼容集合 | `sync.payload_schema_unsupported` | 否 |
| 信封 / 顶层形状 | 信封字段缺失或类型不合法 | `sync.payload_invalid` | 否 |
| CAS | 基线不符 / 本地领先 | `sync.conflict` · `sync.revision_ahead` | 否 |
| **所有权（新）** | **回声校验不通过** | **`sync.conflict`（复用）** | **否** |

- **`sync.payload_invalid` 的边界不变**：它仍只覆盖信封本身与 §3a 的顶层形状，**回声校验不走它**——回声比较的是透明段内某条 path 的**取值**，不是结构合法性。
- **仍然「不透明段内部的任何结构问题都不得触发拒绝」**：本条只作用于白名单内的四条 path，补集一字不动。

### 5. 与 §7a 的判据边界，须与规则同批落笔

`[既有推演]` §7a 定「复算不一致仅记账、不拒绝」，`purchase.md` §5 定「不为购买单开更严的处置」。本条看起来更严，故**判据必须与规则同处**，否则三句话读起来互抵：

> **判据是所有权，不是严格程度。** §7a 管的是**客户端有权写、后端只作复算比对**的路径——值**可能有争议**，一次误报就是一次错误的进度丢失，故只记账。本条管的是**客户端根本无权写**的路径——值**无争议地不属于它**，正常客户端在这些 path 上**永远只会提交回声**，故零误报，拒绝是安全的。

**推论：`/entitlement/bundleRedeemedOrdinal` 的不变式越界仍走 §7a**（记账不拒绝），尽管它与受约束的 `bundleGrantOrdinal` 同处一键——**同一顶层键内两条 path 走两种处置，判据是各自的所有权**。这一点必须明写，否则实现者会按键统一处置。

## 具体形态（可 derive 的落地面）

**改动清单（逐文件）：**

| 文件 | 改动 |
|---|---|
| `contracts/profile-sync.md` §5 | 在后端写入封闭表下方新增**回声校验通则**一节：恒等式（受约束 path ≡ 写入表行集合）+ 三条推论 + 比较口径表 + 所有权判据 + 「追加字段是两侧同批变更」 |
| `contracts/profile-sync.md` §4 | 拒绝清单扩为四行（含所有权类），并写明判定顺序与「不消耗 revision」 |
| `contracts/profile-sync.md` §7a | 补一句判据边界（所有权 vs 复算），回链 §5 新节 |
| `contracts/purchase.md` §5 | 「不为购买单开更严的处置」补上同一条判据（已由 `solution-draft-bundle-grant-ordinal-authority.md` 登记为连带） |
| `openapi.yaml` / `schemas/profile-visible-subset.json` | **不改**：回声是取值层约束，schema 表达不了「等于当前云端值」；须在 spec 中留一条注释指向 §5 新节，否则实现者会试图用 schema 承担它（与「缺失透明 path 走告警台账、不走 schema 校验」同一处坑） |

**服务端保证（栈中立的验收断言，接在既有保证之后）：**

- 上行 `playerDiff` 含 `accountInfo`，其中三条后端写入 path 与云端语义相等 ⇒ 接受；`nickname` 照常写入。
- 上行 `playerDiff` 含 `accountInfo`，其中任一条后端写入 path 与云端不等 ⇒ `sync.conflict`，`detail.field` 给第一条不匹配的 path，且 `cloudRevision` 与 profile 均不变。
- `createdAtUtc` 以不同合法 RFC 3339 表示（`Z` ↔ `+00:00`、不同小数秒位数）提交同一时刻 ⇒ **接受**。
- `identities` 元素顺序与云端不同 ⇒ **拒绝**。
- `bundleRedeemedOrdinal > bundleGrantOrdinal` 且 `bundleGrantOrdinal` 回声正确 ⇒ **接受** + 告警台账 + 风控事件（§7a，不拒绝）。

## 后果

- 回声校验从「`entitlement` 一处的特例」升为**通则**，适用面随写入表自动封闭 ⇒ 「适用面未穷举」不会再次发生。
- 上行路径新增一次字段级比较，仅当 `playerDiff` 含两个受约束顶层键之一时触发，代价可忽略。
- **对客户端新增一条刚性**（受约束键内追加字段 = 两侧同批），如实记下；对不透明段的「客户端加字段零配合」不受影响。
- 不扩后端写入封闭表，护栏未被动用。

## 备选方案（已考虑并否决）

- **另立一张「受回声校验约束的 path」清单** — 与写入表必然漂移，而漂移形态正是「进了写入表却没进回声表」，即本问题要关掉的口子。恒等式使这张表不必存在。
- **按顶层键统一处置**（`entitlement` 键内任何不一致都拒绝）— 会把 `bundleRedeemedOrdinal` 的越界从「记账」升为「拒进度」，与 §7a 正面冲突。判据必须逐 path 按所有权判。
- **原始字节相等** — 把序列化器实现细节抬成契约；`createdAtUtc` 的合法表示差异会让正常账号稳定被拒。
- **字段级挑拣：忽略客户端提交的后端写入路径、接受其余** — 要求后端在顶层键内部做字段级合并，动摇 §3a 的分段。（`solution-draft-bundle-grant-ordinal-authority.md` 已按同一理由否决。）
- **为回声失败新增专用错误码** — 客户端处置与 Conflict 完全一致；可观测性由风控事件承担（已裁决）。
- **`identities` 按集合相等（忽略顺序）比较** — 更宽松但无收益：顺序由后端产出、客户端原样回声，宽松只会掩盖客户端的重排 bug。
- **用 JSON Schema 表达回声约束** — schema 表达不了「等于当前云端值」；强行表达只能退化为把这些 path 标成必填，而 §3a 的浅合并 diff 里它们本就常常不出现。
- **回声校验放在 CAS 之前** — 无收益且更贵：CAS 失败时本就整批拒绝，先做字段比较是白做。

## 与既有决策的张力

1. **`purchase.md` §5「不为购买单开更严的处置」与本条表面互抵。** 已由 `solution-draft-bundle-grant-ordinal-authority.md` 登记为必须同批落笔的连带；本方案给出了判据的完整措辞（子项 5）。**不写判据即两句互抵**，请确认判据措辞可接受。
2. **本条使「后端何时拒绝上行」从三类变四类**（原草稿写作「两类变三类」，实际清单含 `schemaVersion` 闸门，故为四类）。§4 现有表述失真，**须同批改**。
3. **`envelope.md` §8 定「客户端加一个字段不需要后端配合、不需要提升 `schemaVersion`」**——本方案对**受约束顶层键内的对象**造出一个例外（后端加字段需要客户端配合）。方向相反但对象不同（那句讲不透明段、本条讲白名单内），**仍须在 §8 留一句指路**，否则读者会认为「加字段永远零配合」。

## 前置依赖

- **`solution-draft-bundle-grant-ordinal-authority.md`（status `decided`）须先经 `/analyze-new-ideas` 提炼进 `contracts/profile-sync.md`。** 回声校验规则本体、`/entitlement/bundleRedeemedOrdinal` 白名单行、`receiptId` 幂等窗口、读己所写要求**至今没有一条落进契约**；而客户端库 `systems/services/sync-service.md` 已在正文回链「权威在 `backend-design-documents/contracts/profile-sync.md`」——**该回链目前指向不存在的内容，两侧已处于不一致状态**。本方案是在那份草稿之上的**通则化**，**它不落笔则本方案无处附着**。
- **本方案与 `counterpart` 须同时采纳。** 本库定「校验哪些 path、如何比较、如何拒绝」，对侧定「客户端如何组装、回声值取自哪里、push 前自检、老档补默认值的例外」。只采纳本侧 ⇒ 客户端现有的「老档缺字段补默认值」会在正常账号上稳定触发整批拒绝（= 丢进度）；只采纳对侧 ⇒ 客户端老实回声但无人校验，口子仍开着。
- **风控事件的字段与处置阈值**归 `02` / `06`，落 `operations/`，**不阻塞**本方案（契约层只声明「必须上报、不在热路径裁决」）。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> 逐条裁决（`/batch-provide-solution-draft` 合并 interview）：
> 1. `createdAtUtc` 的比较口径 → **A · 按时刻相等** `[采纳推荐 — 待复核]`
> 2. `identities` 的比较口径 → **A · 有序逐元素相等** `[采纳推荐 — 待复核]`
> 3. 新刚性「向受约束顶层键内的对象追加字段 = 两侧同批变更」 → **已裁决：接受**（与 `counterpart` 同项同裁）
>
> 连带（对侧同批裁定，供本稿参照，不在本库落笔）：客户端 push 前自检不一致时 = **强制回声改写 + `PushError`**；`account-info.md` 的「老档补默认值」**批准松动**为分路式。两侧须成对采纳。


1. **`createdAtUtc` 的比较口径**（承重，`[取向选择]`）
   - **A（推荐）—— 按时刻相等：** 容忍合法的 RFC 3339 表示差异。理由：字面相等等于把两侧时间序列化器的逐字一致做成隐含契约，其破坏形态是「全体玩家改昵称各丢一次进度」，且无处校验。**代价**：后端比较需按类型解析，实现略贵（可忽略）。
   - **B —— 逐字相等：** 更简单、更严格，但要求客户端对该 path 原样透传 pull 到的字符串（不经强类型往返）。**它把一条本可由后端一次解析消化的风险，压成客户端一条必须永远记得的纪律。**
2. **`identities` 的比较口径**（`[取向选择]`）
   - **A（推荐）—— 有序逐元素相等。** 严格、便宜、且客户端本就原样回声。
   - **B —— 集合相等（忽略顺序）。** 更宽松，但会掩盖客户端的重排 bug，且顺序本就由后端产出。
3. **新增刚性「向受约束顶层键内的对象追加字段 = 两侧同批变更」是否接受**（`[取向选择]`）——见「张力 3」。替代方案是要求客户端对受约束键采用保留未知字段的松散持有形态，代价落在对侧（打破其类型一致性纪律），`counterpart` 已就同一项**不推荐**该替代。
