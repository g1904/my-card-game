# monetization（商业化）

> 付费形态与其对玩法的影响面。**当前只有一个付费点：premium bundle（付费礼包）。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### premium bundle（已定案 · 唯一已陈述的付费点）

购买后一次性给予：

| 项 | 内容 | 影响面 |
|----|------|--------|
| ① | **随机 1 个 PlayerPower** | 账号级能力（`systems/player-profile/player-power/`） |
| ② | **随机 2 个 PlayerItem** | 账号级道具（`systems/player-profile/player-item/`） |
| ③ | **第二篇章重试上限 3 → 9** | ADR-0004 / `services/life-cycle-service.md` |
| ④ | **第三篇章重试上限 1 → 3** | 同上 |

第一篇章的重试**本就无限**，礼包不涉及。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

### 推论

- **重试上限首次成为可变量（承重）。** ADR-0004 的「无限 / 3 / 1」不再是常量，而是**基线值**——由账号级的礼包持有状态改写为「无限 / 9 / 3」。凡读取重试上限的地方（`RetryChapter` 的判定、篇章解锁 / 重新锁定的判断、主菜单的剩余次数展示）都要经这一层，不能硬编码常量。
- **它踩在既定的「轻度提升、PvE-only 可容忍」边界上。** PlayerPower 的既定定位（本作无 PvP，故容忍一定强度、以换取更大的设计空间）正是 ① ② 成立的前提。
- **③ ④ 是一次经确认的、有意的口径变化（已定案）。** 「存档角色是一种会被耗尽的有限资源、构成元进程压力」是 ADR-0004 明写的后果；**付费放宽这条压力线是有意为之**，不是疏漏。因此设计上应正视其后果：**重试上限是元进程难度的主要旋钮，而它现在有两档**（免费 ∞/3/1 与付费 ∞/9/3）——平衡时须以**免费档**为「游戏应当可通关」的基准，付费档是宽松化而非必需品。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **付费的战斗价值主要由古宝承载，法则保持稀缺（已定案 · 08-04b · 承重的分工）。** 08-04b 之后，法则与古宝**都能进入战斗**（法则以 `CardType.Power` 开局入场、古宝以 `CardType.Item` 存于储物袋），故礼包的 ① ② 两项**不再只影响元进程，也影响战斗玩法层**。这条分工把风险收在两侧：
  - **古宝有使用次数限制** —— **次数天然是节流阀**，让付费的战斗收益是「关键时刻多几次转圜」而非「永久变强」。**这是付费战斗价值的主要承载者。**
  - **法则保持极其稀缺** —— `UsableScene` 含 `InCombat` 的法则应 ≤ **1/5**（加载时统计、超标 `PushWarning`），且强度定位偏**体验改善与容错**（信息、便利、少量兜底），而非直接抬高道念产出上限。见 `player-profile/player-power/`。
  - **不设规则禁令，代价由稀缺性承担** —— premium bundle 是花钱买的，理应让体验更好，而战斗是核心体验的关键一环；用内容配额而非硬编码规则表达这条边界。
  - **它同时满足「花钱体验更好」与「不滑向 pay-to-win」，不需要任何新机制。** 但**法则不可被针对且跨轮回永久持有**，其价值随账号年龄单调累积——平衡时须按「**老账号全开**」校准难度曲线，见 `systems/balance.md`。

  Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **付费获得的法则不会被游戏销毁（已定案 · 08-06b · 承重）。** 事件侧「失去法则」**永远不强制剥夺**：真正从账号移除只发生在**玩家自愿接受的置换**中（有对价，例如换成另一条法则），其余事件一律降级为**「本轮回禁用」——不从账号删除**。**推论：「花钱买到的东西可能被一个事件拿走」这条风险彻底关闭**，它免去了一整类客诉与退款争议，并让「失去法则」成为一条有梯度的压力线（本场移除 < 本轮回禁用 < 自愿置换）而非二元惩罚。**置换本身是卡组构筑式的取舍，是正向设计而非负向条目。** 见 `player-profile/player-power/`。Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
- **随机 PlayerPower 与「道统残卷」共用同一个获取面。** 后者是失败累积的 PlayerPower 掉落概率（见 `player-profile/player-power/`）；二者是否互相影响（礼包给的 power 是否重置残卷概率）未陈述。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **premium bundle = 唯一已陈述的付费点；重试上限由常量降为基线值（付费放宽为有意的口径变化）** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。ADR-0004 的重试条款已相应改写。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **购买形态。** 一次性还是可重复购买？可重复则 ③ ④ 如何叠加（9 → 更多？还是只生效一次）？定价与地区策略？
- **是否还有其他付费点。** 外观 / 通行证 / 单次续命等未陈述；「不做哪些」同样需要明确（例如是否明确排除抽卡与消耗型货币）。
- **随机的口径。** ① ② 的「随机」是从全池等概率抽，还是排除已拥有的？抽到重复如何处理？走哪条 RNG（**不应污染轮回 seed 的确定性**）？
- **与道统残卷的交互。** 礼包给的 PlayerPower 是否重置「下次轮回获得新 PlayerPower」的累积概率。→ `systems/player-profile/player-power/`。
- **持有状态的存档表达。** 礼包持有落成什么——`CapabilityFlag`？modifier pipeline 的具名修正？独立的 `Entitlement` 字段？它需要**服务端权威**（付费凭证不能只信客户端），故也是一条客户端 ↔ 后端协议契约，应同步登记进 `backend-design-documents/`。→ `systems/services/profile-service.md`、`sync-service.md`。
- **UX 呈现。** 礼包入口放在哪、是否在重试次数耗尽时提示购买（这直接决定观感是「增值」还是「付费才玩得下去」）。→ `ux/screen-flow.md`。
- **合规。** 付费与实名 / 防沉迷 / 渠道分成 / 退款的交互归后端与合规侧。→ `backend-design-documents/`。

## 对应
提炼至：`.claude/knowledge/systems/monetization.md`（待建）。
