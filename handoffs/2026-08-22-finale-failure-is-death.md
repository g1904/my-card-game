# Finale 失败即角色终结 · 判定二值化

- id: 2026-08-22-finale-failure-is-death
- date: 2026-08-22
- topic: systems/adventure-event/combat · systems/game-progression · systems/balance · systems/services/life-cycle-service · systems/services/plot-manager · systems/services/combat-service · systems/architecture · systems/character-profile · systems/player-profile · terminology · program-overview · system-overview · ux · decisions/ADR-0002 · ADR-0004 · ADR-0016
- status: distilled
- distilled-to: systems/adventure-event/combat/_index.md, systems/game-progression.md, systems/balance.md, systems/scoring.md, systems/architecture.md, systems/common-properties.md, systems/monetization.md, systems/services/life-cycle-service.md, systems/services/combat-service.md, systems/services/future-event-service.md, systems/services/plot-manager.md, systems/services/content-service.md, systems/services/profile-service.md, systems/character-profile/_index.md, systems/character-profile/life-total.md, systems/player-profile/_index.md, systems/player-profile/player-power/_index.md, terminology.md, program-overview.md, system-overview.md, ux/_index.md, ux/screen-flow.md, decisions/ADR-0002-adventure-event-taxonomy.md, decisions/ADR-0004-realm-checkpoint-retry-model.md, decisions/ADR-0016-hidden-stat-band-model.md

## Intent (distilled)

**一句话：** 篇章终局战（Finale / 天劫）的胜负就是篇章推进的闸门——**通过则突破，失败则角色当场终结**；判定二值化为「不落后即通过」，`WinMargin` 在该档退场。

### 1. 判定：二值化，胜负线落在 0

`d = 角色道念 − 敌人道念`。

| 条件 | 结果 |
|---|---|
| `d >= 0` | **通过**：角色存活 · 境界突破 · 等级归位新境界初期 · 篇章推进 · 落篇章边界存档点 |
| `d < 0` | **失败**：角色当场终结（`defeated`）· 本篇章不推进 |

- 中间态被取消：原先「达不到门槛却也没输」的那段区间**归入通过侧**，只是奖励取最低档。
- 三档的判定统一写成一条式子，**不按档分发**：`d >= WinMargin → Victory`；`d == WinMargin − 1` 且 `WinMargin >= 1` → `Draw`；否则 → `Defeat`。
  代入 `Practice 0 / Standard 1 / Finale 0` 即得三档各自的语义；`WinMargin == 0` 的两档因此**二值化**，`Draw` 收为**仅 `Standard` 一档可达**。
- `Practice` 与 `Finale` 同取 `0` 是**巧合**（一个是「点到为止」，一个是「非胜即败」），不是共性——不得提取共享常量。
- **`Practice` / `Standard` 两档的失败语义原样不变**：只扣 `lifeTotal`，经 `LifeTotalExhausted` 通道。本次收窄到 Finale 一档。

### 2. 终结通道：`DefeatReason` 四值 + 一条显式旁路

- `DefeatReason` 新增 **`FinaleFailed`**（枚举四值，按既定纪律只增不删、code 不复用）。
- **终态判定的形状因此改变（本次唯一的结构性新增，必须明写）：** 原判定是**纯查表驱动**（遍历 `ResourceElements` 中 `DepletionDefeat` 非空的行）；Finale 失败**不是资源触底**、没有对应 `CostKey`、塞不进该表 ⇒ 必须在查表之外补一条**显式旁路**。
  判定形状 = `if finaleFailed → DefeatCharacter(FinaleFailed)`，其后才是既有的资源表循环。
  旁路只在**判定②**（事件结算后）生效；判定①（支付 `selectCost` 之后）尚无战斗结果，入参恒 `false`。
- **实现侧不能以为「照表走就行」**——这是表驱动被开的第一个也是唯一一个口子；新增终态**资源**仍照表扩展。

### 3. 奖励最低档：由既有换算自动兑现，零新增结构

「通过但差点没够到」的那段区间拿最低档奖励，**不需要新字段 / 新分支 / 新表**：

- **强制奖励**走线性 `1:1`：`d = 0` 时加成恰为 0。
- **可选奖励**走归一化 `advantage` 三档：代入各章 `baseMomentum`，低区间整体落在**险胜 `Tier.Narrow`**。
- **已知代价（接受）：** `Tier.Narrow` 不为该区间独占——「刚好打平」与「小幅领先」拿同一档可选奖励，只在强制奖励的线性量上有差。

### 4. `WinMargin` 在 Finale 侧退场，且该档不再有专属难度旋钮

- 胜负线固定为 0 后，Finale 的 `WinMargin` 是**没有消费者的死结构**，按本库既有判据删除（初值 3 / 5 / 8 一并退场）。
- 连带：`PlotModulation.Tighten` 拧 `VictoryRule` 对 Finale **零效果**（对 `Standard` 仍有效，故 `Tighten` 本身不是死结构）；剧本 / 隐藏属性给 Finale 加压只剩敌人侧两个字段（`EnemyPoolScope` / `LevelBias`）。
- **Finale 的压迫从三重降为二重**：(a) 开局落后 5 / 13 / 25（`baseMomentum` 表的必然结果，不是旋钮）· (b) 失败即终结（二值，不可调）。
- **明写「Finale 的难度不再有专属旋钮」**，并给出三条替代校准手段（天劫赋级带位置 / 天劫定制卡组强度 / `TurnLimit`），全部归 ch1 数值标杆专场。不写这句，日后会有人去找一个不存在的旋钮。

### 5. 难度口径的净效果：显著下调

通过所需追回的道念点数从「开局落差 + N」降为「开局落差」：ch1 8→5 · ch2 18→13 · ch3 33→25。与「平衡基准是免费档、免费档应当可通关」同向加强。

### 6. 残卷与里程碑：全部照常，后端零改动

- **失败侧**：`PlayerPowerFragment.Accumulated` 照常累加。
  **⚠ 写入顺序纪律（本次最危险的隐性后果）：** 累加是**账号级**写入，而 `DefeatCharacter` 走角色终态数据清理；顺序必须是 **`eventEnd` 的那一次 `TryApply` 提交成功 → 终态判定② → `DefeatCharacter`**。
  颠倒 ⇒ 「Finale 失败累积残卷」这条承重机制在**每一次**失败上都丢，而失败恒等于终结 ⇒ **100% 失效且静默**。
- **通过侧**：掷骰 · 发放 · `FinaleWinOrdinal` +1 · `LastRoll` / `LastEffectiveChance` 照写，**四项不可拆**（`FinaleWinOrdinal` 同时是掷骰序号、幂等键与后端复算入参；「序号 +1 却不掷骰」会使后端校验稳定失败）。`Ch*FirstWinDone` 照常置位、首胜 100% 照常。
- **这是唯一能保住后端零改动的形态。** 代价明写：玩家可能用一次刚好打平的通过，兑掉该篇章一生一次的首胜里程碑。
- 那笔按道念差 1:1 扣的 `lifeTotal` **照常扣**（合进 `eventEnd` 那一次 `TryApply`），只是不再是死亡判据。

### 7. 重试压力：维持 ∞ / 3 / 1，不补偿

一次 Finale 失败恰好消耗一次篇章重试 ⇒ **免费档账号在金丹→元婴这一关一生只有 1 次容错**。这条压力有意保留，缓解全在难度侧（判定线已下移）与付费档（∞ / 9 / 3）。

### 8. 叙事：一条「渡劫身死」定性文案

复用被腾空的那条链路（`ResolveOutcome` → `eventEnd`、内容层 `LocalizedText`、启动期校验、overlay 只改不增），**结构成本为 0**。一条文案、不做随机二选一。边界不变且更吃紧：**绝不暗示道统残卷**——失败恰是累积发生的那一刻。
库中四处「内容层举例」保留 Finale 这个例子，改指新文案。

## Clarifications

interview 裁决逐条（每条注明它推翻 / 细化了既有设计的哪一句）：

- **Finale 失败后是否还能存活？** → **不能，失败必死、篇章立即结束。**
  推翻 `combat/_index.md` 的「Finale 失败不直接 `defeated`（承重）」与「失败但存活（约 1%）⇒ 篇章照常完成、境界照常突破（承重）」，以及 `game-progression.md` 的「篇章收口 = 一次性的 Finale，胜负不是推进闸门（承重）」。
- **`DefeatReason` 怎么表达它？** → **新增 `FinaleFailed` + 显式旁路。**
  推翻 `combat/_index.md`「**不设** `DefeatReason.FinaleFailed`」与 `architecture.md` 枚举旁那条行内注释；细化 `life-cycle-service.md` 的终态判定伪码——它此前是纯查表。
  否决「借道 `LifeTotalExhausted`」：`LifeTotal` 无置值通道（`profile-service.md` 明写），开一个 `Set` 是更大的口子，且玩家 / 客服 / 数据侧永远分不清「打穿死」与「渡劫死」。
- **`Draw` 区间（够不到门槛但不落后）算胜还是败？** → **归入胜利侧，奖励取最低档。**
  这条**改变了 `WinMargin` 的性质**：它不再是胜负门槛。三处此前互不一致的判定口径（`combat/_index.md` 只写 `Victory` / `Draw` 无 `Defeat` 分支 · `combat-service.md`「差额未达 `WinMargin` → Draw」· `scoring.md`「平局 = 道念相等」）**本次统一**为一条式子。
- **「最低档」要不要新造一条奖励线？** → **不要。** 既有的两条换算规则已自动给出最低档（验算：各章该区间 `advantage` 上界 0.133 / 0.125 / 0.093，整体落在 `Tier.Narrow`）。为已被满足的需求造结构会新增一个字段与一条 `Tighten` 够不到的旋钮。
- **`WinMargin` 在 Finale 怎么处置？** → **删掉。** 推翻 `balance.md` / `ADR-0002` / `combat/_index.md` 三处的「`N` = ch1 3 / ch2 5 / ch3 8」与两处逐字重复的「`WinMargin` 是双向的第一旋钮」。
- **Finale 失去唯一难度旋钮，补不补？** → **不补新旋钮，如实写下这个事实并指向替代手段。** 数值校准归 ch1 标杆专场，此刻凭直觉选旋钮与该分工相悖；但删掉「第一旋钮」那句后必须留一条指引，否则该位置是空白。
- **残卷四项与首胜里程碑照不照常？** → **全部照常。** 唯一保住后端零改动的选项；四项不可拆的理由与代价均已写入 `life-cycle-service.md` 与 `player-power/_index.md`。
- **ch3 重试上限 1 要不要放宽？** → **维持 ∞ / 3 / 1（付费 ∞ / 9 / 3），不做任何补偿**，但 `ADR-0004` 的 Consequences 须明写免费档在终局的容错次数。
  （该裁决作出时判定线尚未下移；下移后压力反而低于裁决时的语境，理由更强，无需复核。）
- **失败时那笔 1:1 扣的 `lifeTotal` 还扣不扣？** → **照常扣**，只是不再是死亡判据。跳过它需要在合并逻辑里加一个 tier 分支——为省一次无害的加法引入条件分支。
- **要不要为「渡劫身死」补新叙事？** → **补一条**，复用被腾空的链路。四处「内容层举例」保留 Finale 这个例子、改指新文案。
- **`ux/screen-flow.md` 那条呈现纪律怎么改？** → **保留主结论**（渡劫成功次数 ≠ 总通关数），删掉已作废的第二条论据（1% 分支导致成功数 < 完成篇章数）——两数现在恒等。同一事实在 `player-profile/_index.md` 的第二处复述一并改写，`TotalChaptersCompleted` 的「不设」理由随之从「几近恒等」升为「恒等」。

## Open questions

- **死亡 / 轮回结束屏尚无设计。** 全库只有一句「lifeTotal 归 0 即角色终结」，没有任何结算屏形态。四条终结原因现在需要区分呈现（「寿元耗尽」/「耐久归零」/「主动弃置」/「渡劫身死」），而「渡劫身死」文案的载体已定、**呈现它的那一屏仍未定**。这是既有空白，本次裁决让它更急。
- **Finale 难度的实测校准**（天劫赋级带位置 / 定制卡组强度 / `TurnLimit` 三选）归 ch1 数值标杆专场，本次只定形态不定值。

## Notes / triage

- 本次输入是 interview 中的新裁决，不来自 `inbox/` 草稿，无草稿可归档。
- **后端设计库零写入**（已核实）：后端全部 Finale 相关内容只覆盖通过路径，`defeatReason` 在后端契约面内零登记。**若日后 `characterProfile` 的 `defeatReason` 进入上行透明段，枚举名须与客户端逐字一致。**
- 连带作废：`inbox/solution-draft-priority-elevation-conditions.md` 把「下调 `WinMargin`」列为 Finale 抬升的退让位——**该退让位本身不再成立**，须整条改写（由 priority-elevation 分片执行）。
