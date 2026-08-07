# adventure-event / practice（AdventureEvent-Practice）

> 修炼：比试 / 切磋——低风险战斗式历练。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **修炼（Practice）= 战斗的变体（低风险历练）。** 语义为比试 / 切磋；与 Combat 一样**走战斗结算**，但风险较低。Source: `systems/adventure-event/_index.md`、`terminology.md`。
- **属于走战斗结算的类型。** Practice 复用 Combat 的回合制战斗模型：**mana 出牌 + 道念定胜负**，失败时按道念差扣 life（见 `systems/scoring.md`）。Source: `systems/adventure-event/_index.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **复用 combat-service 的参战方结构（已定案）。** Practice 使用 **CharacterManager + EnemyManager**，与 Combat 同一套回合循环与参战方模型——它是 combat 的**变体**，差异在胜负条件、风险与奖励结构，不在代码结构。因此**切磋对手就是 Enemy**（各自持有卡组）。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **Practice = 三档难度中的「小盲」（已定案）。** Practice / Combat / Finale 对位 Balatro 的 **small / big / boss blind**——Practice 是**最轻的一档**。**「低风险」由难度旋钮直接承担**：Practice 的**胜负条件与回合数均可相对 Combat 改写**，整体**比 Combat 更简单**。**推论：不必靠「失败不扣惩罚」这类特例来实现低风险**——把回合数与胜负门槛拧松即可，结算规则与 Combat 保持同一套。标准 Combat 是 10 回合、道念高者胜；Practice 的具体改写值未给，见待决问题。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **Practice 的具体改写值 = `TurnLimit 8` + `VictoryRule(WinMargin 0, DrawCountsAsLoss false)`（已定案 · 初值）。** 语义 = **道念相等即判胜**，「点到为止」。**减到 8 回合**：追分窗口少 2 回合，但追分要求从「反超」降到「追平」——**两侧相抵，净效果是更简单且更快**，快正是 small blind 该有的节奏，也直接服务篇章时长控制。**难度旋钮是 `WinMargin`，回合数是节奏旋钮。** **推论：`CombatOutcome.Draw` 在 Practice 档永不可达**（相等即胜）——干净的退化，不是缺陷，但呈现层需知晓。取值与理由见 `systems/balance.md`。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **意图揭示规则同 Combat。** 按全局等级差三档揭示（见 `systems/services/combat-service.md`）。**「低风险 ⇒ 天然给完整意图」不成立**——Practice 的对手同样只能落在 `diff ∈ [−2, +2]` 内，信息档位与 Combat 用同一张阈值表。
- **对手赋级同受 `±2` 带约束（已定案 · 08-05）。** 赋级规则**挂在 Enemy 上、不挂在事件类型上**，故切磋对手与 Combat 的敌人适用同一条区间与同一张权重表。**推论：Practice 的「低风险」由回合数与胜负门槛承担，不由「派个更弱的对手」承担**——与「低风险落在难度旋钮上，不落在结算特例上」的既定分工完全同向。Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md`。
- **对手来源 = 复用同一批 `EnemyData`，由 `EncounterScopes` 声明作用域（已定案）。** 不另立一批「切磋对手」条目：同门师兄、道友一类标 `[Practice]`，凶兽、魔修一类标 `[Combat]`，两者皆可的标 `[Practice, Combat]`。**承重论据 = 图鉴的正向增益**——共享池使玩家能**先在低风险的 Practice 里遇到并解锁某个敌人的图鉴，再在 Combat 里正式对上它**，这条教学路径正好补上「意图揭示退出教学职能」后留下的空缺；另立一批则图鉴要么翻倍、要么分裂成两套，且敌人条目是本作最重的内容单元之一。见 `systems/enemies/`。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Practice 为分类法第一类，修炼 ≈ 比试** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **Practice = small blind 档，回合数与胜负条件可相对 Combat 改写、整体更简单** —— 已定案。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Practice 的奖励厚薄：** 回合数与胜负门槛已定（8 / `WinMargin 0`）；**奖励是否相应变薄**（`BaseReward` 与 `RewardPoolId` 的取值）未定，归 **ch1 数值标杆专场**。→ `systems/balance.md`。
- **叙事一致性的编写口径：** 标为 `[Practice, Combat]` 的敌人条目，其图鉴与台词须同时说得通「切磋」与「厮杀」两种语境——具体口径归 `systems/player-profile/codex/enemy-codex.md` 的写作规格。
- **与隐藏属性的交互：** 修炼是否推拉道心 / 煞气 / 寿元未定。→ `systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/practice.md`（待建）
