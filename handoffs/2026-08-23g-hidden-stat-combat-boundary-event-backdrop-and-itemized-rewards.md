# 隐藏属性与战斗层的边界 · 事件背景板分期 · 战后奖励逐项领取

- id: 2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards
- date: 2026-08-23
- topic: systems/services/plot-manager · systems/adventure-event/combat · systems/scoring · art/visuals · systems/services/combat-service · ux/combat-ux · systems/services/life-cycle-service
- status: distilled
- distilled-to: `systems/services/plot-manager.md`、`systems/adventure-event/combat/_index.md`、`systems/scoring.md`、`art/visuals/_index.md`、`systems/services/combat-service.md`、`ux/combat-ux.md`、`systems/services/life-cycle-service.md`、`systems/character-profile/_index.md`、`systems/adventure-event/explore/_index.md`

## Intent（distilled）

三条彼此独立的定案，合并成稿只为归档整洁。

### 1. 隐藏属性不是战斗内的资源，战斗层不读写它

**权威表述：隐藏属性（道心 / 煞气 / 寿元）不作为战斗内的资源或结算输入，战斗层不读写它；隐藏属性与战斗的全部交互发生在事件层。**

这条边界**不否定**三条既有通道——它们都在事件层，一条不动：

| 既有通道 | 发生在 |
|---|---|
| PlotManager 依隐藏属性调制 eventOptions 的参数（Band 触发 arc → `PlotModulation` 六字段） | 事件生成期 |
| 事件的数据驱动 outcome 求值读取隐藏属性当前值作为输入项之一 | 事件结算期 |
| `eventEnd` 对 `HiddenStatGrade` 的推拉 | 事件收口 |

**两处与战斗层相邻但不构成反例：**
- **`lifeSpanCost`（寿元的成本侧）** —— 它在「择一进入」时施加，是事件成本，不是战斗内的读写；Combat 事件同样扣，但扣发生在进入战斗之前。
- **失败时按道念差扣 `lifeTotal`** —— 它写的是战斗外耐久 `lifeTotal`，不是隐藏属性，且施加时点在 `eventEnd` 收口。

原始措辞「隐藏属性与战斗资源无直接耦合 / 不设直接读写通道」按字面会连上表三条既有通道一并否掉，故收窄为上述表述。

**权威落点是 `systems/services/plot-manager.md`，不是 `systems/scoring.md`。** 后者全文零处提及隐藏属性，写进去等于造第二权威；它只在「归属与协作」表加一行回链。

### 2. 事件背景板按地域区分，后期再按事件类型细化

地点不同，事件的背景板不同。**前期**同一地域的所有事件共用同一张背景板；**后期**再考虑按事件类型（Combat / Exchange / Research / Explore / Travel）定制。

**与既有「事件插图」类目并存，不替代。** 两者资产量级差一个数量级：背景板前期每地域一张，事件插图是逐条目、数量最大的类目。合为一行会让排期失真，故 `art/visuals/` 的资产类目表新增独立一行「事件背景板」，「事件插图」行保留并注明前期不产出。

### 3. 战后 / 事件奖励面板：逐项列出、逐项领取 / 跳过

奖励面板的交互参照 **Slay the Spire**：候选**逐项列出**，玩家**逐项领取或跳过**，不再是从候选中择一。

**被推翻的三条既有定案：**
- 「不设『放弃全部候选』通道」—— 逐项跳过天然包含「一项都不领」，该通道存在且合法。
- 「固定 3 项候选」的**择一**语义 —— 三项各自独立可领可跳；数量仍为 3。
- 「战后奖励选择不是决策点」—— 它现在是决策点。

**为什么「是决策点」与「reroll 已被封死」并不矛盾（承重）：** 封死 reroll 的机制是**候选预先算定并落存档**——`picks` 在胜负判定后一次抽定，退出重进读到的是同一组候选，这条一字不变。新出现的是**领取进度**这段中途状态（已领哪几项、还剩哪几项），它由玩家输入产生、重算不出来，故必须落存档，而「状态机停下来等玩家输入且随机已反映在持久化 `State` 里」正是决策点的判据。

**连带定义：**
- **存档结构** —— `activeCombat` 新增一段奖励状态，承载已算定的候选与逐项的领取 / 跳过进度。
- **决策点清单** —— 战斗内清单由 D0–D6 扩为 **D0–D7**：新增 `D6 = 一次领取 / 跳过`，原「战斗收口」顺延为 `D7`。
- **既有理由的存废** —— 「奖励数量恒定使 UI 布局稳定」这条理由随逐项领取失效（列表长度本就随领取变化），删除；「道念差的价值全部落在候选质量而非数量上」仍成立，是固定 3 项的现行理由。
- **`±2` 带封住碾压深度**这条推论不受影响。
- **置换 / 禁用面板不必改动** —— 它本就是逐槽「接受 / 拒绝」，与逐项领取 / 跳过同构，「形状与战后奖励面板完全同构」这条定案在新形态下更成立，不是更不成立。

## Clarifications（interview 产物）

- **奖励面板是否按 StS 引入逐项领取 / 跳过** → 按草稿引入，明确推翻 `combat-service.md` 三处与 `ux/combat-ux.md` 一处（用户 08-25 批量 interview 裁决）。
- 标准默认（未出题，直接采纳）：
  - 第 1 条措辞由「无直接耦合」收窄为「战斗层不读写隐藏属性，交互全在事件层」，并明写两处相邻情形不构成反例 —— 依据：原措辞按字面否掉三条既有通道，与 `plot-manager.md`「输入侧全开」直接相抵。
  - 第 1 条权威落 `plot-manager.md` 而非 `scoring.md` —— 依据：`scoring.md` 零处提及隐藏属性，权威句写在无相关内容的文档里会制造第二权威。
  - 事件背景板新增独立类目行、事件插图行保留并注明前期不产出 —— 依据：两者资产量级差一个数量级，合并会让排期失真。
  - 决策点新增点编号为 `D6`、原收口顺延 `D7`，六处 `D0–D6` 引用同步改写 —— 依据：清单以时序排列，插在收口之前是唯一自洽的位置。
  - 置换 / 禁用面板不随之改动 —— 依据：它本就是逐槽接受 / 拒绝，与新形态同构。

## Open questions

- **三项皆可领之后，候选厚度与 `RewardPoolId` 取值需重估。** 择一改为逐项领取使单场奖励的期望价值上移，`Tier` 三档的质量落差与 `BaseReward` 的相对分量随之改变。归内容扩充后的统计校准。→ `systems/balance.md`。
- **奖励面板的呈现形态仍未定** —— 强制项与可选项如何同屏区分、逐项领取的竖屏排布、已领项的视觉处置、能否反悔。→ `ux/combat-ux.md`，待战斗 UX 专场。
