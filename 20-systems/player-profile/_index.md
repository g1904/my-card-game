# player-profile

> 玩家信息 / **PlayerProfile** —— 账号级主档，跨轮回持久，持有一组 CharacterProfile 及账号级元数据。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerProfile = 账号级主档（元进程层）。** 跨轮回持久，持有 `List<CharacterProfile>`（单次轮回状态见 `../character-profile/`）及账号级元数据。与「强制在线 · 云端权威」一致——PlayerProfile 是云端权威主档。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **账号级字段（大局骨架）。** `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等——`PlayerPower` / `PlayerItem` / `Achievements` 是**独立于任何单次轮回**的账号级解锁与成就。Source: `20-systems/services/life-cycle-service.md`。
- **子系统的文件形态（已定案）。** **`player-item/`、`player-power/`、`achievements/` 各成文件夹**（有子结构，`_index.md` + `common-properties.md`）；**`account-info.md`、`game-setting.md` 结构轻，各为独立 markdown**。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **服务归属：profile-service（已定案）。** 账号级行为——PlayerPower 的获取 / 失去与 `status` 开关持久化、PlayerItem 使用次数扣减、成就进度与奖励发放、capability flag 聚合——归 **`20-systems/services/profile-service.md`**。因 `PlayerProfile ⊃ List<CharacterProfile>`，该服务**同时是两层 profile 的唯一写入面**（`ProfileManager.TryApply(spec)`，全有或全无），使「扣账号级 PlayerItem 次数 + 扣轮回级灵玉」天然落在同一事务内。登录归 `account-service`，云端同步归 `sync-service`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 子系统导航

| 子系统 | 文件 | 内容 |
|--------|------|------|
| 玩家道具 player-item | `player-item/_index.md`、`player-item/common-properties.md` | 账号级、有使用次数限制的道具（PlayerItem），含可购道具定义。 |
| 玩家能力 player-power | `player-power/_index.md`、`player-power/common-properties.md` | 账号级 always-available 能力（PlayerPower，带开关）；通过事件触发器的被动修正 / relic-joker，含 RelicData 定义。 |
| 成就 achievements | `achievements/_index.md`、`achievements/common-properties.md` | 账号级分组成就与两档（60% / 90%）一次性奖励；80/20 可见比例。 |
| 账号信息 account-info | `account-info.md` | 账号身份与状态元数据（AccountInfo）；强制账号登录，无游客态。 |
| 游戏设置 game-setting | `game-setting.md` | 账号级常规系统设置（GameSetting，音量等）。 |

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **强制在线 · 云端权威**（PlayerProfile 为云端权威账号主档）→ `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **元进程持久化范围与平衡边界：** 各账号级字段的具体 schema、解锁 / 获取 / 失去触发，以及 PlayerPower 的平衡边界（防 pay/grind-to-win、是否影响 cycle seed / 计分公平）仍待定。→ 见 `20-systems/services/life-cycle-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/_index.md`（待建）。
