# 购买次数不设 StatKey 成员

- id: 2026-08-22-purchase-count-statkey
- date: 2026-08-22
- topic: systems/adventure-event/exchange | systems/services/profile-service
- status: distilled
- distilled-to: systems/adventure-event/exchange/_index.md, systems/services/profile-service.md

## Intent（distilled）

**一行摘要：不为「购买次数」新增 `StatKey` 成员；交易不产生任何统计依赖。**

Exchange 收口时留下的一条轻量待决——要不要给「购买次数」一个 `StatKey` 成员——裁定为**不设**。

### 判据（四条，全部来自既有设计）

1. **零规则消费点，且最后一条是结构性的。** 定价走「商品族 × 稀有度」表 + `PriceOffset` + 两条折扣通道；刷新价读事件级的 `RerolledCount`；残卷掷骰读 `PlayerPowerFragment.Accumulated` / `FinaleWinOrdinal` / 法则计数；礼包兑现读 `BundleGrantOrdinal` / `BundleRedeemedOrdinal`；剧本推进读 `PlotCondition` + `pastEvent` 扫描。没有一处读「购买次数」。成就发放本身是规则，而**统计计数层恒不可被任何规则读取** ⇒ 即便日后出现「累计购买 N 件」的成就，它也必须有自己的进度模型。**「为成就预留」因此不成立**。
2. **无展示落点。** 统计计数层字段的唯一合法消费方是 UI，而玩家档案 / 元婴通关证书统计区当前只列渡劫成功次数与总通关数，没有任何已定界面要求呈现购买次数。设而不展示 = 一个无消费方的字段。
3. **轮回内的那一半已经可推导。** PlotManager 今天就在读 `pastEvent` 的 `AppliedChange` 找 `Op == Grant` 且 `Source == ExchangePurchase` 的 element；再落一个字段装它即第二份真值。
4. **同形先例已被裁决。** 「篇章重试的账号级累计」在各方面同形（账号级 · 纯读数 · 成本近零 · 不可事后重建 · 无展示落点），已被明确否决并接受「需要时纯加法补」的代价。统计层新增成本近乎为零，**正因如此清单的取舍不能以「便宜」为理由**；为购买次数破例需要一条说清它凭什么比篇章重试更值得的依据，而当前没有。

### 层归属（顺带判死，不再是开放项）

「购买次数」若要设，只能落统计计数层（`StatKey`），不可能是规则字段层（`CostKey`）——判据是「这个数会被任何判定 / 闸门 / 幂等键读取吗」，答案为否，且成就一路被单向依赖纪律结构性封死。故本问题从来不是「哪一层」，而纯粹是「设不设」。

### 代价（接受，必须留在活文档里）

「你这个账号一共买过多少件东西」目前没有字段回答，且**事后无法追溯重建**——唯一的逐笔痕迹 `pastEvent` 是 `CharacterProfile` 上的轮回级字段，随轮回清理。日后若要它，只能从加上成员的那一刻起计数，历史永久归零。补的成本是三步（`PlayerStatistics` 一个只读字段 → `StatKey` 一个同名成员 → 零迁移）+ 一个采集点（每笔购买的即时 `TryApply` 上多挂一条 `StatDelta`），且成员名一经随线上存档写出即永久冻结、不可改名、不可复用。

### 连带

- 「篇章重试的账号级累计」维持既有的不设裁决；两条同形项同处置，首批统计清单保持「小而无歧义」的两项。
- 交易侧零改动：不新增字段、不新增枚举成员、不新增采集点、无存档迁移、无后端配合。

## Clarifications（interview 产物）

- **是否为「购买次数」设一个 `StatKey` 成员？** → **不设**（选项 A）。用户明确接受「账号级累计购买数事后不可重建」这条不可逆代价，并确认与「篇章重试累计」的先例保持一致处置。
  - 该裁决使草稿中两个条件项（若设则同批补回篇章重试累计 / 成员名确认 `TotalItemsPurchased`）**消解，不再是待答项**——它们仅在选「设」时成立。

## Open questions

- （无）本条已完全答定。相邻的两条 Exchange 待决项（定价表取值 · 满袋时能否购买）与本问题彼此独立，不受影响。
