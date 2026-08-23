# Answer log event-outcome-spec-fields

- 日期：2026-08-22
- 来源：`inbox/solution-draft-event-outcome-spec-fields.md` → `handoffs/2026-08-22-event-outcome-spec-fields.md`
- 移出条数：1（`open-questions/02-event-options.md`）

---

**`EventOutcomeSpec` 的内部字段面（08-17 新增 · 承重）** → **整条答结。** 内部字段面落定：两侧复用 `ProfileChangeSpec`（`Elements` / `AbilityElements` / `DeckElements` 三列开放，其余各列逐列恒空、承重表述不写列数）· `Elements` 的 key 取值域两层收紧（模板可声明 `LifeSpan` / `LifeTotal` / `ManaLimit` / `Jade`；`ExperiencePoint` / `Faith` / `Bloodlust` 只由物化组装从档位表展开；`PowerFragment*` 与 `BundleRedeemedOrdinal` 恒不出现；`ManaLimit` 量值恒为 1）· `AbilityElements` 只承载 `Op == Grant` 且作用域恒 `Character`（事件产出不给账号级古宝 / 法则）· 经验失败折算在物化组装时完成（`FailureRatio` 为百分比整数、不进定稿实例）· 模板侧五格参数空间 + `OutcomeRule` 三个 `Kind` · Explore 壳的产出取真身模板 · 置换 / 禁用候选前移到物化时掷定并落 `EventOption.AbilityChangeSlots`。
（归档去向：`systems/services/future-event-service.md` · `systems/adventure-event/common-properties.md` · `systems/architecture.md` · `systems/adventure-event/explore/_index.md` · `systems/services/profile-service.md`）

**同条附带的「⚠ 阻塞来源待重新确认（阻于效果关键字体系与目标规则）」** → **答结：这条登记从一开始就挂错了对象，两套作用面不相交。**

- 根因：本库「效果」一词有**两个所指** —— ① 战斗侧的效果原语（`EffectData` 的七个原子操作 + `KeywordData` + `TargetSlot` / `EffectScope` / `EntryFilter`），作用于战场条目与手牌、经战斗内求值管线施加、寿命一场战斗；② 事件产出 element（`ProfileChangeSpec` 各列），作用于 `CharacterProfile` / `PlayerProfile` 的字段、经 `ProfileManager.TryApply` 施加、跨事件持久。
- 核实：`EffectData` 的七个原子操作（`ModifyMomentum` / `Draw` / `Discard` / `ModifyMana`（明写不改 `manaLimit`）/ `ApplyState` / `RemoveEntry` / `MoveCard`）**无一写 Profile**；`TargetSlot` / `EffectScope` / `EntryFilter` 锚定的是战场条目与手牌，而一个事件产出里根本没有战场。反向亦然：`ProfileChangeSpec` 各列的施加语义对本条**没有一格缺口**。
- 由此定下的**术语纪律**：产出侧一律称「产出 element」，不称「效果」——与「字段名取 `OutcomeSpec` 而非 `Outcome`」同源的防混淆纪律。已写入 `systems/services/future-event-service.md`。
（归档去向：`systems/services/future-event-service.md`）

---

**仍留在待答清单的相关项（本次不移出）：**

- `open-questions/02-event-options.md` 的「生成 / 加权规则与叠加顺序」—— 本条明写不阻塞它、也不答它。
- 两项 `[采纳推荐 — 待复核]`：`GrantFromPool` 型产出不加加载期池断言（闸 ①）· `OutcomeRule` 不支持多选一 / 加权掷一条。
- 新增一条：`HiddenStatGrant` 的推拉方向如何表达（道心可正可负，而 `HiddenStatGrade` 的映射值是正量；方向位落在哪里未定）。
