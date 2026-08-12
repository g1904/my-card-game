---
type: solution-draft
date: 2026-08-12
question: 两条 PlayerPower 获取渠道（道统残卷 / premium bundle）从哪个池抽、抽到重复怎么办？
source: open-questions/07-codex-monetization.md → 「两条 PlayerPower 获取渠道的候选池与排重规则（08-09b 收窄，只剩「抽哪一条」）」；同条并列于 `systems/player-profile/player-power/_index.md` 与 `systems/monetization.md` 的 `## 待决问题`
targets:
  - systems/player-profile/player-power/_index.md（权威：候选池定义 + `HasGrantable()` 语义 + 残卷伪码补完）
  - systems/monetization.md（礼包 ① ② 的抽取口径与空池兜底）
  - systems/common-properties.md（账号级 RNG 加具名域；`Rarity` 的第三个消费点）
  - systems/services/profile-service.md（`GrantPoolPicker` 的 API 面 + 授予前的抽取落点）
  - systems/services/content-service.md（`DrawPool<T>` 的第四个调用方登记）
  - systems/balance.md（授予池的 `RarityTier` 权重表初值）
  - systems/player-profile/achievement/（成就奖励 = **指定条目 · 成就限定**，不走抽取）
status: distilled
decided-on: 2026-08-12
reviewed: 2026-08-12 — 用户裁决 §A=A1（单张共用权重表）· §B=B1（硬保证不补发）+ 追加前置校验 · §C=成就奖励不并入抽取（指定条目 · 成就限定）
distilled-to: handoffs/2026-08-12e-ability-grant-draw-pool.md
---

> **已裁决（08-12 · 用户）：** §A 取 **A1 单张共用权重表**；§B 取 **B1 内容侧硬保证 + 报错不补发**，并**加一道前置校验**（不等到兑现才发现）；§C **成就奖励不并入抽取**——成就给的是**指定条目**，且这些条目**为成就限定**（除该成就外无任何其他获取途径、不进任何抽取池），**目的是保证成就奖励恒不落空**。裁决内容已并入正文，`## 仍需用户决定` 改为裁决记录。

# 方案草稿 — 账号级能力授予的候选池与排重规则

## 问题

道统残卷（08-09b）与 premium bundle（08-01b）是账号级法则的两条获取渠道。**获取时机、渠道交互、RNG 三问均已答结**，只剩最后一半：**具体抽哪一条**。

它卡着两处具体的东西：

- 08-09b 残卷伪码里的 `pickedPowerId`（掷中后授予哪一条）与 `HasGrantable()`（「池已取尽 ⇒ 静默停摆」这条全局前置的判据）；
- `monetization.md` 待答项「随机的口径」——礼包 ① 随机 1 个 PlayerPower、② 随机 2 个 PlayerItem 的「随机」到底是什么。

08-10c 已指出**一次合并收口的机会**：它与置换候选池是同一形状的问题（`AllEnabled()` 全池 → 排除已有 → seeded 抽一条），差别只在残卷侧不限稀有度、走账号级 RNG。本草稿即按这条思路收口。**成就奖励经裁决不并入**（它给指定条目，见 §8），故抽取的调用方是**三个**：残卷 · 礼包 · 置换。

## 约束（来自既有设计）

- **抽取必走 `AllEnabled()`**，不得自写 `AllIncludingDisabled().Where(...)`；仓储上没有中性名 `All()`。`systems/common-properties.md`、`systems/services/content-service.md`。
- **`DrawPool<T>` 已采纳、排到第二阶段开工前**：`AllEnabled()` 返回类型升为 `readonly struct DrawPool<T>`，seeded 抽取（`PickOne` / `PickMany` / `Filter`）**只定义在它之上**。`systems/services/content-service.md`。
- **置换候选池已定案（08-10c）：** `AllEnabled()` → 同 `(Kind, Scope)` → 同 `Rarity` → 排除已持有 → 走 `reward` 子流抽一条；空池 = 整个置换成为空操作 + `PushWarning` 带定位上下文。`systems/player-profile/player-power/_index.md`。
- **账号级随机与轮回随机是两条不相交的线（08-09b）：** 结果写 `PlayerProfile` 的随机**绝不可从 `CycleSeed` 派生**；形态为 `Hash64(AccountSeed, <账号级单调序号>)`，**序号同时是幂等键**。`systems/common-properties.md`。
- **`Rarity: RarityTier { Tier1..Tier5 }` 落在内容定义上**（`PowerData` / `ItemData` / `CardData`），缺失 → `PushError`；既有两个消费点 = 战后奖励池权重、置换候选池过滤键。`systems/common-properties.md`。
- **`AbilityChangeElement` 只承载已定稿的 `Id`**——随机必须在 spec 组装**之前**掷完，否则同一份 spec 重放两次得到不同结果，而 `PastEventEntry.AppliedChange` 要求它可重放。`systems/services/profile-service.md`。
- **授予通道强制携带 `Source`**，`GrantPower(string powerId, Source source)` 无默认值。同上。
- **残卷的全局前置：** 仅当「尚未拥有的法则数 > 0」时才累积、才掷骰、才发放；池取尽 → **静默停摆**。`systems/player-profile/player-power/_index.md`。
- **付费获得的法则不会被游戏销毁**（08-06b · 承重），付费边界是「花钱体验更好、不滑向 pay-to-win」。`systems/monetization.md`。
- **`UsableScene` 含 `InCombat` 的法则 ≤ 1/5**——这是**内容侧配额纪律**，加载时统计比例 + `PushWarning`。`systems/player-profile/player-power/_index.md`。

## 建议方案

### 1. 一段抽取，三个调用方：`AllEnabled()` → `(Kind, Scope)` → 去成就限定 → 排除已持有 → [可选 `Rarity`] → seeded 抽

`[既有推演]`

置换池已经把这条链定死了；残卷与礼包是**同一形状的授予**，没有任何理由各写一份。统一形态：

```
DrawPool<TData> pool = Content.AllEnabled<TData>()
    .Filter(d => d.Kind == kind && d.Scope == scope)   // 四个独立池，判据同置换
    .Filter(d => d.ExclusiveSource == null)            // 去成就限定：专属条目不进任何抽取池（§8）
    .Filter(d => !owned.Contains(d.Id))                // 排重：排除已持有
    [.Filter(d => d.Rarity == anchorRarity)]           // 仅置换：锚定被换出条目的稀有度
```

**四类池的口径与置换完全一致**（`(Kind, Scope)` 全同 ⇒ `PlayerPower` / `PlayerItem` / `CharacterPower` / `CharacterItem` 四个独立池）。残卷与礼包 ① 取 `(Power, Player)`，礼包 ② 取 `(Item, Player)`。

三点顺带明确：

- **不按 `UsableScene` 过滤。** 「战斗内法则 ≤ 1/5」是内容侧的**条目比例**纪律，抽取侧再加一道过滤等于把同一条闸门做成两处、且会让实际掉落比例偏离内容侧的编排意图。
- **不按 `status` / `disabledAbility` 过滤。** 那是生效维度，与持有维度正交（08-10c 既定）；被禁用的法则**照常算作已持有**、照常排除出池。
- **`ContentEnabled` 的语义天然吃进来。** 线上关闭一条法则 ⇒ 它退出抽取池，但玩家**已持有**的那条照常 `Get(id)` 解析、照常计入 `x`、照常排除自身（它本就不在池里）。无需任何额外规则。

### 2. 「抽到重复怎么办」——这个问题在结构上被消解

`[既有推演]`

排重发生在**取池阶段而非掷骰之后**：池里根本没有已持有的条目，因此**抽不出重复**。这不是本草稿的选择，而是既有设计已经隐含的答案——08-09b 的全局前置写的就是「**尚未拥有的法则数 > 0** 才掷骰」，它只有在「池 = 未持有集合」时才自洽。

由此 `HasGrantable()` 的定义直接落地：

> **`HasGrantable()` ⟺ 按 §1 构造的池非空。**

它与全局前置是同一个判断，不是两个。**残卷伪码的 `_powerPool.HasGrantable()` 与 `pickedPowerId` 由此全部有定义，08-09b 的伪码就此可执行。**

一次授予多条时（礼包 ② 的 2 件古宝）用**无放回抽取**（`PickMany(rng, 2)` 语义 = 无放回），保证两件不同。`PickMany` 的无放回语义应写进 `DrawPool<T>` 的契约——这是它唯一一处会被误实现成有放回的地方。

### 3. 稀有度：残卷与礼包**按 `RarityTier` 加权**抽，共用一张表（**已裁决 · A1**）

`[取向选择 → 已裁决]`

**取一张共用的「授予池稀有度权重表」加权**，理由：

- `RarityTier` 的存在理由就是「同一池内不同档位不等概率」。若账号级授予走等概率，则一条 `Tier5` 法则与一条 `Tier1` 法则掉落概率相同，**内容侧一旦多写 20 条低档法则，高档条目的实际稀有度就被稀释**——稀有度字段形同虚设。
- **共用一张表**（而非礼包一张、残卷一张）保留单一旋钮。分表等于让付费直接买到更高档强度，与「礼包净强度较 08-09b 已上升是被接受的、平衡时按此校准」叠加两次。

**权重表初值（待实测校准，归 `systems/balance.md`，随 overlay 可调）：**

| `RarityTier` | Tier1 | Tier2 | Tier3 | Tier4 | Tier5 |
|---|---|---|---|---|---|
| 权重 | 40 | 27 | 18 | 10 | 5 |

推导：相邻档约 ×0.6 递减，五档跨度 8:1。取 0.6 而非更陡的 0.5，是因为账号级法则的**获取次数极少**（残卷一个账号生命周期内量级为个位数、礼包 1 次），过陡会让 `Tier4/Tier5` 事实上不可达、白写内容。

**权重按剩余池即时归一**（排除已持有之后再归一），推论：老账号的池会逐渐只剩高档条目，**高档占比自然上升**。这是好的——它与残卷的递减掉率曲线方向相反，恰好让「越往后越难拿到，但拿到的更好」，不需要为此再加任何规则。

**校验：任一档权重为 0 → `PushError`。** 否则会出现「池非空但抽不出来」的状态，让 `HasGrantable()` 说谎。

### 4. 账号级 RNG 需要一个**具名域**，否则两条渠道会撞出同一序列

`[既有推演]` —— 这是对 08-09b 既定形态的一处**必要修订**，见 `## 与既有决策的张力`。

08-09b 写的是 `Hash64(AccountSeed, ordinal)`，唯一用例是残卷（`ordinal = FinaleWinOrdinal`）。礼包一旦也用账号级掷骰，它必然有自己的序号（`1, 2, …`），于是**同一 `AccountSeed` + 同一整数 ⇒ 同一 `Hash64` 输出**：礼包的第 1 次授予与残卷的第 1 次胜利掷骰共享同一随机数。两者消费方式不同（一个作命中判定、一个作池索引），玩家感知不到，但这是一条**没有理由留着的相关性**，且日后第三条渠道加入时会越来越难排查。

建议与 `CycleSeed` 的具名子流同构，给账号级随机同样的具名域：

```csharp
enum AccountStream { PowerFragment, PremiumBundle }   // 成就奖励无随机，不占域（§8）

// 派生一次、连续抽多条，序列由 (stream, ordinal) 完全确定 ⇒ 幂等
RandomNumberGenerator AccountRng.For(AccountStream stream, int ordinal);
// 内部：seed = Hash64(AccountSeed, (ulong)stream, (ulong)ordinal)
```

- 残卷的掷骰改为 `AccountRng.For(PowerFragment, ordinal)` 取一个万分比 —— **命中判定语义不变**，只是加了域。
- 礼包一次授予要抽 3 条（1 法则 + 2 古宝）**共用同一个 rng 实例连续抽**，故整次授予由 `(PremiumBundle, ordinal)` 完全确定，**退出重进 / 重放不改变结果**，与既定的幂等纪律一致。
- **它仍不进 `SeedManager`、不进子流清单**，故「增删子流不 bump schema 版本」那条纪律原样不受影响。

**礼包侧需要一个账号级单调序号 `BundleGrantOrdinal`**（形态同 `FinaleWinOrdinal`：单调递增、不清零、随授予事务一并持久化）。**它落在哪个字段上依赖「礼包持有状态的存档表达」那条待答**，见 `## 前置依赖`。

### 5. 宿主 = `profile-service` 内的 internal `GrantPoolPicker`（形态 A · 同步直返）

`[既有推演]`

抽取需要两样东西：**内容池**（content-service）与**已持有集合**（profile-service）。后者是 profile-service 的自有状态，前者可经服务门面跨服务读取（跨服务方法调用允许，不得触及对方 manager 私有字段）。反向（放 content-service）则要求它读 `PlayerProfile`，违反「服务之间不读写对方字段」。

```csharp
// profile-service 门面，形态 A（纯内存查询，不跨边界，不带 Async）
bool HasGrantable(AbilityKind kind, AbilityScope scope);
bool TryPickGrantable(AbilityKind kind, AbilityScope scope, RandomNumberGenerator rng, out string pickedId);
bool TryPickGrantableMany(AbilityKind kind, AbilityScope scope, RandomNumberGenerator rng, int count, out IReadOnlyList<string> pickedIds);
```

- 失败语义按既定三分法：**可选缺失（池空 / 不足）→ `TryXxx` + `PushWarning`**，由调用方决定降级方式（§6）。
- **抽取结果在 spec 组装之前定稿**，`AbilityChangeElement` 只拿到已定稿的 `Id`——与「随机在 spec 组装前掷完」的既定纪律一致，无需新规则。
- 置换候选池（08-10c）可复用同一 picker，只多传一个 `anchorRarity`；**这样全库只有一处抽取账号级 / 轮回级能力的代码**。

### 6. 空池的处置分档；礼包侧**前置校验 · 不补发**（**已裁决 · B1 + 前置校验**）

`[通行做法]` + `[既有推演]` + `[取向选择 → 已裁决]`

| 渠道 | 空池处置 | 依据 |
|---|---|---|
| 道统残卷 | **静默停摆**，概率停在原值，不掷骰不发放 | 既定（08-09b），玩家侧本就彻底隐含 |
| 置换 | **整个置换成为空操作** + `PushWarning` | 既定（08-10c） |
| **premium bundle** | **前置校验拦截**：购买流程开始前判定池是否够，不够则**不进入购买**并 `PushError` + 上报；真走到兑现仍空 → `PushError` + 上报 + 计未兑现，**不补发** | 见下 |
| 成就奖励 | 不适用——**指定条目，不抽取**（§8） | 08-12 裁决 |

礼包与其余两者有本质区别：**它是玩家付过钱的**。静默少发一条法则 = 收了钱没给货，是客诉与退款级别的问题，且在「强制在线 · 云端权威」下后端必须能看见这件事。既定的「付费内容不会被游戏销毁」讲的是**已授予**的不被拿走；本条补的是**未授予**的不被吞掉。

**三道闸，按时间从早到晚（这是「前置校验」的具体形态）：**

| # | 时机 | 判定 | 失败处置 |
|---|---|---|---|
| ① | **内容加载期**（合并后强校验阶段） | `(Power, Player)` / `(Item, Player)` 通用池条目数 ≥ 单账号可获取上限（残卷分档上限 + 礼包 1/2 之和；**成就限定条目不计入通用池**） | **`PushError`**（由 `PushWarning` 升格——它是内容侧硬保证的机械化，越界必须在启动期就大声失败） |
| ② | **购买入口**（进入付费流程之前） | 当前账号的可授予池 ≥ 礼包所需（1 法则 + 2 古宝，均已排除已持有） | **购买入口不可用 / 拒绝进入付费流程** + `PushError` + 上报。**这是「不收钱又不给货」的真正防线**——把失败点挪到掏钱之前，从「退款争议」降级为「暂不可购买」 |
| ③ | **兑现结算**（`spec` 组装时） | `TryPickGrantable*` 是否成功 | 理论不可达（②已拦）。真发生 → `PushError` + 上报 + 该项计未兑现，**不补发、不折价、不降级替代**；③ ④ 重试上限照常兑现 |

**内容侧硬纪律**：`(Power, Player)` 与 `(Item, Player)` 两个通用池的条目总数必须显著大于单账号可获取上限；闸 ① 是它的机械化检查，与 `UsableScene ≤ 1/5` 的比例检查同一处落地。**空池是运营事故，不是玩法分支**——不为它设计兜底玩法。

### 7. 日志与校验

`[既有推演]`

```
[GrantPool-Pick] kind=Power scope=Player stream=PremiumBundle ordinal=1 poolSize=37 picked=power_xxx rarity=Tier3
[GrantPool-Check] bundle blocked, kind=Item scope=Player available=1 required=2      → PushError + 上报（闸 ②）
[GrantPool-Pick] pool empty, kind=Item scope=Player stream=PremiumBundle ordinal=1   → PushError + 上报（闸 ③，理论不可达）
```

- 能力得失是玩家最在意、最容易被投诉的一类变更，`ProfileManager` 侧已有 `AbilityChangeElement` 的可追溯性日志；**抽取侧再留一行**，使「为什么给了这条」可复盘（`poolSize` + `ordinal` 足以离线复算）。
- 加载期校验（均 `PushError`）：权重表任一档为 0；`(Power, Player)` / `(Item, Player)` 通用池条目数低于单账号可获取上限；成就奖励引用的 `Id` 悬空或其 `ExclusiveSource != AchievementReward`（见 §8 校验表）。

### 8. 成就奖励 = **指定条目 + 成就限定**，不进任何抽取池（**已裁决 · C**）

`[取向选择 → 已裁决]`

成就奖励**不走 §1 的抽取**：每条成就奖励**指定**具体条目 `Id`；且这些条目是**成就限定**的——**除该成就外没有任何其他获取途径**（不进残卷池、不进礼包池、不进置换的**换入**侧）。

**「成就限定」的目的是保证成就奖励恒不落空。** 若成就指定的条目同时躺在通用池里，玩家完全可能在达成成就之前就从残卷 / 礼包 / 置换拿到它；等成就达成时，`spec` 里那条 `Grant` 指向一个**已持有**的条目——按 §2 的排重语义，这一发就是空的。**成就是一次性的确定回报，没有第二次机会补发**，所以这条不能靠概率侥幸，必须由准入规则从结构上排除。

由此得到一条**不变式**：

> **成就限定条目在其成就发放的那一刻，玩家必然尚未持有。**

它是可断言的——发放时若目标条目已在持有集合 → `PushError`（说明限定被破坏，或该成就被重复发放，两者都是缺陷）。**这条断言正是「不落空」从口头保证变成机械保证的那一步。**

两条附带推论：

- **`AccountStream` 不需要 `AchievementReward` 成员**（无随机 ⇒ 无掷骰 ⇒ 无序号）。授予路径退化为「读成就配置的 `Id` → `spec.Add(GrantPower, id, Source.AchievementReward)`」，比抽取路径短得多。
- **置换的两侧不对称：换入侧永不出现成就限定条目；换出侧不禁止**——玩家自愿把成就条目换掉是既定三形态表里的正向决策（「置换是卡组构筑式的取舍」），且既定的「置换所得继承 `SourceCode`」原样成立。**不落空管的是发放那一刻，不是此后玩家自己的取舍。**

**形态：内容定义上新增可空共有字段 `ExclusiveSource: Source?`（默认 `null` = 通用）。**

| | `ExclusiveSource` | `SourceCode` |
|---|---|---|
| 落点 | **内容定义**（`PowerData` / `ItemData`） | **持有条目** |
| 语义 | 这条内容**只能由哪条渠道给出**（准入） | 这一次获取**实际来自哪条渠道**（记账） |
| 消费点 | §1 的取池过滤 | 残卷的 `x` |
| 不填的含义 | `null` = 通用，任何渠道都能给 | 无「不填」——授予通道强制携带（既定） |

两者名字相近但方向相反，**文档里必须并排写出这张对照表**，否则必被混淆。选 `Source?` 而非新开一个布尔 `AchievementExclusive`，是因为**同一个问题日后必然重演**（例如活动限定、剧情限定条目）；复用既有枚举让「限定给谁」成为一次数据填写，而非每次新增一个布尔字段——与「新增内容 = 新增 `.tres`，不改 switch」同一条纪律。

**校验（三条，全部 `PushError`）——它们合起来才等于「不落空」：**

| 时机 | 判定 | 漏掉的后果 |
|---|---|---|
| 加载期 | 每条成就奖励指定的 `Id` **存在**（走既有交叉引用校验） | 成就发放时授予一个不存在的条目 |
| 加载期 | 每条成就奖励指定的条目 **`ExclusiveSource == Source.AchievementReward`** | 条目仍在通用池里 ⇒ 可被提前拿到 ⇒ 空发 |
| 发放时 | 目标条目**不在**玩家持有集合中（上文不变式的断言） | 空发已经发生，只是没人看见 |

**指定条目被 `ContentEnabled = false` 关闭时照常发放**——读取侧 `Get(id)` 不过滤是既定语义，且成就奖励是承诺给玩家的确定回报，不该被放量开关吞掉；`ContentEnabled` 对成就限定条目实际只影响不到任何抽取池（它本就不在池里），因此关它没有意义，可在内容评审口径里提一句。

**范围提醒：** 本节只定「怎么给」，**不定「给哪些条目」**——后者仍归待答项「成就奖励的具体条目目录」。

## 具体形态（可 derive 的落地面）

**残卷伪码的两处空缺补完**（其余行原样，取自 08-09b §8）：

```csharp
if (!Profile.HasGrantable(AbilityKind.Power, AbilityScope.Player)) return;   // 池已取尽：静默停摆
...
var rng = AccountRng.For(AccountStream.PowerFragment, ordinal + 1);
int roll = (int)(rng.Randi() % 10000U);
...
if (roll < effective)
{
    if (Profile.TryPickGrantable(AbilityKind.Power, AbilityScope.Player, rng, out var pickedPowerId))
    {
        spec.Add(GrantPower, pickedPowerId, Source.FinaleWin);
        spec.Set(PowerFragmentAccumulated, _balance.PowerFragmentBase(x + 1));
    }
    // else：与入口处的 HasGrantable 判断之间不存在时序缝隙（同一事务内），走 PushWarning 并视作未命中
}
```

**礼包兑现伪码：**

```csharp
// 闸 ②：购买入口，掏钱之前
if (!Profile.HasGrantable(AbilityKind.Power, AbilityScope.Player)
    || Profile.GrantableCount(AbilityKind.Item, AbilityScope.Player) < 2)
{
    BlockPurchase();                                         // 入口不可用 + PushError + 上报
    return;
}

// 闸 ③：兑现结算（理论不可达的分支仍须显式处理）
var rng = AccountRng.For(AccountStream.PremiumBundle, bundleGrantOrdinal + 1);
if (Profile.TryPickGrantable(AbilityKind.Power, AbilityScope.Player, rng, out var powerId))
    spec.Add(GrantPower, powerId, Source.PremiumBundle);
else
    ReportUnfulfilled(BundleItem.Power);                     // PushError + 上报，见 §6

if (Profile.TryPickGrantableMany(AbilityKind.Item, AbilityScope.Player, rng, 2, out var itemIds))
    foreach (var id in itemIds) spec.Add(GrantItem, id, Source.PremiumBundle);
else
    ReportUnfulfilled(BundleItem.Items);                     // 含「只够 1 件」的部分情形

spec.Set(RetryCapChapter2, 9);                               // ③ ④ 不依赖内容池，照常兑现
spec.Add(BundleGrantOrdinal, +1);
```

**新增 / 修订字段与类型：**

| 项 | 形态 | 落点 | 说明 |
|---|---|---|---|
| `AccountStream` | `enum { PowerFragment, PremiumBundle }` | `systems/common-properties.md` | 账号级随机的具名域；对齐 `CycleSeed` 的子流命名。成就无随机、不占域 |
| `AccountRng.For(stream, ordinal)` | 静态工厂 → `RandomNumberGenerator` | 同上 | 一次派生、连续抽；`(stream, ordinal)` 是幂等键 |
| `ExclusiveSource` | `Source?`，默认 `null` | `systems/common-properties.md`（挂 `PowerData` / `ItemData`） | 内容定义上的**准入**标记；`!= null` 的条目不进任何抽取池 |
| `BundleGrantOrdinal` | `int`，单调递增、不清零 | **待定**，见前置依赖 | 礼包授予序号 |
| `GrantPoolWeights` | 五档整数权重 | `systems/balance.md` | 初值 40/27/18/10/5；任一档为 0 → `PushError` |
| `HasGrantable` / `GrantableCount` / `TryPickGrantable` / `TryPickGrantableMany` | 形态 A | `systems/services/profile-service.md` | 门面方法，internal `GrantPoolPicker` 承载；`GrantableCount` 供闸 ② 判「够不够 2 件」 |

## 后果

- **`systems/player-profile/player-power/_index.md`**：候选池定义 + `HasGrantable()` 语义落地，08-09b 伪码由「带一处待定」变为完整可执行；该条待决问题移出。
- **`systems/monetization.md`**：「随机的口径」答结（① ② 走同一段抽取、无放回、加权）；新增**三道闸的前置校验**与「不补发」的处置纪律；**购买入口新增一条可用性前置条件**（这条会牵动 `ux/screen-flow.md` 的礼包入口态——那属另一条待答，此处只留一句约束）。
- **`systems/common-properties.md`**：账号级 RNG 形态由 `Hash64(AccountSeed, ordinal)` 修订为带具名域；`Rarity` 的消费点由两个增为**三个**（战后奖励池 / 置换过滤键 / **账号级授予池权重**）；**新增内容共有字段 `ExclusiveSource`**，并与 `SourceCode` 并排写出对照表。
- **`systems/player-profile/achievement/`**：奖励形态定为**指定条目 + 成就限定**，不走抽取；新增「成就奖励恒不落空」的不变式与三条校验；条目目录仍待定。**内容侧多一条编排纪律**：每条成就奖励都需要一个专属条目，成就目录与内容目录由此**一一对应地一起增长**（内容侧应正视这条工作量）。
- **`systems/services/content-service.md`**：`DrawPool<T>` 的调用方由三处（物化 / 商店 / 奖励）增为四处（+ 账号级授予），且 `PickMany` 的**无放回语义**成为契约的一部分——**这加强了「第二阶段开工前落地 `DrawPool<T>`」的排期理由**。
- **`systems/balance.md`**：新增授予池权重表；它是既有待答项「`RarityTier` 的分布与权重表未定」的**第一张具体表**（战后奖励池与置换池的表仍待定）。
- **存档 schema**：仅在礼包序号落点确定后 bump（`BundleGrantOrdinal`）；本方案其余部分**不新增存档字段**（`ExclusiveSource` 落内容定义，不落存档）。
- **不影响**：`SeedManager` 四条子流、确定性边界、残卷的累积 / 闸门 / 首胜规则、`SourceCode` 的 `x` 口径与单调不减。

## 备选方案（已考虑并否决）

- **全池等概率抽（不排除已持有），抽到重复则重掷 / 转为等价补偿。** 否决：与 08-09b 的全局前置「尚未拥有的法则数 > 0」直接矛盾（若允许重复，池永不取尽，那条前置无意义）；且「重掷」会让掷骰次数不定，破坏 `(stream, ordinal)` 的幂等性。
- **抽到重复转为「该法则 +1 层强度」。** 否决：本作的法则没有等级 / 层数维度，引入即是一套新机制；且与「置换是唯一的强度取舍面」相悖。
- **每条渠道各写一份抽取逻辑。** 否决：三个调用方形状相同，散写必然在某一处漏掉 `AllEnabled()` 或漏掉排重——正是 `DrawPool<T>` 那条纪律要防的事。
- **成就奖励也走随机抽取（草稿初版的写法）。** 08-12 裁决否决：成就是**确定性的里程碑回报**，随机会让「达成了同一个成就却拿到不同东西」，与里程碑语义相悖；且指定条目让成就设计能与奖励内容互相呼应。
- **成就指定通用条目 + 「已持有则改发别的」兜底。** 否决：那正是「落空」的另一种形态（玩家拿到的不是成就设计好的那件东西），且要为它设计一套替补规则；`ExclusiveSource` 从准入侧一刀切断，零运行时分支。
- **成就专属条目用一个布尔 `AchievementExclusive` 标记。** 否决：日后活动限定 / 剧情限定必然重演同一诉求，届时又加一个布尔。`ExclusiveSource: Source?` 一个字段覆盖全部限定渠道。
- **礼包空池时只在兑现处报错、不做前置拦截。** 否决（08-12 裁决）：那让玩家在**付款之后**才撞上失败，是最糟的失败时机；闸 ② 把它降级为「暂不可购买」。
- **残卷池排除高稀有度、把 `Tier5` 留给礼包。** 否决：等于「最好的东西只能买」，直接踩「不滑向 pay-to-win」的边界；且与「付费的战斗价值由古宝承载、法则保持稀缺」的既定分工冲突。
- **礼包空池时以灵玉 / 其他资源折价补偿。** 否决（作为默认项）：本作没有账号级可支配货币，为兜底引入一条等于新开一套经济，与残卷「不发放账号级货币」的论证同一条理由。

## 与既有决策的张力

**① 账号级 RNG 形态的一处修订（建议松动，代价极小）。** 08-09b 与 `systems/common-properties.md` 明写 `Hash64(AccountSeed, <账号级单调序号>)` 两个参数。本方案建议改为**三参数（含具名域）**。松动的必要性见 §4（两条渠道的序号会撞出同一序列）；代价是 `AccountSeed` 的复算契约多一个参数，**后端侧需同步**——建议与既有的「`AccountSeed` 的下发与复算协议形态」那条后端待答**合并成一份后端 handoff**，不单开。若用户选择不动它，替代方案是**给各渠道分配不相交的序号区间**（如残卷 `1..`、礼包 `10_000_000..`），能达到同样效果但更脆（区间耗尽 / 新渠道加入时需重新分配），**不推荐**。

**② 与「`x` 单调不减」无张力。** 本方案不改 `SourceCode` 的写入规则，礼包给的法则仍记 `PremiumBundle`、不计入 `x`。

**③ 与在办草稿 `solution-draft-grant-source-per-kind-scope.md` 无冲突，但 `ExclusiveSource` 与它有一处交汇。** 那份改的是 `Source` 的**成员清单**，本份改的是**抽哪一条**；两者在 `spec.Add(GrantPower, id, source)` 这一行交汇但互不覆盖，`Source.PremiumBundle` / `Source.FinaleWin` 取值在两种清单下都原样成立。**交汇点**：`ExclusiveSource` 复用 `Source` 作类型，故清单一旦扩为按 `(Kind, Scope)` 分域的开放清单，`ExclusiveSource` 的合法取值域也随之扩大——这是想要的（活动限定 / 剧情限定自然获得取值），**但两份草稿提炼时应保持先后**：先定 `Source` 清单，再落 `ExclusiveSource`。

**④ `SourceCode` 与 `ExclusiveSource` 命名相近、方向相反。** 一个记「实际来自哪」（持有条目），一个定「只能来自哪」（内容定义）。这是本方案引入的**唯一一处易混点**，缓解方式是文档并排写出 §8 的对照表；若用户认为仍不够，替代命名可取 `GrantChannelLock` 一类更长但更不易混的名字——本草稿倾向保留 `ExclusiveSource`（与 `Source` 同族、读起来即是「限定来源」）。

## 前置依赖

- **`BundleGrantOrdinal` 的落点**依赖待答项「**礼包持有状态的存档表达与服务端权威**」（`CapabilityFlag` / modifier / 独立 `Entitlement`）。本方案只约束它的**形状**（账号级、单调递增、不清零、随授予事务同一次持久化），落点待那条答定。
- **礼包是否可重复购买**（`monetization.md` 待答）会影响序号的量级与「同一账号第二次礼包是否可能抽到与第一次相同的条目」——按 §1 的排重，**不可能**（第一次给的已进持有集合）。故本方案对该问题**不构成阻塞**，只是那条答定后需回来确认一句。
- **权重表的最终数值**依赖内容侧各档条目数量（`systems/balance.md` 的既有待答「`RarityTier` 的分布与权重表未定」）。本方案给的是**结构 + 初值**，结构是硬的、数值待实测。
- **`ExclusiveSource` 的取值域**依赖在办草稿 `solution-draft-grant-source-per-kind-scope.md`（`Source` 清单）。提炼顺序：先 `Source`、后 `ExclusiveSource`。

## 裁决记录（08-12 · 用户）

| 项 | 原选项 | 裁决 | 落在正文 |
|---|---|---|---|
| §A 稀有度加权 | A1 单张共用表 / A2 等概率 / A3 分渠道两表 | **A1** | §3 |
| §B 礼包空池 | B1 硬保证不补发 / B2 记缺额补发 / B3 降级替代 | **B1**，并**追加前置校验**——不等到兑现才发现，闸 ② 拦在付款之前 | §6 |
| §C 成就奖励 | 并入抽取 / 另有口径 | **不并入**：**指定条目**，且**为成就限定**——除该成就外无任何其他获取途径，**目的是保证成就奖励恒不落空** | §8（新增） |

裁决引出的两处新增，均由裁决直接推演、非新决策：**① `ExclusiveSource: Source?`** —— 「除成就外无其他获取途径」必须有一个把条目挡在全部抽取池外的机械表达，否则「不落空」只是一句口头约定；**② 闸 ②（购买入口前置校验）** —— 「前置校验报错」在付费流程里的唯一有意义落点就是掏钱之前。二者若与用户本意不符，请在提炼前指出。

**本草稿无剩余待决项，可直接喂给 `/analyze-new-ideas`。**
