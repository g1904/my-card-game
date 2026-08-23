---
type: solution-draft
date: 2026-08-22
question: `Practice` / `Standard` 两档战斗失败，除按道念差扣 `lifeTotal` 外，是否另有后果？
source: open-questions/01-combat.md → 「内容与数值的残留」·「失败后果的其余部分（08-16b 采集）」
targets: systems/adventure-event/combat/_index.md（主）· systems/scoring.md（三档结算产物表旁注）· systems/balance.md（仅当 K3 的频次口径被采纳）
status: distilled
distilled-to: handoffs/2026-08-22-combat-defeat-consequences.md
reviewed: 2026-08-22 —— 主结论「不另加规则层的额外后果」获确认；K1 软口径（不加校验）· K2 不加折扣维持 1:1（张力交叙事层）· K3 给口径 ≤ 10% 落 `balance.md`（待实测初值）。
---

# 方案草稿 — Practice / Standard 两档的失败后果

## 问题

清单条目问的是：`Practice` / `Standard` 两档失败，**除扣 `lifeTotal` 外是否另有后果**。（`Finale` 不在范围内——该档失败即角色终结，走 `DefeatReason.FinaleFailed` 独立终结通道。）

它悬着的原因是**提问方式本身预设了「只有一条后果」**：`systems/scoring.md` 的「三档结算产物」表只画了 `lifeTotal` 与奖励两列，读起来像是「失败 = 掉点血 + 少拿奖励」，显得单薄，于是自然产生「是不是该再加点什么」的疑问。

**但本库既有设计里，一次失败实际付出的代价有六条，只是它们分散在五份文档里、从未被并排列出。** 本草稿的主要工作是先把这六条列全，再回答「够不够」。

**建议的答案：不另加任何规则层的额外后果。** 详见下。

## 约束（来自既有设计）

- **`lifeTotal` 的扣减是 1:1、不设截断、不隔系数、不分档**——`lifeTotal -= (敌人道念 − 角色道念)`。「道念差是一把通用刻度」（战斗屏上的「落后 8 点」当场就是「输了掉 8 点」）**依赖于这条换算不被任何分支污染**。权威：`systems/scoring.md`、`systems/character-profile/life-total.md`。
- **`DefeatReason` 里没有「输掉一场普通战斗」这一项。** `Practice` / `Standard` 失败**本身不终结角色**，对应项是资源触底的 `LifeTotalExhausted`。权威：`systems/character-profile/life-total.md`。
- **失败侧的额外惩罚已有承载，且明确「不另立结构」**——它就是奖励结构中的负向条目（`ProfileChangeSpec` 的带符号约定）。模板侧的落点是 `AdventureEventData.OnFailureRules`（`OutcomeRule[]`，`Direction = Loss`，可写 key `{ LifeSpan, LifeTotal, ManaLimit, Jade }`，另可走 `DeckOperation`）。权威：`answer-logs/log-0802.md`、`systems/adventure-event/common-properties.md`。
- **经验的失败折算已定案，且定案理由正是「失败已付了 lifeTotal 的硬代价」**：`FailureRatio` 默认 50（向下取整、下限 1），明写「**50% 而非更低**：失败已经付了 `lifeTotal` 的硬代价（归 0 即角色终结），靠反复失败刷经验天然不是优势路线」。权威：`systems/game-progression.md`。
- **隐藏属性推拉胜负同施一份 `HiddenStatGrade`，不套用 `FailureRatio`**——判据是「隐藏属性的语义是『做了什么』，胜负不改变行为的性质」。权威：`systems/adventure-event/common-properties.md`、`systems/adventure-event/combat/_index.md`。
- **`selectCost` 无条件施加、支付在结算之前、不可退。** 走向不影响它。权威：`systems/adventure-event/common-properties.md`。
- **`eventCountLimit` 只计「选择进入并结算」的事件，不分胜负。** 权威：`systems/game-progression.md`。
- **经验供给 / 需求比仅 1.15–1.20，满级后经验直接丢弃，卡级的后果是「寿元耗尽而等级未满 → `defeated`」**——这是**有意保留的失败面**。权威：`systems/game-progression.md`。
- **炼气（ch1）可无限重试**，元进程压力主要落在 ch2 / ch3 的有限重试上。权威：`ux/onboarding.md`、`systems/services/life-cycle-service.md`。
- **`Practice` 的定位是「比试 / 切磋——低风险历练，点到为止」**，且**低风险全部由遭遇参数承担，不由派个更弱的对手承担**（三档赋级一律 `±2`）。权威：`systems/adventure-event/combat/_index.md`。
- **`Practice` 与 `Finale` 同取 `WinMargin 0` 是巧合不是共性，两档的「失败后果全部不同」已被明写为承重条目**——本条的答案不得把两档并到一起。权威：同上。

## 建议方案

### 1. 一次 `Practice` / `Standard` 失败**已经**付出的代价 —— 六条，逐条有权威

`[既有推演]`

这是本草稿的核心。下表只是把既有定案并排列出，**不含任何新提案**：

| # | 代价 | 量级 / 形态 | 权威 |
|---|---|---|---|
| ① | **扣 `lifeTotal`** | `= 敌人道念 − 角色道念`，1:1 无截断；炼气基线仅 10，最坏开局落差 9 ⇒ **一次惨败几乎打穿整条耐久线** | `systems/scoring.md`、`character-profile/life-total.md` |
| ② | **已支付的 `lifeSpanCost` 打了水漂** | 无条件施加、支付先于结算、不因失败退还；寿元是**唯一的时长 / 生命预算**，归 0 即 `defeated`（大限将至） | `adventure-event/common-properties.md` |
| ③ | **占掉一个 `eventCountLimit` 名额** | 配额是「在这个地域做了几件事」的纯计数，不分胜负；名额有限 ⇒ 它挤掉的是另一个本可选的事件 | `systems/game-progression.md` |
| ④ | **经验按 `FailureRatio` 折半** | 默认 50%、向下取整、下限 1；且供需比只有 1.15–1.20 ⇒ **反复失败会真实地导致卡级**，而卡级的终点是「寿元耗尽而等级未满 → `defeated`」 | `systems/game-progression.md` |
| ⑤ | **失去胜利侧的全部奖励厚度** | 强制奖励的线性 `1:1 × rewardPerMomentum` 归零、可选奖励的 `advantage` 三档不适用；失败只发 `baseReward` | `systems/scoring.md`、`systems/balance.md` |
| ⑥ | **隐藏属性照推，且推的是同一份量** | 胜负同施一份 `HiddenStatGrade`、不套 `FailureRatio` ⇒ 输掉一场杀伐类 `Standard` 照样积满煞气，剧本层的后果一分不少 | `adventure-event/common-properties.md`、`combat/_index.md` |

**另有一条内容侧的可选通道（已存在，非新增）：** 少数条目可在 `OnFailureRules` 里夹带负向条目（扣 `Jade` / 扣 `ManaLimit` / 经 `DeckOperation.AddLooseCard` 塞一张业障入组）。**「另有后果」这件事本身在机制上早已可表达**——问题从来不是「有没有承载」，而是「要不要一条**规则层的、三档通用的**额外后果」。

### 2. 结论：**不另加规则层的额外后果**

`[既有推演]`

四条依据，各自独立成立：

1. **既有定案已经用「失败已付了 lifeTotal 的硬代价」这句话论证过一次了。** `FailureRatio` 取 50% 而非更低，理由逐字写在 `systems/game-progression.md`。**再加一层后果等于推翻那次论证的前提**——若失败的代价不够重，`FailureRatio` 就该往下调，而不是在旁边并联一条新惩罚。两处不能各调各的。
2. **代价 ② ③ ④ 是「隐形但真实」的三条**，它们之所以让人觉得「失败后果单薄」，是因为**它们在结算面板上不可见**（寿元在 Band 0 / Band 1 完全不显示数字、配额没有专门呈现、经验折半玩家算不出来）。**这是呈现问题，不是机制问题。** 用加惩罚去解决呈现不足，是给一个已被满足的需求造结构——与 Finale「勉强通过不另立奖励线」是同一条克制。
3. **失败在本作里已经是一条通向死亡的连续曲线，不是一次可无限重来的挫折。** ①（耐久）与 ④（卡级 → 寿元耗尽）是**两条独立的 `DefeatReason` 路径**（`LifeTotalExhausted` / 寿元归 0），一次失败同时把角色往这两条线上推。再加第三条压力源，改变的不是"失败有代价"这件事，而是**容错量**——而容错量的正确旋钮是 `baseMomentum` 表、赋级带、`lifeSpanCost` 定价表，不是新增一条后果。
4. **它撞休闲定位与「炼气可无限重试」的手感。** 本作的元进程压力刻意集中在 ch2 / ch3 的有限重试上，ch1 是无门槛无限重试的入口；`Practice` 更是被明确定位为「低风险历练」。**给 `Practice` 加重惩罚是正面撞击**，给 `Standard` 单独加则会让两档失去共用同一套结算代码的前提之一（三档共用结算，差异只在 `EncounterSpec` 的参数）。

### 3. `Practice` 与 `Standard` 的差异化 —— **已由三个既有旋钮自动兑现，不需要为失败侧另立差异**

`[既有推演]`

条目要求给出「两档的差异化依据」。**差异不需要新建，它已经在了**：

| 旋钮 | `Practice` | `Standard` | 对失败后果的实际效果 |
|---|---|---|---|
| `TurnLimit` | 8 | 10 | **失败时的道念差期望更小** ⇒ 代价 ① 自动更轻。少 2 个回合 = 少 2 个回合的差距累积窗口 |
| `WinMargin` | 0（相等即胜） | 1（高者胜） | **判负的门槛更靠后** ⇒ 同一场对局在 `Practice` 更可能落在「平即胜」而非 `Defeat` |
| `ExperienceGrade` 档位偏置 | 胜利 `Standard`（低风险 ⇒ 对位低一档） | 胜利 `Major` | 失败折半后 `Practice` 本就更薄 ⇒ 代价 ④ 已随档位自动分层 |

再加上定价表按「事件类型 × 篇章」分格、**`combatTier` 各档可各有 `lifeSpanCost` 取值**（`adventure-event/common-properties.md` 明写），代价 ② 也有一个现成的分档位。

**推论：`Practice` 的「低风险」是完整成立的**——回合更少 ⇒ 输得更轻，门槛更低 ⇒ 更少判负，产出更薄 ⇒ 折半后更薄，入场费更低 ⇒ 沉没成本更小。**四条全部由既有参数承担，一条新机制都不需要**，这正是「低风险 / 高难度全部由遭遇参数承担」那条承重定案的直接兑现。

### 4. 落笔形态：把「不另加」写成一条明文，并把六条代价列进 `combat/_index.md`

`[通行做法]`

本条问题**是第二次被采集**（08-16b 归集时标注「此前未进清单」）。一个「不加东西」的结论若只体现为待答清单里少一行，**日后必然被第三次重开**——因为原始的观感（结算表只有两列，看起来单薄）不会因为答了一次就消失。

建议在 `systems/adventure-event/combat/_index.md` 的「结算产物」小节下补一条承重条目，内容 = 上文第 1 节的六条代价表 + 第 2 节的四条依据摘要 + 一句「呈现不足不是加惩罚的理由」，并在 `systems/scoring.md` 的「三档结算产物」表下加一行旁注回链本条（**不复述表**，避免第二权威）。

## 具体形态（可 derive 的落地面）

**本方案的结构面净改动 = 零。** 不新增字段、不新增枚举成员、不新增 `DefeatReason` 项、不 bump 存档 schema、不新增校验（K1 若选硬校验则另计，见下）。落地面只有三处文档写作：

| # | 文件 | 改动 |
|---|---|---|
| 1 | `systems/adventure-event/combat/_index.md` | 「结算产物」下新增一条承重条目（六条代价表 + 四条依据）；「待决问题」删去「失败后果的其余部分」那一条 |
| 2 | `systems/scoring.md` | 「三档结算产物」表下加一行旁注：完整代价清单见 combat/_index.md（回链，不复述） |
| 3 | `systems/balance.md` | **仅当 K3 被采纳** —— 记一条内容编排口径「`Standard` 条目挂负向 `OnFailureRules` 的占比 ≤ N%」（待实测初值） |

若 K1 选「硬校验」，另加一处：`AdventureEventData` 内容模板加载期校验表新增一行 —— `eventType == Combat && combatTier == Practice` 的条目，`OnFailureRules` 内不得出现 `Direction == Loss` → `PushError` + 条目 `Id`。（`combatTier` 是模板常量，加载期可见，技术上成立。）

## 后果

- **对 derive 就绪度是净正向**：`combat/_index.md` 的待决问题从 9 条降为 8 条，且减掉的这条不带任何数值依赖，是纯粹的机制面收口。
- **不触发任何迁移**（零结构改动）。
- **它把「失败很轻」这个潜在误读提前封住**：日后若实测发现失败确实太轻，正确的调节点已经被指名了（`baseMomentum` 表 / 赋级带 / `lifeSpanCost` 定价表 / `FailureRatio`），不会再有人去加第七条后果。
- **代价明写（接受）：** 结算面板上玩家仍然只看得见 `lifeTotal` 一列在掉。代价 ② ③ ④ 的可见性归 `ux/combat-ux.md` 与 `ux/screen-flow.md` 的战后面板设计，**且寿元那一条受 Band 门控、在 Band 0 / Band 1 本就不该显示数字**——这是既定纪律，不是本条要修的。

## 备选方案（已考虑并否决）

- **失败额外扣一次寿元（"疗伤耗时"）。** 通行做法里失败常带时间惩罚。**否决**：`selectCost` 已在事件入口无条件付过，二次扣寿元会让「寿元预算 = 时长旋钮、按目标时长反推定价表」这条口径出现**随走向分叉的分支**——反推时要按胜率加权算期望，旋钮精度直接下降。这与「`lifeSpanCost` 形态 = 非负整数定值、不带区间不带公式」的否决理由逐字同构。
- **失败额外扣 `manaLimit`。** **否决**：`manaLimit` 的推拉幅度已被钉死为 ±1 且「一章净增仅 +1~+2」（加载期校验 `ResourceKey == ManaLimit` 时 `Magnitude == 1`）。把它接进失败侧会让一条本该缓慢单调成长的长期线变成随战绩抖动的短期线，且 −1 在 5/5 基线上是 20% 的战力削减 —— 对一个已经在输的玩家施加的**滚雪球惩罚**，正是休闲定位要避开的形状。
- **失败塞一张业障（`Affliction`）入组。** **否决为规则层通则，保留为内容侧特例**：这正是 `OnFailureRules` + `DeckOperation.AddLooseCard` 已经能表达的东西（`Slay the Spire` 的诅咒牌范式）。作为**通则**它撞疲劳规则——卡组规模直接换算为后期失血速率，每输一场胖一张卡 = 每输一场后期多失血，是双重滚雪球。
- **失败计入一个新的 `PlayerStatistics` 项（如 `TotalCombatsLost`）。** **否决**：统计层是**纯读数层**、「绝不被任何规则 / 闸门 / 幂等键读取」，故它**不构成任何后果**——加了也不改变失败的代价，只是多一个数字。首批两项刻意最小，扩表要有独立的理由（例如成就系统落地），不是本条的答案。
- **给 `Practice` 的 `lifeTotal` 扣减加一个折扣系数（如 50%）以对位「低风险」。** **否决**（但它引出一条真实张力，见下节，并列为 K2 交由用户复核）：这是「减轻」方向，与休闲定位同向，但会**污染 1:1 这条通用刻度**——「落后 8 点 = 输了掉 8 点」当场变成「除非这是 Practice，那时掉 4 点」，玩家心算的账本要分档，而「不隔系数、不分档、不设截断」是明写的承重定案。`Practice` 的低风险已由 `TurnLimit 8` + `WinMargin 0` 充分兑现（见第 3 节）。

## 与既有决策的张力

**一条，轻度，不阻塞本方案：`Practice` 的「点到为止 / 切磋」叙事 ↔ 失败仍按 1:1 全额扣 `lifeTotal`（理论上可致 `LifeTotalExhausted` 角色终结）。**

- 冲突的是**叙事而非规则**：`combat/_index.md` 把 `Practice` 描述为「比试 / 切磋——低风险历练，点到为止」，而机制上一场切磋输得够惨仍可能直接终结一个耐久见底的角色。
- **为什么不为它松动 1:1**：松动的代价是通用刻度分档（见上节末条）；而**规则层的护栏已经在了**——赋级带 `±2` 使最坏开局落差有界（炼气 9 < 基线 10），`life-total.md` 明写这条护栏正是为了封住「一次惨败打穿耐久」。
- **不松动时的替代方案（推荐走这条）：** 张力交给**叙事层**而非规则层解决——`Practice` 失败的定性文案写成「力竭负伤 / 自愧不如」一类，不写「败于同门之手身受重创」。这落在 `plot-manager.md` 已有的叙事层，零新增结构。
- **由此派生一个待用户复核的取向：K2。**

## 前置依赖

以下三条**不阻塞本方案的结论**（结论是「不加东西」，不依赖任何数值），但**阻塞对结论的实测复核**：

- **卡牌产 / 削道念的量纲基准**（ch1 数值标杆专场）。它决定**失败时的典型道念差**落在什么区间 —— 若典型差值远小于 `lifeTotal` 基线，代价 ① 会比设计预期轻得多，届时应调 `baseMomentum` / 敌人产出曲线，**而不是回头加后果**。
- **三档 `BaseReward` / `RewardPoolId` 的取值**（ch1 数值标杆专场）。它决定代价 ⑤ 的实际厚度 —— 若 `baseReward` 本身就很厚，「失败只发 baseReward」的痛感会被抹平。
- **`lifeSpanCost` 定价表的 `combatTier` 各格**（ch1 数值标杆专场）。它决定代价 ② 的量级，以及第 3 节里 `Practice`／`Standard` 差异化的第四个旋钮是否真的被用上。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> - **主结论（§ 建议方案 2「不另加规则层的额外后果」）** → **已确认照草稿采纳**。合并 interview 中无人反对；
>   六条既有代价 + 四条依据按草稿写进 `systems/adventure-event/combat/_index.md`，`systems/scoring.md` 只加回链旁注、不复述表。
> - **K1 · `Practice` 能否挂负向 `OnFailureRules`** → **A · 软口径**：只写内容编排口径「`Practice` 条目默认不挂负向 `OnFailureRules`」，**不加加载期校验**。
> - **K2 · `Practice` 失败的 `lifeTotal` 扣减是否加折扣** → **A · 不加，维持 1:1 三档统一**。
>   「点到为止」的张力**交给叙事层**：`Practice` 失败的定性文案写「力竭负伤 / 自愧不如」一类，落 `systems/services/plot-manager.md` **既有**叙事层，零新增结构。
> - **K3 · `Standard` 负向 `OnFailureRules` 的频次口径** → **A · 给口径，占比 ≤ 10%**，落 `systems/balance.md`，**标为待实测初值**（不是安全证明）。
>
> K1 / K2 / K3 三项均为用户逐条单答的**正式拍板**，不带 `[采纳推荐 — 待复核]`。
> 三项皆不改变主结论；K1 取 A 后，「具体形态」一节里那条**仅当 K1 选硬校验才追加的加载期校验行不落地**。

**K1 · `Practice` 档条目能否挂负向 `OnFailureRules`？（轻）**

- 选项 A **软口径**（推荐）—— 不加校验，只在 `combat/_index.md` 写一条内容编排口径「`Practice` 条目默认不挂负向 `OnFailureRules`」。后果：保留剧情性特例的书写位（例如一场有故事分量的切磋），但依赖作者自觉，无机制发现。
- 选项 B **硬校验** —— 加载期 `PushError`（`combatTier == Practice` 且 `OnFailureRules` 含 `Direction == Loss`）。后果：「Practice = 低风险」成为可机械检查的不变式，与本库偏好一致；代价是关死特例，日后要开需改校验。
- 选项 C **不表态** —— 什么都不写。后果：本条日后第三次被重开。
- **推荐 A，理由：** 本条的整个论证是「代价已足够、不需要**规则层**通则」，而 `OnFailureRules` 本就是**内容层的例外通道**（「少数事件夹带负向条目」是既有定案）。为一个 tier 关死例外通道，是把一条内容编排偏好升格成结构约束，量级不匹配。

→ 已裁决（2026-08-22 · 批量评审）：**A · 软口径** —— 只在 `combat/_index.md` 写编排口径，不加加载期校验（选项 B 的校验行不落地）。

**K2 · `Practice` 失败的 `lifeTotal` 扣减是否加折扣系数（例如 50%）？**

- 选项 A **不加，维持 1:1 三档统一**（推荐）—— 后果：「落后 N 点 = 输了掉 N 点」这条通用刻度保持无分支、零心算成本；`Practice` 的低风险由 `TurnLimit 8` + `WinMargin 0` 承担。
- 选项 B **加折扣** —— 后果：`Practice` 的「点到为止」叙事与机制严格对齐、切磋不再可能致死；代价是通用刻度分档，且 `EncounterSpec` 需新增一个字段（或平衡表新增一格），并撞上「1:1 就是全部规则、不隔一层映射」这条明写定案。
- **推荐 A，理由：** 该张力是**叙事层**的，已有零成本的叙事层解法（见「张力」一节）；且 1:1 的价值恰恰在于它没有例外——一旦开一档，`Standard` 与 `Finale` 为何不开就需要新的论证。

→ 已裁决（2026-08-22 · 批量评审）：**A · 不加折扣，维持 1:1 三档统一**；「点到为止」的张力交由**叙事层**承担
（`Practice` 失败的定性文案写「力竭负伤 / 自愧不如」一类，落 `plot-manager.md` 既有叙事层，零新增结构）。

**K3 · `Standard` 档条目挂负向 `OnFailureRules` 的频次是否给一个编排口径初值？（轻）**

- 选项 A **给口径** —— 例如「`Standard` 条目中挂负向 `OnFailureRules` 的占比 ≤ 10%（待实测初值）」，落 `systems/balance.md`。后果：「少数事件」这个既有措辞从形容词变成可对账的数字，`/audit-content` 日后可核；代价是多一格待校准的初值。
- 选项 B **不给** —— 保持「少数事件」的定性表述。后果：少一格初值，但「少数」是多少由每个作者各自解读，条目一多就会漂移。
- **推荐 A（≤ 10%），理由：** 与本库「内容侧走枚举档 + 平衡表映射、可对账」的既有范式一致，且这条口径的成本极低（一行表）。**10% 是待实测的初值，不是安全证明** —— 它的校准依赖上文三条前置依赖。

→ 已裁决（2026-08-22 · 批量评审）：**A · 给口径，占比 ≤ 10%**，落 `systems/balance.md`，**标为待实测初值**。

---

> **注：** 本条的主结论（第 2 节「不另加」）**不在待决之列**——它由六条既有代价 + 四条依据推出，属 `[既有推演]`。K1 / K2 / K3 都是它落地时的边角取向，三条无论怎么选都不改变主结论。
