---
type: solution-draft
date: 2026-09-11
question: 付费角色系列的解锁载体与购买流程形态 —— `CharacterData` 轨道标记、`PlayerProfile` 具名集合、取池过滤、`schemaVersion` bump 与客户端购买流程的具体形态
source: open-questions/06-meta-progression.md → 「付费角色系列的解锁载体与购买流程形态（09-10 新增）」
targets: systems/character-profile/_index.md · systems/monetization.md · systems/player-profile/_index.md · systems/services/life-cycle-service.md · systems/services/profile-schema-versions.md · ux/screen-flow.md · ux/error-and-blocking-ux.md · content/character/_index.md
counterpart: backend-design-documents/inbox/solution-draft-premium-character-series-unlock.md
status: distilled
distilled-to: handoffs/2026-09-12-premium-character-series-unlock.md
reviewed: 2026-09-11（批量评审 · 2 项取向 + 5 条张力全部已裁决；另新增「购买时限」机制，见 §仍需用户决定（2））
---

# 方案草稿 — 付费角色系列的解锁载体与购买流程形态（客户端半）

> **本文件只写客户端这一半。** SKU 的命名与粒度、验票后写入 profile 的报文与语义、`profile-sync` 白名单 / 封闭表加行、兼容矩阵登记、购买域失败 `code` —— 全部归 counterpart（`backend-design-documents/inbox/solution-draft-premium-character-series-unlock.md`），本文件一字不复述，只回链。

## 问题

`ADR-0255` 已把「付费解锁角色系列」定为商业化第三支，并定死了四条轨道决策（系列化成批 · 轨道属性 + 单向棘轮 · 整系列礼包定价 · 严格横向不卖强度）。但它把**载体**整块推给了本技能：

- `CharacterData` 上那一格「免费 / 付费」轨道标记长什么样？
- `PlayerProfile` 上那个具名集合装什么粒度的 id（角色？系列？）？
- 取池过滤落在哪个服务 / manager？
- `schemaVersion` bump 落哪一版、老档怎么处置？
- 购买流程在客户端走什么形态 —— premium bundle 那套（掷骰 + 兑现水位 + `TryApply`）能照抄吗？
- 「单向棘轮」既然不做运行时机制，`/audit-content` 的核对项拿什么当基线？

卡住的是：这一条不落，付费系列的内容编排（`SeriesId` 怎么填）、后端契约（SKU ↔ 什么 id）与一次 schema bump 全部无法启动，而 `ADR-0255` 已 Accepted。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| C1 | 一个系列 5 或 10 个、每批五行对称；**整系列全免费或全付费，绝不单出一个角色** | `ADR-0255`「决策」 |
| C2 | **单个角色零售已被明确否决**（「破坏五行对称，且会把『买哪个最强』变成事实上的强度选择」） | `ADR-0255`「备选方案」 |
| C3 | 「一旦免费永不改付费」= **内容纪律 + `/audit-content` 核对项候选，不做运行时机制** | `ADR-0255`、`systems/character-profile/_index.md` |
| C4 | 首批五角**永久免费恒可用**（它就是第一个免费系列）；双灵根首批十角走免费轨道 | 同上 |
| C5 | 解锁载体 = `PlayerProfile` 一个具名集合（元素用 `readonly record struct` 包一层，照 `CodexEntry` 的加法窗口纪律）+ 一条取池过滤 + 一次 `schemaVersion` bump，**不需要任何新机制** | `systems/character-profile/_index.md`「角色模板池的形态」 |
| C6 | `PlayerEntitlement` 类内**只放付费凭证本身与其兑现水位，不放任何派生量**；否决 `CapabilityFlag` 与 modifier pipeline（派生态不能承载原始事实） | `systems/player-profile/_index.md`、`systems/monetization.md` |
| C7 | **禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合**（合法性校验由注册表接管）。日后真新增第二个付费点 = 本类加一个具名字段 + bump 一次 schema | `systems/player-profile/_index.md` |
| C8 | 集合字段名**恒为单数**，且这是**跨边界通则**（Profile 透明段字段改名 = 破坏性契约变更） | 同上 · `ADR-0105` |
| C9 | 后端写入的 profile 字段**受回声约束**：上行时只能原样回声最近一次 pull 的值，不参与读档钳制 / 缺省补齐 / 格式归一化 | `systems/player-profile/_index.md`、`systems/services/sync-service.md` |
| C10 | **受回声校验约束的顶层键内追加字段 ⇒ 与「移动 / 重命名透明路径」同档：两侧同批落笔并进版本行** | `systems/services/profile-schema-versions.md`「形态纪律 ⑤」 |
| C11 | **首发前的一切改动全部归入 `schemaVersion = 1`，不拆成多版** | 同上「v1 —— 首发形状」 |
| C12 | 产出侧只从 `ContentEnabled == true` 抽取（`AllEnabled()`）；读取侧 `Get(id)` 不过滤；**flags 不参与合并后强校验**（校验走 `AllIncludingDisabled()`） | `systems/services/content-service.md` |
| C13 | **`DrawPool<T>` 的构造签名不必变成 `AllEnabled(bucketContext)` 一类，它的唯一依赖就此解除** —— 注册表不吃账号上下文 | 同上 |
| C14 | `GetSelectableCharacters()` 已存在；`StartCycle` 已有守卫「`CharacterDataId` 不在可选池内 → `OpResult`」 | `systems/services/life-cycle-service.md` |
| C15 | 购买只在**主菜单**发起；轮回内 / 战斗内 / 结算流程内不存在购买入口 | `systems/monetization.md` |
| C16 | 兑现结果 / 购买处理态是 **Store 屏的结果态，不新增屏**；文案走 `STORE_` 分区；灰态 = 置灰 + 说明、不隐藏 | `ux/screen-flow.md`、`ux/error-and-blocking-ux.md` |
| C17 | **诚实性纪律**：UI 必须在**付款前**如实列出本次买到什么 | `systems/monetization.md` |
| C18 | **付费内容不会被游戏销毁**（已授予的不被拿走）；空池三道闸的判据是「玩家有没有为这一次产出付过钱」 | 同上 |
| C19 | `Cosmetic : IReadOnlyList<CosmeticEntry>` 的先例：**写入方只有后端**（验票事务内追加）、客户端经 pull 读到、**不配兑现水位**、不加 `Status` / `Charges` / `SourceCode` | `systems/player-profile/_index.md`、`systems/monetization.md` |
| C20 | 角色**完全不涉及 RNG**：不新开子流、`AccountStream` 不动、`StartCycle` 不走 `RngElements` 列 | `systems/services/life-cycle-service.md` |

## 建议方案

### ① 解锁粒度 = **系列**，不是单个角色

`[既有推演]`

C2 明确否决了单个角色零售 ⇒ **可购 SKU 只有「整系列礼包」一种**；`ADR-0255` 的「付 4 个单解之价 / 付 8 个单解之价」是**定价锚（记账单位）**，不对应任何可购商品。

由此推出持有集合的元素粒度：**系列 id**，不是角色 id。

**这条推演的真正承重面在跨边界一侧：** 若持有集合存角色 id，后端就必须持一张「SKU → 该系列的 5 / 10 个 `character.<slug>`」的表 —— 那是**内容编排知识**，抄到后端即制造第二权威（内容侧加一个角色、改一次编排，后端表就漂了，而本项目没有任何机制能发现它不一致）。存系列 id 之后，后端只需 **SKU ↔ 一个字符串**的一对一映射，零内容知识。这与「回链而非复述」是同一条纪律在数据面的兑现。

### ② `CharacterData` 加**两格**：`SeriesId` + `Track`

`[既有推演]`

C1「整系列全免费或全付费」使轨道在语义上是**系列的属性**，但本方案主张**不为此新建内容类型**，而是两格都落在 `CharacterData` 上，用加载期校验兑现「同系列轨道一致」。

```csharp
// CharacterData 上新增两格（模板静态字段，不落存档）
[Export] public string        SeriesId { get; set; } = "";           // 两段式 character_series.<snake_case_slug>
[Export] public CharacterTrack Track   { get; set; }                 // 必填，见哨兵

public enum CharacterTrack
{
    Unspecified = 0,   // 防御性哨兵：唯一作用是让「漏填」可被加载期检出
    Free        = 1,
    Paid        = 2,
}
```

**为什么是枚举 + `Unspecified = 0` 哨兵，不是 `bool IsPaid`（承重）。** Godot 的 `[Export]` 未填即取 0 ⇒ `bool IsPaid` 的漏填会**静默落进免费轨道**。而棘轮方向恰恰是「免费永不改付费」—— 漏填造出的免费轨道**在发版之后不可逆**。哨兵枚举把它变成加载期 `PushError`。这与 `Affinity.Unspecified = 0` / `Source.Unknown = 0` / `Pool` / `CardType` 的必填纪律逐字同理。

**字段名 `Track` / 类型名 `CharacterTrack` 的取法**同 `Rarity : RarityTier`（字段名短、类型名带限定）。

**`SeriesId` 前缀取 `character_series.`**，与既有主类型前缀词表（`character.` / `character_item.` / `player_item.` / `character_power.` / `player_power.`）不撞车，且为日后真建 `CharacterSeriesData` 内容类型留好引用键。

**存档增量仍为 0。** 两格都是模板静态字段，与既有的 `Affinities` / `RealmArtworks` 同档 —— `CharacterData` 侧**不 bump `schemaVersion`、无迁移、后端零影响**；bump 只由 ④ 的 `PlayerProfile` 那一格产生。

### ③ 加载期校验：在 `CharacterData` 既有十一条之后追加四条

`[既有推演]`（判据 = 「坏数据必须在启动期大声失败」）

| # | 违规 | 处置 |
|---|---|---|
| 12 | `Track == Unspecified` | `PushError` + 抛，带 `characterId` —— 漏填不可默认为免费（见 ②） |
| 13 | `SeriesId` 为空 / 不符 `character_series.<snake_case_slug>` 形态 | `PushError` + 抛，带 `characterId` |
| 14 | 同一 `SeriesId` 下各条目的 `Track` **不一致** | `PushError` + 抛，带 `seriesId` 与两个取值 —— C1「整系列全免费或全付费」的机械化 |
| 15 | 同一 `SeriesId` 下的条目数 ∉ {5, 10} | `PushError` + 抛，带 `seriesId` 与实际条数 —— C1「一个系列 5 个或 10 个」的机械化 |

- **14 / 15 一律走 `AllIncludingDisabled()`，不走 `AllEnabled()`。** C12 明写 flags 不参与合并后强校验；按 `AllEnabled()` 统计会让「线上秒关一个问题角色」把启动打崩。
- **五行对称不做代码校验。** 5 人系列的五行各一、10 人系列的双灵根十种组合各一，是**内容编排口径**（首批「长度恰为 1」已是同款处置），且未来的 10 人系列未必按 C(5,2) 铺。归 `/audit-content` 核对项，与 C3 把棘轮判给内容纪律是同一条处置。

### ④ `PlayerEntitlement` 加一格具名集合 `CharacterSeries`

`[既有推演]`（C5 · C7 · C19 逐条对位）

```csharp
public sealed class PlayerEntitlement    // 规则字段层：严格同步 · 后端可复算
{
    public int BundleGrantOrdinal    { get; }
    public int BundleRedeemedOrdinal { get; }
    public IReadOnlyList<CharacterSeriesEntry> CharacterSeries { get; }   // ← 新增
}

public readonly record struct CharacterSeriesEntry(string SeriesId);
```

| 项 | 取值 | 依据 |
|---|---|---|
| JSON path | `/entitlement/characterSeries` | camelCase 单点策略的机械像 |
| 字段名单复数 | **单数 `characterSeries`**（"series" 单复同形，天然合规） | C8 |
| 元素形态 | `readonly record struct CharacterSeriesEntry(string SeriesId)` —— **不用裸 `string[]`** | C5 · `CodexEntry` / `CosmeticEntry` 先例：日后加一格是在 record 上加字段（老档补默认值、零迁移），裸 `string` 则元素形状从标量变对象，是一次真实的破坏性变更 |
| 键名 | `SeriesId` 而非 `Id` | 四类持有条目的 `<Kind>Id` 命名通则（`Id` 在本库指「本条目自身的稳定 Id」） |
| 写入方 | **只有后端**（验票事务内追加），客户端经 pull 读到 | C19 · counterpart 的验票写入段 |
| 客户端写入通道 | **无**。不进任何 `ProfileChangeSpec` 列，`ResourceElements` **不加行** | 同 `BundleGrantOrdinal` 的既定处置：缺行即命中「`ChangeElement.Key` 无对应行 → `PushError` + 整批拒绝」，**任何日后误写的客户端置位当场在施加时大声失败**，不需要新增任何断言 |
| 回声约束 | **受约束**（它在后端写入字段封闭表内 —— 封闭表本体的权威在 counterpart，本库不复制） | C9 |
| 兑现水位 | **不配** | 见 ⑥：解锁授予无随机、无内容抽取 ⇒ 客户端零兑现事务 |
| 附加格 | **不加** `Status` / `Charges` / `SourceCode` | 解锁零启用开关、零使用次数、来源恒为购买 —— 与 `CosmeticEntry` 逐字同理 |
| 默认 | 空列表 | |

**读档校验**（照 `CosmeticEntry` 的既定口径，并按回声路径纪律落位）：

| 情形 | 处置 |
|---|---|
| 非数组 / 元素缺 `SeriesId` | `PushError` + **`entitlement` 顶层键本次不进 diff** + 触发一次 pull 重取权威值，**不钳制** |
| `SeriesId` 在内容层无任何 `CharacterData` 与之对应 | `PushWarning` + **保留条目**（同 Codex：一条读不出的旧条目不该阻断登录；且它是回声路径，剔除会招致整批拒绝） |
| 同一 `SeriesId` 重复 | `PushWarning` + **呈现层去重，不改写存档值**（回声路径，改写即在正常账号上稳定招致整批拒绝） |

**它不是「以付费点种类为 key 的开放容器」（C7 的准确边界）。** 元素是 `character_series.*` 这一类由内容层定义、可被内容层解析的 id，不是自由 key —— 与七个 Codex、四类持有条目同形。付费点的**种类**仍是具名字段（本次即「加一个具名字段」）。

### ⑤ 取池过滤落 `life-cycle-service.GetSelectableCharacters()`，**不落 `ContentRegistry`**

`[既有推演]`（C13 · C14）

```
可选角色 = AllEnabled<CharacterData>()
           ∩ 全部绑定条目 ContentEnabled == true          ← 既有「可抽取性」那一层，原样不动
           ∩ ( Track == Free ∨ entitlement.CharacterSeries 含该条目的 SeriesId )   ← 本方案新增的一层
```

- **绝不写成 `AllEnabled(accountContext)` 一类。** C13 已经为 flags 的分桶问题把这个形态明确关死了（「它的唯一依赖就此解除」）；让注册表读 `PlayerProfile` 是让内容层反向依赖存档层。过滤发生在 life-cycle-service 内、`AllEnabled()` 的返回值之上。
- **`StartCycle` 零改动。** C14 的既有守卫「`CharacterDataId` 不在可选池内 → `OpResult`」**原样覆盖**新增的这一层，不新增拦截点、不新增失败语义。
- **加载期校验 #1（池为空 → `PushError` + 抛）口径不变。** 它数的是 `AllEnabled<CharacterData>()`，**不含解锁过滤** —— C4 保证首批五角恒免费恒可用 ⇒ 运行时可选池恒非空。**不新增「解锁后池为空」这条校验**（它永不可达，而一条永不可达的校验只会误导后来者以为免费轨道可能为空）。
- **完全不涉及 RNG**（C20 原样成立）：解锁是集合包含判定，不新开子流、`AccountStream` 不动。

### ⑥ 购买流程：走既有两条腿，但**兑现段整段不存在**（承重）

`[既有推演]` + `[通行做法]`

渠道封装层（`StoreChannelManager` 持 `IStoreChannel`、运行时探测 + `UnavailableStoreChannel` 兜底、后端 HTTP 调用走 `IPurchaseBackend`）**原样复用，一格不改** —— 形状的权威在 `systems/services/sync-service.md`，本文件不复述。

```
主菜单 → Store 屏（既有入口，不新增屏、不新增主菜单入口）
  → 系列列表（Store 屏的又一个列表 / 结果态）
  → 系列详情（付款前如实列出本系列全部角色，见 ⑦）
  → 下单（条件步，仅需商户侧下单的渠道）
  → IStoreChannel 唤起平台内购 → 收据
  → IPurchaseBackend 验票 → 后端在验票事务内写入 /entitlement/characterSeries（报文归 counterpart）
  → 购后强制 pull
  → pull 到该 seriesId 出现 ⇒ 全屏模态进度态切「解锁结果态」（列出本次解锁的角色）
  → Apple 侧 finish()（只能在验票成功或幂等命中之后）
```

**与 premium bundle 的决定性差别 —— 客户端不发货：**

| 段 | premium bundle | 付费角色系列 |
|---|---|---|
| 购买段 | 平台 SDK + 后端 | **同款，不变** |
| **兑现段** | 客户端 pull 到新序号 → `AccountRng` 掷骰抽 3 条 → 一次 `TryApply` → `Immediate` push | **不存在**。授予即后端写入的那一格，pull 下来就是终态 |
| 兑现水位 | `BundleRedeemedOrdinal`（`Grant > Redeemed` 即待兑现） | **无** |
| 空池三道闸 / `GrantPoolMargin` / `K` | 适用 | **一概不适用**（无内容抽取） |
| 购后 pull 失败 | 阻塞在主菜单、不允许开始新轮回 | **不阻塞**，见下 |

⇒ 客户端在本付费点上**零 `TryApply`、零 `AccountRng`、零水位、零「差值 > 1」异常路径**。这与 C19 的 `Cosmetic` 先例（「不需要兑现水位 —— 礼包要水位是因为兑现要掷骰抽内容」）逐字同构。

**最诱人的错误答案是照抄一个 `CharacterSeriesRedeemedOrdinal`。** 它不成立：水位存在的唯一理由是「发货动作在客户端，需要一个云端可见的已发货记号」；本付费点的发货动作在后端，验票成功的那一刻货已经在云端，没有任何东西需要被记号。

**跨启动补入口 = 两条，都不依赖云端水位：**

1. `[既有推演]` **本地持久化的 `receiptId` + 收据幂等读**（与 premium bundle 同一条通道，端点归 counterpart）。
2. `[通行做法]` **每次启动的商店初始化时查询平台未完成交易并补验票** —— 未 consume / 未 finish 的交易在下次查询时重新出现，是 Google Play Billing 与 StoreKit 2 的标准形态。本地态丢失（卸载重装 / 换设备 / 清缓存）时，它是最后一道保证。

  **两条合起来即闭合，无需第三条。** 本地态丢失的最坏后果只是「那一次尚未完成的验票没被立刻重试」—— 而若验票**已**成功，货已在云端、pull 即到账；若验票**未**成功，平台收据未被核销、下次启动重新出现。premium bundle 之所以另需云端水位，恰恰因为它有一个**客户端侧的、云端看不见的**发货动作。

**购后不阻塞「开始新轮回」（对既有阻塞面的一次收窄）。** premium bundle 那条阻塞的成立前提是「存在未兑现状态，在此状态下开新轮回会让兑现与轮回交错」；本付费点没有未兑现状态，未到账的最坏后果是「这几个角色暂时选不到」，玩家照常可用免费角色开轮回。**premium bundle 的那条纪律一字不改**，但它不外延为全部付费点的通则 —— 见「与既有决策的张力」。

**失败处置沿用既有五情形表**（收据处理中 / 收据无效终态 / 已在另一账号核销 / 渠道未开通 / 报文格式错误），**不新增情形**；只需把「待兑现态」列在本付费点上读作「本地 `receiptId` 待结清态」（本付费点无云端水位）。**无硬超时、永不放弃**原样适用。

**`IPurchaseBackend` 的应答类型随对侧分形（本库只定调用形状，不定报文）。** 既有 `VerifyAck(long BundleGrantOrdinal, long Revision, bool Deduplicated)` 的第一格对系列购买无意义 —— counterpart 提案按 SKU 类别分形，故本库这三个 record（`VerifyAck` / `OrderAck` / `ReceiptStatusAck`）的形状**随对侧定案同批调整**。**接口方法签名不变**（仍是那三个调用），`StoreChannelManager` / `IStoreChannel` / `UnavailableStoreChannel` 一格不动。

### ⑥b Store 屏「有哪些系列在售」由**内容层自己给出**，零新增下发面

`[既有推演]`

counterpart 提案 `productId` 与 `seriesId` 之间是**机械变换**而非映射表（同「能机械变换的绝不建第二张手写表」—— `code → ERR_*` 是本库首例）。推论落在客户端侧：

- **在售系列清单** = 对 `AllIncludingDisabled<CharacterData>()` 按 `SeriesId` 归组，取 `Track == Paid` 且不在 `entitlement.CharacterSeries` 内的那些。**走 `AllIncludingDisabled()` 而非 `AllEnabled()`**：flags 秒关一个角色不应让整个系列从商店里消失（该情形由前置条件 7 置灰承接，见 ⑦）。
- **`productId`** 由同一条机械变换从 `SeriesId` 拼出，**客户端不硬编码任何 `productId` 字面量、不持任何映射表**。
- **价格与货币仍由平台商店按 SKU 返回**，客户端不硬编码金额（与 premium bundle 的既定纪律同款）。
- ⇒ **零新增端点、零新增下发通道、零新增内容字段**（`SeriesId` 那一格已由 ② 给出，一格两用）。变换规则本身的权威在 counterpart，本库不复述规则文本。

### ⑦ 购买入口的前置条件：既有那张表**按作用域重排为两段，不新开第二张表**

`[既有推演]`

| 段 | # | 条件 | 适用 SKU | 不满足时 |
|---|---|---|---|---|
| **全局**（Store 入口本身） | 1 | 当前在主菜单（不在任何轮回内） | 全部 | 入口不渲染 |
| | 2 | 待发队列为空（或一次 `FlushPendingAsync` 成功） | 全部 | 入口置灰 + 「请先完成同步」 |
| | 5 | 当前平台存在可用渠道 | 全部 | 入口不渲染 |
| **per-SKU** | 3 | `GrantableCount(Power, Player) ≥ 1` 且 `GrantableCount(Item, Player) ≥ 2` | **仅 premium bundle** | 该 SKU 置灰 + 说明 + `PushError` + 上报 |
| | 4 | `BundleGrantOrdinal == BundleRedeemedOrdinal` | **仅 premium bundle** | 该 SKU 置灰 + 「上一笔购买正在发放」 |
| | **6（新）** | 该 `SeriesId` **不在** `entitlement.CharacterSeries` 内 | **仅付费系列** | 该 SKU 置灰 + `STORE_UNAVAILABLE_SERIES_OWNED`（「已拥有」）—— 非消耗型商品的通行做法 |
| | **7（新）** | 该系列的全部条目当前 `ContentEnabled == true` | **仅付费系列** | 该 SKU 置灰 + `STORE_UNAVAILABLE_SERIES_PARTIAL` + 上报 |

- **条件 3 / 4 原本就是 premium bundle 兑现形态特有的**（空池、水位），重排只是把这一事实写明；**既有五条一条不删、语义一字不改**，新增的只有 6 / 7 两行与「作用域」这一列。
- **条件 7 是闸 ② 同一条纪律的第二次兑现**（`systems/monetization.md`：「把失败点挪到掏钱之前，从『退款争议』降级为『暂不可购买』」）。它取**灰态**而非不渲染是对的：flags 秒关是临时运营动作，灰态的既有语义正是「暂不可用、会恢复」。

### ⑧ 呈现：Store 屏加一个列表 / 结果态；`STORE_` 分区加普通键

`[既有推演]`（C16 · C17）

- **不新增屏、不新增主菜单入口。** 与外观族的既定处置逐字同款（「Store 已是一屏多结果态 ⇒ 外观购买是它的又一个列表 / 结果态」）。
- **系列详情页（付款前）必须列出本系列的全部角色**：复用角色选择屏卡面的同一套构件（`Artwork` + 灵根一行 + 神通名与一行简述 + 两门绑定功法名与各一行简述），**不展示数值**，**不标推荐**，**不写任何「更强」暗示**（`ADR-0255` 严格横向）。这是 C17 诚实性纪律在本付费点上的兑现。
- **解锁结果态** = Store 屏的一个结果态，列出本次解锁的角色。它不是推销面（发生在付款之后、内容已定）。
- **文案键**：`STORE_` 分区新增普通键（`STORE_SERIES_*` · `STORE_UNAVAILABLE_SERIES_OWNED` · `STORE_UNAVAILABLE_SERIES_PARTIAL`），**不占 `ERR_` 前缀** —— 它们是本地业务拒绝，没有后端 `code`。后端购买域 `code` 对应的 `ERR_*` 照既有机械变换得出、不手写。

### ⑨ 单向棘轮的 `/audit-content` 核对项：基线 = 内容层的系列台账

`[取向选择 → 已给推荐]` / `[既有推演]`

C3 把棘轮判给了内容纪律 + `/audit-content`，但**没说基线从哪来** —— `/audit-content` 对的是当前库，没有历史。提案：

- 在 `content/character/_index.md`（类型档案）建一张**系列台账**：`seriesId | track | 五行构成 | 首次发版的 appVersion`。它是内容层既有的「条目台账」形态的延伸，不是新机制。
- `/audit-content` 新增一条核对项，**方向敏感**：

  | 台账 → `.tres` | 判定 |
  |---|---|
  | `Free` → `Paid` | 🔴 **违反单向棘轮**，报错 |
  | `Paid` → `Free` | 合法（棘轮只禁一个方向），`PushWarning` 级提示「台账须同批更新」 |
  | 台账缺该 `seriesId` | 提示补登（新系列） |

- **不做运行时机制**（`ADR-0255` 明写），故这条只活在 `/audit-content` 与发版清单里，一行代码不进客户端。

### ⑩ `Track == Paid` 的退役口径：临时关闭可以，**永久退役不可以**

`[既有推演]`

C18「付费内容不会被游戏销毁」与「线上可秒关一个问题角色」在付费轨道上正面相遇。提案把它切成两档：

| 动作 | 对 `Track == Free` | 对 `Track == Paid` |
|---|---|---|
| **flags 秒关**（临时、可恢复） | 允许（既定运营手段） | **允许** —— 运营应急不能为轨道让路。它是**运营事故不是玩法分支**：该系列购买入口按条件 7 置灰、已购玩家该角色暂不可选、一律上报 |
| **基线里置 `ContentEnabled = false`**（永久退役） | 允许（既定退役形态） | **禁止**，落一条加载期 `PushError`：`Track == Paid` 且基线 `ContentEnabled == false` → 报错 + 抛，带 `characterId` 与 `seriesId` |

这把 C18 从「已授予的法则不被拿走」平移到了角色轨道上，且与内容层的「跨发版基线 `Id` 集合单调不减」自洽（`Id` 仍在，只是不许把付费条目的 `ContentEnabled` 永久置假）。**它收窄了 `content-service.md` 退役表对 `CharacterData` 的既有口径** —— 见「与既有决策的张力」。

### ⑪ `schemaVersion`：**第一次真实 bump（v2）**，除非付费系列在首发前落地

`[既有推演]`（C10 · C11）

- `/entitlement/characterSeries` 落在 `entitlement` 内，而 `entitlement` 是**两个受回声校验约束的顶层键之一** ⇒ 命中形态纪律 ⑤ 的第三档：**两侧同批落笔并进版本行**。它**不能**走「不透明段内追加字段不 bump」那一档。
- `ADR-0255` 把付费系列定为「后续版本引入」⇒ 预期路径是**首发之后** ⇒ 这将是本库的**第一次真实 bump**，`schemaVersion = 2`。登记表拟新增一行：

  | `schemaVersion` | 本版纳入的结构改动 | 老档处置口径 | 触碰透明 / 回声路径 | golden 形状快照 | 权威回链 |
  |---|---|---|---|---|---|
  | **2** | `PlayerEntitlement` 新增 `characterSeries`（元素 `CharacterSeriesEntry`） | **v1 → v2 迁移器写入空列表**；迁移之后仍缺该格 → 按回声路径的必需缺失处置 | **有**：`/entitlement/characterSeries` 是透明路径且由后端写入 ⇒ 受回声约束 | `profile-shape-v2.json` | `systems/player-profile/_index.md` · `systems/monetization.md` |

- **条件分支（如实写下）：** 若付费系列改在首发**之前**落地，按 C11「首发前的一切改动全部归入 `schemaVersion = 1`」，本格并入 v1 清单新增一行，**不产生 bump**。两条路径的结构一字不差，只是登记位置不同。

- **老档口径的衔接（本方案顺带答出的一格）。** 既有纪律有两条看似打架的话：「老档缺字段 → 空列表（无损）」与「**回声路径缺失 → 走必需缺失处置，不补默认值**」。准确解是**它们作用在不同时点**：
  - **迁移时点**（v1 → v2）：迁移器写入空列表 —— 迁移是结构搬运，v1 档里本就没有这一格，这不是「客户端造一个值去回声」。
  - **迁移之后的读档时点**：该格缺失即真异常，按 C9 走 `PushError` + `entitlement` 本次不进 diff + 触发一次 pull。
  - 首次 pull 立即带回权威值，空列表的存活期以一次往返计。
  - **这条口径对 `Cosmetic` 那格逐字同款适用**（它是同形态的第二例），落笔时建议一并写明 —— 详见「与既有决策的张力」第 4 条。

## 具体形态（可 derive 的落地面）

**`CharacterData` 字段表新增两行**（接在既有 7 行之后）：

| # | 字段 | 类型 | 必填 | 语义 / 取值 |
|---|---|---|:--:|---|
| 8 | `SeriesId` | `string` | 是 | 两段式 `character_series.<snake_case_slug>`。所属角色系列；同系列条目数 ∈ {5, 10} |
| 9 | `Track` | `CharacterTrack` | 是 | `Unspecified` = 0（哨兵）/ `Free` = 1 / `Paid` = 2。同系列必须一致 |

**`CharacterData` 加载期校验新增四条**：#12 ~ #15，见建议方案 ③；另加 ⑩ 的一条（`Track == Paid` 且基线 `ContentEnabled == false` → `PushError` + 抛）。

**`PlayerEntitlement` 新增一格 + 新 record**：见建议方案 ④。

**`PlayerProfile` 完整字段表第 16 行的「权威 / 写入通道」列微调**：`entitlement` 由「2 字段」改为含 `characterSeries`；写入通道列补一句「`CharacterSeries` 由后端写、经 pull 下行，无客户端通道、**受回声约束**」。

**`life-cycle-service.GetSelectableCharacters()` 的过滤式**：见建议方案 ⑤。签名不变（`IReadOnlyList<CharacterData> GetSelectableCharacters()`）。

**`ux/screen-flow.md`**：Store 屏新增「系列列表」「系列详情」「解锁结果态」三个结果态（不新增屏）；角色选择屏**不变**（除非 ①「仍需用户决定」裁向可见）。

**`ux/error-and-blocking-ux.md`**：`STORE_` 分区说明补上系列相关键。

**`content/character/_index.md`**：新增系列台账表（`seriesId | track | 五行构成 | 首次发版的 appVersion`）与 `/audit-content` 的棘轮核对项。

**`systems/services/profile-schema-versions.md`**：新增一行（或并入 v1 清单），见 ⑪。

**跨库回链（不复述）：** SKU 命名与粒度 · 验票后写入报文与幂等 / CAS 语义 · `profile-sync` 白名单与封闭表加行 · 兼容矩阵登记 · 购买域失败 `code` ⇒ 全部在 `backend-design-documents/inbox/solution-draft-premium-character-series-unlock.md`。

## 后果

- **存档 schema**：一次真实 bump（v2）+ 一个 v1 → v2 迁移器（写入空列表）+ 一份 `profile-shape-v2.json` golden 快照。这是本库从「首发前一切归 v1」走出来的第一步，迁移链路首次被真正走一遍。
- **内容层**：`content/character/` 的每个条目多两格必填；类型档案多一张系列台账；`/audit-content` 多两条核对项（棘轮 + 五行对称）。
- **服务层**：`life-cycle-service` 多一层过滤（一次集合包含判定）；`profile-service` / `ContentRegistry` / `sync-service` 的**签名与结构一格不动**。
- **UI 层**：Store 屏多三个结果态；`STORE_` 分区多几个键。屏清单不变、主菜单入口预算不变。
- **不新增**：内容类型、autoload、`ProfileChangeSpec` 列、`CostKey` / `StatKey` 成员、RNG 子流、`AccountStream` 成员、存档点、拦截点。
- **迁移风险点**：`/entitlement/characterSeries` 是回声路径 ⇒ 迁移器写入的空列表若被当成「客户端造的值」上行回声，会在正常老档上招致整批拒绝。⑪ 的时点切分就是为堵这一条 —— 它必须与后端同批落笔（C10）。

## 备选方案（已考虑并否决）

- **持有集合存角色 id（而非系列 id）** — 否决：迫使后端持一张「SKU → 5/10 个 `character.<slug>`」的内容编排表，制造第二权威且无发现机制。
- **单个角色零售 SKU 与整系列礼包并存** — 否决：`ADR-0255` 已明确否决单个角色零售（C2）。「付 4 个单解之价」是定价锚，不是可购商品。
- **`bool IsPaid`** — 否决：Godot `[Export]` 未填即 `false`，漏填静默落进**不可逆**的免费轨道（棘轮）。
- **现在就建 `CharacterSeriesData` 内容类型** — 否决（**但留好路**）：系列除 id + 轨道之外的字段面（名称 / 主题 / 商店插图）正是另一条尚未答定的待答项（「推出时点与主题包装」），此刻建类型就得替它拍板字段。日后需要时走一次 `/scaffold-content-type`，`SeriesId` 原地变成指向它的引用键 —— `CharacterData` 是模板、不落存档 ⇒ **零存档增量、零迁移、后端零影响**。
- **`CharacterSeriesRedeemedOrdinal` 兑现水位** — 否决：水位的存在理由是「发货在客户端」，本付费点发货在后端（详见 ⑥）。
- **把解锁过滤落进 `ContentRegistry`（`AllEnabled(accountContext)`）** — 否决：C13 已为 flags 分桶把这个形态关死；让内容层反向依赖存档层。
- **在 `PlayerEntitlement` 之外另开一个顶层键装解锁集合** — 否决：C6 明写该类装「付费凭证本身」，解锁集合正是付费凭证；另开顶层键还要多一次 golden 快照的顶层键登记。
- **落 `CapabilityFlag` 或 modifier pipeline** — 否决：C6 的共同判据（派生态不能承载原始事实），且两者受轮回级禁用截断。
- **购后 pull 失败时同样阻塞「开始新轮回」** — 否决：本付费点无未兑现状态，阻塞是在惩罚一个不存在的风险；未到账的最坏后果是几个角色暂时选不到。
- **五行对称做成加载期硬校验** — 否决：未来 10 人系列未必按 C(5,2) 铺；与 C3 把棘轮判给内容纪律同一条处置。

## 与既有决策的张力

> **本节的 5 条已于 2026-09-11 批量评审全部裁定**，逐条裁决见各条末尾的「→ 已裁决」。

1. **「线上可秒关一个问题角色」 vs 「付费内容不会被游戏销毁」。** `systems/character-profile/_index.md` 明写关一个角色是既定运营手段，`systems/monetization.md` 明写付费内容不被销毁。⑩ 的两档切分（临时 flags 关闭允许 / 基线永久退役对 `Track == Paid` 禁止）是本方案的提案解，**它需要用户点头** —— 代价是运营在付费系列上少了「永久下架一个问题角色」这一手，只能靠改内容修。不松动时的替代方案：允许永久退役但要求**同批为已购玩家补发同系列的替代角色**（需要一条补偿机制，而本作没有账号级可支配货币 ⇒ 成本显著更高）。
   **→ 已裁决（2026-09-11 · 批量评审）：采纳 ⑩ 的提案解 —— 禁止永久退役付费角色（落加载期 `PushError`），临时 flags 关闭允许（可逆）。** 用户已知悉代价（运营失去「永久下架一个问题付费角色」这一手）并选定。与本轮另一项裁决「购买窗口关闭后已购玩家永久可用」同向且互为支撑。
2. **`content-service.md` 退役表对 `CharacterData` 的口径被 ⑩ 按轨道收窄。** 该表现在写的是「抽取池成员 → 基线里置 `ContentEnabled = false` 退役」，无轨道维度。落笔时须在该表或其附注上写明这条例外，否则两处并存即互相矛盾。
3. **「购后 pull 失败 ⇒ 阻塞主菜单」不再是全部付费点的通则。** 本方案主张它只适用于有客户端兑现动作的付费点（当前只有 premium bundle）。`systems/monetization.md` 那句现在读起来像通则，落笔时须加限定词。**premium bundle 的行为一字不改。**
4. **回声路径的「老档缺字段」口径此前没有迁移时点的切分。** `systems/player-profile/_index.md` 写的是「回声路径缺失 → 必需缺失处置，不补默认值」，而一次真实 bump 的迁移器必须写入空列表。⑪ 给出了时点切分（迁移时点 vs 迁移后读档时点）。**这条同样适用于尚未落地的 `Cosmetic` 那格** —— 它是同形态的第二例，建议一并写明，否则两个付费点各自推演一遍。
5. **`ADR-0255` 的「付 4 个单解之价」在本方案下不对应任何可购商品。** ① 把它解读为定价锚（记账单位）。若用户本意是「单解 SKU 真实存在」，则与 `ADR-0255` 备选方案里明写否决的「单个角色零售」直接冲突，须先裁决改 ADR 还是改解读 —— 本方案按**不改 ADR** 推演。
   **→ 已裁决（2026-09-11 · 批量评审）：单解 SKU 不存在，「付 4 个单解之价」就是定价锚。** 商店只上架整系列礼包一种商品，玩家看不到也买不到单个角色。`ADR-0255` **不需改写**，本方案 ① 的推演（解锁粒度 = 系列、后端 SKU 粒度 = 系列级且只一种）逐字成立。张力本身随之消解。

## 前置依赖

- **counterpart（后端草稿）的四项，须与本方案同时采纳：** ① **`productId ↔ seriesId` 的机械变换规则** —— 本方案 ①（解锁粒度 = 系列）与 ⑥b（在售清单由内容层自给、零新增下发面）的成立前提；② **验票后写入 `/entitlement/characterSeries` 的报文与幂等 / 事务语义** —— 本方案 ⑥「客户端零兑现事务」直接建立在它之上；③ **`profile-sync` 后端写入字段封闭表与透明字段白名单各加一行** —— 本方案 ④ 的「受回声约束」这一格由它定义；④ **`verify` / `GET receipt` 应答按 SKU 类别分形** —— 本方案 ⑥ 的 `IPurchaseBackend` 三个应答 record 随它同批调整。**单侧采纳即两侧不一致**：客户端会读一个后端从不写的路径，或后端写一个客户端不认的 path。
- **回声比对的有序性依赖本方案的一条纪律。** counterpart 对 `/entitlement/characterSeries` 取**有序逐元素**比较（同 `identities`），其成立前提是后端恒在尾部追加、**客户端原样回声不重排、不去重、不归一化** —— 即本方案 ④ 读档校验表的第三行。两条须一并采纳。
- **counterpart 的兼容矩阵登记**须与本方案 ⑪ 的版本行同批（C10：受回声约束的顶层键内追加字段 = 两侧同批落笔并进版本行；且矩阵先加、客户端后发）。
- **`open-questions/06-meta-progression.md`「双灵根批与付费系列的推出时点与主题包装」** —— 首批付费系列的 `SeriesId` 具体 slug、系列名与五行构成在它答定前**无法定稿**；本方案只定结构，不填任何 `SeriesId` 取值。
- **⑪ 的版本号取决于付费系列落地是否在首发之后**（`ADR-0255` 说「后续版本引入」，故预期是 v2；若提前到首发前则并入 v1）。结构与该分支无关。

## 仍需用户决定

### （1）付费系列的**推销面穷举** —— 未拥有的付费角色是否出现在角色选择屏？

> **→ 已裁决（2026-09-11 · 批量评审）：选项 A —— 完全不出现在角色选择屏。** 付费入口只在主菜单 Store 一处；角色选择屏只列玩家已拥有的角色，不为未拥有项设卡位、不加底部入口。用户已知悉代价（付费面近乎不可发现、转化依赖玩家主动进 Store）并选定。

`systems/monetization.md` 为 premium bundle 写下了「允许的全部呈现穷举为三处」，付费角色系列作为新的一支，它的推销面穷举尚未定。这是真取向（无客观最优，取决于产品取向）：

| 选项 | 后果 |
|---|---|
| **A（推荐）· 完全不出现在角色选择屏** | 与既有「安静的一等入口 · 绝不在失败时刻推销」的克制基调一致；角色选择屏保持「这些都是你能玩的」这一干净语义，也不必为未拥有项设计第七个卡位。**代价如实写下：付费面近乎不可发现** —— 发现面只剩 Store 屏与版本更新公告，转化依赖玩家主动进入 Store |
| **B · 灰显 + 购买引导** | 标准 IAP 转化做法，发现成本最低。**代价：** 角色选择屏是每次开新轮回的必经屏，把未拥有项常驻在那里等于把推销面从「主菜单一个入口」扩成「每局开场一次」；且它与「不标推荐 / 不展示数值 / 首批刻意压平复杂度」的选择屏设计基调冲突 —— 玩家会把「灰的那几个」读成「更好的那几个」，正是 `ADR-0255` 严格横向要避免的观感 |
| **C · 只在 Store 屏内展示，但角色选择屏底部加一行静态入口** | 折中；但主菜单 / 选择屏的入口预算已明确紧张（同一条理由否决过「逐本图鉴开七个入口」与外观的 Wardrobe 入口） |

**推荐 A。** 理由：本库在推销面上的既定取向是**一致地克制**（重试耗尽不提示购买、兑现结果不算推销面、拒开第二个入口），而 B 是这条取向上最大的一次反向；且 A 的代价（可发现性）有非付费的替代解（版本更新公告、Store 屏首次进入时的一次性提示）。

### （2）**付费 → 免费**的反方向是否允许（棘轮只定了一个方向）

> **→ 已裁决（2026-09-11 · 批量评审）：选项 B —— 棘轮双向，付费的也永不改免费。** 付费轨道一旦发布即永久付费。`/audit-content` 核对项 ⑨ 的方向表**两个方向各留一行**（`Free → Paid` 与 `Paid → Free` 皆为违规），`Track` 在发布后成为完全不可变的字段。
>
> **→ 同批新增一条机制（用户在评审中提出，非本草稿原有）：每个付费系列有购买时限（限时销售窗口）。** 三条语义已一并裁定：
> 1. **不绝版** —— 窗口关闭后系列可**重新上架**（如周年复刻），或**转为常驻商品仅失去限时优惠价**；两种具体形态均可，由运营按系列择一，设计上不预设。**限时的是价格与销售节奏，不是可得性。**
> 2. **已购买的玩家永久可用** —— 下架的只是购买入口，已写入 `PlayerEntitlement.CharacterSeries` 的解锁记录不受任何影响。这与本轮另一项裁决「禁止永久退役付费角色」（见 ⑩）同向且互为支撑。
> 3. ⇒ **本草稿须补一处落地面**：系列的**在售窗口**是一个内容层属性（与 §⑥b「有哪些系列在售由内容层自己给出」同一条通道，零新增下发面），后端侧另需在 SKU 表上加「上架窗口」字段用于校验购买请求（见 counterpart）。**窗口字段不进存档、不进 `PlayerEntitlement`** —— 它约束的是「能不能买」，不是「拥有什么」。
>
> 用户已知悉 B 的代价（永久失去「老系列免费化拉新」这一手）并选定。

`ADR-0255` 只定了「一旦免费永不改付费」，反方向未表态。它有真实的结构后果（`/audit-content` 核对项 ⑨ 的方向表要不要留那一行、已购玩家的 `characterSeries` 条目会变成什么）：

| 选项 | 后果 |
|---|---|
| **A（推荐）· 允许，但不承诺、不做任何补偿机制** | 老内容免费化是拉新的常规手段，结构上零成本（改一个字段值，走「只改不增」路径；已购玩家的条目成为**无害的幂等残留** —— 与「禁用表条目不因失去持有而自动移除」同一条处置）。**代价如实写下：已付费玩家会经历「我买的现在白送」的负面公平事件**，而本作**没有补偿通道**（补偿要求一条账号级可支配货币，已被明确关死） |
| **B · 也禁止（棘轮双向）** | 付费轨道一旦发布即永久付费，公平性零争议。**代价：** 运营失去「把老系列免费化拉新」这一手，而它恰是买断式横向内容扩张最常用的长尾手段 |
| **C · 允许，且给已购玩家补偿** | 需要一条补偿通道 —— 本作没有账号级可支配货币，为它引入一条等于新开一套经济（该形态已在空池兜底处被明确否决） |

**推荐 A。** 理由：C 的前提（可支配货币）已被本库明确关死；B 与 A 之间是纯运营取向，而 A 保留选择权且结构成本为零 —— 真要不做，不做即可，不需要在结构上禁止它。

---

> **两份草稿须成对评审。** 对侧：`backend-design-documents/inbox/solution-draft-premium-character-series-unlock.md`。
