# Vision — References

参照标杆，以及哪些该借鉴、哪些该规避。要具体——“我们想要 X 的 Y 机制，但不要它的 Z。”

## Slay the Spire
- **借鉴：** 节点地图式的轮回结构；以卡牌构筑为核心 build；回合制、意图预告（intent-telegraphed）的战斗。
- **规避：** 每个节点都战斗的节奏。在本作中，**并非每个 AdventureEvent 都是一场战斗**——许多是事件/抉择。

## Balatro
- **借鉴：** roguelite 卡牌构筑的手感；组装一次轮回的引擎所带来的乐趣；明快的移动端游玩时段。
- **规避：** 它那种温馨、低风险的基调——本作是 grimdark，而非温馨。（计分模型已定为**道念 / momentum**，既非 HP 消耗战也非 chips × mult，见 `20-systems/scoring.md`。）

## Reigns（手游）
- **借鉴：** **属性平衡求生张力**——玩家不断在相互竞争的压力之间权衡，而非优化单一数值；每次抉择会同时拨动多个仪表。
- **规避：** 它那种纯粹左右滑动二选一、无 deck 的极简——我们仍想要一层真正的卡牌构筑。
- **有意背离并给出替代：** Reigns 的张力来自**可见**仪表；本作**属性全隐藏**，改以「**跨档时给一条定性叙事**」制造**可感知但不可测量**的张力——玩家学到方向与因果，学不到精确数值，因而**无法做电子表格式优化**。见 `20-systems/services/plot-manager.md`。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 月圆之夜 (Night of the Full Moon)
- **借鉴：** **事件 / 抉择机制**——它是 AdventureEvent 如何呈现抉择并触发后果的范本；**节点形态**亦参照它——精心策划的事件菜单，而非 StS 式完全分支地图。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **规避：** _(待定——待 AdventureEvent 系统设计好后，注明具体不该照搬什么。)_

## Magic: the Gathering & Hearthstone
- **借鉴：** **mana 作为每回合出牌资源**的形态（对齐 `CharacterProfile.Status` 的 currentMana / manaLimit）。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **规避：** **「打到对方血量归零」的胜负模型**——本作胜负由**道念（momentum）高者胜**判定，life 退到战斗外承接失败惩罚（见 `20-systems/scoring.md`）。同样规避 **mana 曲线**（无爬升，每回合刷满）。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## Warhammer 40k
- **借鉴：** **叙事氛围**——grimdark、阴郁、高风险的叙事。
- **规避：** 它具体的设定/IP；我们是仙侠，不是科幻。只借基调。

## 美术方向 — 三国杀 (Legends of the Three Kingdoms) & 弈仙牌
- **借鉴：** 具有绘画感的中式卡牌游戏插画风格；竖版卡面构图。
- **约束：** 必须在手机尺寸下清晰可读，并处于 **GL Compatibility** 渲染器的限制之内。

## 其他参照
> _遇到相关的游戏/应用/美术时随时补充。_
