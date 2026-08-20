# report — bundle-grant-ordinal-authority（**跨库**）

> worker 自身写入本文件被 harness 拦截，报告由 orchestrator 代为落盘。

- 主库 `game-design-documents/` · 对侧库 `backend-design-documents/`
- 依据构成：既有推演 9 · 通行做法 2 · 取向选择 6（客户端 3 + 后端 3）
- 写入两份草稿（front-matter 互指 `counterpart`，均 `status: awaiting-review`）；未写任何 `_index.md`。

## 主库写了什么（客户端半）
1. **裁决：保留「后端唯一 `+1`」，删客户端置位路径。** 三条独立依据（防篡改 / 时序 / 依赖方向）。关键新论据：客户端 pull 到的 profile **已带新序号**，照伪码再 `+1` 得 `n+2` —— **跳号是实现缺陷，不只是措辞冗余**。
2. **`ResourceElements` 里 `BundleGrantOrdinal` 整行撤下**，且不登记为 `CostKey` 成员 ⇒ 白嫖既有失败语义「`Key` 无对应行 → `PushError` + 整批拒绝」，把纪律换成硬闸。否决「置空 `AllowedOps`」（违反既有断言 `AllowedOps != 0`）与「标注 backend-only」（该表无「后端写入」语义位）。
3. **新增客户端写的水位字段 `PlayerEntitlement.BundleRedeemedOrdinal`**（`AllowedOps = Set`、两修正列 `null`、透明路径 `/entitlement/bundleRedeemedOrdinal`、不变式 `0 ≤ redeemed ≤ grant`）。兑现判定 = `Grant > Redeemed` 一次纯比较，跨启动 / 跨设备 / 清缓存均成立。
4. **兑现伪码改写**：`ordinal = profile.Entitlement.BundleGrantOrdinal`（直接取 pull 值），spec 的 `Elements` 改载 `BundleRedeemedOrdinal := ordinal`；闸 ③ 的「照常 +1」纪律整体迁移到水位字段。
5. **11 步完整时序表 + 逐步失败语义**；`receiptId` 本地持久化降级为「加速补查的优化」，不再承载正确性。
6. **UI 态**：复用既有阻塞屏变体 · 无硬超时永不放弃 · 待兑现期间禁用「开始新轮回」· **购买入口前置条件表加第 4 行**（无待兑现）。

## 对侧库写了什么（后端半）
1. 本库既有口径**无需改写**（`purchase.md` §2 与 `profile-sync.md` §5 封闭表已同向）；全文是**新增护栏与登记**。
2. **⚠ 发现既有漏洞 + 护栏：`/entitlement` 顶层键的回声校验（承重）。** §3a 浅合并是顶层键粒度 ⇒ 客户端提交 `entitlement` 键即**整键替换**，键内后端唯一写入的 `bundleGrantOrdinal` 会被覆写。CAS 只问基线、不问所有权，**后端写入字段封闭表的护栏此前没有任何执行点**。建议：该字段必须是回声，不等即整批拒绝（复用 `sync.conflict`）+ 风控事件。
3. **`/entitlement/bundleRedeemedOrdinal` 登记进 §5 白名单（只读 + 不变式）**，**不扩后端写入封闭表**（真值在客户端，与 `nickname` 同型）。不变式违反 → 告警台账 + 风控，**不拒绝**。
4. **verify 之后的读己所写要求**：整条链上唯一一个**无人重试**的失败点 —— 客户端 pull 读到旧序号会判「无待兑现」且不会重试，玩家静默拿不到货。建议把 §6 保证 3 升格为对读路径的一致性要求。
5. **`receiptId` 幂等窗口与 `pushId` 的 30 天 TTL 不同轴**，建议**永久保留 + 全局唯一键**。
6. 新增 4 条栈中立服务端保证（编号 5–8）。

## 台账行（两库各一行，实际表头均为 `文件 | status | 说明`）

```
| `solution-draft-bundle-grant-ordinal-authority.md` | awaiting-review | `BundleGrantOrdinal` 施加权归属（客户端侧半）：后端唯一 `+1` · `ResourceElements` 撤行 · 兑现水位字段 · 兑现时序与 UI 态。跨库，与 `backend-design-documents/inbox/` 同名草稿成对。评审 3 项取向后 `/analyze-new-ideas` |
```
```
| `solution-draft-bundle-grant-ordinal-authority.md` | awaiting-review | `bundleGrantOrdinal` 施加权归属（后端侧半）：`/entitlement` 回声校验 · 兑现水位路径登记 · 读己所写 · `receiptId` 幂等窗口。跨库，与 `game-design-documents/inbox/` 同名草稿成对。评审 3 项取向后 `/analyze-new-ideas` |
```

## 仍需用户决定（结构化）

### Q1 · `PlayerEntitlement` 是否加第二个字段 `BundleRedeemedOrdinal`（主库 · 承重 · 本题最关键）
- **问题**：后端唯一 `+1` 定案后，「这个序号兑现过没有」在云端**没有任何记录**。**`pushId` 与 `revision` CAS 都兜不住这一面** —— `pushId` 只保证同一批不被写两次，而第二次兑现是**另一批**合法变更，CAS 下两侧都不报错，玩家凭一次付款拿到 2 法则 4 古宝。反向地，待兑现态只放本地缓存则清缓存 / 重装 / 换设备后「收了钱永不给货」且线上无痕迹。
- **A 加字段（推荐）** → 1→2 字段、与承重表述张力、空迁移、两个方向同时闭合
- **B 只放本地缓存** → 保住字面、失败模式是玩家付钱永不拿到货
- **C 后端记状态 + 新增 ack 端点** → 多端点多报文、与「兑现段客户端演算」相悖、ack 自身还需幂等
- 成本 = 一个 int + 一句表述改写（建议改为「类内只放付费凭证本身与其兑现水位，不放任何派生量」）。

### Q2 · 是否新增「回声校验」这条上行拒绝条件（对侧库 · 承重）
- Q1 取 A 后，该覆写窗口从理论变成**每次兑现都走一遍**的常规路径。
- **A 不等即整批拒绝 + 风控（推荐）** → 护栏首次有执行点、§4 拒绝清单从两类变三类
- **B 只靠 CAS** → 契约零改动，但客户端 bug 在基线正确时被原样接受、两侧都不报错
- **C 只记账不拒绝** → 可观测但不阻止，后续 verify 在错位基线上继续 `+1`
- 理由：所有权越界与复算不一致不同轴；B 的失败无声且不可逆，C 观测到时损害已成。

### Q3 · 是否把「读己所写」升格为服务端一致性要求（对侧库）
- **A 升格（推荐）** → 约束栈选型、本库首次触及实现层边界
- **B 保持验收断言、交客户端轮询** → 栈自由，但客户端分不清「副本滞后」与「verify 未成功」，且它根本不会重试

### Q4 · `receiptId` 幂等记录保留期（对侧库）
- **A 永久（推荐）** → 存储只增（与购买次数同阶）
- **B 长 TTL（2 年）** → 需论证「超期重复提交不可能」，而客户端无自动放弃
- **C 沿用 30 天** → 过期后同票重复提交即**重复 `+1`**
- 理由：`pushId` 过期是一次进度丢失（已被接受），`receiptId` 过期是一次错误发放且不可发现。

### Q5 · 兑现结果屏是否设立（主库 · 轻）
- **A 设立（推荐）** → 呈现处两处变三处，须改「穷举」那句（该句约束的是**推销面**，兑现结果不是推销）
- **B 不设** → 保住字面，但玩家付款后看不到买到了什么

### Q6 · 待兑现期间是否维持「阻塞在主菜单」（主库 · 轻）
- **A 维持既定（推荐）**；**B 放宽** → `sync-service.md` 已明确否决，水位字段不改变否决理由。

## 前置依赖
- **两份草稿必须成对采纳**：只客户端加字段 ⇒ 路径未登记 + 覆写窗口在无校验下常态化；只后端登记 ⇒ 字段无写入方、恒为 0、白名单多一条死行。
- **Q2 若取 B，Q1 的 A 需重新评估**。
- 后端侧子项 5 的存储 / 归档形态依赖 `06-platform-stack.md` 选型（落 `operations/`），**语义（永不过期）不依赖选型**。

## 与既有决策的张力
1. **本题是内部相抵，且是三处而非两处（重要发现）。** 除 `open-questions` 已记的两处外，**`systems/player-profile/_index.md` 是第三处**：字段表第 14 行写「`entitlement` 写入通道 = `Elements`（`BundleGrantOrdinal` 置值）」，而**同一文件**里 `PlayerEntitlement` 的类注释写着「客户端永不自行置位」。**采纳须三处同改。**
2. 与「`PlayerEntitlement` 类内只有一个字段（承重）」直接张力（Q1）。原判据是「同一个数的三份拷贝」，水位字段**不是**拷贝（恰在待兑现时不相等）。
3. 与「允许的全部呈现穷举为两处」的字面张力（Q5），属措辞补充。
4. 与「不新增拦截点」的字面张力（轻）：第 4 条前置条件加在既有那张表里，拦截点数量不变。
5. 后端侧：`purchase.md` §5「不为购买单开更严的处置」vs Q2-A —— 判据不同（所有权 vs 复算），改写时须一并写入判据。
6. 后端侧：`profile-sync.md` §4 的拒绝清单将从两类变三类。
7. 后端侧：读己所写是本库首次对读路径提实现约束。

## 越界发现
- **`/accountInfo` 是「客户端整键替换覆写后端写入字段」的第二处同形**（含后端写的 `accountSeed` / `createdAtUtc` / `identities` 与客户端写的 `nickname`）。Q2-A 的通则措辞能覆盖它，但逐条登记哪些路径受回声校验超出本题范围，建议单独立项。
- 平台内购 SDK 工程连带（MVP 外）· `K` 与 `GrantPoolMargin` 数值 · 纯外观付费点 —— 无耦合。
- `operations/` 尚未落笔，后端草稿两处指向它。
