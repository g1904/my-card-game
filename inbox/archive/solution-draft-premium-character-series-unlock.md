---
type: solution-draft
date: 2026-09-11
question: 付费角色系列的后端承接 —— SKU 的命名与粒度、验票后写入 profile 的报文与语义、`profile-sync` 两张表加行、兼容矩阵登记、失败 `code`
source: open-questions/cross-boundary.md → 「待承接」第一条（`ADR-0255` 三项义务）
targets: contracts/purchase.md · contracts/profile-sync.md · contracts/envelope.md · operations/version-matrix.md · operations/purchase-ops.md · systems/profile-store.md
counterpart: game-design-documents/inbox/solution-draft-premium-character-series-unlock.md
status: distilled
reviewed: 2026-09-11（批量评审 · 1 项按标准默认采纳；cross-boundary 两问均已答结；另须补「上架窗口」落地面，见文末连带裁决）
distilled-to: handoffs/2026-09-12-premium-character-series-unlock.md
---

# 方案草稿 — 付费角色系列的后端承接（后端半）

> **本文件只写后端这一半。** `CharacterData` 的轨道标记字段、`PlayerProfile` 的集合字段形态与读档校验、取池过滤落哪个服务、客户端购买流程与 UI、`schemaVersion` 的逐版形状 —— 全部归 counterpart（`game-design-documents/inbox/solution-draft-premium-character-series-unlock.md`），本文件一字不复述，只回链。
>
> **技术栈虽已落定，本方案仍停在协议与语义层**：不指定表结构、索引、框架或库。

## 问题

`open-questions/cross-boundary.md`「待承接」的第一条（2026-09-11 登记）把 `ADR-0255` 给后端的三项义务列了出来，并明写它**现阶段是待答 / 提案形态**，后端侧要决的是两件事：

1. **SKU 粒度是系列级还是角色级？**
2. **封闭表加的是哪张表？**

由此还牵出该条目未点名、但一旦落笔就绕不开的四件：验票后写入什么、幂等语义如何对位、失败 `code` 要不要加、`schemaVersion` bump 的矩阵登记。

本方案逐条给出提案。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| B1 | **验票必须由后端向平台服务器校验，不信客户端自述**；写入只由 verify 承担；渠道回调只作对账 / 补偿，不作写入路径 | `contracts/purchase.md` §2 · `ADR-0007` |
| B2 | **客户端提交的一切只作「去哪里查」的索引，不作判据** | `purchase.md` §3a |
| B3 | 请求根是以 `platform` 为判别式的 `oneOf` 三分支；**新增第四条渠道 = 新增一个 `oneOf` 分支 + 一个枚举值**，`/v1/` 不动 | `purchase.md` §3 · `ADR-0018` |
| B4 | **幂等键不由客户端生成**；`receiptId` 全局唯一、**永久保留不设 TTL**、字符集 `[A-Za-z0-9._~-]`、上界 1024 | `purchase.md` §3a · §7 |
| B5 | **同一 `receiptId` 重复提交绝不重复写入**，回 `deduplicated = true` 且结果逐位相同（§6 保证 1 / 6） | `purchase.md` §6 |
| B6 | **profile 写入与 `cloudRevision += 1` 必须在同一次事务内**；禁止「先写 profile 再改 revision」的两步非原子形态 | `purchase.md` §6 保证 2 · `profile-sync.md` §8 |
| B7 | **读己所写**：verify 应答返回后，任何后续 `pull` / `GET receipt` 必须读到该次写入 | `purchase.md` §6 保证 3 |
| B8 | **后端写入字段封闭表护栏（措辞不许改）**：规则是「后端只读，**除表内四项外**」；任何扩表提案须**显式引用本护栏并说明为何不能用别的通道**，不得静默加行 | `profile-sync.md` §5 |
| B9 | **够格进表的判据（两条同时满足）：** ① 真值只可能在服务端产生；② 客户端无任何其他通道能取到它 | 同上 |
| B10 | **「写入时机」列同样封闭**：建号 / 验票 / `bind`·`unbind` 之外的任何时机，后端一律不写 | 同上 |
| B11 | **适用面恒等式：受回声校验约束的 JSON path 集合 ≡ 后端写入字段表的行集合。** 写入表加一行，该路径**自动**进入回声约束，不需要第二次决定 | `profile-sync.md` §5c |
| B12 | **受约束的顶层键恰有两个**：`accountInfo` · `entitlement` | 同上 |
| B13 | **⚠ 连带刚性：向受约束顶层键内的对象追加字段，是需要两侧同批落笔的变更** —— 它是 `envelope.md` §8「客户端加字段不需要后端配合」的例外 | 同上 |
| B14 | diff 是**顶层键粒度的浅合并**：出现即整键替换、未出现即不变、空对象 = 无变化、**不表达删除** | `profile-sync.md` §3a |
| B15 | **新增一个 `code` 的三条判据**（任一成立即应独立成码；三条全不成立即复用既有码、台账不加行）：① 客户端处置逐字相同 ② 玩家面为空 ③ 区分所需的事实在服务端自己的进程内 | `envelope.md` §6 的反向先例（flags 零装载） |
| B16 | **P-1**：`envelope.md` §6 台账首列是机器读取面；**P-3**：§3 端点全集表首列同理，新增 / 删除 / 改名端点须同批改表 | `envelope.md` §6 · §3 |
| B17 | **SKU 表本身不在契约内** —— 契约只写「后端与自己的 SKU 表比对，不匹配即无效」；不匹配一律 `purchase.receipt_invalid` + 风控事件 | `purchase.md` §3a |
| B18 | **退款不回收权益、不回退序号**；退款态记在幂等记录的**运维侧字段**上，**不进 `GET receipt` 的 `status` 枚举** | `purchase.md` §7 |
| B19 | **§7a 的既有处置形态**：不一致 / 越界一律**接受写入 + 打风控事件，不拒绝、不改写** | `profile-sync.md` §7a · `purchase.md` §6 保证 7 |
| B20 | **兼容矩阵：矩阵先加、客户端后发**；`schemaVersion` 子表当前只有 `1` 一行 | `operations/version-matrix.md` · `operations/_index.md` |
| B21 | 契约变更的**完成判据**六条（markdown · spec · 台账 · 三条机检断言 · 人工清单四项 · 另一侧 handoff 互相回链），**变更内原子，只改一边即视为未完成** | `contracts/_index.md` |
| B22 | **分域判据**：一个域的承重纪律若与既有任一份相反，才独立成文 | 同上 |

## 建议方案

### ① SKU 粒度 = **系列级**（回答 `cross-boundary.md` 的第一问）

`[既有推演]`

`ADR-0255` 的「备选方案」段**明确否决了「单个角色零售」**（理由：破坏五行对称，且会把「买哪个最强」变成事实上的强度选择）。⇒ **可购商品只有整系列礼包一种**；ADR 里的「付 4 个单解之价 / 付 8 个单解之价」是**定价锚（记账单位）**，不对应任何 SKU。

⇒ **一个角色系列 = 一个 SKU**。后端无需表达角色粒度，也**不持有任何「这个系列包含哪 5 / 10 个角色」的知识** —— 那是内容编排，抄到后端即制造第二权威，而本库与对侧都没有任何机制能发现它漂移。

### ② `productId ↔ seriesId` 用**机械变换**，不建映射表

`[既有推演]`

SKU 表本就存在（B17），本方案**只给它加一个类别维度**，不给它加一列手工维护的 `seriesId`：

```
productId  =  "series_" + <seriesId 的 slug 段>
             例：seriesId = character_series.wu_xing_chu_zu  →  productId = series_wu_xing_chu_zu
```

- **判据是本库已行使过两次的那一条：「能机械变换的绝不建第二张手写表」。** 先例：`code → ERR_*` 的像（对侧 `ux/error-and-blocking-ux.md`）；本契约自己的 `receiptId` = 渠道前缀 + 平台 id（§3a），同样是拼出来而非查出来的。
- **后端校验的是形态，不是存在性。** 后端不知道内容层有哪些合法 `seriesId`（它没有内容知识，这正是 ① 的目的），故 `productId` 必须能机械反解出一个符合 `character_series.<snake_case_slug>` 形态的 `seriesId`；反解失败 → `purchase.receipt_invalid` + 风控事件（复用 B17 的既有处置，零新码）。
- **存在性的真实防线在发版前的商店配置核对**（归 `operations/purchase-ops.md` 的发布清单），不是运行时。客户端读到一个解析不到内容条目的 `seriesId` 的降级处置在 counterpart，本库不复述。
- **推论：客户端零新增下发面、零新增端点。** 「Store 屏该列哪些系列 SKU」由客户端内容层自行归组、`productId` 由同一条机械变换得出 —— 不需要 catalog 端点、不需要经 manifest / flags 通道下发。

**SKU 表的类别维度（不进契约，落 `operations/purchase-ops.md` 或 `systems/profile-store.md`）：**

| 列 | 取值 |
|---|---|
| `productId` | 各渠道商店后台配置的商品 id |
| `kind` | `PremiumBundle` \| `CharacterSeries` —— **验票后的写入动作按它分流** |
| 渠道商品类型 | `PremiumBundle` → **consumable**（既定：可重复购买）；`CharacterSeries` → **non-consumable**（见 ⑤） |

### ③ `verify` 的应答按 `kind` 分形；**请求一格不加**

`[既有推演]`

**请求侧零变更。** 不在 `VerifyRequest` 里加 `seriesId` —— 那是客户端自述，正面违反 B2。`seriesId` 由后端从 `productId` 经 ② 的机械变换解析。`productId` 本来就在 `receipt` 分支内（Google Play 显式字段 / App Store 的 JWS 内 / 微信经 `outTradeNo` 查单），**请求报文一字不动**。

**应答侧按 `kind` 分形**（`bundleGrantOrdinal` 的存在理由是「兑现段掷骰的 `ordinal`」，而系列解锁**没有兑现段**）：

| 方向 | 字段 | 语义 |
|---|---|---|
| ↓ | `kind` | `PremiumBundle` \| `CharacterSeries` —— **后端权威回显**该 `productId` 的 SKU 类别；判别式 |
| ↓ | `bundleGrantOrdinal` | **仅 `kind == PremiumBundle` 时存在**；`+1` 后的新序号 |
| ↓ | `revision` | `+1` 后的新 `cloudRevision`（两类同有） |
| ↓ | `deduplicated` | boolean（两类同有） |

- **spec 层取 `oneOf` + `discriminator: { propertyName: "kind" }`**，与请求根判别式（`ADR-0018`）**同构**——本契约已经用过这个手法一次，其收益（必填性可被 schema 层校验）原样继承。
- **系列解锁的应答不需要回 `seriesId`**：客户端知道自己点的是哪个 SKU，且**正确性由购后 pull 读到的 `/entitlement/characterSeries` 承载**，不由应答承载。这与 §3 既有的「应答只回序号 + revision，不内联新 profile」同一条取向。
- **新增 SKU 类别 = 新增一个应答分支 + 一个枚举值**，对既有客户端是纯追加 ⇒ `openapi.yaml` 的 `info.version` bump **minor**，`/v1/` 不动 —— 与 B3 对渠道的既定处置逐字同构。

**`GET /v1/purchase/receipt/{receiptId}` 的 `Verified` 应答同款分形**（现状「`Verified` 时附 `bundleGrantOrdinal` 与 `revision`」改为「附 `kind` 与 `revision`；`bundleGrantOrdinal` 仅 `kind == PremiumBundle` 时附」）。`Rejected` 的 `code` 取值域**一字不变**（仍 ⊂ { `purchase.receipt_invalid`, `purchase.receipt_claimed` }）。

### ④ 验票事务内的写入：**集合追加**，与 `revision += 1` 同事务

`[既有推演]`（B6 · B14）

```
kind == PremiumBundle   →  /entitlement/bundleGrantOrdinal += 1        （既有，一字不改）
kind == CharacterSeries →  /entitlement/characterSeries 尾部追加 { seriesId }   （本方案新增）
两者共有                →  cloudRevision += 1                          （同一次事务）
```

- **后端恒在数组尾部追加，且保证元素唯一**（已含即无操作）。尾部追加使 §5c 的**有序逐元素**比较口径天然成立（见 ⑥），不必为本 path 另开一种集合比较语义。
- **元素形态 `{ seriesId }`（对象而非裸字符串）** —— 形态权威在 counterpart 的存档字段表，本库只写「按对方定义的元素形状原样写入」，不复述字段表。
- **两类写入的幂等性质不同，但都必须走 `receiptId` 幂等：**

  | | premium bundle | 角色系列 |
  |---|---|---|
  | 写入动作 | 非幂等自增 `+1` | **自然幂等**的集合并入 |
  | 仍需 `receiptId` 幂等的理由 | 自增本身 | ① `cloudRevision` 的推进**不幂等**，重复验票会白推 revision 并撞 CAS；② 「已被其他账号核销」的检查依赖 `receiptId` 全局唯一；③ §6 保证 1 / 6 是对全域的承诺，不按 SKU 分叉 |

### ⑤ 重复购买已拥有系列：**接受写入 + 风控事件，绝不拒绝**

`[通行做法]` + `[既有推演]`

**主防线是平台侧的商品类型：`kind == CharacterSeries` 的 SKU 一律配置为非消耗型** —— Google Play 非消耗型商品（**不 consume、不 acknowledge 后重购**）与 App Store `Non-Consumable` 在平台层即拒绝重复购买。这是 IAP 的标准形态，也与 premium bundle「商品须配置为 consumable」形成明确对照（两类 SKU 的商品类型由 `kind` 决定，见 ②）。

**但微信支付没有「非消耗型商品」这一概念**，且多设备并发能绕过客户端的「已拥有即置灰」前置。⇒ 后端需要一道兜底。处置：

> 验票通过、但该 `seriesId` 已在该账号的 `characterSeries` 内，且本次 `receiptId` 是**新的**（不是幂等命中）
> ⇒ **接受写入**（集合幂等 ⇒ 实际无变化）· `cloudRevision` 仍 `+1` · 回 `deduplicated = false` · **打一条风控 / 运维事件**（账号 · `seriesId` · 两个 `receiptId` · `requestId`）· 退款处置走人工工单。

- **绝不拒绝（承重）。** 钱已经扣了。回一个 `Fatal` 只会让玩家在付款之后撞上失败面，正是对侧反复引用的「把失败点挪到掏钱之前」所要避免的最糟时机；而这里已经挪不动了，只能不失败。
- **处置形态与 B19（§7a）逐字同构**：接受写入 + 打风控事件、不拒绝、不改写。本方案**不新开处置语义**。
- **不自动退款**（见「仍需用户决定」）。

### ⑥ `profile-sync.md` 两张表各加一行（回答 `cross-boundary.md` 的第二问：**两张都加**）

`[既有推演]`

**问题问的是「封闭表加的是哪张表」。答案是：`§5` 下的两张表都要加，且它们不是二选一 ——** 后端写入字段表（封闭）与透明字段白名单是两个正交维度：前者答「谁写」，后者答「后端看不看得懂」。一个由后端写入的字段必然对后端透明，故**加写入表就必须同批加白名单**。

**(a) 后端写入字段表（封闭）新增一行**

| JSON path | 写入时机 | 频次 | 语义权威 |
|---|---|---|---|
| `/entitlement/characterSeries` | **验票通过且该 SKU 的 `kind == CharacterSeries` 时，尾部追加一个元素** | 反复 | `purchase.md` |

**按 B8 护栏要求，显式论证为何不能用别的通道：**

- **B9 判据 ①（真值只可能在服务端产生）成立。** 解锁是付费凭证的兑现结果；客户端写入 = 客户端有权发货，这正是 `ADR-0007`（购买写入权威分配）与 `purchase.md` §2 已明确关死的那条。
- **B9 判据 ②（客户端无任何其他通道能取到它）成立。** 与 `bundleGrantOrdinal` 不同的是，本 path **没有兑现段**：没有客户端掷骰、没有可由本地事实派生的值、没有第二个字段能承载它。若不进写入表，就没有任何通道能让解锁到达客户端。
- **对照三条既有反例，逐条不同：** `/accountInfo/nickname`（判据 ① 不成立，客户端写）· `/statistics`（宽松同步、客户端写）· `/entitlement/bundleRedeemedOrdinal`（「同键不等于同所有权」—— 水位由客户端写）。本 path 与 `bundleGrantOrdinal` 同所有权、同时机。
- **「写入时机」列（B10，护栏最紧的一列）不被触碰**：本次是在**既有的「验票」时机**下新增一条 path，**不新增任何时机**。建号 / `bind`·`unbind` 两个时机一字不动。

**(b) 透明字段白名单新增一行**

| JSON path | 类型 | 后端用途 |
|---|---|---|
| `/entitlement/characterSeries` | array of `{ seriesId }` | 解锁集合；**后端写入**（验票时尾部追加）；受 §5c 回声校验约束。**后端不做除回声比对之外的任何校验** —— 它不是任何复算的输入，也无区间 / 单调不变式可查（集合语义，唯一不变式「只增不删、元素唯一」由后端自己保证，见 ⑦） |

**(c) §5c 的「当前具体面表」新增一行，但「受约束的顶层键恰有两个」这句一字不改**

`[既有推演]` —— 这是本方案对护栏最漂亮的一处零扰动：

- 按 B11 的恒等式，写入表加一行 ⇒ 该 path **自动**进入回声约束，「不需要第二次决定」。
- 而 `entitlement` **已经**是两个受约束顶层键之一（因 `bundleGrantOrdinal`）⇒ **顶层键集合不变、恒为两个**，B12 那句承重表述原样成立。
- 触发路径列：`entitlement` 那一行现写「兑现」，本方案建议改为「**兑现 · 系列解锁后的下一次 `entitlement` 上行**」—— 准确说是「任何提交 `entitlement` 整键的 push」，因为浅合并下客户端改动键内任一格都会把整键提交上来。

**(d) §5c 比较口径表新增一行**

| 类型 | 口径 |
|---|---|
| 对象数组（`characterSeries`） | **有序逐元素**，元素内逐字段递归 —— 与 `identities` 逐字同款 |

- **有序而非无序集合比较。** 理由：④ 保证后端恒在尾部追加、客户端原样回声（counterpart 明写客户端对该 path 不改写、不去重、不归一化）⇒ 有序天然成立；而另开一种无序比较语义要在这张口径表上加一种读法，为零收益付一次歧义。

**(e) `envelope.md` §8 的连带刚性（B13）由本次首次真实行使。** 它此前只是一条写下来的例外；本方案是它的第一个实例 —— 向 `entitlement` 内追加字段，两侧同批落笔。**这不需要改 §8 一个字**，只需在本次变更的 handoff 里点明它被行使了一次。

### ⑦ `purchase.md` §6 服务端保证的对位

`[既有推演]`

| 既有保证 | 对角色系列的处置 |
|---|---|
| 1（同 `receiptId` 恰好 `+1`） | **加一条对位**：同一 `receiptId` 提交 N 次，该 `seriesId` 在 `characterSeries` 中**恰好出现一次**，且 `cloudRevision` 恰好 `+1`；第 2..N 次回 `deduplicated = true` 且结果逐位相同 |
| 2（写入与 revision 同事务） | **原样覆盖**，主语由「`bundleGrantOrdinal`」放宽为「本次的 profile 写入」 |
| 3（读己所写） | **原样覆盖**，一字不改 |
| 4（`bundleGrantOrdinal` 严格单调） | 不适用（本类无序号） |
| 5（上行 `bundleGrantOrdinal` 不等即拒） | **自动覆盖新 path**（B11 恒等式），无需加字 |
| 6（任意时间跨度仍幂等） | **原样覆盖** |
| 7（水位越界接受 + 记账） | 不适用（本类无水位） |
| **8（新增）** | **`/entitlement/characterSeries` 只增不删、元素唯一** —— 后端保证客户端读到的数组无重复、且既有元素永不被移除（**含 ⑩ 的付费→免费情形**：轨道改了，已解锁条目照样留着，它是无害的幂等残留） |

### ⑧ 失败 `code`：**零新增**，`envelope.md` §6 台账零加行

`[既有推演]`（B15 三条判据）

逐一核对本方案引入的全部新情形：

| 新情形 | 处置 | 是否需要新码 |
|---|---|---|
| `productId` 不在 SKU 表 / 反解不出合法 `seriesId` 形态 | `purchase.receipt_invalid` + 风控事件 | ❌ 复用（B17 的既有处置逐字覆盖） |
| 该系列已拥有、重复购买 | **不回错误**（⑤：接受写入 + 风控事件） | ❌ **玩家面为空**（判据 ② 成立即不应独立成码） |
| 收据无效 / 已被他账号核销 / 未终态 / 渠道未开通 / 报文不合法 | 既有五条 `purchase.*` 原样 | ❌ |

⇒ **零新增 `code`、零新增端点、零新增 `OpError` 取值。**

推论（都是实打实的省事）：`envelope.md` §6 台账**不加行** ⇒ **P-1 护栏不被触碰**；§3 端点全集表**不加行** ⇒ **P-3 不被触碰**；三条机检断言的双向映射**零变化**；B21 完成判据的第 3 条（「若涉及新增 / 变更 `code`」）在本次变更中**无对象**。

### ⑨ `receiptId` 幂等记录的存储形态加两格

`[既有推演]`

§7 现存形态 `receiptId → { accountId, bundleGrantOrdinal, revision, verifiedAtUtc, status }`，建议改为：

```
receiptId → { accountId, productId, kind, bundleGrantOrdinal?, grantedSeriesId?, revision, verifiedAtUtc, status }
```

- **存 `productId` 原值而非只存解析结果**：SKU 可被下架，历史记录靠反查会断。
- **`grantedSeriesId` 是解析结果的快照**：同理，机械变换规则若日后调整，历史工单仍要能定位当时发了什么。
- `bundleGrantOrdinal` 与 `grantedSeriesId` **按 `kind` 二选一存在**，与 ③ 的应答分形对位。
- **仍与 profile 写入、`cloudRevision` 自增同一次事务**（§7 既定）。
- **退款态仍记在运维侧字段、不进 `GET receipt` 的 `status` 枚举**（B18 一字不改）。

### ⑩ 兼容矩阵登记：`schemaVersion = 2`，**矩阵先加、客户端后发**

`[既有推演]`（B20）

- counterpart 的 `schemaVersion` 登记表将新增一行（对侧的 `/entitlement/characterSeries` 落在**受回声校验约束的顶层键**内，按其形态纪律必须进版本行）。**逐版形状的权威在对侧，本库一字不复述**。
- 本库的承接义务：`operations/version-matrix.md` 的 `schemaVersion` 子表**加 `2` 一行 + 下线计划**；`sync.payload_schema_unsupported` 的 `detail.supportedSchemaVersions` 随之为 `[1, 2]`。
- **顺序纪律是硬的**：矩阵先加、客户端后发。矩阵未加就发客户端 ⇒ 每一个新版客户端的第一次 push 即被 `sync.payload_schema_unsupported` 拒（`Upgrade` 档，不硬阻塞，但玩家进度上不去云端）。
- **条件分支（如实写下）：** 若付费系列改在客户端首发**之前**落地，按对侧「首发前的一切改动全部归入 `schemaVersion = 1`」，**本条整条不发生** —— 矩阵零改动。`ADR-0255` 说「后续版本引入」，故预期是前者。
- **这正是 `cross-boundary.md` 头部点名的那类常规触发源**（「对侧 `profile-schema-versions.md` 登记表新增一行 = 一次 bump 定案 ⇒ 本库须把该版本号登进矩阵子表」），本条按四段式登记即可。

### ⑪ 契约变更的完成判据（B21）在本次的逐条落位

`[既有推演]` —— 写出来是为了让「这次改完了没有」可核对：

| # | 判据 | 本次的对象 |
|---|---|---|
| 1 | markdown 语义 / 理由 / 承重纪律已更新 | `purchase.md` §2 §3 §4 §6 §7 · `profile-sync.md` §5 §5c |
| 2 | `openapi.yaml` / `schemas/*.json` 同批更新 | **本次无对象** —— spec 尚未落笔（`contracts/_index.md` 明写「spec 尚不存在时本条无对象」），三条机检断言走**降级形态** |
| 3 | 新增 / 变更 `code` 登台账 | **本次无对象**（见 ⑧） |
| 4 | 三条机检断言 | 降级形态：① `skipped: no spec yet`（**不是 `pass`**）· ② 台账首列 ⇔ 六份契约正文 `code` 字面量双向（零变化）· ③ §3 端点全集 ⇔ 正文 `METHOD 路径` 双向（零变化） |
| 5 | 人工清单四项 | ① `detail` / `message` 零变化；② **承重纪律段落是否失效** —— 本次必须逐条复核 `profile-sync.md` §5 白名单与 §5c 恒等式（正是本方案 ⑥ 所做）；③ 需 bump `schemaVersion`（见 ⑩），URL 主版本不动、spec `info.version` bump **minor**；④ 另一侧 handoff |
| 6 | 另一侧跨库 handoff 已写并互相回链 | counterpart 是本条的前半；落笔时两侧各写一份 handoff 互相回链 |

**分域判据（B22）复核：本方案不新开契约文档。** 它没有引入任何与既有六份相反的承重纪律 —— 它就是 `purchase.md` 既有纪律（后端权威写入 · 必须裁决 · 必须能拒绝）在第二类 SKU 上的直接延伸。

## 具体形态（可 derive 的落地面）

**`contracts/purchase.md`：**
- §2 写入权威分配：主语由 `bundleGrantOrdinal` 放宽为「本次的 profile 写入」，两类 SKU 的写入动作分列。
- §3 verify 应答表：新增 `kind` 行；`bundleGrantOrdinal` 标注「仅 `kind == PremiumBundle`」；补一句「请求侧一字不动，`seriesId` 由后端从 `productId` 机械解析」。
- §3a：新增一小节「SKU 类别与 `productId ↔ seriesId` 的机械变换」（规则 + 反解失败的处置 + 「SKU 表不进契约」的既有立场不变）；三渠道商品类型（consumable / non-consumable）按 `kind` 分列。
- §4 `GET receipt`：`Verified` 应答同款分形；`Rejected` 取值域一字不变。
- §6：保证 1 加对位、保证 2 主语放宽、**新增保证 8**。
- §7：幂等记录存储形态加 `productId` / `kind` / `grantedSeriesId?`。
- 新增一小节：重复购买已拥有系列的处置（⑤）。

**`contracts/profile-sync.md`：** §5 两张表各加一行（⑥ a / b）；§5c 具体面表加一行、比较口径表加一行、「受约束的顶层键恰有两个」**保持不变**。

**`contracts/envelope.md`：** **零改动**（⑧）。§8 的连带刚性被首次行使，但条文不变。

**`operations/version-matrix.md`：** `schemaVersion` 子表加 `2` 一行 + 下线计划（⑩）。

**`operations/purchase-ops.md`：** SKU 表的类别维度与商品类型配置；`productId` 机械变换的发版前核对清单；重复购买风控事件的工单处置。

**`systems/profile-store.md`：** 验票事务内的集合追加与唯一性保证的实现侧落点。

**跨库回链（不复述）：** `CharacterData` 轨道字段 · `PlayerEntitlement` 集合字段形态与读档校验 · 取池过滤落点 · `schemaVersion` 逐版形状 · 客户端购买流程与 UI ⇒ 全部在 `game-design-documents/inbox/solution-draft-premium-character-series-unlock.md`。

## 后果

- **契约面**：两份文档改动（`purchase.md` · `profile-sync.md`），**零新增文档、零新增端点、零新增 `code`**。
- **护栏**：后端写入字段封闭表由 4 行增至 5 行 —— 这是它成文以来的**第一次扩表**，须按 B8 显式引用护栏（⑥ 已照做）。「写入时机」列与「受约束顶层键恰有两个」两处承重表述**一字不动**。
- **运维**：SKU 表多一个类别维度；幂等记录多三格；多一类风控事件（重复购买已拥有系列）；矩阵多一个版本行。
- **spec**：`info.version` bump minor（纯追加）；`/v1/` 不动。spec 尚未落笔，故本次机检断言走降级形态。
- **不新增**：端点、错误码、`OpError` 取值、契约文档、写入时机、受约束顶层键。

## 备选方案（已考虑并否决）

- **角色级 SKU（单个角色零售）** — 否决：`ADR-0255` 备选方案段已明确否决，本库无权推翻对侧已 Accepted 的决策。
- **新开端点 `POST /v1/purchase/verify-series`** — 否决：验票逻辑（渠道校验、幂等、事务、读己所写）逐字相同，分端点即写两遍；且 §3 端点全集表、三条机检断言、`receiptId` 幂等窗口全要分叉。B3 已为「新增渠道」定下「加分支不加端点」的形态，新增 SKU 类别同理。
- **应答复用 `bundleGrantOrdinal`，在系列购买时回「云端当前值」** — 否决：同一字段在不同 SKU 下语义不同（「+1 后的新序号」vs「当前值」），正是本契约反复分列的那种歧义（`receipt_pending` 与 `server.unavailable` 分列的判据同源）。
- **请求里带 `seriesId`** — 否决：客户端自述，正面违反 B2。
- **后端持「系列 → 角色 id 列表」表** — 否决：内容编排知识的第二权威，两库无机制发现漂移。
- **后端 SKU 表加一列手工维护的 `seriesId`** — 否决：能机械变换的绝不建第二张手写表（`code → ERR_*` 与 `receiptId` 前缀是两个先例）。
- **无序集合比较口径** — 否决：④ 的尾部追加 + 客户端原样回声使有序天然成立；另开一种比较语义为零收益付一次歧义。
- **重复购买已拥有系列时返回一个新的 `Fatal` code** — 否决：钱已扣，让玩家在付款后撞失败面是最糟的失败时机；且 B15 判据 ②（玩家面为空）成立即不应独立成码。
- **把解锁做成「后端主动推送」** — 否决：`purchase.md` §6 保证 3 的注解**已明确否决**「后端主动推送新序号给客户端」，读己所写 + 购后强制 pull 是既定路径。
- **给角色系列另设一条兑现水位（对称于 `bundleRedeemedOrdinal`）** — 否决：水位的存在理由是「发货动作在客户端、云端需要一个可见的已发货记号」；本类的发货动作在后端，没有任何东西需要被记号。完整论证在 counterpart。

## 与既有决策的张力

1. **后端写入字段封闭表的第一次扩表。** B8 的护栏措辞是「后端只读，**除表内四项外**」—— 加行之后这句话里的「四项」变成「五项」。**护栏本身的措辞规则（「不是『后端可写的字段有……』」）一字不改**，但这是它成文以来第一次被行使，值得用户明确点头：扩表是破坏性契约变更，须两侧同批评审（护栏自己这么写的）。**本方案主张这一次够格**（B9 两条判据逐条论证见 ⑥），但裁决权在用户。
2. **`purchase.md` §6 保证 2 的主语需要放宽。** 现写的是「`bundleGrantOrdinal` 与 `revision` 的自增要么都发生、要么都不发生」。放宽为「本次的 profile 写入与 `revision` 自增」后，语义更强、覆盖面更大，**但它改动了一条承重保证的措辞** —— B21 人工清单第 2 项（「承重纪律段落是否随形态变更而失效」）正指向这类改动。
3. **`GET receipt` 的 `Verified` 应答形状变更。** 现写「附 `bundleGrantOrdinal` 与 `revision`」是无条件的；③ 把它变成按 `kind` 条件化。对既有客户端是**破坏性的吗？** 本方案判断不是 —— 既有客户端只会查到 `kind == PremiumBundle` 的收据（它买不到系列 SKU），该分支字段一字不变。**但这条判断依赖「老客户端不可能持有系列 SKU 的 `receiptId`」这个前提**，值得用户复核。
4. **`cross-boundary.md` 那条待承接的定性需要更新。** 它现写本条是「待答 / 提案形态，不是等落笔的已定案承接项」并列出后端要决的两问。本方案对两问都给了提案（① 系列级 · ⑥ 两张表都加），但**它们仍是提案**；条目在用户裁决之前不应改成「已定案承接项」。

## 前置依赖

- **counterpart（客户端草稿）的三项，须与本方案同时采纳：** ① **解锁粒度 = 系列、集合元素是 `seriesId`** —— 本方案 ① ② ④ ⑥ 全部建立在它之上；② **`PlayerEntitlement.CharacterSeries` 的字段名与元素形状**（`/entitlement/characterSeries`、元素 `{ seriesId }`）—— 本方案 ⑥ 的两张表行逐字依赖它；③ **客户端对该 path 不改写、不去重、不归一化**（原样回声）—— 本方案 ⑥(d) 的**有序逐元素**比较口径依赖它。**单侧采纳即两侧不一致**：后端会写一个客户端不认的 path，或回声比对在正常账号上稳定失败。
- **counterpart 的 `schemaVersion` 登记行**须与本方案 ⑩ 的矩阵行同批，且**矩阵先加、客户端后发**（B20）。
- **`open-questions/06-meta-progression.md`（对侧）「双灵根批与付费系列的推出时点与主题包装」** —— 首批付费系列的 `seriesId` 取值、进而 `productId` 取值，在它答定前无法在各渠道商店后台落地配置。本方案只定变换规则，不定任何取值。
- **⑩ 是否发生取决于付费系列落地是否在客户端首发之后**（`ADR-0255` 说「后续版本引入」，故预期发生）。
- **渠道资质**：微信支付渠道随资质开通启用（既定），首版不开通 ⇒ 系列 SKU 首版只在 Google Play / App Store 上架，⑤ 的微信兜底首版不发生但须先写下（它是微信开通时的前置）。

## 仍需用户决定

### （1）重复购买已拥有系列时，是否**自动发起渠道退款**？

> **→ 已按标准默认采纳（2026-09-11 · 批量评审）：选项 A —— 不自动退款，记风控事件走人工工单。**
> 本项在合并 interview 中经分类纪律复核后**判定不构成真取向**，按推荐直接定案、未单独出题：B 要求后端持三渠道**退款 API 写权限**（当前 `operations/purchase-ops.md` 的凭据面只覆盖查询 / 核销，是显著攻击面扩大）且需引入一条异步补偿状态机；C 的前提「账号级可支配货币」已被明确关死。主防线是平台侧非消耗型商品「已拥有即灰」、微信渠道首版不开通 ⇒ 近乎零触发，且 **A → B 是纯加法**，触发率超预期时不需回头改任何契约条款。

⑤ 已定死「绝不拒绝、接受写入、打风控事件」，但**那笔钱怎么办**是一个真取向（运营取向 + 合规取向，无客观最优）：

| 选项 | 后果 |
|---|---|
| **A（推荐）· 不自动退款，记风控事件走人工工单** | 与 B18 的既有形态一致（「退款不回收权益、不回退序号，退款态记在运维侧字段」—— 本库已经把退款整体放在人工侧）。**代价如实写下：** 玩家要主动找客服，体验差；且三渠道的客服可达面目前只有 `#requestId` 一条（对侧既定，不新增客服入口） |
| **B · 自动发起渠道退款** | 体验最好、争议最少。**代价：** 后端须持有三家渠道的**退款 API 写权限凭据**，这是一次显著的攻击面扩大（当前 `operations/purchase-ops.md` 的凭据面只覆盖查询 / 核销）；且退款成功与否异步不可控，要引入一条补偿任务与一个新的运维状态机 —— 本库刻意不做的那类长时异步已在 `compliance` 域单独成文，往 `purchase` 域再开一条是分域判据要慎重的事 |
| **C · 折价成下次购买抵扣** | 需要账号级可支配货币，对侧已**明确关死**（「为兜底引入一条等于新开一套经济」） |

**推荐 A。** 理由：C 的前提已被关死；B 的成本（退款写权限 + 一条异步补偿状态机）远高于它要解决的问题频次 —— 该情形的主防线是平台侧非消耗型商品，微信渠道首版根本不开通，⑤ 的兜底在可预见期内近乎零触发。**若实际触发率超预期，A → B 是纯加法**，不需要回头改任何契约条款。

---

## 批量评审的连带裁决（2026-09-11 · 对本草稿有结构影响）

以下三项在合并 interview 中裁定，**改变或坐实了本草稿的落地面**，落笔时须一并兑现：

1. **SKU 粒度 = 系列级，且只有这一种。** 用户裁定「单解 SKU 不存在」——对侧 `ADR-0255` 的「付 4 个单解之价」仅为**定价锚**，不对应任何可购商品。⇒ 本草稿 ① 的推演逐字成立，`cross-boundary.md` 的第一问**就此答结**；②「`productId ↔ seriesId` 机械变换」无需为第二类 SKU 分形。
2. **`profile-sync.md` 两张表各加一行 —— 批准。** 用户明确批准后端**写入字段封闭表的首次扩表**（4 行 → 5 行，加 `/entitlement/characterSeries`），透明字段白名单同加一行（两表正交、非二选一）。⇒ 本草稿 ⑥ 逐字成立，`cross-boundary.md` 的第二问**就此答结**；护栏措辞一字不改，但落笔时须按护栏自述以「破坏性契约变更」的评审规格处理。
3. **新增机制：付费系列有购买时限（限时销售窗口）—— 本草稿须补一处落地面。** 用户在评审中新提出，三条语义已一并裁定：**不绝版**（窗口关闭后可重上架，或转常驻仅失去限时优惠价）· **已购玩家永久可用**（下架的只是购买入口，已写入的解锁记录不受影响）· 限时的是价格与销售节奏、不是可得性。
   ⇒ **对后端的义务：** SKU 表（本草稿提案落 `operations/purchase-ops.md`）须加一格**上架窗口**，`verify` 在校验购买请求时据此拒绝窗口外的新购；**窗口不进 profile、不进 `/entitlement/characterSeries`、不进任何封闭表** —— 它约束的是「能不能买」，不是「拥有什么」，故 ⑥ 的两张表加行形态**不受影响**。窗口外的拒绝复用既有 `code`，⑧「失败 `code` 零新增」**仍然成立**（窗口外购买 = 商品不可售，与既有不可售态同码）。

> **两份草稿须成对评审。** 对侧：`game-design-documents/inbox/solution-draft-premium-character-series-unlock.md`。
