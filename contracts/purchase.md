# purchase —— 付费验票 · 后端权威写入 · 收据幂等

> 覆盖 `/v1/purchase/…` 两个端点的报文本体。**边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、错误码台账、版本协商——全部见 `envelope.md`，本文件只写 purchase 域**相对它的差异与细化**。
> 客户端侧的购买流程、兑现段演算与入口前置条件见 `game-design-documents/systems/monetization.md` 与 `game-design-documents/systems/services/sync-service.md`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> 技术栈未定 ⇒ 本文件停在**协议与语义层**，不指定语言 / 框架 / 存储实现。字段形态最终由 spec 单点承载（`envelope.md` §1）。

## 1. 端点集：两个

```
POST /v1/purchase/verify              提交平台收据 → 验票 → 权威写入   —— 需鉴权
GET  /v1/purchase/receipt/{receiptId} 收据状态的幂等读                 —— 需鉴权
```

**本域与 `profile-sync` 的承重纪律恰好相反，这是它单独成文的第一理由。** `profile-sync` 的三条纪律是「后端对透明段只读 · 后端不裁决 · 复算不一致不拒绝」；购买则是**后端权威写入 · 必须裁决 · 必须能拒绝**。两套相反的纪律同居一份契约，读者无法判断哪一条管哪个端点。另两条理由：`_index.md` 的分域惯例本就按域切（边界层 / 内容分发 / 登录会话 / 存档同步 / 购买）；本域牵动平台 SDK 与渠道回调，与 `02-account-compliance.md` 的「自建 vs 接第三方」耦合，独立成文才使那条耦合显式可见。

## 2. 验票的权威分配：写入只由 verify 承担

- **验票必须由后端向平台服务器校验，不信客户端自述。** 客户端已明写「付费凭证不能只信客户端」，`bundleGrantOrdinal` 的推进权因此只能在后端——否则整套防篡改归零。
- **渠道回调只作对账 / 补偿通道，不作写入路径。** 渠道回调的时序不可控：可能早于、晚于、或永不到达客户端的 verify。把它作为写入路径会让「玩家已付款但序号未涨」无处排查，且要额外处理「回调与 verify 竞态」——而那条竞态的收益仅在「客户端崩溃且从不回来」这一场景。**回调记账与补偿任务归 `operations/`**，作为「已付款但从未 verify」的兜底发现手段。
- **兑现段仍由客户端掷骰、后端复算**（`profile-sync.md` §6 §7），本域不参与兑现。

## 3. `POST /v1/purchase/verify`

| 方向 | 字段 | 语义 |
|---|---|---|
| ↑ | `platform` | 枚举字符串，取值与客户端 C# 成员名逐字相同（`envelope.md` §2）。**取值域封闭为三条渠道**：Google Play Billing · App Store（StoreKit）· 微信支付（范围权威在 `game-design-documents/vision/scope.md`；成员名两侧同批冻结） |
| ↑ | `receiptId` | 平台收据唯一 id —— **幂等键**（窗口见 §7） |
| ↑ | `receipt` | 平台原始收据负载（形态**逐渠道不同**，三家的收据 / 凭证结构与校验协议互不相同，随各渠道接入落笔） |
| ↓ | `bundleGrantOrdinal` | `+1` 后的新序号（**兑现段掷骰的 `ordinal`**） |
| ↓ | `revision` | `+1` 后的新 `cloudRevision` |
| ↓ | `deduplicated` | boolean；同一 `receiptId` 重复提交时为 `true`，序号与 `revision` 回上次结果 |

- **幂等键取平台收据 id，不由客户端生成。** 它天然全局唯一、由平台发放。这与 `profile-sync` 为同一场景引入 `pushId` 是同一条理由，只是这里的键现成。
- **同一 `receiptId` 重复提交绝不重复 `+1`**，直接回上次结果（与 `pushId` 的 `deduplicated = true` 同构）。缺这一条，移动网络下的重试会让玩家的序号跳号、掷骰序列错位。
- **`bundleGrantOrdinal += 1` 与 `cloudRevision += 1` 必须在同一次事务内**——与 `profile-sync.md` §8 的「禁止先写 profile 再改 revision 的两步非原子形态」同一条。
- **verify 不接受 `baseRevision`、不做 CAS 判定。** 它是后端权威写入，不是客户端提交的 diff；且客户端此刻的 `baseRevision` 必然落后，走 CAS 只会失败。客户端拿新 `revision` 的路径是**购后强制一次 pull**（客户端已定）。
- **应答只回序号 + revision，不内联新 profile。** 客户端本就会另发一次 pull，两侧形态因此一致；且让 verify 保持**窄接口**，不与 profile 的下行形态耦合。否决内联：省一个 RTT，却把 profile 的完整下行形态复制进购买域，两处形态从此要同步演进。

**失败面**（错误码归 `envelope.md` §6 台账，具体码待落笔）：收据无效 · 已被其他账号核销 · 平台服务不可达（**可重试**，须与「无效」在报文层面可区分——否则客户端无从判断该不该重试）。

**verify 不返回 `compliance.*`。** 它是业务端点，而合规拦截只在 `signin` 落地（`auth.md` §5a）：在这里硬拒，玩家会在已付款之后拿不到发放，而钱已经花了——这是「仅两处硬阻塞」那条纪律代价最高的一处违反。被合规拦住的账号根本走不到 verify，因为它拿不到 access token。

## 4. `GET /v1/purchase/receipt/{receiptId}`

回 `status ∈ {unknown, verified, rejected}`；`verified` 时附 `bundleGrantOrdinal` 与 `revision`，`rejected` 时附原因。**纯读、幂等、不产生任何写入。**

**本端点同样受 §6 的读己所写要求约束**：它是「响应丢失」时的补查路径，读到滞后结果的后果与 pull 读到旧序号逐字相同——客户端据此判定「无待兑现」而不再重试。

**这个端点是承重的，不是可选便利。** 客户端在「已付款、后端已 `+1`、但响应丢失」这一移动网络常态下**必须**有一条查得回来的路径；客户端据此把玩家阻塞在主菜单重试直到拿到序号（形态归客户端，见 `game-design-documents/systems/monetization.md`）。没有这条通道，那里的阻塞就变成死等。`receiptId` 由客户端随待兑现态持久化，**跨启动也能补查**。

## 5. 复算：与残卷共用同一条链，不新开

客户端兑现段用 `(accountSeed, stream = PremiumBundle, ordinal = bundleGrantOrdinal)` 掷骰抽 3 条，后端以同一三元组复算——**这正是 `profile-sync.md` §6 已定义的 SplitMix64**（`PremiumBundle = 1` 已在那里冻结）。**本契约不定义任何新的随机源**，只回链。

复算不一致的处置**沿用 §7a**（接受写入 + 打风控事件，不拒绝、不改写），不为购买单开更严的处置：兑现段的条目是客户端从池里抽的，与残卷同构；真正需要严格把关的是**验票**那一步，而它由平台校验兜住。

**这一条与 `profile-sync.md` §5c 的回声校验不抵触，判据是所有权而不是严格程度。** 本节说的是**客户端有权写、后端只作复算比对**的路径（掷骰结果与兑现水位）——值可能有争议，一次误报即一次错误的进度丢失，故只记账；§5c 管的是**客户端根本无权写**的路径（`bundleGrantOrdinal`）——值无争议地不属于它，正常客户端永远只提交回声，故零误报。**两条判据不同轴；不写下判据，两句话会被读成互相抵触。**

## 6. 服务端保证（栈中立的验收断言）

1. 同一 `receiptId` 提交 N 次，`bundleGrantOrdinal` 恰好 `+1`；第 2..N 次回 `deduplicated = true` 且序号与第 1 次逐位相同。
2. `bundleGrantOrdinal` 与 `revision` 的自增**要么都发生、要么都不发生**。
3. **读己所写（对读路径的一致性要求，不只是一条测试断言）**：verify 应答返回之后，同一账号的任何后续 `GET /v1/profile/pull` 与 `GET /v1/purchase/receipt/{receiptId}` 都必须读到该次写入的结果（`bundleGrantOrdinal` 与 `revision` 均不早于 verify 应答中的值）。
4. `bundleGrantOrdinal` 账号级**严格单调递增、不清零**（与 `finaleWinOrdinal` 同一条纪律）。
5. 上行 `playerDiff.entitlement.bundleGrantOrdinal` 与云端当前值不等 ⇒ 上行被拒（`sync.conflict`，`profile-sync.md` §5c），且 `bundleGrantOrdinal` / `bundleRedeemedOrdinal` / `cloudRevision` 三者皆不变。
6. 同一 `receiptId` 在首次 verify 之后**任意时间跨度**（含 > 30 天）重复提交，仍回 `deduplicated = true`，序号与 `revision` 与第一次逐位相同。
7. 上行使 `bundleRedeemedOrdinal > bundleGrantOrdinal` ⇒ **接受写入**，记一条告警级台账 + 风控事件（不拒绝，`profile-sync.md` §7a）。

**保证 3 是一条要求，不是一种实现。** 客户端拿到新序号的唯一路径是 verify 应答后强制一次 pull（§3 已定 verify 不内联 profile）。若这次读落在滞后的只读副本上，客户端读到旧序号 ⇒ 判定「无待兑现」⇒ **玩家付了钱、客户端认为没有货可发，且不会再重试**（它已经不觉得自己欠什么）——这是整条链上唯一一个无人重试的失败点，客户端也无从区分「副本滞后」与「verify 其实没成功」。因此它排除「读走可能滞后的只读副本」这一部署形态，或要求该形态附带会话粘滞 / `revision` 下界等待；**具体实现不指定**，跨区域侧的对应约束见 `profile-sync.md` §8。**代价如实记下**：这是本库唯一一条对读路径提出的实现约束，须在栈选型时带上。**明确否决**「后端主动推送新序号给客户端」——新增一条通道与平台推送依赖，而它解决的问题已被强制 pull 解决。

## 7. `receiptId` 幂等窗口：全局唯一键 + 永久保留

**与 `profile-sync.md` §9 的 `pushId` 窗口不同轴，不沿用它的旋钮。** `pushId` 的 200 条 / 30 天由**客户端待发队列的存活上界**（refresh token TTL）推出；`receiptId` 的存活上界完全不同——客户端的待兑现态跨启动持久化、**无硬超时、永不放弃**，玩家可以卸载、几个月后重装再登录；而平台侧的退款 / 客诉窗口以月计，对账需要按 `receiptId` 回查一次购买的全部历史。

| 旋钮 | 定值 | 推导 |
|---|---|---|
| 唯一键 | **`receiptId` 全局唯一**，不带 `accountId` 前缀 | 「已被其他账号核销」是既定失败面（§3），它要求跨账号可查重；`pushId` 取 `(accountId, pushId)` 是因为那个键由客户端生成、只在账号内有意义 |
| 保留时长 | **永久（不设 TTL）** | 过期代价不对称：`pushId` 过期只降级为一次进度丢失（既定语义已接受），`receiptId` 过期是**重复 `+1`**——第二次提交查不到记录即当作新票，玩家白得一份，且这是发放侧漏洞、线上不可发现。记录体量与购买次数同阶（每账号个位数 / 年），存储成本可忽略 |
| 存储形态 | `receiptId → { accountId, bundleGrantOrdinal, revision, verifiedAtUtc, status }` | 与 `bundleGrantOrdinal` / `cloudRevision` 的写入**同一次事务**——分开写会出现「revision 已 `+1` 但幂等记录未落」，正是重放会重复发放的那一刻 |

**幂等记录的存储选型、分区与冷存归档归 `operations/`**（与本文件 Open questions 中「幂等记录的存储、事务边界」同一处置），**不回头改契约**。本节只定语义：**永不过期**。

**对账信号不进本契约。**「`bundleGrantOrdinal > bundleRedeemedOrdinal` 持续超过 N 天」（玩家付了钱但客户端一直没兑现）是有价值的运营信号，落点是 `operations/` 的对账任务，**不驱动任何自动写入**——自动补发等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖，只作人工 / 工单入口。

## 决策(-> ADR)

- **购买写入只由 verify 端点承担，渠道回调降为对账通道** → ADR 候选，登记于 `decisions/_index.md`。值得固化其依据（回调时序不可控 ⇒ 「已付款但序号未涨」无处排查），否则「用回调直接写库省一次往返」会反复被重新提出。

## 备选方案（已考虑并否决）

- **把购买端点并进 `profile-sync.md`** — 两套相反的承重纪律不能同居一份契约（§1）。
- **平台回调直接写库、不设 verify 端点** — 回调时序不可控，且「已付款未涨序号」无处排查（§2）。**回调保留为对账通道。**
- **让客户端携带 `baseRevision` 走 CAS 提交购买** — 走 CAS 等于承认客户端有权参与决定序号；且客户端此刻的 `baseRevision` 必然落后，只会失败。
- **为购买在 CAS 三分支表加第四分支** — 客户端的时机纪律已在结构上关闭该窗口，加分支等于为一个不可达的情形增加同步模型的复杂度。
- **验票由客户端做、后端事后复算** — 客户端置位 = 客户端有权发货；事后发现不一致时玩家已拿到东西，回收比不发更糟。
- **verify 应答内联新 profile** — 省一个 RTT，却把 profile 的下行形态复制进购买域，两处形态从此要同步演进。
- **在本库复述客户端的时机纪律与兑现流程** — 回链即可；复述会制造第二权威，而客户端那侧才是它的归属。
- **`receiptId` 沿用 `pushId` 的 30 天 TTL**（§7） — 两者的存活上界不同轴；过期后果是重复发放（玩家白得一份），与 `pushId` 过期只降级为一次进度丢失不是同一量级。
- **后端在 `grant > redeemed` 超时后自动补发**（§7） — 等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖；对账信号归 `operations/`，只作人工入口。
- **把「读己所写」留作客户端的轮询纪律**（读到旧序号时重试 N 次）（§6） — 把一条可验收的服务端保证换成一条客户端纪律，且客户端无法区分「副本滞后」与「verify 未成功」。
- **后端主动推送新序号给客户端**（§6） — 新增一条通道与平台推送依赖，而强制 pull 已解决同一问题。

## Open questions

- **三条渠道各自的 `receipt` 内部形态与平台错误码映射** —— 三家的收据 / 凭证结构与校验协议互不相同，验票端点须逐渠道定形态。归 `06-platform-stack.md`，**属 MVP 范围内必须答结的一项**。
  **这里的「渠道」与 `auth.md` 的登录渠道不同轴**，二者不共用同一次选型：账号身份模型已定案，本条不因此解锁。**不阻塞**本文件其余部分与服务端保证（它们对渠道无差别）。
- **幂等记录的存储与冷存归档、事务边界的实现、对账与补偿任务的落点** —— 归 `06`，落 `operations/`，**不回头改契约**（与 `profile-sync.md` §12 同一条处置）。§7 的语义（永不过期）本身不依赖选型。

Source: `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md` · `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`（§3 的失败面：verify 不返回 `compliance.*`）· `handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md`（§3 渠道取值域 · §4 与 §6 读己所写 · §5 判据 · §7 收据幂等窗口）。
