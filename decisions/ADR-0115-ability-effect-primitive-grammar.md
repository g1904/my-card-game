# ADR-0115 — 效果原语语法：`EffectData` 一原语一子类，`StaticModifierData` 并列为第二种定义体，流水线五阶段

- **状态：** Accepted
- **日期：** 2026-08-27
- **来源：** handoffs/2026-08-27-ability-primitive-grammar.md

## 背景

`ability/`（`AbilityData` / `EffectData` / `TriggerConditionData`）是卡牌 / 神通 / 法宝 / 法则 / 古宝五个内容类型的共同底座，其语法此前未定案——`AbilityData` 上只有一格占位的 `Effect`，六处缺口同时悬着：原语的表达形式、静止式修正的归属、首批原语清单、触发器形态、条件形态、效果的执行时序。

## 决策

**`EffectData` = 抽象基类 + 一个原语一个 `[GlobalClass]` 子类**，按 `Type` 分派，**不引入 `EffectKind` 判别枚举**。

**静止式修正不是 `EffectData`，是并列的第二种定义体 `StaticModifierData(Scope, What : ModifierTarget, Layer, Amount)`**；`AbilityData` 因此落为 `Effects` / `StaticModifiers` **两格 + 一条 XOR 校验**。`ModifierTarget` 首批五项，成员序视同冻结、只能追加；量纲取万分比整数，合并算法「同层求和 → 只乘一次 → 只取整一次」。

**首批八个原语**（既有七个 + `BumpCounterEffect`）；**疲劳不是原语**。触发器用点分 `TimingId` + 代码侧封闭常量表 `TimingIds`（首批十个）。条件 = 三个封闭谓词挂 `EffectData.Conditions`、**AND 语义、条件不满足 ≠ fizzle**、单一落点。`CardData` 收口为独立 `ManaCost` 格 + 新增 `OnPlay`、**取消触发器格**。

**槽位在栈条目层扁平化编号**，`FizzledSlots` 位掩码 ⇒ 单条目槽位数硬上限 32。

**效果流水线 = 五个阶段**（重检 / 挂起 → 关键字展开 → 数值求值 → 逐 element{条件 → 施加} → 收口），**挂起点唯一 = 阶段 1**；`IEffectHandler` 拆 `Evaluate` / `Apply`，**随机只在 `Apply` 内取 `combat` 子流**；数值整条一次求完而条件**逐 element 就地求**。

**单次动作链的栈条目总数上限 N** 落 `CombatRulesData`，超限中止链路并 `PushError`。

**存档面零新增字段、空迁移。** 逐子类定义、十九条加载期校验与六条流水线规则 → `systems/character-profile/deck/common-properties.md`、`systems/services/combat-service.md`。

## 理由

**多态子类树的四条判据**：检视器可写性 · 链路类型一致性 · 加载期校验的归属 · 可加性。它与 `ProfileChangeSpec` 的 `ChangeElement` 否决多态**判据不同故不冲突**——后者落存档、进 diff、走热路径构造，前者是内容侧 `Resource`、恒不落存档。**这条区分必须并置写下**，否则日后必被当成矛盾。

**静止式另立定义体**：第一层的定义是「**结算时执行**的原子操作」，而静止式修正不入栈、只在求值瞬间被读取；混装会让这句定义失真。分立之后「静止式不执行原子操作」由**类型形状**承担，不必再写校验。

**`TimingId` 保留字符串而不改枚举**：点分惯例已被次类型 id 规范显式引用为先例，且加载期封闭集校验拿到的安全性与枚举等同。

**条件逐 element 就地求**：规则「element 顺序是规则、前一条改了道念后一条读到改后的值」保留。代价是 AI 试算须补一条例外规则（按进入本动作前的局面求条件，试算与真实结算可能分支不同），已明写。

**动作链上限而非有限性闸**：无限组合是被接受的设计面，非本意的无限由内容侧纪律承接；工程侧的上限只阻止进程不返回、不约束任何设计面。

## 备选方案

- **`Op` 枚举 + 扁平参数表** — 否决：四条判据（检视器可写性 · 链路类型一致性 · 加载期校验归属 · 可加性）全部指向子类树。
- **效果表达式串** — 否决：同上，且撞「内容侧不落裸逻辑」。
- **静止式修正作为 `EffectData` 的一个子类** — 否决：它不入栈，混装会让「结算时执行的原子操作」这句定义失真。
- **把疲劳做成第九个原语** — 否决：它是栈条目结算时执行的一条内建 `ModifyMomentum`，无需独立原语。
- **恢复 `TargetKind.StackEntry` 以支持「取消疲劳」** — 否决：改为「可被削减至 0」，由 `ForTurns(1)` 条目 + 一条静止式修正表达，不新增栈筛选结构。
- **合并 `ModifierTarget` 与 `ModifierKey` 两套 key 空间** — 否决：两侧宿主不同；量纲与合并算法逐字相同已足够，合并会让战斗内运行态与 Profile 字段共用一个枚举。
- **给启动式异能设有限性闸** — 否决：见理由，改设动作链上限 → `ADR-0114`。

## 后果

- `systems/character-profile/deck/common-properties.md` 是语法权威；`systems/services/combat-service.md` 承载流水线与槽位编号。
- **`Sorcery` 不得带任何异能**（`Abilities` 须为空）——三档异能都以「在场」为前提，而 `Sorcery` 结算后进弃牌堆、从不落场。
- 疲劳的「可被削减至 0」由 `ADR-0088` 就地承载，本条不重复。
- AI 试算的例外规则因此成立：按进入本动作前的局面求条件 → `ADR-0113`。
- 单条目槽位数硬上限 32 是位掩码的直接后果，软警戒 4。
