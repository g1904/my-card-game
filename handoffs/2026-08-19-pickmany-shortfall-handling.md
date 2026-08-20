# `PickMany` 抽不足 `count` 的调用侧处置：Research 候选与 Exchange 库存的三道闸

- id: 2026-08-19-pickmany-shortfall-handling
- date: 2026-08-19
- topic: systems/adventure-event/research/common-properties.md · systems/adventure-event/research/_index.md · systems/adventure-event/exchange/common-properties.md · systems/adventure-event/exchange/_index.md · systems/adventure-event/explore/_index.md · systems/services/future-event-service.md · systems/services/content-service.md · systems/services/profile-service.md · systems/balance.md · systems/monetization.md · ux/error-and-blocking-ux.md
- status: distilled
- distilled-to: systems/adventure-event/research/common-properties.md, systems/adventure-event/research/_index.md, systems/adventure-event/exchange/common-properties.md, systems/adventure-event/exchange/_index.md, systems/adventure-event/explore/_index.md, systems/services/future-event-service.md, systems/services/content-service.md, systems/services/profile-service.md, systems/balance.md, systems/monetization.md, ux/error-and-blocking-ux.md

## Intent（distilled）

抽取原语一侧的契约只回答了「原语不假装成功」（`PickMany` 短缺时返回 `false` + `PushWarning`，不静默少给），没有回答**调用侧拿到 `false` 之后干什么**。两个调用点各欠一个处置：Research 构筑面板的候选（`CandidateCount` 条，其中 `LearnTechnique` / `GrantItem` 两类走内容池）与 Exchange 的库存（每条 `ExchangeStockRule` 抽 `SlotCount` 条 offer）。硬约束是**两处都不能留空面板**——一个零候选的构筑槽 / 一个零商品的商店，是玩家付了 `lifeSpanCost` 之后撞上的空屏，而 Research 是轮回内构筑的唯一落点。

本次照 premium bundle 的空池三道闸体例逐闸重填，并写下**为什么本处的失败处置与礼包相反**。

### 一、原语侧的契约细化：短缺时把已抽出的那几条交出来

```csharp
bool PickMany<TRng>(TRng rng, int count, out IReadOnlyList<T> picked);
//   池 ≥ count      → true，picked.Count == count
//   0 < 池 < count  → false + PushWarning，picked = 池中全部（无放回、已加权）
//   池 == 0         → false + PushWarning，picked = 空列表（永不为 null）
```

`TryPickGrantableMany` 同款语义，`out IReadOnlyList<string> pickedIds`。「不静默少给」防的是**原语假装成功**，`false` + 告警已完整兑现；丢弃已抽出的结果只会逼调用侧走「先数一次池、再用较小的 `count` 抽第二次」，同一条取池链在同一次物化里跑两遍，且两次之间消耗的 RNG 次数依赖于池大小。

### 二、三道闸与分界判据

| 闸 | 时机 | Research | Exchange | 失败处置 |
|---|---|---|---|---|
| ① | 内容加载期（合并后强校验） | 每个 `ResearchSlotSpec` 的每类内容池型操作：通用池条目数 ≥ `CandidateCount` + `ResearchPoolMargin` | 逐 `Kind` 逐 `RarityTier` 档位核算：覆盖该档位的全部规则 Σ`SlotCount` + `ExchangePoolMargin` ≤ 该档位的池条目数 | `PushError` + 定位上下文 |
| ② | 取池期（挑候选事件条目、物化之前） | 至少一个槽能产出 ≥ 1 条候选；`AllowDecline == false` 的槽逐槽 ≥ 1 | 全部 `StockRule` 可产出 offer 数之和 ≥ 1 | 该条目本次不进候选池 + `PushWarning`，不落快照 |
| ③ | 物化期（`PickMany` 返回 `false`） | 该槽候选降级为实际抽到的条数；降到 0 → 该槽不进 `ResearchSlot[]` | 该规则少产出几个 offer；降到 0 → 少一批槽位 | `PushWarning` + want / got |

> **分界判据：玩家有没有为这一次产出付过钱。** 付过钱（premium bundle）→ 少给即事故，失败点前移到掏钱之前，宁可拒绝进入流程；没付钱、是玩法内容（Research 候选 / Exchange 库存）→ 降级到更少是可接受的方差，硬拒绝反而制造更严重的后果。

### 三、闸 ② 穿透进 Explore 壳过滤

Exchange 可作 Explore 的真身。壳的取池期过滤原先只判真身的 `ContentEnabled`，于是一个遮罩了 Exchange 真身的壳，在真身库存池收缩到 0 时照常进候选池：玩家付掉壳的 `lifeSpanCost` → 揭示 → 撞上空商店。故过滤扩写为「真身 `ContentEnabled == false` **或** 真身是 Exchange 且闸 ② 不通过 ⇒ 该壳本次不进候选池」，与既有那条同形同档。

### 四、reroll 的前置校验

闸 ② 只在取池期判一次，而 reroll 是结算期动作；能力族取池链含「排除已持有」⇒ 玩家在店内买走几件之后池即收缩，重掷结果可以比初始更少乃至为 0。故 reroll 走与礼包购买入口同形的前置校验：可产出 offer 数 < 1 ⇒ **刷新按钮置灰 + 一行说明**，不进入付费路径。

### 五、闸 ② 之后的退化情形不新增分支

批次规模可缩到 1 项（1 项批次本就合法）· Travel 兜底恒可产出 ⇒ 轮回死锁在规则层不成立 · 过滤后候选池为空落既有的「内容池为空 = 坏数据 → `PushError` + 抛」。

### 六、开局构筑事件可以缺席

`eventPriority = 1` 的开局强制构筑事件若被闸 ② 拦下，首批退化为常规批、轮回照常开始。它是一次大声失败的运营事故，不新增任何降级路径或补发机制。

### 七、落存档：记实际结果

`EventOption.ExchangeStock` / `ResearchSlot.Candidates` 的长度就是实际抽到的数量，不新增「期望数量 / 短缺标记」字段、不 bump schema、无迁移。恢复即读结果 ⇒ 一个因池收缩而少给的商店 / 面板，在退出重进后仍然少给，这正是防重掷纪律要的行为。

### 八、平衡数值

新设 `ResearchPoolMargin` / `ExchangePoolMargin` 两格，与 `GrantPoolMargin` 同表不同值（三处用途量级差异明显，焊在同一个数上则调其一必动其二）。取值归 ch1 数值标杆专场。

## Clarifications（interview 产物）

- **闸 ③「全部槽 / 全部 offer 皆空 ⇒ 由 future-event-service 另取一条填补批次」怎么办？** → **整条作废**，该条目本次作废、本批少一项，不补位。它推翻了草稿 §2 闸 ③ 失败处置列的原句——那句直接撞 `future-event-service` 的「不设单项补位，没有 `TryRefill` 一类的方法」，而 1 项批次本就合法，少一项不需要额外规则允许它。
- **Explore 壳这条路径要不要覆盖？** → **闸 ② 穿透到真身**。草稿全文未提 Explore，是一处真空；不覆盖即留一个能上线、线上不可见的洞，其形状与 `ContentEnabled` 那条过滤的既有论证完全相同。
- **reroll 后库存可能归零，而玩家已付过刷新费？** → **前置校验 + 按钮置灰**（付费前拦截）。这**松动了草稿裁决第 3 项「零 UI 改动、零文案键」**：那一项说的是「短缺时不给提示」，而刷新按钮不可用是另一个界面元素；说明文案走 `EVENT_` 普通分区，不占 `ERR_`。
- **闸 ② 对 Exchange 能力族的计数，既有 `GrantableCount` 给不出「按 `RarityFilter` 过滤后」的数？** → **给 `GrantableCount` 加一个可选 `rarityFilter` 参数**。草稿 §2「闸 ② 需要的计数能力全部现成、零新增接口」这句随之改写——闸的判据必须与实际抽取链同口径，这是闸 ② 能声称「闸 ③ 的空分支理论不可达」的全部依据。
- **闸 ① 的 Exchange 聚合口径按「同 `Kind` + 同 `RarityFilter`」合并够不够？** → **改为逐 `RarityTier` 档位核算**。两条 `RarityFilter` 分别为 `[T1,T2]` 与 `[T2,T3]` 的规则同样抢同一批 T2 条目，按草稿原句会各自单独判、放过一个真实的短缺编排。
- **闸 ② 过滤后批次不足 / 候选池为空怎么办（草稿未交代）？** → **不新增任何分支**，写一句推论落在三条既有定案上（1 项批次合法 · Travel 恒可产出 · 池空即坏数据）。
- **三道闸「分界判据」的本体写在哪？** → **本体写 `future-event-service.md` 的闸 ②/③ 小节，`monetization.md` 三道闸小节补一句回链**（单一权威、双向可见）。草稿建议的「两处都写下」与「回链而非复述」有张力。
- **「开局构筑事件可以缺席」写在哪？** → **写进 `research/_index.md` 的开局构筑事件小节**（那里的开局底盘描述读起来像结构性必然），`future-event-service.md` 闸 ② 段回链。

## 已按草稿裁决落笔的五项

`PickMany` / `TryPickGrantableMany` 增 `out picked`（可为空列表、永不为 `null`）· 两格独立余量参数 · 短缺完全不给玩家提示 · 闸 ② 对 `AllowDecline == false` 的槽逐槽收紧为 ≥ 1 · 闸 ② 阈值取 `≥ 1`。连带答定「开局强制构筑事件缺席时开局流程仍成立」。前置依赖「满袋能否购买道具」已答定为购买前置校验拦截而非库存侧过滤 ⇒ 闸 ①② 的池计数口径不含满袋过滤，余量取值无需上调。

## Open questions

- `ResearchPoolMargin` / `ExchangePoolMargin` 的取值（归 ch1 数值标杆专场；形态已定，取值不阻塞落地，可先填 0）。
- 多操作槽内 `CandidateCount` 如何在 `AllowedOperations` 各类之间分配（本次的闸 ① 逐操作类保守核算与闸 ③ 的合并降级都不依赖它，方案自洽；但它是一条真实的待答项）。
- eventOptions 的上游生成 / 加权合并算法——闸 ② 会移出个别条目、轻微改变类型分布，与「类型配比」待答项有交互面，合并算法本身不在本次范围内。
