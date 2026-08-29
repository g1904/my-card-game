# 货币体系拆分：灵石（基础）+ 仙玉（高阶）

- id: 2026-08-25-currency-split-spirit-stone-and-immortal-jade
- date: 2026-08-25
- topic: terminology.md · systems/character-profile/currency.md · systems/architecture.md · systems/balance.md · systems/adventure-event/exchange/**
- status: distilled
- distilled-to: `terminology.md`、`program-overview.md`、`systems/_index.md`、`systems/architecture.md`、`systems/balance.md`、`systems/monetization.md`、`systems/character-profile/{_index,currency,mana}.md`、`systems/character-profile/{deck,item}/_index.md`、`systems/player-profile/_index.md`、`systems/player-profile/codex/common-properties.md`、`systems/services/{_index,profile-service,life-cycle-service,future-event-service}.md`、`systems/adventure-event/common-properties.md`、`systems/adventure-event/exchange/{_index,common-properties}.md`、`systems/adventure-event/research/_index.md`、`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`、`decisions/ADR-0020`、`ADR-0022`、`ADR-0023`（后三份仅字面改名）

## Intent（distilled）

### 单层货币拆为两层，`jade` 整体退役

- **灵石 `spiritStone`** —— 基础货币，承接原单一货币的全部角色：轮回级软通货，主要花销在 Exchange。
- **仙玉 `immortalJade`** —— 高阶货币，**轮回级**，归 `CharacterProfile`，随轮回清理。

原标识符 `jade` 不再指代任何东西。**不把 `jade` 改派给仙玉**：库中每一处 `Jade` / `jade` 今天都指基础货币，改派后每一处未改到的引用都静默变成错的意思，而没有任何机制能发现——这与稳定 `Id` 纪律直接相抵。

### 仙玉是轮回级，不触碰「无账号级可支配货币」这条取向

账号级路线要从零设计获取 / 囤积 / 兑换 / 定价四件事并新增通胀护栏；轮回级路线只是照灵石的行再加一行。落点因此是纯加法：`CharacterProfile` 字段表加一行、`CostKey` 由 15 值增至 16 值、`ResourceElements` 轮回层加一行、`currency.md` 扩为双币文档。付费面排除表、`player-power` 的「为何不是货币」、`ADR-0023` 四处**零改动**。

### 获取与花销：不新增任何机制

- **获取 = 稀有 AdventureEvent 产出**，走既有 `OutcomeSpec.Elements`；`ResourceKey` 校验集合与 `future-event-service.md` 的合法子集表各扩一项。「稀有」由内容侧的事件出现权重与编排承载，**不加字段、不加加载期校验**——不给字段就不存在「谁有权用它」的问题。
- **花销 = 高阶 Exchange 商品。**
- 仙玉的「高阶」由**稀有度与价格量级**表达，不由新机制表达。
- 被排除的通道，理由留作正面陈述：付费获取会造出一条可反复付费的消耗型硬通货，撞穿「只有一个付费点、买断式一次授予」的排除表；成就与置换是账号级，用轮回级货币输血跨层；Finale 产出在篇章收口处发放、随后即被清理，价值可疑；新事件类型会牵动五值封闭枚举与整套物化链。
- Research 一律不产出货币——两币的长期价值出口都在 Exchange，而 Research 是最贵且必然赚的那一类事件。

### 计价币种是「族 × 稀有度」定价表那一格的属性

Exchange 全链此前没有任何币种载体：定价表格值是纯 `int`，`ExchangeOffer` 与 `ExchangeStockRule` 都无币种格，购买 spec 写死单一币种。本次的书写位定在**表**上：

- 定价表格值由 `int` 变为 **（支付币种, 基准价）**；内容侧**零新增书写位**，「条目默认不填、取表值」原样成立。
- `ExchangeOffer` 增一格 `Currency`（物化时从表上抄下的快照）；`ExchangeStockRule` 与 `ExchangeSpec` **不加**币种格。
- 购买 spec 取 `offer.Currency`；`CanAfford` / `TryApply` 本就对 `CostKey` 泛化，pipeline **零改动**。
- 刷新是店级动作、不落在任何一格上，恒以灵石计价。

**被接受的代价：** 币种与「族 × 稀有度」绑死——编排不出「同一稀有档有的收灵石、有的收仙玉」，也编排不出「专收仙玉的商贾」。换来的是币种不可被内容条目误填，以及下面这条闭合。

### 两币完全不可兑换，且售出通道不留事实汇率

不设任何单向或双向兑换，零机制。可兑换会使双层退化为单层加一个汇率。

售出侧的闭合是免费的：`SellRatePercent` 的折算基准本就取「族 × 稀有度」定价表的基准价，币种既然在表上，**卖出所得恒与买入同币**。「可售出 ⟺ `Kind == CharacterItem`」那条代码级常量判据一字不动。

### 仙玉沿用灵石的既有语义

取值域 `[0, ∞)`；归 0 不构成终态（`DefeatReason` 四值封闭，无货币项）；`ResourceElements` 行 `(0, null, null, null, null, Add)`，两个修正列恒 `null`（`ShopPrice` 的施加点在物化 / 展示侧，再填即打两次折）；不设篇章维涨价（随轮回清理、每章重置）。

### 呈现

仙玉与灵石的非战斗查看落点是**储物袋**这一单一落点（不进战斗 HUD——货币在战斗内无用途）。同一家店可同时出现两种币计价的商品，价签因此标明币种。

## Clarifications（interview 产物）

- **计价币种写在哪一层** → 表驱动：币种是「族 × 稀有度」格的属性。这**推翻了原始输入「加一种支付币种是在既有表上加一列」的前提**——实测全链无币种载体，「加一列」在这张表上有三种互不相同的落法。规则驱动（`ExchangeStockRule` 加币种格）被否：币种会成为内容可配，一个填错的条目就把高阶商品变成灵石可买，而校验无从判断作者是否故意；且物品脱离 offer 后无从读出币种，售出只能恒发灵石，回收率当场变成事实汇率。
- **售出所得的币种** → 同币回收。它是表驱动的自动解，本题因而无需单独裁决。
- 标准默认（未出题，直接采纳）：`CostKey` 新成员紧随 `SpiritStone`；`profile-service.md` 的 `ResourceElements` 逐行表新增整行并把三处计数 15 改 16（原始输入把该文件归为「纯改名」，实测不成立——它是逐行权威）；`architecture.md` 的 `OutcomeDirection` 用法面由四个 key 扩为五个；胜侧 `rewardPerMomentum` 单价表**不加**仙玉列（每场战斗一条线性涓流与「稀有」相抵）；仙玉不进 Exchange 的回收折算之外的任何售出通道；存档字段名 `immortalJade`，随本次 bump schema 版本（空迁移）；`PlayerItem` 族的措辞泛化为「货币」、规则层口径零改动。
- **顺手订正一处既有漂移：** `DefeatReason` 的权威是**四值**（含 `FinaleFailed`），而 `currency.md` 沿用了「三值封闭」的旧措辞。只改本次触及的句子，不扩面全库收口。

## Open questions

- **仙玉的获取量与花销价格量级未设计。** 形态已定，只欠取值，与既有的「灵石的获取渠道与掉落权重整体未设计」同归内容扩充后的统计校准。两者互相约束：双币经济的相对价值由两条产出曲线共同决定。灵石那一半的空白**不因本次答定而移出**。
- 定价表中**哪些格填仙玉**属逐格取值，同归统计校准。

## Notes / triage

- 改名波及面实测：全库 78 份文件 237 处，其中活文档 26 份。过程档案（`handoffs/` · `inbox/archive/` · `answer-logs/` · `update-log-archive.md`）约 146 处**不回改**，历史归 git。
- 库外 `.claude/knowledge/` 3 处（`dictionary.md` · `systems/_index.md` · `scenes/_index.md`）归 `/sync-knowledge`，本次不改。
- `open-questions.md` 的「derive 就绪度」小节内含旧币名，**本次未动**（该小节由 `/assess-derive-readiness` 独占写入，待其下次全量重估）。
