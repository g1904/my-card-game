# 单例平衡资源如何进 ContentRegistry

- id: 2026-08-22-singleton-balance-resource-registry
- date: 2026-08-22
- topic: systems/services/content-service · systems/balance · systems/game-progression · content/_index
- status: distilled
- distilled-to: `systems/services/content-service.md` · `content/_index.md`（`systems/balance.md` 与 `systems/game-progression.md` 的承接见下方「未落笔的承接项」）

## Intent（distilled）

**一句话：** `CombatRulesData` 一类「全库恰好一条」的平衡资源与其他内容走同一条路——进 ContentRegistry、走同一个泛型仓储、有稳定两段式 `Id`；调用方不碰 `Id`，改用注册表上带编译期约束的 `Single<T>()` 取那一条；条数与启用态在加载期强校验。

### 1. 进 ContentRegistry，不另开通道

平衡表已被归入本地内容层的「只改不增」一栏，而该栏的三项性质——**overlay 可热更 · 合并后强校验 · 按 `Id` 索引**——全部由 ContentRegistry 兑现。在服务里直读 `res://content/balance/*.tres` 会同时失去这三项：overlay 是按 `Id` 合并进注册表的、不在文件系统层做覆盖，直读即绕过覆盖层，「平衡数值可热更而不发版」当场失效；同时绕开合并后强校验（坏平衡表要到轮回中途才炸）；同时违反「不散落 `ResourceLoader.Load`」。

同形先例是 `LocationMapData`：单份全局唯一、启动加载一次、只读常驻、不进存档，已定为进 ContentRegistry。

### 2. `Id` 形态 = 两段式，且 `Id` 的消费者是 overlay 合并、不是调用方

**这两件事必须分开说。** 单例资源之所以必须有稳定 `Id`，不是因为有人要用 `Id` 去查它，而是因为 **overlay 按 `Id` 覆盖基线**——没有稳定 `Id` 就没有热更。调用方则既不应该、也不需要看到这个 `Id`（见第 4 条）。不分开说，会得出「既然没人查，给不给 `Id` 无所谓」这个错误结论。

形态照抄全库两段式 `<内容类型>.<snake_case_slug>`，slug 取固定 `default`：`combat_rules.default` · `enemy_leveling.default` · `location_map.default`。理由：全库只保留一种 id 语法（「恰好一个点」可机械校验），且日后某份资源真长出第二行时语法不必改。代价是 `.default` 这一段当前不携带信息。

- 前缀沿用「不用裸 `item.` / `power.`」那条前缀词表纪律：平衡资源的类型前缀是资源自己的全名 snake_case，不与次类型命名空间撞车。
- **`Id` 写在 `.tres` 里，不写进任何 C# 常量**——写常量就等于把它变成调用方可见的字符串键，而字符串键正是本库反复否决的形态（`CapabilityFlag` 用 enum 不用字符串 key，判据是「拼错了从编译期推迟到运行时」）。

### 3. 走既有泛型仓储，不新增仓储种类、不新增服务

`IContentRepository<T>` 对全部内容类型是同一形状，而「新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目」已是既定条款。**单例是「合法条目数恰好为 1 的类型」，不是另一种东西**——为它开第二种仓储接口等于给「唯一内容读取入口」开一个平行入口，并立刻要求回答「哪些类型走哪条路」这种逐类型记忆的问题。

### 4. 读取面 = `T Single<T>() where T : Resource, ISingletonContent`

```csharp
T Single<T>() where T : Resource, ISingletonContent;
//   恰好一条 → 返回它
//   零条 / 多条 → 已在 LoadAll() 处 PushError + throw，此处不可能到达
```

- **`Id` 字面量彻底不出现在调用方**——`combat-service` 写 `Content.Single<CombatRulesData>()`，没有可拼错的字符串。与「`CapabilityFlag` 用 enum 不用字符串 key」「`Repo<T>()` 而非七个具名属性」同一种偏好。
- **`where T : ISingletonContent` 是编译闸（阶梯第 2 级）**：对 `CardData` 调 `Single<T>()` 编译不过。与「删掉中性诱饵名 `All()`」同款——不靠条款靠类型。
- 语义与 LINQ 的 `Single()` 逐字一致，读者零学习成本。
- **它不是第二个诱饵名。** `AllEnabled()` / `AllIncludingDisabled()` 那对名字的问题是「两个语义、一个中性名」；`Single<T>()` 只在单例类型上可见，在它可见的地方它就是唯一正确的取法。

### 5. 单例身份由标记接口声明，条数在加载期校验

```csharp
/// 标记：这个内容类型全库恰好一条。ContentRegistry 据此做条数校验并开放 Single<T>()。
public interface ISingletonContent { }
```

加载期校验（合并后强校验内，全量、非 `#if DEBUG`、带类型名定位）：某 `ISingletonContent` 类型条目数 `!= 1` → `PushError` + 抛（带类型名与实际条数）；某 `ISingletonContent` 条目 `ContentEnabled == false` → `PushError` + 抛。

**这不是新增一条校验，而是把一条已存在的手写校验一般化。** `systems/game-progression.md` 的图校验表里已有「`LocationMapData` 存在多份 / 零份 → `PushError`」这一行；标记接口让它对全部单例类型自动成立，那一行随之改为回链——逐份手写的形态里，漏写一份就是一个静默的洞。

overlay 侧已被合并期闸 A 兜住（overlay 新增的 `Id` 其宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` }），故 overlay 不可能把一份单例变成两份；条数校验主要防的是 `res://` 基线的编写错误。

### 6. 单例归入「结构性查表类恒启用」，`AllEnabled()` 对它没有意义

`content-service.md` 的既有判据——**有一类内容不是抽取池的成员，而是被查表读取的结构，对它们「放量开关无处安放」：关掉一条不会让它不再被抽到，只会在结构上造出空洞**——逐字适用于单例平衡资源。关掉 `CombatRulesData`，战斗就没有起手手牌数、抽牌数与手牌上限，这不是「少一个候选」而是规则层缺了一块。

推论三条，全部是既有语义的直接套用：`ContentEnabled` 字段照带但无语义，`false` → 加载期 `PushError`；flags 第三层对单例不生效（flags 只作用于 `AllEnabled()` 取池，而单例不经取池）；`Single<T>()` 内部走全量口径。

**否决「给单例仓储砍掉 `AllEnabled()`」**：那要求单例走一个形状不同的仓储接口，直接打破「对外是同一形状」这条既定条款，换来的只是挡住一个本就没人会写的无害调用。用类型约束把正确路径变成最短路径已经够了。

### 7. 切成几份：三问判据，不设兜底大表

| 问 | 分开的信号 |
|---|---|
| ① **消费者是谁**（哪个 service / manager 读它） | 消费者不同 ⇒ 倾向分开 |
| ② **覆写纪律是什么**（可被 `EncounterSpec` 一类可空覆写 / 不接受任何覆盖参数） | 纪律相反 ⇒ **必须**分开 |
| ③ **有没有跨字段不变式** | 有（如带宽 == 权重数组长度）⇒ **必须**同住一份 |

**不设 `GlobalBalanceData` 兜底大表。** 兜底表会成为默认倾倒处，随后「哪些字段可被 `EncounterSpec` 一类覆写」退化为逐字段记忆——正是 `EnemyLevelingData` 不并入 `CombatRulesData` 的同一条否决理由。代价如实记下：短期内会出现若干份字段很少的小资源，且每份都要各自命名。

当前可点名的单例平衡资源只有两份（`CombatRulesData` · `EnemyLevelingData`）。`balance.md` 中其余尚未定名的旋钮不在本次切分范围内——切分要逐条回答「消费者是谁」，属各自专场的事；判据先立，切分随各旋钮的消费者明确时逐份做。

### 8. 准入边界：消费点早于 `LoadAll()` 的旋钮不能住注册表

**一份平衡资源可以进 ContentRegistry，当且仅当它的全部消费点晚于 `LoadAll()`。**

现成的违反候选：overlay 下载重试次数 / 退避，消费点是 `ContentUpdateManager.CheckAndUpdateAsync`，跑在 `LoadAll()` 之前——那时 ContentRegistry 还不存在。把它做成注册表里的一份平衡资源即自指：要读它必须先合并 overlay，而要合并 overlay 必须先读它。**处置：写死为代码常量，并在 `balance.md` 那张表上如实标注「不可线上调（消费点早于 `LoadAll()`）」**——这三个数是稳态运维值，调它的收益远低于为它开一条平行配置通道的代价；如实标注比让它假装是可调平衡值更好。

其余管线旋钮（flags 拉取退避三项、push 防抖 / 断线缓冲 / push 退避、剧本预取深度、全部玩法平衡值）消费点均晚于 `LoadAll()`，可进注册表。

### 9. 两处措辞澄清

- **`content/_index.md`：不建 `content/` 类型 ≠ 不进 ContentRegistry。** 「平衡数值归 `systems/balance.md`，不是条目」裁定的是「不为平衡数值单开一个 `content/<类型>/` 文件夹与类型档案」；按字面读会被误解成「平衡数值不是内容 ⇒ 不进 ContentRegistry」，而那与「平衡表属本地内容层」正面矛盾。补一句澄清堵掉误读，不松动任何决定。
- **`content-service.md`「是否被存档引用」表：** 平衡表列在「被存档引用」一栏是结论正确、理由标签不准（存档里没有任何平衡表 `Id`）。该栏的实际作用是决定 overlay 权限，故加一条脚注写明本栏的判据是「必须只改不增」。风险很轻但真实：按字面去找「存档哪里引用了平衡表」找不到，可能反推「那它是不是该归可新增 `Id` 的一类」，而平衡表绝不可由 overlay 新增。

### 排期与影响面

- `ISingletonContent` + `Single<T>()` 是 `IContentRepository<T>` / 注册表面的**纯加法**改造，与已排期的 `DrawPool<T>` · `LocalizedText` 属同一次改动面，宜同批落在第二阶段（内容）开工前、第一份 `.tres` 之前。窗口关闭后，改动会从「纯加法」退化为「改全部调用方」。
- **无存档影响、不 bump schema**：单例平衡资源不进存档，`ISingletonContent` 是代码侧标记、不进 `.tres`、不走 overlay。
- 本方案不改任何数值、不改任何机制。

## Clarifications（interview 产物）

来自 2026-08-22 批量评审（`/batch-provide-solution-draft` → `/batch-analyze-new-ideas` 合并 interview）：

- **是否设一份 `GlobalBalanceData` 兜底大表？** → **不设，按三问判据逐份切。****正式拍板**（第 1 轮阻断题，因它阻塞本批另外三道题）。这推翻了草稿里「兜底表能少若干个文件」那条备选的可行性论证。
- **单例 `Id` 形态？** → 两段式 `<类型>.default` `[采纳推荐 — 待复核]`（备选：单段式 `combat_rules`）。
- **单例身份怎么声明？** → 标记接口 `ISingletonContent` + `Single<T>()` 的编译期约束 `[采纳推荐 — 待复核]`（备选：注册时 `RegisterSingleton<T>()`，加载期校验相同但拿不到编译期约束）。
- **消费点早于 `LoadAll()` 的旋钮怎么落？** → 写死为代码常量 + 在 `balance.md` 如实标注「不可线上调」 `[采纳推荐 — 待复核]`（备选：随包 `res://` 直读小资源 / 由后端 manifest 携带）。
- **两处措辞张力（`content/_index.md` 的字面冲突、「是否被存档引用」表的标签不准）** → 均按「补一句澄清 / 加一条脚注」办，不松动任何既定决策 `[采纳推荐 — 待复核]`。

## 未落笔的承接项

本 handoff 的意图有两处尚未折进主题文档，须另行落笔：

- **`systems/balance.md`：** ① `CombatRulesData` 与赋级带条目各补一句「注册形态见 `content-service.md`」；② 新增「平衡资源的切分三问判据」与「不设兜底大表」；③「同步 / 内容管线旋钮」表标注 overlay 下载重试 / 退避那一行**不进注册表、写死为常量、不可线上调**。
- **`systems/game-progression.md`：** 图校验表里「`LocationMapData` 存在多份 / 零份 → `PushError`」那一行改为回链到 `content-service.md` 的通用单例条数校验（净减一条手写校验）；`LocationMapData` 的类定义加上 `ISingletonContent`。

## Open questions

- 上述四项 `[采纳推荐 — 待复核]`（两段式 `Id` · 标记接口 · 早于 `LoadAll()` 的旋钮写死为常量 · 两处措辞澄清）仍留在待答清单待用户复核。
- **完整的单例平衡资源清单**依赖 `balance.md` 中各散落旋钮的消费者定名（多数归 ch1 数值标杆专场与各系统专场）。本次只立三问判据与两份已定名资源，清单本身不在范围内。
