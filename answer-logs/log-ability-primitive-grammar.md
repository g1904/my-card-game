# Answer log ability-primitive-grammar

- 日期：2026-08-27
- 来源：`inbox/solution-draft-ability-primitive-grammar.md`（→ `handoffs/2026-08-27-ability-primitive-grammar.md`）
- 移出条数：1（另有 1 条部分答定，剩余部分留在清单）

- **效果原语 / 异能语法未定案（`content/_index.md` 的 `ability/` 标 🔴，卡住五个内容类型的条目写作）** → 全部六处缺口定案：`EffectData` = 抽象基类 + 一原语一 `[GlobalClass]` 子类（按 `Type` 分派、无判别枚举）· 静止式修正另立并列定义体 `StaticModifierData`（`ModifierTarget` 首批五项 · 万分比整数 · 同层求和只乘一次只取整一次）· `AbilityData` 的定义体按 `Kind` 分两格 + XOR 校验 · 首批八个原语 · `TriggerConditionData` 完整形态（`TimingIds` 十个 + `SubjectKind` 相容校验）· `EffectCondition` 三谓词 AND · `CardData` 收口（`ManaCost` + `OnPlay`，不设触发器格）· 效果流水线五阶段 + 六条规则 · 槽位扁平化编号 · 存档零新增字段。（→ `systems/character-profile/deck/common-properties.md`、`systems/character-profile/deck/_index.md`、`systems/services/combat-service.md`）

- **`CardData` 的完整字段清单与起始卡组内容** → **部分答定**：字段清单已收口（费用 = 独立 `ManaCost` 整数格 · 触发器格取消，`Abilities` 已承载 · 新增 `OnPlay : EffectData[]`）；**starter deck 的具体内容仍未设计**，该半留在待答清单。（→ `systems/character-profile/deck/common-properties.md`）

**本次连带的定案（不单独占条目，记此备查）：**

- **疲劳「可被取消」→「可被削减至 0」**：不设取消通道，「免疫下一次疲劳」由一条 `ForTurns(1)` 战场条目 + 一条把 `FatigueAmount` 削到 0 的静止式修正表达。`TargetKind` 仍不含 `StackEntry`、不新增栈筛选结构。（→ `decisions/ADR-0088-fatigue-as-stack-entry.md`、`systems/services/combat-service.md`、`systems/scoring.md`）
- **删除「启动式异能须存在一条有限性闸」这条加载期校验**：零费且不限次的启动式异能是合法内容，**组合技达成无限是被接受的设计面**，终止性由 `TurnLimit` 承接。（→ `systems/character-profile/deck/common-properties.md`）
- **新增单次动作链的栈条目总数上限 N**（超限中止并 `PushError`，N 落 `CombatRulesData`）：进程护栏，不限制设计面。（→ `systems/services/combat-service.md`）
- **条件逐 element 就地求、数值整条一次求完**，并写下 AI 试算侧的例外（试算按进入本动作前的局面求条件，与真实结算可能分支不同）。（→ `systems/services/combat-service.md`）
