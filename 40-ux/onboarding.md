# onboarding

> 首次游玩的教学:玩家学到什么,以及何时学到。

## 意图

- **强制账号登录(无游客)。** 首次进入需先**登录账号**方可游玩——已移除游客态,不存在「不登录直接进入」。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **首玩篇章门禁。** 首玩者进入主菜单后**只能从炼气(第一篇章)开始**;其余篇章选项在主菜单中**隐藏**,后续解锁后才出现。这是新玩家的天然收束——单一入口、零选择负担。Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`。
- **解锁态是账号级元进程数据**(落在 PlayerProfile 层,见 `20-systems/services/life-cycle-service.md`),与既有「篇章边界存档 → 读档续章」模型衔接:炼气可无门槛随机角色起手并无限重试;后续篇章需先解锁 / 有落过境界存档的角色(存档角色是有限资源)。Source: 同上 + `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。
- **篇章解锁触发(已定案)。** 解锁触发 = **角色通关上一篇章**,该角色随即成为下一篇章的**可挑战角色**。**若某篇章没有可重试 / 可挑战的角色,该篇章重新进入锁定(隐藏)状态**——即解锁是「有可挑战角色」的动态状态,而非一次性永久标志。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 50-decisions/ADR-####。_

## 待解问题

> _当前无未决项:篇章解锁触发已定案(见「意图」)。_

## 提供给
提炼进:`.claude/knowledge/scenes/_index.md`
