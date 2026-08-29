# player-power —— 共有属性

> PlayerPower 的共有字段与共有机制：开关、授予来源、事件触发器、被动修正、以及 capability flag + modifier pipeline 两条通道。内容定义侧的类型是 `PowerData`（两层共用），字段清单的权威在 `../../character-profile/power/_index.md`。为未来「每个 power 一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **`status`（共有字段：启用 / 禁用，默认启用）。** 每个 PlayerPower 都是 always-available 且**带开关**——开关落为 PlayerPower 类上的持久字段 `status`（启用 / 禁用），玩家可关闭。
- **`SourceCode`（共有字段 · 类型 `Source` 枚举）。** 落在 **PlayerPower 持有条目**上（与 `status` 同层），不落在 `PowerData` 上。
  - **本层合法取值 =** `FinaleWin` / `PremiumBundle` / `AchievementReward`（+ 读档兜底 `Unknown`）。
  - **本层消费点：** 道统残卷的分档自变量 `x`（= `SourceCode == FinaleWin` 的法则数，见 `_index.md`）——**这是全库唯一的规则消费点**。
  - 枚举清单、分域校验表（入口严 / 读档宽）、授予通道的强制携带与置换继承规则见 `systems/common-properties.md`。
- **`status` 与「拥有 / 失去」是两个正交维度。** PlayerProfile 的 `List<PlayerPower>` 表达**拥有哪些**；`status` 表达拥有的这些里**哪些当前生效**。「AdventureEvent 过程中可能失去 PlayerPower」是把条目**移出列表**，而非置 `status = 禁用`。存档需同时表达这两态。
- **事件触发器 → 被动修正（共有机制）。** power / relic 挂接到游戏事件的**触发器**上，命中时施加**被动修正**。这与 `csharp-godot-rules.md` 的 EventBus / 信号解耦事件一致。
- **内容定义 = `PowerData`（数据即资源）。** relic / joker 语义的条目是**数据**（`.tres`，带稳定唯一 `Id`，显示文案与 `Id` 分离、可本地化），**账号级与轮回级共用同一个 `PowerData` 类型**，由条目上的 `Scope: AbilityScope` 声明层。字段清单、`Abilities` 三档取值域、`GrantedFlags` / `Modifiers` 两条战斗外通道与各条加载期校验的权威在 `../../character-profile/power/_index.md`；触发条件与效果原语的表达形态（`TriggerConditionData` + 封闭时点常量表 · `EffectData` 子类树 · `KeywordData`）的权威在 `../../character-profile/deck/common-properties.md`。数值读自资源，不硬编码。

### 全局设定类效果的实现模型

> 原问题：像「让玩家看见角色隐藏属性数值」这类**更改全局设定**的 PlayerPower，如何系统性定制，而不是在每个受影响的层去加定制条件？**capability flag（布尔）+ modifier pipeline（数值）两条通道。**

统一形状：**数据声明 → 中心聚合 → 单点查询**，分两条通道。

**通道一 · 布尔型「能力标记 / capability flag」**（可见性、解锁、QoL）
- 每个此类效果定义为一个**具名 flag**（例：`RevealHiddenStats`、`ShowExploreType`），落成扁平的 `enum CapabilityFlag`——**不分区、不加前缀、不嵌套**（类型名本身就是命名空间，再加一层分区只会让每个消费点先答一次「它属于哪个区」）。条目的效果定义在 `.tres` 上**声明它授予哪些 flag**（`PowerData.GrantedFlags`）——新增能力 = 新增数据，不改系统代码。
- **成员命名 = 动词 + 宾语，动词取自封闭三词表** `Reveal`（把已存在但被隐藏的**信息**显出来）· `Show`（把某处 **UI 元素**显示出来）· `Unlock`（打开一个原本不可用的**入口**）。**禁止否定式 / 关闭式命名**（`Hide*` · `No*` · `Disable*` · `Suppress*` · `Prevent*`）——这不是风格偏好，而是下一条那个不变式的可机械检查形态。
- **capability 聚合面 = `profile-service.CapabilityManager`**，**范围是两层**：账号级 `playerPower` 与当前角色的 `characterPower` 经同三条与门（拥有 · `status == 启用` · 不在 `disabledAbility` 内）聚合成**同一份**生效能力集，变更时经 **EventBus** 广播空负载的 `CapabilitiesChanged`。触发源清单、无当前角色时的正常态、以及「轮回结束后角色级 flag 随重新聚合自然消失」见 `systems/services/profile-service.md`。
- **叠加 = 集合并，幂等。** 两个条目授予同一 flag ⇒ 生效集里出现一次，**不计数、不叠层、不告警**。**冲突则在结构上关死**：全部 flag 恒为增益向 / 打开向 ⇒ 不存在互相矛盾的两个 flag，union 就是全部规则，**不需要优先级字段、声明序或裁决表**。确需「关闭某项默认可见的东西」时，把默认态挪到内容侧 / `GameSetting`，用一个正向 flag 打开它。
- **消费侧收敛为「一个 flag ↔ 一处消费点」。** 让**受影响的组件自己订阅**：隐藏属性显示组件默认隐藏，自查 `Has(RevealHiddenStats)` 并响应 `CapabilitiesChanged` 重绘；业务逻辑层完全不知道该 power 存在。**条件散落的根因是把呈现决策写进了业务层**——决策点归位后，条件自然只剩一处。

**通道二 · 具名数值「修正管线 / modifier pipeline」**（平衡修正）
- 非布尔的全局修正（`lifeSpanCost`、商店价格、掉落权重……）由条目注册**具名 modifier**，形态是 `ModifierEntry(ModifierKey Key, ModifierOp Op, int Value)`、`ModifierOp { Add, Scale }`，落在 `.tres` 字段 `PowerData.Modifiers` 上。**`Scale` 的 `Value` 是万分比增量**（`-2000` = −20%），沿用万分比整数纪律、禁 `float`。
- 系统读取该数值时**统一走一个入口** `ApplyModifier(key, baseValue)`，而非各消费层写 `if (hasPowerX) value -= 1`。新增一个修正 = 新增一条数据，受影响系统零改动。
- **合并算法 = 同层求和 → 只乘一次 → 只取整一次**，外加两条钳制（`scale` 钳到 `[0, ∞)`——总折扣不得翻号；结果与 `baseValue` 同号或为 0）。**结果因此与声明顺序、遍历顺序、条目获得先后全部无关 ⇒ 不设优先级字段、不设稳定排序、不设声明序约定。** 四行算法与逐条理由见 `systems/services/profile-service.md`。
- **作用面（承重）：** modifier 只作用于**非 element 数值**（商店价格、掉落权重、战斗内数值）与 **`ResourceElements` 表中已显式登记 `ModifierKey` 的资源 element**；它**不作用于**能力（`AbilityElements`）、统计（`Stats`）、序号与付费凭证。`Elements` 侧是 opt-in 白名单、缺省豁免——否则一条法则就能静默改写幂等键、付费凭证或元进程计数。表、缺省方向与两向分列见 `systems/services/profile-service.md`。
- **一个 `ModifierKey` 只能有一个施加点**：判据是「该修正后的值是否需要在施加之前呈现给玩家」——需要则施加在展示 / 物化侧，不需要则施加在 `ProfileManager.TryApply`。两处都施加即打两次折。

两条通道均满足 `data-resource-rules.md` 的「内容保持可加性：新增 = 新增 `.tres`，而非编辑 switch 语句」。

Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` · `handoffs/2026-08-27-capability-flag-and-entitlement.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **全局设定类效果 = capability flag + modifier pipeline（数据声明 → 中心聚合 → 单点查询）** → `decisions/ADR-0017-capability-flag-and-modifier-pipeline.md`（Accepted）。
- **两条通道的落地形态**（扁平 `enum CapabilityFlag` + 正向三词表命名 · 叠加为幂等集合并 · 注册面两层共用 · `ModifierEntry` 万分比整数与「同层求和 → 只乘一次 → 只取整一次」）→ `decisions/ADR-0116-capability-flag-and-modifier-shape.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。→ `systems/services/profile-service.md` 的同名待决项。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（`PowerData`）；`.claude/knowledge/systems/player-profile/player-power/`（待建）。
