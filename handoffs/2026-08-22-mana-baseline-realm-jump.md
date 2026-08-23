# mana 基线随大境界跃升 +1

- id: 2026-08-22-mana-baseline-realm-jump
- date: 2026-08-22
- topic: systems/character-profile/mana.md · systems/character-profile/_index.md · systems/balance.md · systems/services/profile-service.md
- status: distilled
- distilled-to: systems/character-profile/mana.md, systems/character-profile/_index.md, systems/balance.md, systems/services/profile-service.md

## Intent（distilled）

**一行摘要：`manaLimit` 除事件推拉外，另在每次大境界提升时 `+1`——增量语义、走既有 `CostKey.ManaLimit`、幅度恒 1，不新增字段 / 不新增表 / 不 bump schema。**

### 1. 定案：`manaLimit` 每次大境界提升 `+1`

- 进入**筑基** `+1`、进入**金丹** `+1`；**元婴是轮回终点，不给**。合计一轮回 `+2`。
- 取值落平衡资源上的一个常量 **`RealmBreakthroughManaBonus`（初值 1）**，由 life-cycle-service 在**篇章边界**施加一次。
- **形态 = 增量语义**：走 `ProfileChangeSpec` 的既有通道 `CostKey.ManaLimit`，幅度 1，与既定「单次变动幅度恒为 1」一致。
- **明确不引入「置值」语义、不新增 mana 境界基线表。** `ProfileChangeSpec` 全部是增量；一张基线表要么配 `max(当前, 基线)` 的置值规则（凭空多出「置值还是加值」要每个消费点分辨），要么在玩家已累积到基线之上时产生「跃升反而压低上限」的不可解释情形。
- **结构面净增 = 一个常量。** 无新字段、无新存档点、无 schema bump——跃升只是在篇章边界多写一次既有字段。

**这次跃升不是被外生压力要求的。** 约束面（牌流：起手 4 / 每回合抽 2 / 手牌上限 7 / 己方 5 个回合 ⇒ 一场流入 14 张）**三章同形**，没有任何数值压力要求基线跳档。它换回的是**突破的实感**：三个境界里最直观的资源格数不再几乎不动。

**明知并接受的代价：**
1. `manaLimit` 从此有一条**与玩家选择无关**的成长来源，「构筑的长期成长体现在 `manaLimit` 的推拉上」这条推论被稀释（量级仍小：整轮回 `+2`，对一章 `+1~+2` 的推拉预算而言是配角）。
2. ch2 / ch3 的 mana **溢出牌流更严重**（见下）。

### 2. 「一章净增 +1~+2」不改，跃升是额外叠加

事件推拉的篇章预算维持 `+1~+2`，境界跃升在其之上叠加 ⇒ **三章末约 6~7 / 8~10 / 10~13**。

| | `manaLimit` | 一场可支配 mana（× 5 回合） | 若平均费用 2，可打出张数 | 相对牌流 14 张 |
|---|---|---|---|---|
| ch1 末 | 6~7 | 30~35 | 15~17 | 已达饱和（跃升发生在进筑基时） |
| ch2 末 | 8~10 | 40~50 | 20~25 | 溢出 |
| ch3 末 | 10~13 | 50~65 | 25~32 | 溢出约两倍 |

> 「平均费用 2」是为让校验可算而取的占位量级，不是提案数值。

**溢出是已知且被接受的代价。** 若后两章希望 mana 仍是紧约束，**正确的旋钮是上调费用曲线或收紧牌流，而不是削掉跃升**——这是 ch1 数值标杆专场的一条输入。

### 3. 分工不变：mana 不承载境界跨度

`lifeTotal` 与 `manaLimit` 被完全不同的外生曲线约束，**不能互相类推**：

| | `lifeTotal` | `manaLimit` |
|---|---|---|
| 是什么 | 承伤 / 存活预算 | 每回合的行动带宽 |
| 量纲被谁拉动 | `baseMomentum`（随境界百倍级放大） | 牌流（三章完全同形） |
| 境界基线形态 | **置值跃升 10 / 25 / 40** | **增量 `+1` / 每次大境界** |

境界跨度仍由 `baseMomentum` 与**每张牌的道念产 / 削量**承载，**不由「一回合能打几张」承载**。故 mana 侧只多一个常量、**不多一张跨境界曲线表**，ch1 专场的校准面只多一个数。

## Clarifications（interview 产物）

- **mana 基线是否随境界跃升？** → **跃升，每次大境界 `+1`**（形态取增量语义 · 既有 `CostKey.ManaLimit` · 不引入置值）。
  这**推翻了 `answer-logs/log-0730b.md` 第 4 条**「`manaLimit` 不随境界自动成长，由 AdventureEvent 的 cost / reward 推拉」——该条已写进 `mana.md` 的决策小节，本次同批改写。用户在知情于「跃升不被外生压力要求」「溢出会加重」两条代价后作出此裁决。
- **「一章净增 +1~+2」是否随之上调？** → **不上调**。跃升是额外叠加，三章末推算相应更新为 6~7 / 8~10 / 10~13。原始草稿只算到「炼气起 5 → 第一篇章末 6~7」，本次补齐三章。

## Open questions

- **卡牌费用曲线是否随境界整体上移（承重）。** 它是本定案唯一能被翻盘的前提：费用曲线上移 ⇒ 可打出张数同比缩水 ⇒ 溢出收窄，`RealmBreakthroughManaBonus` 与「一章净增 +1~+2」两项预算都要连带重估。归 ch1 数值标杆专场。→ `systems/balance.md`、`systems/character-profile/deck/common-properties.md`。
- **`RealmBreakthroughManaBonus` 初值 `1` 的校准。** 形态已定，只欠取值是否随实测调整。归 ch1 数值标杆专场。→ `systems/balance.md`。
