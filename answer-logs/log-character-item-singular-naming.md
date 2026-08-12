# Answer log character-item-singular-naming

- 日期：2026-08-12
- 来源：`inbox/solution-draft-character-item-singular-naming.md` → `handoffs/2026-08-12c-identifier-singular-collapse.md`
- 移出条数：1

---

**`CharacterItem` 的标识符单复数不一致（08-03 新增）——中文定名「法宝」对应单数 `CharacterItem`，但全库既有写法是 `List<CharacterItems>`（复数），是否统一？** → **统一为单数，复数写法整体作废。** 通则定为「**类型名恒为单数，复数只属于集合字段名**」；法宝的三层分工一次写死：内容定义 `ItemData`（两层共用，无 `CharacterItemData`）↔ 持有条目 `CharacterItem`（一份实例 = 一个集合元素）↔ 集合字段 `CharacterProfile.magicPack`（`List<CharacterItem>`，字段直接借用已定名的容器概念「储物袋」，单复数之争在此形态下直接消失）。三条依据各自独立成立：四格对称中 `CharacterItems` 是唯一离群项 · `XxxData` 命名族全单数 · 泛型参数位的复数是双重复数的语义错误。纯标识符收口，机制侧零改动、不 bump 存档 schema、无迁移路径（无线上账号、无对应代码）。（归档去向：`systems/character-profile/item/_index.md` 顶部三层分工表 + `common-properties.md` + `terminology.md` 法宝 / 储物袋两条）

**连带一并答结（本次 interview 追加，原不在待答清单内）：**

- **`List<Achievements>` 的同类缺陷** → 元素类型 `Achievement`、集合字段 `achievement`（成就无「储物袋」式的已定名容器概念可借名，退回库内既有单数字段风格，零张力）；**裸写 `Achievements` 一并单数化**，**文件夹 `systems/player-profile/achievements/` 改名为 `achievement/`** 并同步全库路径引用。分组结构与两档奖励语义不受影响。（归档去向：`systems/player-profile/achievement/_index.md`、`terminology.md` 新增「成就 / Achievement」词条、`architecture.md`、`life-cycle-service.md`、`ux/screen-flow.md`、`player-profile/_index.md` 等）
- **`pastEvent` 的类型漂移** → `List<AdventureEvent>` → `IReadOnlyList<PastEventEntry>`，**三处全部纠正**（`systems/services/life-cycle-service.md`、`program-overview.md`、`decisions/ADR-0004`；ADR 那处为纯类型标注订正，不改变该 ADR 的任何决策语义）。同时中性化 `character-profile/_index.md` 中「先前记为 X」的考古式表述。（归档去向：同上三份 + `systems/character-profile/_index.md`）

**剩余待答：无。** 原草稿标注的前置依赖（「`SourceCode` 是否收窄到账号级两类」）已由同日的 `handoffs/2026-08-12b-grant-source-per-kind-scope.md` 反向答结——`Source` 清单改为按 `(Kind, Scope)` 分域开放，**`CharacterItem` 确定携带 `SourceCode`**，法宝层合法取值为 `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`（+ 读档兜底 `Unknown`）。
