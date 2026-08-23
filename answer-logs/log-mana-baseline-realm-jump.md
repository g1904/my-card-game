# Answer log mana-baseline-realm-jump

- 日期：2026-08-22
- 来源：`inbox/solution-draft-mana-baseline-realm-jump.md` → `handoffs/2026-08-22-mana-baseline-realm-jump.md`
- 移出条数：1

---

**更高境界的 mana 基线是否跃升（进入筑基 / 金丹 / 元婴时是否另有一次基线跃升，还是完全交给事件累积）** → **跃升：每次大境界提升 `manaLimit` `+1`**（进筑基 +1、进金丹 +1；元婴是终点，不给）。形态取**增量语义**——走既有 `CostKey.ManaLimit`、幅度恒 1、由 life-cycle-service 在篇章边界施加一次，取值为平衡资源常量 `RealmBreakthroughManaBonus`（初值 1）。**明确不引入置值语义、不新增 mana 境界基线表、不新增字段 / 存档点 / schema bump。**
（归档去向：`systems/character-profile/mana.md` 的「意图」与「决策」小节；`systems/balance.md` 的「炼气期基线」条；`systems/character-profile/_index.md`；`systems/services/profile-service.md` 的 `ResourceElements` 表 `ManaLimit` 行）

- **⚠ 本条显式推翻 `answer-logs/log-0730b.md` 第 4 条**（「`manaLimit` 不随境界自动成长，而是由 AdventureEvent 的 cost / reward 推拉」）。用户在知情于两条代价后作出裁决：① 跃升不被外生压力要求（牌流约束面三章同形），是为突破的实感而给；② `manaLimit` 从此有一条与玩家选择无关的成长来源。`mana.md` 的决策小节已同批改写。
- **连带裁决（同一问题的一部分）：** 「一章净增 +1~+2」**不上调**，境界跃升为额外叠加 ⇒ 三章末推算更新为约 **6~7 / 8~10 / 10~13**；ch2 / ch3 相对牌流 14 张的溢出加重，**是已知并被接受的代价**（若要收紧，旋钮是费用曲线或牌流，不是削掉跃升）。
- **剩余未答部分：** 由本条派生出**两项新待答**，均归 ch1 数值标杆专场，已登记在 `systems/balance.md` 的待决问题——**「卡牌费用曲线是否随境界整体上移」**（本定案唯一的翻盘前提）与 **`RealmBreakthroughManaBonus` 初值 `1` 的校准**。
