# Answer log ability-effect-primitives

- 日期：2026-08-28
- 来源：`inbox/solution-draft-ability-effect-primitives.md` → `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`
- 移出条数：2 整条 + 1 部分 + 1 条主题文档内待决项

---

**`RelicData` 的字段清单与触发器体系未设计**（四子项：触发条件枚举 / 效果关键字体系 / `status` 持久化与 UI / 字段清单）→ **整条移出**。四项各自已有权威落点：触发条件 = `TriggerConditionData` + 封闭时点常量表（`systems/character-profile/deck/common-properties.md`）· 效果关键字体系 = `KeywordData` 两分（同上）· `status` 持久化与 UI = Profile 侧持有条目 + `ux/screen-flow.md`（**`status` 的 schema 编码那一格另有独立待答项，仍在清单上**）· 字段清单 = `PowerData`（`systems/character-profile/power/_index.md`，两层共用一个类型）。`RelicData` 是一个已不存在的类型名，四处同源表述随之改写。（归档去向：`systems/player-profile/player-power/common-properties.md` · `systems/character-profile/power/_index.md` · `systems/character-profile/power/common-properties.md`）

**`item/common-properties.md` 的共有字段无实质设计**（含「`CardData` 的费用与触发器两格仍是结构占位」）→ **整条移出**。`CardData` 那半的权威形态是「`ManaCost` 独立整数格 + 不设触发器格（`Abilities` 承载）+ 新增 `OnPlay`」（`systems/character-profile/deck/common-properties.md`）；`item/` 共有字段那半由 `ItemData` 的完整字段清单闭合（`systems/character-profile/item/_index.md`），持有条目侧只剩 `status` 的 schema 编码一格，已改写为一条更窄的待答项留在文档内。（归档去向：`systems/character-profile/item/_index.md` · `systems/character-profile/item/common-properties.md`）

**`PlayerItem` 的种类目录、次数补充机制与可购价格 / 库存** → **部分答定**：其中「**战斗外的效果形态**」一项移出——形态定为内容侧的 `ProfileChangeSpec` 模板 `OutOfCombatUseOutcome`，只开放 `Elements` / `CodexElements` / `Stats` 三列、其余各列恒空，表达力上界取「恒定、无条件、无随机」。**其余三项（种类目录 / 次数如何补充 / 价格与库存权重）仍留在待答清单。**（归档去向：`systems/character-profile/item/_index.md` · `systems/player-profile/player-item/_index.md`）

**触发器体系与 RelicData 字段未定案**（`systems/player-profile/player-power/common-properties.md` 的主题文档内待决项，与上方第一条同源）→ **就地删除**，理由同上。（归档去向：同上）

---

同批在主题文档内答定、但此前**从未进过任何待答分片**的四处缺口（故不计入移出条数）：`ItemData` 的使用效果格 · 战斗外效果的执行面 · `Sorcery` 带触发式异能的合法性 · 两个 `AbilityKind` 同名。四者的结论见来源 handoff。
