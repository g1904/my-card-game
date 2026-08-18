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
| ↑ | `platform` | 枚举字符串，取值与客户端 C# 成员名逐字相同（`envelope.md` §2） |
| ↑ | `receiptId` | 平台收据唯一 id —— **幂等键** |
| ↑ | `receipt` | 平台原始收据负载（形态随**支付渠道**，待支付渠道选型） |
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

**这个端点是承重的，不是可选便利。** 客户端在「已付款、后端已 `+1`、但响应丢失」这一移动网络常态下**必须**有一条查得回来的路径；客户端据此把玩家阻塞在主菜单重试直到拿到序号（形态归客户端，见 `game-design-documents/systems/monetization.md`）。没有这条通道，那里的阻塞就变成死等。`receiptId` 由客户端随待兑现态持久化，**跨启动也能补查**。

## 5. 复算：与残卷共用同一条链，不新开

客户端兑现段用 `(accountSeed, stream = PremiumBundle, ordinal = bundleGrantOrdinal)` 掷骰抽 3 条，后端以同一三元组复算——**这正是 `profile-sync.md` §6 已定义的 SplitMix64**（`PremiumBundle = 1` 已在那里冻结）。**本契约不定义任何新的随机源**，只回链。

复算不一致的处置**沿用 §7a**（接受写入 + 打风控事件，不拒绝、不改写），不为购买单开更严的处置：兑现段的条目是客户端从池里抽的，与残卷同构；真正需要严格把关的是**验票**那一步，而它由平台校验兜住。

## 6. 服务端保证（栈中立的验收断言）

1. 同一 `receiptId` 提交 N 次，`bundleGrantOrdinal` 恰好 `+1`；第 2..N 次回 `deduplicated = true` 且序号与第 1 次逐位相同。
2. `bundleGrantOrdinal` 与 `revision` 的自增**要么都发生、要么都不发生**。
3. verify 通过后立即 `GET /v1/profile/pull`，读到的 `/entitlement/bundleGrantOrdinal` 与 verify 应答一致。
4. `bundleGrantOrdinal` 账号级**严格单调递增、不清零**（与 `finaleWinOrdinal` 同一条纪律）。

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

## Open questions

- **`receipt` 字段的内部形态与平台错误码映射** —— 待**支付渠道**（应用商店 / 平台 IAP）选型，归 `06-platform-stack.md`。
  **这里的「渠道」与 `auth.md` 的登录渠道不同轴**，二者不共用同一次选型：账号身份模型已定案，本条不因此解锁。**不阻塞**本文件其余部分与四条服务端保证（它们与渠道无关）。
- **幂等记录的存储、事务边界的实现、对账与补偿任务的落点** —— 归 `06`，落 `operations/`，**不回头改契约**（与 `profile-sync.md` §12 同一条处置）。

Source: `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md` · `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`（§3 的失败面：verify 不返回 `compliance.*`）。
