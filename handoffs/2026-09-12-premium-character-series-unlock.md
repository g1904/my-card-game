# 付费角色系列的解锁载体与购买流程形态（客户端半）

- id: 2026-09-12-premium-character-series-unlock
- date: 2026-09-12
- topic: systems/character-profile（`SeriesId` / `Track` 两格 · 加载期校验 · 轨道退役口径）| systems/player-profile（`PlayerEntitlement.CharacterSeries`）| systems/monetization（第三支的购买流程 · 前置条件表 · 购买时限 · 呈现穷举）| systems/services/life-cycle-service（取池过滤）| systems/services/profile-schema-versions（v2）| systems/services/content-service（退役表按轨道收窄）| ux/screen-flow · ux/error-and-blocking-ux | content/character
- status: distilled
- distilled-to: systems/character-profile/_index.md, systems/player-profile/_index.md, systems/monetization.md, systems/services/life-cycle-service.md, systems/services/profile-schema-versions.md, systems/services/content-service.md, ux/screen-flow.md, ux/error-and-blocking-ux.md, content/character/_index.md

> **对侧（后端半）：** `backend-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`。SKU 命名与粒度、`productId ↔ seriesId` 机械变换规则、验票报文与幂等 / 事务语义、`profile-sync` 两张表加行、兼容矩阵登记、购买域失败 `code`、SKU 表上架窗口字段 —— 全部归对侧，本文件一字不复述。

## Intent（distilled）

**一句话：** 付费角色系列的解锁落成**一格内容层轨道标记 + 一格账号级持有集合 + 一条取池过滤 + 一次真实 schema bump**，购买流程复用 premium bundle 的购买段而**整个兑现段不存在**——客户端零 `TryApply`、零掷骰、零兑现水位、零阻塞。

### 一、解锁粒度 = 系列，不是单个角色

单个角色零售已被 `ADR-0255` 明确否决 ⇒ 可购 SKU 只有「整系列礼包」一种；「付 4 个 / 8 个单解之价」是**定价锚（记账单位）**，不对应任何可购商品。由此推出持有集合的元素粒度是**系列 id**：若存角色 id，边界另一侧就必须持一张「SKU → 该系列的 5 / 10 个 `character.<slug>`」的表，那是内容编排知识，抄到另一侧即制造第二权威而无发现机制。

### 二、`CharacterData` 加两格：`SeriesId` + `Track`

- `SeriesId : string`，两段式 `character_series.<snake_case_slug>`（前缀与既有主类型前缀词表不撞车，且为日后真建 `CharacterSeriesData` 留好引用键）。
- `Track : CharacterTrack`，枚举 `Unspecified = 0 / Free = 1 / Paid = 2`。**必须是带哨兵的枚举而非 `bool IsPaid`**：`[Export]` 未填即取 0，`bool` 的漏填会静默落进免费轨道，而轨道发布后不可变 ⇒ 一次漏填不可逆。
- 两格都是模板静态字段 ⇒ **存档增量为 0**；bump 只由 `PlayerEntitlement` 那一格产生。
- **不新建 `CharacterSeriesData` 内容类型**（但留好路）：系列的名称 / 主题 / 商店插图取决于尚未答定的推出时点与主题包装，此刻建类型就得替它拍板字段。

### 三、加载期校验新增五条（#14 ~ #18）

`Track == Unspecified` · `SeriesId` 形态不合 · 同系列 `Track` 不一致 · 同系列条目数 ∉ {5, 10} · `Track == Paid` 且基线 `ContentEnabled == false`。后三条走 `AllIncludingDisabled()`——flags 不参与合并后强校验，按 `AllEnabled()` 统计会让「线上秒关一个问题角色」把启动打崩。**五行对称不做代码校验**（归 `/audit-content`）；**不新增「解锁后池为空」这条校验**（首批五角恒免费恒可用 ⇒ 永不可达，而一条永不可达的校验只会误导后来者以为免费轨道可能为空）。

### 四、`PlayerEntitlement.CharacterSeries`

`IReadOnlyList<CharacterSeriesEntry>`，元素 `readonly record struct CharacterSeriesEntry(string SeriesId)`，JSON path `/entitlement/characterSeries`，默认空列表。**写入方只有后端**（验票事务内尾部追加），客户端经 pull 读到、**无写入通道**（不进任何 `ProfileChangeSpec` 列，`ResourceElements` 不加行 ⇒ 日后误写的置位当场在施加时 `PushError` + 整批拒绝）。**不配兑现水位、不加 `Status` / `Charges` / `SourceCode`**。受回声约束；**客户端对该 path 不改写、不去重、不归一化**——对侧的有序逐元素比较依赖这一条。

读档校验三情形：非数组 / 缺 `SeriesId` → `PushError` + `entitlement` 本次不进 diff + 触发 pull、不钳制；`SeriesId` 解析不到内容条目 → `PushWarning` + 保留条目；同 `SeriesId` 重复 → `PushWarning` + 呈现层去重、不改写存档值。

**回声路径「老档缺字段」的两个时点（本次顺带答出，对 `Cosmetic` 同款适用）：** 迁移时点写入空列表（结构搬运，不是客户端造值去回声）；迁移之后的读档时点缺失即真异常，走必需缺失处置。首次 pull 立即带回权威值，空列表存活期以一次往返计。

### 五、取池过滤落 `life-cycle-service.GetSelectableCharacters()`

`AllEnabled<CharacterData>()` ∩ 绑定条目全启用 ∩（`Track == Free` ∨ 解锁集合含该 `SeriesId`）。签名不变、`StartCycle` 零改动（既有守卫原样覆盖新增这一层）、完全不涉及 RNG。**绝不写成 `AllEnabled(accountContext)`**——让内容层反向依赖存档层，这条形态已为 flags 分桶明确关死。

### 六、购买流程：购买段复用，兑现段整段不存在

渠道封装层（`StoreChannelManager` / `IStoreChannel` / `UnavailableStoreChannel` / `IPurchaseBackend`）一格不改。授予即后端写入的那一格，pull 下来就是终态 ⇒ 客户端零 `TryApply`、零 `AccountRng`、零水位、零「差值 > 1」异常路径、空池三道闸一概不适用。

- **照抄一个 `CharacterSeriesRedeemedOrdinal` 是最诱人的错误答案**：水位存在的唯一理由是「发货动作在客户端，需要一个云端可见的已发货记号」；本付费点的发货在后端，验票成功那一刻货已在云端。
- **跨启动补入口两条即闭合**：本地持久化 `receiptId` + 收据幂等读；每次启动查询平台未完成交易并补验票（Google Play Billing / StoreKit 2 的标准形态，兜住卸载重装 / 换设备 / 清缓存）。
- **购后 pull 失败不阻塞「开始新轮回」**——本付费点没有未兑现状态，未到账的最坏后果是几个角色暂时选不到。**premium bundle 的阻塞纪律一字不改**，只是不再被读作全部付费点的通则（`systems/monetization.md` 已加限定词）。
- 失败处置沿用既有五情形表，不新增情形；`IPurchaseBackend` 的三个应答 record 随对侧按 SKU 类别分形同批调整，**接口方法签名不变**。

### 七、在售清单与购买入口前置条件

在售系列清单 = `AllIncludingDisabled<CharacterData>()` 按 `SeriesId` 归组，取付费、未拥有、在窗口内的那些（**走 `AllIncludingDisabled()`**：flags 秒关一个角色不应让整个系列从商店消失，该情形由前置条件置灰承接）。`productId` 由 `SeriesId` 机械变换拼出，客户端不硬编码字面量、不持映射表 ⇒ **零新增端点、零新增下发通道、零新增内容字段**。

购买入口的既有前置条件表**按作用域重排为两段**（全局段管 Store 入口本身 / per-SKU 段管某个商品），既有五条一条不删、语义一字不改，新增 6（已拥有）· 7（系列有条目被关）· 8（不在在售窗口内）三行与「作用域」一列。

### 八、购买时限（限时销售窗口）

每个付费系列有一段在售窗口。三条语义：**不绝版**（窗口关闭后可重新上架，或转常驻仅失去限时优惠价，两种形态均可、设计上不预设）· **已购玩家永久可用**（下架的只是购买入口，解锁记录不受任何影响）· **限时的是价格与销售节奏，不是可得性**。窗口是**内容层属性**，与在售清单同一条通道 ⇒ 零新增下发面；**不进存档、不进 `PlayerEntitlement`**——它约束「能不能买」，不是「拥有什么」。

### 九、轨道棘轮双向；`Track` 发布后完全不可变

`Free → Paid` 与 `Paid → Free` **都是违规**。禁反方向的理由：老系列免费化会让已付费玩家撞上「我买的现在白送」，而本作**没有补偿通道**（补偿要求一条账号级可支配货币，已被明确关死）。代价如实写下：运营失去「把老系列免费化拉新」这一手。两个方向都落为内容纪律 + `/audit-content` 核对项，**不做运行时机制**；基线由 `content/character/_index.md` 的系列台账承载（`/audit-content` 对的是当前库、没有历史）。

### 十、`Track == Paid` 的退役口径：临时关闭可以，永久退役不可以

flags 秒关（临时、可恢复）对两条轨道都允许——运营应急不为轨道让路，它是运营事故不是玩法分支；基线里置 `ContentEnabled = false`（永久退役）对 `Track == Paid` **禁止**，落加载期 `PushError`。这把「付费内容不会被游戏销毁」平移到角色轨道，与「跨发版基线 `Id` 集合单调不减」自洽。代价：运营少了「永久下架一个问题付费角色」这一手，只能靠改内容修。`systems/services/content-service.md` 的退役表已按轨道收窄，否则两处并存即互相矛盾。

### 十一、`schemaVersion`：第一次真实 bump（v2）

`/entitlement/characterSeries` 落在受回声校验约束的顶层键 `entitlement` 内 ⇒ 命中形态纪律 ⑤ 第三档（两侧同批落笔并进版本行），**不能**走「不透明段内追加不 bump」那一档。**条件分支如实写下：** 若付费系列改在首发之前落地，按「首发前的一切改动全部归入 v1」并入 v1 清单，不产生 bump；两条路径的结构一字不差，只是登记位置不同。

### 十二、呈现

Store 屏新增三个结果态（系列列表 · 系列详情 · 解锁结果态），**不新增屏、不新增主菜单入口**。系列详情页付款前必须列出本系列全部角色（复用角色选择屏卡面构件，不展示数值、不标推荐、不写「更强」暗示）。**角色选择屏不变：未拥有的付费角色完全不出现**——不设卡位、不灰显、不加底部入口；代价是付费面近乎不可发现，转化依赖玩家主动进 Store，这是「一致地克制」这条推销面取向被接受的结果。文案走 `STORE_` 分区普通键（`STORE_SERIES_*` · `STORE_UNAVAILABLE_SERIES_OWNED` / `_PARTIAL` / `_WINDOW`），**不占 `ERR_` 前缀**。

## Clarifications

本次输入是 `inbox/solution-draft-premium-character-series-unlock.md`（`status: reviewed`），2 项取向 + 5 条张力已于 2026-09-11 批量评审全部裁定，视同用户当面拍板，未重新发问。

- **张力 1（秒关 vs 付费内容不被销毁）** → 采纳两档切分：**禁止永久退役付费角色**（加载期 `PushError`），临时 flags 关闭允许。用户已知悉代价（运营失去「永久下架一个问题付费角色」这一手）。
- **张力 5 / 定价锚** → **单解 SKU 不存在**，「付 4 个单解之价」就是定价锚；`ADR-0255` **不改写**，张力随之消解。
- **仍需用户决定（1）推销面穷举** → **选项 A：未拥有的付费角色完全不出现在角色选择屏**，付费入口只在主菜单 Store 一处。用户已知悉代价（付费面近乎不可发现）。
- **仍需用户决定（2）付费 → 免费方向** → **选项 B：棘轮双向**，付费的也永不改免费；`/audit-content` 方向表两个方向各留一行，`Track` 发布后完全不可变。用户已知悉代价（永久失去「老系列免费化拉新」这一手）。
- **新增机制（用户在评审中提出）：购买时限（限时销售窗口）**，三条语义见上方第八节。客户端侧落地面 = 在售窗口作为内容层属性接进在售清单推导与购买入口前置条件表。
- **标准默认（自动采纳）：** 窗口外的 SKU 取**置灰 + 一行说明**而非移除控件（灰态的既有语义是「暂不可用、会恢复」，而窗口不绝版、会重开——移除控件的既有判据是「已成事实、永不恢复」，本情形不命中）· 灰态说明键取 `STORE_UNAVAILABLE_SERIES_WINDOW`（沿用 `STORE_UNAVAILABLE_*` 的既有构词）· 系列名与角色名不进翻译键（内容层 `LocalizedText`，呈现层作格式参数插入）· 加载期新增校验统一接在既有编号之后（#14 ~ #18）。

## Open questions

- **首批付费系列的 `SeriesId` 具体 slug、系列名与五行构成**——阻于「双灵根批与付费系列的推出时点与主题包装」。本次只定结构，不填任何 `SeriesId` 取值。
- **在售窗口在内容层的具体承载形态**（落 `CharacterData` 的一格、还是随日后的 `CharacterSeriesData` 一起给出）——取决于系列内容类型是否建、何时建；本次只定「它是内容层属性、零新增下发面、不进存档」这三条语义边界。

## 前置依赖（对侧同批采纳，缺一即两侧不一致）

- `productId ↔ seriesId` 的机械变换规则（本半的在售清单自给与零新增下发面建立在它之上）。
- 验票后写入 `/entitlement/characterSeries` 的报文与幂等 / 事务语义（本半「客户端零兑现事务」直接建立在它之上）。
- `profile-sync` 后端写入字段封闭表与透明字段白名单各加一行（本半的「受回声约束」由它定义）。
- `verify` / `GET receipt` 应答按 SKU 类别分形（本半 `IPurchaseBackend` 三个应答 record 随它同批调整）。
- 兼容矩阵的 `schemaVersion = 2` 登记须与本半的版本行同批，且**矩阵先加、客户端后发**。
- SKU 表的上架窗口字段与窗口外购买请求的拒绝语义（本半前置条件 8 的服务端对位）。

对侧 handoff：`backend-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`。
