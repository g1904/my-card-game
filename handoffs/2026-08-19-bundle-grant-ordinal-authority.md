# premium bundle 的序号施加权与兑现水位

- id: 2026-08-19-bundle-grant-ordinal-authority
- date: 2026-08-19
- topic: systems/monetization · systems/services/profile-service · systems/player-profile · systems/services/sync-service · ux/error-and-blocking-ux · ux/screen-flow · vision/scope
- status: distilled
- distilled-to: systems/monetization.md, systems/services/profile-service.md, systems/player-profile/_index.md, systems/services/sync-service.md, ux/error-and-blocking-ux.md, ux/screen-flow.md, vision/scope.md

## Intent（distilled）

### 1. `BundleGrantOrdinal` 的施加权收口为「后端唯一 +1」

客户端**不存在**推进该序号的路径。三条各自独立的依据同向：**防篡改**（客户端置位 = 客户端有权发货，事后发现不一致时玩家已拿到东西，回收比不发更糟）；**时序**（后端在验票事务内把 `bundleGrantOrdinal` 与 `cloudRevision` 各 +1，客户端强制 pull 拿到的 profile 已带新序号，此刻再算一次 `+1` 得到 `n+2` ⇒ 跳号 ⇒ 掷骰序列错位，且下一次购买的后端 `+1` 在 CAS 下表现为「云端落后于本地」的不可能态）；**依赖方向**（`AccountRng` 的 `ordinal` 是输入不是输出，序号来源是 pull 下行）。

**连带：`ResourceElements` 里 `BundleGrantOrdinal` 整行撤下**，且不登记为 `CostKey` 成员。由此白得一条硬闸——既有失败语义「`ChangeElement.Key` 在 `ResourceElements` 中无对应行 → `PushError` + 整批拒绝」使任何日后误写的客户端置位当场大声失败。这比「保留该行 + 注释说别用」强一个量级：后者是纪律，前者是机械保证。

### 2. 兑现幂等落在一个客户端写的水位字段 `BundleRedeemedOrdinal`

关掉客户端写 `BundleGrantOrdinal` 之后，「这个序号兑现过没有」在云端没有任何记录——这是整条链上唯一未被兜住的重复面（同票重复 verify 由后端收据幂等兜、同批重复上行由 `pushId` 兜、多设备并发写由 `revision` CAS 兜）。`pushId` 与 CAS 都兜不住它：第二次兑现是**另一批**变更、另一个 `pushId`，在 CAS 下是一次完全合法的推进，两侧都不报错，玩家凭一次付款拿到两份货。

反向的失败模式同样存在：待兑现态**只**放 `user://cache/` 时，卸载重装 / 清缓存 / 换设备后该状态消失而云端序号已 +1 ⇒ 收了钱永不给货，且线上无痕迹。

故 `PlayerEntitlement` 加第二个字段 `BundleRedeemedOrdinal`（客户端写、只在兑现事务内置为本次 ordinal，`0` = 从未兑现）。不变式 `0 ≤ Redeemed ≤ Grant`，`Grant > Redeemed ⟺ 有待兑现`。它不是 `BundleGrantOrdinal` 的拷贝——两者恰在存在待兑现购买时不相等，这个差值正是它承载的信息。

### 3. 兑现事务：`ordinal = Redeemed + 1` 的循环

```
// 触发点：主菜单，pull 完成之后
while (profile.Entitlement.BundleGrantOrdinal > profile.Entitlement.BundleRedeemedOrdinal)
{
    ordinal = profile.Entitlement.BundleRedeemedOrdinal + 1
    rng     = AccountRng.For(AccountStream.PremiumBundle, ordinal)
    picked  = TryPickGrantable(Power, Player, rng) + TryPickGrantableMany(Item, Player, rng, 2)
    spec    = { Elements:        [ BundleRedeemedOrdinal := ordinal ],
                AbilityElements: [ Grant(picked…, Source.PremiumBundle) ] }
    ProfileManager.TryApply(spec)      // 全有或全无，一次事务
    → Push(SavePointReason.MetaChanged, PushPolicy.Immediate)
}
```

差值为 1 时与「直接取 `Grant`」逐字等价；差值 > 1 时逐一按序兑现，每个 ordinal 一次独立 `TryApply`，`AccountRng` 的 `(域, 序号)` 逐次对位得以保住。**差值 > 1 属异常**（`PushError` + 上报），但它可发生：不变式 `Grant - Redeemed ≤ 1` 只由购买入口的前置条件维持，而那条读的是本地 pull 快照，挡不住两台设备各自付款。

「序号自增与是否抽中无关」这条纪律**整体迁移到水位字段**：闸 ③ 真发生时该项计未兑现、不补发，但 `BundleRedeemedOrdinal` 照常置为 `ordinal`——否则客户端永远认为自己欠一次兑现，每次启动重掷同一 `ordinal`、抽空池、反复报错。

### 4. 购后等待态是 Store 流程内的全屏模态进度态，不是第四个阻塞变体

行为不变：验票 / pull 未回期间不可继续游玩、不允许开始新轮回，允许退出应用，无硬超时、永不放弃。但它**不进 `BlockingNoticeScreen` 的变体表**——硬阻塞的既有判据是「只由已知 `code` 触发」，而购买处理态是客户端自己的等待态、有自愈路径，恰好被该判据排除在外。文案走 `STORE_` 分区。

**兑现结果屏 = Store 屏的一个结果态**（同屏切态，屏数不变），列出本次获得的 1 法则 + 2 古宝。

### 5. 回声校验的客户端侧承接

客户端 diff 语义是「顶层键出现即整键替换」⇒ 每一次兑现 push 都会提交 `entitlement` 整键，因而每次兑现都会走一遍后端的回声校验。客户端侧的义务是：上行组装 `entitlement` 键时**原样回声** pull 下来的 `bundleGrantOrdinal`，永不自行赋值；收到该情形的 `sync.conflict` 时复用既有 Conflict 处置（以云端为准、丢弃本地缓冲、重新 pull），不新增分支。校验规则与拒绝语义的权威在 `backend-design-documents/contracts/profile-sync.md`，本库不复述。

### 6. 相邻定案

- **平台内购 SDK 纳入 MVP**：Google Play Billing · App Store（StoreKit）· 微信支付三渠道，连同 Godot 导出配置与各平台构建。SDK 选型 / 封装层 / 三渠道收据差异归后端的支付渠道选型与一次专门的客户端工程蓝图。对本方案的实质影响为零——时序第 2 步的失败语义（用户取消 / SDK 失败 → 回主菜单，无任何 Profile 变更，无痕迹）逐字不变。
- **纯外观付费点**：架构预留、首批不做。首批不新增任何字段、不新增任何屏；落地时 = `PlayerEntitlement` 加一个具名字段 + bump 一次 schema。
- `K` 与 `GrantPoolMargin` 的数值仍待内容规模明朗，不阻塞。

## Clarifications（interview 产物）

- **购后等待态的载体？** → **做成 Store 流程内的全屏模态进度态，不进阻塞变体表、不碰 `BlockingNoticeKind` 三成员**。这推翻了原始输入子项 6「呈现**既有阻塞屏的一个变体**」那一句；「硬阻塞只有两处、永不得新增第三处」与「只由已知 `code` 触发」原样成立。行为定案（不允许提前离开）不变。
- **兑现伪码取 `Grant` 还是循环？** → **改为 `ordinal = Redeemed + 1` 的循环，直到追平 `Grant`**。这推翻了原始输入子项 4 伪码首行「`ordinal = profile.Entitlement.BundleGrantOrdinal` ← 直接取 pull 下来的值」。理由：差值 ≤ 1 的不变式只保证单设备，两台设备各自付款可使差值为 2，按原伪码会付两次拿一份。
- **字段表第 14 行的写入通道怎么写？** → **照第 1 行 `accountInfo` 的既有写法**：后端写哪几项 / 客户端写哪几项分开写。这推翻了原始输入子项 2 末条「改为**后端写入 · 无客户端写入通道**」——`BundleRedeemedOrdinal` 正是客户端经 `Elements` 写入，照原文落笔会制造第三处相抵。
- **后端已定案的回声校验在客户端侧零承接？** → **补上承接**（上行原样回声、`sync.conflict` 复用既有处置），**只写客户端侧的承接与回链，绝不复述后端语义**。这是原始输入全文未提的一处跨边界缺口。
- **兑现结果屏落在哪？** → **Store 屏的一个结果态**（同屏切态，屏数不变），`ux/screen-flow.md` 的 Store 行补一句；待兑现期主菜单「开始新轮回」禁用的灰态一并写进该文件。
- **`BundleRedeemedOrdinal` 的读档校验？** → **`< 0` 钳到 `0`；`> Grant` 钳到 `Grant`**（判定为「无待兑现」）。偏向不重复发放；坏档下最坏是少发一次，且有后端对账信号可查。
- **`vision/scope.md` 的改写幅度？** → **只把「支付接入 + 商店 UI」移进 MVP，地区定价留在范围外**（定价由平台商店按 SKU 返回，客户端不硬编码金额）。
- **后端半怎么办？** → 后端 counterpart 走它自己的一次运行；**本次不写后端库任何文件**，客户端侧只回链、不复述。

## Open questions

- **纯外观付费点做成什么。** 「做且推后」已定，但做成角色皮肤 / 卡背 / 界面主题的哪些、字段落成什么形状仍未定。
- **`K` 与 `GrantPoolMargin` 的取值。** 结构已定、数值待内容规模明朗。
- **平台内购 SDK 的选型与封装层形态。** 纳入 MVP 已定，具体形态归后端支付渠道选型与一次专门的客户端工程蓝图。

## Notes / triage

原始输入：`inbox/solution-draft-bundle-grant-ordinal-authority.md`（`status: decided`）。
后端 counterpart：`backend-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md`——**成对采纳是硬要求**（只客户端加字段则该路径不在后端白名单内、后端无法校验不变式；只后端登记则字段无写入方、恒为 0）。
