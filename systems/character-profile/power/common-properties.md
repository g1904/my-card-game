# character-power — 共有属性

> CharacterPower 条目的共有字段。**当前为骨架**：唯一已定的是「对标 PlayerPower」这条形状约束；字段清单本身待一次专门 session。

## 已定的约束

- **条目带稳定唯一 `Id`，定义为内容资源。** 与全库一致：能力是数据（`.tres`），显示文案与 `Id` 分离，经 `content-service.ContentRegistry` 读取；抽取走 `AllEnabled()`。
- **形状对标 PlayerPower。** `status`（启用 / 禁用）开关、事件触发器驱动的被动修正、capability flag + modifier pipeline 两条生效通道——除非另有陈述，沿用 `../../player-profile/player-power/common-properties.md` 的模型。**「拥有 / 失去」与「启用 / 禁用」是两个正交维度**（失去 = 移出持有列表，而非置禁用）。
- **生命周期 = 轮回级。** 由 CharacterProfile 持有，随 `defeated` / `completed` 一并清理；这是它与 PlayerPower 的**唯一本质分界**。
- **写入经 `profile-service.ProfileManager`。** 获得 / 失去 / 开关变更是 `ProfileChangeSpec` 的变更目标，不绕过唯一写入面。
- **`SourceCode`（共有字段：授予来源，类型 `Source` 枚举 · 已定案 · 08-12b）。** 神通条目同样记录**它是被哪条渠道给到玩家的**，与 `status` 同层、落在持有条目上而非 `PowerData` 上，写入时刻 = 授予时刻、此后不变。
  - **本层合法取值（08-12b 分域清单的神通列）= `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`**（+ 读档兜底 `Unknown`）。**这四条正是神通的常规来路**——08-10b 的封闭三值全是账号级途径、在本层无一合法，该冲突由 08-12b 扩清单解决（**推翻「清单是封闭的」**，而非收窄字段覆盖面）。`FinaleWin` / `PremiumBundle` / `AchievementReward` 在本层不合法：礼包与成就奖励按定义是账号级发放，发一件随轮回清理的东西作为付费 / 成就回报与「付费内容不会被游戏销毁」冲突。
  - **本层没有规则消费点**——`SourceCode` 的**规则**消费点唯一，是残卷的 `x`，而 `x` 只数法则。本层它承载的是**非规则用途**（`TryApply` 可追溯性日志 + 客服 / 数据侧溯源）。这条张力真实存在，是有意接受的代价：字段有信息但暂无规则消费者。
  - 枚举清单、分域校验表（入口严 / 读档宽）与授予通道的强制携带规则见 `systems/common-properties.md`。Source: `handoffs/2026-08-12b-grant-source-per-kind-scope.md`。

## 待定的字段清单

⟨待定：能力定义的字段（触发器、效果关键字、flag / modifier 声明）、持有条目的其余运行态字段（`status`、获得于哪个事件、层数？——**`SourceCode` 已定案，见上**）、以及是否与 `PlayerPowerData` 共用同一个数据类型——见 `_index.md` 的待决问题。⟩

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/common-properties.md`（待建）。
