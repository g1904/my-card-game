# Vision — References

参照标杆，以及哪些该借鉴、哪些该规避。要具体——“我们想要 X 的 Y 机制，但不要它的 Z。”

## Slay the Spire
- **借鉴：** 节点地图式的轮回结构；以卡牌构筑为核心 build；回合制、意图预告（intent-telegraphed）的战斗；**战后奖励面板的形态**——部分奖励强制自动计入，另一部分由玩家从若干候选中择一。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **规避：** 每个节点都战斗的节奏。在本作中，**并非每个 AdventureEvent 都是一场战斗**——许多是事件/抉择。

## Balatro
- **借鉴：** roguelite 卡牌构筑的手感；组装一次轮回的引擎所带来的乐趣；明快的移动端游玩时段；**blind 的难度分档结构**——**Practice / Combat / Finale 对位 small / big / boss blind**，三档的回合数与胜负条件递进（Practice 更简单、Combat 为标准 10 回合、Finale 更难）。借的是**难度分档**，不是出现节律（Finale 只在篇章边界出现）。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **规避：** 它那种温馨、低风险的基调——本作是 grimdark，而非温馨。（计分模型已定为**道念 / momentum**，既非 HP 消耗战也非 chips × mult，见 `systems/scoring.md`。）

## Reigns（手游）
- **借鉴：** **属性平衡求生张力**——玩家不断在相互竞争的压力之间权衡，而非优化单一数值；每次抉择会同时拨动多个仪表。
- **规避：** 它那种纯粹左右滑动二选一、无 deck 的极简——我们仍想要一层真正的卡牌构筑。
- **有意背离并给出替代：** Reigns 的张力来自**可见**仪表；本作**属性全隐藏**，改以「**跨档时给一条定性叙事**」制造**可感知但不可测量**的张力——玩家学到方向与因果，学不到精确数值，因而**无法做电子表格式优化**。见 `systems/services/plot-manager.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 月圆之夜 (Night of the Full Moon)
- **借鉴：** **事件 / 抉择机制**——它是 AdventureEvent 如何呈现抉择并触发后果的范本；**节点形态**亦参照它——精心策划的事件菜单，而非 StS 式完全分支地图。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **规避：** _(待定——待 AdventureEvent 系统设计好后，注明具体不该照搬什么。)_

## Magic: the Gathering & Hearthstone
- **借鉴：** **mana 作为每回合出牌资源**的形态（对齐 `CharacterProfile.Status` 的 currentMana / manaLimit）。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **借鉴（MTG · 已定案 · 承重）：** **stack（堆栈）式的卡牌结算**——打出的牌先入栈、按后进先出依次结算，「打出」与「结算」是两个时刻。**借入深度已定：只借结算模型，不借交互与优先权**（见下条「规避」）。另借入 MTG 的**回合分步结构**：起始步 / 主阶段 / 结束步，**但去掉战斗步骤与双主阶段**。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` + `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **借鉴（MTG · 术语）：** card / deck / combat 体系将**大量借用 MTG 术语**以简化表达；借词须在 `terminology.md` 登记为已定含义，避免与 MTG 原义漂移，也避免与既有仙侠定名冲突（mana = 法力、momentum = 道念）。Source: 同上。
- **规避（MTG · 已定案 · 承重）：** **交互与优先权传递**——instant（瞬间）类牌、栈非空时出牌、双方轮流取得 / 让渡优先权，**整体不借**。理由：**拉长对局时长、决策点过多、复杂度高而玩法深度收益小**。**所有牌都是 sorcery speed**，只能在自己回合的主阶段打出。这与 `pillars.md` 的反目标「不搞深度的堆栈 / 优先权复杂度」一致。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **规避：** **「打到对方血量归零」的胜负模型**——本作胜负由**道念（momentum）高者胜**判定，life 退到战斗外承接失败惩罚（见 `systems/scoring.md`）。同样规避 **mana 曲线**（无爬升，每回合刷满）。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## Warhammer 40k
- **借鉴：** **叙事氛围**——grimdark、阴郁、高风险的叙事。
- **规避：** 它具体的设定/IP；我们是仙侠，不是科幻。只借基调。

## 美术方向 — 三国杀 (Legends of the Three Kingdoms) & 弈仙牌
- **借鉴：** 具有绘画感的中式卡牌游戏插画风格；竖版卡面构图。
- **约束：** 必须在手机尺寸下清晰可读，并处于 **GL Compatibility** 渲染器的限制之内。
- **展开去处：** 美术与音频的完整方向、参考登记与生成指导在 **`art/`**（`visuals/` · `soundtracks/` · `animations/`）。本处只留 vision 级的一句话锚点；**逐条参考的「借什么 / 不借什么」登记在 `art/*/references/_index.md`**——那里才是能转成 prompt 的粒度。Source: `handoffs/2026-08-04-art-audio-library-scaffold.md`。

## 其他参照
> _遇到相关的游戏/应用/美术时随时补充。_
