# ADR-0098 — 只有法宝可售、古宝不可售；售出两条通道、回收率两档，随售档恒劣于商店档

- **状态：** Accepted
- **日期：** 2026-08-26
- **来源：** handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md

## 背景

储物袋成为跨两层的视图后（→ `ADR-0097`），袋内同时有轮回级法宝与账号级古宝。「卖掉」这个操作因此要先回答：卖哪些？

同时，售出此前只有 Exchange 商店一条通道，而袋内直接随手卖是玩家的自然预期。

## 决策

**售出面仅对 `CharacterItem` 开放**——判据直接复用**代码级常量**：可售出 ⟺ `ExchangeGoodsKind == CharacterItem`，**不加第二条件、不另立族白名单**。**古宝不可售**，其唯一退出通道仍是置换。

**售出有两条通道**：Exchange **商店内售出**（权威 `exchange/`）与**储物袋随售**（权威 `character-profile/item/`）。

**回收率分两档，两者互不作缺省**：商店档 `SellRatePercent`（逐条目字段）· 随售档 `PackSellRatePercent`（全局平衡资源单值）。相对关系是**结构性约束**，由**加载期硬校验**固定：`SellEnabled == true` 且 `SellRatePercent <= PackSellRatePercent` → `PushError`。

两档折算基准同为「族 × 稀有度」定价表基准价，**同币回收**（→ `ADR-0089`）。

新增 **`Source.PackSell`**（code 9），合法子集表只对 `(Item, Character)` 的 `Remove` 开；它进 `TryApply` 日志与客服溯源、**不进存档**。

→ `systems/character-profile/item/_index.md` · `systems/adventure-event/exchange/` · `systems/common-properties.md`（`Source` 枚举唯一权威）· `systems/balance.md`（两个数值格）。

## 理由

古宝不可售：用**账号级资产兑换轮回级货币**会使「开局清仓换经济」成为最优解，且与「避免第二套账号级经济」相抵。

两档的意义**不是**「保住跑一趟商店的规划价值」——Exchange 大部分并不提供回收，**随售才是常态的弃置途径**，提供收购的商店是**罕见的更优机会**。低回收率的作用是让**清仓不构成经济来源**。

相对关系做成加载期硬校验而非编排口径：两值都在加载期可得、可机械比较，停在纪律阶梯的可执行级（→ `ADR-0013`）。

`Source.PackSell` 不复用 `ExchangeSell`：复用会让「购买次数」这类统计永远算不准，且痕迹会指向一个不存在的事件。

## 备选方案

- **允许卖古宝** — 否决：开局清仓换经济成为最优解。
- **两档相对关系做成内容编排口径（只报告）** — 否决：改为加载期 `PushError`。
- **随售换取基础货币灵石** — 推翻：与折算机制自相矛盾，改同币回收。
- **复用 `Source.ExchangeSell`** — 否决：统计失准且痕迹指向不存在的事件。

## 后果

- `SellEnabled` 首批以 `false` 为常态（内容编排口径）。
- **`PackSell` 不进存档、事后不可重建**——随售无 `PastEventEntry` 可挂、又不落 `SourceCode`，代价明写接受。
- 「`ExchangeSell` 是唯一一个只出现在 `Op == Remove` 上的成员」两处改为**两个成员**。
- 同币回收使仙玉出现净产出敞口，量级归统计校准（→ `ADR-0089`）。
