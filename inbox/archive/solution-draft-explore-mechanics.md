---
type: solution-draft
date: 2026-08-17
question: Explore（探索秘境）通用结算器的数据形态 —— 揭示池权重、揭示 UI、遮罩下的成本呈现
source: open-questions/03-adventure-event-types.md → 「各类型的结算 / 机制细化」的 Explore 一段；细目见 systems/adventure-event/explore/_index.md#待决问题
targets: systems/adventure-event/explore/_index.md · systems/adventure-event/explore/common-properties.md · systems/services/future-event-service.md · systems/game-progression.md · ux/screen-flow.md · systems/balance.md · content/_index.md
status: distilled
decided-on: 2026-08-17
reviewed: 2026-08-17 —— 四项取向一律取推荐项（真身占比 5:3:2 · 完全不给部分线索 · 转场 ≈1.2s + 全屏任意触点跳过 + 一次短音效无震动 · 模板侧字段名取 RevealedEventId）
distilled-to: handoffs/2026-08-17c-explore-reveal-mechanics.md
---

> **本草稿已裁决（2026-08-17）：全部取向项一律按推荐方案定案。** 逐项见文末「## 仍需用户决定 → 已全部裁决」。

# 方案草稿 — Explore 类 AdventureEvent 的揭示机制

## 问题

`open-questions/03` 把 Explore 的待答收窄为三项：**揭示池权重 · 揭示 UI · 遮罩下的成本呈现**（对应 `explore/_index.md#待决问题` 的前两条 + 顶层成本一条）。

它卡住的是：Explore 已被定性为**纯元类型**（自身无产出口径，只揭示 Combat / Travel / Exchange 三类真身），但**「三类真身以什么频率出现在玩家面前」目前没有任何承载点**——真身在内容条目上是固定的，故这不是一个运行时掷定的权重，而是「Explore 条目池的组成 × 既有加权抽取」的涌现结果，而这条链路从未被明写。呈现侧同样悬空：遮罩态的卡片长什么样、揭示是一次转场还是一个屏幕、要不要给线索，均未定，导致 `explore/common-properties.md` 的专有字段清单也补不完。

**范围声明：** 本草稿**不碰 `manaLimit −1` 的承载点**——它已从 Explore 移走，归 Research 专场（见 `open-questions/03-adventure-event-types.md` 该条与 `systems/character-profile/mana.md`）。下文凡涉及处只做回链。

## 约束（来自既有设计）

- **Explore = 元类型，遮罩一个固定的真身；真身取值域 = Combat / Travel / Exchange**（不含 Research、不嵌套自身）。→ `decisions/ADR-0002-adventure-event-taxonomy.md`、`explore/_index.md`。
- **真身在内容条目上已固定指定，非点击时临时生成**；沿用 `IsRevealed` / `RevealedEventId` 与 `PastEventEntry.RevealedEventId`，**不新增机制**。→ 同上。
- **一次选择只结算一个事件，`pastEvent` 上只有一条痕迹**（`EventType = Explore`，真身在 `RevealedEventId`）。→ `adventure-event/common-properties.md`。
- **支付先于揭示**：`TryApply(SelectCost)` → 终态判定 ① → 【`eventStart`】选 resolver、Explore 揭示 → resolver。→ 同上「结算阶段」。
- **成本侧只存在一份 `selectCost`（Explore 壳自己的）**；泄漏面在定价侧，由「Explore 自成定价行、不由真身推导」+「Explore 条目禁用条目级成本覆盖」两条纪律封死。→ `explore/_index.md`、`answer-logs/log-cost-side-closure.md`。
- **唯一物化点 = future-event-service；产出即定稿、immutable**；候选一律经 `AllEnabled()` 取池。→ `systems/services/future-event-service.md`。
- **文本类字段一律不物化**，由 UI 按 `EventId` 现场取模板组装。→ 同上。
- **PlotManager 只调内容不调约束**，其权力面 = `PlotModulation` 六个 `[Export]` 字段，**写不出第七个**。→ `systems/services/plot-manager.md`。
- **location 的软框定 = 事件类型出现概率修正**（按 `eventType` 一行一类）；硬框定只在敌人侧。→ `systems/game-progression.md`。
- **Explore 揭示出的 Travel 必走 20% 随机档**；且**由 Explore 揭示而来的 Travel 照常把该地域计数归 0**。→ `travel/_index.md`、`game-progression.md`。
- **Explore 的经验产出档位偏置 = `Standard` / `Minor`**。→ `game-progression.md`。
- **战斗类事件在物化时精确标注敌人等级**（否决模糊危险度档位）。→ `future-event-service.md`。
- **UI 硬约束：** 竖屏优先 · 触控优先 · **无 hover-only 可供性** · 不在最高频操作上加模态 · UI 文案一律走 `res://text/` 翻译键。→ `.claude/rules/ui-input-rules.md`、`ux/combat-ux.md`、`ux/error-and-blocking-ux.md`。

---

## 建议方案

### 1. 「揭示池权重」不是一个新机制 —— 它是既有抽取链路的涌现结果

`[既有推演]`

问题措辞（「三者的出现权重」）成文于 Explore 尚可能「点击时掷定真身」的年代。**「遮罩的是一个固定的 AdventureEvent」一旦定案，运行时就没有任何一个时刻可以掷这个权重**——揭示阶段读的是模板上写死的 `RevealedEventId`，不掷骰。

因此建议明写：

> **真身类型分布 = Explore 条目池的组成 × 既有的加权抽取，不设第二套权重机制。**
> 玩家观察到的「秘境里有多大概率是一场架」= ∑（被抽中的 Explore 条目权重）按其真身 `eventType` 分组的自然结果。

**推论 ①（承重）：`AdventureEventData` 上不新增任何 Explore 权重字段，`LocationData` 不新增 Explore 子权重行，`PlotModulation` 不新增第七个字段。** 三处都是「加一个字段就要回答谁有权改它」的口子，而本库对这类口子的既定收口是不给（对位 `TravelFullFanoutChance` 与「赋级函数不接受区间覆盖参数」）。

**推论 ②：三档调制能力各自的边界因此是不对称的，且这是可接受的。**

| 调制源 | 能表达 | 不能表达 | 判定 |
|---|---|---|---|
| **location** | 「洞天多秘境」（`eventType` 修正表的 Explore 一行） | 「洞天的秘境多半是战斗」 | **接受**——location 的软框定本就是类型级粒度，为它开条目级粒度等于把第二套 `EventWeights` 塞进 `LocationData` |
| **AdventurePlot** | 「这条线上多出指向 Combat 真身的秘境」（`PlotModulation.EventWeights` 对单条 Explore 条目加权） | —— | **既有能力，零改动**；它与 `travel/_index.md` 已明写的「迷途 = 让候选池多出 Explore 条目」是同一条用法 |
| **篇章** | 由该篇章可用的 Explore 条目池自然给出 | —— | **不设专门旋钮** |

**推论 ③：剧本对真身分布的调制是间接的，而这恰好合规。** 它靠「挑哪些 Explore 条目加权」实现，落在**内容面**（PlotManager 的合法权力），而非**约束面**。若另设一个「真身类型权重」字段，剧本一旦能改它，就等于隔着遮罩改变玩家面对的实际事件类型分布而玩家全程无感——这与 `travel/_index.md` 否决「剧本推拉 80/20」的依据 ② 是同一条理由。

### 2. 真身占比的编排口径 = 内容侧台账 + 一条审计，而非运行时约束

`[既有推演]` + `[取向选择]`

既然分布是涌现的，它就**只能在内容编排口径上被控制**，落地形态：

- `content/adventure-event/_index.md`（Explore 分区）的条目台账**登记每条 Explore 的真身 `Id` 与真身 `eventType`**；
- `/audit-content` 增一项对账：**汇总三类真身的条目占比**，与本节的目标区间比对，偏离即报告（**只报告，不阻断**——它是编排口径不是校验）。

**建议初值（待 ch1 数值标杆实测校准）：Combat : Exchange : Travel ≈ 5 : 3 : 2。** 推导链：

- **Combat 过半**——Explore 的张力来源是「可能是一场架」；若战斗占比过低，秘境退化为「随机小惊喜」，元类型的风险语义消失。且 Combat 本就是「最高频的一类」（`adventure-event/_index.md`）。
- **Travel 压到最低档**——Explore 揭示的 Travel 会**强制换图并把该地域计数归 0**（`game-progression.md`），频率一高就打乱「一次篇章 = 若干 location 串联」的地域节奏，且玩家无从选择目的地（必走随机档），连续几次会读成「系统在踢我走」。
- **Exchange 居中作为正向面**——三类都必须有非零占比，否则「未知」在几次之后就不再未知；Exchange 是唯一纯正向的那一类，它让秘境不是纯粹的风险赌注。
- 与 `Standard` / `Minor` 的经验档位偏置自洽：秘境是中等产出，不该被编排成「战斗浓度更高的伪 Combat」。

**这是取向项**（见「仍需用户决定」①）。

### 3. 新增一条取池期过滤：真身被 `ContentEnabled == false` 关闭 ⇒ 该 Explore 壳不进池

`[既有推演]`（**本草稿发现的一处真实漏洞**）

既定语义：**抽取侧过滤（`AllEnabled()`），读取侧不过滤（`Get(id)` 照常解析 disabled 条目）**。Explore 在这两条之间开了一个洞：

> 线上用 flags 关掉一个坏掉的 Combat 条目后，**指向它的 Explore 壳仍在 `AllEnabled()` 池里**——壳自己是 enabled 的。玩家照常选中该秘境、照常付费，揭示后落到那个被关闭的条目上（读取侧不过滤，能解析、不崩），**于是放量开关对这条路径静默失效**。

这正是 `data-resource-rules.md` 点名的失败形态：「漏写过滤 = 线上放量开关失效，且能上线、线上不可见」。建议收口：

> **Explore 条目的可抽取性附加一条：其 `RevealedEventId` 指向的条目必须同样 enabled。** 判定发生在 future-event-service 的取池阶段，与 `AllEnabled()` 同一档；真身 disabled ⇒ 该 Explore 壳本次不进候选池。

- **它不是「读取侧过滤」，不违反既有纪律**：过滤发生在抽取侧（决定「这次能不能抽到它」），而非在 `pastEvent` 回溯 / 图鉴解析侧（那两处照常解析 disabled 条目，历史痕迹不受影响）。
- **代价明写**：关掉一个 Combat 条目会连带压低 Explore 的实际出场率（壳被排除）。**这是正确的方向**——一个被判定为坏掉的事件，不该靠遮罩偷渡上场。
- **实现提示**：真身的启用态**不进 `EventOption` 快照**（它随 flags 变，重算不保证同结果但也无消费方）；只在取池那一刻查一次。

### 4. 加载期校验（可机械检查，四条）

`[既有推演]`（「坏数据必须在启动期大声失败」+ Explore 既有的两条校验同一处）

Explore 条目在**内容模板加载期**照下列校验，违规 `GD.PushError` + 条目 `Id`：

| # | 校验 | 失败语义 |
|---|---|---|
| 1 | `RevealedEventId` 非空且经 `ContentRegistry` 解析得到 | 必需缺失 → `PushError` + `Id` + 悬空目标 `Id` |
| 2 | 真身的 `eventType ∈ { Combat, Travel, Exchange }` | 同上（`Research` 与 `Explore` 均在此被拦） |
| 3 | 真身不是另一个 Explore（不嵌套） | 由 #2 蕴含，**仍单列一条以给出可读的报错**——「不嵌套」是元类型定义，值得一条自己的消息 |
| 4 | Explore 条目**不得**标 `lifeSpanCost` 的条目级偏移 / 覆盖值 | **已定案**（`explore/_index.md`），此处只是与上三条**合并在同一处实现**，不是新增 |

**归位提示：** #1–#3 是 Explore 独有的三条，与既有的 #4 以及物化组装后那条断言（`SelectCost` 不读真身成本字段 · `SelectCost.AbilityElements` 恒空）**放在同一处、同一档**——四处校验共享一个 Explore 校验段，避免散落。

### 5. 揭示 = `eventStart` 内的一次 `with` 派生，不改写当前批

`[既有推演]`

`EventOption` 是 `sealed record` 且「产出即定稿、不得改写其字段」；`future-event-service.md` 已把 `with` 表达式明写为「定稿后若确需派生（如 Explore 揭示）就产生一个新实例」的惯用法。落地：

```
【eventStart 阶段】
  revealed = option with { IsRevealed = true }      ← 派生实例，当前批里那份原实例不动
  resolver = 按 revealed 的真身 eventType 选取       ← 真身是 Combat → CombatEventResolver，否则 GenericEventResolver
  resolver.ResolveAsync(revealed, ct)
```

- **resolver 的选取判据是真身，不是 `EventOption.EventType`。** 这是既有「两个 resolver 的拆分轴是有没有状态机，不是有几个类型」的直接落地；`EventType` 恒为 `Explore`，照它选会把一个战斗真身送进 `GenericEventResolver`。
- **与 `Source.EventOutcome` / `Source.CombatReward` 的既有判据完全一致**（`systems/common-properties.md`：按**谁组装出这条 element** 判，Explore 揭示出战斗真身时战利品出自 combat-service）。本条只是同一条判据在 resolver 选取上的镜像。
- **`IsRevealed` 因此是本次结算内的瞬态标志，痕迹侧无消费方**（`PastEventEntry` 靠恒存的 `RevealedEventId` 即可回溯）。**建议保留该字段不删**：当前批 eventOptions 落存档，退出重进后呈现层需要它判断「这一步已经揭示过了」；删它的收益为零而改动面涉及三处。

### 6. 遮罩态卡片 = 与其余 eventOption **完全同构**的一张卡

`[既有推演]` + `[通行做法]`

选择区是「可横向滑动的选择区」，卡片是其中的等宽单元（`ux/screen-flow.md`）。建议：

- **同尺寸、同触控目标、同滑动节奏**——**不做异形 / 加大 / 特效卡**。异形卡会把「未知」在视觉上读成「特殊奖励」（玩家的通行预期：闪光的卡 = 好东西），而秘境有一半概率是一场架；且异形单元破坏横滑区的等宽节奏，在窄屏上尤其明显。
- **卡面全部取 Explore 模板自己的**显示名 / 描述 / 风味文案 / 图标，`RevealedEventId` **完全不参与呈现**。这是「文本类字段跟随模板」+ 泄漏面纪律的合流：真身的任何一个字段泄漏到卡面上，都会成为定价侧两条纪律之外的第三种指纹。
- **遮罩态不标注敌人等级**——「战斗类事件在物化时精确标注敌人等级」是按**呈现给玩家的类型**成立的，遮罩态呈现的是 Explore，无等级可标。**揭示后的战斗前展示照常精确标注**（见 §7）。
- **`selectCost` 展示照既有档位表**：Band 0 / Band 1 不显示，Band 2 如实展示 Explore 壳自己的那一份精确扣减量。**这一半已答结，本草稿不重开**——见 `adventure-event/common-properties.md` 与 `answer-logs/log-cost-side-closure.md`。清单里「遮罩下的成本呈现」这一句的措辞需在提炼时一并修掉（它仍写得像悬而未决）。

### 7. 揭示 UI = 一次全屏转场，不是一个屏幕、不加确认

`[既有推演]` + `[通行做法]`

**时机已定**（进入即揭示）；本节只定形态。

```
横滑选择区 ──点选──▶ [支付 · 终态判定 ①] ──▶ ┌── 揭示转场层（全屏，安全区内） ──┐ ──▶ 真身事件屏
                                              │  遮罩卡放大居中 → 散雾 / 翻面      │      Combat → 战斗前展示（照常精确标注敌人等级）
                                              │  → 露出真身标题卡                  │      Travel  → 单一目的地的 Travel 结算（随机档）
                                              │  ≈ 1.2s，全屏任意触点即跳过        │      Exchange→ 交易界面
                                              └────────────────────────────────────┘
```

- **不设「确定进入」按钮。** 成本已支付、规则层不可回退，一个只能点「确定」的按钮是纯粹的额外操作；且这是全游戏最高频的操作路径，`ux/combat-ux.md` 已定「不在最高频操作上加模态」。
- **跳过 = 全屏任意触点**，不是一个角落里的小 `跳过` 按钮——触控目标尺寸问题在此一次性消失，且反复游玩的玩家会自然形成「点一下过场」的肌肉记忆。
- **无 hover-only 可供性**：本流程零 hover 通道，全部信息常驻可见。
- **不做二次揭示分层**（「先揭示类型 → 再点一次揭示内容」）：那是把一个瞬间拆成两次点击，代价是每次秘境多一次操作，收益只有一点仪式感。
- **转场层不是一个 `Screen`**，是事件屏进入流程内的一层覆盖节点——它没有返回路径、不进屏幕栈、不需要 `BlockingNoticeScreen` 一类的建制。
- **文案走 `res://text/` 翻译键**（秘境卡标题 / 揭示层的类型名）；此路径不产生 `ERR_*` 键。
- **真身是 Travel 时**：揭示卡直接显示目的地名（只有一个），随后照常结算——**不给「去 / 不去」的选择**（秘境把人带到别处，且 `selectCost` 已付、规则层无拒绝通道）。

### 8. 部分线索（危险度提示 / 类型图标暗示）：建议**完全不给**

`[既有推演]` + `[取向选择]`

`explore/_index.md` 的待答项把它列为开放选项。建议明确否决，理由是**它会从第三侧捅开已被封死两次的泄漏面**：

- 定价侧已用两条纪律（自成定价行 + 禁用条目级覆盖）封死「用成本数值反推真身」；
- 展示侧本已无泄漏面（只有一份成本）；
- **一个机械的危险度档位 / 类型图标，等价于把真身类型直接印在卡上**——三类真身的危险度分布是可学习的（Combat 高、Exchange 低），玩过十次的玩家会把「危险度」直接读成「是不是架」。那样 Explore 就退化为一个换皮的 Combat 标签，元类型的全部价值消失。
- **「这个秘境格外凶险」的表达位已经指定了**：`explore/_index.md` 在放弃条目级成本旋钮时明写「那类表达改由**文案与美术**承载」。给一个机械线索档就是把那个已被让渡的旋钮从另一侧拿回来。

**风味文案本身是否可以暗示真身？** 建议口径：**允许暗示气氛，不建立可学习的映射**——「洞口渗出血腥气」这类写法只要不与真身类型形成一一对应就无害，而这**无法机械检查**，属作者自律（与「同 location 内成本齐平」被否决的那条自律同款，此处只能接受，因为文案不可能被机械约束）。写进类型档案的作者须知即可。

---

## 具体形态（可 derive 的落地面）

### Explore 子类型专有字段（`AdventureEventData` 侧）

| 字段 | 类型 | 必填 | 语义 | 校验 |
|---|---|---|---|---|
| `RevealedEventId` | `string`（`[Export]`） | **是**（`eventType == Explore` 时） | 被遮罩的真身条目 `Id`，内容侧静态指定 | 加载期 #1 / #2 / #3（见 §4） |

- **就这一个字段**——`explore/common-properties.md` 里「其余专有字段待两问答定后补」这句可结案为「**没有其余字段**」。
- **模板侧与物化侧同名（`RevealedEventId`），物化时直拷、不做任何变换。** 取不同的名字（如模板侧叫 `MaskedEventId`）会诱使读者以为中间发生了转换，而实际上没有。（轻取向项，见「仍需用户决定」④。）
- **`IsRevealed` 只存在于物化侧**，模板上没有对应字段（模板恒为「未揭示」）。

### `EventOption`（无变化，此处只是把 Explore 的取值语义写实）

```csharp
// 骨架七字段不变，Explore 路径上的取值：
EventType      = EventType.Explore     // 恒为 Explore，永不为真身类型
IsRevealed     = false                 // 物化产出恒 false；eventStart 阶段以 with 派生为 true
RevealedEventId= <模板上的同名字段直拷> // 物化时即已确定，不掷骰
SelectCost     = Explore 模板 + 定价表 Explore 行组装（既定：不读真身任何成本字段）
```

### 取池与校验的落点

| # | 检查 | 时机 | 失败语义 |
|---|---|---|---|
| A | `RevealedEventId` 解析 / 取值域 / 不嵌套 | **内容模板加载期** | `PushError` + `Id` |
| B | Explore 条目无 `lifeSpanCost` 条目级覆盖（**已定案**） | 内容模板加载期 | `PushError` + `Id` |
| C | 真身 `ContentEnabled == true` | **future-event-service 取池期**（与 `AllEnabled()` 同一档） | 静默排除该 Explore 壳；建议 `PushWarning` 一次带两个 `Id`，便于线上定位 |
| D | 物化组装后：`SelectCost` 未读真身成本字段 · `AbilityElements` 恒空（**已定案**） | 物化组装后断言 | `PushError` |

### 真身类型占比（内容编排口径 · 初值 · 待实测校准）

| 真身 `eventType` | 建议占比 | 理由（摘） |
|---|---|---|
| `Combat` | **≈ 50%** | 元类型的张力来源；Combat 本就是最高频的一类 |
| `Exchange` | **≈ 30%** | 唯一纯正向面，让秘境不是纯风险赌注 |
| `Travel` | **≈ 20%** | 强制换图 + 计数归 0 + 无从选目的地，频率一高即打乱地域节奏 |

- **口径是「条目池加权后的期望占比」，不是运行时约束**——不做任何配额保证、不做「连续 N 次未出 Exchange 则保底」（保底 = 一套新机制，且它把「未知」变成可推算的）。
- 落点：`content/adventure-event/_index.md` 的 Explore 分区台账 + `/audit-content` 的一项汇总报告。
- **绝对数字与 `lifeSpanCost` 定价表的 Explore 行取值归 ch1 数值标杆专场**（`systems/balance.md`）。

### 揭示转场（UX 落地面）

| 项 | 取值 |
|---|---|
| 载体 | 事件屏进入流程内的**全屏覆盖层**（安全区内），非独立 Screen、不进屏幕栈 |
| 触发 | `eventStart` 阶段揭示之后、resolver 落屏之前 |
| 时长 | **≈ 1.2s**（取向项） |
| 跳过 | **全屏任意触点**；跳过即立刻落到真身屏 |
| 确认 | **无**（不设「确定进入」按钮） |
| 展示内容 | 真身的显示名 + 类型名（按 `RevealedEventId` 现场取模板）；**不展示数值** |
| 敌人等级 | 遮罩态不标；**揭示后的战斗前展示照常精确标注** |
| hover | **零 hover 通道** |
| 文案 | `res://text/` 翻译键；无 `ERR_*` |
| 音效 / 震动 | 取向项（见「仍需用户决定」③） |

---

## 后果

- **不 bump 存档 schema。** 不新增物化字段、不新增 `PastEventEntry` 字段（`RevealedEventId` 早已在两侧）。
- **不新增服务方法、不新增 manager。** future-event-service 的 API 面仍是四方法；揭示落在既有 `eventStart` 阶段内。
- **`PlotModulation` 六字段不变**，`LocationData` 三组字段不变。
- **唯一的行为面新增是 §3 的取池期过滤**——它改变 future-event-service 的候选池计算，需在「生成 / 加权规则」那条待答项定稿时一并落进伪码。
- 需更新的文档：`explore/_index.md`（三条待答收口）· `explore/common-properties.md`（专有字段结案）· `future-event-service.md`（取池过滤 + resolver 按真身选取）· `game-progression.md`（location 只能调 Explore 一行，明写不可及真身分布）· `ux/screen-flow.md`（揭示转场）· `balance.md`（真身占比初值挂 ch1 专场）· `content/_index.md`（Explore 分区台账列 + audit 项）。
- **对后端库零影响**——纯客户端的内容形态与呈现，不触及任何报文。**本草稿为单库（客户端）。**

## 备选方案（已考虑并否决）

- **在 `AdventureEventData` 上给 Explore 加一组「真身类型权重」并在揭示时掷定。** 否决：与「遮罩的是一个**固定**事件、非点击时临时生成」正面冲突（ADR-0002 + `explore/_index.md`），且会让 `RevealedEventId` 从「内容侧已确定」退回「物化时掷定」，牵动 `PastEventEntry` 的判据论证。
- **在 `LocationData` 上加一行 Explore 子权重（「洞天的秘境多半是战斗」）。** 否决：它是塞进 `LocationData` 的第二套 `EventWeights`，粒度与既有三组字段不一致；且立刻引出「PlotManager 能不能改它」——而 `PlotModulation` 无字段可填，两侧能力不对称本身就是漂移源。
- **给遮罩卡一个危险度 / 类型线索档。** 否决：见 §8——它把已被封死两次的泄漏面从第三侧捅开，且会让 Explore 退化为换皮的类型标签。
- **两段式揭示（先类型、再内容，各一次点击）。** 否决：全游戏最高频路径上多一次点击换一点仪式感。
- **异形 / 加大的秘境卡。** 否决：把「未知」误读成「奖励」，且破坏横滑区等宽节奏。
- **真身 disabled 时改为「揭示后降级为空结算」。** 否决：玩家已付费却什么也没发生，是最坏的观感；且它在 `pastEvent` 上留下一条「结算了但什么也没产出」的诡异记录（正是 `Aborted` 被引入时明写要避免的那种）。取池期排除才是正确的粒度。

## 与既有决策的张力

**一处，明写接受，不需要松动任何既有决策：**

**「战斗类事件在物化时精确展示敌人等级，让越级挑战成为可主动选择的风险 / 回报」在 Explore 路径上失效。** 玩家选中一个秘境时，无法知道里面是不是一场架，更无从比对等级。

- **这不是缺陷，正是 Explore 的定价**——元类型出售的就是「不知道」。若为它补一条「秘境内的战斗不得越级」之类的保护，等于用规则把风险抹平，Explore 随之失去存在理由；且它会成为 `±2` 带「无例外的硬规则」的一个例外，那条规则明写不接受例外。
- **风险的界仍由 `±2` 带给出**（赋级规则挂在 Enemy 上、`combatTier` 三档一视同仁），已经足够——秘境里的战斗不会比常规战斗更超纲，只是玩家事前不知道有没有。
- **它与「打不过也得打是正常出口」自洽**：产出侧本就不欠可战胜保证。
- 因此建议在 `explore/_index.md` 明写这条代价，**而不是把它当作待办**。

## 前置依赖

- **事件类型出现概率修正的运算形态**（乘性 / 加性 / 白名单 + 权重）未定 → §1 的「Explore 一行如何被 location 修正」只有形状没有算子。→ `systems/services/future-event-service.md`、`systems/game-progression.md`。
- **批次规模区间两端由什么驱动** → 不阻塞本草稿（Explore 不占特殊槽位，与其余四类同走一条加权抽取）。
- **`EventOption` 完整物化字段清单** → 若日后 outcome 权重在物化时固化，**Explore 壳不受影响**（纯元类型，自身无产出口径）；受影响的是真身条目，走它自己那一类的口径。
- **ch1 数值标杆专场** → 定价表 Explore 行的绝对取值 + 真身占比的实测校准。→ `systems/balance.md`。
- **`manaLimit −1` 的承载点** → **不在本草稿范围**，归 Research 专场（`open-questions/03-adventure-event-types.md`、`systems/character-profile/mana.md`、`research/_index.md`）。本草稿的任何一条都不以它的结论为前提。

## 仍需用户决定 → **已全部裁决（2026-08-17）**

> **定案：四项取向一律取推荐项。** 即：① 真身占比 `5 : 3 : 2`（Combat / Exchange / Travel）· ② **完全不给**部分线索 · ③ 揭示转场 ≈ 1.2s + 全屏任意触点跳过 + 一次短音效、无震动（时长为待实测初值；「是否配音效 / 震动」不越权替既有待答项「寿元告警是否伴随音效 / 震动」拍板）· ④ 模板侧字段名取 `RevealedEventId`（与物化侧同名）。
>
> 下列原文保留为选项与理由的溯源。

1. **真身三类的占比初值。**
   - **(a) `5 : 3 : 2`（Combat / Exchange / Travel）—— 推荐。** 理由见 §2：Combat 过半才撑得住元类型的张力，Travel 压最低才不打乱地域节奏。
   - (b) 均分 `4 : 3 : 3` —— 「未知」最纯粹，但 Travel 的强制换图会明显更频繁。
   - (c) Combat 重 `7 : 2 : 1` —— 秘境读作「野外遭遇」，代价是它与 Combat 的区分度下降到只剩「事前不标等级」。
2. **是否给部分线索（危险度 / 类型图标暗示）。**
   - **(a) 完全不给 —— 强烈推荐**（§8：会从第三侧捅开泄漏面）。
   - (b) 只给一个二值的「凶险 / 平和」标 —— 仍是可学习的映射，只是分辨率低一档；不推荐。
3. **揭示转场的时长、跳过形态与是否配音效 / 震动。**
   - **推荐：≈ 1.2s + 全屏任意触点跳过 + 一次短音效、无震动。** 时长是纯手感项，只能实测；音效那一半与既有待答「寿元告警是否伴随音效 / 震动」是同一类问题，**本草稿不替那条拍板**。
4. **模板侧字段名。**
   - **(a) `RevealedEventId`（与物化侧同名）—— 推荐**：物化时直拷、零变换，同名让这件事自明。
   - (b) `MaskedEventId` —— 更贴合「遮罩」的叙事，但会让读者以为中间有转换。
