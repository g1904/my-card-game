# 授予来源 `Source` 从「封闭三值」改为按 `(Kind, Scope)` 分域的开放清单

- id: 2026-08-12b-grant-source-per-kind-scope
- date: 2026-08-12
- topic: systems/common-properties（权威）· systems/player-profile/player-power|player-item · systems/character-profile/power|item · systems/services/profile-service · systems/player-profile/_index
- status: distilled
- distilled-to: `systems/common-properties.md`, `systems/player-profile/player-power/common-properties.md`, `systems/player-profile/player-item/common-properties.md`, `systems/character-profile/power/common-properties.md`, `systems/character-profile/item/common-properties.md`, `systems/services/profile-service.md`, `systems/player-profile/player-power/_index.md`, `systems/player-profile/_index.md`

## Intent（distilled）

> **一行摘要：** `Source` 不再是「只覆盖账号级法则来路的封闭三值」，而是**一张按 `(Kind, Scope)` 分域的七值开放清单**——四类各有自己真实存在的获取来源，字段如实记录；分域约束由**校验表**承载，不由类型系统承载；残卷的 `x` 口径与「单调不减 ⇒ 档位只降不回跳」**完全不变**。

输入：`inbox/solution-draft-grant-source-per-kind-scope.md`（`status: decided`，用户已裁决四项取向、其余按推荐定案）。

### 0. 被推翻的是什么

08-10b 同时定下两件互不兼容的事：① `SourceCode` 覆盖四类（法则 `PlayerPower` · 古宝 `PlayerItem` · 神通 `CharacterPower` · 法宝 `CharacterItem`）；② `Source` 是封闭三值（`FinaleWin` / `PremiumBundle` / `AchievementReward` + 兜底 `Unknown`），并明写不为事件 outcome / 战斗奖励 / Exchange 购买 / 置换所得预留成员。三条成员**全是账号级法则的授予途径**，于是轮回级两类的常规来路在清单里无任何合法取值。

原待答给的两个收口都是顺着「清单封闭」往下收（收窄字段到账号级两类 / 四类照带但轮回级恒 `Unknown`）。**用户裁定：两者都不取。** 封闭三值只适用于法则；神通 / 古宝 / 法宝各有真实存在的获取来源，**该扩的是清单，不是字段的覆盖面**。

**本次明确推翻** `systems/common-properties.md` 的「成员清单已穷举、只有三条途径」与「清单是封闭的」。其中「**不为置换所得预留成员**」那半句**保留并强化**——扩清单后它从「顺带没写」变成一条必须主动守住的禁令。

### 1. 保留单一 `Source` 枚举，不按类拆成四个

四类共用**同一条授予通道**（`AbilityChangeElement` 的 `Op == Grant` 与 `ProfileManager.Grant*`），一个 `Source` 形参贯穿全链。每类各一枚举会把这个形参逼成 `object` / `int` / 泛型，直接撞上根约定「贯穿整条链路的类型一致性：层与层之间不做隐式装箱 / 转换」。

本库已有同型判断：08-10c 把 `PowerScope` / `ItemScope` **合并**为单一 `AbilityScope`，理由正是「保留两个会逼 element 侧写一层无意义的转换」。此处值域虽不全同，但通道是同一条，收益一致——**存档 / 上行负载里的取值处在单一命名空间，后端只需一张表即可复算 `x`**。

差异化由**校验表**承载，不由类型系统承载。

### 2. 成员清单：三值 → 七值（+ 兜底 `Unknown`）

成员的来路全部取自既有文档已写死的获取渠道，不是新造机制。

| 成员 | code | 语义 | 依据 |
|---|---|---|---|
| `Unknown` | 0 | **防御性成员，不是一条途径**：老档缺字段 / 无法识别取值的归入处 | 08-10b |
| `FinaleWin` | 1 | 渡劫成功时由道统残卷掷中并发放 —— **`x` 的唯一数据源** | 08-09b |
| `PremiumBundle` | 2 | 付费礼包给予（随机 1 法则 + 随机 2 古宝） | `systems/monetization.md` |
| `AchievementReward` | 3 | 成就奖励给予 | 08-10b |
| `EventOutcome` | 4 | 非战斗类 AdventureEvent 的 outcome 授予 | `systems/adventure-event/` |
| `CombatReward` | 5 | 战斗类遭遇的 `Spoils` 授予（Combat / Practice；Finale 的残卷那一路走 `FinaleWin`） | `systems/services/combat-service.md` 的 `CombatResult.Spoils` |
| `ExchangePurchase` | 6 | Exchange（交易）事件中购买所得 | `systems/adventure-event/exchange/` |
| `InitialGrant` | 7 | 开局初始持有（角色创建时随 `CharacterProfile` 初始化的起手配置） | `character-profile/power/common-properties.md` 现文已列为神通常规来路 |

- **`FinaleWin = 1` / `PremiumBundle = 2` / `AchievementReward = 3` 的 code 一旦落笔即冻结**——它们已在设计上被后端复算依赖（`x` 只认 `FinaleWin`）。**已删成员的 code 永不复用。**
- **仍不为「置换所得」设成员（禁令，不是遗漏）。** 置换所得条目继承被换出条目的 `SourceCode`；新设一个 `Replacement` 成员会立刻打破 `x` 的单调不减，重开「用置换刷回高掉率」的通道。这是扩清单时最容易踩的一脚，须在文档里**明写为禁令**。

### 3. 合法取值域按 `(Kind, Scope)` 分域，用校验表约束

`(Kind, Scope)` 是全库既有的分类键（置换同池判据即它全同；`Kind ∈ {Power, Item}`、`Scope: AbilityScope { Character, Player }`），四类 = 该二元组的四个取值。

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

判据：

- **账号级不接 `CombatReward` / `InitialGrant`。** 账号级授予唯一的战斗入口就是残卷，而它已有专用成员 `FinaleWin`；「开局初始持有」是角色创建时的行为，账号级两类不随角色创建发放（新账号持有为空是既定起点）。
- **轮回级不接 `PremiumBundle` / `AchievementReward`。** 二者按定义是账号级发放——发一件随轮回清理的东西作为付费 / 成就回报，与「付费内容不会被游戏销毁」（08-06b 推论 ①）正面冲突。
- **`Unknown` 只作读档兜底，不是授予时的合法入参。** 授予侧传 `Unknown` = 调用方漏填，与「不设默认值」同一条纪律。
- **※ 三格 ❌ 是「暂不开放」，不是「语义上不可能」。** 法则 / 古宝一侧的 `EventOutcome` 与法则一侧的 `ExchangePurchase` 取决于尚未设计的「法则的第三条获取渠道」（挂在 `player-power/_index.md` 的既有待决项上）；在那条答定前一律 ❌，**日后开放 = 在校验表里翻一格，无任何结构改动**。这三格必须带注脚，否则后来者会把它读成一条设计禁令。

**校验落点与失败语义**（与既有 `AbilityChangeElement` 校验表同级）：

| 情形 | 语义 | 处置 |
|---|---|---|
| `Op == Grant` 且 `(Kind, Scope, Source)` 不在合法表内 | 必需缺失（代码组装缺陷） | `PushError` + **整批拒绝**（与 `PairKey` 配对不成立同档） |
| `Op == Grant` 且 `Source == Unknown` | 同上 | 同上 |
| 读档遇 `(Kind, Scope, Source)` 不合法的**既有条目** | 可选缺失 | `PushWarning` + **保留原值**，不阻塞、不改写 |

**「入口严、读档宽」是这里唯一安全的非对称。** 读档侧保留原值而非回落 `Unknown`：回落会把一条 `FinaleWin` 法则改判为非 `FinaleWin`，直接压低 `x` 并让档位回跳，违背单调不减。

**合法子集表落为一张静态查表**（`(Kind, Scope) → 允许的 Source 集合`），与置换同池判据共用 `(Kind, Scope)` 键；它是**代码常量，不是内容资源**——它约束的是代码组装而非内容编写，不进 `.tres`、不走 overlay。

### 4. 残卷 `x` 的口径与全部既有推论完全不变

这是本次的兼容性核心，必须在文档里明写，否则读者会以为扩清单动了残卷。

- `x` 仍 = 已拥有且 `SourceCode == Source.FinaleWin` 的法则数。新增四个成员**没有一个**能出现在法则上并被计入（`EventOutcome` / `ExchangePurchase` 在法则一侧尚未开放，且即便日后开放也不是 `FinaleWin`）。
- **`x` 单调不减 ⇒ 档位只降不回跳** 原样保住：法则不被强制剥夺、置换继承来源、新成员不推动 `x`。
- 首胜规则、全局前置、账号级 RNG（`Hash64(AccountSeed, FinaleWinOrdinal)`）、幂等键一概不受影响。

### 5. 「消费点」表述改写为两层

08-10b 写的是「**唯一消费点 = 残卷的 `x`**，没有第二个消费点」。扩清单后这句技术上仍成立，但它原本是「所以字段可以很窄」的论据，现在会被反读成「所以扩清单没必要」。改写为：

- **规则消费点仍唯一**：只有残卷的 `x` 用它做判定，且只看 `FinaleWin`。它因此仍是**严格同步口径 · 后端可复算**的纯规则字段。
- **非规则用途已有两处现成落点**（不新增机制）：① `ProfileManager.TryApply` 的可追溯性日志（08-10c 已定要打 `[ProfileManager-TryApply] ability op=Grant kind=… scope=… id=…`，来源正是这行最该带的信息，也是「能力得失最容易被投诉」那条理由的兑现）；② 客服 / 数据侧的账号溯源（付费给予 vs 玩法所得的区分是退款与申诉的第一手依据）。

**⚠ 顺带澄清一处易混：** `SourceCode`（授予**渠道**，落持有条目）与 `SourceInstanceId`（施加禁用的那个**来源事件实例**，落 `disabledAbility` 条目、供「长按查看来源事件」反查 `pastEvent`）是**两个不同字段、两个不同落点**。名字相邻，文档里应各写一句分工，避免后续把二者合并。

### 6. 落地面

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

- **签名不变**：`ApplyResult GrantPower(string powerId, Source source)` / `GrantItem(…)` 照旧，形态 A。本次只改 `source` 的合法值域与校验。
- **展示文案（value）不落存档**，走翻译键（08-12 已定「全库 UI 文案统一走翻译键」）；但 `SourceCode` 当前不对玩家可见，**翻译键暂不铺开**——待出现玩家可见的溯源界面时再补。
- **存档影响：不 bump schema 版本。** 字段形状不变（仍是一个整数 code），仅值域扩大；老档中的 `Unknown` 原样保留，无迁移动作。
- **同步口径不拆（用户裁决）：** 轮回级两类的 `SourceCode` 后端无从也无需复算，但**不为它单列一套口径**——同一字段两套同步口径的成本高于收益；在 `player-profile/_index.md` 的两层通则处补一句说明即可。

### Clarifications（interview 产物）

本次输入为 `status: decided` 的 solution-draft，四项取向已由用户在评审阶段裁决，提炼时未再触发 interview。用户裁决逐条如下（它们相对原始问题的措辞是**多出来的意图**）：

| 问题 | 用户裁决 | 推翻 / 细化了什么 |
|---|---|---|
| 法则 / 古宝是否接受 `EventOutcome` / `ExchangePurchase` | **暂不开放**（三格 ❌ + ※ 注脚） | 细化：把「未定」写成可执行的「暂不开放 + 日后翻格无结构改动」，而非留白 |
| `EventOutcome` 与 `CombatReward` 是否合一 | **分成两个成员** | 细化：接受二者边界依赖 `Spoils` 与事件 outcome 是两条组装路径这一判断 |
| `InitialGrant`（开局初始持有）是否单列 | **单列成员** | 细化：不并入 `EventOutcome` |
| 轮回级两类的同步口径是否单列 | **不单列**，只在两层通则处补一句 | 细化：承认「同一字段两套口径」的成本高于收益 |
| 收口方向 | **既不收窄字段、也不恒 `Unknown`**，而是扩清单 | **推翻**原待答的倾向项 ①，并推翻 08-10b 的「清单是封闭的」 |
| 其余 | 按推荐定案（单一枚举 · 校验表为代码常量 · 入口严 / 读档宽 · 不设 `Replacement` · 不 bump schema · 消费点两层表述） | — |

## 已考虑并否决的备选

- **① 把 `SourceCode` 收窄到账号级两类，轮回级不带** — 用户否决。神通 / 法宝的来源真实存在且值得记录；且这会让「凡可被授予并持有的条目都带 `SourceCode`」这条整齐的共有字段裂成两半，四类对称（禁用 / 置换 / `Rarity` / `AbilityScope` 全部四类通用）出现一处例外。
- **② 四类照带、轮回级恒 `Unknown` 作占位** — 用户否决。它把「等清单扩了再说」写成存档字段，且让 `Unknown` 同时承担「老档兜底」与「合法的轮回级取值」两种语义，读档校验从此无法区分坏数据与正常值。
- **③ 四个独立枚举** — 否决：撞「贯穿链路的类型一致性」，逼 `AbilityChangeElement` 的形参退化为 `object` / `int`；与 08-10c 合并 `AbilityScope` 的判断反向。
- **④ `Source` 改为字符串 key** — 否决：与「capability flag 的载体是 `enum` 而非字符串 key」同一条纪律，把拼写错误从编译期推迟到运行时；且取值是后端契约，字符串会让契约面失控。
- **⑤ 新增成员 `Replacement`** — 否决：直接打破 `x` 单调不减，重开置换刷分通道。

## 承认的代价（不粉饰）

**「没有第二个消费点 ⇒ 纯规则字段」的论证被削弱。** 扩清单后，轮回级两类的 `SourceCode` 仍**没有任何规则消费点**——它在那四类上依然是「只写不读」的字段，只是取值不再恒为兜底值。这条张力是真实的，本方案没有消除它，只是把它从「字段无意义」降级为「字段有信息但暂无规则消费者」（日志与溯源是弱消费点）。若日后判定这仍不足以支撑字段存在，唯一自洽的退路就是备选 ①——而它已被否决。

## Open questions

- **⚠ 上行负载的枚举序列化形态未收口（承重 · 收口归后端库）。** 本库 08-10b 写「code = 显式稳定整数，是**存档 / 上行负载**里实际序列化的东西」；而 `backend-design-documents/contracts/envelope.md`（08-11 成文，晚于 08-10b）定「**枚举值一律字符串，取值与客户端 C# 枚举名逐字相同**」。两条都明写覆盖「上行负载」，**不能同时成立**。倾向的收口是**契约侧走字符串名 · 存档侧走整数 code · 客户端在序列化边界做一次映射**（通则不开例外），若如此则本库「code 是上行负载里实际序列化的东西」那句需改写，并补一条「成员名与 code 双双冻结、永不复用」。**扩清单本身不依赖这条**——它只决定线上表示形态，客户端可先行落地。裁决在 `backend-design-documents/handoffs/2026-08-12-grant-source-code-contract.md` 的 Open questions。
- **`EventOutcome` 与 `CombatReward` 的边界依赖两条组装路径确实分立。** 若战斗类遭遇的 `Spoils` 与非战斗事件 outcome 最终合流为同一条链路，两个成员应合并为一个——**合并时 `CombatReward = 5` 的 code 作废并永不复用**，不得改判为别的语义。→ `systems/services/combat-service.md`、`systems/services/future-event-service.md`。
- **法则的第三条获取渠道是否存在**（残卷 / 礼包之外，事件 outcome 直接给予？）——它决定校验表里那三格 ※ 何时翻转。**不阻塞本方案落地。** → `systems/player-profile/player-power/_index.md` 的既有待决项。

## Notes / triage

- 后端侧承接已就位：`backend-design-documents/handoffs/2026-08-12-grant-source-code-contract.md`（`status: raw`，待该库自行提炼）。本次运行只写客户端库。
- 顺带修掉 `character-profile/power/common-properties.md` 与 `character-profile/item/common-properties.md` 中重复了一次的 `Source:` 行。
