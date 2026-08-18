# Explore 的揭示分布、取池过滤与揭示转场

- id: 2026-08-17c-explore-reveal-mechanics
- date: 2026-08-17
- topic: systems/adventure-event/explore · systems/services/future-event-service · systems/adventure-event/common-properties · systems/game-progression · ux/screen-flow · systems/balance · content
- status: distilled
- distilled-to: systems/adventure-event/explore/_index.md, systems/adventure-event/explore/common-properties.md, systems/services/future-event-service.md, systems/adventure-event/common-properties.md, systems/game-progression.md, ux/screen-flow.md, systems/balance.md, content/_index.md

## Intent（distilled）

**一句话：** Explore 的三条待答（揭示池权重 · 揭示 UI · 遮罩下的成本呈现）全部收口，且**没有一条需要新机制**——权重是既有抽取链路的涌现结果、成本那一条本就已答结、UI 是一层不进屏幕栈的全屏覆盖。本次真正新增的只有一处：一条**取池期过滤**，堵住「真身被 flags 关掉、Explore 壳照样进池」这个能上线、线上不可见的洞。

### ① 「揭示池权重」不是新机制，是既有抽取链路的涌现结果

「遮罩的是一个固定的 AdventureEvent」一旦成立，运行时就**没有任何一个时刻可以掷这个权重**——揭示阶段读的是模板上写死的 `RevealedEventId`，不掷骰。

> **真身类型分布 = Explore 条目池的组成 × 既有的加权抽取，不设第二套权重机制。**

- **三处数据类一律不加字段（承重）：** `AdventureEventData` 不加 Explore 权重字段 · `LocationData` 不加 Explore 子权重行 · `PlotModulation` 不加第七个字段。三处都是「加一个字段就要回答谁有权改它」的口子。
- **三档调制能力因此不对称，且这是可接受的：** location 只能表达「洞天多秘境」（类型修正表的 Explore 一行），表达不了「洞天的秘境多半是战斗」；AdventurePlot 靠对单条 Explore 条目加权表达倾向（**既有能力、零改动**，与「迷途 = 让候选池多出 Explore 条目」是同一条用法）；篇章不设专门旋钮。
- **剧本对真身分布的调制是间接的，而这恰好合规。** 它落在**内容面**（挑哪些条目加权），而非**约束面**。若另设一个「真身类型权重」字段，剧本一旦能改它，就等于隔着遮罩改变玩家实际面对的事件类型分布而玩家全程无感。

### ② 真身占比 = 内容编排口径 + 一条审计，不是运行时约束

**初值 Combat : Exchange : Travel ≈ 5 : 3 : 2**（待 ch1 数值标杆实测校准）。

- **Combat 过半**——Explore 的张力来源是「可能是一场架」；战斗占比过低，秘境退化为「随机小惊喜」，元类型的风险语义消失。
- **Travel 压最低档**——揭示出的 Travel 强制换图并把该地域计数归 0，频率一高就打乱「一次篇章 = 若干 location 串联」的节奏，且玩家无从选目的地，连续几次会读成「系统在踢我走」。
- **Exchange 居中作为正向面**——三类都必须非零，否则「未知」几次之后不再未知；Exchange 是唯一纯正向的那一类。
- **口径是「条目池加权后的期望占比」**：不做配额保证、不做「连续 N 次未出 Exchange 则保底」（保底 = 一套新机制，且它把「未知」变成可推算的）。
- 落点：`adventure-event` 内容类型开张时，其类型档案的 Explore 分区台账登记每条的真身 `Id` 与真身 `eventType`，`/audit-content` 汇总三类占比并与目标区间比对，**只报告不阻断**。

### ③ 取池期过滤：真身被 `ContentEnabled == false` 关闭 ⇒ 该 Explore 壳不进池（本次唯一的行为面新增）

洞的形状：线上用 flags 关掉一个坏掉的 Combat 条目后，**指向它的 Explore 壳仍在 `AllEnabled()` 池里**（壳自己是 enabled 的）。玩家照常选中、照常付费，揭示后落到那个被关闭的条目上（读取侧不过滤，能解析、不崩）——**放量开关对这条路径静默失效**。

> **Explore 条目的可抽取性附加一条：其 `RevealedEventId` 指向的条目必须同样 enabled。** 判定在 future-event-service 的取池阶段、与 `AllEnabled()` 同一档。

- **它是抽取侧过滤，不违反「读取侧不过滤」**：`pastEvent` 回溯与图鉴解析照常解析 disabled 条目，历史痕迹不受影响。
- **代价明写：** 关掉一个 Combat 条目会连带压低 Explore 的实际出场率。这是正确的方向——被判定为坏掉的事件，不该靠遮罩偷渡上场。
- **真身的启用态不进 `EventOption` 快照**（它随 flags 变，重算不保证同结果且无消费方），只在取池那一刻查一次。

### ④ 加载期校验：Explore 的四条合为一段

| # | 校验 | 时机 | 失败语义 |
|---|---|---|---|
| 1 | `RevealedEventId` 非空且经 `ContentRegistry` 解析得到 | 内容模板加载期 | `PushError` + `Id` + 悬空目标 `Id` |
| 2 | 真身 `eventType ∈ { Combat, Travel, Exchange }` | 内容模板加载期 | `PushError` + `Id` |
| 3 | 真身不是另一个 Explore（不嵌套） | 内容模板加载期 | 由 #2 蕴含，仍单列以给出可读报错 |
| 4 | Explore 条目不得标 `lifeSpanCost` 条目级偏移 / 覆盖 | 内容模板加载期 | `PushError` + `Id` |

四条与物化组装后那条断言（`SelectCost` 不读真身成本字段 · `SelectCost.AbilityElements` 恒空）共享一个 Explore 校验段，避免散落。

### ⑤ 揭示 = `eventStart` 内的一次 `with` 派生；resolver 按真身选取

```
【eventStart 阶段】
  revealed = option with { IsRevealed = true }      ← 派生实例，当前批里那份原实例不动
  resolver = 按 revealed 的真身 eventType 选取       ← 真身是 Combat → CombatEventResolver，否则 GenericEventResolver
  resolver.ResolveAsync(revealed, ct)
```

- **resolver 的选取判据是真身，不是 `EventOption.EventType`。** `EventType` 恒为 `Explore`，照它选会把一个战斗真身送进 `GenericEventResolver`。这与「resolver 的拆分轴是有没有状态机、不是有几个类型」直接一致，也与 `Source` 的「按谁组装出这条 element 判」是同一条判据的镜像。
- **`IsRevealed` 是本次结算内的瞬态标志，痕迹侧无消费方**（`PastEventEntry` 靠恒存的 `RevealedEventId` 回溯）。**字段保留**：当前批 eventOptions 落存档，退出重进后呈现层需要它判断「这一步已经揭示过了」。

### ⑥ 遮罩态卡片 = 与其余 eventOption 完全同构的一张卡

- **同尺寸、同触控目标、同滑动节奏，不做异形 / 加大 / 特效卡。** 异形卡会把「未知」在视觉上读成「特殊奖励」（闪光的卡 = 好东西是玩家的通行预期），而秘境有一半概率是一场架；且它破坏横滑区的等宽节奏，窄屏尤甚。
- **卡面全部取 Explore 模板自己的**显示名 / 描述 / 风味文案 / 图标；`RevealedEventId` 与 `DestinationLocationId` 完全不参与呈现。
- **遮罩态不标注敌人等级**——「战斗类事件在物化时精确标注敌人等级」按**呈现给玩家的类型**成立，遮罩态呈现的是 Explore。揭示后的战斗前展示照常精确标注。
- **`selectCost` 展示照既有档位表**：Band 0 / Band 1 不显示，Band 2 如实展示 Explore 壳自己那一份。

### ⑦ 揭示 UI = 一次全屏转场，不是一个屏幕、不加确认

```
横滑选择区 ──点选──▶ [支付 · 终态判定 ①] ──▶ ┌── 揭示转场层（全屏，安全区内） ──┐ ──▶ 真身事件屏
                                              │  遮罩卡放大居中 → 散雾 / 翻面      │      Combat → 战斗前展示（精确标注敌人等级）
                                              │  → 露出真身标题卡                  │      Travel  → 单一目的地的 Travel 结算
                                              │  ≈ 1.2s，全屏任意触点即跳过        │      Exchange→ 交易界面
                                              └────────────────────────────────────┘
```

- **不设「确定进入」按钮**（成本已付、规则层不可回退，一个只能点「确定」的按钮是纯粹的额外操作，且这是全游戏最高频的操作路径）。
- **跳过 = 全屏任意触点**，不是角落里的小按钮——触控目标尺寸问题在此一次性消失。
- **不做二次揭示分层**（先揭示类型再点一次揭示内容）：把一个瞬间拆成两次点击，收益只有一点仪式感。
- **转场层不是一个 `Screen`**：无返回路径、不进屏幕栈、不需要 `BlockingNoticeScreen` 一类建制。
- **真身是 Travel 时**揭示卡直接显示目的地名（只有一个，物化时已掷定），随后照常结算——不给「去 / 不去」的选择。
- 时长 ≈ 1.2s 与一次短音效是**待实测初值**；无震动。

### ⑧ 部分线索（危险度提示 / 类型图标暗示）：完全不给

- 定价侧已用两条纪律封死「用成本数值反推真身」，展示侧本已无泄漏面；**一个机械的危险度档位 / 类型图标等价于把真身类型直接印在卡上**——三类真身的危险度分布是可学习的，玩过十次的玩家会把「危险度」直接读成「是不是架」。Explore 随之退化为换皮的 Combat 标签。
- **「这个秘境格外凶险」的表达位已经指定给了文案与美术**（放弃条目级成本旋钮时定的）。给一个机械线索档就是把那个已被让渡的旋钮从另一侧拿回来。
- **风味文案允许暗示气氛，不得建立可学习的映射。** 这无法机械检查，属作者自律，写进类型档案的作者须知。

### ⑨ 与既有决策的一处张力：明写接受

**「战斗类事件精确展示敌人等级，让越级挑战成为可主动选择的风险 / 回报」在 Explore 路径上失效。** 这不是缺陷，正是 Explore 的定价——元类型出售的就是「不知道」。若补一条「秘境内的战斗不得越级」，等于用规则把风险抹平，且会成为 `±2` 带「无例外的硬规则」的一个例外，而那条规则不接受例外。风险的界仍由 `±2` 带给出，已经足够。

### 落地面

| # | 落点 | 改动 |
|---|---|---|
| 1 | `explore/_index.md` | 三条待答收口：分布涌现（三处不加字段）· 取池过滤 · 揭示形态 · 无线索 · 等级张力明写接受 |
| 2 | `explore/common-properties.md` | 专有字段结案：**只有 `RevealedEventId` 一个**，模板侧与物化侧同名、物化直拷 |
| 3 | `future-event-service.md` | 取池期附加过滤一条；resolver 按真身选取；Explore 加载期校验段 |
| 4 | `adventure-event/common-properties.md` | 结算流程的 `eventStart` 一步写实：`with` 派生 + resolver 按真身选取 |
| 5 | `game-progression.md` | location 的类型修正只能及 Explore 一行，及不到真身分布 |
| 6 | `ux/screen-flow.md` | 揭示转场层 + 遮罩态卡片同构纪律 |
| 7 | `balance.md` | 真身占比初值挂 ch1 专场 |
| 8 | `content/_index.md` | `adventure-event` 开张时须带 Explore 分区台账列与一项 audit 汇总 |

**不 bump 存档 schema**（不新增物化字段、不新增 `PastEventEntry` 字段）· **不新增服务方法、不新增 manager**（揭示落在既有 `eventStart` 阶段内）· `PlotModulation` 六字段与 `LocationData` 三组字段不变 · **对后端库零影响**。

## Clarifications（评审裁决）

草稿以 `status: decided` 进入本次提炼，四项取向一律取推荐项：

1. **真身占比初值** → **`5 : 3 : 2`**（Combat / Exchange / Travel）。均分 `4:3:3` 会让强制换图明显更频繁；`7:2:1` 让秘境与 Combat 的区分度只剩「事前不标等级」。
2. **是否给部分线索** → **完全不给**。二值的「凶险 / 平和」标仍是可学习的映射，只是分辨率低一档。
3. **揭示转场** → **≈ 1.2s + 全屏任意触点跳过 + 一次短音效、无震动**。时长是纯手感项、只能实测，故记为初值。**本次不替既有待答项「寿元告警是否伴随音效 / 震动」拍板**——那是另一条独立问题。
4. **模板侧字段名** → **`RevealedEventId`**（与物化侧同名）。物化时直拷、零变换，同名让这件事自明；`MaskedEventId` 会让读者以为中间有转换。

**顺带修掉一处措辞滞后：** 待答清单里「遮罩下的成本呈现」仍写得像悬而未决，而它已由成本侧收口那一场答结（只存在一份成本、Band 2 如实展示）。本次一并改掉。

## Open questions

- **两个待实测初值：真身占比 `5:3:2` 与揭示转场时长 ≈ 1.2s。** 前者归 ch1 数值标杆专场回归校准，后者是纯手感项、只能在真机上调。形态均已定，只欠取值。
- **定价表 Explore 行填多少**——归 ch1 数值标杆专场（本次未动）。
- **事件类型出现概率修正的运算形态**（乘性 / 加性 / 白名单 + 权重）未定 ⇒ 「Explore 一行如何被 location 修正」只有形状没有算子。它不阻塞本次任何一条。

## Notes / triage

- 输入：`inbox/solution-draft-explore-mechanics.md`（`status: decided`），已归档进 `inbox/archive/`。
- 本次答结并移出 4 条待答项，见 `answer-logs/log-explore-mechanics.md`。
- 本次是同日第三场专场；Travel 与 Research 两场已把 `EventOption` 骨架推到九字段，本次**不新增任何物化字段**。
