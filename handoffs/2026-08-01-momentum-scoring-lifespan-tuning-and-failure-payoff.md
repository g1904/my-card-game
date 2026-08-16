# 道念取代 life 成为胜负判据 + 寿元定价按目标时长分档 + 失败侧产出

- id: 2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff
- date: 2026-08-01
- topic: systems/scoring, systems/character-profile/life + mana, systems/adventure-event/combat, systems/services/（combat / future-event / life-cycle / plot-manager）, systems/balance, systems/game-progression, systems/player-profile/（enemy-codex / player-power）, ux/（combat-ux / screen-flow）, vision/（scope / references）, terminology
- status: distilled
- distilled-to: terminology.md, systems/scoring.md, systems/character-profile/（life.md, mana.md）, systems/adventure-event/（common-properties.md, combat/**, practice/**）, systems/services/（combat-service.md, future-event-service.md, life-cycle-service.md, plot-manager.md）, systems/balance.md, systems/game-progression.md, systems/architecture.md, systems/_index.md, systems/player-profile/（enemy-codex/**, player-power/_index.md）, ux/combat-ux.md, ux/screen-flow.md, vision/scope.md, vision/references.md, open-questions.md, answer-logs/log-0801.md, `systems/scoring.md（重写）`, `systems/character-profile/（life.md 重写, mana.md）`, `systems/services/（combat-service, future-event-service, life-cycle-service, plot-manager）`

## Intent（distilled）

**一句话：** 本次是对**整条玩法循环**的一次结构性评审后的逐条裁决——战斗的胜负判据从「life 归零」换成**道念（momentum）高者胜**并就此填满空白的 `scoring.md`；寿元从「基准 1 的占位定价」改为**由目标游玩时长反推的分档旋钮**并允许剩余寿元跨篇章结转；隐藏属性在**跨档时给一条定性叙事**；等级成长定为**事件产出（含失败）**、敌人等级**精确标注**；失败侧首次有了产出（图鉴遭遇即记 + 道统残卷概率累积）。

被评审的循环形态（评审时的实况，无争议部分）：

```
登录 → 主菜单（择已解锁篇章）
  └─ 篇章循环：
       future-event-service 物化一批 eventOptions（location 框定 + AdventurePlot 调制 + seeded RNG）
         → 横向滑动菜单择一（受 eventPriority 封锁、ifMandatory 封锁跳过）
         → TryApply(selectCost | skipCost)
         → resolver 结算（Combat / Practice / Finale 走战斗；其余六类走 GenericEventResolver）
         → 合并 outcome + lifeSpanCost + 隐藏属性推拉为一次 TryApply → 记 pastEvent → 自动存档
         → 重算下一批
       ...直到 Finale 突破 → 篇章边界存档 → 下一篇章
```

架构骨架（一事件 = 一事务 = 一存档点、模板 → `EventOption` 物化、两级 service ⊃ manager）**评审确认扎实**，本次不动。裁决集中在玩法闭环的空洞与几处互相打架的定案。

---

### ① 寿元与 `lifeSpanCost` —— 目标时长驱动的分档

**`lifeSpanCost` 用正数表示消耗（已定案）。** 当前的 `1` 是**占位值**，不是设计意图；符号约定亦不再写成 `-1`。

**与 `ProfileChangeSpec` 带符号约定的协调（已定案 · 两条约定各自成立）：**
`systems/adventure-event/common-properties.md` 现载「代码形态 = `ProfileChangeSpec`，`ChangeElement.BaseValue` **带符号**：负 = 消耗，正 = 产出」——**该约定不变**。`lifeSpanCost` 是**内容侧作者标注的正数量值（magnitude）**，由 **future-event-service 在物化组装 `selectCost` / `skipCost` 时取负**填入 `ChangeElement.BaseValue`。即：**内容作者写正数，spec 里仍是负数**，二者互不推翻。

| 层 | `lifeSpanCost` 的形态 |
|----|----------------------|
| 内容侧（`AdventureEventData.tres`、平衡分档表） | **正数量值**（消耗多少寿元） |
| 物化产出（`EventOption.SelectCost` / `SkipCost` 内的 `ChangeElement.BaseValue`） | **取负**（`-magnitude`），符合带符号约定 |
| `ProfileManager.TryApply` | 照常按带符号 element 施加 |

**目标游玩时长（愿景 · 时段形态的量化）：**

| 篇章 | 寿元增量 | 目标时长 | `lifeSpanCost` 取向 |
|------|---------|---------|---------------------|
| 第一篇章 炼气→筑基 | 起始 **100** | **15–30 分钟** | 基准档 |
| 第二篇章 筑基→金丹 | **+100**（外加第一篇章**结转的剩余寿元**） | **15–30 分钟** | **略微上调**（例：闭关耗时更长） |
| 第三篇章 金丹→元婴 | **+300**（远多于前两章） | **20–40 分钟** | **相应大幅上调**，把时长压回区间 |

- **寿元预算不变，靠调 `lifeSpanCost` 控时长。** 预算增量（100 / +100 / +300 / +500）是**叙事与阶梯的形式量**；**事件定价才是时长旋钮**。第三篇章预算最大却目标时长只多一档，正是靠大幅抬高单次定价实现的。
- **剩余寿元跨篇章结转（已定案）。** 第二篇章的可用预算 = `+100 + 第一篇章剩余`——「省着花」有**跨篇章回报**，寿元由此成为一条贯穿全轮回的资源线，而非每章重置的计时器。
- 事件之间 `lifeSpanCost` 有差异（如 **闭关 Research 比常规事件耗时更长**）；**具体分档表待定**（见 Open questions）。

### ② 跳过通道 —— 前提修正，配额 / 递增成本不需要

- **跳过只对「可选」事件开放**：可选的剧情事件、可选的增益事件等。**并非所有事件都能跳过**——这正是 `ifMandatory` 已经承担的约束。因此评审所称「可无限 reroll 刷事件」的**前提不成立**：**不需要每批跳过配额，也不需要递增 `skipCost`**。
- **跳过留痕**（跳过什么类型的事件反向影响 AdventurePlot / 隐藏属性）**是好主意**，且 `pastEvent` 已跟踪跳过痕迹；但它**属于内容设计而非系统设计**，留待将来的**剧情与卡牌设计**阶段。

### ③ 战斗节奏 —— 提案驳回；新愿景：道念 = 胜负判据

**「气机 / 状态层数造节奏」的提案驳回**——同属将来的剧情与卡牌设计范畴。

**新愿景（改写战斗模型）：**

- **momentum = 道念**，是**计分（scoring）用的胜利点数（victory point）**。
- **战斗胜负不再由「life 归零」判定，而是由「道念高者胜」判定。**
- **战斗 / 修炼失败 → 角色在战斗结束时损失 life**，损失量由「**角色道念 − 敌人道念**」的差值决定。
- **战斗过程中 life 不直接参与**，焦点全在道念。

**连锁改写（已定案，随本条一并生效）：**

- **`systems/scoring.md` 的答案就是道念。** 该文档此前整份为空——计分模型不再悬空：**计分 = 道念（momentum），且道念即战斗胜负判据**，不是独立于战斗之外的另一层。
- **`life` 重定位。** life **不再是战斗内的血量资源**，而是「**战斗外的耐久 / 失败惩罚承受量**」——只在战斗**结算时**按道念差被扣减，战斗**过程中不参与**。
- **「life + mana 双资源战斗模型」的表述被推翻。** 凡「参考 MTG / Hearthstone 的 life + mana 双资源」「胜负 = life 归零」一类表述**全部重写**为：**战斗内资源 = mana（出牌）+ 道念（计分与胜负）；life 在战斗外承接失败惩罚**。**炼气基线 life 10/10、mana 5/5 的数值本身不受影响。**
- **combat-service 的胜负判定、`CombatSnapshot` / `PlayResult` 字段需含道念；`ux/combat-ux.md` 的战斗屏幕以道念为主视觉**（双方道念对比），life 退居次要。

### ④ `manaLimit` 下界护栏 + 死牌转化 —— 不需要

**`manaLimit` 下降是非常罕见的情形**，不值得为它专门设计下界护栏与死牌转化规则。高费卡在极端情形下变成死牌是可接受的。

### ⑤ 隐藏属性的定性反馈 —— 批准

保留数值隐藏，但**跨档时给一条定性的叙事描述**（不给数字）：

```
道心 ↑ 跨档：  「你于静室枯坐三日，心念澄明。」
煞气 ↑ 跨档：  「你的指节泛起一层洗不去的暗红。」
寿元 进入 30%：「鬓角新添的白发，你已数不清是第几根。」
```

- **只在跨档时触发**（隐藏属性分若干**隐藏档位**），不是每次结算都播——保持稀缺感。
- 玩家学到**方向与因果**，学不到**精确数值**，无法做电子表格式优化——这正是 Reigns 式张力的来源（Reigns 的张力来自可见仪表；本作以「可感知但不可测量」替代）。
- **复用已有的 `ResolveOutcome` → `eventEnd` 阶段，无新结构。**
- **寿元告警改为两段式：30% 起给定性叙事提示，10% 起给红字数值倒数**（现行只有 10% 红字，对 100 点预算而言太晚，来不及做战略调整）。呈现位置仍为 **EventOption 选择界面的静态标注**。

### ⑥ 等级成长与危险度标注

- **等级成长 = event reward。** 由 AdventureEvent 的产出给予，**不只绑定 Combat / Practice**，且**不只有胜利才给**——失败同样可能有等级产出。
- **危险度标注：Combat / Practice / Finale 不做模糊的危险度档位**（「同阶 / 略高 / 越阶 / 无从揣度」**否决**），**而是在 eventOptions 上精确标注敌人的等级**。
  - 推论：`ux/combat-ux.md` 的待决项「等级差本身是否对玩家可见」由此答定 —— **敌人等级精确可见**；玩家可自行与自身等级比对，从而理解**意图为何被遮蔽**（信息遮蔽有了可解释的因）。
  - 推论：「越级挑战」因此成为玩家**可主动选择**的风险 / 回报维度——信息可见，抉择才成立。

### ⑦ 失败侧的产出

- **EnemyCodex 遭遇即记录**（不必击败才记）——死亡至少换来知识。这同时答定了「敌人图鉴解锁粒度」的解锁**触发**一侧。
- **道统残卷改写：不发放账号级货币，而是提高「下一次轮回获得新 PlayerPower」的概率；一旦获得新 PlayerPower 即重置该概率。**
  - 即：失败累积的是**一个递增的掉落概率**，而非可支配的货币——**避免引入第二套账号级经济**。
  - 待定：概率的累积粒度（每次失败 +X%？按抵达深度加权？）、上限、与 seed 公平性的关系。

## Open questions

- **各篇章 `lifeSpanCost` 的具体分档表。** 哪些事件类型多耗、单次幅度分别多少——需以目标时长 15–30 / 15–30 / 20–40 分钟**反推**。→ `systems/balance.md`、`systems/adventure-event/`。
- **道念模型的剩余机制。** ① 战斗的**终止条件**（回合上限？道念阈值？敌人卡组耗尽？）；② **道念的产出途径**（哪些卡 / 行为产道念）；③ **道念差 → life 损失的换算公式**。连锁改写本身已定案，不在此列。→ `systems/scoring.md`、`systems/services/combat-service.md`。
- **隐藏属性的档位划分。** 分几档、阈值在哪——**定性反馈的触发依赖它**；寿元的 30% / 10% 两段已给，道心 / 煞气的档位未给。→ `systems/services/plot-manager.md`。
- **道统残卷概率的累积规则与上限。** 累积粒度、上限、与 seed 公平性的关系。→ `systems/player-profile/player-power/`。
- **等级产出的频次与分布。** 「等级成长 = event reward」已定；但一章内需要多少个「升级型产出」才能把炼气从 1 爬到 13、它们如何分布在事件池中，未定——它与寿元预算的花法互相约束。→ `systems/balance.md`、`systems/game-progression.md`。
- **敌人等级精确标注的承载字段。** 「eventOptions 上精确标注敌人等级」意味着 `EventOption` 需在物化时携带敌人等级（或其来源）——它是物化字段清单里新的一项，且依赖尚未定的「敌人等级的来源」。→ `systems/services/future-event-service.md`。
- **评审问题 6 未裁决：无俯瞰地图 + 无预告 = 缺中长期规划感。** 进程是逐批择一的线性推进，玩家看不到前方，也无「还有几步到 Finale」的预告——中长期规划感从何而来，本次未讨论。→ `systems/game-progression.md`、`ux/`。

**本次标出的前提修正（非矛盾，但推翻了评审的立论）：**

- 评审问题 2（跳过可无限 reroll）建立在「所有事件都能跳过」之上——该前提错误，`ifMandatory` 已封死不可跳过的事件，故配额 / 递增成本方案连同其前提一并作废。
- 评审问题 4（`manaLimit` 可降 → 高费卡变死牌）建立在「`manaLimit` 会经常下降」之上——该前提不成立（极罕见），故护栏不做。

## Notes / triage

- **`lifeSpanCost` 的符号在全库有两处写法**：内容侧 / 平衡表写**正数量值**，`ProfileChangeSpec` 内写**负值**。凡文档中写「基准 -1」处一律改为「**基准 1（正数量值），物化取负**」，并在 future-event-service 明写取负发生在物化组装阶段。
- **`CombatResult.RemainingHealth` 语义变化**：它现在是「结算扣完道念差之后剩余的 life」，而非「战斗过程中掉剩的血」。
- 评审的七个结构性问题中，① ② ③ ④ ⑤ 及新增的 ⑥ ⑦ 已裁决；**问题 6 留待后续**。
