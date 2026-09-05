# Answer log move-card-effect-side

- 日期：2026-09-02
- 来源：`inbox/solution-draft-move-card-effect-side.md` → `handoffs/2026-09-02-move-card-effect-side.md`
- 移出条数：1

## 移出的条目

**`MoveCardEffect` 缺一格方位声明（08-30 新增）** → **补单格 `Side : SideConstraint`。** 相对 `controllerSide` 解析、不设哨兵、取枚举天然默认 `Any`，与同表另五个方位原语逐字同构。**一格 `Side` 同时解析 `From` 与 `To`，两端恒同侧**：`Side = Opponent` + `From = DrawPile` + `To = DiscardPile` 即「削减对手抽牌堆」；**跨方转移在结构上不可表达，这是有意的**——闭集不变式按侧成立（读档校验逐侧比对三区并集），跨方搬运会让一枚对手侧实例落进玩家侧序列；日后要开是加一格 `ToSide` 的纯加法 + 一次不变式重估。**新增一条加载期校验**（第 21 条：`Selection == Chosen` 且 `Side != Self` → `PushError`，带宿主 `Id` 与 `.tres` 路径），既有第 6 / 8 条一字不动。两条备选被否决：复用 `EffectScope`（它是静止式修正专用的作用域格，混用会让一个字段承载两族语义）· `From` 恒作用己方（收掉一整条已 Accepted 的设计面）。`ADR-0119` 被兑现而非被修改、不改、不新开 ADR。存档 / 内容 / 后端三面零影响。（归档去向：`systems/character-profile/deck/common-properties.md`、`systems/character-profile/deck/_index.md`、`systems/services/combat-service.md`）

## 同批裁决（本身不在待答清单上，故不计入移出条数）

- **`MoveCardEffect.Selection` 的枚举类型是否顺带指名 / 改名** → **不动**（最小扰动；改名会连带改 `DiscardEffect` 一行已成文措辞，收益为零）。
- **是否为 `Side == Any` 加哨兵 / `PushWarning`** → **不加**（六个方位原语须一致，漏填风险在另五个上同样存在且已被接受）。
- **`systems/balance.md` 疲劳段的 `MoveCard` 表述是否改** → **不改**（单格 `Side` 语义下该句仍然成立）。

## 未随本次移出

- **跨方转移（「偷牌」）是否作为一条设计面永久关闭** —— 本次按「结构上不可表达」落笔并写明日后开放的纯加法路径；若要正式开放须连带重估按侧闭集不变式，不与本条同批。
