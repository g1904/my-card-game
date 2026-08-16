# character-power — 共有属性

> CharacterPower 条目的共有字段。**当前为骨架**：唯一已定的是「对标 PlayerPower」这条形状约束；字段清单本身待一次专门 session。

## 已定的约束

- **条目带稳定唯一 `Id`，定义为内容资源。** 与全库一致：能力是数据（`.tres`），显示文案与 `Id` 分离，经 `content-service.ContentRegistry` 读取；抽取走 `AllEnabled()`。
- **形状对标 PlayerPower。** `status`（启用 / 禁用）开关、事件触发器驱动的被动修正、capability flag + modifier pipeline 两条生效通道——除非另有陈述，沿用 `../../player-profile/player-power/common-properties.md` 的模型。**「拥有 / 失去」与「启用 / 禁用」是两个正交维度**（失去 = 移出持有列表，而非置禁用）。
- **生命周期 = 轮回级。** 由 CharacterProfile 持有，随 `defeated` / `completed` 一并清理；这是它与 PlayerPower 的**唯一本质分界**。
- **写入经 `profile-service.ProfileManager`。** 获得 / 失去 / 开关变更是 `ProfileChangeSpec` 的变更目标，不绕过唯一写入面。
- **`SourceCode`（共有字段 · 类型 `Source` 枚举）。** 落在 **CharacterPower 持有条目**上（与 `status` 同层），不落在 `PowerData` 上。
  - **本层合法取值 =** `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`（+ 读档兜底 `Unknown`）——这四条正是神通的常规来路。
  - **本层无规则消费点**——`x` 只数法则。本层它只承载非规则用途，**字段有信息但暂无规则消费者**，这是有意接受的代价。
  - 枚举清单、分域校验表（入口严 / 读档宽）与授予通道的强制携带规则见 `systems/common-properties.md`。

Source: `handoffs/2026-08-12b-grant-source-per-kind-scope.md`

## 待定的字段清单

⟨待定：能力定义的字段（触发器、效果关键字、flag / modifier 声明）、持有条目的其余运行态字段（`status`、获得于哪个事件、层数？——**`SourceCode` 见上**）、以及是否与 `PlayerPowerData` 共用同一个数据类型——见 `_index.md` 的待决问题。⟩

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/common-properties.md`（待建）。
