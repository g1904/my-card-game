---
type: solution-draft
date: 2026-08-27
question: `OutcomeRule.DeckOperation` 走池抽时「该 `Op` 对应的池」全库无定义；以及卡牌效果重洗（把牌送回抽牌堆）是否开口、以何形态开
source: open-questions/03-adventure-event-types.md → `AddLooseCard` 走池抽时「该 `Op` 对应的池」未定义（08-25）· open-questions/01-combat.md → 卡牌效果重洗牌库是否开口、以何形态开（08-26）
targets: systems/adventure-event/common-properties.md · systems/character-profile/deck/_index.md · systems/services/combat-service.md · systems/balance.md · decisions/ADR-0052-no-reshuffle-fatigue.md（后果一节）
status: distilled
reviewed: 2026-08-27 — 用户逐条评审并裁决；提炼时另经一场合并 interview（8 问）补齐三条真冲突与两处跨草稿矛盾
distilled-to: handoffs/2026-08-27-card-pool-and-reshuffle.md
---

# 方案草稿 — 事件产出的卡牌取池链 · 与「牌送回抽牌堆」是否开口

两个子问题各自独立成节。它们被放在同一份草稿里，只因写入面同落 `deck/_index.md` 与 `systems/services/combat-service.md`；**采纳与否可以分开裁决**。

---

## 问题

### ① `OutcomeRule.DeckOperation` 的「该 `Op` 对应的池」无定义

`systems/adventure-event/common-properties.md` 的 `OutcomeRule` 写着：

```csharp
// Kind == DeckOperation
[Export] public DeckChangeOp      DeckOp;        // element 层五值
[Export] public string            TargetId;      // 定值条目；空 = 从该 Op 对应的池抽
```

「该 `Op` 对应的池」在全库**没有任何一处定义**：没有取池链、没有 `CardPoolId` 一类字段、没有过滤器、没有子流指派、没有短缺处置。同时 `DeckChangeOp` 是五值（`LearnTechnique` / `UpgradeTechnique` / `ForgetTechnique` / `AddLooseCard` / `RemoveLooseCard`），其中三个 `Op` 的「池」在语义上根本不指向内容仓储：

- `UpgradeTechnique` 的 `Tier` 写的是**目标层数**，一次抽取给不出「抽哪门 + 抽到第几层」这两个量；
- `ForgetTechnique` / `RemoveLooseCard` 的「池」只能是**玩家当前卡组**——那是运行期状态，不是内容池，且卡组可以被弃空（`deck/_index.md`「退化情形明写」），一条注定可能落空的规则。

而唯一有真实内容需求的 `AddLooseCard`，其「通用卡牌池」写法又与**业障是负向奖励**这件事直接矛盾——从全体 `CardData` 里抽一张塞进卡组，抽到的多半是正向牌，负向奖励当场变成正向奖励。

**卡住了什么：** `OutcomeRule` 是全部五类 AdventureEvent 的产出载体（`GenericEventResolver` 的物化输入）。校验表第 5 条只覆盖 `TargetId` **非空**的路径，为空这一路既无校验也无实现语义 ⇒ 内容作者只要留空这一格，加载期照过、运行期无从物化。

### ② 卡牌效果把牌送回抽牌堆，是否开口

全库从未提出或裁决这件事，它只是被两条**全称推论**顺带排除：

- `systems/services/combat-service.md` 推论 ④：「**`DeckModule` 没有重洗代码路径**」；
- `systems/character-profile/deck/_index.md`：「**抽牌堆的 `Id` 序列在一场战斗内只减不增**」。

而同一份 `deck/_index.md` 的推论 ② 写的却是「卡牌只在区之间流转（**卡组 ⇄ 手牌 ⇄ 弃牌堆 ⇄ 战场 ⇄ 栈**），总量不增不减」——**双向箭头与「只减不增」互相矛盾**，两句都在同一篇文档里。

**卡住了什么：** `EffectData` 的原子操作清单里已有 `MoveCard`（「闭集内的流转，不新造牌」），而抽牌堆本就是闭集的六个位置之一。也就是说「把一张牌放回抽牌堆」在**结构上已经可写**，挡住它的只有上面两句措辞。内容作者要不要有这条设计面、以及写下去会不会踩 `ADR-0052`，目前没有答案。

---

## 约束（来自既有设计）

两个子问题共同吃到的硬约束：

- **`ADR-0068`：抽取原语只有两级，不设第三级。** 第一级 `DrawPool<T>`（住 content-service，唯一的抽取发起面）· 第二级 `GrantPoolPicker`（住 profile-service，能力授予的唯一取池处）。**分界判据 = 这道过滤需不需要读 `Profile`。**
- **`data-resource-rules.md` + `content-service.md`：从内容集合抽取一律经 `AllEnabled()`**；仓储上没有中性名 `All()`。反建索引一类**结构性**输入取 `AllIncludingDisabled()`。
- **`ADR-0091` / `deck/_index.md`「卡池划分」：** 玩家侧取池一律叠一层 `Pool != Enemy`（卡牌层与功法层各一遍）。
- **`deck/_index.md`「成员卡不进散牌产出侧」：** 凡被任一功法引用的卡一律从散牌产出侧排除，反建索引取 `AllIncludingDisabled()`，**不新增字段**。
- **`OutcomeRule` 自带的形态纪律：** 「照抄 `ExchangeStockRule` / `ResearchSlotSpec` 已有的『规则 → 物化展开』范式，**不发明第三种**」。
- **两级 seeded RNG：** 子流清单是 SeedManager 内的常量（`map` / `combat` / `shop` / `reward`），凡消耗子流随机的提交须在同一次原子写内更新 `State` / `DrawCount`（载体 `ProfileChangeSpec.RngElements`）。
- **`ADR-0052`：** 抽牌堆不重洗、抽空即疲劳；卡组规模两侧不设硬限，其代价由疲劳承接。**否决过「重洗弃牌堆」**（理由：疲劳永不可达，对局无终止压力）。
- **`ADR-0088`（`ADR-0052` 的后续）：** 疲劳是**完全一等的栈条目**，**可被监听 / 响应 / 取消**；「可被取消不会让对局不终止：`EncounterSpec.TurnLimit`（8 / 10 / 12）是硬护栏」。
- **`combat-service.md` 推论 ④ 自带的前瞻注记：** 「**内容侧的触发条件（写下来，好让日后有人知道要回来改哪一句）：** 若出现『把一张牌随机洗回抽牌堆 / 随机置入抽牌堆第 N 张』这类关键字，抽牌堆就重新成为战斗中途的随机消耗点。届时**仍不拆分子流**……但本推论与 `deck/_index.md` 的『抽牌堆只减不增』须相应放宽。」

---

## 建议方案

### ①-a 「该 `Op` 对应的池」收窄为**仅 `AddLooseCard` 一个 `Op`**，其余四个 `Op` 的 `TargetId` 必填非空

`[既有推演]`

判据是 `ADR-0068` 的分界判据加一次逐 `Op` 核对：

| `Op` | 池抽是否成立 | 依据 |
|---|---|---|
| `AddLooseCard` | **成立** | 过滤条件全部只读内容（`Pool` / 成员卡索引 / `CardType` / `RarityTier`）⇒ 干净落在**第一级 `DrawPool<CardData>`**，零结构成本 |
| `LearnTechnique` | **建议不开** | 见下方 ①-d |
| `UpgradeTechnique` | **不成立** | `Tier` 是目标层数，一次抽取给不出「抽哪门 + 到第几层」两个量 |
| `ForgetTechnique` | **不成立** | 「池」= 玩家当前卡组（运行期状态，非内容仓储）；且卡组可被弃空 |
| `RemoveLooseCard` | **不成立** | 同上；散牌是多重集，随机移除还要额外定义「同名多张抽哪一张」 |

落地形态 = 一条加载期校验（见「具体形态」校验 5b），一行注释改写。**这条同时把「留空即无从物化」这个静默口子堵死。**

### ①-b `AddLooseCard` 的取池链——逐字沿用商店 `Card` 族那一条，不另写一段

`[既有推演]`

`exchange/common-properties.md` 已经为 `Card` 族写了一条完整取池链，且它明写「**沿用授予池那一条，不另写一段**」。事件产出侧的过滤需求与它**逐条同形**，故建议原样复用：

```
AllEnabled() → CardData 仓储
→ 叠 Pool != Enemy                                   （ADR-0091 / 「卡池划分」）
→ 排除「被任一功法引用的成员卡」                        （反建索引取 AllIncludingDisabled()）
→ CardTypeFilter 过滤（新增一格，见 ①-c）
→ RarityFilter 过滤                                   （与 GrantFromPool 同名同义，空 = 不限）
→ 按 RarityTier 权重表 PickMany(rewardRng, Count)      // 无放回
```

- **子流取 `RngStream.Reward`，不新开第五条。** 与「开局构筑三选一取 `Reward`、不新开子流」逐字同款推理：`Reward` 已承载「候选掷定 + 落存档 + 绝不重抽」这一完全同构的用途，而事件产出与奖励候选**从不并发**（一次只结算一个事件）。
- **抽定与施加落在同一次 `TryApply` 内**（`AdvanceEventAsync` 的固定结算流程 ①→⑤ 是一次原子提交），`Reward` 子流的终态由 `RngElements` 带上。**因此不需要 combat 侧那条「把 `picks` 单独落存档」的额外保护**——那条是为「抽定与领取之间隔着决策点」而设，本路径没有这个窗口。
- **`PickMany` 无放回是既定契约** ⇒ 同一条规则的 `Count` 张互不重复，这条免费成立。

### ①-c 新增一格 `CardTypeFilter`，让「随机业障」写得出来

`[既有推演]` + `[通行做法]`

「业障作为负向奖励从**通用**卡牌池抽讲不通」这条反对**完全成立**——但它反对的是**通用池**，不是「走池抽」。收窄之后语义即刻成立：一条写着 `DeckOp = AddLooseCard` / `CardTypeFilter = [Affliction]` / `Count = 2` 的规则，含义是「随机塞两张业障」，这正是 StS 的 random curse 那一拍，也是本作既定的「业障由事件负向奖励塞进卡组」唯一缺的那半。

- **过滤面落在字段上，不落在 id 前缀上**——与 `CardSubtypeData.AllowedCardTypes` 同一条纪律。
- **取数组不取单值**，与 `RarityFilter` / `AllowedCardTypes` 同形；单值日后要改 schema。
- **不新造「池」内容类型**：见「备选方案」第一条。

### ①-d `LearnTechnique` 不开池抽这一路

`[既有推演]`

两条独立理由，任一条成立即足够：

1. **它绕过一条承重取向。** 玩家侧功法取池共四处（闭关三选一 · 开局构筑三选一 · 商店 `CultivationTechnique` 族 · 战后奖励池），**四处全部是玩家从候选里选**。功法是「一组必须整组入组的卡牌」，是玩家做构筑决策的颗粒度；开这一路会造出第五处、且是唯一「随机塞给你、不给选」的一处，与「构筑的多轮性由 adventureEvent 承载」这条既定方向相反。
2. **它落不进两级原语。** 功法池抽必须**排除已持有**（`deck/_index.md` 与战后奖励侧两处同款口径）⇒ 需读 `Profile` ⇒ 按 `ADR-0068` 落第二级；而第二级 `GrantPoolPicker` 是「**能力授予**的唯一取池处」，功法不是能力族。要么扩它的职责、要么造第三级（`ADR-0068` 明禁）。成本明显高于收益。

**内容侧仍有等价出口**：想给「一门随机功法」，写 `TargetId` 定值的多条 `OutcomeRule` 并由事件模板自己编排分支即可；想给「三选一」，那是 Research 类事件本来就在做的事。

### ②-a 建议**开口**，但形态限定为 `MoveCard` 的目的地扩展，不是新增一条重洗规则

`[取向选择]`（开不开是取向；开的话形态由推演给出）

`ADR-0052` 否决的是「**抽牌堆空时由弃牌堆重洗补充**」这条**规则性、无限次**的机制——它的否决理由逐字是「有重洗则疲劳永不可达，对局无终止压力」。**有限次、消耗性的一次性效果不落在这条理由的射程内**，三条依据：

1. **`ADR-0088` 已经就同一条担忧裁决过一次。** 疲劳是完全一等的栈条目、**可被取消**，「免疫下一次疲劳」这类效果本就写得出来；而 `ADR-0088` 明写「可被取消不会让对局不终止：回合上限是双方合计的硬护栏」。**「把一张牌放回抽牌堆」在对局终止性上是比「取消一条疲劳」更弱的效果**（前者只把疲劳推后一次抽牌，后者直接抹掉一次结算），既然更强的那条已经开了，更弱的这条不构成新风险。
2. **量纲上封死。** `TurnLimit` 上限 12（单侧 6 回合）⇒ 一侧一场最多抽 `4 + 2×6 = 16` 张。**卡组 ≥ 16 张者本就永不疲劳**；疲劳只咬小卡组，而一次性效果回堆 1~2 张只把疲劳推后 1~2 次抽牌，**改不了失血曲线的形状**。
3. **结构上零新增。** `EffectData.MoveCard` 已在原子操作清单里、语义已写死为「闭集内的流转，不新造牌」；抽牌堆是闭集六个位置之一。开口 = **不加原语、不加关键字类别、不加存档字段**（各区 `Id` 序列本就落存档），只放宽两句措辞。

### ②-b 首批只开「置于抽牌堆**顶** / **底**」两个确定性位置，**不开随机位**

`[既有推演]`

`combat-service.md` 推论 ④ 的前瞻注记已经把这条界线画好了：**「随机洗回 / 随机置入第 N 张」才使抽牌堆重新成为战斗中途的随机消耗点。** 顶 / 底是确定性插入，零随机消耗。三条理由：

1. **保住确定性论证。** 「抽牌本身零随机消耗」这条性质被 combat-service 的「两侧牌序互不打乱、无需按侧分流」**直接依赖**；只开顶 / 底，需要改写的从两条推论缩到一条措辞，那条依赖链一个字都不用动。
2. **顶 / 底对玩家是可读、可规划的**（顶 = 我下回合一定抽到它；底 = 这场大概率不再见），随机位是纯运气 —— 与本作「低交互但可规划」的定位相反，且 `combatLog` 要把「洗到第几张」讲清楚会额外挤占那条已经很紧的战报通道。
3. **随机位随时可加，且加法已预写好。** 那条注记已经把处置定好了（仍不拆子流、消耗记在 `combat` 上、`State` 随决策点同批持久化）。现在不开，日后要开也不必重付确定性复核的成本。

### ②-c 载体必须是**消耗性**的，落三条加载期硬校验

`[既有推演]`

这是把 `ADR-0052` 的承重点在新形态下的落点写死——**限制不落在「能不能回堆」上，落在「这条效果能被使用几次」上**：

| 载体 | 判定 | 依据 |
|---|---|---|
| 法术卡（`Sorcery`） | 允许 | 结算后进弃牌堆，一次性天然成立 |
| 古宝 / 道具 | 允许，须带 `Charges` | 「花费 = mana 为主 + 古宝上叠 `Charges`」是既定纪律 |
| 启动式异能 | 允许，须 `MaxActivationsPerCombat != -1` | 配额闸门机制已存在（宣告 + 结算查两次） |
| 触发式异能 | 允许，须 `MaxActivationsPerCombat != -1` | 同上；无配额 = 规则性重洗的等价物 |
| **静止式异能** | **拒绝** | 静止式不入栈、只在求值瞬间被读取，**根本不执行原子操作**——挂 `MoveCard` 本身即缺陷 |

外加一条**批量上界**：`MoveCard(to = DrawPile)` 必须写明有限的 `Count`，**「弃牌堆整堆 / 全部」这一形态不得存在**。这一句就是 `ADR-0052` 被否决的那条方案，不给它换个写法复活。

### ②-d 同批必须重写的三句措辞（承重 —— 不同批改就是留下三处互相矛盾的表述）

`[既有推演]`

**1. `combat-service.md` 推论 ④**

> 现：**推论 ④：`DeckModule` 没有重洗代码路径**，seeded 洗牌只发生在参战方组装时的一次初洗。**抽牌本身因此零随机消耗**，这正是「两侧牌序互不打乱」的来源。

> 建议改为：**推论 ④：`DeckModule` 没有「弃牌堆整堆回流重洗」这条代码路径**，seeded 洗牌只发生在参战方组装时的一次初洗。**卡牌效果可经 `MoveCard` 把有限张牌置于抽牌堆顶 / 底，该路径不掷随机**（随机位入堆未开放）。**抽牌本身因此仍零随机消耗**，「两侧牌序互不打乱」原样成立。

**2. 同处那条前瞻注记**

> 现：「若出现『把一张牌随机洗回抽牌堆 / 随机置入抽牌堆第 N 张』这类关键字……本推论与 `deck/_index.md` 的『抽牌堆只减不增』须相应放宽。」

> 建议改为：**确定性的顶 / 底入堆已开放**（见上）；**随机位入堆仍未开放**——若日后开放，抽牌堆才重新成为战斗中途的随机消耗点，届时**仍不拆分子流**（消耗照常记在 `combat` 上、`State` 照常随决策点同批持久化）。

**3. `deck/_index.md`「抽牌堆的 `Id` 序列在一场战斗内只减不增」**

> 建议改为：**抽牌堆的 `Id` 序列不因规则而增**——没有弃牌堆回流；**卡牌效果可把有限张牌置于其顶 / 底**，这是闭集内的流转，总量仍不增不减。

**并同时收掉措辞不一致：** 同文档推论 ② 写的「卡组 **⇄** 手牌 **⇄** 弃牌堆 **⇄** 战场 **⇄** 栈，总量不增不减」用的是**双向**箭头，它才是对的（闭集流转本就是双向；打出的牌从手牌到栈、结算后到战场或弃牌堆，`MoveCard` 在区间搬运）。**要改的是「只减不增」那一句，不是把 `⇄` 改成 `→`。**

---

## 具体形态（可 derive 的落地面）

### ① `OutcomeRule` 的 `DeckOperation` 分支

```csharp
[GlobalClass] public partial class OutcomeRule : Resource
{
    // …… 前两个 Kind 的字段不动 ……

    // Kind == DeckOperation
    [Export] public DeckChangeOp  DeckOp;          // element 层五值
    [Export] public string        TargetId;        // 定值条目；空 = 走池抽（仅 AddLooseCard 允许）
    [Export] public CardType[]    CardTypeFilter;  // 仅池抽路径有意义；空 = 不限。随机业障写 [Affliction]
    [Export] public RarityTier[]  RarityFilter;    // 空 = 不限（与 GrantFromPool 同名同义）
    [Export] public int           Count = 1;       // 物化时展开为 Count 条 DeckChangeElement
}
```

- **`Count` 在物化组装时展开为 `Count` 条独立 element**，不给 `DeckChangeElement` 加 count 格——与既定的「同名多张 = 提交多条 element，不设 count」一致（一条 element ↔ 一次可重放的操作）。
- 产出的每条 element 形态 = `DeckChangeElement(AddLooseCard, drawnCardId, Tier = -1)`，与商店 `Card` 族购买**逐字同构**。
- **不带 `Source`**，沿用 `DeckElements` 整列的既定形态。

**加载期校验（`PushError` + 条目 `Id`，接在现有 1–9 之后）**

| # | 校验 | 理由 |
|---|---|---|
| 5 | *（保留原样）* `Kind == DeckOperation` 且 `TargetId` 非空时须经 `ContentRegistry` 解析（前三个 `Op` 解析功法、后两个解析卡牌） | — |
| 5b | `Kind == DeckOperation` 且 `TargetId` 为空且 `DeckOp != AddLooseCard` → 拒绝 | 其余四个 `Op` 无可抽之池（见 ①-a 表） |
| 5c | `Kind == DeckOperation` 且 `TargetId` **非空**时，`CardTypeFilter` / `RarityFilter` 须为空且 `Count == 1` → 否则拒绝 | 定值路径不吃过滤器；作者写了过滤器却静默无效是最难查的一类编排错 |
| 5d | `CardTypeFilter` 含 `Item` 或 `Power` → 拒绝 | 道具与 `Power` 不进卡组，抽到即无处可放 |
| 5e | `Kind == DeckOperation` 时 `Count >= 1` → 否则拒绝 | 与 `GrantFromPool` 的校验 4 同款 |
| 5f | 池抽路径的合法池（叠完 `Pool != Enemy` + 成员卡排除 + 两道过滤后）条目数 `< Count` → 拒绝 | 与 Exchange 闸 ① 的「逐 `Kind` 逐 `RarityTier` 档位核算」同一条纪律：把「池实际有多大」在启动期摆到内容作者面前，而不是等到轮回中途开出一条空产出 |

**运行期短缺处置**（与 Exchange 侧逐字同款，不发明第三种）

| 情形 | 语义 | 处置 |
|---|---|---|
| 池抽到 `0 < n < Count` | 可选缺失 | `PushWarning` + want / got；该规则产出 n 条 element，**不补位、不用定值顶替** |
| 池抽到 0 条 | 可选缺失 | 同上；该规则贡献 0 条 element，**同一事件的其余 `OutcomeRule` 照常结算** |

- **不升格为 `PushError`**：闸 5f 已在启动期挡住编排错误，运行期到达此处只可能是 flags 收缩了池（`ContentEnabled` 按账号解析），而事件的其余产出照常成立——按 Exchange 的既定层次这属可选缺失。
- **短缺不给玩家任何提示、不新增文案键**，与 Exchange 同款。

**权重表的落点**：复用**授予池权重表**（分表维度按**用途**，见 `open-questions/01-combat.md`「`RarityTier` 的分布与权重表」），**不新开第三张表**——事件产出与能力授予同属「事件给你的东西」这一用途。表值本身归那条待答项，见「前置依赖」。

### ② `MoveCard` 的目的地扩展

```
MoveCard(from, to, count)
  to ∈ { Hand, DiscardPile, Battlefield, DrawPileTop, DrawPileBottom }   // 新增末两值
```

- **不新增 `EffectData` 之外的任何类型**；`DrawPileTop` / `DrawPileBottom` 是同一个区的两个插入位，**不是两个区**（存档仍只记抽牌堆的一条 `Id` 序列，插入 = 序列头 / 尾插）。
- **不新增存档 schema 一格。**
- **不新增关键字**：若日后要给它一个词，走 `KeywordData` 的 `Action` 档展开为这一条原子操作，不新增第三种效果载体（既定纪律）。

**加载期校验**

| # | 校验 | 处置 |
|---|---|---|
| R1 | 含 `MoveCard(to ∈ {DrawPileTop, DrawPileBottom})` 的 `AbilityData` 为**静止式** | `PushError`（带 `AbilityData.Id`） |
| R2 | 含该操作的**启动式 / 触发式** `AbilityData` 且 `MaxActivationsPerCombat == -1` | `PushError`（带 `AbilityData.Id`） |
| R3 | 该操作的 `count` 未写明有限值（或声明为「全部 / 整堆」形态） | `PushError` |
| R4 | 清单式软检查：一次性列出全部含该操作的效果 `Id` 与其载体 | `PushWarning`（供人工审阅，与「可针对持续状态的效果」清单同构） |

**运行期语义**

- 抽牌堆为空时被放回一张 → 下次抽牌正常抽到、**不触发疲劳**。既有判定顺序（「抽牌堆为空 → 先扣道念」）不变，只是此刻堆非空。
- `from` 侧的牌不存在（已被移走 / 区内为空）→ **fizzle**，走既有的 `FizzledSlots` 通道，不新增失败语义。
- 该操作**照常广播 `CombatFeedEntry`**（结算事件粒度），战报里「这张牌回堆了」有账可查。

---

## 后果

**① 采纳后需改的文档**

- `systems/adventure-event/common-properties.md` —— `OutcomeRule` 字段增两格、`TargetId` 注释改写、校验表增 5b–5f、增一节取池链与短缺处置。
- `systems/character-profile/deck/_index.md` —— `AddLooseCard` 那条补一句「池抽路径见 `adventure-event/common-properties.md`」（**回链，不复述**）。
- `systems/balance.md` —— 授予池权重表的适用面注明覆盖事件产出侧。
- **无存档 schema 变更、无迁移。** 池抽结果落 `AppliedChange`，与定值路径产出的 element 完全同形。

**② 采纳后需改的文档**

- `systems/services/combat-service.md` —— 推论 ④ 与其前瞻注记两处改写（见 ②-d）。
- `systems/character-profile/deck/_index.md` —— 「只减不增」一句改写；`EffectData` 原子操作清单里 `MoveCard` 一条补目的地与载体纪律。
- `decisions/ADR-0052-no-reshuffle-fatigue.md` —— **不改「决策」与「理由」两节**（它否决的规则性重洗依然被否决），只在「后果」一节补一条：有限次消耗性的顶 / 底入堆效果允许存在，护栏落在载体消耗性与 `TurnLimit` 上。
- `systems/balance.md` —— 若首批内容真要出这类牌，`count` 上界作为一格内容侧旋钮登记。
- **无存档 schema 变更、无迁移。**

**跨库：两条都不横跨客户端 ↔ 后端边界。** 取池与战斗结算全在客户端进程内；`ContentEnabled` 的 flags 解析虽然由后端下发，但那条通道已成文，本方案不改它的形状。

---

## 备选方案（已考虑并否决）

**① 具名池 id（`CardPoolId` 字符串 + 一个新的「卡池」内容类型），照 `RewardPoolId` 的样子做**
— 否决：`OutcomeRule` 的注释自己写着「不发明第三种范式」，而 `ExchangeStockRule` / `ResearchSlotSpec` / `GrantFromPool` **三处全部是「仓储 + 过滤器」**范式。`RewardPoolId` 是唯一的具名池，它成立是因为战后奖励池**三类混合**（`CardData` / `ItemData` / `CultivationTechniqueData`）且逐事件编排；`OutcomeRule.DeckOperation` 单族单仓储，具名池只买来一个额外的悬空引用面和一套额外的加载期校验。

**① 裁定 `TargetId` 恒为定值、整条取消走池抽**
— 未否决，作为「仍需用户决定」第 2 条列出（见下）。它简单且当前零内容依赖，代价是「随机业障」这一拍要靠事件模板自己写死分支，同一批业障要铺 N 条 `OutcomeRule`。

**① 在 `CardData` 上加一格「事件产出池标签」**
— 否决：制造第二权威（`CardType` + `Rarity` + `Pool` 三格已经足以表达全部已知的收窄需求），且与「不新增字段」那条硬边界同源。

**① `LearnTechnique` 也开池抽，靠扩 `GrantPoolPicker` 的职责承接**
— 否决：见 ①-d 两条理由。

**② 允许弃牌堆整堆回流重洗**
— 否决：**这正是 `ADR-0052` 明文推翻过的那条**，理由（疲劳永不可达、对局无终止压力）一字未变。

**② 允许随机位入堆（洗回 / 置入第 N 张）**
— 首批不开，见 ②-b。它不是被否决，是被**排在顶 / 底之后**；`combat-service.md` 已预写好届时的处置。

**② 干脆不开口，把两条推论的措辞收紧为真全称**
— 未否决，作为「仍需用户决定」第 1 条列出（见下）。代价：`MoveCard` 的六区闭集里抽牌堆成为唯一只出不进的区，而「把关键牌塞回牌堆顶」是构筑类卡牌游戏里一条相当常规的 payoff 面；关死它等于关掉一整类牌序操控设计。

---

## 与既有决策的张力

**一处，且建议不靠松动解决。**

**`ADR-0052` vs ②-a。** `ADR-0052` 的备选方案栏明写「**重洗弃牌堆 — 推翻（08-11c）：疲劳永不可达，对局无终止压力**」。本方案**不要求它松动**：它否决的是「抽牌堆空时由弃牌堆重洗补充」这条**规则性、无限次**的机制，而 ②-a 提的是**有限次、消耗性的一次性效果**，两者的终止性含义不同（见 ②-a 的三条依据，尤其 `ADR-0088` 已就同一担忧裁决过更强的一条）。

- **建议的处置**：`ADR-0052` 的「决策」与「理由」两节**一字不动**，只在「后果」一节补一条边界说明——与它已有的「疲劳后来改为以栈条目结算（→ `ADR-0088`），但规则本身不变」那条形态完全一致。
- **不松动时的替代方案**：若用户认为这条边界过细、宁可保持「抽牌堆绝对只出不进」，则采纳「仍需用户决定」第 1 条的**否**分支——此时 ②-d 的三句措辞仍需改一句（`deck/_index.md` 内 `⇄` 与「只减不增」的自相矛盾**与开不开口无关**，两句里必有一句错，得挑一句改）。

**`ADR-0091` / 成员卡排除 / `ADR-0068` / `ADR-0088` —— 无张力**，①-b 与 ②-a 均在它们的既有射程内。

---

## 前置依赖

1. **`RarityTier` 的分布与权重表**（`open-questions/01-combat.md`，08-10c）。①-b 取池链末端的「按 `RarityTier` 权重表 `PickMany`」**结构可定、取值不可定**——授予池权重表的初值已给出结构，但事件产出侧要不要单独一档余量（对应 `GrantPoolMargin` / `ExchangePoolMargin` 那一族）无从填。**不阻塞落地**：与那三格同款，可先填 0。
2. **`CardData` 的完整字段清单与起始卡组内容**（`open-questions/01-combat.md`）。①-c 的 `CardTypeFilter` 依赖 `CardType` 五值枚举（**已定**，不阻塞）；但「业障池实际有几条」在首批业障内容出现前算不出，故校验 5f 在内容存量为零时会拦下所有池抽规则——**这是有意的收紧**（与 Exchange 闸 ① 同款），落地代价为零。
3. **道念产 / 削的量纲基准**（`open-questions/01-combat.md`，承重）。②-c 的 `count` 上界该给几，取决于「一张牌值多少道念」——**不阻塞结构**，`count` 是内容侧逐条目的数字，形态已定、只欠取值，归内容扩充后的统计校准。
4. **无跨库前置依赖。**

---

## 仍需用户决定

### 1. `MoveCard` 是否向抽牌堆开口（②-a 的开 / 不开）

- **选项 A（推荐）· 开，形态按 ②-a ~ ②-d。** 后果：多出一整类牌序操控 payoff 面（把关键牌塞回堆顶 / 把废牌压到堆底）；需改三句措辞 + 加四条校验；`ADR-0052` 的「后果」一节补一条。零存档变更、零新增原语。
- **选项 B · 不开，把两条推论收紧为真全称。** 后果：抽牌堆成为闭集六区里唯一只出不进的区；「牌序操控」这一整类设计面在本作永远写不出来。**注意 B 分支仍要改一句**——`deck/_index.md` 内 `⇄` 与「只减不增」的自相矛盾与开不开口无关。
- **推荐 A 的理由（依据既有设计）：** ① `ADR-0088` 已经开了**更强**的一条（疲劳栈条目可被取消），且用的就是「`TurnLimit` 是硬护栏」这条论证 —— 对更弱的回堆效果拒绝同一条论证，是两套标准；② 量纲上封死（`TurnLimit` 12 ⇒ 单侧一场最多抽 16 张，回堆 1~2 张改不了失血曲线的形状）；③ 结构上零新增（`MoveCard` 已在原子操作清单里，抽牌堆已在闭集六区里），挡住它的只有措辞；④ `combat-service.md` **自己预写了**「日后要回来改哪一句」的注记 —— 本库早已预期这一天。

→ **已裁决（2026-08-27 · 批量评审）：A · 开口，形态按 ②-a ~ ②-d。** 首批不开随机位；护栏落在载体消耗性上（静止式一律 `PushError`，「整堆 / 全部」硬禁）；`ADR-0052` 只在「后果」补一条边界说明，决策 / 理由两节不动；②-d 的三句措辞重写须同批落笔。
>
> **⚠ 与同批草稿 `solution-draft-ability-primitive-grammar.md` 的对齐点（提炼时须核）：** 该草稿同批裁定「疲劳**不设取消通道**、改为可被削减至 0」（其 `## 仍需用户决定` 第 1 条取 (c)）。本条推荐理由 ① 引用的「`ADR-0088` 已开了更强的一条（疲劳栈条目**可被取消**）」因此**在措辞上已失效**，但**结论不受影响**：(c) 保留了「疲劳可被监听 / 可被响应 / 可被削减至 0」，`TurnLimit` 作为硬护栏这条论证原样成立，且 (c) 本身就是「用有限次效果改写终止性压力」的先例。提炼时把理由 ① 改述为「`ADR-0088` 以 `TurnLimit` 为硬护栏允许疲劳被削减至 0，同一条论证覆盖更弱的回堆效果」，不要照抄「可被取消」。

### 2. `AddLooseCard` 的走池抽这一路：保留并定义，还是整条取消

- **选项 A（推荐）· 保留并按 ①-a ~ ①-c 定义。** 后果：`OutcomeRule` 增三格字段 + 五条校验；换来「随机塞两张业障」「随机给一张散牌」两拍可由一条规则表达。
- **选项 B · 取消，`TargetId` 五个 `Op` 一律必填非空。** 后果：改动面最小（删一句注释 + 把校验 5 改成无条件），当前零内容依赖；代价是同一批随机业障要在事件模板里铺 N 条定值 `OutcomeRule` 并自己写分支，且「负向奖励有随机性」这一手感要靠事件条目数量堆出来。
- **推荐 A 的理由（依据既有设计）：** ① 结构成本近乎为零 —— 取池链**逐字复用**商店 `Card` 族那一条（它本身也明写「沿用授予池那一条，不另写一段」），过滤器与 `GrantFromPool` 同名同义，子流复用 `Reward`；② 「业障由事件负向奖励塞进卡组」是既定设计，而定值路径下每一条业障产出都要指名道姓，随着业障条目变多，事件模板会被迫按业障数量铺分支 —— 那是内容维护成本，不是设计取舍；③ 原反对意见（「从通用卡牌池抽讲不通」）在 `CardTypeFilter` 收窄后不再成立。
- **若选 B**，①-d（`LearnTechnique` 不开）自动成立，无需单独裁决。

→ **已裁决（2026-08-27 · 批量评审）：A · 保留并按 ①-a ~ ①-c 定义取池链。** 走池抽只对 `AddLooseCard` 开放，其余四个 `Op` 的 `TargetId` 必填非空；取池链逐字沿用商店 `Card` 族那一条；子流复用 `RngStream.Reward`；新增 `CardTypeFilter` 一格；`LearnTechnique` 按 ①-d **不开**池抽（该项亦随本裁决定案）。
