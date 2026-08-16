# 商业化整体收口：付费凭证的存档表达 · 购买形态 · 付费面边界 · UX 观感

- id: 2026-08-15b-monetization-entitlement-purchase-shape-and-scope
- date: 2026-08-15
- topic: systems/monetization.md, systems/player-profile/_index.md, systems/services/profile-service.md, systems/services/sync-service.md, systems/services/life-cycle-service.md, systems/architecture.md, ux/screen-flow.md, ux/error-and-blocking-ux.md, systems/balance.md
- status: distilled
- distilled-to: systems/monetization.md, systems/player-profile/_index.md, systems/services/profile-service.md, systems/services/sync-service.md, systems/services/life-cycle-service.md, systems/architecture.md, system-overview.md, ux/screen-flow.md, ux/error-and-blocking-ux.md, systems/balance.md

> 输入：`inbox/archive/solution-draft-monetization-entitlement-and-scope.md`（`/provide-solution-draft` 产出，用户于 2026-08-15 评审并**全部采纳推荐项**）。
> `systems/monetization.md`「待决问题」的五条里，除**合规**（归后端）外的四条彼此咬合、本次一并答定。

## Intent（distilled）

一句话：**付费凭证落成 `PlayerProfile` 上一个具名小类的单个序号字段，购买段由后端权威、兑现段由客户端掷骰，且整条购买流程只能在主菜单发起——这条时机纪律同时关掉了同步冲突窗口与「在失败时刻推销」的可能性。**

### 1. 持有状态 = `PlayerProfile.entitlement: PlayerEntitlement`（一个字段）

```csharp
public sealed class PlayerEntitlement    // 规则字段层：严格同步 · 后端可复算 · 客户端永不自行置位
{
    public int BundleGrantOrdinal { get; }   // 账号级礼包授予序号；单调递增、不清零；0 = 从未购买
}
```

- **否决 `CapabilityFlag`**：它的唯一授予源是 PlayerPower 条目（礼包没有宿主条目）、它是布尔呈现开关（而 ③ ④ 要数值），**且致命的一条**——生效能力集受 08-10c 的轮回级禁用截断，把付费凭证放进一个设计上就允许被截断的聚合面，等于在结构上给「花钱买的东西被事件拿走」留后门。
- **否决 modifier pipeline 的具名修正**：同受同一条截断（两者由同一个 `CapabilityManager` 聚合），且 modifier 的定位是**法则对数值的软修正**——让一条法则与一份付费凭证写同一张表，等于承认法则可以改写付费权益。
- **共同判据：** capability / modifier 两条通道都是**由内容条目聚合出来的派生态**；付费凭证是**账号上的原始事实**。派生态不能承载原始事实。付费凭证必须是**硬状态**——不参与 pipeline、后端可复算。
- **不设第二个字段。** `HasPremiumBundle ⟺ BundleGrantOrdinal > 0`（一次带判断的派生读取）；可重复购买下 `BundleGrantOrdinal` **就是**购买次数。这正是既定合并判据与 `FinaleWinOrdinal` 先例所指的形态——让重复字段从一开始就不存在。命名合规：`Ordinal` 后缀 ⇒ 规则字段层，类内不出现 `Total` / `Count`。
- **不用 `List<EntitlementKind>` / 字符串集合**：与「`CapabilityFlag` 用 `enum` 而非字符串 key」同一条纪律；付费点被刻意限窄，可扩展集合的成本高于收益。日后真新增第二个付费点 = 本类加一个具名字段 + bump 一次 schema。
- **不落客户端（明确否决）：** 订单号 / 平台 SKU / 收据 / 购买时间 / 金额。它们是**审计凭证**，权威在后端；落到客户端存档既不可信，又会诱导出「客户端拿订单号做判断」的写法。客服排障的既定出口是设置屏「同步版本 #N」+ 后端订单库。
- **读档校验**：`< 0` → `PushWarning` + 钳制到 `0`；**不由购买历史重建**（与三个首胜布尔同口径——它是权威）。
- **schema**：`PlayerProfile.entitlement` ⇒ **bump 一次，空迁移**（老档缺字段 → `0` = 未购买）。当前无线上存档，走既有 MigrationManager 骨架。

### 2. 一次授予 = 一次 `TryApply`（全有或全无）

```
ordinal = profile.Entitlement.BundleGrantOrdinal + 1     ← 先取「本次」的序号
rng     = AccountRng.For(AccountStream.PremiumBundle, ordinal)
picked  = TryPickGrantable(Power, Player, rng) + TryPickGrantableMany(Item, Player, rng, 2)
spec    = { Elements:        [ BundleGrantOrdinal := ordinal ],
            AbilityElements: [ Grant(picked…, Source.PremiumBundle) ] }
ProfileManager.TryApply(spec)
```

- **序号从 1 起、先算后写**；随机在 **spec 组装之前掷完**（既定纪律：`AbilityChangeElement` 只承载已定稿的 `Id`）。
- **序号自增与「是否抽中」无关。** 闸 ③ 真发生时（理论不可达）该项计未兑现、不补发，但 `BundleGrantOrdinal` **照常 +1**——否则下一次购买复用同一 `ordinal`、掷出完全相同的序列，幂等键当场失效。
- **`BundleGrantOrdinal` 这条 element 显式豁免 modifier pipeline**，理由与统计层豁免同源，只是后果严重得多：经 pipeline = 一条法则能改写付费凭证。
- `SavePointReason` 取 `MetaChanged`，`PushPolicy` 取 `Immediate`（既有枚举，无需扩展）。

### 3. 服务端权威：购买写在云端，兑现在客户端，**且只在主菜单发生**

| 段 | 谁做 | 内容 |
|---|---|---|
| **① 购买段（后端权威）** | 平台 SDK + 后端 | 客户端唤起平台内购 → 得到收据 → 上行后端验票 → **后端**把云端 `bundleGrantOrdinal` +1、`cloudRevision` +1 |
| **② 兑现段（客户端演算 · 后端复算）** | 客户端 | 客户端 **pull** 到新序号 → 用 `(PremiumBundle, ordinal)` 掷骰抽 3 条 → 一次 `TryApply` → `Immediate` push；后端以同一 `(AccountSeed, stream, ordinal)` 复算校验 |

「谁有权把 `BundleGrantOrdinal` 从 n 推到 n+1」**只能是后端**，否则整套防篡改归零。**否决客户端自行置位 + 后端事后校验**（客户端置位 = 客户端有权发货；「事后发现不一致」时玩家已经拿到东西，回收比不发更糟），也**否决兑现也放后端做**（`AccountRng` / `GrantPoolPicker` 要在两侧各实现一遍，与既定的「客户端掷、后端复算」分裂成两条路径）。

**⚠ 它引入了现有同步模型没有的第四种情形：后端主动写入。** 这会让 `cloudRevision` 领先 `baseRevision`，而 CAS 三分支表对此判 `Conflict` ⇒ 以云端为准丢弃本地缓冲。若购买发生在轮回中途，被丢掉的正是玩家刚打完的战斗——直接违反「绝不回退存档点」。

**解法不需要任何新机制，只需要一条时机纪律：**

> **购买流程只能在主菜单（轮回外）发起，且进入付费流程前待发队列必须为空。**

- 队列非空（上一轮回残留 / 断线缓冲）→ **先 `FlushPendingAsync` 成功才允许进入付费流程**；这与既有的闸 ② 合并为**同一张前置条件表**，不新增拦截点。
- 购买成功后**强制一次 pull**（而非等下一次启动），拿到新 `revision` 与新序号，再本地兑现。
- 于是「后端主动写」的冲突窗口在结构上被关闭：那一刻客户端没有任何未上行的变更，`Conflict` 分支不可能踩到。
- **否决「购买入口在轮回内可用 + 为它设计冲突合并」**——等于为一个可以靠时机纪律消除的问题引入字段级三路合并，而那已被 ADR-0003 明确排除。

**购买入口的前置条件表（三条全满足才可点）：**

| # | 条件 | 不满足时 |
|---|---|---|
| 1 | 当前在主菜单（不在任何轮回内） | 入口不渲染 |
| 2 | 待发队列为空（或一次 flush 成功） | 入口置灰 + 「请先完成同步」 |
| 3 | `GrantableCount(Power, Player) ≥ 1` 且 `GrantableCount(Item, Player) ≥ 2` | 入口置灰 + 说明 + `PushError` + 上报（既定闸 ②） |

### 4. 重试上限的读取面

- profile-service 增只读属性 **`bool HasPremiumBundle { get; }`**（`=> Entitlement.BundleGrantOrdinal > 0`），形态 A、单点查询——与 `Has(CapabilityFlag)` / `SyncService.UpgradeRequired` / `PendingCount` 同构，**不塞进任何事件负载**。
- **上限表本身是数据不是常量**：两档「无限 / 3 / 1」与「无限 / 9 / 3」落 `systems/balance.md` 的平衡资源，由 life-cycle-service 读 `HasPremiumBundle` 选行。这正是既定的「重试上限首次成为可变量，凡读取处都要经这一层」的落地形态。**可重复购买不产生第三行。**

### 5. 购买形态：可重复购买；① ② 每次都给，③ ④ 只在首次生效

- **否决「一次性、不可重复」**：商业化封顶为一次性小额，与「重账号 + 强制在线 + 长期运营」的路线不匹配，且让 08-12e 的闸 ② 几乎永无用武之地。
- **否决「可重复且 ③ ④ 叠加」**：花钱买接近无限的重试 ⇒ 直接抹平 ADR-0004 唯一的失败压力线，与「免费档是基准、付费是宽松化而非必需品」正面冲突。
- **两条依据指向可重复 + 不叠加**：① 08-12e 已经在为重复购买铺路而不自知——它明写「按排重，**第二次礼包**不可能给到与第一次相同的条目」，并为「池不足」设了闸 ②，而一次性购买几乎不可能抽干通用池，**闸 ② 的存在本身只有在可重复形态下才有真实意义**；② ③ ④ 不叠加的理由已由 `monetization.md` 自己写好——重试上限是元进程难度的主要旋钮，两档（免费 / 付费）是有意的口径变化，第三档、第四档就不是了。
- **落地约束（承重的诚实性纪律）：** 第二次及以后的购买，**UI 必须在付款前如实标注「本次仅含随机 1 法则 + 2 古宝；重试上限已达上限，不再提升」**。付了钱却没拿到宣传的四项之二，是退款争议的标准形态——与 08-12e「把失败点挪到掏钱之前」是同一条纪律。
- **定价：起步单一 SKU、单一价格档**，金额属发行侧、**不落客户端**（价格与货币由平台商店按 SKU 返回，客户端不硬编码任何金额）。多档 SKU 会立刻牵出「哪档给什么」的内容编排，而当前内容池规模尚未明朗。
- **连带：`GrantPoolMargin` 的口径改写。** 闸 ① 原断言「通用池条目数 ≥ 礼包所需（1 / 2）+ 余量」；可重复购买下**「礼包所需」不再是一次的量，而是「支撑 K 次重复购买」**，余量的语义随之变为「留给第 K+1 次的缓冲」。`K` 与余量数值仍待内容规模明朗后给（该待答项保持开放，本次只收窄口径）。

### 6. 付费面的边界：一条「明确不做」清单 + 一个唯一预留方向

**明确排除（写进 `monetization.md` 作为负面边界）：**

| 排除项 | 理由 |
|---|---|
| **付费续命 / 复活** | **最强的一条**：ADR-0004 明写「存档角色是一种会被耗尽的有限资源、构成元进程压力」。付费续命不是放宽这条压力线（③ ④ 那样、有档、有上限），而是**按次取消**它——pay-to-win 滑坡的教科书形态 |
| **抽卡 / 扭蛋 / 随机付费箱** | 本作的随机授予是**买断式一次授予**（付了钱必得 1+2、排重、三道闸保兑现），与「反复付费抽同一个池」形态相反；且概率公示 / 未成年人限额的合规成本高 |
| **消耗型货币 / 硬通货** | 已被既定的「本作没有账号级可支配货币」关死；08-12e 已否决「为兜底引入一条等于新开一套经济」 |
| **体力 / 付费加速** | 本作无体力、无 grind、无等待——没有可被加速的对象 |
| **广告变现（激励视频）** | 与买断式增值路线不冲突但稀释格调，且「看广告换重试」等价于付费续命的免费版本 |

- **唯一预留方向（不定案，只标为「不排除」）= 纯外观**（角色皮肤 / 卡背 / 界面主题）：唯一零玩法影响、可无限扩展、不触及任何平衡讨论的付费面；`vision/scope.md` 已把「外观装饰」列在范围之外（暂时）而非否决。落地时不需要 `PlayerEntitlement` 之外的新机制。
- **通行证 / 赛季：明确「当前不做」**——它要求先有赛季结构与持续内容产能，而本作当前没有赛季结构。若将来做，须先答「赛季是什么」，不能反过来。

### 7. UX 观感：安静的一等入口 + 绝不在失败时刻推销

- **入口 = 主菜单的一等入口，排在既有四个入口之后、安静呈现**，而非藏进 PlayerProfile 面板二级页。**理由反直觉但承重**：藏进二级面板并不会让它更克制——它会因曝光不足而诱导出后续的补偿手段（弹窗、红点、限时角标），那才是「付费才玩得下去」观感的真正来源。**一个安静、可预期、永远在同一个位置的一等入口，是打扰最少的形态。**
- 配套三条纪律：**永不带红点 / 徽标 / 数字角标 / 常驻动效 / 限时促销倒计时** · **除该入口外全游戏不存在第二个通往付费流程的路径**（无弹窗、无插屏、无横幅） · **已购买后不隐藏**（可重复购买），文案改为「再次购买（仅含法则 / 古宝）」。
- **重试次数耗尽时提示购买：明确否决。** 两条独立理由——① 那是玩家刚失去一个角色的时刻，是全游戏情绪最低点，此处推销正是「付费才玩得下去」观感的经典成因，且会把 ③ ④ 从「宽松化」在观感上变成「解锁继续游玩」；② **它在结构上本就不可行**：购买流程只能在主菜单发起且待发队列为空，而重试耗尽是轮回内 / 结算流程内的时刻。
- **允许的全部呈现，穷举为两处：** 主菜单入口本身；礼包详情页内如实列出四项权益（及第二次起的删减说明）。
- **闸不可用时置灰 + 说明，不隐藏**：隐藏会让玩家以为功能消失（且无处解释），而闸 ② 触发时后端已收到 `PushError` 上报——正在被修的运营事故不该表现为「功能不见了」。
  - **与 08-06c「UI 不设置灰态但须如实展示 `selectCost`」不冲突**：那条讲的是**事件选项**——「明知是死路仍然走」是有意义的玩法决策，故不许灰。这里是**付费入口**，玩家点下去只会撞上一个必然失败的流程，没有任何决策价值。**判据：灰态禁令适用于「玩家可能有意选择的失败」，不适用于「必然无结果的操作」。**
- **文案落点**：新增翻译键分区 `STORE_` / `res://text/store.csv`（分区表是开放表）。首批键例：`STORE_TITLE`、`STORE_BUNDLE_NAME`、`STORE_BUNDLE_PERK_POWER`、`STORE_BUNDLE_PERK_ITEM`、`STORE_BUNDLE_PERK_RETRY_CH2`、`STORE_BUNDLE_PERK_RETRY_CH3`、`STORE_REPURCHASE_NOTICE`、`STORE_UNAVAILABLE_POOL`、`STORE_UNAVAILABLE_SYNC`、`STORE_BUTTON_PURCHASE`。
  - **支付失败文案不新造一套**：走既有的 `code → ERR_*` 机械变换与错误映射表，新增一个后端 `code` = 映射表加一行 + `errors.csv` 加一条。
  - **未成年人 / 实名限制不在客户端判断**：客户端不读年龄、不做任何本地拦截，只承接后端返回的 `code` 并展示对应 `ERR_*` 文案。合规判定归后端。

### 8. `IPurchaseBackend`：本次不新增接口，只预先声明

支付是一条全新的跨进程边界（平台 SDK + 后端验票），其失败语义（用户取消、订单待处理、票据重复、跨设备重复到账）与 `IProfileBackend` 完全不同；但**总则 7 的本意**是防「服务内插 `if (offline)`」造成半在线态，**不是**禁止新增边界服务。

**本次不新增接口**——商业化落地本就在 `vision/scope.md` 的「范围之外（暂时）」里，本次答定的四条问题没有一条需要接口现在就存在。只在 `systems/architecture.md` 总则 7 与 `system-overview.md` 第四节的条件编译清单处**预先声明一句**：商业化落地时将新增第四个窄接口 `IPurchaseBackend`，条件编译清单相应由 5 → 6，属**已预告的、有边界的**扩张，不构成对该纪律的普遍松动。裁决点留到真正需要它的时候。

**否决**把 `CreateOrderAsync` / `RedeemReceiptAsync` 挂进 `IProfileBackend`（清单虽不变，但会把「档案同步」与「支付」两个语义无关的边界混住，且 `OfflineProfileBackend` 要同时假装是内存回显和假支付网关）。

## Clarifications（interview 产物）

本次**未触发 interview**：输入草稿是 `/provide-solution-draft` 的产物，五处 `[取向选择]` 与一处「与既有决策的张力」已于 2026-08-15 由用户逐项裁决（**全部采纳推荐项**），且交叉核对未发现与既有 ADR / 主题文档 / 承重纪律相抵触之处。用户裁决逐条如下：

| # | 事项 | 裁决 |
|---|---|---|
| 1 | 购买形态 | 可重复购买；① ② 每次都给；③ ④ 只在首次生效、不叠加 |
| 2 | 付费面边界 | 明确排除五项；唯一预留方向 = 纯外观；通行证 / 赛季当前不做 |
| 3 | 入口位置 | 主菜单一等入口、排末位、安静呈现 + 三条纪律 |
| 4 | `IPurchaseBackend` | 本次不新增接口，只在总则 7 下预先声明 5 → 6 |
| 5 | 定价与地区 | 起步单一 SKU、单一价格档；金额不落客户端 |

## Open questions

- **`Elements` 列表是否一律走 modifier pipeline（通则未收口）。** 本次只定下 `BundleGrantOrdinal` **豁免**这一条个案；建议一并答定通则「**序号 / 幂等键 / 权益类 element 一律不经 pipeline**」（残卷的 `PowerFragmentAccumulated` / `PowerFragmentWinOrdinal` 大概率也应豁免），否则「一条法则能改写它」这个洞会随每条新 element 复现。→ `systems/services/profile-service.md` 的「cost element 清单未定」。
- **`GrantPoolMargin` 的数值与 `K`。** 口径已收窄为「支撑 K 次重复购买 + 留给第 K+1 次的缓冲」，数值仍待内容规模明朗。→ `systems/balance.md`。
- **纯外观付费点是否真做、做成什么。** 本次只标为「不排除」，未定案。
- **后端侧（须另跑一次 `/analyze-new-ideas --lib=backend`，本次不写入后端库）**：验票流程与订单幂等键 · 后端主动 +1 `bundleGrantOrdinal` 的写入语义 · `PremiumBundle` 域的复算白名单补入（`contracts/profile-sync.md` §5 已预留一行）· 跨设备重复到账的处置 · 实名 / 未成年人限额与渠道分成 / 退款。
- **工程连带（不在本库定稿）**：平台内购 SDK（Google Play Billing / App Store / 微信支付）是客户端**唯一必须引入第三方 SDK 的地方**，会牵动 Godot 导出配置与各平台构建。落在 MVP 之外，此处只作提醒。
