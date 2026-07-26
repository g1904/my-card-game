# profile-service（服务）

> 档案服务：**`PlayerProfile` 与 `CharacterProfile` 的唯一写入面**；capability 聚合；成就。**判据 ② —— 需要事务性地跨多个字段一致写入。**
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 为何是**一个**服务同时拥有两层 profile（已定案）

**`PlayerProfile` 持有 `List<CharacterProfile>`**（见 `20-systems/player-profile/_index.md`）——两层本就是一个聚合。由**单一 profile-service** 作为两者的唯一写入面，带来：

- **事务天然闭合。** 一次结算里「扣账号级 `PlayerItem` 使用次数 + 扣 run 级金币 + 加卡牌」落在**同一事务**内，不需要跨服务协调原子性。
- **存档提交点唯一。** 一次变更 = 一次提交，交给 sync-service 上行，不会出现「半套写入已上行」的中间态。
- `life-cycle-service` / `combat-service` / `future-event-service` **都只经它写档**，自身不直接改 Profile 字段。

### ProfileManager：统一变更施加点（已定案）

两个 Profile 的**一切变更**经一个入口，以**声明式的变更规格**驱动：

```csharp
var result = _profileManager.TryApply(spec);   // spec = CostSpec / RewardSpec（element 列表）
if (!result.Success)
{
    GD.PushWarning($"[ProfileManager-TryApply] insufficient, missing={result.MissingElement}");
    return;   // 全有或全无，不产生半成品状态
}
```

- **全有或全无。** 先**全量校验**所有 cost element 是否付得起，再**一次性提交**。这直接确定了「付不起某个 element 时整体不可选」这条判定。
- **它是已定 `selectCost` / `skipCost` 复合成本类型的唯一消费点。**（`selectCost` = 由若干 element 组成的定制复合类型，`lifeSpanCost` 是其中一个 element；`skipCost` 同类型。见 `20-systems/adventure-event/common-properties.md`。）
- **modifier pipeline 在此生效。** ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`，因此 PlayerPower 的全局数值修正（`lifeSpanCost`、商店价格、掉落权重……）**不需要任何消费层写 `if (hasPowerX)`**。新增一个修正 = 新增一条数据，受影响系统零改动。
- **可加性。** 新增一种资源 element = 新增一个 element 类型 + 数据字段；不新增服务、不改调用方。这正是**不为 power / item / card / resource 各开一个 collection 服务**的替代品（见 `_index.md` 的拆分轴）。

### CapabilityManager：能力标记聚合面（已定案）

`2026-07-25b` 定下的 capability flag 体系此前无宿主，现归本服务。

- 在启动及 PlayerProfile 变更时，遍历**拥有且 `status = 启用`** 的 `PlayerPower`，把它们声明授予的 **capability flag**（如 `RevealHiddenStats`、`ShowMysteryType`、`ShowSkipCost`）聚合为一份**生效能力集**，并把具名 **modifier** 聚合为修正表。
- 变更时经 **EventBus** 广播 `CapabilitiesChanged`。
- **消费侧收敛为「一个 flag ↔ 一处消费点」：** 受影响的 UI 组件**自己订阅**并查询 `Has(flag)`，业务逻辑层完全不知道该 power 存在。散落条件的根因是把呈现决策写进了业务层；把决策点归位，条件自然只剩一处。
- **`status`（启用 / 禁用）与「拥有 / 失去」是正交两维：** 列表成员表达「拥有哪些」，`status` 表达「拥有的这些里哪些当前生效」。失去 = 移出 `List<PlayerPower>`，不是置 `status = 禁用`。详见 `20-systems/player-profile/player-power/common-properties.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileManager** | 两个 Profile 的唯一写入面；`TryApply(spec)` 原子施加成本 / 产出；modifier pipeline 生效点 |
| **CapabilityManager** | capability flag 聚合 + 具名 modifier 表；`CapabilitiesChanged` 广播 |
| **AchievementManager** | 成就进度累计（组内加权）、60% / 90% 两档一次性奖励发放 |

## API 面（意图草图 · 签名待定）

- `Hydrate(profile)` → 载入拉取到的 PlayerProfile，触发 CapabilityManager 首次聚合。
- `TryApply(spec)` → 原子施加一份 CostSpec / RewardSpec；返回成功与否 + 未满足的 element。
- `CanAfford(spec)` → 只校验不提交（供 UI 灰显不可选项 / 预览）。
- `Has(flag)` / `Apply(key, baseValue)` → capability 与 modifier 的**单点查询**。
- `SetPowerStatus(powerId, enabled)` → 开关持久化，触发重聚合。
- `GrantPower(powerId)` / `RevokePower(powerId)` → 账号级能力的获取 / 失去（后者可由 AdventureEvent 触发）。
- `ConsumePlayerItem(itemId)` → 账号级道具使用次数扣减。
- `ReportProgress(...)` → 成就进度采集。
- **事件面：** `CapabilitiesChanged`、能力获取 / 失去、成就达档与奖励发放，经 EventBus 广播。

## 与其他服务的关系

- **上游写入方：** `life-cycle-service`（run 状态与隐藏属性）、`combat-service`（战斗内的 life / deck / 道具变更）、`future-event-service`（key points 推进）——**都只经 ProfileManager 写**。
- **下游：** `sync-service` 负责把变更后的聚合持久化 / 上行；本服务不做 I/O。
- **内容查找：** 一切 `Id` → 内容的解析经 `content-service.ContentRegistry`。

## 决策(-> ADR)

- **capability flag（布尔）+ modifier pipeline（数值）两条通道** → 已定案，**ADR 候选**（待固化）。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **单一 profile-service 拥有两层 profile、ProfileManager 为唯一写入面** → 已定案，**ADR 候选**（待固化）。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **强制在线 · 云端权威** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **cost element 清单未定。** `TryApply` 的形状取决于它：有哪些 element（gold / mana / 道具 / 隐藏属性推拉？）、各自数据形态（固定值 / 区间 / 公式）。「付不起时整体不可选」已由全有或全无的事务语义确定，但**是否允许部分抵扣**仍未定。→ `20-systems/adventure-event/common-properties.md`。
- **capability flag 的枚举与命名空间；叠加 / 冲突规则。** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 时的**运算顺序**（加法先于乘法？声明序？优先级字段？）未定。→ `20-systems/player-profile/player-power/common-properties.md`。
- **`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。
- **AchievementManager 的触发采集面。** 成就进度靠订阅 EventBus **被动采集**（解耦但易漏），还是由各服务**主动上报**（可靠但反向依赖）？
- **成就两档奖励内容。** 阈值 60% / 90%、一次性、目录 80% 可见已定；**各档发放何种奖励**待定。→ `40-ux/screen-flow.md`。
- **元进程字段结构。** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 各自 schema 与解锁 / 获取 / 失去的具体触发未定；`player-profile/` 子系统范围（是否为 achievements / account-info / game-setting 各建文件夹）待确认。→ `20-systems/player-profile/`。
- **PlayerPower 的平衡边界。** 方向已定为「轻度提升、PvE-only 可容忍」；是否影响 run seed / 计分公平仍待定。

## 对应
提炼至：`.claude/knowledge/systems/profile-service.md`（引用层，待建）。
