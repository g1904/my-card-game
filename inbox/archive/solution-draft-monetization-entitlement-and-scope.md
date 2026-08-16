---
type: solution-draft
date: 2026-08-15
question: premium bundle 的持有状态如何落存档并保持服务端权威；购买形态（一次性 / 可重复、③④ 是否叠加）；还有哪些付费点、明确排除哪些；商业化的 UX 观感落点
source: open-questions/07-codex-monetization.md → 「premium bundle 的其余细则」「礼包持有状态的存档表达与服务端权威」「商业化的 UX 观感」（并牵动「授予池编排余量 GrantPoolMargin」）
targets: systems/monetization.md, systems/player-profile/_index.md, systems/services/profile-service.md, systems/services/sync-service.md, systems/services/life-cycle-service.md, systems/architecture.md, ux/screen-flow.md, ux/error-and-blocking-ux.md, systems/balance.md
status: distilled
decided: 2026-08-15
reviewed: 2026-08-15 —— 用户全部采纳推荐项（五处 `[取向选择]` + 一处「与既有决策的张力」，逐条见文末「已裁决」）
distilled-to: handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md
---

# 方案草稿 — 商业化整体：持有状态的存档表达 · 购买形态 · 付费面边界 · UX 观感

> **⚖ 已裁决（2026-08-15）：用户全部采纳推荐项。** 五处 `[取向选择]` 与那一条张力的结论见文末「已裁决」；正文中的推荐即定案内容，可直接交给 `/analyze-new-ideas` 提炼。

## 问题

`systems/monetization.md` 的「待决问题」有五条，除「合规」归后端外，其余四条彼此咬合、无法单独答定：

1. **持有状态的存档表达**（连带 `BundleGrantOrdinal` 的落点）—— 落成 `CapabilityFlag`、modifier pipeline 的具名修正，还是独立的 `Entitlement` 字段？它同时是一条需服务端权威的客户端 ↔ 后端契约。**存档 schema 卡在这一条上不能 bump**，后端 `contracts/profile-sync.md` §5 的白名单也为它预留了一行空着。
2. **购买形态** —— 一次性还是可重复？可重复则 ③ ④（重试上限 3→9 / 1→3）如何叠加？
3. **是否还有其他付费点**，以及「明确不做哪些」。
4. **UX 观感** —— 入口放在哪、是否在重试次数耗尽时提示购买。

四条咬合处：② 的答案决定 ① 的字段是布尔还是计数、也决定闸 ① 余量的口径；① 的服务端权威路径决定 ④ 的购买入口能在**什么时机**出现（这一条既有讨论未触及，见「建议方案 §1.4」）。

## 约束（来自既有设计）

- **礼包四项内容已定案**：随机 1 PlayerPower · 随机 2 PlayerItem · 第二篇章重试 3→9 · 第三篇章重试 1→3。第一篇章重试本就无限。（`systems/monetization.md`）
- **重试上限是元进程难度的主要旋钮，且有两档**；平衡须以**免费档**为「游戏应当可通关」的基准，**付费档是宽松化而非必需品**。（同上；`decisions/ADR-0004`）
- **付费获得的内容不会被游戏销毁**（08-06b）；已授予的不被拿走，未授予的不被吞掉（08-12e 的三道闸）。
- **抽取口径已定案**（08-12e）：`AccountRng.For(AccountStream.PremiumBundle, BundleGrantOrdinal)` 一次派生连续抽 3 条，排除已持有、排除成就限定、按 `RarityTier` 加权、②的两件无放回。**`BundleGrantOrdinal` 的形状已定**（账号级 · 单调递增 · 不清零 · 随授予事务同一次持久化），**只差落点**。
- **`AccountStream.PremiumBundle = 1` 已冻结进后端契约**（`backend-design-documents/contracts/profile-sync.md` §5）；本方案不改任何已冻结形状。
- **账号级字段分两层**，判据是「有没有被规则读」（`systems/player-profile/_index.md` 通则）；命名硬约定：后缀 `Ordinal` ⇒ 规则字段层。
- **单一真值纪律**：`x` 不落字段、统计侧不设「Finale 胜利数」而直读 `FinaleWinOrdinal`——**能派生的就不落第二个字段**。
- **本作没有账号级可支配货币**，且明确否决「为兜底引入一条等于新开一套经济」。（08-12e 的否决记录）
- **云端权威 + CAS + `pushId` 幂等**：`revision` 由后端分配，`baseRevision < cloudRevision` ⇒ 客户端**丢弃本地缓冲**。（`systems/services/sync-service.md`）
- **后端接口化：三个窄接口**，`OfflineXxxBackend` 整类 `#if DEBUG`，**条件编译清单穷举 5 处、不得扩张**。（`systems/architecture.md` 总则 7）
- **商业化的落地不属 MVP**（`vision/scope.md`「范围之外（暂时）」明列支付接入 / 商店 UI / 地区定价）。
- **UI 文案一律走翻译键**，分区表是开放表、可随屏幕落地增补。（`ux/error-and-blocking-ux.md`）

---

## 建议方案

### 1. 持有状态 = `PlayerProfile` 上的独立具名小类 `PlayerEntitlement`

#### 1.1 否决另外两个候选（`[既有推演]`）

| 候选 | 否决理由 |
|---|---|
| **`CapabilityFlag`** | ① 它的**唯一授予源是 PlayerPower 条目**，礼包没有宿主条目；② 它是**布尔呈现开关**，而 ③ ④ 要的是数值；③ **致命**：生效能力集受 08-10c 的轮回级禁用截断（`CharacterProfile.disabledAbility` 是第三条与门），而付费权益**必须不可被任何事件影响**——把付费凭证放进一个设计上就允许被截断的聚合面，是在结构上给「花钱买的东西被事件拿走」留了后门 |
| **modifier pipeline 的具名修正** | 同上第 ③ 条（modifier 表与能力集由同一个 `CapabilityManager` 聚合、受同一条截断）；且 modifier 的定位是**法则对数值的软修正**——让一条法则与一份付费凭证写同一张表，等于承认「法则可以改写付费权益」。付费凭证必须是**硬状态**：不参与 pipeline、后端可复算 |

**共同的判据**：capability / modifier 两条通道都是**由内容条目聚合出来的派生态**；付费凭证是**账号上的原始事实**。派生态不能承载原始事实。

#### 1.2 字段形态：只有一个字段（`[既有推演]`）

```csharp
public sealed class PlayerEntitlement    // 规则字段层：严格同步 · 后端可复算 · 客户端永不自行置位
{
    public int BundleGrantOrdinal { get; }   // 账号级礼包授予序号；单调递增、不清零；0 = 从未购买
}
```

**不设第二个字段 `HasPremiumBundle` / `PremiumBundleCount`。** 三者是同一个数的三份拷贝：

- `HasPremiumBundle ⟺ BundleGrantOrdinal > 0`（一次带判断的派生读取，与 `x` 是「对 `List<PlayerPower>` 的一次带过滤计数」同构）；
- 采可重复购买时（见 §2），`BundleGrantOrdinal` **就是**购买次数，`PremiumBundleCount` 与它恒等。

这正是既定的**合并判据**与 `FinaleWinOrdinal` 先例所指的形态：「统计侧不设 Finale 胜利数字段，展示直读 `FinaleWinOrdinal`」——**让重复字段从一开始就不存在**，比任何注释可靠。命名亦合规（`Ordinal` 后缀 ⇒ 规则字段层；类内不出现 `Total` / `Count`）。

**为何是具名字段而不是 `List<EntitlementKind>` 或字符串集合：** 与「`CapabilityFlag` 用 `enum` 而非字符串 key」同一条纪律；且付费点数量在本作被刻意限窄（见 §3），一个可扩展集合的成本高于收益。日后真新增第二个付费点 = 本类加一个具名字段 + bump 一次 schema。

**不落客户端的东西（明确否决）：** 订单号 / 平台 SKU / 收据 / 购买时间 / 金额。它们是**审计凭证**，权威在后端；落到客户端存档既不可信（客户端可改），又会诱导出「客户端拿订单号做判断」的写法。客服排障已有既定出口（设置屏的「同步版本 #N」+ 后端订单库）。

#### 1.3 一次授予 = 一次 `TryApply`（`[既有推演]`）

```
ordinal = profile.Entitlement.BundleGrantOrdinal + 1     ← 先取「本次」的序号
rng     = AccountRng.For(AccountStream.PremiumBundle, ordinal)
picked  = TryPickGrantable(Power, Player, rng) + TryPickGrantableMany(Item, Player, rng, 2)
spec    = { Elements:        [ BundleGrantOrdinal := ordinal ],
            AbilityElements: [ Grant(picked…, Source.PremiumBundle) ] }
ProfileManager.TryApply(spec)                            ← 全有或全无，一次事务
```

- **序号从 1 起，先算后写**——`AccountRng` 的 `ordinal` 必须是「本次授予」的序号；随机在 **spec 组装之前掷完**（既定纪律：`AbilityChangeElement` 只承载已定稿的 `Id`）。
- **序号的自增与「是否抽中」无关。** 闸 ③ 真发生时（理论不可达），该项计未兑现、不补发，但 `BundleGrantOrdinal` **照常 +1**——否则下一次购买会复用同一个 `ordinal`，掷出完全相同的序列，幂等键当场失效。
- **`BundleGrantOrdinal` 这条 element 必须显式排除在 modifier pipeline 之外**（`[既有推演]`，与统计层「绝不经过 pipeline，否则一条法则能改写统计数字」同一条理由，只是后果严重得多：经 pipeline = 一条法则能改写付费凭证）。⚠ 这触及一处未收口的口径，见「前置依赖」。

#### 1.4 服务端权威：购买写在云端，兑现在客户端，且**只在主菜单发生**（`[既有推演]` + `[通行做法]`）

既定架构已经指定了一半答案：`AccountSeed` 在后端、**客户端掷骰 · 后端可复算**（残卷先例，礼包共用同一机制）。剩下的一半是「谁有权把 `BundleGrantOrdinal` 从 n 推到 n+1」——**只能是后端**，否则整套防篡改归零。由此把一次购买拆成两段：

| 段 | 谁做 | 内容 |
|---|---|---|
| **① 购买段（后端权威）** | 平台 SDK + 后端 | 客户端唤起平台内购 → 得到收据 → 上行后端验票 → **后端**把云端 `bundleGrantOrdinal` +1、`cloudRevision` +1 |
| **② 兑现段（客户端演算 · 后端复算）** | 客户端 | 客户端 **pull** 到新序号 → 用 `(PremiumBundle, ordinal)` 掷骰抽 3 条 → 一次 `TryApply` → `Immediate` push；后端以同一 `(AccountSeed, stream, ordinal)` 复算校验 |

**⚠ 这引入了现有同步模型没有的第四种情形：后端主动写入。** 它会让 `cloudRevision` 领先客户端的 `baseRevision`，而既定的 CAS 三分支表对这种情形的判定是 `Conflict` ⇒ **以云端为准丢弃本地缓冲**。若购买发生在轮回中途，被丢掉的正是玩家刚打完的战斗——直接违反「绝不回退存档点」。

**解法不需要任何新机制，只需要一条时机纪律：**

> **购买流程只能在主菜单（轮回外）发起，且进入付费流程前待发队列必须为空。**

- 主菜单处无进行中的轮回变更，待发队列应为空；若非空（上一轮回的残留 / 断线缓冲）→ **先 `FlushPendingAsync` 成功才允许进入付费流程**，这与既有的闸 ②（「购买入口不可用」）合并为**同一张前置条件表**，不新增拦截点。
- 购买成功后**强制一次 pull**（而非等下一次启动），拿到新 `revision` 与新序号，再本地兑现。
- 于是「后端主动写」的冲突窗口在结构上被关闭：那一刻客户端没有任何未上行的变更，`Conflict` 分支不可能踩到。

**这条纪律同时回答了 UX 的一半**（见 §4）：礼包入口在轮回内 / 战斗内 / 结算流程内**不存在**——这不是观感取舍，是同步模型的结构要求。两条独立理由指向同一答案，是本方案里最强的一处推演。

**闸 ② 的前置条件表（合并后）：**

| # | 条件 | 不满足时 |
|---|---|---|
| 1 | 当前在主菜单（不在任何轮回内） | 入口不渲染 |
| 2 | 待发队列为空（或一次 flush 成功） | 入口置灰 + 「请先完成同步」 |
| 3 | `GrantableCount(Power, Player) ≥ 1` 且 `GrantableCount(Item, Player) ≥ 2` | 入口置灰 + 说明 + `PushError` + 上报（既定闸 ②） |

#### 1.5 重试上限的读取面（`[既有推演]`）

- profile-service 增一个只读属性 **`bool HasPremiumBundle { get; }`**（`=> Entitlement.BundleGrantOrdinal > 0`），形态 A、单点查询——与 `Has(CapabilityFlag)` / `SyncService.UpgradeRequired` / `PendingCount` 同构（**不塞进任何事件负载**）。
- **上限表本身是数据不是常量**：两档「无限 / 3 / 1」与「无限 / 9 / 3」落 `systems/balance.md` 的平衡资源，由 life-cycle-service 读 `HasPremiumBundle` 选行。这满足既定的「重试上限首次成为可变量，凡读取处都要经这一层，不能硬编码常量」。

#### 1.6 存档 schema 影响

`PlayerProfile.entitlement: PlayerEntitlement`（1 字段）⇒ **bump 一次，空迁移**（老档缺字段 → `BundleGrantOrdinal = 0` = 未购买，无损）。当前无线上存档，走既有 MigrationManager 骨架。**后端 `profile-sync.md` §5 预留的那一行按同形态补入**（`bundleGrantOrdinal`，规则字段层 · 严格同步 · 后端可复算），不改任何已定形状。

---

### 2. 购买形态：可重复购买；① ② 每次都给，③ ④ 只在首次生效

`[取向选择]`（有强推荐）

| 选项 | 后果 |
|---|---|
| **A. 一次性，不可重复** | 商业化封顶为一次性小额；与「重账号 + 强制在线 + 长期运营」的既定路线（参考三国杀 Online）不匹配；且让 08-12e 的闸 ② 几乎永无用武之地 |
| **B. 可重复；③ ④ 只首次生效（推荐）** | ① ② 可持续购买、③ ④ 不叠加；LTV 有上限但存在；元进程压力线不被钱抹平 |
| **C. 可重复；③ ④ 叠加** | 花钱买接近无限的重试 ⇒ **直接抹平 ADR-0004 唯一的失败压力线**，与「免费档是基准、付费是宽松化而非必需品」正面冲突。**明确否决** |

**推荐 B，两条依据：**

- `[既有推演]` **08-12e 已经在为重复购买铺路而不自知**：它明写「按排重，**第二次礼包**不可能给到与第一次相同的条目」，并为「池不足」设了闸 ②——而一次性购买几乎不可能抽干通用池，**闸 ② 的存在本身只有在可重复形态下才有真实意义**。既有设计的两处细节都指向 B。
- `[既有推演]` ③ ④ 不叠加，理由已由 `monetization.md` 自己写好：重试上限是**元进程难度的主要旋钮**，两档（免费 / 付费）是有意的口径变化；第三档、第四档就不是了。

**落地约束（承重的诚实性纪律）：** 第二次及以后的购买，**UI 必须在付款前如实标注「本次仅含随机 1 法则 + 2 古宝；重试上限已达上限，不再提升」**。付了钱却没拿到宣传的四项之二，是退款争议的标准形态——与 08-12e「把失败点挪到掏钱之前」是同一条纪律。

**定价与地区** `[取向选择]` —— 不推演，且它**不落客户端**：价格与货币由平台商店按 SKU 返回，客户端不硬编码任何金额。建议起步只做**单一 SKU、单一价格档**：多档 SKU 会立刻牵出「哪档给什么」的内容编排，而当前内容池规模尚未明朗（同 `GrantPoolMargin` 的处境）。

**连带：`GrantPoolMargin` 的口径应改写（本方案不给数值）** `[既有推演]` —— 闸 ① 当前的断言是「通用池条目数 ≥ 礼包所需（1 / 2）+ 余量」。采 B 之后，**「礼包所需」不再是一次的量，而是「支撑 K 次重复购买」**，余量的语义随之变为「留给第 K+1 次的缓冲」。建议把闸 ① 的口径改写为该形态，`K` 与余量数值仍**待内容规模明朗后给**（该条待答项保持开放，本方案只收窄它的口径）。

---

### 3. 付费面的边界：一条「明确不做」清单 + 一个唯一预留方向

`[取向选择]`（有推荐）· `[通行做法]`

**建议明确排除（写进 `monetization.md` 作为负面边界，与既有的否决记录同格）：**

| 排除项 | 理由 |
|---|---|
| **付费续命 / 复活**（花钱撤销一次 `defeated`） | **最强的一条**：ADR-0004 明写「存档角色是一种会被耗尽的有限资源、构成元进程压力」。付费续命不是放宽这条压力线（③ ④ 那样、有档、有上限），而是**按次取消**它——pay-to-win 滑坡的教科书形态 |
| **抽卡 / 扭蛋 / 随机付费箱** | 本作的随机授予是**买断式一次授予**（付了钱必得 1+2，且排重、且有三道闸保兑现），与「反复付费抽同一个池」形态相反；且概率公示 / 未成年人限额的合规成本高，与「明确排除消耗型货币」同向 |
| **消耗型货币 / 硬通货** | 已被既定的「**本作没有账号级可支配货币**」关死；08-12e 已否决「为兜底引入一条等于新开一套经济」 |
| **体力 / 付费加速** | 本作无体力、无 grind、无等待——没有可被加速的对象 |
| **广告变现（激励视频）** | 与买断式增值路线不冲突但稀释格调，且「看广告换重试」等价于付费续命的免费版本。建议排除 |

**建议预留为唯一的第二付费点方向（本次不定案，只标为「不排除」）：**

- **纯外观**（角色皮肤 / 卡背 / 界面主题）。它是唯一**零玩法影响、可无限扩展、不触及任何平衡讨论**的付费面；`vision/scope.md` 已把「外观装饰」列在范围之外（暂时）而非否决。落地时不需要 `PlayerEntitlement` 之外的新机制（一个具名字段或一个外观 id 集合即可）。
- **通行证 / 赛季**：明确「**当前不做**」——它要求先有赛季结构与持续内容产能，而本作当前**没有赛季结构**。若将来做，须先答「赛季是什么」，不能反过来。

---

### 4. UX 观感：安静的一等入口 + 绝不在失败时刻推销

`[既有推演]` + `[通行做法]`

#### 4.1 入口位置：主菜单第五个按钮，排末位，永不带红点

主菜单现有四个入口（PlayerProfile / PlayerPower / Achievement / Settings，各自是 PlayerProfile 字段的视图）。建议**加第五个同级入口**，而非藏进 PlayerProfile 面板二级页。

**理由（反直觉但承重）：** 把付费点藏进二级面板并不会让它更克制——它会因曝光不足而诱导出后续的补偿手段（弹窗、红点、限时角标），那才是「付费才玩得下去」观感的真正来源。**一个安静、可预期、永远在同一个位置的一等入口，是打扰最少的形态**（Balatro / Slay the Spire 的 DLC 入口同理）。

配套三条纪律：

- **入口永不带红点 / 徽标 / 数字角标 / 常驻动效 / 限时促销倒计时。**
- **除该入口外，全游戏不存在第二个通往付费流程的路径**（无弹窗、无插屏、无横幅）。
- 已购买后**不隐藏**（可重复购买），文案改为「再次购买（仅含法则 / 古宝）」，如实反映 §2 的不叠加口径。

#### 4.2 重试次数耗尽时是否提示购买：**明确否决**

两条独立理由指向同一答案：

1. `[通行做法]` 那是玩家刚失去一个角色的时刻，是全游戏情绪最低点。此处推销正是「付费才玩得下去」观感的经典成因，且它会把 ③ ④ 从「宽松化」在观感上变成「解锁继续游玩」。
2. `[既有推演]` **它在结构上本就不可行**：由 §1.4，购买流程只能在主菜单发起且待发队列为空；重试耗尽是轮回内 / 结算流程内的时刻。

**允许的全部呈现，穷举为两处：** 主菜单入口本身；礼包详情页内如实列出四项权益（及第二次起的删减说明）。

#### 4.3 闸 ② 不可用时：置灰 + 说明，不隐藏

`[既有推演]` 隐藏会让玩家以为功能消失（且无处解释），而闸 ② 触发时后端已收到 `PushError` 上报——正在被修的运营事故不该表现为「功能不见了」。

> **与「UI 不设置灰态但须如实展示 `selectCost`」不冲突**（08-06c）：那条讲的是**事件选项**——「明知是死路仍然走」是有意义的玩法决策，故不许灰。这里是**付费入口**，玩家点下去只会撞上一个必然失败的流程，没有任何决策价值。**判据：灰态禁令适用于「玩家可能有意选择的失败」，不适用于「必然无结果的操作」。** 建议把这句判据一并写进 `ux/` 侧，否则两条规则会被后来者读成矛盾。

#### 4.4 文案落点

- **新增翻译键分区 `STORE_` / `res://text/store.csv`**（分区表是开放表、明写随屏幕落地增补；一个屏幕 = 一个分区）。首批键例：`STORE_TITLE`、`STORE_BUNDLE_NAME`、`STORE_BUNDLE_PERK_POWER`、`STORE_BUNDLE_PERK_ITEM`、`STORE_BUNDLE_PERK_RETRY_CH2`、`STORE_BUNDLE_PERK_RETRY_CH3`、`STORE_REPURCHASE_NOTICE`、`STORE_UNAVAILABLE_POOL`、`STORE_UNAVAILABLE_SYNC`、`STORE_BUTTON_PURCHASE`。
- **支付失败文案不新造一套**：走既有的 `code → ERR_*` 机械变换（`ERR_` + 全大写 + `.` 换 `_`）与错误映射表，新增一个后端 `code` = 映射表加一行 + `errors.csv` 加一条。
- **未成年人 / 实名限制不在客户端判断**：客户端不读年龄、不做任何本地拦截，只承接后端返回的 `code` 并展示对应 `ERR_*` 文案。合规判定归后端（`vision/scope.md` 已把它列为必须正面处理的合规项）。

---

## 具体形态（可 derive 的落地面）

### 存档字段

| 落点 | 字段 | 类型 | 层 | 默认 | 语义 |
|---|---|---|---|---|---|
| `PlayerProfile.entitlement` | `PlayerEntitlement` | 具名小类 | 规则字段层 | 新建 | 付费权益的唯一载体 |
| `PlayerEntitlement` | `BundleGrantOrdinal` | `int` | 规则字段层（严格同步 · 后端可复算） | `0` | 礼包授予序号；单调递增、不清零；同时是 `AccountRng` 的 `ordinal` 与授予幂等键；`> 0 ⟺ 已购买` |

- **读档校验**：`< 0` → `GD.PushWarning` + 钳制到 `0`；**不由购买历史重建**（与 `PlayerPowerFragment` 三个首胜布尔同口径——它是权威）。
- **schema**：bump 一次，空迁移（老档缺字段 → `0`）。
- **禁止**：类内出现 `Total` 前缀 / `Count` 后缀字段；出现即意味着有人复制了同一个数。

### API 面增量（profile-service）

| 方法 / 属性 | 形态 | 签名 | 失败语义 |
|---|---|---|---|
| 权益查询 | A | `bool HasPremiumBundle { get; }` | 未购买 = `false`，非错误。单点查询，不进任何事件负载 |
| （已存在，复用） | A | `int GrantableCount(AbilityKind, AbilityScope)` | 闸 ② 的判据 |

新增具名 element：`BundleGrantOrdinal`（**置值**，不是加法——它被赋为预先算好的 `ordinal`），落 `ProfileChangeSpec.Elements`，**显式豁免 modifier pipeline**。

### 授予事务（一次 `TryApply`，全有或全无）

```
Elements:        [ BundleGrantOrdinal := ordinal ]
AbilityElements: [ Grant(Power, Player, pickedPowerId,  Source.PremiumBundle),
                   Grant(Item,  Player, pickedItemId1,  Source.PremiumBundle),
                   Grant(Item,  Player, pickedItemId2,  Source.PremiumBundle) ]
```

`SavePointReason` 取 `MetaChanged`，`PushPolicy` 取 `Immediate`（既有枚举，无需扩展）。

### 购买入口的可用性（三条前置，全满足才可点）

见 §1.4 的表。三条都不满足时的呈现：置灰 + 一行说明（走 `STORE_UNAVAILABLE_*` 翻译键）。

### 重试上限（数据，不是常量）

| 篇章 | 免费档（基准） | 付费档 |
|---|---|---|
| ch1 炼气 | 无限 | 无限 |
| ch2 筑基 | 3 | 9 |
| ch3 金丹 | 1 | 3 |

落 `systems/balance.md` 的平衡资源；由 life-cycle-service 读 `HasPremiumBundle` 选行。**可重复购买不产生第三行。**

---

## 后果

- **存档 schema bump 一次、空迁移**（当前无线上存档）；后端 `contracts/profile-sync.md` §5 白名单**补入预留的那一行**，`bundleGrantOrdinal` 的透明路径就此闭合，后端 `open-questions/01-contracts.md` 的对应条目可移出。
- **`AccountStream.PremiumBundle = 1` 与 SplitMix64 测试向量不受影响**——本方案只定 `ordinal` 存在哪里，不改派生形态。
- **同步模型新增一条纪律**（「后端主动写入只发生在购买段，且客户端在待发队列为空的主菜单态发起」）——它是 CAS 三分支表成立的前提，须写进 `sync-service.md`，否则第一个实现购买流程的人会在轮回内触发 `Conflict` 并丢掉玩家的战斗。
- **`ux/screen-flow.md` 的主菜单入口表增一行**；`ux/error-and-blocking-ux.md` 的分区表增 `STORE_` 一行；新增一条灰态判据（§4.3）。
- **`systems/balance.md`**：重试上限两档表从散文改为平衡资源；`GrantPoolMargin` 条目的口径改写为「支撑 K 次重复购买」（数值仍待定）。
- **工程连带（不在本库定稿）**：平台内购 SDK（Google Play Billing / App Store / 微信支付）是客户端**唯一必须引入第三方 SDK 的地方**，会牵动 Godot 导出配置与各平台构建。它落在 MVP 之外，此处只作提醒。

## 备选方案（已考虑并否决）

- **持有状态落 `CapabilityFlag` 或 modifier pipeline** —— 见 §1.1（派生态不能承载原始事实；且两者都受轮回级禁用截断）。
- **`PlayerEntitlement` 用 `List<EntitlementKind>` / 字符串集合** —— 与「`CapabilityFlag` 用 `enum` 而非字符串」同一条纪律；付费点被刻意限窄，可扩展集合成本高于收益。
- **同时设 `HasPremiumBundle` 布尔字段** —— 同一个数的第二份拷贝，正是合并判据与 `FinaleWinOrdinal` 先例要防的东西。
- **客户端自行置位 `BundleGrantOrdinal`，后端事后校验** —— 客户端置位 = 客户端有权发货，防篡改能力归零；「事后校验发现不一致」时玩家已经拿到了东西，回收比不发更糟。
- **兑现（抽 1+2）也放后端做** —— 会让 `AccountRng` / `GrantPoolPicker` 在两侧各实现一遍（后端还需完整的内容池与 `AllEnabled()` 语义），与既定的「客户端掷、后端复算」（残卷先例）分裂成两条路径。
- **购买入口在轮回内可用 + 为它设计冲突合并** —— 等于为一个可以靠时机纪律消除的问题引入字段级三路合并，而那已被 `ADR-0003` 明确排除。
- **③ ④ 叠加（可重复购买越买重试越多）** —— 抹平 ADR-0004 唯一的失败压力线。
- **重试耗尽时提示购买 / 付费续命** —— 见 §3、§4.2。
- **闸 ② 不可用时隐藏入口** —— 玩家会读成「功能没了」，且运营事故不该表现为功能消失。

## 与既有决策的张力

**一处，需用户裁决：后端接口从三个变四个，与「条件编译清单穷举 5 处、不得扩张」冲突。**

- 冲突的是什么：总则 7 定「三个窄接口 × Http/Offline 两份实现」，且 `system-overview.md` 第四节把 `#if` 的使用清单穷举为 **5 处**并明写「不得扩张」。支付是一条全新的跨进程边界（平台 SDK + 后端验票），它的失败语义（用户取消、订单待处理、票据重复、跨设备重复到账）与 `IProfileBackend` 完全不同。
- 为什么需要松动：把 `CreateOrderAsync` / `RedeemReceiptAsync` 塞进 `IProfileBackend` 会把「档案同步」与「支付」两个语义无关的边界混住——而总则 7 的**本意**是防「服务内插 `if (offline)`」造成半在线态，**不是**禁止新增边界服务。新增一个同形的 `IPurchaseBackend` + `OfflinePurchaseBackend`（`#if DEBUG`）**完全遵守**那条本意，只是让清单从 5 变 6。
- 松动的代价：「穷举清单不得扩张」这句话失去字面强度，日后每新增一个边界服务都要重新裁一次。
- **不松动时的替代方案**：把两个方法挂进 `IProfileBackend`（清单不变，但接口语义混住，且 `OfflineProfileBackend` 要同时假装是内存回显和假支付网关）。
- **本方案的推荐处置（第三条路）：** **本次不新增接口。** 商业化落地本就在 `vision/scope.md` 的「范围之外（暂时）」里，本方案要答的四条问题（存档表达 · 购买形态 · 付费面边界 · UX）**没有一条需要接口现在就存在**。建议只在 `systems/architecture.md` 总则 7 下**预先声明一句**：「商业化落地时将新增第四个窄接口 `IPurchaseBackend`，条件编译清单相应由 5 → 6；这是一次**已预告的、有边界的**扩张，不构成对该纪律的普遍松动。」——把裁决点留在真正需要它的时候，而不是现在为一个 MVP 外的功能改动一条承重纪律。

## 前置依赖

- **`Elements` 列表是否一律走 modifier pipeline，未收口。** `profile-service.md` 写「ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`」，而统计层已明确豁免。本方案要求 `BundleGrantOrdinal` **同样豁免**（残卷的 `PowerFragmentAccumulated` / `PowerFragmentWinOrdinal` 大概率也应豁免）。**建议一并答定一条通则：序号 / 幂等键 / 权益类 element 一律不经 pipeline**，否则「一条法则能改写它」这个洞会随每条新 element 复现。→ `systems/services/profile-service.md` 的「cost element 清单未定」那条待答。
- **`GrantPoolMargin` 的数值**（本方案只收窄其口径为「支撑 K 次重复购买」，不给 `K` 与余量）——仍待内容规模明朗。
- **后端侧（需另跑一次，本方案不写入后端库）**：验票流程与订单幂等键、后端主动 +1 `bundleGrantOrdinal` 的写入语义、`PremiumBundle` 域的复算白名单补入、跨设备重复到账的处置、实名 / 未成年人限额与渠道分成 / 退款。→ `backend-design-documents/`。
- **`AccountInfo` 的字段 schema**（含合规字段归属）仍待答；本方案不依赖它，但两者会在同一次实现里碰面。

## 已裁决（2026-08-15 · 用户全部采纳推荐）

原「仍需用户决定」的五项取向已全部按推荐定案，**正文中的推荐即定案内容**，`[取向选择]` 标注就此消解：

| # | 事项 | 裁决 |
|---|---|---|
| 1 | **购买形态**（§2） | **B —— 可重复购买；① ② 每次都给；③ ④ 只在首次购买生效、不叠加。** 连带：闸 ① 的口径改写为「支撑 K 次重复购买」，`K` 与 `GrantPoolMargin` 数值仍待内容规模明朗（该待答项保持开放）；第二次起的购买 UI **必须在付款前**如实标注「本次仅含 1 法则 + 2 古宝，重试上限不再提升」 |
| 2 | **付费面边界**（§3） | **明确排除五项**：付费续命 / 复活 · 抽卡 · 消耗型货币 · 体力与付费加速 · 广告变现。**唯一预留方向 = 纯外观**（不定案，只标为「不排除」）。**通行证 / 赛季明确「当前不做」**——须先有赛季结构 |
| 3 | **入口位置**（§4.1） | **主菜单加第五个一等入口**，排末位、安静呈现。三条纪律一并生效：永不带红点 / 徽标 / 角标 / 常驻动效 / 促销倒计时 · 全游戏不存在第二条通往付费流程的路径 · 已购买后不隐藏（改为「再次购买（仅含法则 / 古宝）」） |
| 4 | **`IPurchaseBackend`**（见「与既有决策的张力」） | **本次不新增接口。** 只在 `systems/architecture.md` 总则 7 下**预先声明**：商业化落地时将新增第四个窄接口 `IPurchaseBackend`，条件编译清单相应由 5 → 6，属**已预告的、有边界的**扩张，不构成对该纪律的普遍松动。扩张的实际裁决留到落地时 |
| 5 | **定价与地区**（§2 末） | **起步单一 SKU、单一价格档。** 金额属发行侧，**不落客户端**（价格与货币由平台商店按 SKU 返回，客户端不硬编码） |

**同时确认的两条连带**（本就是推荐正文的一部分，此处点名以免提炼时漏掉）：

- **`BundleGrantOrdinal` 显式豁免 modifier pipeline**；并建议一并答定通则「序号 / 幂等键 / 权益类 element 一律不经 pipeline」（→ `profile-service.md` 的「cost element 清单未定」）。
- **购买只能在主菜单发起、且待发队列为空**——这条时机纪律须写进 `sync-service.md`，它是 CAS 三分支表在「后端主动写入」下仍然成立的前提。

**未随本次裁决关闭的**：`GrantPoolMargin` 的数值 · `Elements` 的 pipeline 通则 · `AccountInfo` 字段 schema · 全部后端侧事项（验票 / 订单幂等 / 后端主动 +1 的写入语义 / 复算白名单 / 跨设备重复到账 / 实名与退款）。见「前置依赖」。
