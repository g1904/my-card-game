# Answer log capability-flag-and-entitlement

- 日期：2026-08-27
- 来源：`inbox/solution-draft-capability-flag-and-entitlement.md`（→ `handoffs/2026-08-27-capability-flag-and-entitlement.md`）
- 移出条数：2

---

**capability flag 的叠加 / 冲突规则（含连带的「flag 聚合面的宿主服务」一格）** → **叠加 = 集合并、幂等、不计数、不叠层、不告警；冲突在结构上关死**（全部 flag 恒为增益向 ⇒ union 就是全部规则，不设优先级 / 声明序 / 裁决表），护栏是**命名三词表** `{Reveal, Show, Unlock}` + 禁否定式命名（`Hide*` / `No*` / `Disable*` / `Suppress*` / `Prevent*`），落成 `#if DEBUG` 反射断言。枚举为单一扁平 `CapabilityFlag`、不分区不加前缀，落地形态 `HashSet<CapabilityFlag>`、不加 `[Flags]`。**宿主 = `profile-service.CapabilityManager`**（此前已定，本次清理三处过期措辞，不新开账号级服务）。**注册面两层共用**：同时遍历 `playerPower` 与当前角色 `characterPower`，同三条与门，聚合成同一份生效能力集与同一张修正表；`ItemData` 两类不参与。**modifier 合并算法** = `ModifierEntry(ModifierKey, ModifierOp{Add, Scale}, int)`、`Scale` 为万分比增量、**同层求和 → 只乘一次 → 只取整一次** + 两条钳制（`scale >= 0`、结果与 `baseValue` 同号或 0）⇒ 结果与顺序无关，不设优先级字段。（归档去向：`systems/player-profile/player-power/common-properties.md` · `systems/services/profile-service.md` · `systems/architecture.md` · `systems/character-profile/power/_index.md` · `decisions/ADR-0017-capability-flag-and-modifier-pipeline.md`）

**重试上限可变后的存档表达** → **三个候选（`CapabilityFlag` / modifier 的一条具名修正 / 独立 `Entitlement` 字段）全部否决**：正确答案是不新增任何东西，`RetryChapter` 读既有的 `profile-service.HasPremiumBundle`（`=> Entitlement.BundleGrantOrdinal > 0`）选行。**存档 schema · `CostKey` · `ResourceElements` · 透明路径 · sync-service · 后端契约全部零改动**；本次唯一新增的是载体形状 `ChapterRetryLimitsData : Resource, ISingletonContent` + 内嵌 `ChapterRetryRow`（`Chapter1/2/3` 具名字段、`-1` = 无限、经 `Content.Single<T>()` 取、加载期校验）。**两档数值未被答定**，「重试上限的两档数值是否再调」仍留在 `systems/balance.md` 的待决问题与 `open-questions/deferred-content.md` 中。（归档去向：`systems/services/life-cycle-service.md` 正文 · `systems/balance.md`）
