# run-manager

> Run 生命周期:开始(seed)、推进、胜/负、清理。

## 意图
> _设计意图,从 handoffs 中提炼。保持更新。_

- **两层持有模型(大局骨架,细节未定)。** 账号级的 **PlayerProfile** 跨 run 持久,持有一组 **CharacterProfile**;每个 CharacterProfile 是一次 run / 一个角色的状态与历史,对齐既有 RunState 概念。
  - **PlayerProfile(元进程层):** `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等。`PlayerPower` / `PlayerItem` / `Achievements` 是**独立于任何单次 run** 的账号级解锁与成就。
  - **CharacterProfile(单次 run):** `status`(**ongoing | defeated | completed**)、`chapter`(当前篇章)、`Status`(currentHealth / healthLimit、currentMana / manaLimit、以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan)、`List<AdventureEvent>`、`List<CharacterItems>`、**AdventurePlot key points**(剧情进度锚点;完整剧本内容不落存档,存于云端剧本服务,见 `20-systems/adventure-plot.md`) 等。
- **角色状态分类法(已定案)。** `discarded` 与 `defeated` **都是终态**,数据都会被清理;二者**合并为单一终态 `defeated`**,`discarded` 改为 `defeated` 的一个**原因 / 类型**(主动弃置是战败的一种)。故 `status` 收敛为 `ongoing | defeated | completed`(`defeated` 内含 discarded 等原因子类型)。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **多角色并存 + 每篇章至多一个 ongoing(语义已确认)。** 玩家可同时持有多个角色(CharacterProfile);但**每个篇章内至多一个 `ongoing`**——只要有一个角色在该篇章尚未结束进程(ongoing),就**不能在该篇章使用其他角色游玩**;不同篇章之间可各自并行。Source: `10-handoffs/2026-07-15b-...`,语义由 `10-handoffs/2026-07-22-...` 确认。
- **篇章继承:全部继承(已定案)。** 读档续章时,角色带入下一篇章的是**上一篇章的全部信息**(deck、法宝、属性、叙事标记等),无逐项筛选。此项**解锁**了 run-manager / map-progression 走向 `/derive-requirements`。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章解锁触发(已定案)。** 解锁触发 = **角色通关上一篇章**,随即成为下一篇章的**可挑战角色**;若某篇章没有可重试 / 可挑战的角色,该篇章**重新进入锁定(隐藏)**状态。见 `40-ux/onboarding.md`。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章存档 · 读档续章 · 重试模型。** 篇章通关即在所达境界落一个**存档点**(如打通炼气→筑基得到筑基存档);可读档从该境界起始下一篇章(筑基存档 → 开始筑基→金丹)。**炼气起手为随机角色,失败可近乎无限重试**;而**落过境界存档的角色,在后续篇章有有限的重试次数**——存档角色是一种会被耗尽的有限资源。**重试上限(数值,已定案 · 四境三篇章):** 第一章(炼气→筑基)= **无限**;第二章(筑基→金丹)= **3**;第三章(金丹→元婴)= **1**。挑战成功进入下一境界,不能重试之前篇章。(草稿中的「第四章」为笔误,已废弃。)Source: `10-handoffs/2026-07-15b-...` + 数值确认 `10-handoffs/2026-07-22-...`。
- **账号级能力 / 道具语义(已澄清)。**
  - **PlayerPower:** always-available 能力,带**开关(默认开启)**;可为 **QoL** 或**影响公平性的一定加强**(需衡量平衡),**通常全局、不与角色绑定**;获取越多后续越易,但 **AdventureEvent 过程中也可能失去**已获取的 PlayerPower。**定位 = 轻度提升(light improvement):** 承认它影响平衡,但因**本作无 PvP、纯 PvE**,让 power 带来一定强度是**可容忍的**,并**打开更大的设计空间**去做有趣的 power。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
  - **PlayerItem:** 有**使用次数限制**的道具。
  - **Achievements:** 玩家**只能查看进度 / 领取奖励**;奖励按**组内加权进度**发放(见 `40-ux/screen-flow.md`)。
  - Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **`faith` = 道心,归为隐藏数值属性(已定案)。** 原「信仰 / 即时属性」现明确为**隐藏属性 道心**,与 煞气、寿元 同属驱动 AdventurePlot 的隐藏属性。Source: `10-handoffs/2026-07-15-adventure-event-profiles.md` + 归隐藏 `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **属性模型 = 隐藏(已定案)。** 借鉴 **Reigns** 的属性模型,但**与 Reigns 相反:属性隐藏、不作可见仪表**,在背后影响 AdventureEvent。隐藏属性(**道心 / faith**、**煞气 / malefic qi**、**寿元 / lifeSpan**)落在 `CharacterProfile.Status` 内,随 run 推进被 AdventureEvent 推拉;达阈值驱动 **AdventurePlot(隐藏剧本层)** ——见 `20-systems/adventure-plot.md`、`30-content/events.md`。**寿元是独立于血量 `life` 的寿命数值,非 currentHealth。**(隐藏属性完整清单与阈值仍待定,见待决问题。)Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、全部继承、状态机、重试无限/3/1、篇章解锁）** → `50-decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威（含重账号，参考三国杀 Online；已删游客态）** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决,需要一次 handoff/决策。_

- **重试上限已定案:** 无限 / 3 / 1(三篇章)。若后续视作平衡项再调,归 `30-content/balance.md`。
- **元进程持久化范围:** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清(见「意图」),但**各自字段结构与解锁 / 获取 / 失去的具体触发**仍待定;账号级 meta 或许值得单独一份系统文档。**PlayerPower 平衡边界**(防 pay/grind-to-win、是否影响 run seed / 计分公平)待定。
  - **账号 / 云端同步维度(方向 + 路线已定,实现待决):** 已定**强制在线 · 云端权威 + 重账号**(参考三国杀 Online;见 `50-decisions/ADR-0003`)。**移动手感张力已裁定**为「允许短暂断线缓冲、恢复后同步」;**游客态已彻底移除**(强制账号登录)。**仅剩实现级待决:** 后端 / 账号系统具体选型、合规落地(PIPL / 实名 / 防沉迷 / 渠道审核 / 注销 / 数据导出)。Source: `10-handoffs/2026-07-22-...` + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **属性模型(已定为隐藏;细节待定):** 属性隐藏、`faith` = 道心 均已定案(见「意图」);仍待定:**隐藏属性完整清单**(道心 / 煞气 / 寿元之外)、各自阈值与增减触发、AdventurePlot 树的数据编码与 DnD 式选分支机制(归 `20-systems/adventure-plot.md`)。战斗资源已定为 life + mana(见 `20-systems/adventure-event-combat.md`)。Source: `10-handoffs/2026-07-23-...`。
- Source: `10-handoffs/2026-07-15-adventure-event-profiles.md`。

## 对应
提炼至:`.claude/knowledge/systems/run-manager.md`
