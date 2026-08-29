---
type: solution-draft
date: 2026-08-27
question: capability flag 体系的枚举 / 命名空间、叠加与冲突规则、聚合面宿主服务；以及重试上限可变后落成什么存档形状。
source: open-questions/deferred-content.md → 元进程持久化与内容开关（capability flag 的叠加 / 冲突规则）· open-questions/06-meta-progression.md → 重试上限可变后的存档表达
targets: systems/services/profile-service.md · systems/player-profile/player-power/common-properties.md · systems/architecture.md · systems/character-profile/power/_index.md · systems/services/life-cycle-service.md · systems/balance.md
status: distilled
reviewed: 2026-08-27 — 用户逐条评审并裁决；提炼时另经一场合并 interview（8 问）补齐三条真冲突与两处跨草稿矛盾
distilled-to: handoffs/2026-08-27-capability-flag-and-entitlement.md
---

# 方案草稿 — capability flag 体系的形态，与重试上限的存档表达

## 问题

两半必须一起答，因为后者的三个候选之一就是前者。

**① capability flag 体系。** ADR-0017（Accepted）固化了模型「数据声明 → 中心聚合 → 单点查询」，但明写把三项落地细节留在待决：**flag 的枚举与命名空间**、**叠加与冲突规则**（两个 power 授予同一 flag；多条 modifier 作用于同一 key 的运算顺序）、**聚合面的宿主服务**（`player-power/common-properties.md` 与 `deferred-content.md` 都记着「账号级至今无专属服务」）。同一条待决项还在 `character-profile/power/_index.md` 留下一格：**flag / modifier 的注册面是否两层共用**（神通能不能授予 flag）。

**② 重试上限可变后的存档表达。** 上限由礼包从「无限 / 3 / 1」改写为「无限 / 9 / 3」后，`RetryChapter` 的判定要读 PlayerProfile 上的持有状态；`life-cycle-service.md` 与 `06-meta-progression.md` 的待决项并列了三个候选——一个 `CapabilityFlag`、modifier pipeline 的一条具名修正、一个独立的 `Entitlement` 字段。

卡住的东西：`/derive-requirements systems/services/profile-service.md` 已被 `open-questions.md` 明确排除了「capability flag 的叠加 / 冲突规则」这一块；不答就没法把 CapabilityManager 连同 profile-service 的地基一起 derive。

## 约束（来自既有设计）

- **ADR-0017（Accepted）**：两条通道的模型已固化；`CapabilitiesChanged` **空负载**、订阅者自查；`Elements` 侧 modifier 是 **opt-in 白名单、缺省豁免**；**一个 `ModifierKey` 只能有一个施加点**；备选方案里**已明令否决「用 capability flag 承载付费凭证」**。
- **ADR-0023 / `systems/monetization.md` / `player-profile/_index.md`**：付费凭证 = `PlayerEntitlement` 两字段；**不落成 `CapabilityFlag`、不走 modifier pipeline**（两者都是内容条目聚合出的**派生态**且受轮回级禁用截断，而付费凭证是账号上的**原始事实**）；该类**只放付费凭证本身与其兑现水位，不放任何派生量**。
- **`systems/architecture.md`「闭环缺口」表第 1 行：缺口「PlayerProfile 侧无服务」已闭合 → profile-service（ProfileManager / **CapabilityManager** / AchievementManager）。** 现有 `public enum CapabilityFlag { RevealHiddenStats, ShowExploreType }` 已在同文件的共享枚举清单里。
- **`systems/services/life-cycle-service.md`**（已落笔的正文，非待决）：`RetryChapter` 读 `profile-service.HasPremiumBundle`（`=> Entitlement.BundleGrantOrdinal > 0`，单点查询、不缓存）；**两档上限表是数据不是常量**，两行落 `systems/balance.md`，本服务**选行**；可重复购买不产生第三行。
- **生效判据 = 截断在「进入生效面」那一步**（`character-profile/power/_index.md` 的五行表）：被禁用的条目**不进生效能力集、不进修正表**。三条与门 = 拥有 · `status == 启用` · 不在 `disabledAbility` 内。
- **两层共用一个 `PowerData` 定义**，由 `Scope: AbilityScope { Character, Player }` 声明所属层。
- **数据即资源 / 平衡数值不硬编码**（`.claude/rules/data-resource-rules.md`）：平衡资源经 `Content.Single<T>()` 取，调用方不写 `Id` 字面量。
- **万分比整数纪律**（`PlayerPowerFragment.Accumulated`）：概率 / 比率一律万分比 `int`，**不用 `float`**——存档与跨端一致性 + 后端可复算 + 避免浮点比较。

## 建议方案

### 子项 1 · flag 的枚举与命名空间

`[既有推演]`

- **单一扁平 `public enum CapabilityFlag`，不分区、不加前缀、不嵌套命名空间。** 它已经存在于 `systems/architecture.md` 的共享枚举清单里，与 `CostKey` / `StatusKey` / `SettingKey` 同处；成员按注释分组即可。理由与「`CapabilityFlag` 用 `enum` 而非字符串 key」同源——类型名本身就是命名空间（`CapabilityFlag.RevealHiddenStats`），再加一层分区只会让每个消费点先答一次「它属于哪个区」。
- **首批成员 = 现有两个，不预铺占位：** `RevealHiddenStats`（显示隐藏属性数值）· `ShowExploreType`（Explore 前揭示事件类型）。**按内容建、不按对称建**（与「不给统计族建全空 `StatFields`」同一条判据）。
  - 附带清理：`handoffs/2026-07-27b` 里出现过的第三个成员 `ShowSkipCost` **已随 08-06c 移除 skip 通道而作废**，不进枚举。
- **命名规范 = 动词 + 宾语，动词取自封闭三词表** `Reveal`（把已存在但被隐藏的**信息**显出来）· `Show`（把某处 **UI 元素**显示出来）· `Unlock`（打开一个原本不可用的**入口**）。
- **禁止否定式 / 关闭式命名**（`Hide*` · `No*` · `Disable*` · `Suppress*` · `Prevent*`）。这不是风格偏好，是子项 2 那条不变式的**可机械检查形态**——见下。
- **新增一个 flag 恰好三步，不多不少：** ① `CapabilityFlag` 加一个成员 → ② 受影响的 UI 组件加一次 `Has(flag)` 自查 + 订阅 `CapabilitiesChanged` → ③ 某条 `PowerData` 的 `.tres` 声明授予它。**不 bump 存档 schema、不改任何服务、不新增事件**——生效能力集是派生态，不落存档（详见「后果」）。

### 子项 2 · 叠加与冲突规则

`[既有推演]`

- **叠加 = 集合并（union），幂等。** 两个 power 授予同一 flag ⇒ 该 flag 在生效集里出现一次，**不计数、不叠层、不告警**（重复授予是常态而非缺陷，与 `CodexElements` 「同批同 `(Kind, Id)` 去重、不告警」同款口径）。给它计数会立刻引出「两份是不是该更强」，而布尔量没有这个语义。
- **冲突：结构上关死，而不是运行时裁决。** 全部 flag 恒为**增益向 / 打开向**（三词表已经保证了这一点），因此**不存在两个 flag 互相矛盾的可能**，union 就是全部规则——不需要优先级字段、不需要声明序、不需要"谁赢"的裁决表。**子项 1 的禁用词表就是这条不变式的护栏**：允许一个 `HideXxx` 进枚举的那一天，才需要一张裁决表。
  - **确需「关闭某项默认可见的东西」时的正确形态**：把默认态挪到内容侧 / `GameSetting`，用一个正向 flag 打开它；不引入负向 flag。
- **落地形态 = `HashSet<CapabilityFlag>` 聚合，`CapabilityFlag` 保持普通序数 `enum`（不加 `[Flags]`）。** `[Flags]` 位掩码会给 flag 数量焊上 32 / 64 的上界，并让成员值变成必须手工维护的 2 的幂——换来的只是 `Has` 从一次哈希查找变成一次按位与，而 `Has` 的调用点是 UI 重绘，不在热路径。与库内其余枚举形态一致也更便宜。
- **三条与门与生效面截断不变**（拥有 · `status == 启用` · 不在 `disabledAbility` 内；被禁用者不进生效集、不进修正表）。`Has(flag)` 未授予 = `false`，非错误——已定，原样保留。

### 子项 3 · 聚合面的宿主服务

`[既有推演]` —— **它其实已经定了，本子项的建议动作是清理三处过期措辞，而不是再做一次选择。**

- **宿主 = `profile-service.CapabilityManager`。** 三处权威已一致：`architecture.md`「闭环缺口」表第 1 行明写缺口「PlayerProfile 侧无服务」**已闭合** → profile-service（含 CapabilityManager）；ADR-0017 决策正文点名 `profile-service.CapabilityManager`；`profile-service.md` 的 manager 表、API 面（`Has` / `ApplyModifier`）、`system-overview.md`、`program-overview.md` 全部按此写就。
- **「账号级至今没有专属服务」这句现状仍然成立，但它不构成缺口。** 判据 ② 让 profile-service 成为两层 profile 的唯一写入面，而 capability 聚合的**全部输入**（两层持有列表 + 轮回级 `disabledAbility`）恰好都是它的自有状态 ⇒ 放在这里**不跨服务、不新增依赖边**（`profile-service.md` 已明写这一点）。
- **不新开账号级服务。** 服务判据要求「拥有一个状态机」或「跨进程边界」或「需事务性跨字段一致写入」；CapabilityManager 三条皆无——它是一份从既有状态派生的只读缓存。为它开一个第八个服务，只会把 autoload 注册顺序与依赖边各加一条。
- **建议的文本清理（三处，均属陈旧措辞而非设计变更）：**
  - `player-power/common-properties.md` 通道一末尾的括注「（该聚合面缺少宿主服务——见 `systems/architecture.md` 的账号级服务缺口）」→ 删除并改为回链 `systems/services/profile-service.md`。该回链本身也已失效：`architecture.md` 的缺口表说的是"已闭合"。
  - 同文件待决项里的「聚合面的**宿主服务**（当前无账号级服务）」→ 删除该格。
  - `open-questions/deferred-content.md` 该条的「**连带一格（本次归集）：flag 聚合面的宿主服务**」→ 移出。

### 子项 4 · 注册面是否两层共用（`character-profile/power/_index.md` 留的那一格）

`[取向选择]` —— **推荐：共用**（详见「仍需用户决定」）。以下是推荐方案的具体形态。

- **`CapabilityManager` 遍历两份持有列表**：`PlayerProfile.playerPower` + 当前角色的 `CharacterProfile.characterPower`，同三条与门，聚合成**同一份**生效能力集与**同一张**修正表。依据：`PowerData` 本就是两层共用的单一定义（`Scope` 只声明所属层），而生效判据表已把「战斗外 capability flag 聚合 / modifier pipeline」列为**四类通用**的两个生效面——若轮回级条目根本不参与聚合，那两行对它恒为空谈。
- **推论 ①：`CapabilitiesChanged` 再多两个触发源，机制不变**——轮回开始 / 拆解、神通得失各触发一次重新聚合 + 空负载广播。轮回结束后角色级 flag 随重新聚合自然消失，**不需要任何清理代码**。
- **推论 ②：无当前角色时（主菜单）只聚合账号级那一份**，这是正常态而非缺失，不告警。
- **`ItemData` 两类（法宝 / 古宝）不参与聚合。** 它们带 `Charges`、是**启动式**（需主动启用），效果走 `Abilities`；常驻派生态的表达属于**静止式**的 power 两类。生效判据表里那两行对道具恒为空集——这是自洽，不是例外。

### 子项 5 · modifier 的叠加与运算顺序（同一条待答项的另一半）

`[通行做法]` + `[既有推演]`

- **一条 modifier 的形态：** `ModifierEntry(ModifierKey Key, ModifierOp Op, int Value)`，`ModifierOp { Add, Scale }`。**`Scale` 的 `Value` 是万分比增量**（`-2000` = −20%，`+1500` = +15%），沿用 `PlayerPowerFragment.Accumulated` 的万分比整数纪律（禁 `float`：存档 / 跨端一致 + 后端可复算 + 不做浮点比较）。
- **运算顺序 = 先全部加法、再一次乘法；且同类内求和，不逐条相乘：**

  ```
  sum   = base + Σ(Op == Add   的 Value)
  scale = 10000 + Σ(Op == Scale 的 Value)      // 求和，不连乘
  scale = Max(scale, 0)                        // 钳制 ①
  result = sum * scale / 10000                 // 整数运算，向零取整，全程只取整这一次
  ```

- **这个形状的价值是让「运算顺序」这个问题不存在**：加法可交换、乘数求和亦可交换 ⇒ **结果与声明顺序、遍历顺序、条目获得先后全部无关**。因此**不需要优先级字段、不需要稳定排序、不需要声明序约定**。逐条相乘则相反（两条 −50% 连乘 = −75%，且顺序一旦掺入取整就不可复算），且会让多条小修正叠出远超预期的乘积——这是同类作品最常见的一处数值失控源。
- **钳制两条（承重）：**
  - ① `scale` 钳到 `[0, ∞)`——**总折扣不得翻号**。翻号后一笔「消耗」会变成「产出」，而 `ResourceElements` 的两个修正列是**按符号分向**准入的，这一笔会走到另一向的准入上去，并当场撞上入口校验（「产出侧 `LifeSpan` 恒为回复向」那一行）。
  - ② 结果与 `baseValue` **同号或为 0**（① 成立时它自动成立，仍写下来作为断言）。
- **只取整一次。** 分步取整会让「两条 −10%」与「一条 −20%」出现 off-by-one，而后端要逐位复算。
- **无修正 = 原值返回**（已定）；**一个 `ModifierKey` 只能有一个施加点**（已定，不放松）。
- **`ModifierKey` 保持"随各自专场补"的开放形态**（当前 `LifeSpanCost` / `ShopPrice`），本方案不新增成员。

### 子项 6 · 重试上限的存档表达

`[既有推演]` —— **三个候选一个都不采纳：正确答案是「不新增任何东西」，读既有的 `PlayerEntitlement`。**

- **已落笔的正文就是答案。** `life-cycle-service.md` 正文（非待决区）已写死：`RetryChapter` 的上限判定读 `profile-service.HasPremiumBundle`（`=> Entitlement.BundleGrantOrdinal > 0`，只读属性、单点查询、不缓存）；两档上限表**两行落 `systems/balance.md`**，本服务**选行**。`profile-service.md` 的 API 表也已有该属性，并注明「消费方是 life-cycle-service 的重试上限选行」。**这条待决项与本库的既有正文自相矛盾，处置应是答结并移出，而不是再选一次。**
- **候选 A · `CapabilityFlag` —— 明令否决（两条独立理由）：** ① ADR-0017 备选方案第 4 条已写死「用 capability flag 承载付费凭证」被否决——生效能力集**受轮回级禁用截断**，把付费凭证放进一个设计上就允许被截断的聚合面，等于给「花钱买的东西被事件拿走」留后门；② flag 是布尔，而上限是每篇章一格的三元组（∞ / 9 / 3），布尔承载不了（把它压成「选哪一行」的布尔正是 `HasPremiumBundle` 在做的事——但它读的是**原始事实字段**，不是派生聚合态）。
- **候选 B · modifier pipeline 的一条具名修正 —— 明令否决：** ADR-0017 的作用面边界明写 modifier「**不作用于**……序号与付费凭证」；且 modifier 同样是内容聚合出的派生态、同受禁用截断。另有一条形态上的理由：上限不是可被内容连续加减的量，两档是**选行**不是**算数**。
- **候选 C · 一个独立的 `Entitlement` 字段（字面读法）—— 否决：** `PlayerEntitlement` 已定「类内只放付费凭证本身与其兑现水位，**不放任何派生量**」。一个 `HasExtendedRetry` / `RetryLimitBonus` 就是 `BundleGrantOrdinal > 0` 的第二份拷贝，撞上单一真值纪律与该类的命名硬约定（类内禁 `Total` 前缀 / `Count` 后缀，出现即意味着有人复制了同一个数）。这与「不设第三个字段 `HasPremiumBundle` / `PremiumBundleCount`」是**同一条已作出的否决**，只是换了个名字。
- ⇒ **存档 schema 零改动 · `CostKey` 零新增 · `ResourceElements` 零新增行 · 透明路径零新增 · sync-service 与后端契约零改动。**
- **唯一真实残留：`systems/balance.md` 里那张两行表尚未落笔。** 建议形状（`[既有推演]`，来自数据即资源规则）：

  ```csharp
  [GlobalClass]
  public partial class ChapterRetryLimitsData : Resource, ISingletonContent
  {
      [Export] public int[] BaselineLimits { get; set; }   // 长度 3，篇章序；-1 = 无限
      [Export] public int[] PremiumLimits  { get; set; }   // 同上
  }
  ```
  - 经 `Content.Single<ChapterRetryLimitsData>()` 取，**调用方不写任何 `Id` 字面量**（否则绕过 overlay 覆盖层，「平衡数值可热更而不发版」当场失效）。
  - **`-1` = 无限**，与 `PlayerItem.Charges` 的「无限法宝恒为 `-1`」同款约定，不另造哨兵值。
  - 加载期校验：两个数组长度均 == 篇章数（3），元素 `>= -1`，否则 `PushError` + 路径。
  - **数值那半不在本次范围**（`deferred-content.md` 已登记为可调平衡项）；本条只欠载体形状，落笔时先填「∞ / 3 / 1」与「∞ / 9 / 3」两行现值。

## 具体形态（可 derive 的落地面）

**枚举与类型（落 `systems/architecture.md` 的共享枚举 / 类型清单）**

```csharp
public enum CapabilityFlag  { RevealHiddenStats, ShowExploreType }   // 扁平；成员名动词 ∈ {Reveal, Show, Unlock}
public enum ModifierOp      { Add, Scale }                           // Scale 的 Value 是万分比增量
public readonly record struct ModifierEntry(ModifierKey Key, ModifierOp Op, int Value);
```

**`PowerData` 上的两个声明字段**（并入 `PowerData` / `RelicData` 字段清单那次 handoff，见「前置依赖」）

| 字段 | 类型 | 必填 | 语义 |
|---|---|---|---|
| `GrantedFlags` | `CapabilityFlag[]` | 否（缺省空） | 该条目授予的 flag 集；重复声明幂等 |
| `Modifiers` | `ModifierEntry[]` | 否（缺省空） | 该条目注册的具名修正；同 key 多条按子项 5 合并 |

**CapabilityManager 的聚合（伪码）**

```
Recompute():
    flags.Clear(); modifiers.Clear()
    foreach entry in playerProfile.playerPower ∪ activeCharacter?.characterPower:
        if !entry.Status                       -> continue    // 与门 ②
        if disabledAbility.Contains(entry)     -> continue    // 与门 ③（轮回级抑制）
        data = ContentRegistry.GetPowerOrNull(entry.PowerId)
        if data == null: PushWarning(id) ; continue           // 可选缺失：overlay 热更可能移除条目
        flags.UnionWith(data.GrantedFlags)                    // 幂等并集
        foreach m in data.Modifiers: modifiers.Accumulate(m)  // 按 (Key, Op) 累加，不连乘
    EventBus.Emit(CapabilitiesChanged)                        // 空负载

Has(flag)                 => flags.Contains(flag)             // 未授予 = false，非错误
ApplyModifier(key, base)  => 见子项 5 的四行算法                // 无修正 = 原值返回
```

**触发源清单**（全部走同一条 `Recompute()`，不新增机制）：`Hydrate` 首次聚合 · 能力得失（`AbilityElements` 提交后）· `status` 开关 · `disabledAbility` 写入 / 到期 · 轮回开始 / 拆解。

**启动期断言（纪律阶梯第 3 级，`#if DEBUG`）**

1. 每个 `CapabilityFlag` 成员名的首个词落在 `{Reveal, Show, Unlock}` 内，且不含 `Hide` / `No` / `Disable` / `Suppress` / `Prevent`——子项 2 那条不变式的机械护栏，一行反射遍历。
2. 内容加载期：`PowerData.GrantedFlags` / `Modifiers` 中出现枚举外的值 → `PushError` + `Id`（`.tres` 上的枚举序号可能因枚举重排而错位）。
3. 「每个 flag 至少有一处消费点」**无法机械检查**（消费点是一段 UI 代码），**如实停在纪律阶梯第 4 级（评审清单）**——不为它造一张必须手工同步的注册表。

**重试上限的读取链**：`ChapterManager` → `profile-service.HasPremiumBundle` → 选 `ChapterRetryLimitsData` 的两行之一 → 与 `CharacterProfile.chapterRetry` 的对应字段相减 = 「还剩几次」。**凡读取处不得硬编码常量**（ADR-0004 既定纪律）。

## 后果

- **存档 schema：零影响。** 生效能力集与修正表都是**派生态**，只活在内存里；`PlayerEntitlement` 两字段已在既有那次 bump 内。**不新增 `CostKey`、不新增 `ResourceElements` 行、不新增透明路径。**
- **sync-service：零影响**（无新增顶层键、无新增回声路径，两层 Profile diff 与回声校验不受牵动）。**后端契约：零影响。**
- **受影响文档（若采纳）：**
  - `systems/services/profile-service.md` —— CapabilityManager 小节补齐叠加 / 冲突 / 聚合范围三条；待决项「capability flag 的枚举与命名空间；叠加 / 冲突规则」删除。
  - `systems/player-profile/player-power/common-properties.md`（权威）—— 通道一 / 通道二补齐命名规范、union 规则、modifier 运算顺序；删除「缺少宿主服务」括注；待决项收窄为只剩 `status` 与「拥有 / 失去」的存档表达。
  - `systems/architecture.md` —— 加 `ModifierOp` / `ModifierEntry` 两个类型，`CapabilityFlag` 处加一行命名约定注释。
  - `systems/character-profile/power/_index.md` —— 「与 PlayerPower 的复用边界」待决项的**战斗外那一半**答结。
  - `systems/services/life-cycle-service.md` —— 删除与本文件正文自相矛盾的待决项「重试上限可变后的存档表达」。
  - `systems/balance.md` —— 登记 `ChapterRetryLimitsData` 两行表（形状本次给出，数值仍属可调平衡项）。
  - `decisions/ADR-0017` —— 「后果」小节里「仍未定的落地细节」一句需相应收窄（flag 枚举 / 命名空间 / 冲突叠加三项落定，只剩 `status` 与「拥有 / 失去」的存档表达）。
- **`open-questions` 侧：** `deferred-content.md` 的「capability flag 的叠加 / 冲突规则」整条移出（含连带的宿主服务一格）；`06-meta-progression.md` 的「重试上限可变后的存档表达」整条移出。两条各记一份 `answer-logs/`。
- **对 derive 的影响：** `open-questions.md` 第 4 条 derive 建议里「**排除 capability flag 的叠加 / 冲突规则**」的排除项可以撤销——profile-service 地基可连同 CapabilityManager 一起 derive。

## 备选方案（已考虑并否决）

- **按域给 flag 分区 / 加前缀（`UI_` · `Meta_` · 嵌套 enum）** — 否决：类型名已是命名空间；分区只让每个消费点先答一次「它属于哪个区」，且首批只有两个成员。
- **`[Flags]` 位掩码聚合** — 否决：给 flag 数量焊上 32 / 64 上界、成员值要手工维护为 2 的幂，换来的只是非热路径上的一次按位与。
- **flag 带优先级 / 声明序 / 「谁赢」裁决表** — 否决：没有负向 flag 就不存在冲突；为一个被结构关死的问题造裁决表，等于把负向 flag 请回来。
- **flag 计数 / 叠层（两个 power 授予同一 flag 算两份）** — 否决：布尔量没有「两份」的语义，且会立刻引出「两份是不是该更强」。
- **modifier 逐条相乘** — 否决：结果依赖顺序、多条小修正叠出乘积、掺入取整后不可复算。
- **modifier 用 `float` 比率** — 否决：存档 / 跨端一致性与后端复算，万分比整数是既定纪律。
- **给 modifier 加优先级字段 / 按声明序结算** — 否决：子项 5 的形状让结果与顺序无关，优先级字段是为一个不存在的问题付的字段成本。
- **flag / modifier 注册面只收账号级（神通不参与聚合）** — 未否决，作为「仍需用户决定」的另一选项列出（见下）。
- **`ItemData` 也参与 flag 聚合** — 否决：道具带 `Charges`、是启动式，效果走 `Abilities`；常驻派生态属静止式的 power 两类。
- **为 capability 聚合新开一个账号级服务** — 否决：无状态机、无跨进程边界、无跨字段事务，三条服务判据皆不满足；输入全是 profile-service 的自有状态。
- **重试上限落 `CapabilityFlag` / modifier / 新 `Entitlement` 字段** — 三者均否决，逐条理由见子项 6。
- **重试上限两行表写成 C# 常量** — 否决：它是平衡数值，硬编码即绕过 overlay 热更（`data-resource-rules.md`）。

## 与既有决策的张力

1. **`profile-service.md` 现文只写「遍历 `PlayerPower`」，子项 4 建议扩到两层。** 这是对已落笔文本的**扩写**（既有措辞写于 `CharacterPower` 升格为共用 `PowerData` 之前），不是推翻任何判据；但若用户选择「只收账号级」，该措辞原样保留、反而是 `character-profile/power/_index.md` 的「对标 PlayerPower ⇒ 两条生效通道同样适用」一句需要加一条明确例外。**两个方向都要动文本，故必须由用户裁决。**
2. **`life-cycle-service.md` 自相矛盾：** 正文第 17–19 行已把重试上限的读取链写死（读 `HasPremiumBundle` 选行），而同文件待决区仍并列三个候选。本草稿按**正文**收口、删待决项。若用户认为正文那一段本身尚未获授权（它来自 08-15b handoff 的提炼），则子项 6 需重新作为取向题提出——目前**不作此假设**，因为 `profile-service.md` 的 API 表、`monetization.md` 的 ADR 候选行、`player-profile/_index.md` 的 `PlayerEntitlement` 小节三处独立落笔都与它一致。
3. **`player-power/common-properties.md` 与 `deferred-content.md` 的「账号级服务缺口」回链已失效**（`architecture.md` 的缺口表说该缺口"已闭合"）。这是既有的文档漂移，不是本方案引入的；清理动作列在子项 3。它属于 `architecture.md` 待决项里登记的那次「上下游待决问题对账」的一个实例。

## 前置依赖

- **`RelicData` / `PowerData` 的字段清单与触发器体系未定案**（`player-power/common-properties.md` 待决项）。本方案给出的两个声明字段 `GrantedFlags` / `Modifiers` **须并入那次 handoff 的字段清单一起落笔**，不单独成条——否则会出现「字段表在两处各长一半」。这不阻塞本草稿的其余部分（枚举、union 规则、运算顺序、宿主、重试上限均可先定）。
- **flag 首批清单会随各 UX 专场增长**（信息经济 / 图鉴扩展一线已在推进）。本方案定的是**规范与新增流程**，不是最终清单——按「新增恰好三步」逐次加即可。
- **`systems/balance.md` 的两档上限数值**仍属 `deferred-content.md` 登记的可调平衡项，本方案只给载体形状。
- **`status` 与「拥有 / 失去」两态的存档表达**是同一批待决项里**未被本草稿覆盖**的那一条（它已由 `PlayerPower(PowerId, Status, SourceCode)` 的 record 形态事实上答定，但收口措辞不在本次范围）。

## 仍需用户决定

**① flag / modifier 的注册面是否两层共用——神通（`CharacterPower`）能不能授予 capability flag 与具名修正？**

| 选项 | 后果 |
|---|---|
| **A · 共用（推荐）** | `CapabilityManager` 遍历 `playerPower` + 当前角色 `characterPower` 两份列表。**收益**：轮回内的 build 多一条表达通道——一个神通可以在**这一局**里让你看见隐藏属性 / 揭示事件类型，是很强的"这局手感不同"的来源，且与「神通是轮回内 build 的一部分」的既定定位一致。**代价**：全局可见性变成轮回级可变量，UI 需要在轮回开始 / 拆解时正确重绘（机制上已由 `CapabilitiesChanged` 覆盖，无新增机制）；也意味着一条**轮回级**内容可以改写 `ShopPrice` 一类的全局修正。 |
| **B · 只收账号级** | 聚合面只遍历 `playerPower`，措辞原样保留。**收益**：全局设定的可变面只由账号级持有物决定，跨轮回稳定、心智最简。**代价**：`character-profile/power/_index.md` 的「对标 PlayerPower ⇒ 两条生效通道同样适用」要加一条明确例外；神通的战斗外表达面被压缩到只剩事件触发器一条，而它本被定位为与卡组 / 法宝并列的三大 build 组件之一。 |

**推荐 A**，三条依据：① `PowerData` 已是两层共用的单一定义，`Scope` 只声明层不改变能力面；② `character-profile/power/_index.md` 的**生效判据五行表**已把「战斗外 capability flag 聚合 / modifier pipeline」列为**四类通用**的生效面——选 B 会让那两行对轮回级条目成为空谈；③ 选 B 需要新写一条例外，而选 A 不需要写任何新规则（「除非另有陈述，沿用 PlayerPower 那套」原样成立）。

> 本方案的其余全部子项**在两个选项下都成立**，只有子项 4 的聚合范围与「后果」里 `profile-service.md` 那一处措辞随之不同。

→ **已裁决（2026-08-27 · 批量评审）：A · 共用——两层都能授予 capability flag 与具名修正。** `CapabilityManager` 聚合 `playerPower` + 当前角色 `characterPower`，同三条与门；`profile-service.md` 现文「遍历 `PlayerPower`」按子项 4 扩写为两层。用户同时知悉：此裁决**提前定下了「神通 ↔ 法则复用边界」的一半**（该条本批未入选，其余部分仍待专场）。

---

**② modifier 的量纲与合并算法须与 `solution-draft-ability-primitive-grammar.md` 对齐（跨草稿新增项，非本草稿原有）**

本草稿子项 5 定义的 `ModifierEntry(ModifierKey, ModifierOp{Add, Scale}, int)`（`Scale` = 万分比增量、先全部加法再一次乘法、同类求和不连乘），与同批草稿 `solution-draft-ability-primitive-grammar.md` 第 2 节的 `StaticModifierData(ModifierTarget, ModifierLayer{Additive, Multiplicative}, int Amount)`（`Multiplicative` = 百分比、先累乘后整除）**量纲与合并算法互不一致**。同一个词「modifier」在库内出现两个量纲两套舍入，写内容时必然填错。

→ **已裁决（2026-08-27 · 批量评审）：两套并存，但强制对齐量纲与舍入。**
> - **Key 空间分开**：`ModifierKey` 管 Profile 侧具名修正（`LifeSpanCost` / `ShopPrice`），`ModifierTarget` 管战斗内数值。作用面确实不同——前者进 Profile 事务与钳制表，后者在战斗求值管线内且恒不落存档；合并会让「一个 `ModifierKey` 只能有一个施加点」（`ADR-0017` 既定不变式）被战斗内条目撑破。
> - **量纲统一为万分比整数**（既定纪律，`PlayerPowerFragment.Accumulated` 为先例；禁 `float`）。对侧草稿的「百分比（100 = ×1.0）」须改为万分比。
> - **合并算法统一为「同层求和 → 只乘一次 → 只取整一次」**。对侧草稿的「先累乘百分比、最后一次整除」须改为本草稿子项 5 的算法。
>
> 提炼时两份草稿须**同批**落笔，否则对齐即失效。
