# onboarding

> 首次游玩的教学:玩家学到什么,以及何时学到。

## 意图

- **首玩篇章门禁。** 首玩者进入主菜单后**只能从炼气(第一篇章)开始**;其余篇章选项在主菜单中**隐藏**,后续解锁后才出现。这是新玩家的天然收束——单一入口、零选择负担。Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`。
- **解锁态是账号级元进程数据**(落在 PlayerProfile 层,见 `run-manager.md`),与既有「篇章边界存档 → 读档续章」模型衔接:炼气可无门槛随机角色起手并无限重试;后续篇章需先解锁 / 有落过境界存档的角色(存档角色是有限资源)。Source: 同上 + `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 50-decisions/ADR-####。_

## 待解问题

- **篇章解锁触发条件:** 首玩仅开炼气,其余「后续解锁」的具体触发是什么——通关上一篇章?达成成就?其它元进程?且与「篇章存档角色是有限资源」如何精确衔接?
- Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`。

## 提供给
提炼进:`.claude/knowledge/scenes/_index.md`
