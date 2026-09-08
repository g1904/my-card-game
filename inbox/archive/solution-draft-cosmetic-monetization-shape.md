---
type: solution-draft
date: 2026-09-07
question: 纯外观付费点做成角色皮肤 / 卡背 / 界面主题的哪些，字段落成什么形状
source: open-questions/07-codex-monetization.md → 纯外观付费点做成什么
targets: systems/monetization.md（「唯一预留方向 = 纯外观」一段）· systems/player-profile/_index.md（`PlayerEntitlement` 小节）· systems/player-profile/game-setting.md（账号级四字段表 + 候选表）· vision/scope.md（「范围之外」的「外观装饰」一行措辞）· content/_index.md（类型登记表，落地时）· art/visuals/_index.md（资产类目表，落地时）
status: distilled
distilled-to: handoffs/2026-09-07b-cosmetic-monetization-shape.md
reviewed: 2026-09-07（批量评审 · 取向 2 项均已裁决）
---

# 方案草稿 — 纯外观付费点的品类与字段形状

## 问题

`systems/monetization.md` 已把**纯外观**定为付费面的**唯一预留方向**，且「是否真做」已答定：**架构预留、首批不做**（未来会做；落地时 = `PlayerEntitlement` 加一个具名字段 + 一次 schema bump；首批不新增字段、不新增屏）。通行证 / 赛季已明确「当前不做」。

悬着的是两件事：

1. **做成哪些**——角色皮肤 / 卡背 / 界面主题三者中取哪些、以什么顺序。
2. **字段落成什么形状**——「一个具名字段」具体是什么类型；持有（买了哪些）与选用（当前穿哪一套）各落在哪；外观条目本身是不是一个内容类型。

卡住的东西有限但真实：品类未定 ⇒ `art/visuals/_index.md` 的资产类目表无法为它排期（当前表内**没有任何一行**对应外观付费资产）；字段形状未定 ⇒ 「架构预留」这四个字没有可核对的兑现物，容易被误读成「首批先加个占位字段」。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| C1 | **首批不新增任何字段、不新增任何屏**；落地时 = `PlayerEntitlement` 加一个具名字段 + 一次 schema bump，**不需要该类之外的新机制** | `systems/monetization.md`「唯一预留方向」· `answer-logs/log-bundle-grant-ordinal-authority.md` |
| C2 | `PlayerEntitlement` **类内只放付费凭证本身与其兑现水位，不放任何派生量**；两字段 `BundleGrantOrdinal`（后端写）/ `BundleRedeemedOrdinal`（客户端写） | `systems/player-profile/_index.md` · `decisions/ADR-0023` |
| C3 | 该类**用具名字段而非 `List<EntitlementKind>` / 字符串集合**；判据是「付费点在本作被刻意限窄，可扩展集合的成本高于收益」 | `systems/player-profile/_index.md` |
| C4 | `entitlement` 是**透明段**顶层键，`/entitlement/*` 是透明路径；后端写入的 path **受回声约束**，移动 / 重命名 = 破坏性契约变更，须 bump 并与后端同批改 | `systems/player-profile/_index.md` · `backend-design-documents/contracts/profile-sync.md` §5（本库不复述） |
| C5 | schema 登记权威 = `systems/services/profile-schema-versions.md`；**别处不得就地宣布 bump**；引入一个新顶层键进版本行，已登记顶层键内追加字段视受回声约束与否而定（受约束者 ⇒ 两侧同批落笔并进版本行） | `profile-schema-versions.md` 形态纪律 ②⑤ |
| C6 | 玩家偏好的切分判据：**换台手机应跟着走 ⇒ 账号级（`GameSetting` 具名字段）**；取决于这台机器 ⇒ 设备本地。账号级加项成本 = 本类加具名字段 + `SettingKey` 成员 + `SettingFields` 一行 + bump 一次 | `systems/player-profile/game-setting.md` |
| C7 | `GameSetting` **是具名类不是字典**；类内禁 `Ordinal` / `Total` / `Count` 词缀；写入走 `SettingChanges` 列 | 同上 |
| C8 | **二进制资产不经 overlay / blob 通道下发**，换图 / 加图**随版本发布** | `systems/common-properties.md`「`Artwork`」· `decisions/ADR-0125` |
| C9 | 资产挂点 = 内容条目共有字段 `Artwork : Texture2D`（直接资源引用、可空、缺失回落占位）；**屏幕背景与 UI 元件不经内容条目**，UI 元件九宫格、**不走 AI 生成流水线** | `systems/common-properties.md` · `art/visuals/_index.md` |
| C10 | 角色形象已有**稀疏境界覆写** `CharacterData.RealmArtworks`（基础形象 + 至多三条覆写）；其余类目一条内容一张、不随境界分版 | `art/visuals/_index.md` · `systems/character-profile/_index.md` |
| C11 | Store 是主菜单**末位的一等入口**，**一屏多结果态**（购买处理中 / 兑现结果都不是新增屏）；非商店平台入口不渲染 | `ux/screen-flow.md` · `systems/monetization.md` |
| C12 | 内容 id 形态 `<内容类型>.<snake_case_slug>`；**未开张的类型不预先建空文件夹** | `content/_index.md` |
| C13 | 付费面负面边界：外观必须**零玩法影响**（这正是它被留下的唯一理由） | `systems/monetization.md` |

## 建议方案

### 1. 「架构预留」的正确兑现 = 什么都不做，并把这句话写下来

`[既有推演]`

C1 说「首批不新增任何字段」，而「预留」最常见的误读是「先加一个占位字段 / 空列表把位置占住」。**建议明确否决占位字段**，理由三条全部来自既有约束：

- 占位字段会进 `profile-shape-v1.json` 的 golden 快照与 v1 清单（C5），于是一个**永远为空**的结构成为契约的一部分；
- `/entitlement/*` 是透明路径且后端写入面受回声约束（C4），占位即要求后端此刻就在封闭表里为它开一行——**跨边界地固化一个尚未设计的形状**；
- C1 自己写着「不需要该类之外的新机制」，即预留的成立**只依赖三个加法窗口当前是开着的**，而它们都已开着：

| 加法窗口 | 当前状态 | 依据 |
|---|---|---|
| `PlayerEntitlement` 可加具名字段 | 开 | C2 / C3：「日后真新增第二个付费点 = 本类加一个具名字段 + bump 一次 schema」 |
| `GameSetting` 可加账号级具名字段 | 开 | C6：加项成本已是可预期的四步 |
| Store 屏可容纳新结果态 / 新列表而不新增屏 | 开 | C11：一屏多结果态已是既定形态 |

⇒ **建议在 `systems/monetization.md` 落一句：预留的兑现物是「上述三个加法窗口保持开启」，首批不为外观增加任何字段、屏、内容类型或资产类目。** 这让「预留」有可核对的所指，而不是一句无法证伪的承诺。

### 2. 持有 = `PlayerEntitlement` 的一个具名字段 `cosmetic`，元素是 record

`[既有推演]`

落地时的形状建议：

```csharp
public sealed class PlayerEntitlement    // 规则字段层：严格同步 · 后端可复算
{
    public int BundleGrantOrdinal    { get; }   // 既有
    public int BundleRedeemedOrdinal { get; }   // 既有
    public IReadOnlyList<CosmeticEntry> Cosmetic { get; }   // 新增：已购外观的持有集
}

public readonly record struct CosmeticEntry(string Id);     // 首批只有「已持有」这一态
```

四条依据：

- **它是付费凭证本身，不是派生量**（C2 的准入判据）：「买了哪一套」是账号上的原始事实，**写入方只有后端**（验票事务内写入，与 `BundleGrantOrdinal` 同形），客户端无写入通道、经 pull 读到。
- **不需要兑现水位**：礼包要水位是因为兑现要**掷骰抽内容**（`AccountRng` + 取池 + `TryApply`），而外观授予**没有任何随机与内容抽取**——后端直接写持有集，客户端零兑现事务。⇒ 闸 ① ② ③、`GrantPoolMargin`、`K` 一概不适用于外观，**外观购买不受空池闸约束**。
- **元素包一层 record 而非裸 `string[]`**：与七个 Codex 的 `CodexEntry(string Id)` 逐字同构，理由照抄那一处——「日后加一格是在 record 上加字段（老档补默认值、零迁移），用裸 `string` 则元素形状从标量变对象，是一次真实的破坏性变更」。
- **`Status` / `Charges` / `SourceCode` 三格都不加**：外观零玩法影响（C13），没有启用开关、没有使用次数；来源恒为购买，`SourceCode` 会是一格恒定值。

**schema 落点：** `entitlement` 是**受回声校验约束的顶层键**，按 C5 形态纪律 ⑤ 第三档 ⇒ **进版本行、与后端同批落笔**，即落地时 `profile-schema-versions.md` 追加一行 `schemaVersion = 2`（**本草稿不写入该表，只提案**）。老档缺字段 → 空列表，无损。

### 3. 选用 = `GameSetting` 的账号级具名字段，不进 `PlayerEntitlement`

`[既有推演]`

「当前穿哪一套」是**玩家偏好**，不是付费凭证：

- 按 C6 的自检反问——「换了新手机登录同一账号，他会不会觉得这一项理应还是上次调好的样子？」**会** ⇒ 账号级 ⇒ 落 `PlayerProfile.gameSetting`。
- 按 C2，它**不能**进 `PlayerEntitlement`：那里只放凭证与兑现水位，一个「选中项」是纯偏好，与被否决的 `HasPremiumBundle` 同类（该类只收原始事实）。
- 落地时的加项成本正是 C6 明写的四步：`GameSetting` 加一个具名字段 + `SettingKey` 加一个成员 + `SettingFields` 加一行 + 并入同一次 bump。

形态建议（逐品类一个字段，不做字典——C7）：

| 键 | 类型 | 取值域 | 默认 | 缺失 / 解析失败 |
|---|---|---|---|---|
| `EquippedCharacterSkin` | `string?` | 已持有的外观条目 `Id`，或 `null` = 默认外观 | `null` | `PushWarning` + 回落 `null`（与 Codex 条目解析不到的口径同款：可选缺失，不阻断登录） |

- **`null` 就是「默认外观」，不设第二个「是否使用默认」布尔**——与「不设 `IsMuted`，因为 `MasterVolume == 0 ⟺ 静音`」逐字同一判据。
- **持有校验不落在读档钳制里**：读到一个未持有的 id ⇒ `PushWarning` + 回落 `null`（呈现层降级），**不改写字段、不上行纠正**——`entitlement` 侧是后端权威，客户端拿本地判断去覆写选用值只会在权益尚未 pull 到时误清玩家的选择。
- 字段名合规：无 `Ordinal` / `Total` / `Count` 词缀（C7）。
- **它落 `GameSetting` 这个**类**，但不落设置**屏**。** `GameSetting` 的准入判据是「账号级 + 纯偏好 + 不被规则读」，选用项三条全中；而设置屏的语义已被钉死为「音量 / 战斗 / 语言 + 一行只读诊断」三段，`ux/screen-flow.md` 已用「会撑破它已定的三段结构」的理由挡过一次外来内容（账号注销 / 数据导出）。两者本就不是一一对应——同一份文档明写「同步版本 #N 在设置屏上可见但**不进** `GameSetting`」，本条是它的反向：**进 `GameSetting` 但不在设置屏上呈现**。呈现落点见下方子项 7。

### 4. 外观是一个内容类型，落地时才开张

`[既有推演]` + `[通行做法]`

- 一套外观 = **一条内容条目**（`Id` + `LocalizedText` 名称 / 描述 + `Artwork`），走 `ContentRegistry`，与全库「内容即数据」一致；id 形态照 C12：`character_skin.<slug>`。
- **首批不建文件夹、不进类型登记表**（C12「未开张的类型不预先建空文件夹」），落地时走一次 `/scaffold-content-type`。
- **`Artwork` 一格直接够用**（C9），角色皮肤另可复用 `RealmArtworks` 的稀疏覆写形态（C10）⇒ 一套皮肤 = 1 张基础 + 至多 3 张境界覆写，**不需要任何新资产字段**。
- 需要在 `art/visuals/_index.md` 的资产类目表**新增一行**（落地时，不是现在）——当前表内没有任何一行承载外观付费资产。

### 5. 上新节奏受「资产随发版」硬约束，这条决定了品类选择的成本模型

`[既有推演]`

C8：二进制资产不经 overlay，**换图 / 加图随版本发布**。推论两条，建议明写进 `systems/monetization.md`：

- **每上一套外观 = 一次客户端发版**（三渠道审核各一轮）。⇒ 外观是**低频、成套发布**的付费面，不是可周更的上新面。这与「通行证 / 赛季当前不做」同向且互相加固——赛季式高频上新在本作**结构上就不成立**，不只是产能问题。
- **SKU 与条目须同批发版**：后端 SKU 表加一条、客户端资产加一批，两侧同批（落地时的跨边界事项，见「越界发现」/「前置依赖」）。

### 6. 品类：建议做角色皮肤（首选）+ 卡背（低成本填充），界面主题不做

`[取向选择]`（见「仍需用户决定」Q1）

三个品类的成本 / 收益按既有约束推演如下，供裁决：

| 品类 | 边际成本 | 可见面 | 既有承载 | 风险 |
|---|---|---|---|---|
| **角色形象皮肤** | 1 张基础 + ≤3 张境界覆写 / 套 | 主菜单、角色选择、状态区——全程可见 | **最强**：`CharacterData.Artwork` + `RealmArtworks` 已成形（C10），零新机制 | 低。乘数是「角色池规模 × 覆写档数」，但皮肤是**逐角色**售卖，单套成本不随池增长 |
| **卡背** | 1 张图 / 套 | 抽牌堆 / 弃牌堆的背面——战斗内常驻但面积小 | **零**：`art/visuals/_index.md` 资产类目表里没有「卡背」一行，卡牌资产只定义了 full art 正面 | 中低。要新增一个资产类目；且需先确认牌背在竖屏战斗屏上确有可见面（当前 UX 文档未描述牌堆呈现） |
| **界面主题** | 全套 UI 元件（九宫格、状态变体、图标），**且对未来每一个新屏永久征税** | 全程 | **最弱**：UI 元件明写「与插画分开、不适合整图生成」（C9），不走 AI 流水线 | **高**。每加一套主题，此后每新增一个屏 / 一个控件都要产出 N 份资产；且要与灰态语义、错误 / 阻塞屏形态、安全区、GL Compatibility 逐一核对 |

**推荐：角色皮肤为首个品类；卡背作为低成本第二品类（在牌背可见面确认之后）；界面主题明确不做**（若将来做，须先答「主题覆盖到哪一层」——它不是一个可以事后收窄的承诺）。

### 7. 呈现落点 = Store 屏内，不新增屏、不新增主菜单入口

`[既有推演]`

C1 明写「首批不新增屏」，而落地时同样不该新增——三条既有约束叠在一起已把答案挤出来：

- Store 已是**一屏多结果态**（详情 / 购买处理中 / 兑现结果都在同一屏内，C11）⇒ 外观**购买**是它的又一个列表 / 结果态，与既有形态同构。
- **主菜单入口预算是紧的**：`ux/screen-flow.md` 明写十二行入口「会把 Store 推出单手可及区」，并据此否决了「逐本图鉴开七个入口」。为外观开一个 Wardrobe 入口撞的是同一条。
- **选用**（换装）的落点建议是**角色选择屏**——它是玩家已经会看到角色形象的地方，换装在那里是就地操作而不是一次跳转；且该屏本身已定「不新增主菜单入口」。**明确排除设置屏**（理由见子项 3）。

呈现形态的细节（列表布局、预览方式、未持有项的呈现）留给落地时的 UX 专场，本草稿只钉住「不新增屏、不新增主菜单入口」这条边界。

## 具体形态（可 derive 的落地面）

> 全部为**落地时**的形态；首批一格不落。

**A. `PlayerEntitlement` 新增一格**

| 字段 | 类型 | 层 | 默认 | 写入方 | 语义 |
|---|---|---|---|---|---|
| `Cosmetic` | `IReadOnlyList<CosmeticEntry>` | 规则字段层（严格同步 · 后端可复算） | 空列表 | **只有后端**（验票事务内追加），客户端经 pull 读到 | 已购外观条目的持有集；`Id` 属外观内容类型；无顺序语义、无重复 |

- JSON path：`/entitlement/cosmetic`（透明路径；后端写入 ⇒ 受回声约束 ⇒ 白名单与封闭表两侧同批改，权威在对侧契约，本库不复述）。
- 读档校验：非数组 / 元素缺 `Id` → `PushError` + `entitlement` 本次不进 diff + 触发一次 pull 重取权威值、**不钳制**（与 `BundleGrantOrdinal` 同口径——它是回声路径，钳制值一旦回声上行会稳定招致整批拒绝）；`Id` 解析不到内容条目 → `PushWarning` + 保留条目（与 Codex 同口径，旧条目不该阻断登录）。

**B. `GameSetting` 新增一格**（逐品类一格，随品类落地增补）

| 键 | 类型 | 取值域 | 默认 | 载体 | 进 diff | 进 schema |
|---|---|---|---|---|---|---|
| `EquippedCharacterSkin` | `string?` | 已持有外观条目 `Id` \| `null` | `null` | `PlayerProfile.gameSetting` | ✅ | ✅ |

- 写入通道 `SettingChanges`；默认值逐行取值住 `profile-service.md` 的 `SettingFields` 表（本表不复述）。

**C. 内容类型（落地时开张）**

| 项 | 值 |
|---|---|
| 文件夹 | `content/character-skin/`（品类裁决后定名） |
| 代码类型 | `CosmeticData : Resource`（`[GlobalClass]`） |
| id 形态 | `character_skin.<snake_case_slug>` |
| 字段 | `Id` · `DisplayName : LocalizedText` · `Description : LocalizedText` · `Artwork : Texture2D` · 品类专属的绑定格（皮肤：所属 `CharacterData.Id` + 稀疏境界覆写） |
| 校验 | 绑定的角色 id 悬空 → 加载期 `PushError`；`Artwork` 缺失 → 并入既有 `LoadAll()` 的一行汇总告警，不逐条目告警 |

**D. schema**

- 落地时 `profile-schema-versions.md` 追加一行（`schemaVersion = 2`），本版纳入 A + B 两格，老档处置 = 缺字段补默认（空列表 / `null`），触碰透明 / 回声路径 = **有**（`/entitlement/cosmetic`）。**本草稿不写入该表**——登记是那一次落笔的义务。

## 后果

- **首批：零改动。** 唯一的落笔是把「预留 = 三个加法窗口保持开启 + 首批不加占位字段」写进 `systems/monetization.md`，并把 `vision/scope.md`「范围之外」里的「外观装饰」措辞改齐为「架构预留、首批不做」（该措辞在 08-19 已定案时即应改，目前仍是旧写法——**纯机械，答案已定**）。
- **落地时：一次 schema bump（客户端 A + B 两格同批）+ 一次跨边界成对落笔**（后端 SKU 类别、验票后写入 `/entitlement/cosmetic`、封闭表与白名单加行）。
- 影响文档：`systems/monetization.md`（品类与预留兑现）· `systems/player-profile/_index.md`（`PlayerEntitlement` 字段表）· `game-setting.md`（账号级字段表 + 候选表移出一行）· `profile-schema-versions.md`（落地时加版本行）· `content/_index.md` 与 `art/visuals/_index.md`（落地时各加一行）。
- **不影响**：礼包兑现链、三道空池闸、`AccountRng` 的 `PremiumBundle` 域、重试上限、`GrantPoolMargin` / `K`——外观无随机、无内容抽取、无玩法影响，与那条链完全解耦。

## 备选方案（已考虑并否决）

- **首批就加一个空的占位字段以「留出扩展位」** — 否决：它把一个尚未设计的形状固化进 golden 快照与后端回声封闭表（跨边界代价），而加法窗口本就开着，占位不换来任何东西。
- **逐套外观一个具名 `bool` / `Ordinal` 字段（`HasSkinA`…）** — 否决：外观的既定卖点正是「可无限扩展」，每上一套 bump 一次 schema + 改一次后端封闭表，成本随目录线性增长且不可接受。
- **持有集落成 `PlayerProfile` 的第五个顶层持有列表**（与 `playerPower` / `playerItem` 并列） — 否决：那四类的 record 带 `SourceCode` / `Status` / `Charges`，对外观三格恒空或恒定；且 C1 的既定答案明写落点是 `PlayerEntitlement`，另开顶层键是把付费凭证拆到两处。
- **选用项落 `PlayerEntitlement`** — 否决：违反 C2「不放任何派生量」，选用是偏好不是凭证。
- **选用项落设备本地 `device-settings.json`** — 否决：按 C6 自检反问，玩家换机后理应还穿着同一套 ⇒ 账号级。
- **`GameSetting` 用一个 `Dictionary<CosmeticSlot, string>` 收纳全部选用项** — 否决：C7「具名类不是字典」逐字适用。
- **选用项另开一个 `PlayerProfile` 顶层键** — 否决：`GameSetting` 正是「账号级纯偏好」的既定落点，另开顶层键会让偏好散到两处，且要为它单独进版本行。
- **为外观新开一个主菜单入口（Wardrobe / 装扮）** — 否决：主菜单入口预算已明确紧张（`ux/screen-flow.md` 用同一理由否决了逐本图鉴开七个入口），且会把 Store 推出单手可及区。
- **把换装行放进设置屏** — 否决：设置屏语义已钉死为三段 + 一行只读诊断，同一份文档已用「会撑破三段结构」挡过一次外来内容。
- **外观走 overlay 热更以支持高频上新** — 否决：C8 + `ADR-0125` 已关死，且撤销代价明写在 `art/visuals/_index.md`（要连带重开三处评估）。
- **界面主题作为首个品类** — 否决：对**未来每一个新屏**永久征税，且 UI 元件不走既有的资产产出流水线。
- **外观走礼包同款的「后端置序号 + 客户端兑现」两段式** — 否决：兑现段的存在理由是随机抽取与 `TryApply` 事务，外观两者皆无；照抄会凭空造出一个水位字段与一条兑现循环。

## 与既有决策的张力

**一处，需用户裁决（Q2）。** `systems/player-profile/_index.md` 明写「**为何是具名字段而不是 `List<EntitlementKind>` / 字符串集合**：付费点在本作被刻意限窄，可扩展集合的成本高于收益」（C3）。本方案的 `Cosmetic` 恰是一个**可扩展集合**。

- **为什么方案需要它松动**：外观的既定定位就是「可无限扩展」（`systems/monetization.md` 原句），逐套具名字段的成本随目录线性增长（已在备选中否决）。
- **松动的代价**：`PlayerEntitlement` 从「全部具名标量」变为「具名标量 + 一个具名集合字段」；开放容器的原始风险（拼错的 key 从编译期推迟到运行时）由**内容注册表校验**接管——集合元素是 `ContentRegistry` 可解析的内容 `Id`，不是自由字符串 key。
- **建议的收口措辞**：把 C3 那句判据改写为「**禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合，与四类持有条目、七个 Codex 同形**」——保住它真正想拦的东西（把「有哪些付费点」做成运行时可拼错的字符串枚举），同时容纳一个语义清晰的条目持有集。
- **不松动时的替代方案**：逐套具名字段（已否决）；或外观持有另开 `PlayerProfile` 顶层键（已否决，且与 C1 的既定答案相抵）。

## 前置依赖

- **Q1（品类）未裁决前，本方案的「具体形态 C」（内容类型定名、字段、id 前缀）与 `GameSetting` 的具体键名无法定稿**——`EquippedCharacterSkin` 是按推荐项写的示例形态。
- **卡背品类另依赖一项事实确认**：牌堆背面在竖屏战斗屏上是否确有稳定可见面（`ux/` 当前未描述牌堆呈现形态）。未确认前不建议把卡背排进首批外观。
- **落地时的跨边界成对落笔**（后端 SKU 类别 + 验票写入 + 封闭表 / 白名单加行）须与客户端 bump 同批；**首批不做 ⇒ 当前不产生任何后端承接项**，两库 `cross-boundary.md` 保持为空。

## 仍需用户决定

### Q1. 纯外观付费点做成哪些品类、以什么顺序？

`[取向选择]`。三选项的成本 / 可见面 / 既有承载见上方「建议方案 6」的表。

- **A（推荐）：角色皮肤为首个品类，卡背作为第二品类（在牌背可见面确认后），界面主题明确不做。** 后果：零新机制（复用 `Artwork` + `RealmArtworks`）；美术排期加一个类目；界面主题这条路留在关着的状态，将来要开须先答「主题覆盖到哪一层」。
- **B：只做角色皮肤。** 后果：最小面、最快落地；付费面长期只有一个品类，扩展全靠角色池增长。
- **C：三者都做。** 后果：界面主题对未来每一个新屏永久征税，且 UI 元件不走既有资产流水线，等于同时开一条新的美术制作路径。

**推荐 A** —— 依据：`art/visuals/_index.md` 的资产类目表里角色形象**已有一行且已有稀疏覆写机制**（零新机制），卡背只需加一个类目、单套 1 张图；而 UI 元件在同一份文档里被明写「与插画分开、不适合整图生成」，且主题的成本不封顶（对未来每个新屏征税），与「外观 = 零玩法影响、可无限扩展、低风险」的立项理由相悖。

→ **已裁决（2026-09-07 · 批量评审）：选 A。** 角色皮肤为首个品类；**卡背为第二品类**，排入前须先确认牌堆背面在竖屏战斗屏上有稳定可见面（见 `## 前置依赖`）；**界面主题明确不做**。

### Q2. 是否松动「`PlayerEntitlement` 用具名字段而非集合」这条既定判据，允许一个具名的**集合**字段 `Cosmetic`？

`[取向选择]`（🟠 · 触及一条既定判据的字面）。术语：这里的「具名字段」指类上写死名字的字段（对立面是「以字符串为 key 的开放字典」）；争议点是**字段的类型可不可以是一个列表**。

- **A（推荐）：松动，并把判据收口为「禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合」。** 后果：`PlayerEntitlement` 多一个 `IReadOnlyList<CosmeticEntry>`；元素合法性由 `ContentRegistry` 校验接管；与四类持有条目、七个 Codex 的既有形态一致。
- **B：不松动，外观持有逐套一个具名标量字段。** 后果：每上一套外观 = 一次 schema bump + 一次后端封闭表改动，成本随外观目录线性增长。
- **C：不松动，外观持有另开一个 `PlayerProfile` 顶层键。** 后果：付费凭证被拆到两个落点，且与「落地时 = `PlayerEntitlement` 加一个具名字段」这条既定答案（C1）直接相抵。

**推荐 A** —— 依据：那条判据的原文理由是「付费点在本作被刻意限窄」，它拦的是**把付费点种类做成运行时字符串枚举**；而外观条目实例的持有集在本库已有两处同形先例（四类持有条目、七个 Codex），且其元素是可被注册表解析的内容 `Id`，不是自由 key。B 与外观「可无限扩展」的立项理由正面冲突，C 与 C1 相抵。

→ **已裁决（2026-09-07 · 批量评审）：选 A。** 松动该判据：`systems/player-profile/_index.md` 的 C3 措辞按本条建议收口为「**禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合，与四类持有条目、七个 Codex 同形**」，`Cosmetic : IReadOnlyList<CosmeticEntry>` 成立。上方 `## 与既有决策的张力` 记的即本条，一并按此裁决。
