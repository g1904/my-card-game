# character-power — 共有属性

> CharacterPower 条目的共有字段。**当前为骨架**：唯一已定的是「对标 PlayerPower」这条形状约束；字段清单本身待一次专门 session。

## 已定的约束

- **条目带稳定唯一 `Id`，定义为内容资源。** 与全库一致：能力是数据（`.tres`），显示文案与 `Id` 分离，经 `content-service.ContentRegistry` 读取；抽取走 `AllEnabled()`。
- **形状对标 PlayerPower。** `status`（启用 / 禁用）开关、事件触发器驱动的被动修正、capability flag + modifier pipeline 两条生效通道——除非另有陈述，沿用 `../../player-profile/player-power/common-properties.md` 的模型。**「拥有 / 失去」与「启用 / 禁用」是两个正交维度**（失去 = 移出持有列表，而非置禁用）。
- **生命周期 = 轮回级。** 由 CharacterProfile 持有，随 `defeated` / `completed` 一并清理；这是它与 PlayerPower 的**唯一本质分界**。
- **写入经 `profile-service.ProfileManager`。** 获得 / 失去 / 开关变更是 `ProfileChangeSpec` 的变更目标，不绕过唯一写入面。

## 待定的字段清单

⟨待定：能力定义的字段（触发器、效果关键字、flag / modifier 声明）、持有条目的运行态字段（`status`、获得于哪个事件、层数？）、以及是否与 `PlayerPowerData` 共用同一个数据类型——见 `_index.md` 的待决问题。⟩

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/common-properties.md`（待建）。
