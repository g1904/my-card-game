# enemy-codex

> 敌人图鉴 / **EnemyCodex** —— 图鉴族（见 `_index.md`）中的敌人一本，类 Pokédex：记录玩家已遭遇过的敌人信息，跨轮回持久。**遭遇一次即解锁该敌人的全部词条文案。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **敌人图鉴 = 账号级收集（已定案）。** 类似 Pokédex 的收集面：**追踪玩家已遭遇过的全部敌人及其信息**。它归 **PlayerProfile**（账号级、跨轮回持久），不随轮回清理——因此它是玩家跨轮回积累的**知识资产**，而非角色的轮回内状态。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **图鉴给「静态知识」，不给「动态情报」（已定案 · 分层纪律）。** 这条分层是图鉴与战斗信息体系共存的前提：

  | 通道 | 回答的问题 | 获取途径 |
  |------|-----------|----------|
  | **敌人图鉴** | 这个敌人**会做哪些事**（招式 / 意图类型池、大致强度） | 跨轮回遭遇积累 |
  | **意图揭示** | 它**这一回合**要做哪件事 | 由全局等级差被动决定（三档） |
  | **探查 probe** | 同上，但主动买 | 玩家付出代价 |

  因此**图鉴再全，也不会告诉玩家本回合的具体选择** —— 它**不架空越级时的意图黑箱**。反过来，探查再便宜也不揭示敌人的全部底牌。Source: 同上。
- **遭遇即记录，不必击败（已定案）。** 解锁触发是**遭遇**而非**击败**——**死亡至少换来知识**。这是「失败侧也应有产出」这一取向在图鉴上的落点：一次输掉的战斗仍然把这个敌人写进了图鉴，玩家下次面对它时更有底。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **它是「靠试错记忆」的制度化。** 越级遭遇的信息劣势不是纯粹的惩罚：玩家每一次遭遇都在向图鉴写入知识，下一次面对同种敌人时更有底。这把原本只存在于玩家脑中的经验变成**有存档、有收集感、有账号级成长**的正经系统。**「遭遇即记」正是这条意图的直接兑现**——不记击败只记遭遇，才让失败也在积累。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **词条内容 = 五项文案（已定案）。** 一个敌人的图鉴词条记录：

  | 项 | 内容 |
  |----|------|
  | ① | **人物背景** |
  | ② | **功法简介** |
  | ③ | **运作方式** |
  | ④ | **特点与弱点** |
  | ⑤ | **`EnemyTemplate` 中样本卡组的关键卡牌** |

  **一次遭遇，全文案解锁** —— 逐招式 / 逐项解锁**已否决**。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **五项全是描述性文本，这正是分层得以维持的原因。** 词条给的是「他走什么路数、怕什么、常用哪几张牌」，**不是**「他这回合出哪张、精确数值几何」——**因此图鉴再全也不侵蚀越级黑箱**，先前担心的「深度决定它对黑箱的侵蚀程度」这一顾虑由「只写文案、不写数值曲线」化解。Source: 同上。
- **词条文案挂在 `EnemyTemplate` 上，存档只记「已遭遇」。** 与「展示文案留在 `Resource` 上、存档态只带 `Id` + 可变状态」一致——**图鉴的存档负担因此接近一个 id 集合**，先前列出的「存档体积」顾虑基本消解。Source: 同上。
- **服务归属：profile-service。** 与其余账号级字段一致——图鉴的写入（遭遇 / 击败时的解锁）经 `profile-service.ProfileManager.TryApply(spec)`，与轮回内变更落在同一事务体系内。见 `systems/services/profile-service.md`。

> 条目共有字段与解锁语义见 `common-properties.md`；图鉴族总览见 `_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **敌人图鉴为账号级收集，归 PlayerProfile；与意图 / 探查按「静态知识 vs 动态情报」分层** —— 已定案。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **解锁触发 = 遭遇即记录（不必击败）** —— 已定案。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **五项词条的写作规格。** 内容项已定（背景 / 功法 / 运作方式 / 特点与弱点 / 关键卡牌）；仍待定：每项的**长度与写作口径**（几句？是否统一模板？），以及「关键卡牌」**列几张、由谁标注**（`EnemyTemplate` 上的显式字段，还是从样本卡组按某规则挑）。→ `common-properties.md`、`systems/adventure-event/combat/`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **计数字段是否要（遭遇 / 击败 / 败于其手次数）。** 解锁已是一次性全量，计数只服务于收集感与成就；要不要、记哪些未定。→ `common-properties.md`。
- **物化改写与词条的关系。** 敌人等级 / 卡组在物化时可被改写，而词条挂在模板上——**玩家读到的词条是模板的原样**，是否需要标注「本次遭遇的是 X 级」一类实例信息未定。→ `systems/services/future-event-service.md`。Source: 同上。
- **是否影响战斗内呈现。** 图鉴收录的「关键卡牌」，是否在第二档（仅类别）下额外可读？若是，图鉴就从「场外知识」变成了「场内信息面」，需重新评估与意图三档的关系。→ `systems/services/combat-service.md`、`ux/combat-ux.md`。
- **战斗内能否查阅。** 图鉴是只在主界面查看的收集面，还是战斗中可随时调出？后者会显著改变战斗节奏与信息压力。→ `ux/combat-ux.md`。
- **是否与成就 / 奖励挂钩。** 收集完成度是否发放 PlayerPower / PlayerItem 等奖励未定。→ `systems/player-profile/achievements/`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/codex/enemy-codex.md`（待建）。
