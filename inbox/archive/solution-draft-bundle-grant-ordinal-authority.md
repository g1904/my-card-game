---
type: solution-draft
date: 2026-08-18
question: `bundleGrantOrdinal` 的推进权归属定案后，后端侧要承接什么 —— 写入权威的封闭性、兑现水位路径的登记、后端主动写入后的可读语义、收据幂等窗口
source: game-design-documents/open-questions/05-service-contracts.md → 「`monetization.md` 内部相抵——`BundleGrantOrdinal` 究竟由谁施加（08-17 新增 · 承重）」（客户端库待答项，跨边界承接）
targets: contracts/purchase.md · contracts/profile-sync.md（§5 白名单与后端写入封闭表 · §9 幂等窗口 · §6 服务端保证）· operations/（对账与补偿，仅回链）
counterpart: game-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md
status: distilled
reviewed: 2026-08-19 — 三项取向全部按推荐定案（Q1 回声校验整批拒绝 + 风控 · Q2 读己所写升格为服务端一致性要求 · Q3 `receiptId` 永久保留不设 TTL）
distilled-to: handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md
---

# 方案 — `bundleGrantOrdinal` 施加权归属的后端承接

> **本文件只写后端这一半**：验票、序号 `+1` 的写入权威与原子性、后端主动写入后的可读 / 通知语义、幂等窗口、以及新透明路径的后端登记。
> `AllowedOps` 的最终形态、兑现事务、掷骰与 `TryApply`、UI 态 → 见 `counterpart`，**本文件不复述**。
> 技术栈未定 ⇒ 全文停在协议与语义层，不指定语言 / 框架 / 存储实现。

## 问题

客户端库 `systems/monetization.md` 内部两处相抵：购买伪码由**客户端**组装 `Elements: [BundleGrantOrdinal := ordinal]`，而同文档定案写「只能由**后端** `+1`」。`counterpart` 提议按**后端唯一 `+1`** 收口、并删除客户端的施加路径。

这在本库侧不是「跟着改一句」，而是牵出四件本库必须自己定的事：

1. 「后端唯一 `+1`」在本库已成文（`purchase.md` §2、`profile-sync.md` §5 封闭表），但**它只挡住了「客户端主动 `+1`」，没有挡住「客户端整键替换把它写回旧值」**——`profile-sync.md` §3a 的浅合并是**顶层键粒度**，`/entitlement` 一旦出现在 `playerDiff` 中即**整键替换**，键内的 `bundleGrantOrdinal` 随之被客户端提交的值覆盖。
2. `counterpart` 为兑现幂等提议新增客户端写的 `/entitlement/bundleRedeemedOrdinal`。它一旦成立，客户端**每次兑现都必须提交 `/entitlement` 这个顶层键**——第 1 条从「理论窗口」变成「每次兑现都会走一遍的常规路径」。
3. 客户端在 verify 之后**强制一次 pull** 才能拿到新序号，故本库需要一条**读己所写**的可读性保证；`purchase.md` §6.3 目前断言的是「verify 通过后立即 pull 读到一致」，但没有把它写成对读路径的一致性要求。
4. 客户端的待兑现态可**跨启动、跨天**存活，其补查走 `GET /v1/purchase/receipt/{receiptId}`。该端点的幂等记录**没有定保留期**，而 `pushId` 的 30 天 TTL 不适用于它。

## 约束（来自既有设计）

- **验票必须由后端向平台校验，写入只由 verify 承担；渠道回调只作对账**（`purchase.md` §2）。
- **`bundleGrantOrdinal += 1` 与 `cloudRevision += 1` 必须在同一次事务内**（`purchase.md` §3、`profile-sync.md` §8）。
- **后端写入字段表封闭，措辞是「除表内四项外一律只读」**；扩表须显式引用护栏并逐条通过两条判据（`profile-sync.md` §5）。
- **后端对不透明段不解析、不递归、不逐元素合并**（§3a）；`playerDiff` 顶层键出现即整键替换。
- **复算不一致仅记账 + 上报风控，不拒绝、不改写**（§7a），购买域不加严（`purchase.md` §5）。
- **verify 不接受 `baseRevision`、不做 CAS**（`purchase.md` §3）。
- **仅两处硬阻塞**，且 verify 不返回 `compliance.*`（`purchase.md` §3）。

## 建议方案

### 1. 「后端唯一 `+1`」原样成立，本库不改口径

`[既有推演]` `purchase.md` §2 与 `profile-sync.md` §5 封闭表已是这一侧的权威表述，且 §5 的护栏注里已写明「它的推进权只能在后端，否则付费防篡改归零（客户端侧承重定案，不可绕过）」。**`counterpart` 的裁决方向与本库既有表述完全同向，本库无需改写任何既有句子**——本文件的全部内容都是**新增的护栏与登记**，不是修订。

### 2. 新增护栏：`/entitlement` 顶层键的**回声校验**（承重 · 本方案的核心）

`[既有推演]` 后端写入字段表挡的是「谁有权 `+1`」，而 §3a 的整键替换绕过它的方式不是 `+1`，是**覆写**：客户端提交 `entitlement: { bundleGrantOrdinal: n, bundleRedeemedOrdinal: n }`，若 `n` 是它 pull 时的旧值而云端已被另一次 verify 推到 `n+1`，整键替换会把云端**回退**到 `n`。序号回退比不推进更糟——它让同一个 `ordinal` 被兑现两次，且下一次 verify 会把它再推一次，序列彻底错位。

`revision` CAS **确实**能挡住绝大多数这类情形（云端 verify 写入使 `cloudRevision` 领先 ⇒ 客户端的 push 带旧 `baseRevision` ⇒ `sync.conflict` 拒绝）。**但不能把它当作唯一防线**，两条理由：

- CAS 保护的是**并发窗口**，不是**字段所有权**。客户端一个 bug（例如把 `bundleGrantOrdinal` 常量写成 0）在 CAS 通过的情况下会被原样接受——CAS 只问「你的基线对不对」，不问「你有没有权改这个字段」。
- 后端写入字段表的护栏是**声明式**的，目前**没有任何执行点**。这条护栏落不到报文层，就只是一句纪律。

**建议形态（栈中立）：**

> **凡 `playerDiff` 含顶层键 `entitlement`：其中 `bundleGrantOrdinal` 必须与当前云端值逐位相同，否则整批拒绝，回 `sync.conflict`（复用既有码，不新增），`detail.field` 给该 JSON path，并打一条风控事件。**

- **通则化的措辞**：后端写入字段表内的路径，凡落在某个可被客户端提交的顶层键之下的，客户端提交的值**只能是回声（echo）**——与当前云端值相等即通过、不等即拒绝。**后端永不采纳客户端对这些路径的写入，也不静默丢弃它**（静默丢弃会让客户端 bug 永远看不见）。
- **为什么是「拒绝」而不是「忽略该字段、接受其余」**：§3a 的合并语义是整键替换，无法在不解结构的前提下做字段级挑拣；而一旦为它开一次字段级处理，「后端不递归、不逐元素合并」这条分段就被打开了。**拒绝整批是唯一不动摇既有分段的处置。**
- **为什么复用 `sync.conflict` 而不新增错误码**：客户端的处置与 Conflict 完全一致（以云端为准、丢弃本地缓冲、重新 pull），新增码只会逼客户端多写一条分支去做同一件事。**风控事件承担「这不是普通冲突」的可观测性**，与既有「不可能态单列一行但处置相同」同构。
- **它与 §7a「复算不一致不拒绝」不冲突。** §7a 管的是**客户端有权写、后端只是复算比对**的路径（掷骰结果）；本条管的是**客户端根本无权写**的路径。两者判据不同：前者是「值可能有争议」，后者是「所有权无争议」。

### 3. 兑现水位路径 `/entitlement/bundleRedeemedOrdinal` 的登记

`[既有推演]` 若 `counterpart` 的子项 3 被采纳，本库须同批登记：

**A. §5 透明字段白名单新增一行**

| JSON path | 类型 | 后端用途 |
|---|---|---|
| `/entitlement/bundleRedeemedOrdinal` | number int | **后端只读**。不变式校验：`0 ≤ bundleRedeemedOrdinal ≤ bundleGrantOrdinal`，且单调不减 |

**B. 后端写入封闭表不动。** 该字段的真值产生在客户端（兑现事务的一部分），**第 ① 条判据即不满足**——与 `/accountInfo/nickname` 同型，属「透明只读」而非「后端写入」。**本方案不请求扩那张表**，护栏无需被引用。

**C. 不变式违反的处置：告警级台账 + 风控事件，不拒绝上行。** 与 §7a 同侧、与子项 2 相反，判据是所有权：这个字段客户端有权写，越界只说明客户端算错了水位，拒绝它会把一次客户端 bug 升级成一次进度丢失（且玩家的法则 / 古宝已经在同一批里）。**唯一例外仍是子项 2 的回声校验**——那覆盖的是同一个顶层键里的另一个字段。

**D. 后端不据此做任何发放 / 补偿判断。** 「`bundleGrantOrdinal > bundleRedeemedOrdinal` 持续超过 N 天」是一条**有价值的运营信号**（玩家付了钱但客户端一直没兑现），但它的落点是 `operations/` 的对账任务，**不进契约、不驱动任何自动写入**——自动补发会让后端具备发放权，与「兑现段客户端演算」正面相悖。

### 4. verify 之后的可读语义：读己所写（read-your-writes）

`[既有推演]` + `[通行做法]` 客户端拿新序号的**唯一**路径是 verify 应答后**强制一次 pull**（`purchase.md` §3 已定 verify 不内联 profile）。若 pull 落到一个滞后的只读副本上，客户端会读到旧序号 ⇒ 判定「无待兑现」⇒ **玩家付了钱，客户端认为没有货可发**，且不会重试（它已经不觉得自己欠什么）。

**建议把 `purchase.md` §6 的服务端保证 3 从「验收断言」升格为「一致性要求」：**

> **verify 应答返回之后，同一账号的任何后续 `/v1/profile/pull` 必须读到该次写入的结果**（`bundleGrantOrdinal` 与 `revision` 均不早于 verify 应答中的值）。这是对读路径的**要求**，不只是一条测试断言——它排除「pull 走可能滞后的只读副本」这一实现形态，或要求该形态附带会话粘滞 / 版本等待。

- **不指定实现**（主库读 / 会话粘滞 / 携带 `revision` 下界等待），只写要求本身，符合本库「技术栈未定即停在语义层」。
- **同一要求适用于 `GET /v1/purchase/receipt/{receiptId}`**：它是补查路径，读到滞后结果的后果与上面逐字相同。
- **不引入「后端主动通知 / 推送」。** 客户端的既定路径是**强制 pull**，推送会新增一条通道、要求长连接或平台推送依赖，而它解决的问题已被强制 pull 解决。**明确否决。**

### 5. 收据幂等窗口：与 `pushId` 的 30 天 TTL **不同轴**，建议永久保留

`[既有推演]` `profile-sync.md` §9 为 `pushId` 定了 200 条 / 30 天，推导依据是**客户端待发队列的存活上界**（refresh token TTL）。`receiptId` 的存活上界完全不同：

- 客户端的待兑现态**跨启动持久化、且无自动放弃**（`counterpart` 明写「无硬超时、永不放弃」）；玩家可以卸载、几个月后重装再登录。
- 更关键：即使客户端**丢掉** `receiptId`，`counterpart` 的水位字段仍会让它在任意时刻发现自己欠一次兑现——但那时它需要的不再是补查，而是 pull（水位比较不需要 `receiptId`）。**故 `receiptId` 记录的真正消费者是两个**：① 客户端的补查；② `operations/` 的对账与退款处理。
- **平台侧的退款 / 客诉窗口以月计**，对账需要按 `receiptId` 回查一次购买的全部历史。

**建议：`(receiptId)` 幂等记录 —— 全局唯一键、永久保留（不设 TTL）。**

| 旋钮 | 建议值 | 推导 |
|---|---|---|
| 唯一键 | **`receiptId` 全局唯一**，不带 `accountId` 前缀 | 「已被其他账号核销」是既定失败面（`purchase.md` §3），它要求跨账号可查重；`pushId` 用 `(accountId, pushId)` 是因为它由客户端生成、只在账号内有意义 |
| 保留时长 | **永久**（不设 TTL） | 记录体量与购买次数同阶（每账号个位数 / 年），存储成本可忽略；而过期的后果是**重复 `+1`**（第二次提交查不到记录 ⇒ 当作新票 ⇒ 玩家白得一份），与 `pushId` 过期只降级为一次进度丢失**不是同一量级** |
| 存储形态 | `receiptId → { accountId, bundleGrantOrdinal, revision, verifiedAtUtc, status }` | 与 `bundleGrantOrdinal` / `cloudRevision` 的写入**同一次事务**——与 §9 「分开写会出现 revision 已 +1 但幂等记录未落」逐字同理 |

- **实现落点（存储选型、分区、归档到冷存储）归 `operations/`**，与 `purchase.md` 现有的 Open question「幂等记录的存储、事务边界的实现」同一处置，**不回头改契约**。本条只定**语义**：永不过期。

### 6. 与 CAS 三分支表的关系：不动

`[既有推演]` `purchase.md` 已否决「为购买在 CAS 三分支表加第四分支」，理由是客户端时机纪律已在结构上关闭该窗口。**本方案不重开它**：子项 2 的回声校验发生在**接受写入之前的字段级准入**，与 CAS 是两层——CAS 问「基线对不对」，回声校验问「你有没有权改这个键」。两者串联，先 CAS 后回声（CAS 失败即整批拒绝，无须再检字段）。

## 具体形态（可 derive 的落地面）

**改动清单（逐文件）：**

| 文件 | 改动 |
|---|---|
| `contracts/profile-sync.md` §5 | 白名单新增一行 `/entitlement/bundleRedeemedOrdinal`（只读 + 不变式）；封闭表**不动** |
| `contracts/profile-sync.md` §3a 或 §5 | 新增**回声校验**通则（子项 2），含处置、错误码复用与风控事件 |
| `contracts/profile-sync.md` §9 旁 | 新增一节或在 `purchase.md` 内定 `receiptId` 幂等窗口（子项 5），并明写**与 `pushId` 不同轴** |
| `contracts/purchase.md` §6 | 保证 3 升格为读己所写的一致性要求；**新增保证 5**：客户端提交的 `entitlement.bundleGrantOrdinal` 与云端不等时上行被拒且不改变任何状态；**新增保证 6**：同一 `receiptId` 在任意时间跨度后重复提交仍回 `deduplicated = true`（永不过期） |
| `contracts/purchase.md` §4 | `receipt/{receiptId}` 端点补一句读己所写要求 |
| `operations/`（尚未落笔） | 对账信号「`grant > redeemed` 持续 N 天」的落点；幂等记录的存储与归档 |

**服务端保证（栈中立的验收断言，接在 `purchase.md` §6 之后）：**

5. 上行 `playerDiff.entitlement.bundleGrantOrdinal` 与云端当前值不等 ⇒ 上行被拒（`sync.conflict`），且 `bundleGrantOrdinal` / `bundleRedeemedOrdinal` / `cloudRevision` 三者皆不变。
6. 同一 `receiptId` 在首次 verify 之后任意时间跨度（含 > 30 天）重复提交，仍回 `deduplicated = true`，序号与 `revision` 与第一次逐位相同。
7. verify 应答返回后立即发起的 `pull` 与 `receipt/{receiptId}` 读，均不早于该次写入的结果。
8. 上行使 `bundleRedeemedOrdinal > bundleGrantOrdinal` ⇒ **接受写入**，记一条告警级台账 + 风控事件（不拒绝）。

## 后果

- 触及 `contracts/profile-sync.md`（一条白名单行 + 一条通则）与 `contracts/purchase.md`（三处保证 + 一处一致性要求）。**不扩后端写入封闭表**，护栏未被动用。
- 对读路径提出实现约束（读己所写），会排除某些「pull 走异步只读副本」的部署形态——这是**有代价的**，须在栈选型时带上。
- 幂等记录永久保留 ⇒ 存储只增不减；量级与购买次数同阶，判定为可接受。
- 回声校验给上行路径加了一次**字段级比较**（仅当 `playerDiff` 含 `entitlement` 键时），代价可忽略。

## 备选方案（已考虑并否决）

- **只靠 `revision` CAS 挡住 `entitlement` 覆写** —— CAS 问基线不问所有权；客户端 bug 在基线正确时会被原样接受，且后端写入字段表的护栏将永远没有执行点。
- **字段级挑拣：忽略客户端提交的 `bundleGrantOrdinal`、接受其余** —— 要求后端在顶层键内部做字段级合并，动摇 §3a「不递归、不逐元素合并」的分段。
- **为回声校验新增专用错误码** —— 客户端处置与 Conflict 完全一致，新码只逼客户端多写一条走向同一处的分支；可观测性由风控事件承担。
- **把 `bundleRedeemedOrdinal` 提为 profile 的另一个顶层键**（避开与后端写入字段同处一键） —— 能绕开整键替换问题，但把一对语义紧邻的字段拆到两个顶层键、且**与 `counterpart` 的 `PlayerEntitlement` 类形态直接冲突**；更重要的是它只搬走了本条的表现，`/accountInfo`（同时含后端写入的 `identities` 与客户端写入的 `nickname`）仍是同一形状 —— 那说明需要的是**通则**，不是搬家。
- **verify 应答内联新 profile 以免去 pull** —— `purchase.md` 已否决（把 profile 下行形态复制进购买域）。读己所写要求是更便宜的解。
- **后端主动推送新序号给客户端** —— 新增一条通道与平台推送依赖，而强制 pull 已解决同一问题。
- **`receiptId` 沿用 `pushId` 的 30 天 TTL** —— 过期的后果是**重复 `+1`**（玩家白得一份），与 `pushId` 过期只降级为一次进度丢失不是同一量级。
- **后端在 `grant > redeemed` 超时后自动补发** —— 等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖；对账信号归 `operations/`，只作人工 / 工单入口。

## 与既有决策的张力

1. **子项 2 的回声校验与「后端对透明段只读」是同向的，但它给上行路径新增了一条拒绝条件**，而 `profile-sync.md` 现有的拒绝条件只有 CAS 三分支与信封校验（§4、§4 的 `sync.payload_invalid` 明写「不透明段内部的任何结构问题都不得触发这一条」）。本条的拒绝对象是**透明段**，不违反那句话，但它确实使「后端何时会拒绝上行」的清单从两类变三类 —— **须在 §4 一并登记，否则那份清单失真**。
2. **子项 4 的读己所写要求是本库首次对读路径提实现约束**。此前本库一贯停在「协议与语义层，不指定实现」；一致性要求处在语义与实现的边界上。**不提这条的替代**：把风险推给客户端（要求它在 pull 读到旧序号时重试 N 次），代价是把一条服务端保证换成一条客户端轮询纪律，且它无法区分「副本滞后」与「verify 其实没成功」。**建议提，由用户裁决。**
3. **`purchase.md` §5 明写「不为购买单开更严的处置」**（复算不一致沿用 §7a）。子项 2 看起来是「更严」，但它管的不是复算、是所有权 —— **须在改写时把这条判据写进去**，否则两句话会被读成互相抵触。

## 前置依赖

- **本方案的子项 3（`/entitlement/bundleRedeemedOrdinal` 登记）与子项 2（回声校验涉及 `entitlement` 键的形状）须与 `counterpart` 的子项 3（`PlayerEntitlement` 加第二字段）与子项 2（撤下客户端 `BundleGrantOrdinal` 施加路径）同时采纳。单侧采纳即两侧不一致**：只本库登记 ⇒ 该路径永远读不到值、不变式恒真、白名单多一条死行；只客户端加字段 ⇒ 它对后端落在不透明段之外却未登记，且 `entitlement` 整键替换的覆写窗口在**无任何校验**的情况下被常态化触发。
- **本方案的子项 2 若被否决，`counterpart` 的子项 3 需要重新评估**：客户端每次兑现都会提交 `/entitlement` 整键，而该键内含后端唯一写入的字段，只剩 CAS 一道防线。
- **子项 5 的存储与归档形态**依赖 `06-platform-stack.md` 的栈选型（与 `purchase.md` 现有 Open question 同一处置，落 `operations/`，不回头改契约）。语义（永不过期）本身不依赖选型。
- `receipt` 字段的内部形态与平台错误码映射仍待**支付渠道**选型（`purchase.md` Open questions），**不阻塞**本方案任何一条。

## 用户裁决（2026-08-19 · 全部定案）

**后端侧三项取向全部按本方案的推荐定案（各取 A）**：Q1（回声校验）沿用 2026-08-18 批量评审的裁决，Q2 / Q3 于本次一并采纳。本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

> **成对采纳（硬要求，不变）：** 本方案与 `game-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md` **必须成对采纳**，单侧采纳即两侧不一致。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| Q1 | 是否新增「回声校验」这条拒绝条件（承重） | **取 A —— 新增**：`playerDiff` 含 `entitlement` 键时，`bundleGrantOrdinal` 必须与云端逐位相同，否则**整批拒绝 + 风控事件**<br>*（2026-08-18 已裁，照录）* | 所有权类越界与复算不一致**不同轴** —— 复算不一致的值「可能有争议」，所有权越界的值「无争议地不属于你」。B 的失败模式无声且不可逆（客户端一个 bug 即可在基线正确时把后端唯一写入的序号覆写回旧值，两侧都不报错），C 观测到时损害已成。**后端写入字段封闭表由此首次获得执行点** |
| Q2 | 是否把「读己所写」升格为服务端一致性要求 | **取 A —— 升格**，写进 `purchase.md` §6，并**排除「pull 走可能滞后的只读副本」这一部署形态**（或要求其附带等待机制） | 这条链上**唯一一个无人重试的失败点**就在这里：客户端读到旧序号时无法区分「副本滞后」与「verify 未成功」，且它已判定「无待兑现」、根本不会重试 ⇒ 玩家付款后静默拿不到货。一条一致性要求比一条客户端轮询纪律**便宜且可验收**。**代价照录**：对栈选型施加一条约束，本库首次触及实现层边界 |
| Q3 | `receiptId` 幂等记录的保留期 | **取 A —— 永久保留，不设 TTL** | 过期代价**不对称**：`pushId` 过期是一次进度丢失（已被既定语义接受），`receiptId` 过期是一次**错误发放**（发放侧漏洞，且不可发现）。B 需要论证「超过该期限的重复提交不可能发生」，而客户端待兑现态无自动放弃，该论证做不实。存储只增，量级与购买次数同阶，可忽略 |

**Q1 的两处连带（照录，采纳须同批落笔）：**
- `profile-sync.md` §4 的「后端何时拒绝上行」清单**由两类变三类**，须同批登记。
- `purchase.md` §5「不为购买单开更严的处置」改写时须**一并写入判据（所有权 vs 复算）**，否则两句读起来互抵。

**对侧库 Q1 已裁决：加水位字段。** 故 `/entitlement/bundleRedeemedOrdinal` 登记进 §5 白名单（只读 + 不变式）这一条成立，且该覆写窗口从理论变为**每次兑现都走一遍**的常规路径 —— 这正是 Q1 取 A 的直接前提。

**越界发现已被采纳为新待答项**：`/accountInfo` 是「客户端整键替换覆写后端写入字段」的**第二处同形**（含后端写的 `accountSeed` / `createdAtUtc` / `identities` 与客户端写的 `nickname`）—— 需逐条登记哪些路径受回声校验约束。**本方案不改 `open-questions`，交由 `/analyze-new-ideas` 落笔。**

## 已定案的相邻项（本方案不写其本体，只记录裁决与连带）

- **平台内购 SDK 与支付渠道选型 → 已裁决：纳入 MVP。** 计划支持 **Google Play Billing · App Store（StoreKit）· 微信支付** 三条渠道。
  这**推翻了客户端库 `monetization.md` 原先「MVP 之外」的登记**，并把 `06-platform-stack.md` 里的支付渠道选型从「不阻塞、可推后」变为**MVP 范围内必须答结**的一项：后端须逐渠道定验票端点形态（三家的收据 / 凭证结构与校验协议互不相同），`purchase.md` §3 的 `receipt.platform` 取值域随之由「待定」收敛为**三个具名渠道**。
  **对本方案的实质影响为零**：验票通过后的 `+1` 写入权威、原子性、幂等窗口与回声校验逐字不变——它们对渠道无差别。
- **`operations/` 尚未落笔**，本方案两处指向它（幂等记录存储、`grant > redeemed` 对账信号）只作登记。
- **`compliance.*` 与购买的交互**已由 `purchase.md` §3 关死（被合规拦住的账号拿不到 access token，走不到 verify），本题不重开。
