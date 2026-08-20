# Answer log game-setting-schema

- 日期：2026-08-19
- 来源：`inbox/solution-draft-game-setting-schema.md` → `handoffs/2026-08-19-game-setting-schema.md`
- 移出条数：3

- **`GameSetting` 的设置项清单是什么** → 账号级四项（`MasterVolume` / `MusicVolume` / `SfxVolume` 三条 `int` `[0,100]` 音量轨 + `FastCombatAnimation` `bool`），默认 100 / 80 / 100 / `false`；音量默认值标注为待实测初值。首批不收震动 / 画质 / 帧率 / 二次确认开关 / 辅助功能，各带解除条件；内容语言与界面语言分离明确否决；「同步版本 #N」不是设置项。（归档去向：`systems/player-profile/game-setting.md`）
- **设备本地项 vs 账号级项的切分** → 判据 = 「这一项的正确取值是否取决于这台机器」，配一条评审用的自检反问与「拿不准归设备本地」的缺省方向；一项设置只能落一侧。首批设备本地一项 `locale`，落 `user://cache/device-settings.json`（切账号不失效 · 整份可选缺失 · 不走 `MigrationManager` · 不依赖任何服务）。`GameSetting` 只承载账号级那一半，包含关系是「设置 ⊃ `GameSetting`」。（归档去向：`systems/player-profile/game-setting.md`；同一条也登记在 `open-questions/deferred-content.md`）
- **`gameSetting` 的写入通道** → `ProfileChangeSpec` 新增一列 `SettingChanges` + `SettingFields` 配表（Key / Kind / Min / Max / 默认，默认值的唯一一处）；`SettingAssignment` 两个载荷格皆可空（`int?` / `bool?`），使「哪一格有效」可机械校验；施加失败语义五行；`PushPolicy.Debounced` + `SavePointReason.MetaChanged`，不计软阻塞闸门。（归档去向：`systems/services/profile-service.md` · `systems/architecture.md` · `systems/services/sync-service.md` · `systems/player-profile/_index.md` 15 字段表第 15 行）

**同批答定的相邻结论**（不单独占条目）：`user://` 原子写抽成不属任何服务的共享静态工具 `AtomicJsonFile`，本体登记在 `systems/architecture.md`，`LocalCacheManager` 由实现方改为调用方；`user://cache/` 的 schema 版本要求由全称改为按判据（多字段结构体才需版本）。

**仍留在待答清单的相邻项**：三条音量轨默认值的真机校准 · 「寿元告警是否伴随音效 / 震动」（震动开关的解除条件）· 辅助功能一行待战斗 UX 专场重估 · refresh token 的客户端持有形态。
