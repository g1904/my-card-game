# Answer log premium-character-series-unlock

- 日期：2026-09-12
- 来源：`inbox/solution-draft-premium-character-series-unlock.md` → `handoffs/2026-09-12-premium-character-series-unlock.md`
- 移出条数：1

**付费角色系列的解锁载体与购买流程形态** → 整条答定。

- **解锁粒度 = 系列**（不是单个角色）：单个角色零售已被 `ADR-0255` 否决 ⇒ 可购 SKU 只有整系列礼包一种，「付 4 / 8 个单解之价」是**定价锚**，不对应任何可购商品；`ADR-0255` 不改写。
- **`CharacterData` 加两格**：`SeriesId : string`（`character_series.<snake_case_slug>`）+ `Track : CharacterTrack`（`Unspecified = 0` 哨兵 / `Free` / `Paid`）。两格都是模板静态字段 ⇒ 存档增量为 0。**不新建 `CharacterSeriesData` 内容类型**（留好路）。
- **加载期校验新增五条 #14 ~ #18**：`Track == Unspecified` · `SeriesId` 形态 · 同系列轨道一致 · 同系列条目数 ∈ {5, 10} · `Track == Paid` 且基线 `ContentEnabled == false`。后三条走 `AllIncludingDisabled()`；五行对称归 `/audit-content`；**不新增「解锁后池为空」这条校验**。
- **解锁载体 = `PlayerEntitlement.CharacterSeries : IReadOnlyList<CharacterSeriesEntry>`**（元素 `record struct CharacterSeriesEntry(string SeriesId)`，JSON path `/entitlement/characterSeries`）。**只由后端写**（验票事务内尾部追加）、客户端无写入通道、**不配兑现水位**、不加 `Status` / `Charges` / `SourceCode`、受回声约束、客户端不改写 / 不去重 / 不归一化。
- **取池过滤落 `life-cycle-service.GetSelectableCharacters()`**：`AllEnabled()` ∩ 绑定条目全启用 ∩（`Track == Free` ∨ 解锁集合含该 `SeriesId`）。签名不变、`StartCycle` 零改动、零 RNG；**绝不落 `ContentRegistry`**。
- **购买流程：购买段复用 premium bundle，兑现段整段不存在**。客户端零 `TryApply`、零 `AccountRng`、零水位、零阻塞；跨启动补入口两条（本地 `receiptId` 幂等读 + 启动期查询平台未完成交易）即闭合。
- **`schemaVersion = 2`**（本库第一次真实 bump），迁移器写入空列表；**条件分支如实写下**：若付费系列改在首发前落地则并入 v1 清单、不产生 bump。
- **回声路径「老档缺字段」的两个时点切分**（迁移时点 vs 迁移后读档时点）—— 顺带答出，**对 `Cosmetic` 那格同款适用**。

（`systems/character-profile/_index.md` · `systems/player-profile/_index.md` · `systems/monetization.md` · `systems/services/life-cycle-service.md` · `systems/services/profile-schema-versions.md` · `systems/services/content-service.md` · `ux/screen-flow.md` · `ux/error-and-blocking-ux.md` · `content/character/_index.md`）

## 批量评审裁决（2026-09-11 · 2 项取向 + 5 条张力，视同用户当面拍板）

**张力 1 · 「线上可秒关一个问题角色」 vs 「付费内容不会被游戏销毁」** → **采纳两档切分**：`Track == Paid` **禁止永久退役**（基线置 `ContentEnabled = false` ⇒ 加载期 `PushError`），**临时 flags 关闭允许**（可逆）。用户已知悉代价（运营失去「永久下架一个问题付费角色」这一手）。替代方案（允许永久退役但同批补发替代角色）因需要一条补偿机制而成本显著更高，未采纳。

**张力 2 · `content-service.md` 退役表口径** → 按轨道收窄，已在该表新增一行写明 `Track == Paid` 的例外（否则两处并存互相矛盾）。

**张力 3 · 「购后 pull 失败 ⇒ 阻塞主菜单」不再是通则** → 加限定词：只适用于**有客户端兑现动作的付费点**（当前只有 premium bundle）。**premium bundle 的行为一字不改。**

**张力 4 · 回声路径「老档缺字段」缺时点切分** → 按迁移时点 / 迁移后读档时点切开，并**一并写明它对 `Cosmetic` 那格同款适用**。

**张力 5 · `ADR-0255` 的「付 4 个单解之价」** → **单解 SKU 不存在**，它就是定价锚；`ADR-0255` **不需改写**，张力随之消解。

**Q1 推销面穷举：未拥有的付费角色是否出现在角色选择屏？** → **选项 A：完全不出现。** 付费入口只在主菜单 Store 一处；角色选择屏只列已拥有角色，不设卡位、不灰显、不加底部入口。用户已知悉代价（付费面近乎不可发现，转化依赖玩家主动进 Store）。

**Q2 「付费 → 免费」的反方向是否允许？** → **选项 B：棘轮双向**，付费的也永不改免费。`Track` 发布后完全不可变；`/audit-content` 方向表**两个方向各留一行**（`Free → Paid` 与 `Paid → Free` 皆违规）。用户已知悉代价（永久失去「老系列免费化拉新」这一手）；C（补偿）的前提「账号级可支配货币」已被本库明确关死。

**连带新增机制（用户在评审中提出，非草稿原有）：每个付费系列有购买时限（限时销售窗口）。** 三条语义：**不绝版**（窗口关闭后可重新上架，或转常驻仅失去限时优惠价，两种形态均可、设计上不预设）· **已购玩家永久可用**（下架的只是购买入口，已写入的解锁记录不受影响）· **限时的是价格与销售节奏，不是可得性**。客户端侧落地面：在售窗口是**内容层属性**（与在售清单同一条通道，零新增下发面），**不进存档、不进 `PlayerEntitlement`**；接进在售清单推导与购买入口前置条件表（新增条件 8，窗口外 ⇒ 该 SKU 置灰 + `STORE_UNAVAILABLE_SERIES_WINDOW`）。后端侧的 SKU 表上架窗口字段归对侧。

## 仍开放（未随本条移出）

- **首批付费系列的 `SeriesId` 具体 slug、系列名与五行构成**——阻于既有待答项「双灵根批与付费系列的推出时点与主题包装」，本次只定结构。
- **在售窗口在内容层的具体承载形态**（落 `CharacterData` 一格、还是随日后的 `CharacterSeriesData` 给出）——取决于系列内容类型是否建、何时建；本次只定三条语义边界。
