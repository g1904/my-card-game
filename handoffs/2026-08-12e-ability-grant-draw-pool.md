# 账号级能力授予的候选池与排重规则：三条渠道共用一段抽取；成就奖励改走「指定条目 + 成就限定」

- id: 2026-08-12e-ability-grant-draw-pool
- date: 2026-08-12
- topic: systems/player-profile/player-power/_index.md | systems/monetization.md | systems/common-properties.md | systems/player-profile/achievement/_index.md | systems/services/profile-service.md | systems/services/content-service.md | systems/balance.md
- status: distilled
- distilled-to: `systems/player-profile/player-power/_index.md`, `systems/monetization.md`, `systems/common-properties.md`, `systems/player-profile/achievement/_index.md`, `systems/services/profile-service.md`, `systems/services/content-service.md`, `systems/balance.md`, `open-questions.md`, `open-questions/07-codex-monetization.md`, `open-questions/update-log.md`, `answer-logs/log-ability-grant-draw-pool.md`
- 输入：`inbox/solution-draft-ability-grant-draw-pool.md`（`status: decided`，三项取向 §A / §B / §C 已由用户裁决）+ 本次 interview 追加三项裁决

## Intent（distilled）

**一句话：** 残卷 · 礼包 · 置换三条渠道共用**同一段抽取**（`AllEnabled()` → `(Kind, Scope)` → 去成就限定 → 排除已持有 → 加权 seeded 抽），「抽到重复」因排重发生在**取池阶段**而在结构上消解，`HasGrantable()` 由此得到定义、08-09b 的残卷伪码补完；成就奖励**不并入抽取**，改为**指定条目 + 成就限定**以保证恒不落空。

### 1. 一段抽取，三个调用方

```
DrawPool<TData> pool = Content.AllEnabled<TData>()
    .Filter(d => d.Kind == kind && d.Scope == scope)   // 四个独立池，判据同置换
    .Filter(d => d.ExclusiveSource == null)            // 去成就限定：专属条目不进任何抽取池
    .Filter(d => !owned.Contains(d.Id))                // 排重：排除已持有
    [.Filter(d => d.Rarity == anchorRarity)]           // 仅置换：锚定被换出条目的稀有度
    .PickOne(rng, weightByRarity)                      // 加权（置换侧已锚定稀有度，退化为等概率）
```

- **四类池的口径与置换（08-10c）完全一致**：`(Kind, Scope)` 全同 ⇒ `PlayerPower` / `PlayerItem` / `CharacterPower` / `CharacterItem` 四个独立池。残卷与礼包 ① 取 `(Power, Player)`，礼包 ② 取 `(Item, Player)`。
- **不按 `UsableScene` 过滤。** 「战斗内法则 ≤ 1/5」是内容侧的**条目比例**纪律；抽取侧再加一道过滤等于把同一条闸门做成两处，且会让实际掉落比例偏离内容侧的编排意图。
- **不按 `status` / `disabledAbility` 过滤。** 生效维度与持有维度正交（08-10c 既定）；被禁用的法则**照常算作已持有**、照常排除出池。
- **`ContentEnabled` 的语义天然吃进来。** 线上关闭一条法则 ⇒ 它退出抽取池；玩家**已持有**的那条照常 `Get(id)` 解析、照常计入 `x`、照常排除自身（它本就不在池里）。无需任何额外规则。

### 2. 「抽到重复怎么办」在结构上被消解

排重发生在**取池阶段而非掷骰之后**：池里根本没有已持有的条目，因此**抽不出重复**。这不是本次的新选择，而是既有设计已经隐含的答案——08-09b 的全局前置写的就是「**尚未拥有的法则数 > 0** 才掷骰」，它只有在「池 = 未持有集合」时才自洽。

由此：

> **`HasGrantable()` ⟺ 按 §1 构造的池非空。** 它与残卷的全局前置是同一个判断，不是两个。

一次授予多条时（礼包 ② 的 2 件古宝）用**无放回抽取**（`PickMany(rng, 2)`），保证两件不同。

### 3. 稀有度：按 `RarityTier` 加权，残卷与礼包共用一张表（裁决 · A1）

- `RarityTier` 的存在理由就是「同一池内不同档位不等概率」。若账号级授予走等概率，则内容侧一旦多写 20 条低档法则，高档条目的实际稀有度就被稀释——稀有度字段形同虚设。
- **共用一张表**（而非礼包一张、残卷一张）保留单一旋钮。分表等于让付费直接买到更高档强度，与「礼包净强度较 08-09b 已上升是被接受的」叠加两次。

**权重表初值**（归 `systems/balance.md`，随 overlay 可调）：Tier1–Tier5 = **40 / 27 / 18 / 10 / 5**。推导：相邻档约 ×0.6 递减、五档跨度 8:1；取 0.6 而非更陡的 0.5，是因为账号级法则的**获取次数极少**（残卷一个账号生命周期内量级为个位数、礼包 1 次），过陡会让 Tier4/Tier5 事实上不可达、白写内容。

**权重按剩余池即时归一**（排除已持有之后再归一）。推论：老账号的池会逐渐只剩高档条目，**高档占比自然上升**——它与残卷的递减掉率曲线方向相反，恰好让「越往后越难拿到，但拿到的更好」，不需要为此再加任何规则。

**校验：任一档权重为 0 → `PushError`**，否则会出现「池非空但抽不出来」的状态，让 `HasGrantable()` 说谎。

### 4. 账号级 RNG 加具名域 `AccountStream`（interview 裁决 · 修订既定的两参数形态）

08-09b 写的是 `Hash64(AccountSeed, ordinal)`，唯一用例是残卷。礼包一旦也用账号级掷骰，它必然有自己的序号（`1, 2, …`），于是**同一 `AccountSeed` + 同一整数 ⇒ 同一 `Hash64` 输出**：礼包的第 1 次授予与残卷的第 1 次胜利掷骰共享同一随机数。两者消费方式不同、玩家感知不到，但这是一条**没有理由留着的相关性**，且第三条渠道加入时会越来越难排查。

```csharp
enum AccountStream { PowerFragment, PremiumBundle }   // 成就奖励无随机，不占域（§8）

// 派生一次、连续抽多条，序列由 (stream, ordinal) 完全确定 ⇒ 幂等
RandomNumberGenerator AccountRng.For(AccountStream stream, int ordinal);
// 内部：seed = Hash64(AccountSeed, (ulong)stream, (ulong)ordinal)
```

- 残卷的掷骰改为 `AccountRng.For(PowerFragment, ordinal)` 取一个万分比——**命中判定语义不变**，只是加了域。
- 礼包一次授予要抽 3 条（1 法则 + 2 古宝）**共用同一个 rng 实例连续抽**，故整次授予由 `(PremiumBundle, ordinal)` 完全确定，退出重进 / 重放不改变结果。
- **它仍不进 `SeedManager`、不进子流清单**，「增删子流不 bump schema 版本」那条纪律原样不受影响。
- **礼包侧需要一个账号级单调序号 `BundleGrantOrdinal`**（形态同 `FinaleWinOrdinal`：单调递增、不清零、随授予事务一并持久化）。落点依赖「礼包持有状态的存档表达」那条待答，见 `## Open questions`。
- **⚠ 后端侧需一份对应 handoff**：`AccountSeed` 的复算契约多一个参数。建议与既有的「`AccountSeed` 的下发与复算协议形态」那条后端待答合并，不单开。

**否决的替代**：给各渠道分配不相交的序号区间（残卷 `1..`、礼包 `10_000_000..`）——效果相同但更脆（区间耗尽 / 新渠道加入时需重新分配，且区间约定不可机械校验）。

### 5. 宿主 = profile-service 内的 internal `GrantPoolPicker`（形态 A · 同步直返）

抽取需要两样东西：**内容池**（content-service）与**已持有集合**（profile-service）。后者是 profile-service 的自有状态，前者可经服务门面跨服务读取（跨服务方法调用允许，不得触及对方 manager 私有字段）。反向（放 content-service）则要求它读 `PlayerProfile`，违反「服务之间不读写对方字段」。

```csharp
bool HasGrantable(AbilityKind kind, AbilityScope scope);
int  GrantableCount(AbilityKind kind, AbilityScope scope);
bool TryPickGrantable(AbilityKind kind, AbilityScope scope, RandomNumberGenerator rng, out string pickedId);
bool TryPickGrantableMany(AbilityKind kind, AbilityScope scope, RandomNumberGenerator rng, int count, out IReadOnlyList<string> pickedIds);
```

- 失败语义按既定三分法：**可选缺失（池空 / 不足）→ `TryXxx` + `PushWarning`**，由调用方决定降级方式（§6）。
- **抽取结果在 spec 组装之前定稿**，`AbilityChangeElement` 只拿到已定稿的 `Id`——与既定纪律一致，无需新规则。
- 置换候选池（08-10c）可复用同一 picker，只多传一个 `anchorRarity` ⇒ **全库只有一处抽取账号级 / 轮回级能力的代码**。

### 6. 空池的处置分档；礼包侧前置校验 · 不补发（裁决 · B1 + 前置校验）

| 渠道 | 空池处置 | 依据 |
|---|---|---|
| 道统残卷 | **静默停摆**，概率停在原值，不掷骰不发放 | 既定（08-09b），玩家侧本就彻底隐含 |
| 置换 | **整个置换成为空操作** + `PushWarning` | 既定（08-10c） |
| **premium bundle** | **前置校验拦截**：购买入口判定池是否够，不够则**不进入购买**并 `PushError` + 上报；真走到兑现仍空 → `PushError` + 上报 + 计未兑现，**不补发** | 见下 |
| 成就奖励 | 不适用——**指定条目，不抽取**（§8） | 本次裁决 |

礼包与其余两者有本质区别：**它是玩家付过钱的**。静默少发一条法则 = 收了钱没给货，是客诉与退款级别的问题，且在「强制在线 · 云端权威」下后端必须能看见这件事。既定的「付费内容不会被游戏销毁」讲的是**已授予**的不被拿走；本条补的是**未授予**的不被吞掉。

**三道闸，按时间从早到晚：**

| # | 时机 | 判定 | 失败处置 |
|---|---|---|---|
| ① | **内容加载期**（合并后强校验阶段） | `(Power, Player)` / `(Item, Player)` **通用池**条目数 ≥ **礼包所需（1 法则 / 2 古宝）+ 可调编排余量**（成就限定条目不计入通用池） | **`PushError`** |
| ② | **购买入口**（进入付费流程之前） | 当前账号的可授予池 ≥ 礼包所需（1 法则 + 2 古宝，均已排除已持有） | **购买入口不可用 / 拒绝进入付费流程** + `PushError` + 上报。**这是「不收钱又不给货」的真正防线**——把失败点挪到掏钱之前，从「退款争议」降级为「暂不可购买」 |
| ③ | **兑现结算**（`spec` 组装时） | `TryPickGrantable*` 是否成功 | 理论不可达（② 已拦）。真发生 → `PushError` + 上报 + 该项计未兑现，**不补发、不折价、不降级替代**；③ ④ 重试上限照常兑现 |

**闸 ① 的判据（interview 裁决）：只断言「礼包所需 + 可调编排余量」，不断言任何「单账号可获取上限」。** 原草稿写的是「残卷分档上限 + 礼包之和」，但 `systems/balance.md` 的残卷三表在 `x ≥ 15` 档仍有 `Gain = +1%` / `Cap = 5%`——**残卷没有任何账号级上限**，且「池已取尽 → 静默停摆」本就是它的**既定正常终局**。因此那个「上限」不可定义，闸 ① 按原写法永远无法成立。收窄后闸 ① 保住了它唯一真实的目的（保护付费兑现），且是可机械校验的。**残卷把池抽干仍按既定的静默停摆处理，不是事故。**

**否决**：为残卷新设一个账号级硬上限（新机制，且与「池取尽 → 静默停摆」重复承担同一职责）；删掉闸 ①（失去启动期就大声失败的能力，内容缺口只有等到某个玩家撞上才显形）。

**内容侧硬纪律**：`(Power, Player)` 与 `(Item, Player)` 两个通用池的条目总数必须显著大于礼包所需；闸 ① 是它的机械化检查，与 `UsableScene ≤ 1/5` 的比例检查同一处落地。**空池是运营事故，不是玩法分支**——不为它设计兜底玩法。

### 7. 日志与校验

```
[GrantPool-Pick] kind=Power scope=Player stream=PremiumBundle ordinal=1 poolSize=37 picked=power_xxx rarity=Tier3
[GrantPool-Check] bundle blocked, kind=Item scope=Player available=1 required=2      → PushError + 上报（闸 ②）
[GrantPool-Pick] pool empty, kind=Item scope=Player stream=PremiumBundle ordinal=1   → PushError + 上报（闸 ③，理论不可达）
```

能力得失是玩家最在意、最容易被投诉的一类变更；`ProfileManager` 侧已有 `AbilityChangeElement` 的可追溯性日志，**抽取侧再留一行**，使「为什么给了这条」可复盘（`poolSize` + `ordinal` 足以离线复算）。

加载期校验（均 `PushError`）：权重表任一档为 0；两个通用池条目数低于闸 ① 的阈值；成就奖励引用的 `Id` 悬空或其 `ExclusiveSource != AchievementReward`。

### 8. 成就奖励 = 指定条目 + 成就限定，不进任何抽取池（裁决 · C）

成就奖励**不走 §1 的抽取**：每条成就奖励**指定**具体条目 `Id`；且这些条目是**成就限定**的——**除该成就外没有任何其他获取途径**（不进残卷池、不进礼包池、不进置换的**换入**侧）。

**「成就限定」的目的是保证成就奖励恒不落空。** 若成就指定的条目同时躺在通用池里，玩家完全可能在达成成就之前就从残卷 / 礼包 / 置换拿到它；等成就达成时，`spec` 里那条 `Grant` 指向一个**已持有**的条目——按 §2 的排重语义，这一发就是空的。**成就是一次性的确定回报，没有第二次机会补发**，所以这条不能靠概率侥幸，必须由准入规则从结构上排除。

> **不变式：成就限定条目在其成就发放的那一刻，玩家必然尚未持有。**

它是可断言的——发放时若目标条目已在持有集合 → `PushError`（说明限定被破坏，或该成就被重复发放，两者都是缺陷）。**这条断言正是「不落空」从口头保证变成机械保证的那一步。**

两条推论：

- **`AccountStream` 不需要 `AchievementReward` 成员**（无随机 ⇒ 无掷骰 ⇒ 无序号）。授予路径退化为「读成就配置的 `Id` → `spec.Add(GrantPower, id, Source.AchievementReward)`」。
- **置换的两侧不对称：换入侧永不出现成就限定条目；换出侧不禁止**——玩家自愿把成就条目换掉是既定三形态表里的正向决策，且「置换所得继承 `SourceCode`」原样成立。**不落空管的是发放那一刻，不是此后玩家自己的取舍。**

**形态：内容定义上新增可空共有字段 `ExclusiveSource: Source?`（默认 `null` = 通用）**（interview 确认保留此名，否决 `GrantChannelLock`）。

| | `ExclusiveSource` | `SourceCode` |
|---|---|---|
| 落点 | **内容定义**（`PowerData` / `ItemData`） | **持有条目** |
| 语义 | 这条内容**只能由哪条渠道给出**（准入） | 这一次获取**实际来自哪条渠道**（记账） |
| 消费点 | §1 的取池过滤 | 残卷的 `x` |
| 不填的含义 | `null` = 通用，任何渠道都能给 | 无「不填」——授予通道强制携带（既定） |

两者名字相近但方向相反，**文档里必须并排写出这张对照表**，否则必被混淆。选 `Source?` 而非新开一个布尔 `AchievementExclusive`，是因为**同一个问题日后必然重演**（活动限定、剧情限定条目）；复用既有枚举让「限定给谁」成为一次数据填写，而非每次新增一个布尔字段——与「新增内容 = 新增 `.tres`，不改 switch」同一条纪律。

**校验（三条，全部 `PushError`）——它们合起来才等于「不落空」：**

| 时机 | 判定 | 漏掉的后果 |
|---|---|---|
| 加载期 | 每条成就奖励指定的 `Id` **存在**（走既有交叉引用校验） | 成就发放时授予一个不存在的条目 |
| 加载期 | 每条成就奖励指定的条目 **`ExclusiveSource == Source.AchievementReward`** | 条目仍在通用池里 ⇒ 可被提前拿到 ⇒ 空发 |
| 发放时 | 目标条目**不在**玩家持有集合中（上文不变式的断言） | 空发已经发生，只是没人看见 |

**指定条目被 `ContentEnabled = false` 关闭时照常发放**——读取侧 `Get(id)` 不过滤是既定语义，且成就奖励是承诺给玩家的确定回报，不该被放量开关吞掉；`ContentEnabled` 对成就限定条目实际影响不到任何抽取池（它本就不在池里），故关它没有意义，可在内容评审口径里提一句。

**范围提醒：** 本节只定「怎么给」，**不定「给哪些条目」**——后者仍归待答项「成就奖励的具体条目目录」。

### 9. 落地形态（可 derive 的面）

**残卷伪码的两处空缺补完**（其余行取自 08-09b §8）：

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
    // else：与入口处的 HasGrantable 之间不存在时序缝隙（同一事务内），走 PushWarning 并视作未命中
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
    ReportUnfulfilled(BundleItem.Power);                     // PushError + 上报

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
| `BundleGrantOrdinal` | `int`，单调递增、不清零 | **待定**，见 Open questions | 礼包授予序号 |
| `GrantPoolWeights` | 五档整数权重 | `systems/balance.md` | 初值 40/27/18/10/5；任一档为 0 → `PushError` |
| `GrantPoolMargin` | 整数余量 | `systems/balance.md` | 闸 ① 的编排余量常量 |
| `HasGrantable` / `GrantableCount` / `TryPickGrantable` / `TryPickGrantableMany` | 形态 A | `systems/services/profile-service.md` | 门面方法，internal `GrantPoolPicker` 承载 |

**后果：** `DrawPool<T>` 的调用方由三处（物化 / 商店 / 奖励）增为四处（+ 账号级授予），且**无放回**与**加权**成为其契约的一部分——这加强了「第二阶段开工前落地 `DrawPool<T>`」的排期理由。存档 schema **仅在礼包序号落点确定后** bump（`BundleGrantOrdinal`）；本次其余部分不新增存档字段（`ExclusiveSource` 落内容定义，不落存档）。**不影响**：`SeedManager` 四条子流、确定性边界、残卷的累积 / 闸门 / 首胜规则、`SourceCode` 的 `x` 口径与单调不减。

## Clarifications（interview 产物）

| 问题 | 用户裁决 | 它推翻 / 细化了什么 |
|---|---|---|
| 账号级 RNG 是否加具名域？（草稿「张力 ①」自陈为待用户裁定的松动） | **加具名域（三参数）** | 修订 `systems/common-properties.md` 与 `player-power/_index.md` 既定的 `Hash64(AccountSeed, ordinal)` 两参数形态；否决「序号区间隔离」与「接受相关性」两个替代 |
| 闸 ① 该断言什么？（草稿写「残卷分档上限 + 礼包之和」，而残卷在 `balance.md` 中**无上限**、池取尽是既定终局 ⇒ 该判据不可定义） | **收窄为「礼包所需 + 可调编排余量」** | 改写草稿 §6 闸 ① 一行；否决「给残卷设账号级硬上限」与「删掉闸 ①」 |
| 准入字段取什么名？（草稿「张力 ④」自陈易混、并给出替代） | **保留 `ExclusiveSource: Source?`** | 否决 `GrantChannelLock`；缓解手段 = `common-properties.md` 并排写出与 `SourceCode` 的四行对照表 |

**自行推演（未问，依据既有设计）：**
- **`DrawPool<T>` 契约新增「加权抽取」重载**——§3 要求按 `RarityTier` 加权，而 content-service 现有的 `PickOne(rng)` 无权重面；战后奖励池的稀有度权重（`common-properties.md` 既有的 `Rarity` 消费点 ①）同样需要它 ⇒ 属既有需求的显性化，非本次新增机制。
- **闸 ① 走加载期合并后的 `ContentEnabled` 口径**；线上 flags（08-11b）秒关导致的运行时池收缩由闸 ② 在购买入口兜住——不需要新规则。
- **草稿「前置依赖 · `ExclusiveSource` 的取值域依赖 `solution-draft-grant-source-per-kind-scope`」已自然解除**：该草稿已于同日提炼为 `2026-08-12b`，`Source` 现为按 `(Kind, Scope)` 分域的七值开放清单，`ExclusiveSource` 的取值域直接成立。

## Open questions

- **`BundleGrantOrdinal` 的落点**依赖既有待答「礼包持有状态的存档表达与服务端权威」（`CapabilityFlag` / modifier / 独立 `Entitlement`）。本次只约束它的**形状**（账号级、单调递增、不清零、随授予事务同一次持久化）。
- **权重表的最终数值**依赖内容侧各档条目数量（既有待答「`RarityTier` 的分布与权重表未定」的剩余部分）。本次给的是**结构 + 初值**，结构是硬的、数值待实测。
- **闸 ① 的编排余量 `GrantPoolMargin` 取值**待内容侧条目规模明朗后定；结构已定，初值随第一批内容一并给。
- **成就奖励的具体条目目录**仍未定（本次只定「怎么给」）。连带一条**内容侧编排纪律**：每条成就奖励都需要一个专属条目，成就目录与内容目录由此**一一对应地一起增长**。
- **礼包是否可重复购买**（既有待答）会影响序号量级；按 §1 的排重，第二次礼包**不可能**抽到与第一次相同的条目，故本次对该问题不构成阻塞，那条答定后回来确认一句即可。
- **购买入口的可用性前置条件如何呈现**（闸 ② 的 UI 形态）归既有待答「商业化的 UX 观感」，本次只留一句约束。

## Notes / triage

- **⚠ 跨库：后端侧需一份对应 handoff。** `AccountSeed` 的复算契约由两参数变三参数（加 `AccountStream`）。建议与既有的「`AccountSeed` 的下发与复算协议形态」那条后端待答**合并成一份**，不单开。本次只写客户端库。
- 与在办 / 已提炼草稿的关系：`2026-08-12b`（`Source` 清单）与本次（`ExclusiveSource` 取值域）在 `spec.Add(GrantPower, id, source)` 一行交汇但互不覆盖；`Source` 清单已先行落定，提炼顺序正确。
