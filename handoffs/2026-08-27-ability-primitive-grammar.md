# 效果原语 / 异能语法定案

- id: 2026-08-27-ability-primitive-grammar
- date: 2026-08-27
- topic: systems/character-profile/deck/common-properties · systems/character-profile/deck/_index · systems/services/combat-service · systems/scoring · decisions/ADR-0088
- status: distilled
- distilled-to: systems/character-profile/deck/common-properties.md, systems/character-profile/deck/_index.md, systems/services/combat-service.md, systems/scoring.md, decisions/ADR-0088-fatigue-as-stack-entry.md

## Intent（distilled）

`ability/`（`AbilityData` / `EffectData` / `TriggerConditionData`）是卡牌 / 神通 / 法宝 / 法则 / 古宝五个内容类型的共同底座，其语法此前未定案，六处缺口一次补齐。本次只给**语法与结构**，一个数值都不给（`Amount` 取值域、道念量纲、starter deck 归统计校准）。

### 1. `EffectData` = 抽象基类 + 一个原语一个 `[GlobalClass]` 子类

分派用 `Dictionary<Type, IEffectHandler>`，**不引入 `EffectKind` 判别枚举**；否决「`Op` 枚举 + 扁平参数表」（四条判据：检视器可写性 · 链路类型一致性 · 加载期校验的归属 · 可加性）与效果表达式串。多态子类树与 `ProfileChangeSpec` 的 `ChangeElement` 否决多态**判据不同故不冲突**（后者落存档、进 diff、热路径构造；前者是内容侧 `Resource`、恒不落存档），这条区分必须并置写下，否则日后必被当成矛盾。

### 2. 静止式修正不是 `EffectData`，是并列的第二种定义体 `StaticModifierData`

`(Scope, What : ModifierTarget, Layer, Amount)`。第一层的定义是「**结算时执行**的原子操作」，而静止式修正不入栈、只在求值瞬间被读取；混装会让这句定义失真。`AbilityData` 上那格占位的 `Effect` 由此落定为 **`Effects` / `StaticModifiers` 两格 + 一条 XOR 校验**（与 `KeywordData` 的 `Effects` / `StateTemplate` 同构）。**静止式异能因此在结构上装不下任何原子操作**——「静止式不执行原子操作」由类型形状承担，不必再写校验。

- **`ModifierTarget` 首批五项**：`MomentumProduced` · `MomentumReduced` · `CardManaCost` · `DrawCount` · `FatigueAmount`。成员序视同冻结、只能追加。
- **量纲 = 万分比整数（`10000` = ×1.0），合并算法 = 「同层求和 → 只乘一次 → 只取整一次」**，与 Profile 侧的 `ModifierOp.Scale` 对齐；两套 key 空间（`ModifierTarget` / `ModifierKey`）分开保留、不合并。
- **`Scope` 按被修正量的宿主对象匹配**；宿主是卡牌时只吃 `RequiredSubtypes`（与 `HandCard` 槽位那条既定纪律同构）。

### 3. 首批原语八个 = 既有七个 + `BumpCounterEffect`

疲劳**不是**原语（栈条目结算时执行一条内建的 `ModifyMomentum(Self, −N)`，`N` 经求值管线）。扩展方式四步 + 准入判据「能用组合表达的一律用组合」。

### 4. 触发器 `TriggerConditionData`

`TimingId`（点分字符串 + **代码侧封闭常量表** `TimingIds`，首批十个）· `OwnerScope` · `TriggerFilter`（`EntryFilter` + `CardTypes` + 费用区间）。每个时点声明 `SubjectKind` 并校验相容格。保留字符串形态而不改枚举：点分惯例已被次类型 id 规范显式引用为先例，且加载期封闭集校验拿到的安全性与枚举等同。

### 5. 条件 = 封闭谓词小集合，挂 `EffectData.Conditions`，AND 语义

三个谓词（`CounterAtLeast` / `EntryCount` / `Momentum`）· **条件不满足 ≠ fizzle** · 可被 UI 预判的门不得写成 `EffectCondition` · 单一落点（不挂 `AbilityData`）。

### 6. `CardData` 收口

费用 = 独立 `ManaCost : int` · **取消触发器格**（`Abilities` 已承载）· 新增 `OnPlay : EffectData[]`（仅 `Sorcery` / `Affliction`；阵法入场走 `entry.entered` 触发）。

### 7. 槽位在栈条目层扁平化编号

`chosenTargets.Length == Σ(element.TargetSlots.Length)`；`FizzledSlots` 位掩码 ⇒ 单条目槽位数硬上限 32、软警戒 4。既有两处「长度 = 该效果 `TargetSlots` 长度」的不变式同批改写。

### 8. 效果流水线 = 五个阶段，挂起点唯一

`1 重检 / 挂起 → 2 关键字展开 → 3 数值求值 → 4 逐 element{条件 → 施加} → 5 收口`。六条规则见 `systems/services/combat-service.md`。`IEffectHandler` 拆 `Evaluate` / `Apply`，随机只在 `Apply` 内取 `combat` 子流。

### 9. 存档面

**零新增字段、空迁移。** 四类定义体全部是内容侧静态定义，经 `CardId` / `abilityId` 解析而来。

## Clarifications（interview 产物）

- **疲劳「可被取消」与「`TargetKind` 无 `StackEntry`」两份已定案文档直接冲突** → 裁决：**不设取消通道，改为「可被削减至 0」**（`ForTurns(1)` 战场条目 + 一条把 `FatigueAmount` 削到 0 的静止式修正）。原语清单**没有**第 9 个原语，不恢复 `TargetKind.StackEntry`、不新增栈筛选结构。连带改写 `ADR-0088`（标题 / 决策 / 理由 / 备选四处）、`combat-service.md` 四处、`scoring.md` 一处。
- **`ModifierTarget` 首批清单宽度**（真取向：它决定「哪些数值能被卡牌改写」的设计面宽度）→ 裁决：**中档五项**。不收 `HandLimit` / `ManaLimit` / `TurnLimit`——它们各自撞一条已定的层级归属。
- **条件求值的时机：阶段内一次性求完 vs 逐 element 就地求**（草稿自相矛盾）→ 裁决：**逐 element 就地求**，规则「前一条改了道念，后一条的条件读到的是改后的值」原文保留。代价一并写下：**AI 试算按「进入本动作前的局面」求全部条件，试算与真实结算可能走不同分支**；`combat-service.md` 的「试算按 `EffectData` 在求值管线上跑一遍」那条随之补写例外；「阶段 1–4 全路径无副作用」改写为「`Evaluate` 与条件求值无副作用」。
- **`TimingIds` 首批清单是否含 `momentum.changed`**（唯一零先例、且带无界触发链风险的一项）→ 裁决：**保留，首批十个**。无界触发链的担忧由链长护栏承接（下条）。
- **启动式异能的有限性闸** → 裁决：**推翻硬性限制**。删除「`Kind == Activated` ⇒ `ManaCost >= 1` 或 `MaxActivationsPerCombat >= 1`」这条加载期校验；**组合技达成无限是被接受的设计面**，终止性由 `TurnLimit` 承接，避免非本意的无限归内容侧纪律。`Kind != Activated` 时配额须为 `-1` 那条**保留不动**（它防的是「作者以为配额生效」，与无限性无关）。
- **自动触发链的运行期护栏（跨草稿追加）** → 裁决：**设单次动作链的栈条目总数上限 N，超限中止链路并 `PushError`**，N 落 `CombatRulesData`。它只阻止进程不返回，不限制任何玩法设计面。
- **`MoveCard` 的目的地形态**（与同批 card-pool 草稿冲突）→ 裁决：`To : CardZone` 保持四值 + **新增独立一格 `InsertPosition { Top, Bottom }`**（仅目的地为抽牌堆时有意义）；校验 8 放宽为「`From == To` 且 `To != DrawPile` → `PushError`」⇒ **允许抽牌堆内重排**。
- **`StaticModifierData` 的量纲与合并算法须与 Profile 侧对齐** → 裁决：两套 key 空间分开保留，但**量纲统一为万分比整数、算法统一为「同层求和 → 只乘一次 → 只取整一次」**。

**标准默认（自动采纳，不占 interview）：**

- 关键字展开排在条件与数值求值**之前**——否则模板内元素自带的 `Conditions` 永不被求值。
- `BumpCounterEffect` / `CounterAtLeastCondition` 出现在 `CardData.OnPlay` 内 → `PushError`（`OnPlay` 的 element 没有宿主异能，键拼不出来）。
- 阶段 5 的「默认 counters +1」只对 `abilityId` 非空的栈条目成立（`PlayedCard` / `Fatigue` 没有异能主体）。
- 求值管线不只在效果参数上被调用：费用灰态预判（`CardManaCost`）与抽牌流程（`FatigueAmount`）是另两处消费点。
- 「需要选目标的触发式异能 ≤ 10%」的统计式 `PushWarning` **已存在**，只回链、不重复登记。
- `EffectData` 多态与 `ChangeElement` 否决多态的判据区分**写进文档**。
- 代码落点 `combat-service > StackManager > EffectProcessor > handler` 与既定层级判据完全对齐，无需再论证。

## Open questions

- **原语 / 关键字 / 次类型三份首批清单的最终确认**须等 starter deck 设计过程走一遍；本次给的是机制与首批推演值，不是终值。
- **单次动作链的栈条目上限 N 的取值**归内容扩充后的统计校准。
- `Item`（法宝 / 古宝）的一次性使用效果仍无落点：`UseItem(itemId, targets)` 是一等玩家动作，但 `ItemData` 上没有效果格，而道具不是战场条目、走不了 `ActivateAbility`。**属既有 under-specification，本次未引入也未闭合**，落点在 `systems/character-profile/item/` 与 `systems/player-profile/player-item/`。
- `Sorcery` 带 `Triggered` 异能的合法性未被任何校验覆盖（既有规则只禁 `Static` / `Activated`），属既有校验表的缺口。
