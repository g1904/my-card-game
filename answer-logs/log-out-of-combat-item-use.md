# Answer log out-of-combat-item-use

- 日期：2026-08-28
- 来源：`inbox/solution-draft-out-of-combat-item-use.md` → `handoffs/2026-08-28-out-of-combat-item-use-savepoint-and-trace.md`
- 移出条数：1 整条（两问全部答定）+ 1 条主题文档内待决项

---

**战斗外道具的使用入口未设计**（`open-questions/03-adventure-event-types.md`，剩余两问）→ **整条移出**。两问逐条答定：

**① 一次使用是否单独构成一个存档点** → **不是决策点，但是一次即时提交**。决策点的判据是「状态机即将停下来等玩家输入」，而使用发生在批次层、无状态机在推进 ⇒ 不进 D0–D7、也不进 R1 / R2 / X1 / X2 / X3（两份都是事件内清单）；即时提交的两条判据（玩家主动按下 · 不即时写就开出退出重进即回滚的窗口）同时成立 ⇒ 一次 `TryApply` 随之一次本地原子写。连带三条：不触发 `RefreshAfterEvent` · 照跑终态判定（`finaleFailed = false`）· 不计软阻塞闸门。push 走 `PushPolicy.Debounced` + **新增的第六个 `SavePointReason` 成员 `InventoryChanged`**（同时覆盖随售），例外只有「使用致资源触底 → 走既有 `defeated` 的 `Immediate`」。（归档去向：`systems/character-profile/item/_index.md` · `systems/services/life-cycle-service.md` · `systems/services/sync-service.md`）

**② 事件之外使用时的痕迹落点**（含原问题的「扣 `Charges` 没有对应 `Source` 成员可用」）→ 痕迹落 **`CharacterProfile.pastItemUse`** 这条新序列，经 `ProfileChangeSpec` 新增列 **`ItemUseElements`** 写入；条目 `ItemUseEntry(Seq, AfterEventSeq, ItemId, Scope, AppliedChange)` **五字段、不带任何派生量**（剩余寿元由最近的 `pastEvent.LifeSpanAfter` 锚点 + 其后各条 `AppliedChange` 的 `LifeSpan` element 在归并的同一趟遍历内累加得出；剩余次数的消费方是诊断日志）。它与 `pastEvent` **分列两条序列**，读取侧按 `(AfterEventSeq, Seq)` 归并。**`Source` 一个成员不加**：扣 `Charges` 到 0 不产生 `Op == Remove`（耗尽的道具仍留在储物袋）、`Source` 的语义是「怎么来的 / 怎么没的」、且该类成员不进存档而本处的消费方读的是存档。（归档去向：`systems/character-profile/_index.md` · `systems/services/profile-service.md` · `systems/common-properties.md`）

**（连带，此前未进任何分片）「扣 `Charges` 没有 element 形态」** → 新增 `ProfileChangeSpec` 列 **`ItemElements`**（`ItemChargeElement(AbilityScope Scope, string ItemId, int Delta)`），带纯函数式的实例选取规则、首批只开消耗向、恒不经 modifier pipeline、`SelectCost` 内恒为空。门面同批收敛为 `ConsumeItem(AbilityScope, string, int)`，另出使用门面 `UseItemOutOfCombat(AbilityScope, string)`。（归档去向：`systems/services/profile-service.md` · `systems/architecture.md`）

---

**战斗外道具使用的两处空缺**（`systems/character-profile/item/_index.md` 的主题文档内待决项，与上方同源）→ **就地删除**，理由同上。同批在该文档落一条新的加载期校验：`Charges == -1` 且 `UsableScene` 含 `OutOfCombat` → `PushError`。

---

**不答定、保持原样：** `open-questions/deferred-content.md` 的「`PlayerItem` 的种类目录 / 次数如何补充 / 价格与库存」（本方案首批只开消耗向，明写依赖「次数如何补充」）· `open-questions/01-combat.md` 的「回寿法宝总量护栏的内容编排口径」（护栏是数量闸，本方案不触及）。

**本次新增待答：无。**
