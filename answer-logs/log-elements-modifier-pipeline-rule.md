# Answer log elements-modifier-pipeline-rule

- 日期：2026-08-16
- 来源：`inbox/solution-draft-elements-modifier-pipeline-rule.md`（`status: decided`）→ `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md`
- 移出条数：1

---

**`Elements` 是否一律走 modifier pipeline 的通则（原 `open-questions/07-codex-monetization.md`，08-15b 新增 · 承重）**
→ 收口为 **opt-in 白名单，缺省豁免**：`Elements` 缺省不经 modifier pipeline，只有在 `ResourceElements` 表中显式登记了 `ModifierKey` 的那一行才经；`AbilityElements` / `Stats` 永不经。承载形态是在既有钳制表上加两列并**按 `BaseValue` 符号分向**（`CostModifier` / `GainModifier`），表随之由 `ResourceClamps` / `ClampSpec` 更名为 `ResourceElements` / `ElementSpec`。首批七行中只有 `LifeSpan.CostModifier = ModifierKey.LifeSpanCost` 一格非空。连带定下：`ModifierKey` 登记进共享核心类型、首批成员 `LifeSpanCost`；「一个 `ModifierKey` 只能有一个施加点」，判据是「该修正后的值是否需要在施加之前呈现给玩家」；启动期断言表覆盖 `CostKey` 全部成员。

否决的形态：08-15b 原措辞的**语义分类通则**（「序号 / 幂等键 / 权益类不经 pipeline」——把「每次单独裁」从裁 pipeline 改成裁分类，没消掉裁决本身，且缺省仍在不安全的一侧）；维持全称句 + 例外散落各文档；`ChangeElement` 自带 `ModifierKey?`；给 `ModifierKey` 分向而非表里两格；另起一张独立白名单表。

（归档去向：`systems/architecture.md`「共享核心类型」· `systems/services/profile-service.md` ProfileManager 小节与 `ResourceElements` 表 · `systems/monetization.md` `BundleGrantOrdinal` 段 · `systems/player-profile/player-power/common-properties.md` modifier 通道段）

**未答定、仍留在清单上：** `Jade` 的 `CostModifier` 取值（依赖 Exchange 专场）已作为新条目落入 `open-questions/03-adventure-event-types.md`；「cost element 清单（资源族）」「多个 modifier 作用于同一 key 的运算顺序」原样留在各自分片，本次未触及。
