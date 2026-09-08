# ADR-0159 — `MoveCardEffect` 补 `Side` 格：两端恒同侧，跨方转移结构上不可表达

- **状态：** Accepted
- **日期：** 2026-09-02
- **来源：** handoffs/2026-09-02-move-card-effect-side.md · answer-logs/log-move-card-effect-side.md

## 背景

八个效果原语里有六个带方位面，`MoveCardEffect` 是唯一一个没有的——它只写 `From : CardZone` / `To : CardZone`，作用侧全靠上下文推。这使「削减对手抽牌堆」这类已在设计面成立的效果**无从表达**，而同表其余五个原语都能。缺格还让原语表在方位这一维上不同构：读表的人无法从签名判断 `MoveCard` 到底作用于谁。

## 决策

**`MoveCardEffect` 增一格 `Side : SideConstraint`，与同表五个方位原语逐字同构**——相对 `controllerSide` 解析、枚举默认 `Any`、不设哨兵、不为 `Side == Any` 单开 `PushWarning`。

**单格 `Side` 使 `From` 与 `To` 恒落在同一侧**：`Side = Opponent` + `From = DrawPile` + `To = DiscardPile` 即「削减对手抽牌堆」；**跨方转移在结构上不可表达**（闭集不变式按侧成立），日后要开放是加一格 `ToSide` 的**纯加法**。

**加载期校验增第 21 条：** `MoveCardEffect` 的 `Selection == Chosen` 且 `Side != Self` → `PushError`，带宿主 `Id` 与 `.tres` 路径。**按最严收口**，日后放宽是纯加法。

参数表、`SideConstraint` 语义与 21 条校验全表 → `systems/character-profile/deck/common-properties.md`。

## 理由

- **同构是这张原语表的承重形态**：一原语一子类、方位面统一相对施放者解析（`ADR-0115`）。`MoveCard` 缺格是遗漏，不是有意的例外——补格让表恢复可按签名读。
- **两端同侧是闭集不变式的直接要求**：一场战斗的卡牌集合是闭集且按侧成立（`ADR-0041`）。跨方搬运会让一枚 `e#` 前缀的实例出现在玩家侧的三区序列里，读档校验当场误报——除非把校验改写成跨侧全集比对，那是动存档不变式。
- **跨方不得点选**：对手的区玩家看不见（对手手牌 `HandCardInstanceIds` 恒空），点选无从发起；跨方一律走 `Random`。

## 备选方案

- **复用 `EffectScope` 承载方位** — 否决：它是静止式修正 `StaticModifierData.Scope` 专用的第三层作用域格，`MoveCardEffect` 是第一层原子操作，混用即让一个字段承载两族语义；且 `EffectScope` 带 `EntryFilter`，而抽牌堆里的牌不是战场条目，那一半恒无对象。
- **`From` 恒作用己方、不补格** — 否决：收掉一整条已 Accepted 的设计面，且要回头改一份 Accepted 的 ADR，代价远高于补一格。
- **拆 `FromSide` / `ToSide` 两格** — 否决：跨方搬运会让实例前缀与三区序列对不上，读档校验 ④ 当场误报。

## 后果

- **derive 时不再需要排除任何原语**——`deck/common-properties.md` 的结构面因此闭合，加载期校验表由 20 条增至 21 条。
- **跨方转移这条路日后要开，是加 `ToSide` 的纯加法**，不动既有条目、不动存档；本 ADR 不预留该格。
- 存档面零新增字段、空迁移。
- 受约束的文档：`systems/character-profile/deck/common-properties.md`（参数表第 7 行 + 校验第 21 条）· `systems/character-profile/deck/_index.md`（原语清单签名）· `systems/services/combat-service.md` · `decisions/ADR-0119-move-card-drawpile-insert-position.md`（`InsertPosition` 与本格同住一个原语）。
