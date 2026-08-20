---
type: solution-draft
date: 2026-08-18
question: `PickMany` 抽不足 `count` 时，Research 候选与 Exchange 库存两个调用侧各如何处置？两处都不能留空面板。
source: open-questions/02-event-options.md → 「`PickMany` 抽不足 `count` 时的调用侧处置未定（08-17 新增 · 轻）」
targets: systems/adventure-event/research/common-properties.md · systems/adventure-event/exchange/common-properties.md · systems/adventure-event/exchange/_index.md · systems/services/future-event-service.md · systems/services/content-service.md · systems/services/profile-service.md · systems/balance.md
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-pickmany-shortfall-handling.md
---

# 方案 — `PickMany` 抽不足 `count` 的两个调用侧处置

## 问题

抽取原语一侧已定案：**`PickMany(rng, count)` 无放回；数量不足 `count` 时按可选缺失处理（返回 `false` + `PushWarning`），不静默少给**（`systems/services/content-service.md`「两条契约由授予池这个调用方定死」）。

但这只回答了「原语不假装成功」，没有回答**调用侧拿到 `false` 之后干什么**。两个调用点各欠一个处置：

1. **Research 构筑面板的候选** —— `ResearchSlotSpec.CandidateCount` 条候选，其中两类走内容池（`LearnTechnique` 走 `CultivationTechniqueData` 池、`GrantItem` 走 `TryPickGrantableMany(Item, Character, rng, 3)`）。
2. **Exchange 的库存** —— 每条 `ExchangeStockRule` 按 `Kind` + `RarityFilter` 抽 `SlotCount` 条 offer。

硬约束：**两处都不能留空面板。** 一个零候选的构筑槽 / 一个零商品的商店，是玩家付了 `lifeSpanCost` 进来之后撞上的空屏——而 Research 是**轮回内构筑的唯一落点**。

同时它有一个**已经解决过一遍的同类先例**：`systems/monetization.md` 的**空池三道闸**（加载期 `PushError` / 购买入口拦截 / 兑现处报错不补发）。本方案的主线就是「照三道闸的体例推演，逐闸给出本处该填什么」，并明写**为什么本处的失败处置与礼包相反**。

## 约束（来自既有设计）

- **产出侧唯一取池入口 = `AllEnabled()`**；抽取动作只能从 `DrawPool<T>` 发起。→ `systems/services/content-service.md`、`.claude/rules/data-resource-rules.md`。
- **抽取原语只有两级**：`DrawPool<T>`（内容侧过滤）与 `GrantPoolPicker`（需读 `Profile` 的过滤，如排除已持有）。**不设第三级**，本方案不得引入新的抽取原语。→ 同上。
- **物化产出的数值必进快照；产出即定稿、消费侧不得回查模板重算；恢复即读结果，绝不重走取池链。** → `systems/services/future-event-service.md`、`systems/adventure-event/exchange/_index.md`。
- **防重掷纪律**：候选 / 库存必须在物化那一刻算定并落存档，否则退出重进可重掷。→ 同上。
- **坏数据在启动期大声失败**（合并后强校验 `PushError`）；**flags 是运行期通道、不参与加载期校验**，故加载期通过 ≠ 运行期池足够。→ `systems/services/content-service.md`。
- **`CandidateCount` 已明写「是上界不是保证」**，且 `AllowDecline` 默认 `true`。→ `systems/adventure-event/research/common-properties.md`。
- **Exchange 加载期已有一条**：`Kind` 对应的抽取池在 `RarityFilter` 过滤后为空 → `PushError`（「否则会在轮回中途开出一个空商店」）。→ `systems/adventure-event/exchange/common-properties.md`。
- **空池是运营事故，不是玩法分支——不为它设计兜底玩法。** → `systems/monetization.md`。
- **两种失败语义**：必需缺失 → `PushError` + 退出；可选缺失 → `PushWarning` + 安全默认值。→ `.claude/rules/null-check-rules.md`。
- **灰态判据**：灰态禁令只适用于「玩家可能有意选择的失败」，不适用于「必然无结果的操作」。→ `ux/error-and-blocking-ux.md`。

## 建议方案

### 0. 先补一条原语侧的契约细化：`out` 参数在部分成功时带回已抽到的那几条

`[既有推演]`

两个调用侧的一切「降级到更少」处置，前提都是**拿得到那几条已抽出的结果**。故建议把契约那句话的落地形态写明：

```csharp
// DrawPool<T> 与 GrantPoolPicker 门面同款语义
bool PickMany<TRng>(TRng rng, int count, out IReadOnlyList<T> picked);
//   池 ≥ count           → true，picked.Count == count
//   0 < 池 < count       → false + PushWarning，picked = 池中全部（无放回、已加权），picked.Count == 池大小
//   池 == 0              → false + PushWarning，picked = 空列表（非 null）
```

- **「不静默少给」防的是「原语返回 `true` 却少给几条」**，即调用方在不知情的情况下拿到短缺结果。返回 `false` + 告警已经完成了「不静默」；把已抽出的结果一并交出，**不削弱它分毫**，反而让调用方能一次性做出正确降级。
- **反例（`false` 时 `picked` 恒为空）的代价**：调用侧只能「先数一次池、再用较小的 `count` 抽第二次」，于是同一条取池链在同一次物化里跑两遍，且两次之间消耗的 RNG 次数依赖于池大小 —— 与「抽取代码的落点恰好两处」和确定性纪律都不友好。
- 该细化落 `systems/services/content-service.md` 的 `DrawPool<T>` 契约与 `systems/services/profile-service.md` 的 `TryPickGrantableMany` 那一行（后者的失败语义列当前写的是「同上，含『不足 count』的部分情形」，正好在此处补全「部分」二字的含义）。

### 1. 复用 monetization 的三道闸体例，但**逐闸内容按本处重填**，且**失败处置方向相反**

`[既有推演]`

**采用三道闸的体例**（加载期硬校验 / 取池期前置拦截 / 运行期兜底），这是本库对「空池」这类问题已经成熟的分层，不另起体例。

**但三道闸的失败处置在本处与礼包相反，判据必须写下来**（否则后来者会把两处读成矛盾——与 `ux/error-and-blocking-ux.md`「灰态判据」那一节同形）：

> **分界判据：玩家有没有为这一次产出付过钱。**
> 付过钱（premium bundle）→ **少给即事故**，把失败点前移到掏钱之前，宁可拒绝进入流程，绝不降级替代。
> 没付钱、是玩法内容（Research 候选 / Exchange 库存）→ **降级到更少是可接受的方差**，硬拒绝反而制造更严重的后果：Research 是构筑的**唯一落点**，把它整类拦掉等于剥夺轮回内构筑；把一批 eventOptions 拦成空批则直接触及**轮回死锁**（这正是 `LocationData` 恒启用那条论证所防的同一类事故）。

### 2. 闸的完整形态（两个调用点共用同一层次，逐格取值不同）

`[既有推演]`

| 闸 | 时机 | Research | Exchange | 失败处置 |
|---|---|---|---|---|
| **①** | **内容加载期**（合并后强校验，走 `AllIncludingDisabled()` 的同一遍） | 每个 `ResearchSlotSpec`：`AllowedOperations` 中每一类**内容池型**操作（`LearnTechnique` / `GrantItem`）所对应的**通用池**条目数 ≥ `CandidateCount` + 余量 | 每条 `ExchangeStockRule`：`Kind` + `RarityFilter` 过滤后的池条目数 ≥ `SlotCount` + 余量；**同 `Kind` + 同 `RarityFilter` 的多条规则按 `SlotCount` 之和判**（同批无放回，它们抢同一个池） | **`PushError`** + `EventId` + 槽序号 / 规则序号 + 该池的 `Kind` 与实际条目数。内容侧硬保证的机械化 |
| **②** | **取池期**（future-event-service 挑候选事件条目、物化之前） | 该 Research 条目的**至少一个槽**能产出 ≥ 1 条候选 | 该 Exchange 条目的 `ExchangeStock` 能产出 ≥ 1 条 offer | **该条目本次不进候选池**（`PushWarning` + 定位上下文）。**这是「不能留空面板」的真正防线** |
| **③** | **物化期**（实际抽取，`PickMany` 返回 `false`） | 该槽候选数降级为实际抽到的条数；某槽降到 0 → **该槽整槽不产出**（不进 `ResearchSlot[]`） | 该规则少产出几个 offer；某规则降到 0 → 少一批槽位 | `PushWarning` + want / got。**全部槽 / 全部 offer 皆空 = 理论不可达（② 已拦）→ `PushError` + 上报**，该条目本次作废、由 future-event-service 另取一条填补批次 |

**闸 ② 是本方案的承重，它与既有的 Explore 壳过滤完全同构。** `systems/services/future-event-service.md` 已定：「真身被 `ContentEnabled == false` 关闭 ⇒ 该 Explore 壳本次不进候选池，判定与 `AllEnabled()` 同一档，在取池阶段做一次」。本条是同一形状的第二个实例 —— 同样是**取池阶段的一次判定、不落快照、防的同样是「加载期够不着的运行期收缩」**（flags 秒关、玩家已持有导致的池收缩）。

- **闸 ② 需要的计数能力全部现成、零新增接口**：能力族用 `ProfileService.GrantableCount(kind, scope)`（礼包闸 ② 已在用它）；内容族用 `DrawPool<T>` 过滤后的 `Count`。
- **代价明写：** eventOptions 每批产 3–5 项、只发生在屏幕切换点，逐候选条目算一次池计数不落在任何热路径上。
- **闸 ② 的判据取「≥ 1」而不是「≥ 所需」**：取「≥ 所需」会让一次轻微的运行期收缩把整类事件从池里删掉（Research 尤其致命）；取「≥ 1」只兑现硬约束本身——**不留空面板**，其余交给闸 ③ 降级。

### 3. Research 侧的逐情形行为

`[既有推演]`

| 情形 | 行为 |
|---|---|
| 某类操作抽到 **0** 条候选 | 该操作**不进本槽候选**（与既定的「一门都没有则该操作不进候选」同句处置，只是把它从「升阶候选」推广到内容池型两类） |
| 某类操作抽到 **0 < n < 所需** | 给几条算几条 —— **这是 `CandidateCount` 已明写的「上界不是保证」的直接兑现，不是新规则** |
| **整槽候选为 0** | 该槽不进 `ResearchSlot[]`；事件照常物化（其余槽仍有候选） |
| **全部槽皆为 0** | 闸 ② 已拦，到达此处 = 缺陷 → `PushError` + 上报，该条目本次不进批次 |

- **不能留空面板在 Research 侧的兑现 = 闸 ② + 空槽剔除**：面板上呈现的槽必然至少有 1 条候选，配合默认 `AllowDecline = true`，玩家永远有一个可执行的动作。
- **开局构筑事件（两槽 `AllowDecline = false`）是唯一需要额外一句的条目**：它靠 `eventPriority = 1` 强制进入，若它的任一槽降到 0 候选，玩家会被卡在一个无法提交的强制面板上。故**闸 ② 对 `AllowDecline == false` 的槽收紧为「该槽必须能产出 ≥ 1 条候选」**；不满足 → `PushError` + 上报（它是加载期闸 ① 本该拦住的编排错误，运行期唯一可能的成因是 flags 把功法 / 法宝池关到见底，属运营事故）。

### 4. Exchange 侧的逐情形行为

`[既有推演]`

| 情形 | 行为 |
|---|---|
| 某条 `StockRule` 抽到 **0** 条 | 该规则贡献 0 个槽位，其余规则照常 |
| 某条 `StockRule` 抽到 **0 < n < `SlotCount`** | 该规则产出 n 个 offer，**不补位、不用别的族顶替** |
| **整店 `ExchangeStock` 为空** | 闸 ② 已拦，到达此处 = 缺陷 → `PushError` + 上报，该条目本次不进批次 |

- **不设兜底商品 / 保底 offer。** 直接引自 `systems/monetization.md`：「空池是运营事故，不是玩法分支——不为它设计兜底玩法」。一件为空池而生的保底商品必须有 `Id`、有定价、有稀有度，且它会在**正常**库存里也被抽到（除非再加一条 `ExclusiveSource` 式的准入标记），代价远大于收益。
- **不因库存少而下调刷新价 / 免除刷新费。** 刷新价公式已定（`RerollBaseCost + RerollCostStep × 已刷新次数`），为短缺开一条折扣分支会给「刷新价与新库存必须落在同一次 `TryApply`」那条承重再加一个变量。玩家的救济通道就是既有的刷新本身。
- **售出面不受影响**：`SellEnabled` / `SellRatePercent` 与库存抽取无关，一个只剩 1 件商品的店照常收购。

### 5. 落存档：记实际结果，不记「本该有几个」

`[既有推演]`

- **`EventOption.ExchangeStock` 的长度就是实际抽到的 offer 数**（可 < Σ`SlotCount`）；**`ResearchSlot.Candidates` 的长度就是实际候选数**（可 < `CandidateCount`）。
- **不新增任何「期望数量 / 短缺标记」字段，不 bump schema、无迁移。** 期望值在模板上（`SlotCount` / `CandidateCount`）随时读得到，落一份进快照就是无用中间态——与「模板上的 outcome / effect 定义不进快照」同一条判据。
- **恢复即读结果，绝不重走取池链**（既定纪律）。**推论必须明写：一个因池收缩而少给的商店 / 面板，在退出重进后仍然少给** —— 即便此刻 flags 已把条目放回来。这正是防重掷纪律要的行为，**不是 bug**。
- **RNG 侧无特殊处理**：短缺时 `PickMany` 消耗的抽取次数照常由 `DrawCount` / `State` 持久化，确定性不受影响。

### 6. 日志与告警形态

`[既有推演]` · 沿用 `[System-Method]` 约定

```
# 闸 ①（加载期，PushError + 抛）
[ContentRegistry-Validate] research pool short: event=<EventId> slot=<SlotIndex> op=<DeckOperationKind> need=<CandidateCount+margin> pool=<n>
[ContentRegistry-Validate] exchange pool short: event=<EventId> rule=<i> kind=<ExchangeGoodsKind> rarity=<filter> need=<ΣSlotCount+margin> pool=<n>

# 闸 ②（取池期，PushWarning）
[FutureEvent-PoolGate] skip event=<EventId> type=<Research|Exchange> reason=insufficient-pool detail=<kind/slot> pool=<n>

# 闸 ③（物化期，PushWarning）
[FutureEvent-ResearchSlot] instance=<InstanceId> event=<EventId> slot=<SlotIndex> op=<Kind> want=<n> got=<m>
[FutureEvent-ExchangeStock] instance=<InstanceId> event=<EventId> rule=<i> kind=<Kind> want=<n> got=<m>

# 闸 ③ 的不可达分支（PushError + 上报）
[FutureEvent-Materialize] empty panel: instance=<InstanceId> event=<EventId> type=<Research|Exchange> —— gate② should have filtered
```

- **告警要落在能被看见的地方**（本库既有判据）：闸 ① 落内容加载侧（编排错误在启动 / 编辑期被看见）；闸 ②③ 落玩家进程，但因为它们的成因是**运行期收缩**（flags / 已持有），除此之外无处可落。
- **闸 ② 用 `PushWarning` 而非 `PushError`**：flags 秒关是既定的正常运营手段，一个条目因此暂时退出候选池不是缺陷。**闸 ③ 的空面板分支用 `PushError`**：它意味着闸 ② 判定与实际抽取不一致，是真缺陷。

### 7. UI 侧：无灰态、无「本店缺货」提示

`[已定案]` —— 取 A：**完全不提示**，详见 `## 用户裁决（2026-08-19 · 全部定案）` 第 3 项。玩家看到的就是一个商品少一点的店 / 候选少一点的槽，它与内容作者编排出的小店在观感上无法区分，也不需要区分。按灰态判据，这里既没有「玩家可能有意选择的失败」也没有「必然无结果的操作」——根本没有可点的东西，故两条都不适用。

## 具体形态（可 derive 的落地面）

**契约细化（`systems/services/content-service.md` · `systems/services/profile-service.md`）**

| 方法 | 短缺时 |
|---|---|
| `bool PickMany<TRng>(TRng rng, int count, out IReadOnlyList<T> picked)` | `false` + `PushWarning`；`picked` = 池中全部（可为空列表，**永不为 `null`**） |
| `bool TryPickGrantableMany<TRng>(AbilityKind, AbilityScope, TRng rng, int count, out IReadOnlyList<string> pickedIds)` | 同上 |

**新增校验（加载期 · `PushError`）**

| # | 落点 | 断言 |
|---|---|---|
| R1 | `research/common-properties.md` 校验表 | 每个 `ResearchSlotSpec` 的每类内容池型操作：通用池条目数 ≥ `CandidateCount` + 余量 |
| E1 | `exchange/common-properties.md` 校验表（**收紧既有那一行**） | 同 `Kind` + `RarityFilter` 的 Σ`SlotCount` + 余量 ≤ 过滤后池条目数（原为「过滤后为空 → `PushError`」） |

**新增取池期过滤（`systems/services/future-event-service.md`，与 Explore 壳过滤并列一条）**

```
候选条目取池阶段，对每个 Research / Exchange 候选条目：
  Research → 至少一个槽的候选池 ≥ 1；AllowDecline == false 的槽逐槽 ≥ 1
  Exchange → 全部 StockRule 的可产出 offer 数之和 ≥ 1
  不满足 ⇒ 该条目本次不进候选池（PushWarning）；不落快照
```

**新增平衡数值（`systems/balance.md`）**

| 参数 | 语义 | 取值 |
|---|---|---|
| `ResearchPoolMargin` | 闸 ① 在 `CandidateCount` 之上要求的池余量 | **待定，归 ch1 数值标杆专场** |
| `ExchangePoolMargin` | 闸 ① 在 Σ`SlotCount` 之上要求的池余量 | 同上 |

> 余量之所以必须存在（而不是只断言「≥ 所需」）：两条取池链都含**排除已持有**，池会随玩家推进单调收缩；一个恰好等于所需的静态池，在轮回中段必然短缺。形态与 `GrantPoolMargin` 同族，但**不复用同一个值**（用途不同），是否合表见待定项第 2 条。

## 后果

- **改动面 6 份文档**：两份契约（`content-service.md` / `profile-service.md` 的 `out` 语义）、两份子类型 common-properties（校验表）、`future-event-service.md`（取池期过滤 + 物化期降级 + 日志）、`balance.md`（两格余量）。
- **存档 schema 零改动、零迁移**：不新增字段，只是既有列表字段的长度可以更短。
- **对 `EventOption` 的物化字段面零改动**；对 `PastEventEntry` 零影响（`ExchangeStock` 本就不进痕迹侧）。
- **对确定性零影响**：不改变 RNG 子流的划分与消耗记账方式。
- **内容侧多两条启动期硬校验**，当前内容存量为零 ⇒ 落地代价为零；晚做则每多一个 `.tres` 多一份返工。

## 备选方案（已考虑并否决）

- **短缺时用别的操作类型 / 别的商品族补满槽位。** 需要一套跨来源的配额分配算法（谁补、补多少、权重怎么算）——是新机制，而本条问题被标为「轻」。且它会让「这个槽是干什么的」变得不可预期（一个限定 `LearnTechnique` 的槽突然冒出法宝）。
- **设保底商品 / 保底候选条目。** 撞「空池是运营事故，不是玩法分支——不为它设计兜底玩法」；且保底条目本身要 `Id` / 定价 / 稀有度，还要一条准入标记把它挡在正常抽取之外，成本远大于收益。
- **短缺时改用有放回抽取补足数量。** 直接推翻「`PickMany` 无放回」这条已定契约（它正是为「礼包 2 件必须不同」写下的），且会在面板上出现两个一模一样的候选 / 两件一模一样的商品。
- **在结算 / 面板打开时重新抽取补足。** 推翻防重掷纪律：玩家退出重进即可重掷候选。
- **短缺即整个事件条目改判为不可选 / 灰态。** 撞灰态判据（这不是「玩家可能有意选择的失败」，玩家根本不知道池的状态），且拦得太晚——闸 ② 在取池期解决同一问题且不产生任何玩家可见的异常态。
- **只在物化处报错、不做取池期前置拦截。** 正是 monetization 明写否决过的那一条（「让玩家在付款之后才撞上失败，是最糟的失败时机」）的同构形态：让玩家付了 `lifeSpanCost` 之后才撞上空面板。

## 与既有决策的张力

1. **「不静默少给」的读法（需用户确认）。** 本方案第 0 节把 `out` 参数在部分成功时定为**带回已抽到的那几条**。若「不静默少给」被理解为「短缺时一条都不给、由调用方自行重来」，则第 0 节需改写，两个调用侧各多一次「先数池、再用较小 `count` 重抽」的代码路径。**建议按前者细化**——「不静默」的承重在 `false` + 告警，不在丢弃已有结果。
2. **与 monetization 三道闸的处置方向相反。** 礼包明写「不补发、不折价、不降级替代」，本方案则明写「降级到更少」。**这不是打架，但必须在两处都写下分界判据**（玩家有没有付过钱），否则本库会出现第二组「看似相反的规则」而无人给出边界——这正是 `ux/error-and-blocking-ux.md`「灰态判据」那一节存在的理由。建议在 `monetization.md` 的三道闸小节补一句回链。
3. **Exchange 加载期校验被收紧**（从「过滤后为空」到「≥ Σ`SlotCount` + 余量」）。这是纯收紧、方向一致，但它会让编排更容易在启动期失败。当前无内容 ⇒ 零代价；写进文档时应明写这是有意的收紧。

## 前置依赖

- ~~**「满袋时能否购买道具」**~~ → **已答定（2026-08-19）：满袋时不能购买道具**，处置为**购买前置校验拦截（拒收）**，**不是库存侧过滤**。
  **对本方案的连带：闸 ①② 的池计数口径不含任何「满袋过滤」，余量取值无需上调，「池计数含哪几道过滤」这一句照本方案原样落笔即可。**
  该定案本身归 `systems/character-profile/item/_index.md`（本方案不写它），此处只记录它对池计数口径的影响已归零。
- **`ResearchPoolMargin` / `ExchangePoolMargin` 的取值**（ch1 数值标杆专场）。形态在本方案内定稿，取值不定不阻塞落地（可先填 0 并留 TODO，与「首批内容默认关闭 reroll」同一种偏好）。
- **Exchange 槽位总数上界的取值**（同上）。它与闸 ① 是同一张表的两行，宜同批填。

## 用户裁决（2026-08-19 · 全部定案）

**五项取向全部按本方案的推荐定案，逐条无保留采纳。** 本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| 1 | `PickMany` 短缺时 `out` 参数的语义 | **取 A** —— 返回 `false` + `PushWarning`，`picked` 带回池中全部已抽出的条目（**可为空列表，永不为 `null`**） | 「不静默少给」防的是**原语假装成功**，`false` + 告警已完整兑现；丢弃已抽出的结果不增加任何安全性，只增加一条代码路径与一份确定性上的复杂度 |
| 2 | 余量参数的形态 | **取 A** —— 新设 `ResearchPoolMargin` / `ExchangePoolMargin` 两格，与 `GrantPoolMargin` 同表不同值 | 三处用途量级差异明显（防退款争议 vs 防商店冷清），焊在同一个数上则调其一必动其二；C（不设余量）的失败模式已被 monetization 的余量设计预演过 |
| 3 | 短缺时是否给玩家可见提示 | **取 A** —— **完全不提示**，零 UI 改动、零文案键 | 直接落在「空池是运营事故，不是玩法分支——不为它设计兜底玩法」之内；B 只是把兜底玩法从机制层挪到呈现层，同一判据同样适用 |
| 4 | 开局构筑事件（`AllowDecline == false`）的短缺处置 | **取 A** —— 闸 ② 对该类槽逐槽收紧为「必须 ≥ 1 条候选」，不满足则 `PushError` + 上报、该条目不进批次 | B 用「静默改写一条内容侧的强约束」换「不缺席」，而开局底盘残缺的后果贯穿整个轮回；A 的失败面是一次**可见**的运营事故，符合「大声失败」 |
| 5 | 闸 ② 的判据阈值 | **取 A** —— `≥ 1`（只兑现「不留空面板」这条硬约束，其余交给闸 ③ 降级） | 硬约束原文是「不能留空面板」，不是「面板必须是满的」；B 用更强的拦截换一个更严重的失败模式（一次轻微收缩即把整类事件从候选池删掉，并静默改变类型分布） |

**取 4A 留下的那个连带问题，一并定案：** 开局强制构筑事件（`eventPriority = 1`）因池见底而缺席时，**开局流程仍然成立**——首批退化为常规批，轮回照常开始。它是一次**大声失败的运营事故**（`PushError` + 上报），不是需要设计兜底玩法的分支；这与取向 3「不为运营事故设计玩家可见的兜底」同一条判据。**不为此新增任何降级路径或补发机制。**

**满袋前置依赖已解除**（见 `## 前置依赖`）：满袋定为**购买前置校验拦截**而非库存侧过滤 ⇒ 池计数口径不受影响，本方案零改动。

## 越界发现

以下属相邻问题，本方案只记录、不处理：

- **`ResearchPoolMargin` / `ExchangePoolMargin` / 槽位总数上界 / 定价表各格的具体取值** —— 归 ch1 数值标杆专场（`systems/balance.md`）。本方案只定形态与它们必须存在的理由。
- **eventOptions 的上游生成 / 加权运算形态**（类型修正的乘性 / 加性、多条 `PlotModulation` 与 location 修正的合并算法、批次规模区间两端由什么驱动）—— 闸 ② 会把个别条目移出候选池，因而与「类型配比」这条待答项有交互面（少一个 Exchange 条目会轻微改变类型分布），但合并算法本身不在本方案范围内。
- **满袋时能否购买道具**（`systems/character-profile/item/_index.md`）—— 已列入本方案的 `## 前置依赖`，它只影响「池计数含哪几道过滤」这一句，不影响闸的层次。
- **构筑面板与商店的竖屏呈现形态 / 风险档的视觉标注** —— `ux/screen-flow.md` 的既有待答项；本方案第 7 节只表态「不新增提示」，不涉及布局。
