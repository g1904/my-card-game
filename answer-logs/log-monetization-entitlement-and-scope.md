# Answer log monetization-entitlement-and-scope

- 日期：2026-08-15
- 来源：`inbox/archive/solution-draft-monetization-entitlement-and-scope.md` → `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md`
- 移出条数：3（另有 1 条口径收窄、1 条新增，见文末）

## 逐条

**premium bundle 的其余细则（一次性还是可重复购买 / ③ ④ 如何叠加 / 定价与地区 / 是否还有其他付费点、明确排除哪些）** → **可重复购买；① ② 每次都给，③ ④ 只在首次生效、不叠加**（叠加会抹平 ADR-0004 唯一的失败压力线；08-12e 的闸 ② 只有在可重复形态下才有真实意义）。**定价起步单一 SKU、单一价格档，金额不落客户端**（由平台商店按 SKU 返回）。**付费面五项明确排除**：付费续命 / 复活 · 抽卡扭蛋 · 消耗型货币 · 体力与付费加速 · 广告变现；**唯一预留方向 = 纯外观**（不定案，只标为「不排除」）；**通行证 / 赛季当前不做**（须先有赛季结构）。第二次起的购买 UI **必须在付款前**如实标注删减。（归档去向：`systems/monetization.md` 的 `## 意图` + `## 决策`；重试两档表落 `systems/balance.md`）

**礼包持有状态的存档表达与服务端权威（连带 `BundleGrantOrdinal` 的落点）** → **落 `PlayerProfile.entitlement: PlayerEntitlement`，类内只有 `BundleGrantOrdinal` 一个字段**（规则字段层 · 严格同步 · 后端可复算 · 客户端永不自行置位；`> 0 ⟺ 已购买`，不设第二个布尔 / 计数字段）。**否决 `CapabilityFlag` 与 modifier pipeline**——两者都是由内容条目聚合出的派生态、且受 08-10c 的轮回级禁用截断，而付费凭证是账号上的原始事实、必须是硬状态。**服务端权威 = 购买段后端 +1、兑现段客户端掷骰后端复算**，并立一条时机纪律「**购买只能在主菜单发起且待发队列为空**」以关闭「后端主动写入 ⇒ CAS `Conflict` ⇒ 丢弃本地缓冲」的窗口。**存档 schema bump 一次、空迁移**；后端 `contracts/profile-sync.md` §5 预留行按同形态补入。（归档去向：`systems/player-profile/_index.md`、`systems/services/profile-service.md`、`systems/services/sync-service.md`、`systems/services/life-cycle-service.md`、`systems/monetization.md`）

**商业化的 UX 观感（入口放在哪 / 是否在重试次数耗尽时提示购买）** → **主菜单的一等入口、排在既有四项之后、安静呈现**（藏进二级面板会因曝光不足诱导出弹窗红点等补偿手段，那才是「付费才玩得下去」观感的真正来源）+ 三条纪律（永不带红点角标促销倒计时 · 全游戏无第二条通往付费流程的路径 · 已购买后不隐藏）。**重试耗尽时提示购买：明确否决**——情绪最低点推销 + **结构上本就不可行**（购买只在主菜单发起）。**入口不可用时置灰 + 说明、不隐藏**，并立灰态判据「适用于必然无结果的操作，不适用于玩家可能有意选择的失败」（与 08-06c 的不设灰态并不冲突）。新增翻译键分区 `STORE_` / `store.csv`。（归档去向：`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`）

## 未随本次关闭

- **`GrantPoolMargin`**：只收窄口径（「支撑 K 次重复购买 + 第 K+1 次的缓冲」），**`K` 与数值仍开放**，留在 `open-questions/07-codex-monetization.md`。
- **新增 1 条**：`Elements` 是否一律走 modifier pipeline 的通则（本次只定下 `BundleGrantOrdinal` 的个案豁免）→ 同分片。
- **新增 1 条**：纯外观付费点是否真做、做成什么 → 同分片。
- **`IPurchaseBackend`**：本次不新增接口，只在 `systems/architecture.md` 总则 7 与 `system-overview.md` 预先声明清单 5 → 6；实际裁决留到商业化落地时。
- **全部后端侧事项**（验票与订单幂等 / 后端主动 +1 的写入语义 / `PremiumBundle` 域复算白名单 / 跨设备重复到账 / 实名与退款）——须另跑一次 `/analyze-new-ideas --lib=backend`，本次未写入后端库。
