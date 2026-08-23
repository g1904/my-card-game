# 敌人样本卡组规模 · 疲劳量的旋钮层级

- id: 2026-08-22-enemy-deck-size-and-fatigue-knob
- date: 2026-08-22
- topic: systems/enemies/common-properties.md · systems/balance.md · systems/player-profile/codex/enemy-codex.md · systems/character-profile/deck/_index.md · terminology.md
- status: distilled
- distilled-to: systems/enemies/common-properties.md, systems/balance.md, systems/player-profile/codex/enemy-codex.md, systems/character-profile/deck/_index.md, terminology.md

## Intent（distilled）

一句话：**卡组规模两侧皆不设硬限，敌人侧的唯一硬校验是「不得为空」；疲劳扣减保留为全局常量，不升格为 per-encounter 覆写。**

两问同属「卡组规模 / 疲劳」这一组旋钮——卡组规模是疲劳的**触发条件**，疲劳是小卡组的**对价**。

### ① 样本卡组规模：不设硬限

`systems/enemies/common-properties.md` 的字段表曾把样本卡组写成「规模 15」，而全库其余六处（`enemies/_index.md`、`balance.md`、`services/combat-service.md`、`character-profile/deck/_index.md`、`adventure-event/combat/_index.md`）一致写「两侧皆不设硬限」。以**不设硬限**为准，理由三层叠加：

1. **数字自身的推导已不成立。** 「15」= 起手 5 + 5 回合 × 2，意在「保证一场内永不重洗」；重洗规则已删除、起手已改为 4，两条前提都不在了。
2. **权威面。** 「不设硬限」已在六份活文档收敛，其中 `combat-service.md` 把它写进了决策小节。
3. **它与「规模是一条可用的编排旋钮」直接相抵。** 规模偏小的卡组在后期真实触发疲劳，这正是「牌少而精」的内建对价；锁死规模等于关掉这条维度。

**「15」不降格为「编排参考值」保留。** 那张表是**字段形态与加载期校验表**（每行第三列是缺失时的 `PushError` / `PushWarning` 处置），把一个不校验的建议值放进校验表正是这次漂移的成因。**内容侧也暂不给编排锚点数字**——卡组规模的取值区间归 ch1 数值标杆专场，此时给锚点等于提前拍一个没有依据的数。

**新增一条下界校验：样本卡组为空序列 → `PushError`（带模板 `Id`）。** 它与既有的「`EncounterScopes` 空数组 → `PushError`」同族，校验的是**漏填**而非**规模**，不构成对「不设硬限」的回退：空卡组的敌人从第 1 个回合起每回合稳定 −2 道念，在敌人侧不存在任何正当编排路径（玩家侧的「卡组可被弃空」是有意允许的构筑后果，那是玩家的选择，敌人侧没有对应路径）。

### ② 疲劳扣减：不进 `EncounterSpec` 覆写组

先拆一个措辞歧义：疲劳扣减**已经是可调的**——它住在平衡资源 `CombatRulesData` 上，随 overlay 热更可改，完全满足「可调数值属数据资源、不硬编码」。真正的问题是**要不要再加一层 per-encounter 的可空覆写**（与抽牌数 / 手牌上限同档）。

**不加。** 三条理由：

1. **没有 payoff。** 疲劳只打**抽牌方自己**，不是一条攻击对手的通道。要构成「疲劳流」这类构筑方向，玩家必须能削减对手的抽牌堆——而 `EffectData` 的原子操作里唯一沾边的 `MoveCard` 明写为「闭集内的流转，不新造牌」，全库没有任何一处陈述过「削对手牌堆」形态的效果。没有 payoff 就没有构筑方向。
2. **量纲撑不起一条路线。** 单方一场牌流入上限 14 张（起手 4 + 5×2）；对手要被磨到空堆须其卡组本就更小，**而那是对手自己的编排选择、不是玩家能施加的压力**。即便对手从第 1 回合起就空堆，5 回合疲劳总量也只有 −10 上限。
3. **覆写组的动机不迁移到这一格。** 抽牌数 / 手牌上限进覆写组的理由是「更宽容的 `Practice`」——多抽一张是立刻可感的宽容度。疲劳的触发窗口由**卡组规模**决定、不由**档位**决定：`Practice` 的回合数更短反而使疲劳更难触发，调它买不到宽容度。

代价一侧：多一格意味着每个消费点都要写一次 `??` 合并，且「哪些字段可被 `EncounterSpec` 覆写」这份记忆清单又长一格——与「关键字清单当前归零，故不为空清单预铺第二类键」「`EnemyInstance` 不留恒长 1 的伸缩位」是同一个反模式。

**这条取向须在 `balance.md` 明写为「刻意不加」而非留白。** 疲劳扣减与抽牌数 / 手牌上限同住一张表，不写理由的读者会把它当成漏项重开。并记三条**重开判据**：① 出现真的削减对手抽牌堆的内容条目；② 某个遭遇档需要显式调节疲劳压力（而非靠卡组规模编排）；③ ch1 数值标杆定出卡组规模区间后，实测发现疲劳几乎从不触发、或普遍在第 3 回合前就触发。

### ③ 「疲劳」进术语表

疲劳是一条被多份文档反复引用的**规则**（无载体、无卡面、不入栈，是抽牌流程内的一次直接扣减），此前未在 `terminology.md` 立项。定名代码标识符 **`FatiguePerDraw`**（扣减量字段）。它与 MTG / 炉石的同名概念有两处实质出入：本作抽牌堆**不重洗**且空堆抽牌**不致死**，只扣道念、下限 0 逐次截断。

### ④ 连带的活文档订正

- `enemy-codex.md` 三处以「15 张」为前提的说理。**「关键卡 3 张」这个结论本身不受影响**，动的只是说理里的数字——两条理由（「完整列表把词条从事前知识推向事中情报」「与一屏读完相抵」）都不依赖具体数字，后者改以「规模不设硬限 ⇒ 词条长度无上界地涨」承接，论据反而更强。
- `character-profile/deck/_index.md` 的敌人抽牌规则行沿用了旧的手牌上限 9。权威是 `systems/services/combat-service.md` 与 `systems/balance.md` 的 **7**，此行跟改。

## Clarifications（interview 产物）

- **样本卡组规模两处矛盾以哪侧为准** → **两侧皆不设硬限**（`enemies/_index.md` 与 `balance.md` 的现行结论为准），改写 `enemies/common-properties.md` 一侧。原始草稿曾把「15 是否降格为编排参考值」列为待定，裁决为**直接删掉这个数字**、不保留。
- **空样本卡组是否 `PushError`** → **是**（草稿的选项 A）。这是超出「修漂移」范围的新增校验，故须点头；校验的是漏填而非规模。
- **是否给内容侧一个编排锚点数字**（草稿曾建议若给则取 14） → **不给**，规模区间归 ch1 数值标杆专场。
- **疲劳量是否加 `EncounterSpec.FatiguePerDraw`** → **不加**，保留 `CombatRulesData` 全局常量 `1`。草稿曾把「覆写组本体尚未落在 `EncounterSpec` record 定义里」列为前置依赖；该缺口已在同批被独立补齐，但**不改变本结论**——否决理由是缺 payoff 与缺量纲，与覆写组是否存在无关。
- **「疲劳」是否进 `terminology.md`** → **进**，标识符 `FatiguePerDraw`。

## Open questions

- **卡组规模的实际取值区间（玩家起始卡组 / 敌人样本卡组）** 未定，归 ch1 数值标杆专场。它同时是上述三条疲劳重开判据中第 ③ 条的实证输入。

## Notes / triage

来源草稿：`inbox/archive/solution-draft-enemy-deck-size-and-fatigue-knob.md`（`/provide-solution-draft` 产出，用户已评审）。
`answer-logs/log-combat-solutions.md` 第 20 条仍记「卡组规模固定 15」——answer-log 是历史记录、不是活文档，不改。
