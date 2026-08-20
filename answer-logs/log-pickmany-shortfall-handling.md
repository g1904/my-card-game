# Answer log pickmany-shortfall-handling

- 日期：2026-08-19
- 来源：`inbox/solution-draft-pickmany-shortfall-handling.md` → `handoffs/2026-08-19-pickmany-shortfall-handling.md`
- 移出条数：**1**

## 移出的待答项

- **`PickMany` 抽不足 `count` 时，Research 候选与 Exchange 库存两个调用侧如何处置** → **三道闸**：加载期硬校验（Research 逐操作类池 ≥ `CandidateCount` + `ResearchPoolMargin`；Exchange 逐 `Kind` 逐 `RarityTier` 档位核算 + `ExchangePoolMargin`）· 取池期前置拦截（`≥ 1`，`AllowDecline == false` 的槽逐槽收紧，不满足则该条目本次不进候选池）· 物化期降级到实际抽到的条数（空槽 / 空规则剔除，全空为理论不可达的缺陷分支）。分界判据「玩家有没有为这一次产出付过钱」使它与 premium bundle 三道闸的相反方向可读。
  归档去向：`systems/services/future-event-service.md`（三道闸与分界判据本体）· `systems/adventure-event/research/common-properties.md` · `systems/adventure-event/exchange/common-properties.md` · `systems/adventure-event/exchange/_index.md` · `systems/services/content-service.md` · `systems/services/profile-service.md`。
  该条目原在 `open-questions/02-event-options.md`，同一句也曾登记在 `systems/services/future-event-service.md` 的待决问题里（本次已删）。

## 同批答定的连带项（原先并非独立待答条目）

- **闸 ③ 的「另取一条填补批次」** → 整条作废，该条目本次作废、本批少一项，不补位（1 项批次本就合法）。（`systems/services/future-event-service.md`）
- **Explore 壳遮罩 Exchange 真身这条路径** → 取池期壳过滤穿透到真身的库存池前置，与既有「真身须同样 enabled」同形同档。（`systems/adventure-event/explore/_index.md`）
- **reroll 后库存可能归零而玩家已付费** → 前置校验 + 按钮置灰 + 一行说明（`EVENT_REROLL_UNAVAILABLE_POOL`，走普通分区）。这松动了草稿裁决「零 UI 改动、零文案键」的字面口径——那一项管的是「短缺时不给提示」，刷新按钮不可用是另一个界面元素。（`systems/adventure-event/exchange/_index.md`、`ux/error-and-blocking-ux.md`）
- **闸 ② 的计数口径与实际抽取链不一致** → `GrantableCount` 加可选 `rarityFilter` 参数；草稿「零新增接口」的声称随之作废。（`systems/services/profile-service.md`）
- **闸 ① 的 Exchange 聚合口径** → 逐 `RarityTier` 档位核算，取代「同 `Kind` + 同 `RarityFilter` 完全相同才合并」。（`systems/adventure-event/exchange/common-properties.md`）
- **闸 ② 过滤后批次不足 / 池空** → 不新增分支，落既有三条（1 项批次合法 · Travel 兜底恒可产出 · 池空即坏数据）。（`systems/services/future-event-service.md`）
- **开局强制构筑事件可以缺席，首批退化为常规批** → 是一次大声失败的运营事故，不设补发或降级路径。（`systems/adventure-event/research/_index.md`）
- **三道闸分界判据写在哪** → 本体落 `future-event-service.md`，`monetization.md` 三道闸小节只补一句回链。

## 仍留在待答清单的相邻项

- `ResearchPoolMargin` / `ExchangePoolMargin` 的取值（归 ch1 数值标杆专场，见 `systems/balance.md` 的待决问题）。
- 多操作槽内 `CandidateCount` 在 `AllowedOperations` 各类之间如何分配（本次方案不依赖它）。
- eventOptions 的上游生成 / 加权合并算法（与「类型配比」有交互面，合并算法本身不在本次范围内）。
