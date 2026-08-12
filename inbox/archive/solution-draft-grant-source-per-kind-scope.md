---
type: solution-draft
date: 2026-08-12
question: `Source` 的封闭三值只覆盖账号级法则的授予途径，神通 / 古宝 / 法宝的常规来路无合法取值——清单该如何收口？
source: open-questions/06-meta-progression.md → 「⚠ `Source` 三值封闭清单与轮回级两类的取值冲突」；同条并列于 `systems/common-properties.md` 的 `## 待决问题`
targets:
  - systems/common-properties.md（权威：枚举成员清单 + 合法子集表 + 校验语义）
  - systems/player-profile/player-power/common-properties.md
  - systems/player-profile/player-item/common-properties.md
  - systems/character-profile/power/common-properties.md
  - systems/character-profile/item/common-properties.md
  - systems/services/profile-service.md（`GrantPower` 签名旁的校验行 + `AbilityChangeElement` 校验表）
  - systems/player-profile/player-power/_index.md（重申 `x` 口径不变）
status: distilled
decided: 2026-08-12（用户裁决四项取向，其余按推荐定案；见文末「已裁决」）
reviewed: 2026-08-12 · 用户裁决四项取向（法则/古宝暂不开放 `EventOutcome`/`ExchangePurchase` · `EventOutcome` 与 `CombatReward` 分立 · `InitialGrant` 单列 · 轮回级同步口径不单列），其余按推荐定案；无剩余待决项
distilled-to: handoffs/2026-08-12b-grant-source-per-kind-scope.md
---

# 方案草稿 — `Source` 从「封闭三值」改为「按 `(Kind, Scope)` 分域的开放清单」

## 问题

08-10b 定下两件事，它们互相不兼容：

1. **`SourceCode` 覆盖四类**——法则 `PlayerPower` · 古宝 `PlayerItem` · 神通 `CharacterPower` · 法宝 `CharacterItem`，凡「可被授予并持有」的条目都带。
2. **`Source` 是封闭三值**——`FinaleWin` / `PremiumBundle` / `AchievementReward`（+ 兜底 `Unknown = 0`），并明写「不为事件 outcome 授予 / 战斗奖励 / Exchange 购买 / 置换所得预留成员」。

三条成员**全部是账号级法则的授予途径**（`FinaleWin` 更是只发法则）。于是轮回级两类的常规来路——事件 outcome、战斗奖励、Exchange 购买、开局初始持有——在清单里无合法取值，只能一律落 `Unknown`；古宝的 Exchange 购买同样无取值。原问题给的两个收口都是**顺着「清单封闭」往下收**：① 把字段收窄到账号级两类；② 四类照带、轮回级恒 `Unknown`。

**用户裁定（08-12）：两者都不取。** 封闭三值**只适用于法则**；神通 / 古宝 / 法宝各有自己的、真实存在的获取来源，字段应当如实记录它们。问题因此转化为：**清单如何扩、扩到什么粒度、四类各自的合法取值域如何约束。**

## 约束（来自既有设计）

- **`SourceCode` 落在持有条目上，不落在 `PowerData` / `ItemData` 上**；写入时刻 = 授予时刻，此后不变。`systems/common-properties.md`「授予来源共有字段」。
- **`Source` 成员带 code 与 value**：code = 显式稳定整数、是存档 / 上行负载里序列化的东西（**重命名成员不破坏存档；已删成员的 code 永不复用**）；value = 展示文案、不落存档。同上。
- **载体必须是 C# `enum`，不是字符串 key**——与 `CapabilityFlag` 同一条纪律（`systems/architecture.md` API 契约总则）。
- **授予通道强制携带来源**：`AbilityChangeElement`（`Op == Grant`）**必须带 `Source`，不设默认值**；`ProfileManager.GrantPower(string powerId, Source source)` 无默认参数。`systems/services/profile-service.md`。
- **置换不改变来源**：置换所得条目**继承被换出条目的 `SourceCode`**（08-10b），以关死「用置换刷回高掉率」的通道。**这条是硬边界，本方案不动它。**
- **残卷分档自变量 `x` = 已拥有且 `SourceCode == Source.FinaleWin` 的法则数**，且 **`x` 单调不减 ⇒ 档位只降不回跳**（08-09b + 08-10b）。`systems/player-profile/player-power/_index.md`、`systems/balance.md`。
- **`SourceCode` 是纯规则字段 · 严格同步口径 · 后端可复算** ⇒ **code 的稳定性同时是一条客户端 ↔ 后端契约**。
- **`(Kind, Scope)` 是全库既有的分类键**：置换同池判据即 `(Kind, Scope)` 全同（`Kind ∈ {Power, Item}`、`Scope: AbilityScope { Character, Player }`）。四类 = 该二元组的四个取值。
- **读档校验既定**：缺失字段 / 无法识别的 code → `GD.PushWarning` + 归入 `Unknown`，**不阻塞**。

## 建议方案

### 1. 保留**单一** `Source` 枚举，不按类拆成四个枚举

`[既有推演]`

四类共用**同一条授予通道**——`AbilityChangeElement`（`Op == Grant`）与 `ProfileManager.Grant*`，一个 `Source` 形参贯穿。若每类各一枚举，这个形参就得退化成 `object` / `int` / 泛型，直接撞上根约定的「**贯穿整条链路的类型一致性**：层与层之间不做隐式装箱 / 转换」。

同一判断在本库已有先例：08-10c 把 `PowerScope` / `ItemScope` **合并**为单一 `AbilityScope`，理由正是「两个枚举值域与语义完全相同，保留两个会逼 element 侧写一层无意义的转换」。此处值域虽不完全相同，但通道是同一条，合并的收益一致：**存档 / 上行负载里的 code 处在单一命名空间，后端只需一张 code 表即可复算**。

差异化用**校验表**承载，而不是用类型系统承载（见 §3）。

### 2. 成员清单从三值扩到七值（+ 兜底），code 显式且永不复用

`[既有推演]` 成员的**来路**全部取自既有文档已写死的获取渠道，不是新造机制：

| 成员 | code | 语义 | 依据 |
|---|---|---|---|
| `Unknown` | 0 | **防御性成员，不是一条途径**：老档缺字段 / 未知 code 的归入处 | 既定（08-10b） |
| `FinaleWin` | 1 | 渡劫成功时由道统残卷掷中并发放 | 既定（08-09b） |
| `PremiumBundle` | 2 | 付费礼包给予（随机 1 法则 + 随机 2 古宝） | 既定（`systems/monetization.md`） |
| `AchievementReward` | 3 | 成就奖励给予 | 既定（08-10b） |
| `EventOutcome` | 4 | 非战斗类 AdventureEvent 的 outcome 授予 | `systems/adventure-event/`；`character-profile/power/_index.md` 待决项「在哪些 AdventureEvent 获得」 |
| `CombatReward` | 5 | 战斗类遭遇的 `Spoils` 授予（Combat / Practice；Finale 的残卷那一路走 `FinaleWin`） | `systems/services/combat-service.md` 的 `CombatResult.Spoils` |
| `ExchangePurchase` | 6 | Exchange（交易）事件中购买所得 | `systems/adventure-event/exchange/`；`player-item/_index.md`「可购道具定义」 |
| `InitialGrant` | 7 | 开局初始持有（角色创建时随 `CharacterProfile` 初始化的起手配置） | `character-profile/power/common-properties.md` 现文已把「开局初始持有」列为神通的常规来路之一 |

- **`FinaleWin = 1` / `PremiumBundle = 2` / `AchievementReward = 3` 的 code 一旦落笔即冻结**——它们已在设计上被后端复算依赖（`x` 只认 `FinaleWin`）。
- **仍然不为「置换所得」设成员**（08-10b 的这条不动）：置换继承被换出条目的来源，新设一个 `Replacement` 成员会立刻打破 `x` 的单调不减。**这是扩清单时最容易踩的一脚，须在文档里明写为一条禁令，而不是靠「当时没想到」留白。**

### 3. 合法取值域按 `(Kind, Scope)` 分域，用**校验表**约束，不用类型约束

`[既有推演]` + `[通行做法]`

| 成员 | 法则 `(Power, Player)` | 古宝 `(Item, Player)` | 神通 `(Power, Character)` | 法宝 `(Item, Character)` |
|---|:--:|:--:|:--:|:--:|
| `FinaleWin` | ✅ | ❌ | ❌ | ❌ |
| `PremiumBundle` | ✅ | ✅ | ❌ | ❌ |
| `AchievementReward` | ✅ | ✅ | ❌ | ❌ |
| `EventOutcome` | ❌ ※ | ❌ ※ | ✅ | ✅ |
| `CombatReward` | ❌ | ❌ | ✅ | ✅ |
| `ExchangePurchase` | ❌ ※ | ✅ | ✅ | ✅ |
| `InitialGrant` | ❌ | ❌ | ✅ | ✅ |
| `Unknown` | ✅（仅读档兜底） | ✅（同左） | ✅（同左） | ✅（同左） |

判据逐条：

- **账号级不接 `CombatReward` / `InitialGrant`。** 账号级授予唯一的战斗入口就是残卷，而它已有专用成员 `FinaleWin`；「开局初始持有」是角色创建时的行为，账号级两类不随角色创建发放（新账号持有为空是既定的起点）。
- **轮回级不接 `PremiumBundle` / `AchievementReward`。** 礼包与成就奖励**按定义是账号级发放**——发一件随轮回清理的东西作为付费 / 成就回报，与「付费内容不会被游戏销毁」（08-06b 推论 ①）正面冲突。
- **`Unknown` 只作读档兜底，不是授予时的合法入参。** 授予侧传 `Unknown` = 调用方漏填，与「不设默认值」同一条纪律。
- **※ 三格标 ❌ 是「暂不开放」，不是「语义上不可能」（已裁决 · 08-12）。** 法则 / 古宝一侧的 `EventOutcome` 与法则一侧的 `ExchangePurchase` 取决于尚未设计的「法则的第三条获取渠道」；在那条待答答定前一律 ❌，**日后开放 = 在校验表里翻一格，无任何结构改动**。文档中这三格须带注脚说明这一点，否则后来者会把它读成一条设计禁令。

**校验落点与失败语义**（与既有 `AbilityChangeElement` 校验表同级）：

| 情形 | 语义 | 处置 |
|---|---|---|
| `Op == Grant` 且 `(Kind, Scope, Source)` 不在合法表内 | **必需缺失**（代码组装缺陷） | `PushError` + **整批拒绝**（与 `PairKey` 配对不成立同档） |
| `Op == Grant` 且 `Source == Unknown` | 同上 | 同上 |
| 读档遇 `(Kind, Scope, Source)` 不合法的**既有条目** | 可选缺失 | `PushWarning` + **保留原值**，不阻塞、不改写 |

读档侧**保留原值而非回落 `Unknown`**：回落会把一条 `FinaleWin` 法则改判为非 `FinaleWin`，直接压低 `x` 并让档位回跳——违背单调不减。**「入口严、读档宽」是这里唯一安全的非对称。**

### 4. 残卷 `x` 的口径与全部既有推论**完全不变**

`[既有推演]`（这是本方案的兼容性核心，必须在文档里明写，否则读者会以为扩清单动了残卷）

- `x` 仍 = `SourceCode == Source.FinaleWin` 的法则数。新增四个成员**没有一个**能出现在法则上并被计入 `x`（`EventOutcome` / `ExchangePurchase` 在法则一侧尚待定，且即便开放也不是 `FinaleWin`）。
- **`x` 单调不减 ⇒ 档位只降不回跳** 原样保住：法则不被强制剥夺、置换继承来源、新成员不推动 `x`。
- **首胜规则、全局前置、账号级 RNG、幂等键**一概不受影响。

### 5. 字段的「消费点」表述需要**改写**，不能照抄「唯一消费点」

`[既有推演]` 08-10b 写的是「**唯一消费点 = 残卷的 `x`**，没有第二个消费点」。扩清单后这句仍**技术上成立**（仍只有一个规则判定读它），但它原本是「所以字段可以很窄」的论据，现在反过来会读成「所以扩清单没必要」。建议改写为**两层表述**：

- **规则消费点仍唯一**：只有残卷的 `x` 用它做判定，且只看 `FinaleWin`。它因此仍是**严格同步口径 · 后端可复算**的纯规则字段。
- **非规则用途已有两处现成落点**（不新增机制）：① `ProfileManager.TryApply` 的可追溯性日志（08-10c 已定要打 `[ProfileManager-TryApply] ability op=Grant kind=... scope=... id=...` 一行，来源是这行最该带的信息，也正是「能力得失最容易被投诉」那条理由的兑现）；② 客服 / 数据侧的账号溯源（付费给予 vs 玩法所得的区分是退款与申诉的第一手依据）。

**⚠ 顺带澄清一处易混：`SourceCode`（授予**渠道**，持有条目上）与 `SourceInstanceId`（施加禁用的那个**来源事件实例**，`disabledAbility` 条目上、供「长按查看来源事件」反查 `pastEvent`）是**两个不同字段、两个不同落点**。名字相邻，文档里应各写一句分工，避免后续把二者合并。

## 具体形态（可 derive 的落地面）

```csharp
public enum Source
{
    Unknown           = 0,   // 读档兜底；授予侧传入即缺陷
    FinaleWin         = 1,   // 渡劫成功 · 道统残卷掷中（x 的唯一数据源）
    PremiumBundle     = 2,
    AchievementReward = 3,
    EventOutcome      = 4,
    CombatReward      = 5,
    ExchangePurchase  = 6,
    InitialGrant      = 7,
}
```

- **展示文案（value）不落存档**，走翻译键（08-12 已定「全库 UI 文案统一走翻译键」）。**但 `SourceCode` 当前不对玩家可见**（既定），故翻译键**暂不铺开**——待出现玩家可见的溯源界面时再补。
- **签名不变**：`ApplyResult GrantPower(string powerId, Source source)` / `GrantItem(...)` 照旧，形态 A。**本方案不改任何签名**，只改 `source` 的合法值域与校验。
- **合法子集表落为一张静态查表**（`(Kind, Scope) → 允许的 Source 集合`），与置换同池判据共用 `(Kind, Scope)` 键；它是**代码常量，不是内容资源**——它约束的是代码组装，不是内容编写，不该进 `.tres`、不该走 overlay。
- **存档影响：不 bump schema 版本。** 字段形状不变（仍是一个整数 code），仅值域扩大；老档中的 `Unknown` 原样保留。无迁移动作。

## 后果

- **`systems/common-properties.md`「授予来源共有字段」整节需重写**：三值表 → 七值表 + 合法子集表 + 校验表 + 「仍不为置换设成员」的禁令 + 「规则消费点唯一 / 非规则用途两处」的两层表述。
- **四类的 `common-properties.md` 各删掉那段 ⚠ 冲突警告**，改为「本层合法取值 = ⟨该列⟩」。（顺带：`character-profile/power/common-properties.md` 与 `character-profile/item/common-properties.md` 的该条目**末尾各重复了一次 `Source:` 行**，可一并修掉。）
- **`profile-service.md`** 的 `AbilityChangeElement` 校验表新增一行（非法 `(Kind, Scope, Source)` → `PushError` + 整批拒绝）。
- **`player-power/_index.md`** 补一句「扩清单后 `x` 口径与单调不减原样成立」，防止读者误判残卷被动过。
- **⚠ 后端侧需要一份对应 handoff。** `Source` 的 code 是客户端 ↔ 后端契约（后端可复算 `x`）。**复算逻辑本身不变**（仍只认 `FinaleWin`），但后端若维护 code 白名单 / 上行校验，需同步四个新 code；未知 code 的后端处置应与客户端一致（记录原值、不改写）。本次运行只写客户端库，另一侧请另跑一次。
- **不影响**：置换语义、禁用语义、`AbilityScope`、`RarityTier`、账号级 RNG、决策点存档、`ProfileChangeSpec` 的三列表结构。

## 备选方案（已考虑并否决）

- **① 把 `SourceCode` 收窄到账号级两类（法则 / 古宝），轮回级不带** — 原问题的倾向项。**用户已否决**：神通 / 法宝的来源真实存在且值得记录；且这会让「凡可被授予并持有的条目都带 `SourceCode`」这条整齐的共有字段裂成两半，四类对称（禁用 / 置换 / `Rarity` / `AbilityScope` 全部四类通用）出现一处例外。
- **② 四类照带、轮回级恒 `Unknown` 作占位** — **用户已否决**。它把「等清单扩了再说」写成存档字段，且让 `Unknown` 同时承担「老档兜底」与「合法的轮回级取值」两种语义——读档校验从此无法区分「这是坏数据」和「这是正常值」。
- **③ 四个独立枚举（`PlayerPowerSource` / `CharacterItemSource` / …）** — 否决：撞「贯穿链路的类型一致性」，逼 `AbilityChangeElement` 的 `Source` 形参退化为 `object` / `int`；与 08-10c 合并 `AbilityScope` 的判断反向。分域用校验表表达即可。
- **④ `Source` 改为字符串 key（内容侧可自由填）** — 否决：与「capability flag 的载体是 `enum` 而非字符串 key」同一条纪律，把拼写错误从编译期推迟到运行时；且 code 是后端契约，字符串会让契约面失控。
- **⑤ 给「置换所得」新增成员 `Replacement`** — 否决：直接打破 `x` 单调不减，重开「用置换刷回高掉率」的通道（08-10b 明确关死）。

## 与既有决策的张力

1. **直接推翻 `systems/common-properties.md` 的「成员清单已穷举、只有三条途径」与「清单是封闭的——不为事件 outcome 授予 / 战斗奖励 / Exchange 购买 / 置换所得预留成员」。** 这是本方案的核心动作，须在 handoff 中明写为一次**推翻**而非补充。其中「**不为置换所得预留成员**」那半句**保留并强化**——扩清单的同时它变成一条需要主动守住的禁令。
2. **「没有第二个消费点 ⇒ 纯规则字段」的论证被削弱。** 扩清单后，轮回级两类的 `SourceCode` 仍**没有任何规则消费点**——它在那四类上依然是「只写不读」的字段，只是取值不再恒为兜底值。**这条张力是真实的，方案没有消除它**，只是把它从「字段无意义」降级为「字段有信息但暂无规则消费者」（日志与溯源是弱消费点）。若用户认为这仍不足以支撑字段存在，唯一自洽的退路就是选项 ①——而那已被否决。**建议在 handoff 中如实写下这条代价，不粉饰。**
3. **同步口径的分类需复核。** `SourceCode` 现被归为「严格同步口径 · 后端可复算」（因为 `x` 依赖它）。轮回级两类的该字段**后端无从复算也无需复算**。**已裁决（08-12）：不拆**——同一字段两套同步口径的成本高于收益；在 `player-profile/_index.md` 的两层通则处补一句「该字段在轮回级侧无规则消费点，从所在 profile 的既有口径同步即可，不单列」。

4. **⚠ 与后端 `contracts/envelope.md` 的枚举序列化约定冲突（08-12 写后端 handoff 时发现 · 承重 · 未收口）。** 本库 08-10b 写的是「**code = 显式稳定整数，是存档 / 上行负载里实际序列化的东西**」；而 `backend-design-documents/contracts/envelope.md` 定「**枚举值一律字符串，取值与客户端 C# 枚举名逐字相同**」（理由：同名可省掉一整张最易写漏的映射表）。**两条都明写覆盖「上行负载」，不能同时成立**——`envelope.md` 是 08-11 成文的，晚于 08-10b，本库那句话当时还没有对手方。

   **本方案不裁决它**（收口归后端库那一侧，见 `backend-design-documents/handoffs/2026-08-12-grant-source-code-contract.md` 的 Open questions）。倾向的收口是**契约侧走字符串名 · 存档侧走整数 code · 客户端在序列化边界做一次映射**，通则不开例外；若如此，本库 `systems/common-properties.md` 的那句话需改为「**code 是存档里实际序列化的东西**；上行负载按 `envelope.md` 走枚举名」，并补一条「成员名与 code 双双冻结、永不复用」。**扩清单本身不依赖这条**——它只决定线上表示形态，客户端可先行落地。

## 前置依赖

- **法则 / 古宝一侧的 `EventOutcome` / `ExchangePurchase` 已按「暂不开放」定案**（见 §3 的 ※ 注脚），其开放时机挂在 `player-power/_index.md` 的既有待决项「**获取触发未设计（残卷 / 礼包之外）**：是否还有第三条获取渠道（事件 outcome 直接给予？）」上。**该项不阻塞本方案落地**——它只决定日后校验表里翻不翻那三格。
- **`EventOutcome` 与 `CombatReward` 的边界**依赖战斗类遭遇的 `Spoils` 与非战斗事件 outcome 是否确为两条组装路径（`systems/services/combat-service.md` 与 `future-event-service.md` 的物化规则）。当前文档支持这一判断；若二者最终合流为同一条链路，两个成员应合并为一个——**合并时 `CombatReward = 5` 的 code 作废并永不复用**，不得改判为别的语义。

## 已裁决（2026-08-12 · 用户）

1. **法则 / 古宝是否接受 `EventOutcome` / `ExchangePurchase`** → **暂不开放**（三格 ❌ + ※ 注脚，日后翻格无结构改动）。
2. **`EventOutcome` 与 `CombatReward`** → **分成两个成员**。
3. **`InitialGrant`（开局初始持有）** → **单列成员**。
4. **轮回级两类的同步口径** → **不单列**，只在两层通则处补一句说明。
5. **其余全部按推荐定案**：单一 `Source` 枚举（不拆四个）· 七值 + `Unknown` 兜底 · 合法子集校验表为代码常量 · 入口严（`PushError` + 整批拒绝）/ 读档宽（`PushWarning` + 保留原值）· 仍不为「置换所得」设成员 · 不 bump 存档 schema · 消费点表述改为「规则消费点唯一 + 非规则用途两处」。

**本草稿无剩余待决项，可直接喂给 `/analyze-new-ideas` 提炼。**

## 后端侧（另一库，需单独一次运行）

`Source` 的 code 是客户端 ↔ 后端契约（后端复算残卷的 `x`）。本次扩清单**不改后端的复算逻辑**（仍只认 `FinaleWin = 1`），但后端侧需要一份对应 handoff 承接：

- **code 表同步**：`Unknown=0 · FinaleWin=1 · PremiumBundle=2 · AchievementReward=3 · EventOutcome=4 · CombatReward=5 · ExchangePurchase=6 · InitialGrant=7`；**已删成员的 code 永不复用**。
- **未知 code 的处置须与客户端一致**：记录原值、不改写、不拒收（后端若把未知 code 归一为 0，会在回传时压低 `x` 并让档位回跳）。
- **合法子集表不在后端复制**：它约束的是客户端的 element 组装，后端只做 code 识别与 `x` 复算；**不要把校验表做成第二处真值**。
- **`x` 复算口径不变**：`count(PlayerPower where SourceCode == 1)`。

**归属判据**：客户端语义已定、只剩服务端如何兑现 ⇒ 后端库承载，注明「客户端侧已定 · 2026-08-12」+ 回链本文件。**可与 `inbox/_index.md` 里既有的两笔待办后端 handoff 合并成一次运行。**
