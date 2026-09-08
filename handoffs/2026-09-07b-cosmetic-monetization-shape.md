# 纯外观付费点的品类与字段形状

- id: 2026-09-07b-cosmetic-monetization-shape
- date: 2026-09-07
- topic: systems/monetization.md · systems/player-profile/_index.md · systems/player-profile/game-setting.md · vision/scope.md
- status: distilled
- distilled-to: systems/monetization.md, systems/player-profile/_index.md, systems/player-profile/game-setting.md, vision/scope.md, answer-logs/log-cosmetic-monetization-shape.md

## Intent（distilled）

一句话：**外观付费点做成角色皮肤（首个）+ 卡背（第二，待牌背可见面确认），界面主题明确不做；「架构预留」的兑现物是三个加法窗口保持开启，首批一格不落。**

「是否真做」此前已答定为**架构预留、首批不做**。悬着的是两件事：做成哪些品类；「一个具名字段」具体是什么形状、持有与选用各落在哪、外观条目是不是一个内容类型。

卡住的东西有限但真实：品类未定 ⇒ `art/visuals/_index.md` 的资产类目表里没有任何一行对应外观付费资产；字段形状未定 ⇒「架构预留」没有可核对的兑现物，容易被误读成「首批先加个占位字段」。

### 1. 「架构预留」的正确兑现 = 什么都不做，并把这句话写下来

**明确否决占位字段**，三条理由全部来自既有约束：占位字段会进 `profile-shape-v1.json` 的 golden 快照与 v1 清单，于是一个永远为空的结构成为契约的一部分；`/entitlement/*` 是透明路径且后端写入受回声约束，占位即要求后端此刻就在封闭表里为它开一行——跨边界地固化一个尚未设计的形状；而「预留」的成立只依赖三个加法窗口当前开着，且它们都开着：

| 加法窗口 | 依据 |
|---|---|
| `PlayerEntitlement` 可加具名字段 | 「日后真新增第二个付费点 = 本类加一个具名字段 + bump 一次 schema」 |
| `GameSetting` 可加账号级具名字段 | 加项成本已是可预期的四步 |
| Store 屏可容纳新结果态 / 新列表而不新增屏 | 一屏多结果态已是既定形态 |

⇒ 预留的兑现物是「上述三个加法窗口保持开启」，首批不为外观增加任何字段、屏、内容类型或资产类目。这让「预留」有可核对的所指，而不是一句无法证伪的承诺。

### 2. 持有 = `PlayerEntitlement` 的具名字段 `Cosmetic`，元素是 record

落地时形状：`IReadOnlyList<CosmeticEntry> Cosmetic`，`readonly record struct CosmeticEntry(string Id)`。四条依据：

- 它是付费凭证本身而非派生量（「买了哪一套」是账号上的原始事实），**写入方只有后端**（验票事务内写入，与 `BundleGrantOrdinal` 同形），客户端经 pull 读到。
- **不需要兑现水位**：礼包要水位是因为兑现要掷骰抽内容，而外观授予无随机、无内容抽取 ⇒ 三道空池闸、`GrantPoolMargin`、`K` 一概不适用，客户端零兑现事务。
- **元素包一层 record 而非裸 `string[]`**：与七个 Codex 的 `CodexEntry(string Id)` 同构——日后加一格是在 record 上加字段（老档补默认值、零迁移），裸 `string` 则元素形状从标量变对象，是一次真实的破坏性变更。
- **`Status` / `Charges` / `SourceCode` 三格都不加**：外观零玩法影响，没有启用开关、没有使用次数；来源恒为购买。

schema 落点：`entitlement` 是受回声校验约束的顶层键 ⇒ 落地时进版本行、与后端同批落笔（`schemaVersion = 2`）。老档缺字段 → 空列表，无损。

### 3. 选用 = `GameSetting` 的账号级具名字段，不进 `PlayerEntitlement`

「当前穿哪一套」是玩家偏好不是付费凭证：按切分判据的自检反问——换新手机登录同一账号，玩家会觉得这一项理应还是上次调好的样子 ⇒ 账号级；按 `PlayerEntitlement` 的准入判据，它不能进那里（那里只放凭证与兑现水位）。

形态：逐品类一个具名字段（不做字典），如 `EquippedCharacterSkin : string?`，取值域为已持有外观条目 `Id` 或 `null` = 默认外观。`null` 就是默认外观，不设第二个布尔——与「不设 `IsMuted`，因为 `MasterVolume == 0 ⟺ 静音`」同一判据。**持有校验不落在读档钳制里**：读到未持有的 id ⇒ `PushWarning` + 回落 `null`（呈现层降级），不改写字段、不上行纠正——`entitlement` 侧是后端权威，客户端拿本地判断去覆写选用值只会在权益尚未 pull 到时误清玩家的选择。

**它落 `GameSetting` 这个类，但不落设置屏。** 设置屏语义已钉死为「音量 / 战斗 / 语言 + 一行只读诊断」三段，同一份文档已用「会撑破三段结构」挡过一次外来内容。两者本就不是一一对应——「同步版本 #N 在设置屏上可见但不进 `GameSetting`」是它的正例，本条是反例。

### 4. 外观是一个内容类型，落地时才开张

一套外观 = 一条内容条目（`Id` + `LocalizedText` 名称 / 描述 + `Artwork`），走 `ContentRegistry`，id 形态 `character_skin.<slug>`。首批不建文件夹、不进类型登记表；落地时走一次 `/scaffold-content-type`。`Artwork` 一格直接够用，角色皮肤另可复用 `RealmArtworks` 的稀疏覆写形态 ⇒ 一套皮肤 = 1 张基础 + 至多 3 张境界覆写，不需要任何新资产字段。

### 5. 上新节奏受「资产随发版」硬约束

二进制资产不经 overlay ⇒ **每上一套外观 = 一次客户端发版**（三渠道审核各一轮）。外观因此是低频、成套发布的付费面，不是可周更的上新面——这与「通行证 / 赛季当前不做」同向且互相加固：赛季式高频上新在本作**结构上就不成立**，不只是产能问题。SKU 与条目须同批发版。

### 6. 呈现落点 = Store 屏内，不新增屏、不新增主菜单入口

Store 已是一屏多结果态 ⇒ 外观购买是它的又一个列表 / 结果态；主菜单入口预算是紧的（已用同一条理由否决「逐本图鉴开七个入口」），为外观开 Wardrobe 入口撞的是同一条。**选用（换装）的落点是角色选择屏**——玩家已经会在那里看到角色形象，换装是就地操作而非一次跳转。呈现形态细节留给落地时的 UX 专场。

## Clarifications（interview 产物）

- **纯外观付费点做成哪些品类、什么顺序？** → **角色皮肤为首个品类；卡背为第二品类，排入前须先确认牌堆背面在竖屏战斗屏上有稳定可见面；界面主题明确不做。** 依据：角色形象在资产类目表里已有一行且已有稀疏覆写机制（零新机制）；卡背只需加一个类目、单套 1 张图；而 UI 元件被明写「与插画分开、不适合整图生成」，主题的成本不封顶（对未来每个新屏征税），与「外观 = 零玩法影响、可无限扩展、低风险」的立项理由相悖。
- **是否松动「`PlayerEntitlement` 用具名字段而非集合」这条既定判据，允许一个具名的集合字段 `Cosmetic`？** → **松动。** 判据收口为「**禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合，与四类持有条目、七个 Codex 同形**」，`Cosmetic : IReadOnlyList<CosmeticEntry>` 成立。依据：那条判据的原文理由是「付费点在本作被刻意限窄」，它拦的是把付费点种类做成运行时字符串枚举；而外观条目实例的持有集在本库已有两处同形先例，其元素是可被注册表解析的内容 `Id`，不是自由 key。它同时改写了原判据的字面——本次直接改写 `systems/player-profile/_index.md` 的那句话，不新开取代条目。
- **标准默认（自动采纳）：** 元素包 record 而非裸 `string[]`（Codex 先例）· 选用项 `null` = 默认外观不设伴生布尔（`IsMuted` 先例）· 读档两条口径（`entitlement` 侧 `PushError` + 不进 diff + 触发 pull、不钳制；id 解析不到 `PushWarning` + 保留）· 内容类型 id 形态与文件夹延后开张——均由既有同形先例给出明显默认。

## Open questions

- **卡背品类依赖一项事实确认**：牌堆背面在竖屏战斗屏上是否确有稳定可见面（`ux/` 当前未描述牌堆呈现形态）。未确认前卡背不排进首批外观。归入既已排期的竖屏分区 UX 专场。
- 落地时的具体键名与内容类型定名（`EquippedCharacterSkin` / `character_skin.*` 是按首个品类写的示例形态），随落地那次落笔定稿。

## Notes / triage

- **首批零改动。** 唯一的落笔是把「预留 = 三个加法窗口保持开启 + 首批不加占位字段」写进 `systems/monetization.md`，并把 `vision/scope.md`「范围之外」里的外观装饰一行措辞改齐为「架构预留、首批不做」。
- **落地时**：一次 schema bump（`PlayerEntitlement.Cosmetic` + `GameSetting` 选用项两格同批）+ 一次跨边界成对落笔（后端 SKU 类别、验票后写入 `/entitlement/cosmetic`、封闭表与白名单加行）+ `content/_index.md` 与 `art/visuals/_index.md` 各加一行。
- **首批不做 ⇒ 当前不产生任何后端承接项**，两库 `cross-boundary.md` 保持原样、本次不写对侧库。
- 不影响礼包兑现链、三道空池闸、`AccountRng` 的 `PremiumBundle` 域、重试上限、`GrantPoolMargin` / `K`。
