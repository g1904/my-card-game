# 授予来源的判据钉为「谁组装」：`EventOutcome` 与 `CombatReward` 不合并

- id: 2026-08-16h-grant-source-assembler-criterion
- date: 2026-08-16
- topic: systems/common-properties · systems/services/combat-service · systems/services/future-event-service · systems/services/life-cycle-service · open-questions/06-meta-progression
- status: distilled
- distilled-to: `systems/common-properties.md`、`systems/services/combat-service.md`、`systems/services/future-event-service.md`、`systems/services/life-cycle-service.md`、`open-questions/06-meta-progression.md`、`answer-logs/log-event-outcome-vs-combat-reward.md`

## Intent（distilled）

**一句话：`Source` 的 `EventOutcome`(4) 与 `CombatReward`(5) **不合并**；两者的分野判据从「属于哪类事件」改钉为「**谁组装出这条 element**」，并在 `eventEnd` 加一条单向组装校验。成员清单、code、`(Kind, Scope)` 校验表、存档 schema、后端契约**全部零改动**。**

### 判据：看组装者，不看事件类型、也不看施加路径

> **看这条 element 是谁组装出来的。** 出自 `CombatResult.Spoils` → `CombatReward`；出自通用结算器的 outcome / effect 定义 → `EventOutcome`；出自购买流程 → `ExchangePurchase`。

三条支撑：

1. **施加路径不是判据。** 两者今天就已经走同一条施加链路——都收敛为 `ProfileChangeSpec`、都在 `eventEnd` 由同一次 `TryApply` 写入。若「施加路径同一 ⇒ 该合并」成立，`ExchangePurchase` 与 `InitialGrant` 也走同一条，一并该合并——而清单显然不是按这条轴切的。
2. **组装侧逐项不同。**

   | | `CombatReward` | `EventOutcome` |
   |---|---|---|
   | 组装者 | **combat-service**（`RunCombatAsync` 收口段） | **通用结算器**（非战斗四类共享的那条形状） |
   | 输入 | 道念差（决定厚度）+ `RewardPoolId` 抽取池 + `BaseReward` | 物化后的 `EventOption` 上的 outcome / effect 定义 |
   | 是否含玩家选择步骤 | **是**（战后可选奖励面板） | 否 |
   | 是否含随机 | 是（`Reward` 子流掷候选） | 由 outcome 定义决定，非结构必然 |
   | 载体 | `CombatResult.Spoils` | 事件结算产出 |
3. **清单的粒度轴本就是「渠道 / 组装路径」，不是「战斗 vs 非战斗」。** Exchange 是非战斗类事件，其购买所得却单列 `ExchangePurchase` 而非归入 `EventOutcome`。在这条轴上合并 Combat 的 `Spoils` 与非战斗 outcome，会是整份清单里唯一一次反向粗化。

### 按事件类型表述会被两处打穿

- **Explore。** `EventOption.EventType` 在 Explore 时恒为 `Explore` 本身，真身在 `RevealedEventId`。一个揭示出战斗真身的 Explore 选项，按事件类型判是「非战斗」，按组装者判是 combat-service 交出的 `Spoils`——**后者是对的**。
- **Exchange 的非购买 outcome**（对话结果、赠礼）归 `EventOutcome` 还是 `ExchangePurchase`？按组装者判据答案唯一：**只有走购买流程的那一条走 `ExchangePurchase`，其余走 `EventOutcome`**。这是一条预置判据——即便 Exchange 最终只有购买一条产出路径，它也不产生任何取值。

### 为什么不合并：丢掉的信息不可重建

合并后 `ProfileManager.TryApply` 的可追溯性日志只能说「来自某个事件」，客服 / 数据侧也失去「战斗掉落 vs 事件产出」这条区分——它正是「我打赢了却没拿到东西」这类申诉的第一手依据。**持有条目上没有任何字段能补出这个维度**（`SourceInstanceId` 是另一个字段，语义是「施加禁用的来源事件实例」，二者明令不得合并）。对价只是「少一个枚举成员」，而成员本身零维护成本：不进 `.tres`、不走 overlay、后端不复制校验表。

叠加已冻结的「名与 code 双双永不复用」，粒度选择是**不对称的**：细了可以永远不用（成本恒为零），粗了要补回来得追加新成员且老数据无法回填（`SourceCode` 写入即冻结）。

### 唯一的张力，如实记下

`(Kind, Scope)` 校验表中两行逐格相同（❌ ❌ ✅ ✅）——这是合并方最强的论据。**但「行相同」不是合并判据**：同一张表里 `PremiumBundle` 与 `AchievementReward` 两行同样逐格相同（✅ ✅ ❌ ❌），而无人主张合并它们。行相同只说明两者的**挂载面**相同（能出现在哪类持有条目上），渠道说的是**由哪条路径给出**——两个正交维度。

### `eventEnd` 的单向组装校验（采纳）

组装者是代码位置、不可机械校验；可机械化的退而求其次形态：life-cycle-service 合并 `eventEnd` 事务时，检查 spec 内 `Op == Grant` 的 element ——

- 本次事件**未走过 combat-service** 却出现 `Source == CombatReward` → **必需缺失**，`GD.PushError` + **整批拒绝**；
- 反向（走过 combat-service 的事件里出现 `EventOutcome`）**不判非法**——战斗事件除 `Spoils` 外仍可携带事件级 outcome。

**判据取「本次事件是否产生过 `CombatResult`」，不取 `EventOption.EventType`**——照后者判，一个揭示出战斗真身的 Explore 事件会把合法的 `CombatReward` 误判为非法并整批拒绝，正是上面那条打穿点在校验侧的镜像。单向而非双向，与既有的「入口严、读档宽」及 `(Kind, Scope)` 入口校验同一档纪律；读档侧照旧宽（保留原值、不改写）。

### 关闭条件（可观察的重开触发器）

本条答定为「不合并」，从待决区移出。**仅当 combat-service 的奖励计算被并入通用结算器时重新评估**——具体即以下任一发生：① `RunCombatAsync` 不再自算 `Spoils`；② 战后可选奖励选择步骤被取消；③ 奖励厚度不再由道念差决定。三者任一都会在 `systems/services/combat-service.md` 的「意图」节留下明确痕迹，故该触发器是可观察的，不需要定期主动复核。

### 零改动清单

`Source` 七值 + 兜底不变 · 两个 code 不变 · `(Kind, Scope)` 合法子集表不变 · **不 bump 存档 schema、无迁移** · 后端契约与 `backend-design-documents/` 全库零改动。

**本条不横跨边界**：这两个成员按 `(Kind, Scope)` 表只能出现在轮回级两类上，而 `backend-design-documents/contracts/profile-sync.md` §5 把 `characterDiffs` 整体列为不透明段——**后端从头到尾读不到这两个值**。故对侧库无承接项。

## Clarifications（interview 产物）

草稿在评审阶段已由用户裁定两项取向，本次运行无新增澄清：

- **是否就此关闭这条待决问题** → **关闭**。判据已齐备，悬置不产生新信息；每一天的运行都在按当前语义写入不可回改的 `SourceCode`，而当前无线上账号是代价最低的关闭窗口，且重开触发器可观察。
- **是否采纳 `eventEnd` 的单向组装校验** → **采纳**，判据取「是否走过 combat-service」。

## Open questions

无。两条软相关项均不改变本次结论，只可能影响措辞，且各自留在原属文档的待决区：`EventOption` 的完整物化字段清单（`future-event-service.md`）· 交易机制专场未开（`systems/adventure-event/exchange/`）。

## Notes / triage

已否决的备选：合并为单一成员（丢掉不可重建的维度）· 保留两值但按事件类型定义（Explore 揭示战斗真身时判错）· 继续悬置（判据已齐备，悬置不产生新信息）· 合并后另加布尔 / 事件类型字段保住溯源（用两个字段表达一个枚举本就能表达的东西，且新字段要进存档与四类持有条目）。
