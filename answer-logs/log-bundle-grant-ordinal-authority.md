# Answer log bundle-grant-ordinal-authority

- 日期：2026-08-19
- 来源：`inbox/solution-draft-bundle-grant-ordinal-authority.md` → `handoffs/2026-08-19-bundle-grant-ordinal-authority.md`
- 移出条数：1（另有 1 条部分答定）

**`monetization.md` 内部相抵——`BundleGrantOrdinal` 究竟由谁施加（承重）** → **只能由后端**：客户端整条置位路径撤下，`ResourceElements` 里 `BundleGrantOrdinal` 整行删除、不登记为 `CostKey` 成员（缺行即「必需缺失 → `PushError` + 整批拒绝」，成为机械硬闸）。兑现幂等改由客户端写的水位字段 `PlayerEntitlement.BundleRedeemedOrdinal` 承载（`Grant > Redeemed ⟺ 有待兑现`，兑现按 `ordinal = Redeemed + 1` 逐一循环追平）。原先三处相抵（`monetization.md` 伪码 / 同文档购买段 / `player-profile/_index.md` 字段表第 14 行）已同批改齐。
（归档去向：`systems/monetization.md`、`systems/services/profile-service.md`、`systems/player-profile/_index.md`、`systems/services/sync-service.md`）

**纯外观付费点是否真做、做成什么（轻）** → **部分答定**：「是否真做」已答——**架构预留、首批不做**（未来会做；落地时 = `PlayerEntitlement` 加一个具名字段 + bump 一次 schema，不需要新机制；首批不新增字段、不新增屏）。**「做成什么」仍留在待答清单**（角色皮肤 / 卡背 / 界面主题的哪些、字段落成什么形状）。
（归档去向：`systems/monetization.md`）

## 同批答定的相邻项（原不在待答清单上）

- **平台内购 SDK 的工程连带** → **三渠道（Google Play Billing / App Store / 微信支付）纳入 MVP**，`vision/scope.md` 的商业化行按此改写（只挪「支付接入 + 商店 UI」，地区定价留在范围外）。SDK 选型 / 封装层归后端支付渠道选型与一次专门的客户端工程蓝图。
- **购后等待态的载体** → Store 流程内的**全屏模态进度态**，不进阻塞屏变体表；`BlockingNoticeKind` 与「硬阻塞只有两处、只由已知 `code` 触发」原样不动。
- **兑现结果屏的落点** → **Store 屏的一个结果态**，屏清单不变。
- **`BundleRedeemedOrdinal` 的读档校验** → `< 0` 钳到 `0`，`> Grant` 钳到 `Grant`。
- **后端回声校验的客户端侧承接** → 上行组装 `entitlement` 键时原样回声 pull 下来的 `bundleGrantOrdinal`，客户端永不自行赋值；该情形的 `Conflict` 复用既有处置，不新增分支。规则权威在 `backend-design-documents/contracts/profile-sync.md`。
