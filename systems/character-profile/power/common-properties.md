# character-power — 共有属性

> CharacterPower 条目的共有字段。**内容定义侧的字段清单在 `_index.md`**（两层共用一个 `PowerData`）；本文件只承载**持有条目侧**的共有字段与形状约束。

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

## 字段清单

- **内容定义侧 = `PowerData`，两层共用一个类型**，由条目上的 `Scope: AbilityScope` 声明自己属于哪一层。字段清单（含 `Abilities` 的三档取值域、`GrantedFlags` / `Modifiers` 两条战斗外通道、三格至少一格非空与战斗外触发式两条加载期校验）的权威在 `_index.md`，本文件**不复述**——复述即制造第二权威，两份各自漂移而本库无机制发现。
- **触发条件与效果的表达形态**同样不在本层：触发器是 `TriggerConditionData` + 封闭时点常量表、效果原语与关键字体系是 `EffectData` 子类树与 `KeywordData`，两者的权威均在 `../deck/common-properties.md`，`PowerData` 与 `CardData` 共用同一套。
- **内容编排口径**（开放的 `SourceCode` 通道与各自的档位收窄 · 失去形态与频次归属 · 效果形态禁令 · 条目数下限 · 绑定神通是否填 `ExclusiveSource`）与**跨载体边界判据**（什么该做成一张卡 / 一件法宝 / 一个神通）的权威同样在 `_index.md`，本文件**不复述**。
- **持有条目侧仍待定的一格**：`status`（启用 / 禁用）与「拥有 / 失去」两个正交维度如何编码进 schema，见 `_index.md` 的同名待决项。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/common-properties.md`（待建）。
