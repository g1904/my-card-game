# game-setting

> 游戏设置 / **GameSetting** —— PlayerProfile 上的账号级常规系统设置。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **GameSetting = 账号级常规系统设置。** PlayerProfile 的一个账号级字段（音量等）；是主菜单「Settings（设置）」按钮的数据来源。Source: `40-ux/screen-flow.md`。
- **随账号云端持久。** 与其他账号级字段一致，写入经 `profile-service.ProfileManager`、同步经 `sync-service`，云端为权威。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **本子系统为独立 markdown（已定案）。** 结构轻，不成文件夹。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **设置项清单未定：** 除音量外还有哪些（画质 / 震动 / 语言 / 辅助功能 / 动画速度？）未设计。
- **设备本地项 vs 账号级项的切分未定：** 部分设置（如画质、震动）与设备强相关，是否应留在本地 `user://` 而不上行云端待定。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/game-setting.md`（待建）。
