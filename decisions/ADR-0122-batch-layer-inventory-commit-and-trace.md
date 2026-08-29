# ADR-0122 — 批次层的储物袋操作不是决策点而是一次即时提交；补 `ItemElements` / `ItemUseElements` 两列与 `pastItemUse` 序列

- **状态：** Accepted
- **日期：** 2026-08-28
- **来源：** handoffs/2026-08-28-out-of-combat-item-use-savepoint-and-trace.md

## 背景

战斗外用一件道具发生在**批次层**——不在任何事件内，没有状态机在推进。既有的两套框架都答不了它：决策点清单全是事件内清单；而 `ProfileChangeSpec` 的各列没有一列装得下「扣一份实例的次数」，`pastEvent` 也挂不上一次事件之外的使用。

## 决策

**一次使用不构成决策点，但构成一次即时提交**：一次 `TryApply` ⇒ 一次本地原子写。它**不进任何既有决策点清单**；**不触发 `RefreshAfterEvent`**；**照跑终态判定**；**不计软阻塞闸门**。随售同属批次层，同款处置。

**push 走 `PushPolicy.Debounced`，`SavePointReason` 增第六个成员 `InventoryChanged`**（同时覆盖随售）；唯一例外是使用致资源触底判负后走既有 `defeated` 的 `Immediate`。

**`ProfileChangeSpec` 新增 `ItemElements`** 承载 `Charges` 扣减：`ItemChargeElement(AbilityScope Scope, string ItemId, int Delta)`；实例选取是**纯函数**（同 `(Scope, ItemId)` 中 `Charges > 0` 且最小者，并列取存档列表靠前者，`-1` 不参与）；**首批只开消耗向**；**恒不经 modifier pipeline**；**`SelectCost` 内恒为空**。

**痕迹落新序列 `CharacterProfile.pastItemUse`**，经新增列 `ItemUseElements` 写入：`ItemUseEntry(Seq, AfterEventSeq, ItemId, Scope, AppliedChange)` **五字段、不带任何派生量**，与 `pastEvent` **分列两条序列**，不设条数硬上限。

**不新增任何 `Source` 成员。** **无限次可用的战斗外道具由一条加载期校验关掉**（`Charges == -1` 且 `UsableScene` 含 `OutOfCombat` → `PushError`）。

**一次 schema bump，空迁移。** 列语义与入口校验 → `systems/services/profile-service.md`；序列本体 → `systems/character-profile/_index.md`。

## 理由

**不是决策点**：判据是「状态机即将停下来等玩家输入」，而批次层没有状态机在推进、没有可取消的长流程。**但是即时提交**：它是玩家主动按下的一次消费，且不即时写就开出「用一颗丹 → 退出 → 重进」的无限回寿窗口。

**不触发 `RefreshAfterEvent`**：重算会消耗 `map` 子流 ⇒ 这一次当场变成一个真的决策点，并开出「用一颗丹刷新这一批事件」的通道。**照跑终态判定**：一件扣资源的道具能把某条资源打到 `Min`，不判定就会出现「资源触底但角色仍 `ongoing`」。

**reason 新增而非复用 `EventResolved`**：事件内的即时提交其 diff 由所在事件收口那一次 `EventResolved` 的防抖窗口带走，而批次层这一次**没有所在事件**。用「事件已结算」标注一次事件之外的操作，会让日志与后端 reason 聚合上的归因永久失真。

**`ItemElements` 必须分列**：`Elements` 按 `CostKey` 索引一个标量，装不下「哪一层 + 哪个 `ItemId` + 选哪一份实例」，且给 `CostKey` 加成员会破坏双向满射并留下一行填不出 `(Min, Max, DepletionDefeat)` 的配表条目；`AbilityElements` 是幂等无量纲的集合成员操作，扣次数有量纲且不幂等。

**恒不经 modifier pipeline**：一条法则若能改写次数扣减，「古宝的总量被次数封死」这条付费分工当场失效。**`SelectCost` 内恒为空**：成本侧只放可如实计价的量，而「扣一次道具次数值多少寿元」无法回答。

**`ItemUseEntry` 不带派生量**：剩余寿元与剩余次数**两者都重算得出来**——前者由最近一条 `pastEvent.LifeSpanAfter` 锚点 + 其后各条 `AppliedChange` 累加，而归并本就要按 `(AfterEventSeq, Seq)` 走一趟，累加在同一次 `O(n)` 内完成。`PastEventEntry.LifeSpanAfter` 那个明示例外的成立前提是「换掉一次全序列重放」，本序列不需要全序列重放，成本论证在此不成立。

**与 `pastEvent` 分列**：合并要把元素类型改成二成员 sum type，而 `TraceElements` 的两条入口校验与「载荷即 `PastEventEntry`」都绑在载荷类型上，合并后全部退化为按载荷类型分支。**分列判据因此补一句：载荷类型不同且入口校验绑定在载荷上时同样分列。**

## 备选方案

- **把它算作一个决策点** — 否决：批次层没有状态机在推进，不满足判据；且会连带触发 `RefreshAfterEvent` 的重算通道。
- **复用 `SavePointReason.EventResolved`** — 否决：归因永久失真。
- **次数扣减塞进 `Elements` / `AbilityElements` / `StatusChanges`** — 否决：三列各有结构性阻碍，见理由。
- **痕迹并进下一条 `PastEventEntry.AppliedChange`** — 否决：污染「本次事件的最终账」这条语义，且使用后再无事件时痕迹永远落不下来。
- **`ItemUseEntry` 带 `LifeSpanAfter` / `ChargesAfter`** — 否决：两者都重算得出来，成本论证不成立。
- **`pastItemUse` 与 `pastEvent` 合并为一条序列** — 否决：入口校验绑在载荷类型上，合并后退化为分支。
- **新增一个 `Source` 成员标注「次数消耗」** — 否决：扣 `Charges` 到 0 不产生 `Op == Remove`，没有挂载位；且 `Source` 记的是持有条目的来去。
- **给 `pastItemUse` 设条数硬上限** — 否决：条数由 `Charges` 与内容编排天然封顶，体积由既有护栏覆盖。

## 后果

- `systems/services/profile-service.md` 是两列与门面的权威；`systems/character-profile/_index.md` 承载 `pastItemUse` 序列本体。
- 门面收敛：`ConsumePlayerItem(string, int)` → `ConsumeItem(AbilityScope, string, int)`（只扣次数、无产出的路径），另出单一使用门面 `UseItemOutOfCombat` → `ADR-0121`。
- **连带零改动收益**：战斗内使用的次数扣减自此也有了 element 形态，战斗侧流程一字不改。
- **账号级古宝的痕迹同样落角色档**（`Scope = Player` 标识）。代价明写：轮回清理时随之消失，跨轮回使用史不留存；需要时的落点是 `PlayerStatistics` 的聚合项，首批不加。
- **代价明写**：内容侧就此关掉「无限次可用的战斗外道具」整类书写位。
- 跨库对称：`SavePointReason` 扩为六值，`backend-design-documents/contracts/profile-sync.md` 同批同改并明写未知取值的宽容语义。
- `sync-service.md` 中「账号级设置不新增 reason」那条的理由句同批明确为条件式（**当既有 reason 能如实描述该次提交时不新增**），使两处并列时不被读成互相矛盾。
