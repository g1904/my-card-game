# ADR-0017 — 全局设定类效果 = capability flag（布尔）+ modifier pipeline（数值）两条通道

- **状态：** Accepted
- **日期：** 2026-07-25
- **来源：** handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md · handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md · answer-logs/log-0725c.md

## 背景

有一类 PlayerPower 更改的是**全局设定**（例：「让玩家看见角色隐藏属性数值」「降低商店价格」）。若逐个在受影响的层里加定制条件（`if (hasPowerX) ...`），条件会散落到每一个消费点，新增一条能力就要改一遍系统代码——与「新增内容 = 新增数据，不编辑 switch」的可加性纪律正面冲突。

## 决策

**统一形状「数据声明 → 中心聚合 → 单点查询」，分两条通道：**

**通道一 · 布尔型 capability flag**（可见性、解锁、QoL）。每个此类效果定义为一个**具名 flag**；PlayerPower 的效果定义在 `.tres` 上声明它授予哪些 flag。一个 **capability 聚合面**（`profile-service.CapabilityManager`）在启动及 PlayerProfile 变更时，把**拥有且 `status = 启用`** 的 PlayerPower 所授予的 flag 聚合为一份**生效能力集**，变更经 EventBus 广播 `CapabilitiesChanged`（**空负载**）。**消费侧收敛为「一个 flag ↔ 一处消费点」**：受影响的组件自己订阅、自查 `Has(flag)`，业务逻辑层完全不知道该 power 存在。

**通道二 · 具名数值 modifier pipeline**（平衡修正）。PlayerPower 注册具名 modifier（key + 运算 + 数值，同为 `.tres` 字段）；系统读取该数值时统一走入口 `ApplyModifier(key, baseValue)`。

**两条承重边界：**

- **作用面。** modifier 只作用于**非 element 数值**（商店价格、掉落权重、战斗内数值）与 **`ResourceElements` 表中已显式登记 `ModifierKey` 的资源 element**；**不作用于**能力（`AbilityElements`）、统计（`Stats`）、序号与付费凭证。**`Elements` 侧是 opt-in 白名单、缺省豁免。**
- **一个 `ModifierKey` 只能有一个施加点。** 判据 = 「该修正后的值是否需要在施加之前呈现给玩家」——需要则施加在展示 / 物化侧（`ShopPrice` 即此档），不需要则施加在 `ProfileManager.TryApply`。两处都施加即打两次折。

形态与逐行取值见 `systems/player-profile/player-power/common-properties.md` 与 `systems/services/profile-service.md`。

## 理由

- **条件散落的根因是把呈现决策写进了业务层**——决策点归位后，条件自然只剩一处。
- 两条通道都满足可加性：**新增一个能力 / 一个修正 = 新增一条数据，受影响系统零改动**。
- **缺省方向必须取豁免侧**（两侧代价不对称）：漏填时若缺省豁免，最坏是某条法则本该修正它却没修正——数值不对、可见可复现、改一行修好；若缺省经 pipeline，最坏是某条法则**静默地**改写了幂等键 / 付费凭证 / 元进程计数，无人察觉，且在云端权威 + 后端复算下表现为两侧算不一致。
- **`CapabilitiesChanged` 用空负载**：订阅者收到后自行重查，这正是「一个 flag ↔ 一处消费点 · 单点查询」；把生效集塞进负载反而制造第二份真值。

## 备选方案

- **在每个受影响的层里写 `if (hasPowerX)`** — 否决：条件散落，新增能力要改系统代码。
- **让 `Elements` 缺省经 pipeline、逐条标注豁免** — 否决：漏填的代价是静默改写权威值（见理由第三条）。
- **一个 `ModifierKey` 在展示侧与施加侧都生效** — 否决：打两次折。
- **用 capability flag 承载付费凭证** — 否决：生效能力集受轮回级禁用截断，把付费凭证放进一个设计上就允许被截断的聚合面，等于给「花钱买的东西被事件拿走」留后门（见 `decisions/ADR-0023-premium-entitlement-and-redemption.md`）。

## 后果

- 长出一条承重的类型学判据：**capability / modifier 都是由内容条目聚合出的派生态，付费凭证与幂等键是账号上的原始事实——派生态不能承载原始事实。**
- `ResourceElements` 表因此多两列（`CostModifier` / `GainModifier`），且**按符号分向是必需的**——一条「寿元消耗 −20%」的法则若不分向，会把寿元回复也削 20%。
- **`Op == Set` 恒不经 pipeline**，与该行两个修正列是否为空无关；配套启动期断言把「允许 `Set` 的行两个修正列必须为 `null`」固定下来。
- 仍未定的落地细节（flag 枚举 / 命名空间、`status` 与「拥有 / 失去」两态的存档表达、**冲突 / 叠加规则**）留在 `systems/player-profile/player-power/common-properties.md` 与 `systems/services/profile-service.md` 的待决问题里——本 ADR 只固化模型。
- 影响文档：`systems/player-profile/player-power/common-properties.md`（权威）· `systems/services/profile-service.md` · `systems/architecture.md`（`ModifierKey` / `CapabilityFlag` 枚举与 `ResourceElements` 表）· `systems/adventure-event/exchange/_index.md`（`ShopPrice` 的施加点）。
