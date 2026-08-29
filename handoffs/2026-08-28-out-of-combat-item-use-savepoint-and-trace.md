# 战斗外道具使用的存档点归属、次数扣减 element 与痕迹落点

- id: 2026-08-28-out-of-combat-item-use-savepoint-and-trace
- date: 2026-08-28
- topic: systems/character-profile/item · systems/character-profile · systems/services/profile-service · systems/services/sync-service · systems/services/life-cycle-service · systems/adventure-event · systems/common-properties · systems/architecture · systems/player-profile · ux/screen-flow · terminology
- status: distilled
- distilled-to: systems/services/profile-service.md, systems/character-profile/_index.md, systems/character-profile/item/_index.md, systems/adventure-event/common-properties.md, systems/services/sync-service.md, systems/services/life-cycle-service.md, systems/common-properties.md, systems/architecture.md, systems/player-profile/_index.md, ux/screen-flow.md, terminology.md, systems/services/combat-service.md

> **一行摘要：** 战斗外用一件道具**不是决策点**但**是一次即时提交**（一次 `TryApply` ⇒ 一次本地原子写，push 走 `Debounced` + 新 reason `InventoryChanged`）；`ProfileChangeSpec` 补上它缺的两列——`ItemElements`（次数扣减）与 `ItemUseElements`（事件之外的使用痕迹，落新序列 `CharacterProfile.pastItemUse`）；`Source` 一个成员不加；无限次可用的战斗外道具由一条加载期校验关掉。一次 schema bump，空迁移。

## Intent（distilled）

### 1. 一次使用不构成决策点，但构成一次即时提交

逐条对判据：决策点的判据是「状态机即将停下来等玩家输入」，而这一次发生在**批次层**——`AdvanceEventAsync` 未在运行、没有状态机在推进、没有可取消的长流程。故它**不进任何既有决策点清单**（战斗侧 D0–D7、非战斗四类的 R1 / R2 / X1 / X2 / X3 都是**事件内**清单）。

但即时提交的两条判据同时成立：① 它是玩家主动按下的一次消费；② 不即时写就开出「用一颗丹 → 退出 → 重进」的无限回寿窗口。⇒ **一次 `TryApply`，随之一次本地原子写**（「不允许提交了但不落盘」）。

三条连带纪律，均是既有约定的直接落地：

- **不触发 `RefreshAfterEvent`**，当前批 `eventOption` 一字不变。重算会消耗 `map` 子流 ⇒ 这一次当场变成一个真的决策点，并开出「用一颗丹刷新这一批事件」的通道。
- **照跑终态判定**（`finaleFailed = false`）。战斗外道具不限于回寿，一件扣资源的道具能把某条资源打到 `Min`；不判定就会出现「资源触底但角色仍 `ongoing`」。
- **不计软阻塞闸门**（闸门只数事件级存档点），与事件内的即时提交同款。

同一条注记覆盖**随售**：它同属批次层的储物袋操作。

### 2. push 走 `Debounced`，`SavePointReason` 增第六个成员 `InventoryChanged`

policy 取 `Debounced`：它不在立即 flush 清单五项内，且被「应用失焦 / 挂起」那一条兜住；本地已原子写 ⇒ 进度不丢。唯一例外是使用致资源触底 → 判负后走既有 `defeated` 的 `Immediate`。

reason 新增而非复用 `EventResolved`：事件内的即时提交其 diff 由所在事件收口那一次 `EventResolved` 的防抖窗口带走，而批次层这一次**没有所在事件**，必须自己发一次 push、自己带一个 reason。用「事件已结算」标注一次事件之外的操作，会让日志与后端 reason 聚合上的归因永久失真。成本 = 一个枚举成员、不落存档 schema ⇒ 零迁移。它同时补上随售此前空着的那个 reason。

连带把 `sync-service.md` 中「账号级设置不新增 reason」那条的理由句明确为条件式（**当既有 reason 能如实描述该次提交时不新增**），使两处并列时不被读成互相矛盾。

### 3. `ProfileChangeSpec` 新增 `ItemElements`，承载 `Charges` 的扣减

既有各列无一装得下「扣一份实例的次数」：`Elements` 按 `CostKey` 索引一个标量，装不下「哪一层 + 哪个 `ItemId` + 选哪一份实例」，且给 `CostKey` 加成员会破坏它与两层 Profile 字段表的双向满射、并留下一行填不出 `(Min, Max, DepletionDefeat)` 的配表条目；`AbilityElements` 是集合成员操作（幂等增删、无量纲），扣次数有量纲且不幂等；`StatusChanges` 绑定 `Status` 上的规则字段。按「施加语义根本不同就分列」⇒ 分列。

```csharp
public readonly record struct ItemChargeElement(AbilityScope Scope, string ItemId, int Delta);
```

- **实例选取是纯函数**：取同 `(Scope, ItemId)` 中 `Charges > 0` 且最小者，并列取存档列表靠前者，`Charges == -1` 不参与。只依赖存档列表顺序 ⇒ 同一份 spec 重放两次同结果。
- **首批只开消耗向**：`Delta > 0` / `Delta == 0` 一律 `PushError` + 整批拒绝；正向书写位待「次数如何补充」答定后放开，那是把一行校验从拒绝改为允许，无结构改动。
- **恒不经 modifier pipeline**：一条法则若能改写次数扣减，「古宝的总量被次数封死」这条付费分工当场失效。
- **`SelectCost` 内恒为空**，独立成行的不变式：成本侧只放可如实计价的量，而「扣一次道具次数值多少寿元」无法回答。
- 连带零改动收益：**战斗内使用的次数扣减自此也有了 element 形态**，战斗侧流程一字不改。

门面同批收敛：`ConsumePlayerItem(string, int)` → **`ConsumeItem(AbilityScope, string, int)`**（保留给「只扣次数、无产出」的路径），另出**单一使用门面 `ApplyResult UseItemOutOfCombat(AbilityScope scope, string itemId)`**，内部一次组装「战斗外产出 + 次数扣减 +（`activeEvent == null` 时）痕迹」交**一次** `TryApply`。分两次调用即「先扣次数后产出失败」这种半套写入。两层共用一个门面、用 `AbilityScope` 选层，因为储物袋是跨两层的呈现视图、同一个「使用」键要服务两级。

### 4. 不新增任何 `Source` 成员

三条各自独立成立：① 扣 `Charges` 到 0 不产生 `Op == Remove`——`Charges` 允许取 0、「已耗尽」chip 正读它 ⇒ 耗尽的道具仍留在储物袋，没有 `Remove` 就没有挂载位；② `Source` 记的是「这条持有条目怎么来的 / 怎么没的」，扣一次次数既不是来也不是没；③ 即便加了成员也承载不了本处的消费方——这类成员不进存档、只进可追溯性日志，而寿元曲线读的是存档。⇒ 九值 + 兜底保持不变，合法子集表不加行。

### 5. 痕迹落 `CharacterProfile.pastItemUse`，经新增列 `ItemUseElements` 写入

痕迹判据是「重算不出来且有消费方的存」，这一笔两条都满足：它由玩家在批次层的即时操作产生，消费方是元进程的角色履历寿元曲线。

```csharp
public sealed record ItemUseEntry(
    int Seq, int AfterEventSeq, string ItemId, AbilityScope Scope, ProfileChangeSpec AppliedChange);
```

**五个字段，不带任何派生量。** 使用后的剩余寿元与剩余次数**两者都重算得出来**：前者由最近一条 `pastEvent.LifeSpanAfter` 锚点 + 其后各条 `AppliedChange` 里 `LifeSpan` element 累加得出，而归并本就要按 `(AfterEventSeq, Seq)` 走一趟，累加在同一次 `O(n)` 内完成；后者的消费方是诊断日志，由 `ProfileManager` 的可追溯性日志行承担。`PastEventEntry.LifeSpanAfter` 那个明示例外的成立前提是「换掉一次全序列重放」，本序列不需要全序列重放，成本论证在此不成立。

- **与 `pastEvent` 分列两条序列**：合并要把 `pastEvent` 的元素类型改成二成员 sum type，`TraceElements` 的两条入口校验与「载荷即 `PastEventEntry`」都绑在载荷类型上，合并后全部退化为按载荷类型分支。分列判据因此补一句：**载荷类型不同且入口校验绑定在载荷上时同样分列。**
- **不并进下一条 `PastEventEntry.AppliedChange`**：那会污染「本次事件的最终账」这条语义，且使用后再无事件时痕迹永远落不下来。
- `AppliedChange` 的自指防呆断言由「只覆盖 `TraceElements` 一列」扩为覆盖两列，两条独立成行。
- **账号级古宝的痕迹同样落角色档**（`Scope = Player` 标识）。代价明写：轮回清理时随之消失，跨轮回使用史不留存；需要时的落点是 `PlayerStatistics` 的聚合项，首批不加。
- **不设条数硬上限**：条数由 `Charges` 与内容编排天然封顶，体积由 `CharacterProfile` 级既有护栏覆盖，挂同一聚合 ⇒ 不新增同步单元。

### 6. 无限次可用的战斗外道具由一条加载期校验关掉

`ItemData.Charges == -1` 且 `UsableScene` 含 `OutOfCombat` → `PushError` + 条目 `Id`。战斗外效果恒是一份写 Profile 的 `ProfileChangeSpec` 模板 ⇒ 这类条目就是一个**没有次数上限的重复消费源**，玩家可在批次层无限次点它、把 `pastItemUse` 刷成无界序列。它与既有两条准入校验（`PowerData` 不得产寿元、含寿元产出者不得含 `InCombat`）是同一条判据的第三个实例。代价明写：内容侧就此关掉「无限次可用的战斗外道具」整类书写位。

### 7. 呈现：就地生效、就地反馈

使用在储物袋面板内就地结算并就地反馈（`Charges` 立即 `-1`、`×N` 与「已耗尽」chip 立即重算），**不新开屏、不新增弹层、不做二段确认**——与「售出后条目直接移出列表」同一处交互层级；使用不像售出那样不可逆地损失资源。回寿数值照既有寿元 Band 门控：Band 0 / Band 1 定性文案，Band 2 才追加精确 `+n`。文案走 `PROFILE_` 分区普通键，不占 `ERR_` 前缀。

### 8. 存档面与跨边界面

三处改动（两列 + 一个字段）合并为**一次** schema bump，当前无线上存档 ⇒ 空迁移。`SavePointReason` 增员不落存档 schema，但该枚举以成员名逐字序列化上行 ⇒ 取值清单是两侧共同约定的契约面，后端那一半见 `backend-design-documents/handoffs/2026-08-28-save-point-reason-inventory-changed.md` 与 `backend-design-documents/contracts/profile-sync.md`。

## Clarifications

- **战斗外使用时「`Charges` −1」的 element 形态** → 新增第十二列 `ItemElements`（`ItemChargeElement`），不走 `Elements` / `CostKey` 那条路（会破坏 `CostKey ↔ ResourceElements` 的双向满射，且装不下三元信息）。
- **战斗外使用的门面形状** → 单一使用门面 `UseItemOutOfCombat(AbilityScope, string)`，一次组装、一次 `TryApply`；`ConsumeItem` 收敛照常执行，保留给「只扣次数、无产出」的路径。服务归属答定为 profile-service。
- **`ItemUseEntry` 是否带 `LifeSpanAfter` / `ChargesAfter`** → **两个派生字段都不写**，收为五字段。判据零松动，代价（曲线读取侧的锚点累加）写进读取算法。
- **无限法宝在事件之外的使用如何处置** → 加载期禁令。「会写 Profile」这个条件已随战斗外效果面的定案退化（战斗外效果恒是纯 `ProfileChangeSpec` 模板 ⇒ 恒写 Profile），故校验条款只留两个条件。
- **`pastItemUse` 与 `pastEvent` 分列还是合并** → 分列两条序列，读取侧按 `(AfterEventSeq, Seq)` 归并。
- **「零结构成本」那句话的作用域**（自行推演）→ 它的实际书写位在 `systems/adventure-event/common-properties.md`，且只对**寿元的施加路径**成立；限定作用域即可，`decisions/ADR-0066-lifespan-gain-outcome-side-only.md` 一字不动。
- **「寿元回复通道 B」的归类**（自行推演）→ 由「事件内部的主动消费即时提交」订正为「批次层的主动消费即时提交」——即时提交的两条判据不看它发生在事件内外。这是既有文本的一处失真。
- **`AppliedChange` 的两条不变式**（自行推演）→ 只有**自指防呆断言**扩到新列；「恒不含 `EventStateChanges`」是累加时的剔除规则，不是入口断言，不得混为一谈。
- **「使用恒发生在事件之外」不写成承重推论**（自行推演）→ 入口挂在角色状态条上，组装判据取 `activeEvent == null ⇒ 写痕迹，否则不写`，机械覆盖两种情形，不依赖入口面的排他性。

## Open questions

- **回寿法宝的总量护栏在内容编排面的具体口径**（出现频率 / 商店库存深度 / 定价）仍未给——它是寿元这条压力线的唯一剩余数量闸。
- **古宝的次数补充机制**未设计，`ItemChargeElement.Delta > 0` 的书写位因此暂闭。
- **战斗外道具的种类目录与其余效果形态**仍未设计；本次的写入通道对效果内容无假设，不被它阻塞。

## Notes / triage

- 两条方向性定案可作 ADR 候选：①「批次层的储物袋操作不是事件内决策点，是独立的即时提交」（与战斗侧、非战斗侧两份清单对称）；②「分列判据补充：载荷类型不同且入口校验绑定在载荷上时同样分列」。
- 台账侧连带：`open-questions/03-adventure-event-types.md` 的「战斗外道具的使用入口未设计」整条移出；`terminology.md` 补登「随售」。
- 一处引用出处订正：「零结构成本」那句的权威书写位不是 ADR，而是 `systems/adventure-event/common-properties.md` 的寿元回复通道段。
