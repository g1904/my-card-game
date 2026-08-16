# Answer log combat-solutions

- 日期：2026-08-06
- 来源：`inbox/combat-solutions.md`（2882 行 · 五组 · 覆盖 38 条战斗待答，已带用户逐节裁决）→ `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`
- 移出条数：**38**

## 第 1 组 · 赋级带与意图（8 条）

1. **`±2` 赋级带与意图揭示阈值的算术冲突** → 采纳「调阈值」收口：三档整体收紧一级（ch1 `≤−2` / `−1~+1` / `≥+2`；ch2 · ch3 `≤−1` / `=0` / `≥+1`），三档在带内全部可达；**赋级带回退三章统一的对称 `±2`，08-06 / 08-06b 的 `[−4, +2]` 与「降阶 = 碾压」硬门作废**；「碾压」重定义为「压到带内下界」。（`systems/balance.md`、`systems/adventure-event/combat/_index.md`、`systems/services/combat-service.md`、`ux/combat-ux.md`）
2. **`±2` 是硬规则还是默认带** → **硬规则，无例外**；剧本调制不得改写，赋级函数不接受任何区间覆盖参数；绝境感只能由样本卡组 / item / power / 遭遇参数四个旋钮表达。（`systems/balance.md`、`systems/services/future-event-service.md`）
3. **境界边界处 `diff = +2` 的残余量纲** → **`lifeTotalLimit` 概念整体删除**；改由境界基线一次性跃升承载（公式 `≈ ceil(1.1 × 最坏开局落差)` → 炼气 10 / 筑基 25 / 金丹 40），配套要求回复类事件幅度随境界跳档。（`systems/character-profile/life-total.md`、`systems/balance.md`、`terminology.md`）
4. **敌人赋级的分布规则** → 基础权重表（按角色在本境界内的等级位置分三段）× 调制修正 × 截断重分配 × 批内去重；众数恒为 `diff = 0`。（`systems/balance.md`、`systems/services/future-event-service.md`）
5. **意图类别的枚举** → `IntentCategory { Offense, Defense, Buff, Special }`，以道念语义定义、内容侧静态标注、20% 贡献阈值选主类别；完整档一个数字位靠符号区分。（`systems/adventure-event/combat/_index.md`、`ux/combat-ux.md`）
6. **敌人等级标注的措辞** → 面向玩家一律「境界名 + 层级」，全局序不出现在任何 UI；`EventOption` 上并列双方等级、战斗屏内不并列；**不做方向标记**。（`ux/combat-ux.md`）
7. **物化时「充实 / 改写」敌人的规则** → 五旋钮管线（选池 → 赋级 → 卡组对齐 → item/power 取自模板 → 遭遇参数），等级先定且不叠第二条强度曲线；**剧情线不可调制模板，改由地点 / 剧情线专属池表达**；「关键卡牌不得被改写」为可机械检查的上界。（`systems/services/future-event-service.md`、`systems/enemies/`）
8. **`EnemyTemplate` 与 `EnemyData` 的关系 + 物化实例的承载** → 同一个东西，统一定名 **`EnemyData`**；实例 = **`EnemyInstance`**（定稿不可变、嵌在 `EventOption` 上随批次落存档）；**不存在多敌人场景，字段写单数**；`TurnLimit` / `VictoryRule` 落 `EncounterSpec`。（`systems/enemies/`、`terminology.md`、`systems/architecture.md`）

## 第 2 组 · 存档与结构（7 条）

9. **战场与栈的存档字段形态** → `ActiveCombat` 挂 `CharacterProfile`、可空、收口即清；战场单表 + `kind` 三档、栈条目数组序即栈序、`pending` 全局至多一个、道具只落 `UsesThisCombat`、`Power` 运行态即战场条目的 `counters`；四条读档校验（含闭集不变式断言）。（`systems/services/combat-service.md`、`systems/character-profile/_index.md`、`sync-service.md`）
10. **挂起态的取消语义** → 恢复回到该选择点、栈原样挂起、**不允许反悔**；连带硬要求「选目标态必须自解释」。（`combat-service.md`、`ux/combat-ux.md`）
11. **需要选目标的触发式异能的频度** → **稀少（≤ 10%）**，作为设计亮点；一场期望进入挂起态 1~2 次；连带「挂起态存档不做专门优化、栈的增量写入不做」。（`combat-service.md`、`systems/character-profile/deck/`）
12. **决策点的粒度** → D0–D6 清单，**保留 D2**；缓冲上限闸门口径确认为事件级存档点，战斗内决策点不参与软阻塞判定。（`combat-service.md`、`life-cycle-service.md`、`sync-service.md`）
13. **`attemptIndex` 是否还需要** → **整层删除**，`Hash64(combatStreamSeed, eventId)`；`RetryChapter` 内部生成新 seed；「篇章重试是重开一局，不是重打这一局」。不 bump schema、无迁移。（`systems/common-properties.md`、`life-cycle-service.md`、`sync-service.md`）
14. **`AdvanceEventAsync` 的取消触发方** → 只有「玩家主动退出」与「后端挤下线」两个真触发方；**`ct` 只在决策点被观察**（取消点与存档点永远重合）；新增 `AdvanceStage.Cancelled`；**玩家退出静默处理、不做二次确认**。（`life-cycle-service.md`、`ux/combat-ux.md`）
15. **module 以下的下沉判据** → processor 三条与门判据 + handler 的「开放 kind」判据 + 三条反判据；**第四 / 第五级暂不落实例**，`BattlefieldManager` 提级仍不推荐。（`systems/architecture.md`）

## 第 3 组 · 卡牌与规则（7 条）

16. **次类型的具体清单与 id 形态** → `CardSubtypeData` schema（权威匹配面 = `AllowedCardTypes` 字段）、id 规范 `<maintype>.<name>`、单一全局索引、准入判据（3 条目 + 1 payoff）、17 条初值清单；**`Ambush` → `enchantment.ambush`**，移除 PascalCase 暂定标识符。（`systems/character-profile/deck/_index.md`、`terminology.md`）
17. **回合三步结构留下的卡牌侧空缺** → 起手 5 / 每回合抽 2（首回合照抽）/ 不设先后手差 / 手牌上限 10 / 敌人侧完全同值；三项住在平衡资源且 `EncounterSpec` 可空覆写。（`systems/balance.md`、`deck/_index.md`）
18. **「回合内状态」的判定边界** → 生命周期三件套 `EntryLifetime` × `CountdownSide` × `RemainingTurns`；结束阶段清理判据可直接写成代码；「持续到下回合结束」是三件套的组合；**非永久条目可被针对但效果须显式声明目标类别**。（`deck/_index.md`、`combat-service.md`）
19. **回合内的效果 / 状态系统** → 三层结构（`EffectData` / 战场条目 / 求值管线）；求值 = **加法层 + 乘法层**且「加法先于乘法」写成规则；**本作不存在「参战方身上的 buff 列表」**；`CardInstance` 运行态判据 = 有无过期时刻。（`deck/_index.md`）
20. **敌方卡组的设计形态** → **共用 `CardData` 体系、不共用卡池**（`CardData.Pool` 三值枚举，必填无默认）；卡组规模固定 15、允许重复条目；抽牌同规则但走独立子流。（`deck/_index.md`、`systems/enemies/`）
21. **探查（probe）的实现形态** → 仍搁置到内容横向扩展阶段，但方向一并定死、**不再作为待答项挂着**：**升一档、不打穿越阶黑箱**（规则层结论）· 古宝 + 阵法双载体 · mana 为主 + `Charges` 为辅、排除弃牌 · 只揭示当回合快照。（`deck/_index.md`、`combat-service.md`）
22. **`manaLimit` 推拉的分档** → 单次幅度**恒为 1**；分档表（闭关为主通道、Finale 每章一次保底、探索是唯一常见下降来源、**战斗类不给**）；一章净增 +1~+2，**牌流是增长的天花板**。（`systems/character-profile/mana.md`）

## 第 4 组 · 奖励与遭遇参数（7 条）

23. **胜利侧的「道念差 → 奖励厚度」换算** → 两条支路：强制奖励 `1:1 × 可调单价`（单价逐篇章下调）、可选奖励归一化 `advantage` 三档。（`systems/balance.md`、`systems/scoring.md`）
24. **可选奖励的候选生成** → 固定 3 项、道念差只改质量；池 = 事件模板的 `RewardPoolId` 经 `AllEnabled()` 取；**结果预先算定并落存档，恢复时读结果不重抽**；不设放弃通道；池不足显式降级。（`combat-service.md`）
25. **回合数与胜负判据落在哪个类型上** → 落 `EncounterSpec`（改为 `sealed record`），物化时从 `AdventureEventData` 代入，`EnemyData` 完全不携带；胜负判据参数化为 `(WinMargin, DrawCountsAsLoss)` 两个数；`IsFinale` 收编为 `EventType`。（`combat-service.md`、`future-event-service.md`）
26. **Practice / Finale 的具体改写值** → Practice 8 / `(0,false)`、Combat 10 / `(1,false)`、Finale 12 / `(N,false)`，`N` = 3 / 5 / 8；**难度旋钮 = `WinMargin`，回合数 = 节奏旋钮**；**Finale 失败不直接 defeated**（走既有 `LifeTotalExhausted` 通道，失败后可再次挑战）。（`practice/_index.md`、`finale/_index.md`、`systems/balance.md`）
27. **Practice 的对手来源** → 复用同一批 `EnemyData` + `EncounterScopes` 作用域字段；天劫也在同一批里；承重论据 = 图鉴的教学路径。（`systems/enemies/`、`practice/_index.md`）
28. **enemies 归属** → **升为 `systems/enemies/`，与 `adventure-event` 平级**；五处引用方改为薄引用，一次做完。（`systems/enemies/`、`systems/_index.md`、`systems/architecture.md`）
29. **`EncounterSpec` / `CombatSnapshot` / `TargetRef` / `PlayResult` 的完整字段** → 四个类型字段全给；`MomentumDelta` 四字段承载「声明量 vs 实际量」；`SideSnapshot` 单类型；**新增 `ProvideTarget` API 补上目标回传缺口**；`CombatSnapshot` 按变更广播 + 缓存。（`combat-service.md`）

## 第 5 组 · 数值进程与呈现（9 条）

30. **`experiencePoint` 的阈值曲线与产出分布** → 由事件总数反推；境界内递增 + 境界间重置量纲；ch1 阈值表（合计 79）/ ch2 114 / ch3 138；`ExperienceGrade` 四档 + 阈值与给予量同比放大；失败 50%；**承重推论：Finale 之前必须已升满**。（`systems/balance.md`、`systems/game-progression.md`、`finale/_index.md`）
31. **等级产出的频次与分布** → 75% 覆盖率 + 类型档位偏置（与 location 的类型修正自然咬合，**不为 location 再加经验字段**）；失败产出 = 一条 reward 两个字段（`FailureRatio`）；**ch2 / ch3 升级稀疏由常驻经验条补偿**（同时答复「中长期规划感」的进度那一半）；eventOption 卡片不标注经验档位。（`game-progression.md`、`ux/screen-flow.md`）
32. **道具折价系数 / 战斗内法则的强度上沿** → 折价按 `Charges` **分层**（0.55 / 0.65 / 0.75 / 0.90），「不受抽牌运的溢价」写成公式；法则闸门 = 单条 ≤ 10% + **老账号全开合计 ≤ 25%** + 不得随对局延长累积；**ch1 前段只能是纯信息 / 便利类**。（`systems/balance.md`、`character-profile/item/`、`player-profile/player-power/`）
33. **「1% 的游戏场景」的分母口径** → 分母 = 一次轮回中玩家进入并结算的战斗类遭遇总数、分子按「实际结算」计；**1% ≈ 每 3 次完整轮回一次**；R1–R5 编排规则；**R3 需一个 `CycleState` 布尔位** ⇒「1% 不落代码」措辞微调。（`systems/balance.md`、`player-profile/player-power/`）
34. **储物袋的 UI 形态** → 不进主菜单（挂轮回内的角色状态条）；全屏滚动网格 + 筛选 chip、不分页；**同 `Id` 可持有多份、堆叠显示 `×N`**；战斗内视图定名 **「随身」**（角标 + 底部抽屉）。（`ux/screen-flow.md`、`ux/combat-ux.md`、`character-profile/item/`、`terminology.md`）
35. **选目标态的呈现形态** → **唯一合法目标时不进入该态**（规则层，削掉约一半进入次数）；暗幕 + 来源上浮 + 固定指令条；**单点即确认、不做二次确认、误触不做保护**；连锁进度取 `还有 N 项待结算`；与「响应窗口」严格区分的三条禁令。（`ux/combat-ux.md`）
36. **快照与执行偏差的呈现形态** → `≈` + 虚线底纹；飘字为主 + ticker 为辅（ticker 默认显示最近一行）；**偏差对照标记**是最关键的一项；敌人回合演出 ≤ 4 s、可 3× 加速但**加速对偏差步无效**。（`ux/combat-ux.md`）
37. **意图区收起后的布局稳定性** → **固定预留高度 + 敌人回合复用为结算日志 ticker**（同一信息槽的两个时态）；**明确修订「不换成其他指示」那一句**；≈ 屏高 8%、永不换行、无高度动画；元素上移排除。（`ux/combat-ux.md`）
38. **敌人图鉴的写作规格与实例信息** → 五项长度与口径（总 150–280 字、**不含阿拉伯数字**、弱点必须可行动）；关键卡牌列 3 张由 `KeyCardIds` 显式标注；实例信息 = 静态正文 + **动态页眉**（只写境界名 + 层级）；**战斗开始即可读全部五项**，结算 / 选目标态禁用入口。（`player-profile/codex/enemy-codex.md`、`systems/enemies/`）

## 连带被推翻的既有条目

- **08-06 / 08-06b 的「ch1 赋级带 `[−4, +2]` + 降阶碾压硬门 + 阈值不动」整体作废**，以本次的「阈值收紧 + 带回退 `±2`」取代。连带作废：「ch1 落差只在领先侧拉宽」「ch1 黑箱只集中在炼气末两级」及其内容侧补偿之问（该待答项前提消失，已删除）。
- **`ux/combat-ux.md` 的「意图区收起后不换成其他指示」**被修订为「收起后该槽位在敌人回合复用为结算日志 ticker」。
- **`lifeTotalLimit` 及一切「耐久上限」表述**在全库活文档中删除。

## 台账原记（自 `_index.md` 归并）

> 台账瘦身前，`answer-logs/_index.md` 本行记有以下内容，原样保留于此。

战斗待答方案草稿汇总，五组 · 已带用户逐节裁决）：**`01-combat.md` 的 38 条战斗待答一次性全部答结** —— 意图三档阈值整体收紧一级且**赋级带回退三章统一的对称 `±2`**（推翻 08-06 / 08-06b 的 `[−4, +2]` 与降阶碾压硬门）/ **`lifeTotalLimit` 概念整体删除** / `ActiveCombat` 存档 schema 与 D0–D6 决策点清单 / 卡牌侧数值与效果系统三层骨架 / 遭遇参数收进 `EncounterSpec` / **enemies 升为与 adventure-event 平级的系统** / 经验曲线与分布 / 道具折价分层与法则强度闸门 / 1% 分母口径 / 九项呈现形态定稿
