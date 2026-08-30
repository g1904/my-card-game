# ADR-0025 — Finale 失败即角色终结；胜负判定二值化，`WinMargin` 在该档退场

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-finale-failure-is-death.md

## 背景

篇章边界的 Finale（天劫）此前有三种走向：胜、败但存活、平。「失败但存活仍完成篇章、境界照常突破」被 `combat/_index.md` 与 `game-progression.md` 双双写作承重前提，其直接后果是**渡劫的胜负不构成篇章推进的闸门**——一场终局战打输了，篇章照推。同时三处判定口径互不一致（`combat/_index.md` 只有 `Victory` / `Draw` 两分支、`combat-service.md` 写「差额未达 `WinMargin` → Draw」、`scoring.md` 写「平局 = 道念相等」），实现侧无从确定该按哪一条落码。必须先定「终局战的胜负到底是不是闸门」，其余判定细节才有归属。

## 决策

**篇章终局战的胜负即篇章推进的闸门：`d >= 0`（角色道念不落后于敌人）通过，`d < 0` 失败且角色当场终结。**

- 判定统一为一条不按档分发的式子：`d >= WinMargin → Victory`；`d == WinMargin − 1` 且 `WinMargin >= 1` → `Draw`；否则 `Defeat`。代入三档 `WinMargin`（`Practice 0` / `Standard 1` / `Finale 0`）即得各档语义；`Draw` 收为仅 `Standard` 可达。
- `DefeatReason` 含 `FinaleFailed`（全表三值）。**终态判定因此不再是纯查表**：Finale 失败不是资源触底、无对应 `CostKey`、进不了 `ResourceElements` 表，须在资源表循环之前补一条显式旁路，且该旁路只在事件结算后的判定②生效。这是表驱动被开的唯一一个口子。
- `WinMargin` 在 Finale 侧删除（初值 3 / 5 / 8 一并退场），该档**不再有专属难度旋钮**；替代校准手段（天劫赋级带位置 / 定制卡组强度 / `TurnLimit`）的取值**留待内容扩充后的统计校准**。
- 「通过但打平」的区间取最低档奖励，由既有的 `1:1` 强制奖励与 `advantage` 三档换算自动兑现，**零新增字段 / 分支 / 表**。
- 写入顺序写死：`eventEnd` 的 `TryApply` 提交成功 → 终态判定② → `DefeatCharacter`。
- `Practice` / `Standard` 两档的失败语义原样不变（只扣寿元；扣到 0 时走 `LifeSpanExhausted`）。

逐条规则与判定伪码 → `systems/adventure-event/combat/_index.md`、`systems/services/life-cycle-service.md`；难度校准手段 → `systems/balance.md`。

## 理由

- **闸门语义要与玩家的心理模型一致。** 一场被全库叙述为「篇章高潮」的战斗打输了却照样过关，使 Finale 在规则层没有分量；胜负即闸门是把已有的叙事重量兑现为规则。
- **三处判定口径的不一致只有靠二值化才能一次消掉。** 统一成一条式子后，三档差异全部落在 `WinMargin` 一个取值上，实现侧不需要按档分发。
- **`WinMargin` 删除是本库既有的死结构判据。** 胜负线固定为 0 后它在 Finale 没有消费者；`PlotModulation.Tighten` 拧它对该档零效果（对 `Standard` 仍有效，故 `Tighten` 本身不是死结构）。
- **借道任何一个资源触底原因被否决**：资源触底的原因由 `ResourceElements` 表驱动、须真有一条资源被打到 `Min`，而渡劫失败不消耗任何资源；硬把它塞进去要为该资源开一个置值通道，那是更大的口子。**独立成员同时保住可观测性**：玩家 / 客服 / 数据侧一眼分得清「大限将至」与「渡劫身死」。
- **残卷四项与首胜里程碑照常，是唯一保住后端零改动的形态**（`FinaleWinOrdinal` 同时是掷骰序号、幂等键与后端复算入参，「序号 +1 却不掷骰」会使后端校验稳定失败）。

## 备选方案

- **保留「失败但存活」的 1% 分支** — 使胜负不构成推进闸门，与终局战的叙事重量相抵；且它是三处判定口径不一致的根源。
- **`Draw` 区间判为失败** — 会把「刚好打平」也变成角色终结，而难度口径此时已足够苛（开局落后 5 / 13 / 25）。
- **借道某个资源触底原因表达渡劫失败** — 见上，需为该资源开置值通道，且失去可观测性。
- **为「最低档奖励」新造一条奖励线** — 既有两条换算规则已自动给出该档（验算：各章该区间 `advantage` 上界 0.133 / 0.125 / 0.093，整体落在 `Tier.Narrow`）；为已被满足的需求造结构会新增一个 `Tighten` 够不到的旋钮。
- **为 Finale 补一个新的难度旋钮** — 难度校准依赖内容扩充后的统计样本，此刻凭直觉选旋钮与「先定形状、后定数值」的分工相悖。

## 后果

- **难度口径显著下调**：通过所需追回的道念点数由「开局落差 + N」降为「开局落差」——ch1 8→5 · ch2 18→13 · ch3 33→25。
- **免费档账号在金丹→元婴一关一生只有 1 次容错**（重试上限维持 ∞ / 3 / 1，付费 ∞ / 9 / 3，不做补偿）。`decisions/ADR-0004-realm-checkpoint-retry-model.md` 的后果须明写这一点。
- **`decisions/ADR-0002-adventure-event-taxonomy.md`** 的保留清单不含「失败但存活仍完成篇章」；**`decisions/ADR-0016-hidden-stat-band-model.md`** 的论据须自足、不再依赖该分支。
- **`systems/game-progression.md` 的承重结论反转**为「渡劫的胜负即篇章推进闸门」。
- **实现侧不得以为终态判定「照表走就行」**；新增终态**资源**仍照 `ResourceElements` 表扩展，Finale 失败是唯一例外。
- **一条承重机制的写入顺序不可颠倒**：残卷 `PlayerPowerFragment.Accumulated` 是账号级写入，而 `DefeatCharacter` 清理角色终态数据；失败恒等于终结后，顺序写反会让「Finale 失败累积残卷」在每一次失败上静默丢失。
- **`Practice` 与 `Finale` 同取 `WinMargin 0` 是巧合**，不得提取共享常量。
- **后端零改动**（已核实：后端 Finale 相关内容只覆盖通过路径，`defeatReason` 在 `backend-design-documents/contracts/` 内零登记）。日后 `characterProfile.defeatReason` 若进入上行透明段，枚举名须与客户端逐字一致。
- 叙事侧补一条「渡劫身死」定性文案，复用被腾空的 `ResolveOutcome` → `eventEnd` 链路，结构成本为 0；边界不变且更吃紧——**绝不暗示道统残卷**。
- 遗留：**死亡 / 轮回结束屏尚无设计**，而三条终结原因需要区分呈现。见 `open-questions/06-meta-progression.md`。
