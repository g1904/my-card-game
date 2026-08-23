---
type: solution-draft
date: 2026-08-22
question: 是否为「购买次数」设一个 `StatKey` 成员？若设，成员名、语义边界与采集点各是什么？
source: open-questions/03-adventure-event-types.md → 「是否为「购买次数」设一个 `StatKey` 成员（08-17d 登记 · 本次归集 · 轻）」（同名条目亦在 systems/adventure-event/exchange/_index.md#待决问题）
targets: systems/adventure-event/exchange/_index.md（移出该条待决项 + 记下「不设」的结论与依据）
# 2026-08-22 裁定「不设」后，原列的四处「仅当采纳『设』」落点（profile-service.md / player-profile/_index.md / architecture.md / ux/screen-flow.md）均不成立，已移除——写入面只剩上面一处。
status: distilled
distilled-to: handoffs/2026-08-22-purchase-count-statkey.md
reviewed: 2026-08-22 —— 采纳 A · **不设**「购买次数」`StatKey` 成员（代价：账号级累计购买数永久不可回溯）；取向 2、3 为条件项，随此裁决消解。
---

# 方案草稿 — 是否为「购买次数」设一个 `StatKey` 成员

## 问题

Exchange 收口时（08-17d）留下一条轻量待答：**要不要给「购买次数」一个 `StatKey` 成员**。

它悬着的原因不是难，而是**没人提出过消费方**。条目自己写明「不统计则零依赖」；而若统计，则连带两件事：`StatKey` 增一个成员（**成员名即存档 / 上行契约，一经写入线上存档即永久冻结**），以及定一个采集点（交易逐笔即时提交 ⇒ 采集点天然落在每笔交易的那一次 `TryApply` 上）。

它卡住的不是任何系统——`profile-service` / `exchange` 两侧都能在不设它的前提下定稿。它卡住的是**一个不可逆的时间窗口**：账号级累计计数**无法事后追溯重建**（唯一的逐笔痕迹 `pastEvent` 随轮回清理），所以「日后需要时再加」意味着历史数据永久归零。这是本问题唯一的真实张力。

## 约束（来自既有设计）

1. **分层判据（通则 · 承重）。** `systems/player-profile/_index.md`「账号级字段分两层」：**这个数会被任何判定 / 闸门 / 幂等键读取吗？** 会 → 规则字段层（`CostKey` / `Elements`）；只被 UI 读来看 → 统计计数层（`StatKey` / `Stats`）。**「展示不改变分层」**：被 UI 读到不会把规则字段变成统计计数。
2. **依赖方向单向（承重）。** 规则字段层可被统计 / UI 读；**统计计数层绝不可被任何规则读取**。
3. **词缀硬约定（可机械检查）。** `StatKey` 成员**必须**带 `Total` 前缀**或** `Count` 后缀；**禁用** `Ordinal` / `Used` 后缀。`StatKey` 成员名 = `PlayerStatistics` 字段名**逐字相同**，由一条 `#if DEBUG` 启动期双向覆盖断言兜住。
4. **新增一个统计项恰好三步**（`systems/player-profile/_index.md`）：① `PlayerStatistics` 加一个只读字段 → ② `StatKey` 加同名成员 → ③ 无需迁移（老档缺字段 → 0）。**后端零配合**（宽松同步口径第 5 条：后端不复算不校验、不得用统计驱动任何发放）。
5. **首批清单的价值在于「小而无歧义」**（`systems/player-profile/_index.md`）：统计层新增成本近乎为零，正因如此，**清单的取舍不能以「便宜」为理由**。既有裁决据此**否决过两项**：`TotalChaptersCompleted`（与 `FinaleWinOrdinal` 恒等 = 第二真值）、**「篇章重试的账号级累计」**（`log-ability-deprivation-and-player-statistics.md` 明写「⚠ 推翻 08-06b『首项 = 篇章重试累计』」，并**代价明写**：「你在炼气段重开了多少次」目前没有字段回答，**需要时纯加法补**）。
6. **成员名是契约。** `StatKey` 经 `StatDelta` 落进 `ProfileChangeSpec`，而 `ProfileChangeSpec` 是 `PastEventEntry.AppliedChange` 的类型 ⇒ **它落存档**；按 `sync-service.md` 的通则「枚举值序列化与 C# 枚举名逐字相同」⇒ **改名即破坏性契约变更**。当前无线上存档，窗口开着。
7. **`Stats` 列的标的只有 `PlayerStatistics`（账号级）。** `systems/services/profile-service.md`：`PlayerStatistics` 字段全部只读，**唯一写入路径是 `Stats` 列表经 `TryApply`**。**`CharacterProfile` 侧不存在任何统计容器** ⇒ **`StatKey` 在结构上就只能是账号级的**，不存在「轮回级购买次数」这一选项。
8. **轮回内的购买笔数已经可推导。** `systems/adventure-event/exchange/_index.md`「社交型产出触发 AdventurePlot 分支」表已明写：**PlotManager 读 `pastEvent`：`AppliedChange` 里有 `Op == Grant` 且 `Source == ExchangePurchase` 的 element**。这条路径今天就已存在并被使用。
9. **买卖两向已在 `Source` 上分立。** `Source.ExchangePurchase` / `Source.ExchangeSell` 分立的既定理由**逐字提到本问题**：「复用会让『购买次数』这类统计永远算不准」（`exchange/_index.md`）。⇒ 若统计，口径边界已由既有枚举免费给出。
10. **成就采集面仍是未答项。** `systems/player-profile/achievement/_index.md`「AchievementManager 的触发采集面未定」。本草稿**不臆造**它的形态。

## 建议方案

### 一、层归属：无歧义 —— 若要设，只能是 `StatKey`（不是 `CostKey`）

`[既有推演]` 把约束 1 的判据套上去，逐一核对当前设计里所有可能的规则消费点：

| 可能的规则消费点 | 它实际读什么 | 是否读「购买次数」 |
|---|---|---|
| 定价 | `systems/balance.md` 的「商品族 × 稀有度」表 + `PriceOffset` + 两条折扣通道 | 否 |
| 刷新价 | `RerollBaseCost + RerollCostStep × RerolledCount`；`RerolledCount` 落 `activeEvent`（**事件级**，规则字段层） | 否 |
| 残卷掷骰 | `PlayerPowerFragment.Accumulated` / `FinaleWinOrdinal` / `x`（法则计数） | 否 |
| 礼包兑现 | `BundleGrantOrdinal` / `BundleRedeemedOrdinal` | 否 |
| 剧本推进 | `PlotCondition` + `pastEvent` 的 `AppliedChange` 扫描（约束 8） | 否 |
| 成就发放 | 未定（约束 10）——但**发放是规则**，故按约束 2 它**恒不得读统计层** | 结构上不可 |

⇒ **零规则消费点，且最后一行是结构性的**：即便日后出现一条「累计购买 N 件」的成就，它**也不能**读这个成员——`AchievementManager` 必须有自己的进度模型（约束 2 是承重纪律，不是习惯）。**「为成就预留」因此不构成设它的理由**，这消掉了唯一可能的规则侧动机。

**推论：本问题不是「哪一层」，而纯粹是「设不设」。** 层已由判据判死在统计侧。

### 二、结论建议：**不设**（推荐项 A）

`[既有推演]` 把约束 5 的判据（首批清单以「小而无歧义」为价值，不以「便宜」为理由）套上「购买次数」，逐条核对：

- **无展示落点。** `ux/screen-flow.md` 已定的统计区只列两个数（渡劫成功次数 / 总通关数，且带「措辞不得暗示二者应当一致」的呈现纪律）。**没有任何已定的界面要求呈现购买次数**——`TotalCyclesCompleted` 之所以进首批，正是因为它有一个确定的展示位（玩家档案 / 元婴通关证书统计区）。
- **无规则消费点**（见 §一）。
- **轮回级的那一半已经可推导**（约束 8）：数 `pastEvent` 里 `Source == ExchangePurchase` 的 `Grant` element 即得「本轮回买了几件」。落一个字段去装它 = 第二份真值，正是既有裁决否决 `TotalChaptersCompleted` 时用的那条单一真值纪律。
- **有一条完全同形的先例已被裁决过。** 「篇章重试的账号级累计」在各方面与本项同形：账号级、纯读数、成本近零、不可事后重建、当时也没有展示落点。它**被明确否决并留下「需要时纯加法补」**。为「购买次数」破例，就得说清它凭什么比篇章重试更值得进首批——**当前没有任何依据能说清这一点**。

⇒ **建议：不设。** 在 `exchange/_index.md` 与 `profile-service.md` 侧把这条待决项移出，改记一句结论 + 代价，而不是留白。

**代价明写（这一条必须落进文档，不能只留在草稿里）：**

> **「你这个账号一共买过多少件东西」目前没有字段回答，且事后无法追溯重建**——唯一的逐笔痕迹 `pastEvent` 是 `CharacterProfile` 上的轮回级字段，随轮回清理。日后若要它，只能**从加上成员的那一刻起计数，历史永久归零**。补的成本是三步（`PlayerStatistics` 一个只读字段 → `StatKey` 一个同名成员 → 零迁移）+ 一个采集点（每笔购买的即时 `TryApply` 上多挂一条 `StatDelta`），且**成员名一经随线上存档写出即永久冻结、不可改名、不可复用**。

### 三、若用户裁定「设」：完整可落地形态（备用分支，不是推荐）

`[既有推演]` 三步全部由既有约定机械导出，无一处需要新裁决：

**① 字段与成员名。** `TotalItemsPurchased`。
- 合规核对：带 `Total` 前缀 ✅ · 无 `Ordinal` / `Used` 后缀 ✅ · 与 `CostKey` 的成员名空间在构造上不相交 ✅ · `StatKey` 成员名 = `PlayerStatistics` 字段名逐字 ✅（双向覆盖断言自动覆盖）。
- 取 `Items` 而非 `Purchases`：**一个 `ExchangeOffer` 买完即售罄、一笔交易恰一件商品**（`exchange/_index.md`），故笔数 ≡ 件数；用 `Items` 让这层等价在名字上显形，避免日后若出现「一次买多件」时名字与语义分岔。

```csharp
public sealed class PlayerStatistics
{
    public int TotalCyclesCompleted { get; }
    public int TotalCyclesDefeated  { get; }
    public int TotalItemsPurchased  { get; }   // 账号级累计购买件数（Exchange 买入侧）
}

public enum StatKey { TotalCyclesCompleted, TotalCyclesDefeated, TotalItemsPurchased }
```

**② 语义边界（三条，全部由既有枚举免费给出，不新增判据）：**

| 计入 | 不计入 | 依据 |
|---|---|---|
| `Source == ExchangePurchase` 的每一条 `Grant` / 产出 element，一条 +1 | **售出**（`Source == ExchangeSell`） | 两者分立的既定理由逐字点名本统计（约束 9） |
| —— | **刷新**（`-jade` 但无产出 element） | 刷新不是购买；它扣的是同一种资源，但组装路径不同 |
| —— | 事件产出 / 战利品 / 残卷 / 礼包 / 成就奖励 | 各自有自己的 `Source`，`Source` 的粒度轴就是渠道 / 组装路径 |

**③ 采集点。** 落在**每一笔交易那一次即时 `TryApply`** 上——与 `-jade` 和产出 element **同批、同事务**，与既有的「统计与规则字段同批同事务」逐字一致：

```
TryApply( Elements[ChangeElement(Jade, -ListPrice, Add)]
        + <该商品族的产出 element>
        + Stats[StatDelta(TotalItemsPurchased, +1)] )
```

- **不新增存档点、不新增决策点、不新增 push 通道**——搭在一次已经存在的提交上（与图鉴六行同款）。
- **不由 `ProfileManager` 看到 `Source == ExchangePurchase` 就自动派生 `StatDelta`。** 与 `CodexElements` 的同款裁决逐字同构：自动派生会让 `AppliedChange` 记的账与组装方提交的 spec 不一致，违反「提交的是已算好的整块，本 manager 不做合并 / 增量」。**改用显式组装**；若要兜底，用 `#if DEBUG` 断言（一批变更里有 `Source == ExchangePurchase` 的 element 而同批无对应 `StatDelta` → `PushWarning`，纪律阶梯第 3 级）。
- **`AppliedChange` 照常含 `Stats`**（被剔除的只有 `EventStateChanges` 这类整块快照与 `TraceElements`），体积增量为每笔一个 `(Key, Delta)`，可忽略。
- 宽松口径原样适用：未知 `StatKey` → `PushWarning` + 跳过；恒不走 modifier pipeline；读档越界钳制到 0 且不由历史重建；上行被拒即丢弃不补偿重放；后端不复算不校验。

**④ 展示落点必须同批定下。** 若设而不展示，它就是一个无消费方的字段——**统计层字段的唯一合法消费方就是 UI**。落点建议为 `ux/screen-flow.md` 已有的「玩家档案 / 元婴通关证书统计区」再加一行，与既有两行同处。**这一条是「设」这个选项的组成部分，不能留到以后**。

## 具体形态（可 derive 的落地面）

**若采纳 A（不设）——零代码面。** 文档改动仅三处措辞：

| 文档 | 改动 |
|---|---|
| `systems/adventure-event/exchange/_index.md` | 「待决问题」移出该条；「意图」内记一句结论 + §二的代价明写段 |
| `systems/services/profile-service.md` | 无结构改动；可在统计计数一段末补一句「购买次数不设成员，理由与代价见 `exchange/_index.md`」 |
| `open-questions/03-adventure-event-types.md` | 移出该条（由 `/analyze-new-ideas` 执行） |

**若采纳 B（设）——落地面见 §三**，涉及 `systems/architecture.md`（枚举 +1）· `systems/player-profile/_index.md`（字段 +1、首批清单措辞由「首批就这两项」改为三项）· `systems/services/profile-service.md`（采集点一句）· `systems/adventure-event/exchange/_index.md`（一笔交易的 spec 形状多一列）· `ux/screen-flow.md`（统计区 +1 行）。**存档 schema 无需 bump**（统计层老档缺字段 → 0，宽松同步口径；这是既有的三步之三）。

## 后果

- **采纳 A：** 零系统影响、零存档影响、零后端影响。唯一后果是 §二明写的那条不可逆代价（账号级累计购买数永久无法回溯）。`exchange` 与 `profile-service` 两份文档各减一条待决项。
- **采纳 B：** 五份文档小改（见上表），无存档迁移、无后端配合、无新存档点。长期后果是**成员名进入存档 / 上行契约并永久冻结**；另需接受一条纪律负担——`Stats` 列从此会出现在事件内的即时提交里（此前只出现在轮回收口那一次），**这不违反任何既有纪律**（写入时机那条只说了首批两项落在收口，没有说 `Stats` 只能落在收口），但它是首个反例，落笔时应显式写明以免后来者误读。

## 备选方案（已考虑并否决）

- **设成 `CostKey`（规则字段层）。** 否决：零规则消费点，且成就一路被约束 2 结构性封死（见 §一）。判据不给它规则层的位置。
- **落一个轮回级的购买计数（挂 `CharacterProfile.Status` 或新建轮回级统计容器）。** 否决三条：① `Stats` 列的标的只有 `PlayerStatistics`，轮回级要新建一个容器 + 一条写入通道 + 一列 spec，**与条目自称的「轻」正面矛盾**；② 该数已可从 `pastEvent` 的 `AppliedChange` 推导且**这条路径今天就在被 PlotManager 使用**，落字段即第二真值；③ 轮回级数据随轮回清理，做统计的意义本就存疑。
- **由 `ProfileManager` 看到 `ExchangePurchase` 自动派生 `StatDelta`（零遗漏）。** 否决：与 `CodexElements` 的既有裁决逐字同构——自动派生使 `AppliedChange` 与提交的 spec 不一致。
- **合并买卖两向为一个「交易次数」。** 否决：`Source` 分立的既定理由逐字点名「复用会让『购买次数』这类统计永远算不准」；合并即把那条裁决从后门放回来。
- **现在只加 `PlayerStatistics` 字段、暂不加 `StatKey` 成员（先占位）。** 否决：违反「新增一个统计项恰好三步」的原子性，且启动期双向覆盖断言会**立即失败**（每个字段须有同名成员）——这条断言正是为拦下这种半套状态而存在的。
- **靠后端聚合回答「买了多少」而不落客户端字段。** 否决：宽松同步口径第 5 条明写「后端不复算不校验，且**不得用统计驱动任何发放**」，而 push 信封上行的是 profile diff——客户端不采集，后端就无从聚合。它不是一条可用的替代通道。（`DefeatReason` 分布归后端聚合那一条能成立，是因为 `DefeatReason` 本身随轮回收口进了痕迹 / 报文；购买笔数没有等价通道。）

## 与既有决策的张力

**无冲突，但有一处需要用户知情的紧张关系：**

「成本近零」与「不该加」在本问题上指向相反方向，而**既有设计已经明确站在后者**（`systems/player-profile/_index.md`：「统计层新增字段的成本近乎为零……**故首批清单的价值在于小而无歧义**」）。这条措辞把「便宜」直接判为**不构成加入理由**。本草稿的推荐项 A 就是原样执行它。

**唯一削弱它的事实**：篇章重试那条先例被否时，代价是「一个问题暂时答不出」；本问题的代价是「**一段历史永久不可重建**」——因为账号级累计只能从采集之日起算。这个差别真实存在，但**它同样适用于篇章重试累计**（那个数也不可回溯），而既有裁决在明知这一点的情况下仍选择了不设。**故本草稿判定：这不是推翻先例的新信息，而是同一代价的再一次出现。** 若用户认为这一代价这次不可接受，那应当**同时重估篇章重试累计那一项**（两者同形，只留一个会让首批清单从「有判据」退回「凭偏好」）——这一点列入「仍需用户决定」。

→ 已裁决（2026-08-22 · 批量评审）：用户选 A（不设），**该代价被接受**，先例保持一致——篇章重试累计与购买次数两项同形同处置，首批清单仍为「小而无歧义」的两项。

## 前置依赖

- **`AchievementManager` 的触发采集面**（`systems/player-profile/achievement/_index.md#待决问题`）——**不阻塞本问题**。约束 2（统计层绝不可被规则读）已经结构性地保证：无论成就采集面最终定成 EventBus 被动订阅还是各服务主动上报，它**都不会读这个 `StatKey`**。此处列出只为说明「等成就定了再决定」不是一条有效的等待理由。
- **`ux/screen-flow.md` 的玩家档案统计区最终形态**——**仅当采纳 B 时阻塞**：`TotalItemsPurchased` 的展示位必须与它同批定下，否则会落成一个无消费方的统计字段（见 §三④）。采纳 A 则无依赖。
- 与本分片相邻的两条 Exchange 待决项（定价表取值 · 满袋时能否购买）**与本问题彼此独立**，任一先答不改变本问题的判据。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> - **（1）** 设不设「购买次数」`StatKey` 成员 → **A · 不设**。正式拍板（第 3 轮单独问）。代价（账号级累计购买数事后不可重建、日后补只能从那天起计数）已明写并被接受。
> - **（2）** 是否同批补回「篇章重试的账号级累计」→ **随（1）裁决消解，无需回答**（仅当选 B / C 时才需答）。
> - **（3）** 成员名确认 → **随（1）裁决消解，无需回答**（仅当选 B / C 时才需答）。

**（1）设不设「购买次数」这个 `StatKey` 成员。**

| 选项 | 后果 |
|---|---|
| **A · 不设（推荐）** | 零改动、零存档影响。**代价：账号级累计购买数从此永久不可回溯**——日后要它只能从那天起计数，历史归零。判据侧最干净：与已被否决的「篇章重试累计」同形同处置，首批清单保持「小而无歧义」。 |
| **B · 现在就设** `TotalItemsPurchased` | 五份文档小改、零迁移、零后端配合，历史从第一天起完整。**代价：** ① 首批清单出现一个**当前无展示落点、无消费方**的字段（除非同批定下展示位）；② 成员名随第一份线上存档永久冻结；③ 它使「便宜就加」成为一个可被后来者援引的先例，而既有措辞正是为封死这一点写的。 |
| **C · 设，但同批把展示位一并定下** | = B + 在 `ux/screen-flow.md` 的玩家档案 / 元婴通关证书统计区补一行。**这是 B 唯一自洽的形态**（统计层字段的唯一合法消费方是 UI）；代价是要顺带裁决一处 UX 呈现，超出本条「轻」的范围。 |

**推荐 A**，理由：判据（§二四条）四条全部指向不设，且本库对完全同形的一项已经作出过同样裁决并接受了同款代价；没有任何新信息能说清购买次数为何比篇章重试更值得进首批。**若倾向要历史数据，请选 C 而非 B**——B 会留下一个无消费方的字段。

→ 已裁决（2026-08-22 · 批量评审）：**A · 不设** —— 不为「购买次数」新增 `StatKey` 成员。§二的代价明写段须原样落进 `exchange/_index.md`：账号级累计购买数**事后不可追溯重建**，日后要它只能从加上成员那一刻起计数、历史归零。

**（2）仅当选 B / C 时：是否同批把「篇章重试的账号级累计」也一并补回？**

两者同形（账号级 · 纯读数 · 成本近零 · 不可回溯）。若为购买次数破例而不动篇章重试，首批清单的取舍将不再有可陈述的判据。

- **推荐：一并补回**（若选 B / C）。理由：判据的价值在于一致；两条同形项给出相反结论，等于宣告清单是凭偏好排的。
- 反向选择（只补购买次数）也可接受，但需要用户给出一条能写进文档的区分理由，否则后来者无从遵循。

→ 随项（1）裁决消解，无需回答（本项仅在选 B / C 时成立；已选 A）。「篇章重试的账号级累计」维持既有的「不设」裁决不变。

**（3）仅当选 B / C 时：成员名确认。**

建议 `TotalItemsPurchased`（词缀合规、与「一 offer 一件」的既定形态对齐）。备选 `TotalPurchaseCount`（同样合规，但 `Total` + `Count` 双词缀在既有两项上无先例）。**一经随线上存档写出即永久冻结**，故此刻确认比日后改名便宜得多。

→ 随项（1）裁决消解，无需回答（本项仅在选 B / C 时成立；已选 A，不新增成员，故无名可定）。
