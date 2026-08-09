# profile-service（服务）

> 档案服务：**`PlayerProfile` 与 `CharacterProfile` 的唯一写入面**；capability 聚合；成就。**判据 ② —— 需要事务性地跨多个字段一致写入。**
> Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 为何是**一个**服务同时拥有两层 profile（已定案）

**`PlayerProfile` 持有 `List<CharacterProfile>`**（见 `systems/player-profile/_index.md`）——两层本就是一个聚合。由**单一 profile-service** 作为两者的唯一写入面，带来：

- **事务天然闭合。** 一次结算里「扣账号级 `PlayerItem` 使用次数 + 扣轮回级灵玉 + 加卡牌」落在**同一事务**内，不需要跨服务协调原子性。
- **存档提交点唯一。** 一次变更 = 一次提交，交给 sync-service 上行，不会出现「半套写入已上行」的中间态。
- `life-cycle-service` / `combat-service` / `future-event-service` **都只经它写档**，自身不直接改 Profile 字段。

### ProfileManager：统一变更施加点（已定案）

两个 Profile 的**一切变更**经一个入口，以**声明式的变更规格**驱动：

```csharp
var result = _profileManager.TryApply(spec);   // spec = ProfileChangeSpec（element 列表，BaseValue 带符号）
if (!result.Success)
{
    GD.PushWarning($"[ProfileManager-TryApply] insufficient, missing={result.MissingElement}");
    return;   // 全有或全无，不产生半成品状态
}
```

- **全有或全无。** 一次 `TryApply` 是**单点提交**：要么全部 element 一起落，要么一个都不落——不允许半套写入。**「先全量校验付得起、否则整体拒绝」已不再适用于事件推进（08-06c）**：`selectCost` **无条件施加**，支付后由 life-cycle-service 做终态判定。**事务性与可负担性校验是两件事，这次只拆掉后者**；负值施加时各资源的钳制规则待定，见待决问题。Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **它是已定 `selectCost` 复合成本类型的唯一消费点。**（它是 **`ProfileChangeSpec`**——由若干 `ChangeElement` 组成，`lifeSpanCost` 是其中一个 element；见 `systems/adventure-event/common-properties.md`。）**成本与产出用同一个类型**：`ChangeElement.BaseValue` 带符号（负 = 消耗，正 = 产出），使一次结算的扣减与收益天然落在同一事务内。Source: `handoffs/2026-07-27b-service-api-contracts.md`。
- **modifier pipeline 在此生效。** ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`，因此 PlayerPower 的全局数值修正（`lifeSpanCost`、商店价格、掉落权重……）**不需要任何消费层写 `if (hasPowerX)`**。新增一个修正 = 新增一条数据，受影响系统零改动。
- **首批具名 element 中已确定的一组：道统残卷（已定案 · 08-09b）。** 「cost element 清单未定」这条待答由此添了具体条目——`PowerFragmentAccumulated`（累加 / 置值）、`PowerFragmentWinOrdinal`（自增）、`PowerFragmentFirstWin(chapter)`（置位）、以及**授予法则**（复用 `GrantPower` 语义，但作为 `Spoils` 的一个 element 提交）。四者与 `baseReward` / `lifeTotal` 扣减 / `lifeSpanCost` 落在 Finale 的**同一次 `TryApply`** 内，符合「一个事件 = 一次事务 = 一个存档点」。**`Accumulated` 是万分比整数、施加后钳制到 `[0, 10000]`**——它是「负值施加的钳制规则」这条待答项在账号级侧的第一个已定案例。Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **可加性。** 新增一种资源 element = 新增一个 element 类型 + 数据字段；不新增服务、不改调用方。这正是**不为 power / item / card / resource 各开一个 collection 服务**的替代品（见 `_index.md` 的拆分轴）。

### CapabilityManager：能力标记聚合面（已定案）

`2026-07-25b` 定下的 capability flag 体系此前无宿主，现归本服务。

- 在启动及 PlayerProfile 变更时，遍历**拥有且 `status = 启用`** 的 `PlayerPower`，把它们声明授予的 **capability flag**（如 `RevealHiddenStats`、`ShowMysteryType`）聚合为一份**生效能力集**，并把具名 **modifier** 聚合为修正表。
- 变更时经 **EventBus** 广播 `CapabilitiesChanged`。
- **消费侧收敛为「一个 flag ↔ 一处消费点」：** 受影响的 UI 组件**自己订阅**并查询 `Has(flag)`，业务逻辑层完全不知道该 power 存在。散落条件的根因是把呈现决策写进了业务层；把决策点归位，条件自然只剩一处。
- **`status`（启用 / 禁用）与「拥有 / 失去」是正交两维：** 列表成员表达「拥有哪些」，`status` 表达「拥有的这些里哪些当前生效」。失去 = 移出 `List<PlayerPower>`，不是置 `status = 禁用`。详见 `systems/player-profile/player-power/common-properties.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileManager** | 两个 Profile 的唯一写入面；`TryApply(spec)` 原子施加成本 / 产出；modifier pipeline 生效点 |
| **CapabilityManager** | capability flag 聚合 + 具名 modifier 表；`CapabilitiesChanged` 广播 |
| **AchievementManager** | 成就进度累计（组内加权）、60% / 90% 两档一次性奖励发放 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界，故**全部方法为形态 A**、不实现 `IBootstrappable`。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 载入 | A | `void Hydrate(PlayerProfile profile)` | `profile == null` = 程序缺陷 → `PushError` + 抛；触发 CapabilityManager 首次聚合 |
| 施加变更 | A | `ApplyResult TryApply(ProfileChangeSpec spec)` | **业务失败** → `ApplyResult.Fail(missingElement)`，全有或全无，绝不抛 |
| 预校验 | A | `bool CanAfford(ProfileChangeSpec spec)` | 供 UI 灰显 / 预览，**不提交** |
| 能力查询 | A | `bool Has(CapabilityFlag flag)` | 未授予 = `false`，非错误 |
| 数值修正 | A | `int ApplyModifier(ModifierKey key, int baseValue)` | 无修正 = 原值返回 |
| 开关 | A | `ApplyResult SetPowerStatus(string powerId, bool enabled)` | 未拥有该 power → `ApplyResult.Fail` |
| 授予 / 撤销 | A | `ApplyResult GrantPower(string powerId)` / `ApplyResult RevokePower(string powerId)` | 同上 |
| 消耗账号道具 | A | `ApplyResult ConsumePlayerItem(string itemId, int count = 1)` | 次数不足 → `ApplyResult.Fail` |
| 成就采集 | A | `void ReportProgress(AchievementSignal signal)` | — |
| 只读快照 | A | `PlayerProfile Snapshot { get; }` | **只读视图**（非可变引用），供 sync / ViewModel 组装 |

- **`CostSpec` / `RewardSpec` 已合并为单一 `ProfileChangeSpec`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）。两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入，与「全有或全无、单点提交」直接冲突。
- **`CanAfford` 与 `TryApply` 必须走同一条 modifier pipeline**，否则 UI 显示「买得起」而实际拒绝。二者共用一个内部 `Evaluate(spec)`，`TryApply` = `Evaluate` + 提交。
- **`Snapshot` 返回只读视图**（总则 3）；运行态写入一律经 `TryApply`。
- **`CapabilityFlag` 是 C# `enum` 而非字符串 key**：flag 的消费点必然是一段 UI 代码，新增 flag 本就要写消费代码；字符串只是把「拼错了」从编译期推迟到运行时。可加的是 `.tres` 里**谁授予哪个已定义的 flag**。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CapabilitiesChanged` | **空负载**——订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查（既定的「一个 flag ↔ 一处消费点 · 单点查询」；把生效集塞进负载反而制造第二份真值） |
| `AchievementTierReached` | `(string GroupId, int TierPercent)` |

## 与其他服务的关系

- **上游写入方：** `life-cycle-service`（轮回状态与隐藏属性）、`combat-service`（战斗内的 life / deck / 道具变更）、`future-event-service`（key points 推进）——**都只经 ProfileManager 写**。
- **下游：** `sync-service` 负责把变更后的聚合持久化 / 上行；本服务不做 I/O。
- **内容查找：** 一切 `Id` → 内容的解析经 `content-service.ContentRegistry`。

## 决策(-> ADR)

- **capability flag（布尔）+ modifier pipeline（数值）两条通道** → 已定案，**ADR 候选**（待固化）。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **单一 profile-service 拥有两层 profile、ProfileManager 为唯一写入面** → 已定案，**ADR 候选**（待固化）。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **cost element 清单未定。** `TryApply` 的形状取决于它：有哪些 element（jade / mana / 道具 / 隐藏属性推拉？）、各自数据形态（固定值 / 区间 / 公式）。→ `systems/adventure-event/common-properties.md`。
- **负值施加的钳制规则未定（08-06c 新增 · 承重）。** `selectCost` 无条件施加后必须回答：**哪些资源截断到 0、哪些允许为负、哪些的耗尽构成终态**（寿元归 0 = `defeated` 已定；灵玉 / mana / 其余 element 未定）。它决定 `TryApply` 在余额不足时的行为。→ `systems/character-profile/currency.md`。Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **`CanAfford` / 「余额不足即拒」还剩哪些消费点（08-06c 新增）。** 事件推进路径已不需要；Exchange 内的商店购买等主动消费点是否仍需？若全都不需要，`CanAfford` 与 `AdvanceResult.CostRejected` / `MissingElement` 可整体删除。Source: 同上。
- **capability flag 的枚举与命名空间；叠加 / 冲突规则。** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 时的**运算顺序**（加法先于乘法？声明序？优先级字段？）未定。→ `systems/player-profile/player-power/common-properties.md`。
- **`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。
- **AchievementManager 的触发采集面。** 成就进度靠订阅 EventBus **被动采集**（解耦但易漏），还是由各服务**主动上报**（可靠但反向依赖）？
- **成就两档奖励内容。** 阈值 60% / 90%、一次性、目录 80% 可见已定；**各档发放何种奖励**待定。→ `ux/screen-flow.md`。
- **元进程字段结构。** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 各自 schema 与解锁 / 获取 / 失去的具体触发未定；`player-profile/` 子系统范围（是否为 achievements / account-info / game-setting 各建文件夹）待确认。→ `systems/player-profile/`。
- **PlayerPower 的平衡边界。** 方向已定为「轻度提升、PvE-only 可容忍」；是否影响 cycle seed / 计分公平仍待定。

## 对应
提炼至：`.claude/knowledge/systems/profile-service.md`（引用层，待建）。
