---
type: solution-draft
date: 2026-09-06
question: 五条「机制 / 数值口径的文档间矛盾」逐条直读裁定：exchange 同批两份打架 · combat-service 奖励候选池 vs 神通获取通道 · lossPerMomentum 三种口径 · life-cycle-service 的 experiencePoint 待决区 · systems/_index.md 残留「敌人意图」登记。
source: open-questions.md → 「derive 就绪度」→「台账 / 投影缺口」小节（五条 🟠）
targets: systems/adventure-event/exchange/common-properties.md · systems/services/combat-service.md · systems/balance.md · systems/character-profile/life-span.md · systems/services/life-cycle-service.md · systems/_index.md · systems/character-profile/deck/_index.md · vision/references.md
status: distilled
reviewed: 用户已评审定案（2026-09-06 批量运行 · 合并 interview 零待裁项；references.md:6 的改写为用户明示确认；balance.md 的「三组待定」同型残留经 orchestrator 授权顺带对齐）
distilled-to: handoffs/2026-09-06-mechanism-contradiction-roundup.md
---

# 方案 — 五条机制 / 数值口径矛盾的逐条收口

## 问题

`open-questions.md` 的「derive 就绪度」小节（2026-09-06 全量评估产出）在「台账 / 投影缺口」下登记了五条 🟠 级的**文档间口径矛盾**。它们都不阻塞 derive 的结构面，但会让 `/derive-requirements` 按更宽的那一份写出**假的排除面**，或按已被推翻的机制写出验收标准。

本草稿对五条**逐条直读源文件**，引用原句后裁定哪一侧成立，并给出可直接落笔的替换文本。

**总裁定：四条成立（① ② ④ ⑤），一条不成立（③）。** 第 ③ 条经直读发现三处措辞的**实质结论完全一致**（候选值 5 / 10 · 均未定案 · 阻塞源同一条），就绪度小节所依据的前提「09-03 的反推已做完」被 09-03 handoff 自己的 `## Open questions` 逐字否定。

### 行号订正（直读所得，与就绪度小节的登记不符者）

| 条 | 就绪度小节写的 | 实际行号 | 说明 |
|---|---|---|---|
| ② | `combat-service.md:589` | **`:591`** | `:588` 是小节标题「### 可选奖励的候选生成」，`:589` 空行，`:590` 是「固定 3 项候选」条，`:591` 才是候选池那条 |
| ③ | `life-span.md:53` | **`:54`** | `:51` 是 `## 待决问题` 标题，`:53` 为空 |
| ④ | `life-cycle-service.md:320` | **`:390`** | `:320` 是篇章重试判定面的「三处读取上限不得硬编码」条，与 `experiencePoint` 无关 |

其余行号（`exchange/common-properties.md:213` · `exchange/_index.md:170` · `power/_index.md:73` · `balance.md:466` / `:819` · `systems/_index.md:45` · `ux/combat-ux.md:11`）逐一核对**准确**。

---

## 条目 ① — `exchange/` 同批两份互相打架

### 直读证据

**过时侧 · `systems/adventure-event/exchange/common-properties.md:213`**（该文档 `## 待决问题` 小节的**唯一**一条）：

> - **各字段的数值取值**（定价表每格、刷新价参数、两档回收率、槽位总数上界）留待内容扩充后的统计校准。→ `systems/balance.md`。

**已更新侧 · `systems/adventure-event/exchange/_index.md:170`**（同批文档，同一 `## 待决问题` 位）：

> - **刷新基价与递增量 · 单事件槽位总数上界的取值。** 形态均已定，留待**内容扩充后的统计校准**；刷新首批一律填 0（关闭）。定价表 25 格、每格币种与两档回收率**已有初值**（见 `systems/balance.md`），其绝对数字仍归同一次校准复核。→ `systems/balance.md`、`systems/character-profile/currency.md`。

**权威侧 · `systems/balance.md`（三处，逐一直读）：**

- `:361` 起 —「**25 格定价表初值**（篇章维不设 · 石 = `CostKey.SpiritStone` · 玉 = `CostKey.ImmortalJade`）：」后接完整的 5 × 5 表（`Card` 石 15/30/60/120/240 …… `PlayerItem` 玉 1/2/3/5/8），`:371` 另给出「初值来源可解释：两个一维向量的外积」的推导。
- `:302` / `:303` —「商店档 `SellRatePercent` …… **初值 40%**，可编排区间 **30–50%**」/「随售档 `PackSellRatePercent` …… **初值 15%**，显著低于商店档区间」。
- `:814`（`## 待决问题`）—「**Exchange 剩余的两组数值格**（留待内容扩充后的统计校准）：刷新基价 `RerollBaseCost` / 递增量 `RerollCostStep`（首批一律填 0 = 关闭刷新）· 单个 Exchange 事件的槽位总数上界（建议 ≤ 8）。**定价表 25 格、每格币种与两档回收率已有初值**（见上方「货币产出与定价」），其绝对数字仍归这次校准复核。」

### 裁定：**矛盾成立；`_index.md:170` + `balance.md:814` 一侧成立，`common-properties.md:213` 是过时残留。**

依据三条：

1. **时间先后。** 25 格初值与两档回收率来自 `handoffs/2026-09-05-currency-acquisition-and-pricing.md`（该 handoff 已列入 `exchange/_index.md:153` 与 `balance.md:828` 的 `Source:` 行）；而 `exchange/common-properties.md:203` 的 `Source:` 行**没有** 09-05 这一份——它在那一批落笔时被漏改，是机械遗漏而非另一派主张。
2. **权威归属。** 数值的权威在 `systems/balance.md`（两份 exchange 文档的待决项都写着「→ `systems/balance.md`」）。转发链的终点已给出取值 ⇒ 转发本身的措辞必须跟上。
3. **同批两份形态一致性。** `_index.md` 与 `common-properties.md` 是同一层的两份，其 `## 待决问题` 描述的是同一组数值格；两份写法不同即必有一份过时。

### 建议改写文本

`systems/adventure-event/exchange/common-properties.md:213`，**整条替换**为（措辞与 `_index.md:170` 对齐，但保留本文件的落点视角、不复述取值）：

> - **刷新价参数 `RerollBaseCost` / `RerollCostStep` · 单事件槽位总数上界的取值。** 形态均已定（本文件的字段面与校验表不变），留待内容扩充后的统计校准；刷新首批一律填 0 = 关闭。**定价表 25 格、每格币种与两档回收率已有初值**，见 `systems/balance.md`；其绝对数字仍归同一次校准复核。→ `systems/balance.md`。

`[既有推演]` —— 不新增任何设计，只把本文件的待决面收窄到与权威侧一致。

**顺带（纯机械、答案已定）：** `common-properties.md:203` 的 `Source:` 行建议补入 `handoffs/2026-09-05-currency-acquisition-and-pricing.md`（`_index.md:153` 已列，同批两份应齐）。

---

## 条目 ② — `combat-service` 的可选奖励候选池与神通获取通道不一致

### 直读证据

**过时侧 · `systems/services/combat-service.md:591`**（节选，原句）：

> **池 = 事件模板携带的 `RewardPoolId`，经 `AllEnabled()` 取池**，**三类混合（`CardData` / `ItemData` / `CultivationTechniqueData`）**，去重（本次已抽中的 `Id` 不再出）。

同文件 `:598`：

> `combatTier` 三档**共用同一条生成路径**，差异只在 `RewardPoolId` 与 `Tier`。

**权威侧 · `systems/character-profile/power/_index.md:73`**（内容编排口径表首行）：

> | 开放的 `SourceCode` 通道 | `InitialGrant` · `CombatReward`（收窄到 `combatTier ∈ { Standard, Finale }`，`Practice` 档不产神通——最轻一档也掉神通会把这条获取面稀释成常规掉落） · `ExchangePurchase`（定价表已有 `CharacterPower` 行，不新增旋钮） |

同文件 `:46`（**决定性的一句：它直接点名了落点就是本条要改的那个面**）：

> 战斗侧交出的授予一律记 `Source.CombatReward`（判据是「谁组装出这条 element」），**挂在战斗奖励「可选逐项领取」那一类上**，与「玩家选中一门功法 = `Spoils` 内一条 `DeckChangeElement`」逐格同构。→ `systems/common-properties.md` 的分域校验表、`systems/adventure-event/common-properties.md`、`systems/services/combat-service.md`。

**佐证 1 · `systems/character-profile/power/common-properties.md:12`：**

> **本层合法取值 =** `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`（+ 读档兜底 `Unknown`）——这四条正是神通的常规来路。

**佐证 2 · `systems/common-properties.md:271`**（`Source` 枚举登记表）：

> | `CombatReward` | 5 | 由 **combat-service** 在 `RunCombatAsync` 收口段算定、经 `CombatResult.Spoils` 交出的授予（含强制与可选两类；`Finale` 档的残卷那一路仍走 `FinaleWin`） | 否 |

**佐证 3 · 上游 handoff · `handoffs/2026-09-03-character-power-mechanics.md:24`：**

> 首批内容口径：开 `InitialGrant`（每局恰一条）· `CombatReward`（收窄到 `Standard` / `Finale` 两档，`Practice` 不产神通）· `ExchangePurchase`……

**排除另一条可能路径（必须做，否则裁定站不住）：** 神通的 `CombatReward` 能否**不经**可选奖励面板、而走 `OutcomeRule.Kind == GrantFromPool`？不能。`adventure-event/common-properties.md:135-142` 表明 `GrantFromPool` 是 `OutcomeRule` 的一个 `Kind`，而由 outcome 组装出的 element 按「谁组装出这条 element」判据记 `Source.EventOutcome`（`systems/common-properties.md:279` 原句：「出自 `CombatResult.Spoils` → `CombatReward`……出自通用结算器的 outcome / effect 定义 → `EventOutcome`」）。⇒ **`Source.CombatReward` 的神通只能出自 combat-service 的战利品组装**，而其中「强制自动计入」那一类是 `BaseReward`（资源量）⇒ 唯一落点就是 `:591` 的可选候选池。

**第四处同源残留（本条的完整修复面之一）· `systems/balance.md:816`：**

> 仍待定：**战后奖励池**各档权重（按优势档 `Tier` 三档各一张表，**族维度含卡牌 / 道具 / 功法三类**），……

### 裁定：**矛盾成立；`power/_index.md` 一侧成立，`combat-service.md:591` / `:598` 与 `balance.md:816` 需追平。**

依据：① 时间先后（`power/_index.md` 的这一批出自 `ADR-0152` / `ADR-0153`，Accepted，2026-09-03；`combat-service.md` 的候选池段落早于此批）；② 权威归属（`power/_index.md:64` 明写「**本表是三者边界的唯一权威**」，且 `:46` 明确把落点指向 `combat-service.md`，是**单向指派**而非并列主张）；③ 上游 handoff 与 `Source` 枚举登记表两侧独立佐证。

**注意本条不是纯措辞收口——它有实质的 derive 后果：** 第 23 步（战后奖励）若按 `:591` 落笔，会写出一个**结构上不可能产出神通**的候选生成器，而 `power/_index.md` 的「条目数下限 ≥ 5」正是靠 `CombatReward` / `ExchangePurchase` / 置换三条通道非空来论证的。

### 建议改写文本

**改动 1 · `systems/services/combat-service.md:591`**，把「三类混合」那一句改为四类 + 档位闸（其余部分**一字不动**）：

> **四类混合（`CardData` / `ItemData` / `CultivationTechniqueData` / `PowerData`）**，去重（本次已抽中的 `Id` 不再出）。**`PowerData` 只在 `combatTier ∈ { Standard, Finale }` 时进候选族，`Practice` 档整族排除**——最轻一档也掉神通会把这条获取面稀释成常规掉落（口径权威见 `systems/character-profile/power/_index.md`「内容编排口径」，此处不复述）。

**改动 2 · `systems/services/combat-service.md:592` 后，新增一条与「功法候选的两条口径」并列的子条**（`[既有推演]`，与既有两条功法口径逐格同构）：

> - **神通候选的两条口径。**
>   - **档位闸：`Practice` 档整族不进候选**（见上）。这是**唯一**一处让三档生成路径产生族级差异的地方，故 `:598` 的「三档共用同一条生成路径」需同批加一句限定。
>   - **候选中出现已持有的神通 → 直接排除。** 与功法侧「已持有 → 直接排除，不折算为升阶」同款：神通没有层数维度，重复授予无表达；换一条同 `Rarity` 的神通是**置换**这条独立通道（判据见 `systems/player-profile/player-power/_index.md`「同池判据 = `(CarrierKind, Scope)` 全同 + 同 `Rarity` + 排除已持有」），混进奖励抽取会让两条通道互相污染。
>   - **玩家选中一条神通 = `Spoils` 内一条 `AbilityChangeElement(Grant, Power, Character, id, Source.CombatReward)`**，与商店购买、与「选中功法 = 一条 `DeckChangeElement`」逐格同构，不新增任何结构。

**改动 3 · `systems/services/combat-service.md:598`**，整句替换：

> `combatTier` 三档**共用同一条生成路径**，差异只在 `RewardPoolId`、`Tier`，以及 `Practice` 档对 `PowerData` 族的整族排除。

**改动 4 · `systems/balance.md:816`**，把族维度从三类改为四类：

> ……（按优势档 `Tier` 三档各一张表，**族维度含卡牌 / 道具 / 功法 / 神通四类**；`Practice` 档不产神通，故神通列只在 `Standard` / `Finale` 两张表上非空）……

以上四处均为 `[既有推演]`：每一格都能从 `power/_index.md:46` / `:73` 与既有的功法候选两条口径逐字推出，无新增设计。

---

## 条目 ③ — `lossPerMomentum` 的 ch2 / ch3「三种口径」

### 直读证据（三处逐字）

**处 A · `systems/character-profile/life-span.md:54`**：

> - **`lossPerMomentum` 的 ch2 / ch3 系数取值。** ch1 = 10 已锁定；后两章已由形状锚解出候选值 5 / 10，**定案待反推**，口径见 `systems/balance.md`。

**处 B · `systems/balance.md:466-476`**（表 + 收口句）：

> | ch1 炼气 | 1–15 | **10**（锁定） |
> | ch2 筑基 | 20–32 | **5**（「1 / 2 点」· 候选值） |
> | ch3 金丹 | 45–75 | **10**（候选值） |
>
> - **形状锚（是形状不是取值）：** **一次带内最坏落差的失败，恒落在本章可用预算的 8%–12%**。三章逐格校验：ch1 `9 × 10 / 1000` = **9%** ✓ · ch2 `23 × 5 / 1150` = **10.0%** ✓ · ch3 `35 × 10 / 3100` = **11.3%** ✓。
> - **ch2 / ch3 的两格仍是候选值而非定案**——它们随「典型道念差的分布」一同校准，定案见待决问题。

**处 C · `systems/balance.md:819`**（`## 待决问题`）：

> - **`lossPerMomentum` 的 ch2 / ch3 系数（留待内容扩充后的统计校准）：** ch1 = 10 已锁定，**形态与形状锚已定**（一维按篇章、三个 `combatTier` 共用；一次带内最坏落差的失败恒落在本章可用预算的 8%–12%），上表已由该形状解出候选值 **5 / 10**，仍待定案。它被「典型道念差的分布」阻塞——上表的 9 / 23 / 35 是**最坏开局落差**，而最终道念差可能更大。它同时是失败螺旋陡度的旋钮，须与 `experiencePoint` 阈值曲线一同反推。→ `systems/scoring.md`、`systems/character-profile/life-span.md`。

**上游 · `handoffs/2026-09-03-lifespan-cost-table-and-budget-scale.md`：**

- `:41`（正文第五节）——「故三章取 **10 / 5 / 10**（ch2 沿用分数记法「1 / 2 点」的 ×10 形态）。形状锚逐格校验：9×10/1000 = 9% · 23×5/1150 = 10.0% · 35×10/3100 = 11.3%。」
- `:80`（该 handoff **自己的 `## Open questions` 首条**）——「**`lossPerMomentum` 的 ch2 / ch3 定案。** 形状锚已解出候选值 5 / 10，**定案仍待「典型道念差的实际分布」**。」
- `:83`（同一 `## Open questions`）——「**卡牌的道念产 / 削量纲基准**——它同时阻塞 `E[道念差]` 与上面两条。」

### 裁定：**本条不成立（不是三种互斥口径）。**

三处的**实质结论逐格一致**：

| 命题 | 处 A | 处 B | 处 C |
|---|---|---|---|
| ch1 = 10 已锁定 | ✅ | ✅ | ✅ |
| ch2 / ch3 候选值 = 5 / 10 | ✅ | ✅ | ✅ |
| 该两格**尚未定案** | ✅ | ✅ | ✅ |
| 形状锚已逐格校验通过 | 隐含（「已由形状锚解出」） | ✅（写出三个百分比） | ✅ |

**就绪度小节所依据的前提「09-03 的反推已做完」不成立。** 09-03 的 handoff 做完的是 **λ 反推**（21 格 `lifeSpanCost` 定价）与**量纲 ×10 的同步换算**；`lossPerMomentum` ch2 / ch3 的**定案**被该 handoff 自己列进 `## Open questions`（`:80` 逐字如上），且其阻塞源（`:83` 的「卡牌道念产 / 削量纲基准」）正是就绪度小节自己列为 🔴 的「战斗内容本体整体为空」那一条。⇒ **三处措辞不是「未收口」，而是正确地反映了一个仍待定的取值。**

处 C「留待内容扩充后的统计校准」与处 B「随『典型道念差的分布』一同校准」也不冲突——后者是前者的具体阻塞源，处 C 同句内即已写出（「它被『典型道念差的分布』阻塞」）。

### 唯一残余：一处措辞对齐（非矛盾、不改排除面）

处 A 的「**定案待反推**」把阻塞源表述为一次**解析反推**，而处 B / C 一致地表述为**待实测分布**（统计校准）。读者按处 A 会以为「现在坐下来算一算就能定」，实际不能。建议对齐：

`systems/character-profile/life-span.md:54`，仅改末半句：

> - **`lossPerMomentum` 的 ch2 / ch3 系数取值。** ch1 = 10 已锁定；后两章已由形状锚解出候选值 5 / 10（形状锚逐格校验已通过），**定案待「典型道念差的实际分布」实测**，口径见 `systems/balance.md`。

`[既有推演]` —— 措辞与处 B / C 对齐，**不改任何取值、不改排除面**（三处本就一致地判它未定案）。这一处属**可做可不做**：即使不改，derive 的排除面与另两处完全相同。

---

## 条目 ④ — `life-cycle-service.md` 的 `experiencePoint` 待决区措辞未跟上

### 直读证据

**过时侧 · `systems/services/life-cycle-service.md:390`**（`## 待决问题`，行号订正见上）：

> - **`experiencePoint` 的阈值曲线与产出分布。** 载体（新字段、每级一个阈值、事件发经验、失败也给）；**仍待定：各级阈值曲线、单次事件的经验给予量、在事件池中如何分布、失败给的比胜利少多少。** **它与寿元预算的花法互相约束**——事件总数少则单次给予必须更厚。→ `systems/game-progression.md`、`systems/balance.md`。

**四项逐条对照权威侧（全部已定）：**

| 该行称「仍待定」的项 | 权威原句（直读） | 状态 |
|---|---|---|
| **各级阈值曲线** | `balance.md:590-594`：ch1 逐级表「4 4 4 4 4 4 4 4 5 5 5 **8**」+ 公式「`threshold(L) = 4 + floor((L−1)/8)`（L = 1..11），**L = 12 特例取 8**……**ch1 合计 55**。ch2 = **32 / 38 / 44**（合计 114）；ch3 = **38 / 46 / 54**（合计 138）。」 | **已定（三章齐全）** |
| **单次事件的经验给予量** | `balance.md:596`：「给予量以「一次标准事件的成功产出」为基准：`ExperienceGrade { None 0 / Minor 0.5× / Standard 1.0× / Major 1.5× }` 枚举 + 平衡表映射，内容侧不落裸数字。**阈值与给予量同比放大**（ch1 标准 **4** / ch2 **12** / ch3 **16**）」 | **已定** |
| **在事件池中如何分布** | `game-progression.md:49`：「**带经验的产出点约占事件总数 75%（初值）。** 全覆盖会让经验变成「时间的自动函数」……覆盖率过低（< 50%）则玩家为了升级只挑带经验的事件」 | **已定（初值）** |
| **失败给的比胜利少多少** | `balance.md:597`：「**失败 = 同档的 50%**，向下取整、**下限 1**（给了就不能是 0，否则「挫折亦是修行」在数值上落空）」 | **已定** |

另有 `balance.md:585` 的抬头一句，正面宣告本组已离开「未定」状态：

> - **`experiencePoint` 的阈值曲线与给予量（初值 · **曲线形状与量纲已定，统计校准只填值**）。** 模型与分布见 `systems/game-progression.md`；本条只承载数值。

### 裁定：**矛盾成立；`balance.md` / `game-progression.md` 一侧成立，`life-cycle-service.md:390` 是过时残留。**

依据：① 该行自己写着「→ `systems/game-progression.md`、`systems/balance.md`」——**转发链的两个终点都已给出答案**（与条目 ① 同型）；② 时间先后：ch1 曲线由 `handoffs/2026-09-03-lifespan-cost-table-and-budget-scale.md:45`（「ch1 合计 **79 → 55**」）改定，而 `life-cycle-service.md` 该行的措辞早于此批；③ 权威归属：`life-cycle-service` 是**消费方**（走 `ProfileChangeSpec` → `TryApply` 链路），数值权威不在它这里。

### 建议改写文本

`systems/services/life-cycle-service.md:390`，**整条替换**为（保留它唯一仍有效的那半句——与寿元预算互相约束的脆弱反推链，那是本文件视角下真正值得留的风险提示）：

> - **`experiencePoint` 曲线的反推链随时长旋钮失效的风险。** 阈值曲线、给予量（`ExperienceGrade` 四档）、事件池覆盖率与失败折算**四项均已定值**，权威在 `systems/balance.md` 与 `systems/game-progression.md`，本服务只是施加方、不持有取值。**本文件需要留意的只有一条：阈值曲线是事件总数的从属量**——`eventCountLimit` 调整或 `lifeSpanCost` 重定价会让整条曲线失效，须连带重算。→ `systems/balance.md`。

若评审认为这条「风险提示」不属 `## 待决问题`（它不是一个待答问题、而是一条已知的维护纪律），备选处置是 **整条删除**，理由是 `balance.md:601` 已逐字承载它（「**已知风险：反推链是脆的。** 事件总数一变……整条阈值曲线跟着失效。**缓解：把「供给 / 需求比」做成一份可算的校验表**」）。**本草稿倾向后者（整条删除）**——按根约定「活文档只保留最新设计」，在消费方文档留一份风险副本即制造第二权威；`balance.md:601` 是唯一权威且更完整。上面给的替换文本作为「若要保留」的形态备用。

`[既有推演]`。

---

## 条目 ⑤ — `systems/_index.md:45` 残留「敌人 AI 与意图（三档揭示）」

### 直读证据

**过时侧 · `systems/_index.md:45`**（服务导航表的 `combat-service` 行）：

> | └ [combat-service](services/combat-service.md) | 战斗驱动：**固定 10 回合**循环、抽/弃/洗、**敌人 AI 与意图（三档揭示）**；**Practice / Finale 为其变体**。（TurnManager、CharacterManager、EnemyManager；`DeckModule` 为参战方内部第三级组件） |

**上游定案（三处，逐一直读）：**

1. **`decisions/ADR-0059-no-enemy-intent-telegraph.md`（Accepted，2026-08-15）**，标题即「敌人的行动不作任何事前预告；可读性改由六条既有通道分工承担」，`:15`：

   > **敌人的行动不作任何事前预告（承重）。** 本作**不设任何形式的意图预告**——不设揭示档位、不设行动类别标注与内容侧的对应必填字段、不生成回合级行动描述、不设「花代价换情报」的探查通道。

   `:32` 另明确否决了本行残留的那个正是形态：「**只砍篇章分档、保留三档揭示** — 否决：分档本身就是内容成本的来源。」

2. **`ux/combat-ux.md:11`**：

   > **敌人的行动不作任何事前预告（承重）。** **意图区、三档呈现、类别符号体系、综合数值、「预估」视觉提示与偏差对照，全部从战斗屏移除。**

3. **`handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md`**（`ADR-0059` 的来源 handoff）。

**被指向的文档自己也已改完 · `systems/services/combat-service.md:51`**：

> **敌人的行动不作任何事前预告（承重）。** 本服务**不提供任何形式的意图预告**——不设揭示档位、不设行动类别标注、不生成回合级行动描述、不设「花代价换情报」的探查通道。

**规则侧权威 · `systems/adventure-event/combat/_index.md:139`** 同款表述。

**现成的替换文本已存在 · `terminology.md:120`**（同为导航 / 词表性质、已完成同一次改写）：

> | 战斗服务 | combat-service | 服务：**定长回合循环**（回合数与胜负判据是 `EncounterSpec` 的遭遇参数，10 回合 / 「道念高者胜」是 `Standard` 档取值）、抽/弃（**不重洗**，抽空即疲劳）、**双方道念与胜负判定**、**敌人 AI（不作任何事前预告——意图机制已整条移除）**；**`combatTier` 三档共用同一套代码**。（TurnManager、CharacterManager、EnemyManager、**BattlefieldManager**、**StackManager**；`DeckModule` 为第三级组件，每个 character / enemy 一份） |

### 裁定：**矛盾成立；`ADR-0059` 一侧成立，`systems/_index.md:45` 是过时残留。**

依据无需权衡：对立面是一份 **Accepted 的 ADR** 加两份主题文档正文加一份 handoff，而 `systems/_index.md:45` 是一行**导航摘要**（本身不是任何设计的权威）。索引是找文档的第一跳，它写着一个已被整条移除的机制，代价是读者按它去 `combat-service.md` 找「三档揭示」而扑空。

### 建议改写文本

`systems/_index.md:45` 的**描述列**，整格替换（沿用 `terminology.md:120` 的口径，并把该表已过时的 manager 清单一并补齐）：

> 战斗驱动：**固定 10 回合**循环、抽/弃（**不重洗**，抽空即疲劳）、**敌人 AI（不作任何事前预告——意图机制已整条移除）**；**Practice / Finale 为其变体**。（TurnManager、CharacterManager、EnemyManager、**BattlefieldManager**、**StackManager**；`DeckModule` 为参战方内部第三级组件）

**两点提示（均由直读发现，非臆造）：**

- 原格写「抽/弃/**洗**」，而 `terminology.md:120` 与 `combat-service.md` 的口径是「**不重洗**，抽空即疲劳」（来源：`handoffs/2026-08-27-card-pool-and-reshuffle.md`）。**这是同一行里的第二处过时**，建议一并改（上文替换文本已含）。
- `BattlefieldManager` / `StackManager` 两个 manager 见 `combat-service.md:674`（「引入 battlefield（战场）并新增 BattlefieldManager 与 StackManager 两个 manager」），`systems/_index.md:45` 的 manager 清单同样漏登。上文替换文本已补。

### 就绪度小节的一处不精确：**「全库唯一残留的『意图』正面登记」不成立**

对全库（排除 `handoffs/` · `answer-logs/` · `inbox/` · `open-questions*` 四类过程档案）机械检索 `三档揭示|意图揭示|IntentCategory|意图类别|意图区|意图预告|敌人意图`，**另有三处残留**，都以「意图机制存在」为前提：

| # | 文件:行 | 原句（节选） | 性质 |
|---|---|---|---|
| a | `systems/character-profile/deck/_index.md:28` | 「既有 `level`（境界内层级，炼气 1–13 层……）**是敌人意图揭示档的判据**、已登记在 `terminology.md`，**不动**」 | **前提已伪的论据**。该条的结论（功法等级叫「层数 / `TechniqueTier`」，不叫 level）仍成立，但它给出的理由已不存在 |
| b | `systems/character-profile/deck/_index.md:60` | 「**推论 ②：类型是「结算生命周期」的分类，与意图类别（敌人行为的展示分类）正交**——两者共用一套枚举会导致……无解归类」 | **对已不存在对象的正交性论证**。「意图类别」这个分类已不存在 ⇒ 该推论没有对手 |
| c | `systems/character-profile/deck/_index.md:105` | 「敌人牌服务于**可读的对手行为**：**要能被意图汇总成一条结果值**、要能写进图鉴的「关键卡牌」」 | **已伪的设计目标**。「不共用卡池」的结论仍由同句其余两条理由（奖励抽取排除敌方专用牌 · 图鉴关键卡牌）独立支撑 |

（`deck/_index.md:242` 也含「意图」二字，但它是**否定式**表述——「故『买当回合敌人意图』……这类标的**不存在**」——与 `ADR-0059` 一致，**不需要改**。）

三处的建议改写（`[既有推演]`，均为删除已伪的理由、保留仍成立的结论）：

| # | 建议改写 |
|---|---|
| a | 把「是敌人意图揭示档的判据、已登记在 `terminology.md`，**不动**」改为「**已登记在 `terminology.md`，不动**」——理由改由「术语表已登记」独立承担，不再引用已移除的机制 |
| b | 整条推论 ② **删除**（它论证的正交对象已不存在）；若担心日后有人重新提「用 `CardType` 兼作展示分类」，可保留一句收窄版：「**推论 ②：`CardType` 是「结算生命周期」的分类，不兼作任何展示 / 行为分类**——既产道念又削对方道念的牌在后者下无解归类。」 |
| c | 删去「要能被意图汇总成一条结果值、」，其余不动 —— 该分句后的「要能写进图鉴的「关键卡牌」」逐字保留 |

**另有一处不同性质、单列提请裁决 · `vision/references.md:6`**：

> - **借鉴：** 节点地图式的轮回结构；以卡牌构筑为核心 build；回合制、**意图预告（intent-telegraphed）的战斗**；**战后奖励面板的形态**……

这是参考作品（Slay the Spire）的**借鉴项清单**，把「意图预告的战斗」列为本作**借鉴**的东西——与 `ADR-0059` 正面相抵。**裁定（用户已确认）：清单定位为「本作借鉴什么」⇒ 改写为明确偏离**，该分句改为「回合制战斗（**其意图预告一族本作不采用** → `decisions/ADR-0059-no-enemy-intent-telegraph.md`）」。依据：`references.md` 位于 `vision/`，其读者是拿它当方向输入的人；一条会被误读为设计意图的参考描述，其代价与 `systems/_index.md:45` 同型（索引 / 方向层的一句话，比正文里的一句话传播得远）。改写只需一个括号从句，不改该条其余部分。

---

## 具体形态（可 derive 的落地面）

五条合计 **13 处**文本改动，**零字段 / 零签名 / 零 schema / 零存档迁移 / 零代码**。逐条列出：

| # | 条目 | 文件 | 位置 | 动作 | 要点 |
|---|---|---|---|---|---|
| 1 | ① | `systems/adventure-event/exchange/common-properties.md` | `:213` | 改 | 四组待定 → 两组（刷新价参数 · 槽位上界），另两组标「已有初值」 |
| 2 | ① | `systems/adventure-event/exchange/common-properties.md` | `:203`（`Source:` 行） | 增 | 补 `handoffs/2026-09-05-currency-acquisition-and-pricing.md` |
| 3 | ② | `systems/services/combat-service.md` | `:591` | 改 | 三类混合 → 四类混合 + `Practice` 档整族排除 `PowerData` |
| 4 | ② | `systems/services/combat-service.md` | `:592` 后 | 增 | 新增「神通候选的两条口径」子条（档位闸 · 已持有排除 · `AbilityChangeElement` 形态） |
| 5 | ② | `systems/services/combat-service.md` | `:598` | 改 | 三档差异补上「`Practice` 对 `PowerData` 的整族排除」 |
| 6 | ② | `systems/balance.md` | `:816` | 改 | 战后奖励池族维度 三类 → 四类（神通列只在两张表上非空） |
| 7 | ③ | `systems/character-profile/life-span.md` | `:54` | 改（可选） | 「定案待反推」→「定案待典型道念差的实际分布实测」 |
| 8 | ④ | `systems/services/life-cycle-service.md` | `:390` | **删**（备选：改） | 四项均已定 ⇒ 整条移出待决区；风险提示由 `balance.md:601` 独占 |
| 9 | ⑤ | `systems/_index.md` | `:45` | 改 | 删「意图（三档揭示）」· 「抽/弃/洗」→「抽/弃（不重洗）」· 补两个 manager |
| 10 | ⑤ | `systems/character-profile/deck/_index.md` | `:28` | 改 | 删「是敌人意图揭示档的判据」 |
| 11 | ⑤ | `systems/character-profile/deck/_index.md` | `:60` | 改 / 删 | 推论 ② 删除或收窄为「不兼作任何展示 / 行为分类」 |
| 12 | ⑤ | `systems/character-profile/deck/_index.md` | `:105` | 改 | 删「要能被意图汇总成一条结果值、」 |
| 13 | ⑤ | `vision/references.md` | `:6` | 改 | 「意图预告（intent-telegraphed）的战斗」→「回合制战斗（其意图预告一族本作不采用 → `decisions/ADR-0059-no-enemy-intent-telegraph.md`）」 |

**`open-questions.md` 的「derive 就绪度」小节不在本清单内**——该小节由 `/assess-derive-readiness` 独占写入，五条登记在下一次全量评估时自然消失；`/analyze-new-ideas` **不得**去改它。

**均不需要新增 `Source:` 行**，唯一的 `Source:` 改动是第 2 项（且它是同批遗漏的补登，非新增溯源）。

---

## 后果

- **零代码后果。** 无字段、无签名、无 schema、无存档迁移、无 RNG 子流变更；`game-feature-branch/` 不受影响（这些系统均无实现）。
- **derive 排除面的净变化（本草稿的实际价值）：**
  - 条目 ① ⇒ `exchange/common-properties.md` 的排除面由「四组数值全欠」收窄为「两组」，且两组均不承重（刷新价首批填 0 即整条关闭）。
  - 条目 ② ⇒ **derive 第 23 步（战后奖励）的候选生成器落笔形态改变**：四族而非三族，且带一个档位闸。这是五条里唯一有实质结构后果的一条。
  - 条目 ④ ⇒ `life-cycle-service.md` 的排除面减一项（原本会被高估为「经验四项全欠」）。
  - 条目 ⑤ ⇒ 索引与三处论据不再指向一个已移除的机制；无排除面变化，但避免了按已否决前提写验收标准。
  - 条目 ③ ⇒ **无变化**（三处口径本就一致），第 7 项改动纯属措辞对齐。
- **对 `/audit-content` 无影响。**
- **对内容侧的实际指示（条目 ②）：** `content/character-power/` 开张时，其条目须被编入 `Standard` / `Finale` 档的 `RewardPoolId` 池；`Practice` 档的池不得含 `PowerData` 条目（或由生成侧的族级排除兜底——本草稿建议后者，因为它是机械保证而非编排纪律）。

---

## 备选方案（已考虑并否决）

- **条目 ①：反过来把 `exchange/_index.md:170` 与 `balance.md:814` 撤回「四组全欠」** — 否决。那要同时推翻 `balance.md:361` 的 25 格表、`:302`/`:303` 的两档回收率与 `:371` 的外积推导，以及 09-05 handoff 的整批落笔。
- **条目 ②：反过来把 `power/_index.md:73` 的 `CombatReward` 通道关掉，让神通只走 `InitialGrant` + `ExchangePurchase`** — 否决。① 它推翻两份 Accepted ADR（`ADR-0152` / `ADR-0153`）与 09-03 handoff；② `power/_index.md:81` 的「首批 5 条即可让 `CombatReward` / `ExchangePurchase` / 置换换入三条通道非空」这条论证会当场失效，「条目数下限 ≥ 5」随之失去依据；③ `power/common-properties.md:12` 的合法 `Source` 表要同改。
- **条目 ②：让神通走 `OutcomeRule.Kind == GrantFromPool` 而不进战斗奖励面板** — 否决（且它在结构上就写不出来）。按 `systems/common-properties.md:279` 的「谁组装出这条 element」判据，走 outcome 的授予记 `Source.EventOutcome` 而非 `CombatReward`；而 `power/_index.md:73` 首批口径明写 `EventOutcome`「保留机制、零条目」。
- **条目 ③：强行把三处「统一收口」为已定案（填死 5 / 10）** — 否决。09-03 handoff 的 `## Open questions:80` 与 `:83` 明写它被「典型道念差的实际分布」阻塞，而后者又被「卡牌道念产 / 削量纲基准」阻塞（就绪度小节自己列为 🔴）。把候选值当定案写下去，就是用臆造的前提填满一个真空缺。
- **条目 ④：保留原行但在末尾加一句「以上四项已定，见 balance.md」** — 否决。那是「原为未定 / 已被 X 答定」型的考古注释，与根约定「活文档只保留最新设计（重写替换，不留考古）」直接相抵。
- **条目 ⑤：只改 `systems/_index.md:45`，`deck/_index.md` 三处不动** — 否决。三处都以「意图机制存在」为前提，其中 a 与 c 是**论据**——留着它们，日后有人核对论证链时会去找一个不存在的机制，且可能据此把机制「补回来」。这正是本项目已经踩过的那个坑（同型：`solution-draft-enemy-momentum-scaling.md` 记录的「登记 → 答结归档 → 再度登记」一个来回）。

---

## 与既有决策的张力

**无。**

五条（含判为不成立的第 ③ 条）都不要求任何既有决策松动。四条成立的裁定方向**全部是把偏离既有决策的残留措辞拉回一致**：条目 ① 拉回 `ADR-0133`~`ADR-0135` 与 09-05 落笔；条目 ② 拉回 `ADR-0152` / `ADR-0153`；条目 ④ 拉回 09-03 的经验曲线重算；条目 ⑤ 拉回 `ADR-0059`。收口后各自的推导链比现在更完整。

**唯一需要点明的一处非张力：** 条目 ② 的改动会让 `combat-service.md` 的候选生成路径**首次出现族级的档位差异**（`Practice` 排除 `PowerData`），而该文件 `:598` 原本以「三档共用同一条生成路径」为一条简洁性主张。这不是张力而是**该主张的精确化**——`power/_index.md:73` 已给出这条差异的完整理由（「最轻一档也掉神通会把这条获取面稀释成常规掉落」），且差异只在候选族的一次过滤，代码路径仍是同一条。

---

## 前置依赖

**四条成立项（① ② ④ ⑤）：无前置依赖**，可立即落笔。

**第 ③ 条（判为不成立）：** `lossPerMomentum` ch2 / ch3 的**定案**依赖两级仍待答的问题——「典型道念差的实际分布」← 「卡牌的道念产 / 削量纲基准」（后者属就绪度小节列出的 🔴「战斗内容本体整体为空」）。本草稿**不试图**关闭它，只建议一处措辞对齐（第 7 项，可做可不做）。

**条目 ② 的下游提示（不是前置）：** `balance.md:816` 仍待定的「战后奖励池各档权重」在改为四族后，神通列的权重取值同样待内容扩充后的统计校准——本草稿只改族维度的**结构**，不给任何权重数字。

