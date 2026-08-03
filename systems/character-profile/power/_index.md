# character-power

> **神通 / CharacterPower** —— **轮回级**的角色能力，**对标账号级的 PlayerPower（法则）**：同一概念的两层，差别只在生命周期与获取面。占位结构，机制待一次专门 session。
> **中文定名 = 神通**（08-03 定，取代「角色能力」）。**中文名不表达层级** —— 账号级 ↔ 轮回级的对称只在英文标识符上成立（`Player*` / `Character*`）。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterPower = 轮回级的角色能力（已定案）。** 它**对标 `PlayerPower`**（账号级能力，见 `../../player-profile/player-power/`）：二者是同一个「能力」概念在两个生命周期层上的实例。由 CharacterProfile 持有，**随轮回存在、随轮回清理**。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **「对标」的含义（可复用的形状）。** PlayerPower 已定的那套结构在轮回层同样适用，除非另有陈述：**always-available、带 `status` 开关**、通过**事件触发器施加被动修正**（relic / joker 语义）、以及 **capability flag（布尔）+ modifier pipeline（数值）**两条生效通道。**「拥有 / 失去」与「启用 / 禁用」仍是两个正交维度。** 见 `../../player-profile/player-power/common-properties.md`。Source: 同上（推演自「对标 PlayerPower」）。
- **与 PlayerPower 的分界 = 生命周期层，而非能力种类。** 这与全库既定的拆分轴一致（`PlayerItem` ↔ `CharacterItems` 是同一条分界）：**账号级的跨轮回持久、失败不清；轮回级的随 `defeated` / `completed` 一并清理**。因此二者**不共用一份持有列表**，但可以共用同一套能力定义与生效管线。Source: 同上。
- **神通可承载战斗内的触发式效果（已定案 · 08-03 · 承重）。** 触发式效果的载体是开放的——**牌上的触发器 / 场上的持续状态 / CharacterPower** 都可能承载。**推论 ①：轮回级能力必须能被战斗内读到**——combat-service 组装参战方时要把角色持有的神通**注册进战场（battlefield）**，触发命中后由 StackManager 压栈。**推论 ②：神通不再只是「战斗外的 build 数值」**——它在战斗内有一条直接的表达通道，与卡牌并列。见 `systems/services/combat-service.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **它是轮回内 build 的一部分。** 与 deck（卡组）、CharacterItem / 法宝（角色道具）并列——一次轮回里「我这局变强了多少」由这三者共同承载，而 PlayerPower 承载的是「跨轮回我强了多少」。
- **有自己的图鉴：CharacterPowerCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色能力单列一本。**图鉴是账号级、跨轮回持久的**，而 CharacterPower 本身随轮回清理：轮回结束后能力没了，但「见过它」这条知识留下。Source: 同上。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **存在轮回级的 `CharacterPower`，对标账号级的 `PlayerPower`** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **与 PlayerPower 的复用边界（承重）。** 「对标」到什么程度：共用同一个 `PowerData` 定义与同一条 modifier pipeline，只是持有列表与清理规则不同？还是各自一套数据类型？前者可加性更好，但要求能力定义能声明自己属于哪一层。→ `../../player-profile/player-power/common-properties.md`、`systems/services/profile-service.md`。
- **获取 / 失去触发。** 在哪些 AdventureEvent 获得（闭关顿悟？社交传功？秘境所得？）、能否失去、篇章突破时是否随「全部继承」一并带入下一篇章（既定的篇章继承是**全部继承**，故默认应带入——需确认）。→ `systems/adventure-event/`、`systems/services/life-cycle-service.md`。
- **与卡牌 / CharacterItems 的边界。** 三者都是轮回内的 build 组件：什么该做成一张卡、什么该做成一件道具、什么该做成一个能力？判据未给。→ `../deck/`、`../item/`。
- **写入面与存档形态。** 持有列表落在 CharacterProfile 的哪个字段、`status` 开关是否也持久化、写入是否同样经 `profile-service.ProfileManager`（应是）。→ `systems/services/profile-service.md`。
- **数量与强度尺度。** 一次轮回里预期获得几个、单个的强度量级（相对 PlayerPower 的「轻度提升」定位是更强还是更弱）未定。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/_index.md`（待建）。
