# adventure-event-combat

> 回合结构、敌人意图/AI、胜/负结算。

## 意图
> _设计意图,从 handoffs 中提炼。保持更新。_

- **AdventureEvent** 是逐时逐刻的游玩单元。战斗存在,但**并非每个 AdventureEvent 都是一场战斗**——这是对 Slay the Spire「每个节点都战斗」节奏的有意背离。
- AdventureEvent 呈现**事件 / 选择**,其后果会影响玩家及未来状态;事件 / 抉择机制参照**月圆之夜(Night of the Full Moon)**建模。
- 战斗发生时是**回合制**且易读(意图预告式),而非实时 / 拼 APM。
- 底层压力遵循一种**类 Reigns 的属性平衡**手感——选择在相互竞争的仪表间摆动,而非优化单一数值。
- 来源:`10-handoffs/2026-07-13.md`。

**术语(唯一命名 = AdventureEvent)。** 逐时逐刻的游玩单元统一为 **修行事件 / AdventureEvent**(单个节点;整段旅程为「修行历程」);**`encounter` 为废弃旧名,已在全部设计文档中覆写**。见 `terminology.md`。Source: `10-handoffs/2026-07-15b-...` + 覆写确认 `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

**修行事件分类法(七类 · 已定案 ADR-0002,07-23 加入 Finale)。** 修行事件分为七类;仅 战斗(及其变体 修炼)走战斗结算、Finale 走独立的境界突破结算,呼应「并非每个事件都是战斗」这一支柱:

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**:进入后才揭示为其余某一类 |
| 境界突破 | Finale | **篇章边界高潮**:渡劫 / 突破,独立于 Combat 的结算(2026-07-23 加入的第七类) |

休养 / Rest 不单列,并入 战斗 或 闭关。定案见 `50-decisions/ADR-0002-adventure-event-taxonomy.md`(七类,07-23 加入 Finale)。Source: `10-handoffs/2026-07-15b-...` + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

**战斗模型 = life + mana(已定案)。** 战斗结算参考 **Magic: the Gathering** 与 **Hearthstone** 的 **life + mana** 双资源系统(而非 StS 纯 HP,或 Balatro 的 chips×mult)。与 `CharacterProfile.Status` 既有的 `currentHealth/healthLimit`、`currentMana/manaLimit` 字段一致——mana 作为出牌资源见 `20-systems/energy-economy.md`。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。

**mana = 无曲线 · 上限 + 逐步恢复(已定案)。** **不采用 mana 曲线**(既非 Hearthstone 式每回合 +1 上限,也非 MTG 式打地的递增);改为「**上限 + 逐步恢复**」:mana 有上限,每回合逐步恢复。**炼气期标准基线(起始满值):** life = **10/10**、mana = **5/5**。恢复速率 / 更高境界基线见待决问题与 `30-content/balance.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

**Combat = AdventureEvent 子类型(命名显式化)。** 「adventure-event-combat」概念即 **AdventureEvent-Combat**:Combat 是 AdventureEvent 的一个子类型(与 ADR-0002 分类法一致)。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

**境界突破 = AdventureEvent-Finale(已定案)。** 篇章边界的**境界突破**定义为 **AdventureEvent-Finale**,**独立类型、区别于 Combat**,并作为**第七类正式并入 ADR-0002 枚举**——回答了下方「篇章边界高潮事件复用 Combat 还是独立」的待决项:**独立,而非 Combat**。Source: 同上。

**节点呈现 = 月圆之夜风格(已定案)。** 修行事件的呈现形态参考《月圆之夜》(精心策划的事件菜单)。见 `20-systems/map-progression.md`、`00-vision/references.md`。Source: 同上。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **修行事件分类法(七类):** 修炼/战斗/闭关/交易/社交/未知 + **境界突破 Finale**(2026-07-23 加入的第七类,独立于 Combat)。休养并入 战斗 或 闭关;未知为元类型(进入后揭示);修炼≈比试、闭关≈研究;Finale = 篇章边界境界突破。→ `50-decisions/ADR-0002-adventure-event-taxonomy.md`(Accepted,07-23 修订)。

## 待决问题
> _尚未解决,需要一次 handoff/决策。_

- ~~**篇章边界高潮事件 / Finale 是否入枚举**~~ → **已完全定案:** 境界突破 = **AdventureEvent-Finale**,作为**第七类并入 ADR-0002 枚举**,独立于 Combat(见「意图」与已修订的 `50-decisions/ADR-0002`)。**仅剩:** Finale 独立结算的具体机制(区别于 Combat 的规则)属内容 / 平衡设计。
- ~~**选择界面**~~ → **已定案:** 「从可用修行事件中选择」用一个**可横向滑动的选择区**(horizontal scrolling area),滑动选中目标 AdventureEvent。详见 `20-systems/map-progression.md`。
- **战斗模型细化(收窄):** life + mana、**无曲线 · 上限 + 逐步恢复**、炼气基线 10/10 · 5/5 均已定;**仅剩** mana 逐步恢复的具体速率、manaLimit / 基线随境界的成长。→ `20-systems/energy-economy.md`、`30-content/balance.md`。
- **属性模型(方向已定为隐藏):** 已定**属性隐藏**(类 Reigns 但不可见,驱动 AdventurePlot,见 `20-systems/run-manager.md`、`30-content/events.md`);仍待定 faith 归可见 / 隐藏、隐藏属性清单与阈值、以及它们与 life + mana 战斗资源的共存与推拉。

## 对应
提炼至:`.claude/knowledge/systems/adventure-event-combat.md`
