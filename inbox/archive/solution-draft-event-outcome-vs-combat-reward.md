---
type: solution-draft
date: 2026-08-16
question: `Source` 枚举的 `EventOutcome`（4）与 `CombatReward`（5）是否终将合并为一个成员
source: open-questions/06-meta-progression.md → 第 3 条；权威条目在 systems/common-properties.md#待决问题
targets: systems/common-properties.md（「授予来源共有字段」节 + 待决问题 → 决策）· systems/services/combat-service.md · systems/services/future-event-service.md · systems/services/life-cycle-service.md（若采纳校验项）
status: distilled
decided-date: 2026-08-16
reviewed: 2026-08-16 —— 两项取向均按推荐项定案（① 关闭本问题，结论「不合并」落笔；② 采纳第 7 项的 `eventEnd` 单向组装校验），无遗留取向项
distilled-to: handoffs/2026-08-16h-grant-source-assembler-criterion.md
---

> **两项取向已由用户裁定（2026-08-16），均按推荐项定案：**
> ① **关闭本问题** —— 结论「不合并」落笔，从 `## 待决问题` 移出，附下方的可观察重开触发器。
> ② **采纳第 7 项** —— life-cycle-service 在 `eventEnd` 加那条单向组装校验。
>
> 本草稿全文即定案内容，可直接喂给 `/analyze-new-ideas`。

# 方案草稿 —— `EventOutcome` 与 `CombatReward` 是否合并

## 问题

`systems/common-properties.md` 的「授予来源共有字段 `SourceCode` + `Source` 枚举」在 08-12 扩为按 `(Kind, Scope)` 分域的七值开放清单时，把「非战斗事件 outcome 授予」（`EventOutcome = 4`）与「战斗遭遇 `Spoils` 授予」（`CombatReward = 5`）定为**两个成员**，前提是二者确为**两条组装路径**。该前提当时标注为「当前文档支持这一判断」，但未被钉死，于是留下一条开放问题：

> 若最终合流为同一条链路，两个成员应合并为一个——合并时 `CombatReward = 5` 的 code 就此弃用、永不复用，不得改判为别的语义。

**它卡住的是什么。** 这条问题本身不阻塞任何 derive（清单已可用），但它把 `Source` 的成员语义留在「随时可能被推翻」的状态：`SourceCode` **写入时刻即冻结、此后不变**，因此每一天的运行都在按当前语义写入不可回改的数据。悬置越久，「若合并」那一支要处理的历史数据越多。当前**无线上账号**，是代价最低的关闭窗口。

## 约束（来自既有设计）

- **成员名与 code 双双冻结，已删成员的名与 code 永不复用。** 存档侧靠 code、契约侧靠名，两者各自都是稳定键。来源：`systems/common-properties.md`「授予来源共有字段」· `backend-design-documents/contracts/profile-sync.md` §5a。
- **`SourceCode` 落在持有条目上、写入时刻 = 授予时刻、此后不变。** 条目被移除后再次获得 = 一次新的获取，写新的 `SourceCode`。来源：同上。
- **`EventOutcome` 与 `CombatReward` 的合法取值域完全相同**：`(Kind, Scope)` 校验表中两行逐格相同（法则 ❌ · 古宝 ❌ · 神通 ✅ · 法宝 ✅），即两者**只出现在轮回级两类上**。来源：同上的合法子集表。
- **规则消费点唯一 = 残卷的 `x`，且只看 `FinaleWin`。** 这两个成员**都不计入 `x`**，故合并与否对残卷、对后端复算**零影响**。来源：同上「消费点分两层」。
- **奖励由 combat-service 计算，「获取奖励」是战斗流程的一部分。** `RunCombatAsync` 尾部含「胜负判定 → 计算奖励 →（若有可选奖励）等玩家选择 → 收口」，产出 `CombatResult.Spoils`。来源：`systems/services/combat-service.md`「意图」节。
- **非战斗四类共享同一形状，差异在数据而非代码**：「呈现 → 择一进入 → 扣成本 → 应用产出 → 推拉隐藏属性 → 收口」，由**通用结算器 + 数据驱动的 outcome / effect 定义**承担。来源：同上「为何 Combat 需要独立服务」。
- **两者的施加路径今天就已经是同一条**：都收敛为 `ProfileChangeSpec`，都由 life-cycle-service 在 `eventEnd` 合并为一次 `ProfileManager.TryApply`。来源：`combat-service.md`「分工 = 计算归战斗、施加归生命周期」。
- **`EventOption.EventType` 在 Explore 时 = `Explore` 本身，真身在 `RevealedEventId`。** 来源：`systems/services/future-event-service.md` 的 `EventOption` 定义。

## 建议方案

### 1. 结论：**不合并，两个成员分立保留**；并把这条问题**就此关闭**，不再挂在待决区

`[既有推演]`

依据是下面 2–5 四条。核心判断：**待决问题里那句「若最终合流为同一条链路」必须读作「组装链路」，而组装链路当前不仅没有合流的迹象，其分叉点（combat-service 自算奖励）本身是一条带推论的承重定案。**

### 2. 先钉死判据：「合流」指**组装**链路，不指**施加**链路

`[既有推演]`

施加链路**今天就已经是同一条**——两者都是 `ProfileChangeSpec`、都在 `eventEnd` 由同一次 `TryApply` 写入。若「施加路径同一 ⇒ 应合并」成立，那么 `ExchangePurchase`（6）与 `InitialGrant`（7）也走同一条施加路径，一并该合并——而清单显然不是按这条轴切的。

**因此本条是本问题最需要先说清的一步**：判据是**谁组装出这条 element**，不是**它最后被谁写进去**。按这条判据看，两者的组装侧逐项不同：

| | `CombatReward` | `EventOutcome` |
|---|---|---|
| 组装者 | **combat-service**（`RunCombatAsync` 收口段） | **通用结算器**（五类共享的那条形状） |
| 输入 | 道念差（决定厚度）+ `RewardPoolId` 抽取池 + `BaseReward` | 物化后的 `EventOption` 上的 outcome / effect 定义 |
| 是否含玩家选择步骤 | **是**（可选奖励面板，Slay the Spire 式） | 否 |
| 是否含随机 | 是（`Reward` 子流掷可选奖励候选） | 由 outcome 定义决定，非结构必然 |
| 载体 | `CombatResult.Spoils` | 事件结算产出 |

### 3. `ExchangePurchase` 的存在已经证明：清单的粒度轴不是「战斗 vs 非战斗」

`[既有推演]`

Exchange 是**非战斗类** AdventureEvent，它的购买所得却单列 `ExchangePurchase = 6`，而没有归入 `EventOutcome`。所以清单本来就是按**渠道 / 组装路径**切的，比「战斗 vs 非战斗」这条二分**更细**。

在这条轴上，把 Combat 的 `Spoils` 与非战斗 outcome 合并，会是整份清单里**唯一一次反向粗化**——它不会让清单更一致，只会让清单多一条不成立的例外。

### 4. 合并会丢掉一个**不可重建**的信息维度，而收益只是少一个枚举成员

`[既有推演]`

非规则消费点两处（`systems/common-properties.md`「消费点分两层」）在两值分立下才成立：

- **`ProfileManager.TryApply` 的可追溯性日志** —— 合并后日志只能说「来自某个事件」。
- **客服 / 数据侧的账号溯源** —— 「战斗掉落 vs 事件产出」正是「我打赢了却没拿到东西」这类申诉的第一手区分。

**不可重建这一点是关键。** 持有条目上**没有**指回事件实例的字段（`SourceInstanceId` 是另一个字段，落 `disabledAbility`、语义是「施加禁用的来源事件实例」，本文件已明写二者不得合并）。因此合并之后，「这条神通是打赢来的还是事件给的」**在数据里彻底消失，事后无法从任何地方补出来**。

对价是「少维护一个枚举成员」——而成员本身零维护成本（它不进 `.tres`、不走 overlay、后端不复制校验表）。

### 5. 在「只能追加、永不复用」的冻结纪律下，粒度选择是**不对称**的

`[通行做法]` + `[既有推演]`

运营 / 客服侧的授予来源枚举在同类产品中普遍**按发放渠道细分**（战斗掉落 · 任务奖励 · 商店购买 · 活动发放 · 补偿发放各一档），因为它服务的是客服与数据分析而非玩法规则——玩法规则侧的消费者只有残卷的 `x`，它只认 `FinaleWin`。

叠加本项目已冻结的「名与 code 双双永不复用」：**细了可以永远不用（零成本），粗了要补回来就得追加新成员，且老数据无法回填**（`SourceCode` 写入即冻结）。在不对称的两侧之间，本方案选成本恒为零的那一侧。

### 6. 顺手把语义边界改写为**按组装者**表述，而非按事件类型

`[既有推演]`

当前措辞是「非战斗类 AdventureEvent 的 outcome 授予」/「战斗类遭遇的 `Spoils` 授予」——**按事件类型表述**。建议改为按组装者表述（具体措辞见下节），三条理由：

- **Explore 会把按事件类型的表述打穿。** `EventOption.EventType` 在 Explore 时 = `Explore` 本身，真身在 `RevealedEventId`；一个揭示出战斗真身的 Explore 选项，按事件类型判是「非战斗」，按组装者判是 combat-service 交出的 `Spoils`。**后者是对的，前者会写错。**
- **它顺手答掉一个当前没人问、但一定会撞上的边界**：Exchange 事件若另有**非购买**的 outcome（对话结果、赠礼），它归 `EventOutcome` 还是 `ExchangePurchase`？按组装者判据答案是唯一的——**只有走购买流程的那一条走 `ExchangePurchase`，其余走 `EventOutcome`**。
- 它与本库既有的判据风格一致（`combat-service.md` 的战场 / 参战方划线判据同样是「是否在场上生效」而非「属于谁」）。

### 7. 加一条 `eventEnd` 侧的组装校验（**已采纳定案**）

`[既有推演]`

组装者本身是**代码位置**，不可机械校验。退而求其次的可机械化形态：在 life-cycle-service 合并 `eventEnd` 事务时，检查 spec 内 `Op == Grant` 的 element ——

- 该事件**非战斗类**（含 Explore 揭示后真身非战斗）却出现 `Source == CombatReward` → **必需缺失**，`PushError` + **整批拒绝**；
- 反向（战斗类事件的 spec 里出现 `EventOutcome`）**不判非法**——战斗事件除 `Spoils` 外仍可携带事件级 outcome。

单向而非双向，与既有的「入口严、读档宽」及 `(Kind, Scope)` 校验表同一档纪律。**读档侧照旧宽**（保留原值、不改写）。

**这条校验的判据取「揭示后的真身」，不取 `EventOption.EventType`。** Explore 选项的 `EventType` 恒为 `Explore`，若照它判，一个揭示出战斗真身的 Explore 事件会把合法的 `CombatReward` 误判为非法并整批拒绝——正是第 6 条那条打穿点在校验侧的镜像。实现上以「本次事件是否走过 combat-service」为准（等价于该事件是否产生过 `CombatResult`），而非读事件类型字段。

## 具体形态（可 derive 的落地面）

**`Source` 成员清单：不变。** 七值 + 兜底，`EventOutcome = 4` / `CombatReward = 5` 双双保留，code 不动，`(Kind, Scope)` 合法子集表不动。**不 bump 存档 schema，无迁移，后端零改动。**

**唯一的改动 = 两个成员的语义列改写（按组装者表述）：**

| 成员 | code | 建议的新语义措辞 |
|---|---|---|
| `EventOutcome` | 4 | 由**通用事件结算器**从物化后的 `EventOption` 的 outcome / effect 定义算出的授予（Research / Explore / Travel，以及 Exchange 的非购买 outcome） |
| `CombatReward` | 5 | 由 **combat-service** 在 `RunCombatAsync` 收口段算定、经 `CombatResult.Spoils` 交出的授予（含强制与可选两类；`Finale` 档的残卷那一路仍走 `FinaleWin`） |

**判据一句话（建议写进文档，供日后引用）：**

> **看这条 element 是谁组装出来的，不看它属于哪类事件、也不看它最后被谁写进去。** 出自 `CombatResult.Spoils` → `CombatReward`；出自通用结算器的 outcome 定义 → `EventOutcome`；出自购买流程 → `ExchangePurchase`。

**关闭条件（把开放问题换成一条可观察的重开触发器）：**

> 本条**答定为「不合并」**。仅当 combat-service 的奖励计算被并入通用结算器时重新评估——具体即以下任一发生：① `RunCombatAsync` 不再自算 `Spoils`；② 战后可选奖励选择步骤被取消；③ 奖励厚度不再由道念差决定。三者任一都会在 `systems/services/combat-service.md` 的「意图」节留下明确痕迹，故该触发器是**可观察的**，不需要定期主动复核。

## 后果

- **`systems/common-properties.md`** —— 「授予来源共有字段」节的成员清单表改两行语义措辞 + 增一句组装者判据；`## 待决问题` 中的该条**移出**，`## 决策` 或该节内记一条结论 + 关闭条件。
- **`systems/services/combat-service.md`** —— 可在「奖励由本服务计算」那条加一句回链：本服务交出的 `Spoils` 内的授予一律记 `Source.CombatReward`。
- **`systems/services/future-event-service.md`** —— 同理，通用结算器侧的 outcome 授予记 `Source.EventOutcome`。
- **`systems/services/life-cycle-service.md`** —— **（第 7 项已采纳）** 在 `eventEnd` 事务的校验清单里加一条单向组装校验，判据取「本次事件是否走过 combat-service」而非事件类型字段。
- **存档 / 契约 / 后端：全部零改动。** 已核实：这两个成员按 `(Kind, Scope)` 表只能出现在轮回级两类上，而 `backend-design-documents/contracts/profile-sync.md` §5 把 **`characterDiffs` 整体列为不透明段**（含轮回级两类持有条目的 `sourceCode`）——**后端从头到尾读不到这两个值**。故本问题**不横跨边界**，对侧库不需要配套草稿。
  - 唯一的历史残留（不需要动作）：`backend-design-documents/handoffs/2026-08-12-grant-source-code-contract.md` 的清单表里列了这两行语义。它是 `status: distilled` 的历史 handoff，权威在 `contracts/profile-sync.md`，而该契约并未逐一枚举成员。若日后确要同步，改的也只是措辞。
- **derive 就绪度：不受影响。** 本条本就不是 `systems/common-properties.md` 判 blocked 的卡点（卡点是 `Source` 上行序列化形态那条 ⚠ 跨边界项，以及本条）。答定后 `common-properties.md` 的两条待决只剩一条，但仍 blocked——**本方案不宣称改变任何就绪度判定**（那归 `/assess-derive-readiness`）。

## 备选方案（已考虑并否决）

- **合并为单一成员（如 `EventGrant`），`CombatReward = 5` 弃用永不复用。** 否决：丢掉一个不可重建的信息维度（第 4 条）；在按渠道切分的清单里制造唯一一次反向粗化（第 3 条）；换来的只是少一个零维护成本的枚举成员。
- **保留两值，但按事件类型定义（`combatTier` 三档 → `CombatReward`）。** 否决：Explore 揭示出战斗真身时会判错（第 6 条第一点），且 Exchange 的非购买 outcome 归属仍悬空。
- **继续悬置，「等链路稳定后再看」。** 否决：判据已经齐备（combat-service 的奖励计算是带推论的承重定案，不是临时状态），悬置不会产生任何新信息；而当前无线上账号是代价最低的关闭窗口，越往后 `SourceCode` 写入的不可回改数据越多。
- **把两者合并、另加一个布尔 / 事件类型字段来保住溯源信息。** 否决：这是「用两个字段表达一个枚举本就能表达的东西」，且新字段要进存档、要进四类持有条目、要处理老档缺失——成本远高于保留一个已冻结的枚举成员。

## 与既有决策的张力

**一条，如实写下：`(Kind, Scope)` 校验表中两行逐格相同**（❌ ❌ ✅ ✅）。这是合并方最强的论据——在**校验层面**两者确实不可区分，表里多的那一行是纯冗余。

**本方案承认这一点，并主张「校验表的行相同」不是合并判据**，理由是同一张表里 `PremiumBundle` 与 `AchievementReward` 两行**同样逐格相同**（✅ ✅ ❌ ❌），而没有任何一方主张合并这两者。**行相同只说明两者的挂载面相同，不说明两者是同一条渠道**——挂载面是「能出现在哪类持有条目上」，渠道是「由哪条路径给出」，两个正交的维度。

除此之外与既有决策无冲突：清单本就明写是**开放**的、成员语义澄清不触及任何已冻结的名与 code、不 bump schema、不改后端契约。

## 前置依赖

**无硬前置。** 两条软相关，均**不改变本方案的结论**，只可能影响措辞：

- **`EventOption` 的完整物化字段清单未定**（`future-event-service.md` 待决项）——特别是「outcome 权重是否在物化时固化」。若 outcome 授予的组装点因此位移，第 6 条的措辞可能要微调；但只要 combat-service 仍自算 `Spoils`，分叉点就还在。
- **交易机制专场未开**（`systems/adventure-event/exchange/` 整体待定）——Exchange 是否真的存在「非购买 outcome」尚未确认。第 6 条第二点因此是一条**预置判据**而非已发生的需求；即便 Exchange 最终只有购买一条产出路径，该判据也无害（不产生任何取值）。

## 已裁决（2026-08-16 · 无遗留取向项）

两项取向均由用户按推荐项定案，本节保留原措辞作溯源：

1. **是否把这条问题就此关闭** —— **定案：关闭。** 结论「不合并」落笔，从 `systems/common-properties.md` 的 `## 待决问题` 移出，改由该节的结论 + 上方「关闭条件」承载。判据已齐备，悬置不产生新信息，而每一天的运行都在按当前语义写入不可回改的 `SourceCode`；当前无线上账号是代价最低的窗口。可观察的重开触发器已给出，不存在「关早了没法回头」的风险。

2. **是否采纳第 7 项**（`eventEnd` 的单向组装校验） —— **定案：采纳。** 它是这条判据在代码里唯一可机械化的落点，形态与既有的 `(Kind, Scope)` 入口校验完全同档。判据取「本次事件是否走过 combat-service」，不取 `EventOption.EventType`（见第 7 条）。

**本草稿至此无待用户决定项，可直接 `/analyze-new-ideas`。**

### 落笔时的动作清单（供 `/analyze-new-ideas` 使用）

| # | 文件 | 动作 |
|---|------|------|
| 1 | `systems/common-properties.md` | 成员清单表改 `EventOutcome` / `CombatReward` 两行语义为按组装者表述；「授予来源共有字段」节增一句组装者判据 |
| 2 | `systems/common-properties.md` | `## 待决问题` 中该条**移出**，改记结论「不合并」+ 关闭条件（可观察重开触发器） |
| 3 | `systems/services/combat-service.md` | 「奖励由本服务计算」那条加一句：本服务交出的 `Spoils` 内的授予一律记 `Source.CombatReward` |
| 4 | `systems/services/future-event-service.md` | 通用结算器侧的 outcome 授予记 `Source.EventOutcome`；Exchange 的非购买 outcome 同归此值 |
| 5 | `systems/services/life-cycle-service.md` | `eventEnd` 事务校验清单增一条单向组装校验（第 7 条） |
| 6 | `open-questions/06-meta-progression.md` | 移出该条待答项，并在分片抬头的「已答结并移出」行追加一笔 |
| 7 | `answer-logs/` | 记一条答结日志（含「行相同不是合并判据」这条反驳，它是本次唯一的张力处置） |

**不动的**：`Source` 成员清单与 code · `(Kind, Scope)` 合法子集表 · 存档 schema（不 bump、无迁移）· 后端契约与 `backend-design-documents/` 全库。
