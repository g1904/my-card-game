# game-setting

> 游戏设置 / **GameSetting** —— PlayerProfile 上的账号级常规系统设置。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **GameSetting = 账号级常规系统设置。** PlayerProfile 的一个账号级字段（音量等）；是主菜单「Settings（设置）」按钮的数据来源。
- **随账号云端持久。** 与其他账号级字段一致，写入经 `profile-service.ProfileManager`、同步经 `sync-service`，云端为权威。
- **形态 = 具名类，不是字典 / 键值表。** 与「`CapabilityFlag` 用 `enum` 而非字符串 key」「`PlayerEntitlement` 用具名字段而非集合」同一条纪律：开放容器把「拼错了」从编译期推迟到运行时，还会让「哪些项是账号级」这个真问题被悄悄绕过。
  - **落笔顺序：先答「设备本地项 vs 账号级项的切分」，再一次性定清单**（见待决问题）。那一条决定哪些字段进 `PlayerProfile`（云端权威 · 进 diff）、哪些留 `user://`；在它答定前填字段等于替用户拍板一次同步口径。
- **本子系统为独立 markdown。** 结构轻，不成文件夹。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-08-17h-profile-field-schema.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **设置项清单未定：** 除音量外还有哪些（画质 / 震动 / 语言 / 辅助功能 / 动画速度？）未设计。
- **设备本地项 vs 账号级项的切分未定：** 部分设置（如画质、震动）与设备强相关，是否应留在本地 `user://` 而不上行云端待定。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/game-setting.md`（待建）。
