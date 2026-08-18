# player-item

> **古宝 / PlayerItem** —— 账号级、有使用次数限制的道具，含可购道具定义。
> **中文定名 = 古宝**；轮回级的对应物是 **法宝 / CharacterItem**（`../../character-profile/item/`）。**中文名不表达层级**。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerItem = 账号级、有使用次数限制的道具。** 独立于任何单次轮回，由 PlayerProfile 持有（`List<PlayerItem>`）；跨轮回持久。与角色级的 CharacterItem（`../../character-profile/item/`）区分开。
- **道具定义归本处，交易机制归 Exchange；切分判据是「这条信息在游戏里没有商店时是否仍然存在」。** 仍然存在 → 归道具侧；不存在 → 归 Exchange 侧。**直接推论：`ItemData` 上不加 `Price`，也不加 `Purchasable`**——价格归定价表（写进条目会制造第二权威），「能不能买」已由 `ExclusiveSource != null` 不进任何抽取池免费给出。判据本体与逐字段归属表见 `systems/adventure-event/exchange/_index.md`。
- **古宝恒不可售出。** 售出面仅对轮回级的法宝 `CharacterItem` 开放，且这是一条代码级常量判据，规则权威同上。

- **一条已定的获取渠道 = premium bundle。** 付费礼包一次性给予**随机 2 个 PlayerItem**（外加随机 1 个 PlayerPower）。这是目前唯一明确写下的 PlayerItem 获取途径——其余（Exchange 购买、事件产出）仍是方向而非定案。礼包全貌见 `systems/monetization.md`。
- **已获得的 PlayerItem 会进 PlayerItemCodex。** 图鉴族（见 `../codex/`）为 PlayerItem 单列一本，记录静态文案；与当前**持有**的 `List<PlayerItem>`（含剩余使用次数）是两回事。

- **古宝在战斗内以 `CardType.Item` 呈现，与法宝走同一条路径（承重）。** 战斗道具区**同时呈现两级**，条目上带 `AbilityScope { Character, Player }` 标识来源。规则与法宝完全相同（不洗进卡组、存于储物袋、不受抽牌运制约、使用窗口 = 自己回合的行动阶段且栈为空时、可带 mana 费用与启动式异能、`UsableScene` 三档），差别只在**持久层与次数**：
  - **`Scope == Player` 时 `Charges > 0` 是硬约束**（古宝定义上有使用次数限制，违反 → 加载时 `PushError`）；法宝可为「无限（-1）」。
  - **使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口。** 与「战斗过程中的变更即时经 ProfileManager，`Spoils` 只承载收口产出」一致，且**堵死「用完退出重进恢复次数」的窗口**。
  - **推论（承重）：道具是战斗内唯一会即时写 Profile 的卡牌行为。** 其余所有牌都是战斗内运行态（道念、手牌、战场条目战斗结束即消失），而古宝的次数是**账号级持久数据**。既有定案「战斗内的一切写入经 ProfileManager」正好承接这条，无需新机制。
  - **推论：古宝是付费战斗价值的主要承载者。** premium bundle 给的是随机 1 法则 + 随机 2 古宝，而**次数限制天然是节流阀**——让付费收益是「关键时刻多几次转圜」而非「永久变强」。见 `systems/monetization.md`。

- **古宝可被「本轮回禁用」，也可被置换。** 与法则 / 神通 / 法宝完全对称，**含 `ThisCycle` 档**：
  - **禁用 = 不进「本场可用道具」列表**（古宝 ≈ 启动式异能，故截断在「可否启动」那一层）——**仍在 `PlayerProfile` 里、`Charges` 分毫不动**，只是本轮回 / 本篇章 / 下一事件不可启动。禁用表落 `CharacterProfile.disabledAbility`（轮回级），故轮回结束即自然恢复。
  - **不违反「付费内容不会被游戏销毁」**：禁用不销毁、不扣次数、轮回结束即恢复。对法则开放而对古宝不开放，反而会让内容侧多背一条「哪些层能用哪些档」的例外表。但它确实是对付费内容的一次可感知削弱，故补一条**内容侧纪律**：**禁用古宝的事件应比禁用法宝显著更稀有，且一并计入既定的 1% 分子**（评审清单级，不加代码硬规则——与 `IgnoresProtection` 的 1% 同性质）。
  - **置换只在同池内进行**（`(Kind, Scope)` 全同 + 同 `Rarity` + 排除已持有），即 `PlayerItem ↔ PlayerItem`；置换所得继承被换出条目的 `SourceCode`。规则权威见 `../player-power/_index.md`。
  - `ItemData` 因此新增必填的 `Rarity: RarityTier`（缺失 → `PushError`），`ItemScope` 与 `PowerScope` 合并为 `AbilityScope`。

> 具体的使用次数模型、可购字段等共有属性见 `common-properties.md`。

Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **PlayerItem 机制未设计。** **已定：战斗内形态 = `CardType.Item`、`Charges > 0` 为硬约束、次数即时写 PlayerProfile**（见上）。**仍未设计**：道具种类目录、次数如何补充、可购价格 / 库存、战斗外的效果形态。
- **战斗内道具运行态的存档形态未定。** 决策点存档须能恢复「本场已用掉哪些道具、各自剩余次数」；字段形态需与战场条目、`Power` 运行态一并落定。→ `systems/services/combat-service.md`、`sync-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-item/`（待建）。
