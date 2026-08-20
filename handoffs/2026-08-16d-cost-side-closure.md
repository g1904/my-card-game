# 成本侧收口：钳制表 · 拒绝语义的残留消费点 · 遮罩下的成本展示

- id: 2026-08-16d-cost-side-closure
- date: 2026-08-16
- topic: systems/services/profile-service · systems/architecture · systems/adventure-event/common-properties · systems/adventure-event/explore · systems/adventure-event/exchange · systems/services/life-cycle-service · systems/character-profile/currency · systems/character-profile/life-total · systems/character-profile/mana
- status: distilled
- distilled-to: `systems/services/profile-service.md`、`systems/architecture.md`、`systems/adventure-event/common-properties.md`、`systems/adventure-event/explore/_index.md`、`systems/adventure-event/exchange/_index.md`、`systems/services/life-cycle-service.md`、`systems/character-profile/currency.md`、`systems/character-profile/life-total.md`、`systems/character-profile/mana.md`

## Intent（distilled）

**一句话：** `selectCost` 的成本侧三条待答项同属一条语义链，一起答定——**钳制是逐 element 的一张封闭表**（不是全局通则）、**拒绝语义按「有无消费点」分三样各自处置**、**遮罩下只存在一份成本**（Explore 壳自己的），泄漏面因而消失。

三条问题必须一起答：分开答会各自定出互不自洽的规则。第三条看似是 UX 问题，实为成本侧问题——它问的是「这一步到底扣的是哪一份成本」，而这正是第一条的施加语义要回答的事。

### 一、钳制是逐 element 的规格，不是一条全局规则

把钳制建模为 `CostKey → (Min, Max, DepletionDefeat)` 的一张**封闭表**，而非「资源一律截断到 0」这样一条通则。三条依据：

1. **已有的钳制案例本就是逐条的、且各带自定义区间。** `PowerFragmentAccumulated` 钳制到 `[0, 10000]`（上界来自它自己的万分比语义）；道心 `Faith` / 煞气 `Bloodlust` 钳制到 `[0, 100]` 且**不构成终态**。两个区间互不相同、也都不可能由任何通则给出——形态本就是表。
2. **终态性与钳制是同一张表的两列。** 「归 Min 是不是终态」逐 element 不同（寿元是、灵玉不是），而终态判定 ① / ② 要么硬编码检查两个字段，要么查表。查表使「新增一个终态资源 = 表里加一行 + `DefeatReason` 加一个成员」，与「新增一张卡 = 新增一个 `.tres`」的可加性同向。
3. **一条通则一旦定下，第一个例外就在门口**——上述两个区间已经是例外。

**落点 = 代码常量静态表，不进 `.tres`**（取向 T2）。它与 `(Kind, Scope, Source)` 合法子集表、`RngStream` 子流清单同类：三列没有一列是平衡旋钮，`Min` 是取值域、`DepletionDefeat` 是终态语义，改任一列改变的是规则而非难度。

### 二、`Min = 0` 是资源族的默认，例外逐条写明；寿元取默认

首批五行（其余随「cost element 清单」逐条补）：

| `CostKey` | Min | Max | 归 Min 时 | 依据 |
|---|---|---|---|---|
| `LifeSpan` | 0 | 无 | **终态** `DefeatReason.LifeSpanExhausted` | 归 0 = `defeated` |
| `Jade` | 0 | 无 | 无（只是变穷） | `DefeatReason` 三值封闭无灵玉项；灵玉随轮回清理，不承载终态语义 |
| `LifeTotal` | 0 | **无**（明确不设上界） | **终态** `DefeatReason.LifeTotalExhausted` | `lifeTotalLimit` 概念已整体删除、无上限截断；归 0 = `defeated` |
| `Faith` | 0 | 100 | 无（不构成终态、不影响档判定） | 既有已定的区间，迁入本表 |
| `Bloodlust` | 0 | 100 | 同上 | 同上 |

寿元取 `Min = 0`（截断，不允许为负）的四条依据：

- **Band 百分比的分母是 `ChapterLifeSpanBudget`。** 允许为负则 Band 2 的「标红精确余量倒数」会显示负数，与该呈现的语义（还剩多少）自相矛盾——而那是寿元在全库**唯一**的精确显示通道。
- **终态判据的两种写法因此同解。** `lifeSpan <= 0` 与 `lifeSpan == 0` 在截断后完全等价；不截断则两者行为不同，而本库没有任何地方指定过用哪一种。截断消掉这个歧义面。
- **跨篇章结转要求剩余寿元是一个可加的非负预算。** 负数结转在语义上不成立（角色此时已 `defeated`，不会有下一篇章），但不截断意味着 `Status.LifeSpan` 会以负值落进存档，读档校验与元进程的寿元曲线都要额外处理负轴，换来零收益。
- **通行做法：** roguelike 的资源条一律 clamp 到 0。「欠债」只在有**还债机制**时才值得建模，本作没有——寿元透支后角色当场终结，没有下一步去偿还。

### 三、spec 不截断，字段截断（承重的分层）

截断只作用在「把 element 施加到 Profile 字段」那一刻；`ProfileChangeSpec` 内 `ChangeElement.BaseValue` 与落进 `PastEventEntry.SelectCost` / `AppliedChange` 的快照，**一律保留未截断的原值**。

- 保住 `AppliedChange`「可直接重放的账」这条定位——截断进 spec 等于让账本记的不是实际发生的事。
- 使**「超支了多少」这一信息不丢**：由 `LifeSpanAfter == 0` 与 `AppliedChange` 中的原值相减即可得出，回收了截断方案唯一真实的代价。
- 它与「内容侧写正数量值、物化时取负、`TryApply` 按带符号施加」是同一条分层纪律的第四段：**每一层只做自己那一次变换，不把下游的语义提前**。

### 四、拒绝语义按「有无消费点」分三样处置

| | 处置 | 依据 |
|---|---|---|
| `AdvanceStage.CostRejected` | **删除** | 只服务于事件推进路径，而该路径已定「无条件施加、不做付得起校验」⇒ 成员已不可达。留着不只是死代码，它会主动诱导后来者把校验加回来 |
| `AdvanceResult.MissingElement` | **删除** | `CostRejected` 是让该字段有意义的唯一 stage；删掉后它恒为默认值，同上判据 |
| `ProfileService.CanAfford(spec)` | **保留** | 有一个已知且已定存在的消费点：Exchange 的商店购买。主动消费与事件推进的语义根本不同 |
| `ApplyResult.MissingElement` | **保留** | `CanAfford` 失败时唯一能告诉 UI「差的是哪一样」的通道 |

**为什么商店可以灰显、而事件选择面不可以**——不是双标，判据同为一条：**「明知做不到仍然去做」有没有意义。** 事件选择面有意义（明知是死路仍然走，与「打不过也得打」同构，且换来一段终局叙事）；商店里点一件买不起的商品没有任何意义——不产生终态、不产生叙事、不推进任何东西，只产生一次挫败。

这条判据要在 `exchange/_index.md` 与 `profile-service.md` 两处同时写下（而不是只写结论），否则「事件面不灰显」很容易被误推广到商店。

### 五、遮罩下展示的是 Explore 壳自己的 `selectCost`

这条待答项的前提（「两份成本要选一份展示」）在既有流程下不成立：**支付先于揭示**。`TryApply(SelectCost)` 在 `eventStart` 阶段的 Explore 揭示**之前**，被施加的必然是 `EventOption.SelectCost`，而 Explore 的 `EventOption` 由 Explore 模板物化——**真身模板的成本字段从头到尾不在链路上**。`PastEventEntry` 也只有一份 `SelectCost`。

所以答案不是「二选一」，而是：**只有一份成本存在**，泄漏面随之消失。配套落定三条，否则这个干净的结论会被内容侧重新捅破：

1. **物化纪律（可机械检查）：** 物化 Explore `EventOption` 时 `SelectCost` 一律取 Explore 模板 + 定价表的 Explore 行，**不读真身模板的任何成本字段**；物化组装后加一条断言，与「`SelectCost.AbilityElements` 恒空」同一处、同一档（`PushError`）。
2. **Explore 在定价表上自成一行，且该行不得由真身推导。** 若成本取自真身，Band 2 的精确展示会让玩家用成本数值反推真身类型——三类定价不同即构成指纹。这是本问题真正的泄漏面所在。
3. **真身模板的成本字段不是死字段。** 同一个 Combat / Travel / Exchange 条目也可能作为普通选项直接出现在同批 eventOptions 里，那时它自己的 `selectCost` 照常施加。「被遮罩时不读」是 Explore 这条路径的局部规则，不是对该字段的全局否定。

**Explore 条目禁用条目级成本覆盖值**（取向 T1）：`lifeSpanCost` 一律取定价表的 Explore 行，内容条目不得标偏移 / 覆盖值——否则作者写出的差异化成本本身就是第二种指纹（玩家会记住「这个秘境花 4 点的总是打架」）。落地为**内容模板加载期校验**，违规条目 `PushError` + `Id`。

## Clarifications（interview 产物）

- **草稿论据「道心 / 煞气是双向量，`Min = 0` 对它们是错的」→ 与既有设计相抵，按既有权威改写。** `life-cycle-service.md` 已明写两者施加后截断到 `[0, 100]` 且不构成终态。草稿由跨档判据 `|newBand| > |oldBand|` 反推「属性值带符号」是误读——band 是围绕常态的偏移档，band 带符号与属性值 `[0, 100]` 完全兼容。**结论不变**（草稿自己声明该论据不承重，`PowerFragmentAccumulated` 的 `[0, 10000]` 单独已足够支撑「必须配表」）；且 `[0, 100]` 恰是第二个自定义区间，反而更支持配表。落笔时该论据改写为引用既有区间，并把这两行直接填进钳制表。
- **`AdvanceResult.MissingElement` 的处置 → 一并删除**（用户裁决）。草稿只表态了 `ApplyResult.MissingElement` 保留，未提 `AdvanceResult` 上的同名字段；`CostRejected` 是让它有意义的唯一 stage，删除后它恒为默认值，按同一条「不可达成员会诱导后来者加回校验」的判据一并删除。`AdvanceResult` 收窄为 `(Success, FailedAt, StatusAfter)`。

## 已定案的取向（用户裁决，一律取推荐项）

> 本节保留每一项的**否决理由与代价**——定案后被丢弃的那半边正是日后最容易被无意重新提出的东西。

- **T1 · Explore 条目禁用条目级成本覆盖值。**
  - 代价（明写接受）：Explore 作者失去一个风味旋钮，「这个秘境格外凶险，代价更高」只能由文案与美术承载。
  - 已否决：允许覆盖但要求同一 location / 篇章内取值齐平——效果等价，却**无法机械检查**、只能靠作者自律，而本库对内容侧一贯的收口方式是「能加载期校验的就不留自律」。
- **T2 · 钳制表落代码常量静态表，不落 `.tres`。**
  - 已否决：落 `.tres` 使区间可热更。代价过高——一次 overlay 热更即可改写终态判据（把 `LifeSpan` 的 `Min` 调成 -50 就等于取消寿元死亡），这类改动应走版本发布而非热更。
  - 配套护栏：在 `.claude/rules/data-resource-rules.md` 留一句可判的边界——「取值域与终态语义走常量表，平衡数值走 `.tres`」，使本例外不被援引去把别的数值搬进代码。
- **T3 · `ApplyResult` 不新增「触底 element」字段。** 终态判定读 `Snapshot.Status`，判据是「== 对应 `ClampSpec.Min`」；「本来就是 0 还在推进」在规则层不可达（归 0 当场 `defeated`），故触底与既有值无须区分。
  - 已否决：新增 `IReadOnlyList<CostKey> Depleted`。收益仅限日志与诊断，代价是每次 `TryApply` 多一次堆分配——而 `ApplyResult` 是 `readonly record struct`（零堆分配）正是既定纪律。
  - 若日后确需触底诊断，正确的加法是在 `ProfileManager` 内部打一行 `[ProfileManager-TryApply] depleted key=LifeSpan` 的可追溯性日志（与既有 `AbilityChangeElement` 日志同档），**不是**改结果类型的形状。
- **附 · mana 张力的处置：不视为松动。** `manaLimit` 若进 `CostKey`，其 `Min = 0` 是**取值域**而非下界护栏；被否决的两条护栏（保底 ≥ 1、死牌转化）仍然不做。在 `mana.md` 补一句澄清以免日后被当作不一致而「顺手统一」。

## 备选方案（已考虑并否决）

- **寿元允许为负、终态判据写 `<= 0`。** 否决：Band 2 的精确余量会显示负数（寿元唯一的精确显示通道）；负值落存档使读档校验与履历曲线要处理负轴；「超支量」信息本方案已用「spec 不截断」免费拿到。
- **一条全局通则「资源一律截断到 0」，不建表。** 否决：`[0, 10000]` 与 `[0, 100]` 两个既有区间各自已是反例，通则从第一天起就要挂例外；且终态性无处安放，只能继续硬编码。
- **`CanAfford` / `MissingElement` / `CostRejected` 三样一起删。** 否决：`CanAfford` 与 `ApplyResult.MissingElement` 有已知的未来消费点（Exchange），删了要原样加回来。「有无消费点」正是应当分开处置的判据。
- **Explore 展示真身的 `selectCost`。** 否决：真身成本根本不在施加链路上，展示它等于展示一个不会发生的扣减——比泄漏更糟，它是错的。
- **Band 2 下 Explore 一律不显示成本（用不显示回避泄漏）。** 否决：Band 2 的整个设计意图是「让玩家算得出这一步可能是最后一步」，对 Explore 关掉它恰好在玩家最需要算账时挖一个洞；泄漏面已由「Explore 自成定价行」封死，不需要牺牲这条。

## 存档与跨库

- **存档 schema 不 bump。** 截断只收窄既有字段的取值域（`Status.LifeSpan` 等本就是 `int`，此后恒 ≥ 0），不增删字段；`PastEventEntry` 的两个 spec 字段形状不变（本方案明确它们**不**截断）。迁移：无。
- **不跨库。** `backend-design-documents/contracts/profile-sync.md` §5 明写 `characterDiffs` 整体落不透明段、纯透传，透明字段表不含任何 `characterProfile` 字段；后端对不透明段不递归、不比对、不校验，因此**不重放 `AppliedChange`**，客户端的截断语义对后端零可见。故本次不写对侧草稿、不产生跨边界承接项。
  - **护栏：** 若日后要把寿元 / 灵玉 / 耐久任一字段提进透明档，必须同批把本方案的钳制语义写进契约——否则后端复算会在正常账号上误报（它看到的 `AppliedChange` 是未截断值，而快照是截断值）。已登记进 `open-questions/cross-boundary.md` 作为预警条目。
- **`.claude/rules/*` 的薄引用**（各一句 + 回链，不展开设计）：`state-save-rules.md` 加「资源 element 的钳制与终态判据查 `ResourceClamps` 表，不散落字段判断」；`data-resource-rules.md` 加 T2 的配套护栏。两处由 `/sync-knowledge` 落笔，不在本次提炼范围内。

## Open questions

- **cost element 清单（资源族）未定** → 钳制表当前只有五行，形态已定稿，行数随该问答定逐条补。
- **道心 `Faith` / 煞气 `Bloodlust` 是否正式列入 `CostKey`。** 两者的区间 `[0, 100]` 已定，但它们目前经隐藏属性推拉施加、是否与资源族共用 `CostKey` 枚举未定。不阻塞本方案。
- **Exchange 专场未开** → `CanAfford` 的**呈现形态**（灰显 / 弹窗 / 价格标注）待该专场；本方案只定「保留它、唯一消费点在 Exchange」。
- **`lifeSpanCost` 定价表取值（ch1 数值标杆专场）** → Explore 行**填多少**待定；本方案只定「Explore 自成一行、不由真身推导」。
