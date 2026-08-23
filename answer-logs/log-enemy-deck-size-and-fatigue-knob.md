# Answer log enemy-deck-size-and-fatigue-knob

- 日期：2026-08-22
- 来源：`inbox/archive/solution-draft-enemy-deck-size-and-fatigue-knob.md` → `handoffs/2026-08-22-enemy-deck-size-and-fatigue-knob.md`
- 移出条数：2

---

**样本卡组规模两处矛盾（「不设硬限」vs「规模 15」）改哪一侧** → **两侧皆不设硬限**；改写 `systems/enemies/common-properties.md` 一侧，「15」直接删除、**不降格为编排参考值**保留（那张表是字段形态与加载期校验表，放不校验的建议值正是本次漂移的成因）。连带：新增「样本卡组为空序列 → `PushError`（带模板 `Id`）」——校验的是漏填而非规模，不构成对「不设硬限」的回退；**不给**内容侧编排锚点数字，规模区间归 ch1 数值标杆专场。（归档去向：`systems/enemies/common-properties.md`；连带措辞订正 `systems/player-profile/codex/enemy-codex.md`）

**疲劳量是否可调（是否升格为 `EncounterSpec` 的可空覆写）** → **不加覆写**，保留 `CombatRulesData` 上的全局常量 `1`（它本就是可调的数据资源值，「是否硬编码」与「是否加 per-encounter 覆写」是两件事）。三条否决理由：没有 payoff（无削减对手抽牌堆的效果形态）· 量纲撑不起路线（5 回合疲劳总量上限 −10）· 覆写组「更宽容的 `Practice`」这条动机不迁移（触发窗口由卡组规模而非档位决定）。`systems/balance.md` 该行已明写「不进覆写组」+ 三条重开判据。连带：「疲劳」立项进 `terminology.md`，代码标识符 `FatiguePerDraw`。（归档去向：`systems/balance.md`、`terminology.md`）

---

**未随本次移出、仍待答：** 卡组规模的实际取值区间（玩家起始卡组 / 敌人样本卡组）归 ch1 数值标杆专场，是上述第三条重开判据的实证输入。
