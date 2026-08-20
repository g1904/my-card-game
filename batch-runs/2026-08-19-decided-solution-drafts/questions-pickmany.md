# Phase A — pickmany

- 分片：`pickmany`
- 输入：`game-design-documents/inbox/solution-draft-pickmany-shortfall-handling.md`（`status: decided`）
- 目标库：`game-design-documents/`（草稿 `targets:` 全部是客户端主题文档；后端零改动）
- 结论：**存在 4 项 🔴 + 4 项 🟠，Phase B 落笔前必须经合并 interview 裁决**

## 一句话摘要

`PickMany` 抽不足 `count` 时，Research 候选与 Exchange 库存两个调用侧按**三道闸**（加载期硬校验 / 取池期 ≥1 前置拦截 / 物化期降级到更少）处置，方向与 premium bundle 三道闸**相反**（没付钱 ⇒ 降级可接受），存档 schema 零改动、UI 零改动。

## 已定案项（用户已裁决，不进 interview）

草稿 `## 用户裁决（2026-08-19 · 全部定案）` 五项取向全部取 A，**按定案落笔**：

| # | 定案 |
|---|---|
| 1 | `PickMany` / `TryPickGrantableMany` 增 `out IReadOnlyList<T> picked`：短缺返回 `false` + `PushWarning`，`picked` 带回池中全部已抽出条目；**可为空列表，永不为 `null`** |
| 2 | 新设 `ResearchPoolMargin` / `ExchangePoolMargin` 两格平衡数值，与 `GrantPoolMargin` **同表不同值**；取值归 ch1 数值标杆专场（可先填 0） |
| 3 | 短缺**完全不给玩家提示**：零 UI 改动、零文案键 |
| 4 | 闸 ② 对 `AllowDecline == false` 的槽逐槽收紧为「必须 ≥ 1 条候选」，不满足 → `PushError` + 上报、该条目不进批次 |
| 5 | 闸 ② 的阈值取 `≥ 1`（只兑现「不留空面板」），其余交给闸 ③ 降级 |

连带定案（同样不进 interview）：

- **开局强制构筑事件因池见底而缺席时，开局流程仍然成立**——首批退化为常规批，轮回照常开始；它是一次大声失败的运营事故，**不新增任何降级路径或补发机制**。
- **满袋前置依赖已解除**：满袋定为**购买前置校验拦截**而非库存侧过滤 ⇒ 闸 ①② 的池计数口径**不含满袋过滤**，余量取值无需上调。
- 三道闸的**分界判据**（玩家有没有为这一次产出付过钱）写下来这件事本身已定；**写在哪一份文档**见 🟠-3。

## 🔴 冲突

### 🔴-1 闸 ③ 的「另取一条填补批次」直接推翻 future-event-service 的「不设单项补位」

- 草稿 §2 闸 ③ 失败处置列：「全部槽 / 全部 offer 皆空 …… 该条目本次作废、**由 future-event-service 另取一条填补批次**」
  ✗ `systems/services/future-event-service.md`：「**不设单项补位。** 本服务的 API 面是**四个**方法，没有 `TryRefill` 一类的单项补位方法——一旦有它，就要跟着回答「补位落空怎么办」「不生成付不起的事件」「不生成整批不可选的批次」一整串问题，而整批重算让这些问题不存在。」
- 选项
  - **(a) 该条目作废、本批少一项，不补位。** 后果：批次规模区间 1–5 天然容得下少一项；零新增方法；与「批次刷新只有一种形态：整批重算」一致。
  - (b) 该条目**照常留在批中**，只 `PushError` + 上报。后果：玩家可能选中一个空面板条目——直接违反本方案的硬约束「两处都不能留空面板」。
  - (c) 触发一次整批重算。后果：重算输入未变（同一 profile、同一 `State`）⇒ 大概率复现同一批，且要回答「重算几次算够」，等价于新开补位机制。
- **推荐：(a)** —— 唯一不新增方法、不违反硬约束的一支；`EventOptionBatch` 明写「1 项的批次合法」，少一项不需要额外规则允许它。

### 🔴-2 Exchange 可作 Explore 真身，闸 ② 未覆盖 Explore 壳这条路径

- 草稿全文未提 Explore。而 `systems/adventure-event/explore/_index.md`：「**可被遮罩的真身取值域 = Combat / Travel / Exchange**」，且 Explore 壳的取池期过滤当前**只判真身的 `ContentEnabled`**。
  ⇒ 一个遮罩了 Exchange 真身的 Explore 壳，在真身库存池收缩到 0 时**照常进候选池**：玩家付掉 Explore 壳的 `lifeSpanCost` → 揭示 → 撞上空商店。
  这正是本方案自己引用并否决的那条失败时机（`systems/monetization.md`：「让玩家在**付款之后**才撞上失败，是最糟的失败时机」），也直接违反硬约束「两处都不能留空面板」。
  （Research 不受影响——`explore/_index.md` 明写真身**不含 Research**。）
- 选项
  - **(a) 把闸 ② 的判定穿透到真身：** Explore 壳的取池期过滤扩写为「真身 `ContentEnabled == false` **或** 真身是 Exchange 且其闸 ② 不通过 ⇒ 该壳本次不进候选池」。落点 `explore/_index.md`「取池与校验」+ `future-event-service.md`。后果：改动面 +1 份文档；壳的过滤成本从「查一个布尔」升为「跑一次池计数」（仍不在热路径）。
  - (b) 闸 ② 只判直接出现的 Exchange 条目，Explore 壳不穿透。后果：留一个**能上线、线上不可见**的洞——形状与 `explore/_index.md` 为 `ContentEnabled` 那条过滤写下的论证**完全相同**，那条论证在此处一字不改地成立。
  - (c) 揭示时才判，空则改判为其他真身。后果：推翻「遮罩的是一个**固定的** AdventureEvent」这条承重定案。
- **推荐：(a)** —— 它是既有 Explore 壳过滤的第二个实例，同形同档；(b) 的代价已被库内既有论证明确否决。
- 连带（需在写入时一并记）：Explore 壳被移出候选池会轻微改变真身类型分布（初值 `Combat : Exchange : Travel ≈ 5 : 3 : 2`）——按 `explore/_index.md`「口径是条目池加权后的期望占比，不做配额保证」，**不为此新增补偿**，但值得在该处写一句。

### 🔴-3 Exchange 刷新（reroll）后库存可能归零，且玩家已经付过刷新费

- 闸 ② 只在**取池期**判一次；reroll 是**结算期**动作（`exchange/_index.md`「刷新（reroll）」：花 jade 重掷整批库存，走同一条取池链）。
  能力族取池链含「排除已持有」⇒ **玩家在店内买走几件 `CharacterItem` 后池即收缩**，reroll 重掷的结果可以比初始更少、乃至为 0。
  草稿 §4 只写了「不因库存少而下调刷新价 / 不免除刷新费」，未处理**刷新后为空**：玩家付了刷新费换来一个空店 —— 同时撞硬约束与「失败点必须前移到付费之前」。
- 选项
  - **(a) reroll 前置校验（与礼包闸 ② 同形）：** 用闸 ② 同款计数，可产出 offer 数 < 1 ⇒ **刷新按钮置灰 + 一行说明**，不进入付费路径。后果：与 monetization 闸 ②「把失败点挪到掏钱之前」完全同形；按 `ux/error-and-blocking-ux.md` 灰态判据属「必然无结果的操作」⇒ 置灰合法。**代价：需要一个文案键（如 `EVENT_REROLL_UNAVAILABLE_POOL`，走普通分区不占 `ERR_`），与已定案项 3「零 UI 改动、零文案键」有张力——但 3 说的是「短缺时不给提示」，此处是「刷新按钮不可用」，是另一个界面元素。**
  - (b) 重掷若得 0 条 ⇒ 保留原库存 + 不扣费 + `PushWarning`。后果：需要一条「已进入 `TryApply` 又回滚」的路径，与承重「刷新价与新库存必须落在同一次 `TryApply`」冲突。
  - (c) 允许刷出空店，不处理。后果：直接违反硬约束。
- **推荐：(a)** —— 唯一与既有两条承重（付费前拦截 · 单次原子 `TryApply`）都相容的一支。落点 `exchange/_index.md`「刷新（reroll）」+ `ux/error-and-blocking-ux.md` 灰态判据表补一行。
- 若用户坚持已定案项 3 的「零文案键」口径，退化形态：**刷新按钮置灰、无说明文字**（灰态判据要求「不隐藏」，但未强制必须有说明）——请在裁决时一并明确。

### 🔴-4 闸 ② 对 Exchange 能力族的计数，既有 API 给不出「按 `RarityFilter` 过滤后」的数

- 草稿 §2：「**闸 ② 需要的计数能力全部现成、零新增接口**：能力族用 `ProfileService.GrantableCount(kind, scope)`」
  ✗ `systems/services/profile-service.md` API 面：`int GrantableCount(AbilityKind kind, AbilityScope scope)` —— **没有 `RarityTier[]` 参数**。
  而 Exchange 的取池链是 `… 排除已持有 → RarityFilter 过滤 → 加权 PickMany`（`exchange/common-properties.md`）。用不含 `RarityFilter` 的计数去判闸 ②，会出现「总池非空、过滤后为空」⇒ **闸 ② 判过、闸 ③ 抽空**，正是草稿自己标为「理论不可达 → `PushError`」的那条分支被真实触发。
  （Research 侧无此问题：`TryPickGrantableMany(Item, Character, rng, 3)` 不带 `RarityFilter`，`GrantableCount(Item, Character)` 口径吻合。）
- 选项
  - **(a) 给 `GrantableCount` 加一个可选 `RarityTier[] rarityFilter = null` 参数**（`null` / 空 = 不限）。后果：改一行签名，调用方（礼包闸 ②）零改动；`profile-service.md` API 表改一行。
  - (b) 新增一个重载 `GrantableCount(kind, scope, RarityTier[] filter)`。后果：等价，API 表多一行。
  - (c) 闸 ② 对能力族改用不含 `RarityFilter` 的宽松计数。后果：保留上述漏判，且它无法在任何地方被发现——与「闸 ② 是不能留空面板的真正防线」自相矛盾。
- **推荐：(a)** —— 闸的判据必须与实际抽取链**同口径**，这是闸 ② 之所以能声称「闸 ③ 的空分支理论不可达」的全部依据；可选参数比重载少一行且不改既有调用点。
- 注：草稿「零新增接口」这句话在写入时须相应改写，不能原样落进设计文档。

## 🟠 含糊

### 🟠-1 Exchange 闸 ① 的聚合口径：`RarityFilter` **重叠但不相同**的多条规则逃过合并断言

- 草稿 E1：「**同 `Kind` + 同 `RarityFilter`** 的多条规则按 `SlotCount` 之和判（同批无放回，它们抢同一个池）」。
  但两条 `Kind` 相同、`RarityFilter` 分别为 `[T1,T2]` 与 `[T2,T3]` 的规则**同样抢同一批 T2 条目**，却因为 filter 不完全相同而各自单独判 ⇒ 断言放过一个真实的短缺编排。
- 选项
  - (a) 保持草稿原文（完全相同才合并）。后果：留重叠漏洞，闸 ① 的「机械化硬保证」名不副实。
  - (b) 按 `Kind` 合并**全部**规则，池取各 `RarityFilter` **并集**过滤后的条目数。后果：实现最简；会误报（并集足够但某单档不足的情形判不出），方向偏保守。
  - **(c) 逐 `RarityTier` 档位核算**：对每个 `Kind` 的每个档位，覆盖该档位的全部规则 Σ`SlotCount` + 余量 ≤ 该档位的池条目数。后果：精确、无漏无误报；实现是一次分组求和，落在加载期不计成本。
- **推荐：(c)** —— 闸 ① 的存在理由就是「机械化」，一个放过重叠编排的断言等于把问题推到运行期由闸 ②③ 兜，而闸 ①③ 的分工本是「编排错误在启动期就大声失败」。

### 🟠-2 闸 ② 过滤之后，批次规模不足 / 候选池为空时怎么办，草稿未交代

- 草稿只写「该条目本次不进候选池」，未回答「大量条目被闸 ② 移出后，本批凑不够怎么办」。
  相关既有权威：`future-event-service.md` API 面「内容池为空 = 坏数据 → `PushError` + 抛」；批次规模「常态 3、区间 1–5，**1 项的批次合法**」；「邻接集合不经 `AllEnabled()` …… 这条例外也是 **Travel 兜底恒可产出**的前提」。
- 选项
  - **(a) 不新增任何分支**：闸 ② 只做候选池过滤，批次规模照常由既有产出逻辑给出（可缩到 1 项）；若过滤后候选池为空，落既有「内容池为空 = 坏数据 → `PushError` + 抛」。理由：Travel 恒可产出 ⇒ 轮回死锁在规则层不成立。
  - (b) 为闸 ② 设一个「最多移出 N 条 / 移出后至少保留 K 条」的上限。后果：新机制，要回答「保留哪几条」，且会让被保留的条目正是空面板条目。
- **推荐：(a)** —— 三条既有定案（1 项批次合法 · Travel 恒可产出 · 池空即坏数据）已把这个退化情形完全覆盖，写一句推论即可，不新增规则。**但草稿没写这一句，需用户确认按此落笔。**

### 🟠-3 三道闸「分界判据」的**本体**写在哪一份文档，是否改动 `monetization.md`

- 草稿 §「与既有决策的张力」第 2 条：「必须在**两处都写下**分界判据（玩家有没有付过钱）…… 建议在 `monetization.md` 的三道闸小节补一句回链」。
  但 `monetization.md` **不在草稿 `targets:` 的 7 份文档内**；且「两处都写下」与本库硬纪律「回链而非复述，绝不制造第二权威」有张力。
- 选项
  - **(a) 判据本体写在本次的新落点（`future-event-service.md` 的闸 ② / ③ 小节），`monetization.md` 三道闸小节补一句回链。** 后果：改动面 +1 份（monetization.md，一句话）；单一权威，双向可见。
  - (b) 判据本体写进 `monetization.md`（它是三道闸体例的原产地），本次新落点回链过去。后果：同样 +1 份；但把玩法侧的判据挂在商业化文档下，读 Research / Exchange 的人要跳一次。
  - (c) 只在本次落点写，不动 `monetization.md`。后果：读礼包三道闸的人看不到边界，本库出现「第二组看似相反的规则而无人给出分界」——正是草稿引用 `ux/error-and-blocking-ux.md`「灰态判据」小节所要防的形态。
- **推荐：(a)**。

### 🟠-4 「开局构筑事件可以缺席、首批退化为常规批」这句话写在哪份文档

- 该结论已由用户定案（取 4A 的连带），但 `systems/adventure-event/research/_index.md`「开局构筑事件」小节现写着「开局底盘明写为『2 门角色绑定功法 + 1 门选来的功法 + 1 件选来的法宝』」「它是玩家的第一屏」，读起来是**结构性必然**。该文档**不在草稿 `targets:` 内**。
- 选项
  - **(a) 写进 `research/_index.md`「开局构筑事件」小节一句**（缺席是可能的、是大声失败的运营事故、不设补发）。后果：+1 份文档；读到开局底盘定义的人当场看到它的失败面。
  - (b) 只写进 `future-event-service.md` 的闸 ② 段。后果：开局底盘那句话继续读起来像硬保证，读者需要自己发现另一份文档里的例外。
  - (c) 两处都写。后果：第二权威。
- **推荐：(a)**，并在 `future-event-service.md` 闸 ② 段回链。

## 🔵 可推演（无需回答）

- **`ResearchSlot.SlotIndex` 在空槽剔除后不重排，保留模板槽序号。** 依据：`ResearchSlot` 上存在 `SlotIndex` 字段本身就是为了不依赖数组下标溯源到 `ResearchSlotSpec`（`research/common-properties.md`）。
- **存档 schema 零改动、零迁移。** 只是既有列表字段（`EventOption.ExchangeStock` / `ResearchSlot.Candidates`）可以更短；「期望数量 / 短缺标记」不落快照——与「模板上的 outcome / effect 定义不进快照」同一条判据。
- **确定性零影响。** 闸 ② 的计数不消耗 RNG；闸 ③ 短缺时 `PickMany` 消耗的抽取次数照常由 `DrawCount` / `State` 持久化（`state-save-rules.md` · `life-cycle-service.md` 的原子写不变式）。
- **「退出重进后仍然少给」是防重掷纪律要的行为，不是 bug。** 依据：`exchange/_index.md`「恢复即读结果，绝不重走取池链」。
- **闸 ① 的 Research 断言只覆盖内容池型操作（`LearnTechnique` / `GrantItem`）。** 其余四类（`UpgradeTechnique` / `ForgetTechnique` / `RemoveLooseCard` / `Recuperate`）取自卡组或无池，加载期够不着，不写断言。
- **`PickMany` 的加权重载与 `out` 参数不冲突。** `content-service.md` 已定「`PickOne` / `PickMany` 需要加权重载」，本次只是给每个重载加一个 `out`；且 `DrawPool<T>` 排在「第二阶段开工前」的**纯加法窗口**内，改签名零返工。
- **`AllEnabled()` 纪律、无第三级抽取原语、不硬编码平衡数值三条全部满足。** 闸 ①② 的计数分别走 `AllIncludingDisabled()`（加载期强校验的正当调用方）与 `DrawPool<T>` / `GrantableCount`；余量两格落 `balance.md`。
- **不新增 RNG 子流。** Research 用 `RngStream.Reward`、Exchange 用 `RngStream.Shop`，均既有。

## 拟改动文档清单与各自新增要点

> 标 ⚠ 的落点取决于对应 interview 项的裁决。

| 文档 | 新增/修改要点（供跨草稿核对） |
|---|---|
| `handoffs/2026-08-19-<slug>.md`（新建） | 本次意图的整洁 handoff；`## Clarifications` 记合并 interview 的每一项裁决 |
| `systems/services/content-service.md` | 「两条契约由授予池这个调用方定死」那一段：`PickMany` 签名补 `out IReadOnlyList<T> picked`；补三行短缺语义（≥count / 0<池<count / 池==0），明写 `picked` **永不为 `null`** |
| `systems/services/profile-service.md` | API 表 `TryPickGrantableMany` 行：签名补 `out IReadOnlyList<string> pickedIds`，失败语义列把「含『不足 count』的部分情形」补全为完整语义；⚠🔴-4 `GrantableCount` 行加 `RarityTier[] rarityFilter` 可选参数 |
| `systems/adventure-event/research/common-properties.md` | 新增闸 ① 校验行（R1，逐操作类池 ≥ `CandidateCount` + `ResearchPoolMargin`）；「候选取池」小节补逐情形降级表（0 → 该操作不进本槽；0<n<所需 → 给几条算几条，即 `CandidateCount` 上界语义的兑现；整槽 0 → 该槽不进 `ResearchSlot[]`，`SlotIndex` 不重排）；日志形态 |
| `systems/adventure-event/exchange/common-properties.md` | 加载期校验表：**收紧既有那一行**（原「过滤后为空 → `PushError`」→ ⚠🟠-1 裁定的聚合口径 + `ExchangePoolMargin`）；运行期校验表补短缺降级行（0 → 该规则贡献 0 槽；0<n<`SlotCount` → 不补位、不用别族顶替）；日志形态 |
| `systems/adventure-event/exchange/_index.md` | 「库存生成」补：不设兜底商品 / 保底 offer（引「空池是运营事故，不是玩法分支」）；「刷新（reroll）」补：不因库存少而下调刷新价 / 免除刷新费，救济通道是刷新本身；⚠🔴-3 reroll 前置校验 + 按钮置灰；「售出」补一句售出面不受库存短缺影响 |
| `systems/services/future-event-service.md` | 新增**取池期过滤第二条**（与 Explore 壳过滤并列）：Research 至少一个槽 ≥1 且 `AllowDecline == false` 的槽逐槽 ≥1；Exchange 全部 `StockRule` 可产出 offer 之和 ≥1；不满足 ⇒ 本次不进候选池 + `PushWarning` + 不落快照。物化期降级（闸 ③）+ ⚠🔴-1 的不可达分支处置。三道闸的**分界判据**（⚠🟠-3）。⚠🟠-2 的一句推论（批次可缩到 1 项 / 池空即坏数据 / Travel 恒可产出） |
| `systems/balance.md` | 新增两格 `ResearchPoolMargin` / `ExchangePoolMargin`（与 `GrantPoolMargin` 同表不同值，取值待 ch1 专场）；「待决问题」补一条取值待定项 |
| ⚠ `systems/adventure-event/explore/_index.md` | 🔴-2：「取池与校验」把壳过滤扩写为「真身 `ContentEnabled == false` **或** 真身是 Exchange 且闸 ② 不通过」；「真身类型的分布」补一句「闸 ② 的移出会轻微偏移期望占比，不为此设补偿」 |
| ⚠ `systems/monetization.md` | 🟠-3(a)：三道闸小节补一句分界判据回链（不复述玩法侧内容） |
| ⚠ `systems/adventure-event/research/_index.md` | 🟠-4(a)：「开局构筑事件」小节补一句——它可能因池见底而缺席，首批退化为常规批，是大声失败的运营事故，不设补发 |
| ⚠ `ux/error-and-blocking-ux.md` | 🔴-3(a) 若采纳：灰态判据表补一行「Exchange 刷新按钮的池前置不满足 → 置灰（+ 说明？见 🔴-3 尾注）」；若需说明文案，键走 `EVENT_` 普通分区，**不占 `ERR_`** |

**台账行（由 orchestrator 代笔，worker 不写）**

- `handoffs/_index.md`：新增一行 `2026-08-19-<slug> | 2026-08-19 | systems/adventure-event/{research,exchange} · systems/services/{content,profile,future-event} · systems/balance | distilled | <上表实际改动文件>`
- `open-questions/02-event-options.md`：**删除**「`PickMany` 抽不足 `count` 时的调用侧处置未定（08-17 新增 · 轻）」整条
- `open-questions/02-event-options.md`：**新增**（仅当对应 interview 项被裁定为「结构已定、数值待定」）—— 无新增结构性待答项；数值项并入 `balance.md` 侧
- `answer-logs/log-pickmany-shortfall-handling.md`（新建）：移出 1 条；`answer-logs/_index.md` 台账追加一行
- `open-questions/update-log.md` 顶部追加本次摘要；`open-questions.md` 索引「最近更新」一行
- `inbox/_index.md`：`solution-draft-pickmany-shortfall-handling.md` 从待处理表移入已归档表；文件 `git mv` 进 `inbox/archive/`，front matter 补 `reviewed:` / `distilled-to:`
- **不动 `open-questions.md` 的「derive 就绪度」小节**

## 越界发现

- **多操作槽内 `CandidateCount` 如何在 `AllowedOperations` 各类之间分配**（例：一个槽同时允许 `LearnTechnique` 与 `UpgradeTechnique`，3 条候选怎么分）——`research/common-properties.md` 的取池链表逐操作给了链，但没给分配规则。本方案的闸 ①（逐操作类各自 ≥ `CandidateCount` + 余量，保守口径）与闸 ③（降级为**实际抽到的合并条数**）都不依赖它，故**本方案自洽**；但它是一条真实的待答项，建议 orchestrator 收尾时评估是否新增进 `open-questions/03-adventure-event-types.md`。
- **`ResearchPoolMargin` / `ExchangePoolMargin` / Exchange 槽位总数上界 / 定价表各格的取值** —— 归 ch1 数值标杆专场（`systems/balance.md`），本方案只定形态。
- **eventOptions 的上游生成 / 加权合并算法**（类型修正乘性还是加性、多条 `PlotModulation` 与 location 修正的合并、批次规模区间两端由什么驱动）—— 闸 ② 会移出个别条目、轻微改变类型分布，与「类型配比」待答项有交互面，但合并算法本身不在本分片范围内。
- **满袋时能否购买道具**（`systems/character-profile/item/_index.md`）—— 已答定为购买前置校验拦截；对本方案的连带已归零，本分片不写该文档。
- **构筑面板与商店的竖屏呈现形态 / 风险档的视觉标注** —— `ux/screen-flow.md` 既有待答项；本方案只表态「不新增短缺提示」，不涉布局。（🔴-3 若采纳 (a)，会新增一个**刷新按钮**的灰态，属灰态判据表而非布局，已列入拟改动清单。）

## 跨草稿风险信号（供 orchestrator 合并时优先核对）

1. **`profile-service.md` 的 API 表**将被本分片改两行（`TryPickGrantableMany` 的 `out` + `GrantableCount` 的 `rarityFilter`）——**写入面冲突高危**，任何其他分片若也写该表必须与本分片串行或合并。
2. **`content-service.md` 的「两条契约由授予池这个调用方定死」段**同理。
3. **`future-event-service.md` 的取池期过滤 / 物化段**将新增一整条并列条目——若有分片同样在动该文档的物化面，需串行。
4. **`balance.md` 新增两格 + 待决问题一条**——`balance.md` 是典型的多分片共写文件。
5. ⚠ 本分片可能把改动面从草稿声明的 6 份扩到 **10 份**（+ explore/_index.md、monetization.md、research/_index.md、error-and-blocking-ux.md），取决于 🔴-2 / 🔴-3 / 🟠-3 / 🟠-4 的裁决。请在分区时按**最大改动面**推算。
