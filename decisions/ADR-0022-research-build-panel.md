# ADR-0022 — Research 结算形态 = 复数决策槽的构筑面板

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** handoffs/2026-08-17b-research-build-panel-and-deck-elements.md · handoffs/2026-08-12f-cultivation-technique-deck-building.md

## 背景

Research（闭关）是轮回内构筑的唯一落点，但它此前只有语义（「调整 / 升阶卡组」）没有结算形态。同时开局那个强制的构筑事件要求「一门功法 + 一件法宝，各三选一」——同一事件内的**两个**选择，而它已明写「不需要新机制」。Research 另有一个结构性问题：它是纯收益事件（付寿元、拿构筑，没有任何可能变糟），而它的 `lifeSpanCost` 又是全类型最贵一档。

## 决策

**① 结算形态 = 构筑面板，由若干决策槽组成。** 模板持有 N 个决策槽；**物化时为每个槽预先掷定一组候选操作**（随 `EventOption` 落存档）；结算时玩家逐槽择一，全部选择与 `lifeSpanCost` 合并为 `eventEnd` 的一次 `TryApply`。Research 走 `GenericEventResolver`。

**② 操作清单五类，闭合：** `LearnTechnique` · `UpgradeTechnique` · `ForgetTechnique` · `RemoveLooseCard`（以上载体 `DeckChangeElement`）· `GrantItem`（`AbilityChangeElement`）。**`manaLimit ±1` 不单列为一种操作**——它是上述操作的附带产出。**回寿不进本清单**：寿元的回复通道恒定为三条（回寿事件 outcome / 补天丹类法宝 / 商店购入），槽内回寿会开出第四条；且同一次事件先付寿元、再在槽内退回一部分，会让门票价格变成随玩家选择浮动的量，而「付不起在事件选择面整体消失」这条准入语义要求 `lifeSpanCost` 是一个静态量。**Research 因此是纯构筑事件。**

**③ 产出面收窄为卡组 + `manaLimit` + 共有的隐藏属性推拉，此外不给**（尤其**不给灵石 `SpiritStone` 产出、不给寿元产出**）。

**④ `manaLimit` 的下降承载点 = Research 的玩家自选风险档**：玩家可选一个高风险的钻研候选，成功 `manaLimit +1`、失败 `−1`；**掷定发生在物化阶段并随 `EventOption` 落存档**。

**⑤ 不另收资源代价**——Research 的卡组操作不收灵石或其他资源，代价全部由 `lifeSpanCost` 的 Research 行承载。

槽的字段面、候选取池链与开局构筑事件的编排见 `systems/adventure-event/research/_index.md` 与 `research/common-properties.md`。

## 理由

- **它不是新机制，是既有决策点面板的第三个实例**（前两个：战后奖励面板、能力置换面板）。「预先掷定候选 + 玩家择一 + 并入 `eventEnd` 那一次 `TryApply`」这套形状零新增结构。
- **槽的复数形态是被开局构筑事件逼出来的，不是为扩展预留。** 若只支持单槽，开局事件就必须另设机制，而它已明写「不需要新机制」。
- **候选必须在物化时掷定**，否则退出重进可以重掷；**这同时是风险档能够成立的前提**——结果已定、只是尚未展示。
- **风险档补上 Research 唯一缺失的张力**：没有它，一个「最贵且必然赚」的事件会成为批次里的无脑首选，压掉「从一批里择一」的决策价值。**「玩家自选」而非「随机惩罚」是关键的一半**——被系统随机扣上限只会让玩家回避 Research，而 Research 是构筑的唯一落点。
- **Research 唯一的内部张力落在 `manaLimit` 的玩家自选风险档上**（成功 `+1` / 失败 `−1`，玩家自己按下那个按钮）。没有它，Research 就是一个「最贵且必然赚」的纯收益事件，会成为批次里的无脑首选，压掉「从一批里择一」的决策价值。
- **不另收资源代价**兑现核心权衡「花寿元换永久出牌力」；再叠一层灵石，权衡就从一条变成两条。它还保住「付不起在事件选择面整体消失」这条承重定案——若槽内操作另收灵石，会出现「进来了但买不起任何一个操作」的死屏。
- **不给灵石产出**：灵石的长期价值出口已分派给 Exchange，Research 产灵石会与之抢同一条价值线。

## 备选方案

- **单槽结算 + 开局事件另设机制** — 否决：与「开局构筑事件不需要新机制」正面冲突。
- **候选在面板打开时才掷** — 否决：退出重进即可重掷，且风险档失去成立前提。
- **`manaLimit` 下降做成随机惩罚** — 否决：玩家会回避构筑的唯一落点。
- **`manaLimit ±1` 单列为第七类操作** — 否决：它是附带产出，与「压低只以负向奖励条目的形态出现、不另立结构」一致。
- **把「加一张游离散牌」作为 Research 的正向操作** — 否决：构筑单位是功法，单卡入组会稀释这一颗粒度；单卡的既有通道是战斗奖励与事件负向奖励。
- **在 Research 里领悟法则（`PlayerPower`）** — 否决：合法子集表里 `EventOutcome × (Power, Player)` 是 ❌，这是现成的机械约束而非取向问题。

## 后果

- 开局构筑事件成为「`Priority = 1` 依什么条件抬升」那条待答项的**第二个确定答案**（第一个是配额闸门的 Travel）。
- 它可以**缺席**而开局流程仍然成立：两槽 `AllowDecline = false` ⇒ 取池期前置逐槽收紧为「必须能产出 ≥ 1 条候选」，不满足则该条目不进批次、首批退化为常规批。缺席是一次**大声失败的运营事故**（`PushError` + 上报），**不新增任何降级路径或补发机制**。
- 数值格（走火入魔候选权重、功法层数上限）**留待内容扩充后的统计校准**；风险档的竖屏呈现仍未设计。
- 影响文档：`systems/adventure-event/research/_index.md`（权威）· `research/common-properties.md` · `systems/character-profile/deck/_index.md` · `systems/architecture.md`（`DeckChangeElement` / `DeckChangeOp` / `ResearchSlots`）· `systems/services/future-event-service.md`（候选取池与短缺处置）· `systems/balance.md`。
