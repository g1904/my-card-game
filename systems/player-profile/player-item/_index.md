# player-item

> **古宝 / PlayerItem** —— 账号级、有使用次数限制的道具，含可购道具定义。
> **中文定名 = 古宝**（08-03 定，取代「玩家道具」）；轮回级的对应物是 **法宝 / CharacterItem**（`../../character-profile/item/`）。**中文名不表达层级**。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerItem = 账号级、有使用次数限制的道具。** 独立于任何单次轮回，由 PlayerProfile 持有（`List<PlayerItem>`）；跨轮回持久。与角色级的 CharacterItems（`../../character-profile/item/`）区分开。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **可购道具定义。** 道具的**定义 / 可购语义**归入本处；**交易机制**本身（作为一种 AdventureEvent）归 `systems/adventure-event/exchange/`（Exchange / 交易）。即：道具**是什么**在这里，**如何买到**在 exchange。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

- **一条已定的获取渠道 = premium bundle（已定案）。** 付费礼包一次性给予**随机 2 个 PlayerItem**（外加随机 1 个 PlayerPower）。这是目前唯一明确写下的 PlayerItem 获取途径——其余（Exchange 购买、事件产出）仍是方向而非定案。礼包全貌见 `systems/monetization.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **已获得的 PlayerItem 会进 PlayerItemCodex。** 图鉴族（见 `../codex/`）为 PlayerItem 单列一本，记录静态文案；与当前**持有**的 `List<PlayerItem>`（含剩余使用次数）是两回事。Source: 同上。

- **古宝在战斗内以 `CardType.Item` 呈现，与法宝走同一条路径（已定案 · 08-04b · 承重）。** 战斗道具区**同时呈现两级**，条目上带 `ItemScope { Character, Player }` 标识来源。规则与法宝完全相同（不洗进卡组、存于储物袋、不受抽牌运制约、使用窗口 = 自己回合的行动阶段且栈为空时、可带 mana 费用与启动式异能、`UsableScene` 三档），差别只在**持久层与次数**：
  - **`Scope == Player` 时 `Charges > 0` 是硬约束**（古宝定义上有使用次数限制，违反 → 加载时 `PushError`）；法宝可为「无限（-1）」。
  - **使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口。** 与「战斗过程中的变更即时经 ProfileManager，`Spoils` 只承载收口产出」一致，且**堵死「用完退出重进恢复次数」的窗口**。
  - **推论（承重）：道具是战斗内唯一会即时写 Profile 的卡牌行为。** 其余所有牌都是战斗内运行态（道念、手牌、战场条目战斗结束即消失），而古宝的次数是**账号级持久数据**。既有定案「战斗内的一切写入经 ProfileManager」正好承接这条，无需新机制。
  - **推论：古宝是付费战斗价值的主要承载者。** premium bundle 给的是随机 1 法则 + 随机 2 古宝，而**次数限制天然是节流阀**——让付费收益是「关键时刻多几次转圜」而非「永久变强」。见 `systems/monetization.md`。

  Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。

> 具体的使用次数模型、可购字段等共有属性见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **道具定义 vs 交易机制切分（handoff Open question）：** shop（Exchange）既是**获取机制**（→ `adventure-event/exchange/`），又产出**可购道具**（→ 本处）。当前把**道具定义**归 player-item、**交易机制**归 adventure-event/exchange；是否需要更清晰的切分待确认。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **PlayerItem 机制未设计（08-04b 部分落定）。** **已定：战斗内形态 = `CardType.Item`、`Charges > 0` 为硬约束、次数即时写 PlayerProfile**（见上）。**仍未设计**：道具种类目录、次数如何补充、可购价格 / 库存、战斗外的效果形态。
- **战斗内道具运行态的存档形态未定（08-04b 新增）。** 决策点存档须能恢复「本场已用掉哪些道具、各自剩余次数」；字段形态需与战场条目、`Power` 运行态一并落定。→ `systems/services/combat-service.md`、`sync-service.md`。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-item/`（待建）。
