# ADR-0260 — 道具战斗外可写 key 收窄为白名单 `I-13` = `{ LifeSpan }`

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-item-family-supply-guardrails.md · answer-logs/log-item-family-supply-guardrails.md

## 背景

回寿法宝那一族的供给护栏已答全，但「其余道具族的同三格口径」还开着。逐族各写一套 L-1 / L-2 / L-3 是不可行的——族的数量取决于道具**能表达什么**，而战斗外 `OutOfCombatUseOutcome.Elements` 当时可写的 key 是整张 `ResourceElements` 表。不先收窄可写面，待答的口径就没有边界。

## 决策

**新增加载期校验 `I-13`：`OutOfCombatUseOutcome.Elements` 中任一行的 `Key ∉ { CostKey.LifeSpan }` → `PushError` + 条目 `Id` + 报出该 `Key`。**

- 与 `I-6` **并存不合并**：`I-6` 管 `Op` 是否在该行 `AllowedOps` 内，`I-13` 管 key 的编排准入；形态照事件侧「模板可声明的 key ≠ 物化后可出现的 key」两张表。事件侧与道具侧**两张表各自独立、不合并**。
- **拒绝面**：`SpiritStone` / `ImmortalJade` / `ManaLimit` / `ExperiencePoint` / `Faith` / `Bloodlust` + 六个账号层 `CostKey`（`PowerFragment*` × 5 · `BundleRedeemedOrdinal`）。
- **方向可逆，条件先记下**：要开货币须**同时**补三样（加回白名单一格 · L-0 同构的免费通道排除 · 商店侧「产灵石的法宝不进 `CharacterItem` 库存」排除）；要开 `ManaLimit` 须**同时**补三样（`|BaseValue| == 1` 的加载期闸 · `Charges == 1` 强制 · L-0 同构排除）。三样缺一，对应那本账即不可复算。

→ `systems/character-profile/item/_index.md`「战斗外可写 key 的白名单」。

## 理由

`systems/character-profile/item/_index.md`：**不补白名单，三个已封的口全部从道具侧重开** —— `ExperiencePoint` 绕开 `ExperienceGrade` 枚举档与平衡表映射且直改 `G_c` 供给账 · `Faith` / `Bloodlust` 绕开 `HiddenStatGrant` 的档位映射 · 账号层六个 `CostKey` 中一件写 `PowerFragmentAccumulated` 的法宝就是一条绕开残卷机制的道统碎片通道。

**它让问题自己收敛**：战斗外可表达的功能族 = 白名单长度。收到 1 ⇒ `Elements` 一列只剩回寿，而它的口径已答定。与「不设 `Abilities` 一格」同形——**把写不出来当作护栏，而不是写得出来再加校验**。

`ManaLimit` 另有独立依据：载体判据不成立（永久增量下 `Charges` 这个节流阀名存实亡 ⇒ 它属神通 / 法则那一侧），且预算已被事件侧铺满。两种货币在商店侧结构上无意义（`CharacterItem` 五档恒收灵石 ⇒ 产灵石的法宝是「用灵石买灵石」，产出 < 价格则无人买、≥ 价格则套利）。

## 备选方案

- **不设白名单、逐族加校验** — 否决：三个已封的口从道具侧全部重开。
- **白名单含两种货币** — 否决：商店侧结构无意义 + 免费通道上是账外 `I(c)` / `J(c)` 增量。
- **白名单含 `ManaLimit` 并加 `|BaseValue| == 1` 闸** — 否决：载体判据不成立，且事件侧预算已铺满，道具侧再开即账外增量。

## 后果

- **代价明写并接受**：内容侧从此编排不出经验丹 / 静心符 / 血煞珠 / 碎片袋 / 灵石袋 / 储物锦囊的**道具形态**；同名风味改由战斗 `BaseReward` 与事件 outcome 承载（两处都在账内）。
- `item/_index.md` 战斗外效果面表 `Elements` 行的理由文字随之只写回寿。
- 它是 `decisions/ADR-0261-family-guardrail-necessity-criterion.md` 的前置：可写面收窄后，族护栏判据才有可枚举的作用对象。
