---
type: solution-draft
date: 2026-09-03
question: `CombatSnapshot.Battlefield` 对侧 `faceDown == true` 的条目，其内容格按视角如何填充？
source: open-questions/01-combat.md → 呈现的残留
targets: systems/services/combat-service.md · systems/character-profile/deck/common-properties.md · ux/combat-ux.md · systems/architecture.md
status: distilled
reviewed: 2026-09-03 — 批量评审裁定走向 = 选项 A（对侧 faceDown 条目整条不入 Battlefield）；合并 interview 另裁两项：PendingTarget 补按视角填充纪律（本稿子项 3 末尾「PendingTargetRequest.SourceCardId 不是泄漏面」的理由在双视角下是假命题，不采纳）· CombatFeedEntry 同增一格 SourceCardId（本稿只给了 StackEntryView）
distilled-to: handoffs/2026-09-03-combat-snapshot-facedown.md
---

# 方案草稿 — `CombatSnapshot.Battlefield` 的 `faceDown` 按视角填充纪律

## 问题

`CombatSnapshot` 对三处信息泄漏面都写死了填充纪律：`SideSnapshot.HandCardInstanceIds`「仅 viewer 己方非空；对侧恒为空」（公开面由 `HandCount` 承载）、`SideSnapshot.UsableItemIds`「仅 viewer 己方非空」、`BattlefieldEntryView.ActivatableAbilities`「只对 `ViewerSide` 己方条目填充，对侧条目恒为空列表」。

`Battlefield` 是**单一列表**（条目自带 `OwnerSide`，呈现层分区渲染），条目自带 `faceDown` 与 `sourceId` / `keywordId` 等内容格，而文档没有写「对侧 `faceDown == true` 的条目怎么办」。照字面读，对手埋伏的**内容**在类型层是可读的 ——「对手只知有一张埋伏、不知是哪张」（`terminology.md`「埋伏」；`ux/combat-ux.md`「只给计数，不给内容」）就退化为 UI 侧的一条约定，而同款泄漏面在本库已经三次都在类型层收口了。

卡住的东西：`BattlefieldEntryView` 的字段面无法定稿（不知道哪些格是条件填充的）；AI 侧「决策输入面限对称可见信息」这条纪律无法宣称是结构保证；`ux/combat-ux.md`「对手侧的面朝下条目不渲染任何条目级入口或标记」这条要求没有契约面的对应物。

## 约束（来自既有设计）

- **「结构上不存在」优于「约定不去读」。** `systems/services/combat-service.md`：「这正是『不读玩家手牌内容』能停在第 1 级的原因 —— 敌方视角下那份内容**结构上不存在**，而不是靠约定不去读它」（ADR-0013 第 1 级）。
- **`SideSnapshot` 单类型，不拆己方 / 对方**；**不为 AI 另立第二个投影类型** —— 两条都在 `combat-service.md` 明写，且 `CombatSnapshot` 是「双视角的单一投影，AI 与呈现共用一个类型（承重）」。
- **`AmbushCount` 已经存在**（`SideSnapshot` 上，「双向对称：只给计数不给内容」），且 08-05 那次定案的原文就是「决定了 `AmbushCount` **而非条目列表**」。
- **AI 侧的消费者只读计数**：`systems/enemies/_index.md` 的 `AmbushCaution` term ——「对手埋伏计数 > 0 时……（**只读计数、不读内容**）」。
- **UX 侧对侧没有渲染对象**：`ux/combat-ux.md`「对手侧的面朝下条目不渲染任何条目级入口或标记……对手侧只汇总进埋伏计数」；「埋伏标记（必做项）—— 只给计数，不给内容；双向对称」。
- **己方 `faceDown` 条目仍需完整视图**：`ux/combat-ux.md`「己方面朝下条目（埋伏）照常有启动入口」，且「逐条渲染还是折叠成一格」归竖屏分区专场 —— 两者都要读 `FaceDown` 这一格。
- **目标面当前够不着 `faceDown` 条目**：`EntryFilter.IncludeFaceDown` 默认 `false`，且「保留字段……内容侧当前不使用」（`deck/common-properties.md`），故 `LegalTargets` 的结果集当前恒不含面朝下条目。
- **隐藏信息不进目标面，走 `EffectScope`**：「弃掉对手一张手牌……走 `EffectScope`（随机 / 全部，无 `TargetRef`）」（同上文件）。
- `ActiveCombat` 是战斗的**全量真值**（`faceDown` 是其战场条目表上的持久字段）；`CombatSnapshot` 明写**不落存档**，「运行时视图字段 ≠ 存档 schema」。

## 建议方案

### 子项 1 — 对侧 `faceDown == true` 的条目**整条不入** `Battlefield` 列表

`[既有推演]`

组装 `CombatSnapshot` 时按视角整条过滤，而不是保留条目再置空内容格：

- 过滤判据：`entry.faceDown == true && entry.ownerSide != ViewerSide` → 该条目**不进** `Battlefield`。
- **不变式（组装期可断言）：** `Battlefield` 中不存在 `FaceDown == true && OwnerSide != ViewerSide` 的条目 ⇒ 视图里 `FaceDown == true` **恒等于「观察方己方的埋伏」**。
- 被过滤掉的条数由 `SideSnapshot.AmbushCount` 承载 —— **公开面零损失**（对手本就只该知道「有几张」）。
- `BattlefieldEntryView` **保留 `FaceDown` 一格**：己方埋伏要靠它决定折叠 / 逐条渲染与埋伏标记，删掉它己方那一半就没形状了。

依据（四条同向，无一条需要新决策）：

1. **与三条既有填充纪律同型。** 其中前两条的形状恰好就是「内容整条不给、另给一个计数」：`HandCardInstanceIds` 恒空 + `HandCount` 给数。`AmbushCount` 在 `SideSnapshot` 上的存在本身就是这条纪律在埋伏这一项上的**已完成的一半**，缺的只是把「列表侧也不给」写下来。
2. **它把泄漏面停在第 1 级。** 置空 / 哨兵值的方案里，内容格在类型上仍然存在，AI 与 ViewModel 都能读到，只靠「记得先判 `faceDown`」把关 —— 这正是本库在手牌那一项上**明确拒绝过**的形态。
3. **AI 侧的消费者已经是计数。** `AmbushCaution` 只读计数、不读内容；取本方案后，「AI 决策输入面限对称可见信息」由结构兑现，而非由 AI 实现的自律兑现。
4. **UX 侧对侧条目没有消费者。** 对手面朝下条目不渲染任何条目级东西，只汇总进计数 —— 视图里给它留一条壳条目，没有任何读者。

### 子项 2 — 把子项 1 的前提机械化：`TargetSlot` 侧的 `IncludeFaceDown` 加一条加载期闸

`[既有推演]`

子项 1 的正确性依赖一条前提：**对侧 `faceDown` 条目永不出现在 `LegalTargets` 里**（否则 UI 会拿到一个自己列表里没有的 `entryId` 去高亮）。当前它成立，靠的是「`IncludeFaceDown` 内容侧不使用」这句散文纪律 —— 建议改成机械可发现的：

在 `deck/common-properties.md` 的加载期校验表加一行：

| 条件 | 处置 |
|---|---|
| `TargetSlot.Kind == BattlefieldEntry` 且 `Filter.IncludeFaceDown == true` 且 `Side != Self` | `PushError` —— 报出引用它的 `CardData.Id` / `AbilityData.Id` 与槽位序号 |

同表已有「`TargetSlot.Kind == HandCard` 且 `AllowedEntryKinds` / `RequiredKeywords` / `IncludeFaceDown` 非空 → `PushError`」一行，本行与它逐字同构（同样是「隐藏信息不进目标面」这条判据的落点），不新造风格。

**不动 `EffectScope` / `TriggerFilter` 两处的 `IncludeFaceDown`：** 它们纯服务端求值、不经视图，日后真要写「揭示 / 清除一张埋伏」，走 `EffectScope`（随机 / 全部，无 `TargetRef`）即可 —— 与「弃掉对手一张手牌走 `EffectScope`」逐字同构，也是隐藏信息上唯一诚实的形态（玩家指不了他看不见的东西）。

### 子项 3 — 揭示时刻的承接面：不加翻面态，由栈条目 + 战报承担（附带项）

`[既有推演]`

子项 1 之后必须回答一句：**对手的埋伏被触发时，玩家从哪里看到它是哪张。** 建议**不给战场条目加「已翻面 / 已揭示」态、不加任何字段**：

- 埋伏触发即压栈，其可观测面由既有两条承担 —— 该次触发的**栈条目**，以及 `CombatFeedEntry(Kind = AbilityTrigger)`（已带 `SourceId = abilityId` · `SourceInstanceId` · 双方 `MomentumDelta`）。这与「敌方启动的可观测性由飘字与战报承担」是同一条纪律。
- **仍缺一格数据源：** 把 `SourceInstanceId` 解析成「哪张牌」在对侧视角下没有解析通道（对侧的条目与手牌内容本就不在视图里）。建议 `StackEntryView` 带一格 **`SourceCardId`**，与 `PendingTargetRequest.SourceCardId` 逐字同构、对有卡牌来源的栈条目恒非空。**栈是完全公开面**（栈上的东西正在结算、逐步演出是硬要求），故这一格不需要条件填充。
- 顺带建议在文档里点一句：**`PendingTargetRequest.SourceCardId`（注释举例「埋伏·XX 需要一个目标」）不是泄漏面** —— 挂起三条与门的第 ② 条要求 `controllerSide == Character`，故该格恒为观察方己方的来源。不点这一句，它读起来像一处与本纪律相抵的例外。

### 子项 4 — `AmbushCount` 的定义按 `faceDown` 收口（不改名）

`[通行做法]`

把它的定义写作「该侧 **`faceDown == true`** 的战场条目计数」，而不是「次类型 `enchantment.ambush` 的条目计数」。当前两者同值（`faceDown` 只由埋伏产生），故这不是语义变更，只是把定义与子项 1 的过滤判据**逐字同源**：它是「被过滤掉了多少条」的唯一公开面，两处口径若各写各的，日后一旦出现一个非埋伏的面朝下条目，列表少一条而计数不变，且没有任何机制发现。

**不改名为 `FaceDownCount`：**「埋伏计数」已进 `ux/combat-ux.md`（必做项）与 `terminology.md`，改名的收益只是命名精确，代价是三处措辞连锁改动 + 玩家可见词汇分叉。

## 具体形态（可 derive 的落地面）

组装侧（伪码，落 `combat-service.md` 的 `CombatSnapshot` 小节）：

```
Battlefield(viewerSide) =
    battlefield
      .Where(e => !(e.faceDown && e.ownerSide != viewerSide))     // 对侧面朝下条目整条剔除
      .Select(e => new BattlefieldEntryView(
          …,
          FaceDown            = e.faceDown,                       // 剩下的 true 恒为己方埋伏
          ActivatableAbilities= e.ownerSide == viewerSide ? Availabilities(e) : []))

SideSnapshot(side).AmbushCount = battlefield.Count(e => e.faceDown && e.ownerSide == side)
```

契约面改动清单：

| 位置 | 改动 |
|---|---|
| `CombatSnapshot.Battlefield` | 注释 / 正文加一条填充纪律：**对侧 `faceDown` 条目不入列**（与 `ActivatableAbilities` 那条并列陈述） |
| `BattlefieldEntryView` | 保留 `FaceDown` 一格；文档写明「视图内 `FaceDown == true` ⇒ 该条目属 `ViewerSide` 己方」 |
| `SideSnapshot.AmbushCount` | 注释改为「该侧 `faceDown == true` 的战场条目计数；对侧条目被 `Battlefield` 剔除后，这是它唯一的公开面」 |
| `StackEntryView` | 须含 `SourceCardId`（子项 3；该视图字段面尚未成文，见前置依赖） |
| `deck/common-properties.md` 加载期校验表 | +1 行（子项 2） |
| `EntryFilter.IncludeFaceDown` 的纪律段 | 补一句：它同时是快照填充纪律的前提，放开前须回看本条 |

不变式（可在 Godot 编辑器内运行观察的断言形态）：

1. 任一时刻的 `snapshot.Battlefield` 中，`FaceDown == true` 的条目其 `OwnerSide == snapshot.ViewerSide`。
2. `snapshot.Battlefield.Count(e => e.OwnerSide == s)` + `snapshot[s].AmbushCount`（`s != ViewerSide` 时）= `ActiveCombat` 中该侧的战场条目总数。
3. 同一局面下取两个 `ViewerSide` 各组装一次，两份 `Battlefield` 的并集 = 全量条目集，交集 = 双方全部**面朝上**条目。

## 后果

- **存档面零影响。** `ActiveCombat` 保留全量真值（`faceDown` 字段原样），本条只约束视图 —— 无 schema bump、空迁移。
- **双视角缓存不受影响。** 两份缓存本就按 `ViewerSide` 分别持有、同一次组装产出，过滤在各自那次组装内完成，不新增结构、不落热路径分配面。
- **`Battlefield.Count` 不再等于场上条目总数。** 凡想按列表长度算「场上有几个条目」的消费者须改读 `AmbushCount` 补齐；**当前无此消费者**（AI 的 term 清单与 UX 的战场区都是按 `OwnerSide` 分区渲染的）。这条须写进文档，否则日后有人把列表长度当总数用。
- 文档改动：`systems/services/combat-service.md`（主要）· `systems/character-profile/deck/common-properties.md`（校验表 +1 行、`IncludeFaceDown` 纪律补一句）· `ux/combat-ux.md`（已与本方案一致，只需在「对手侧只汇总进埋伏计数」处补一句指向契约面的回链，**不复述**）。
- `terminology.md` 无改动。

## 备选方案（已考虑并否决）

- **保留条目、内容格置空 / 置哨兵值** —— 泄漏防线从结构降为约定：内容格在类型上仍存在，每个消费者读 `sourceId` / `keywordId` / `amount` 前都要先判 `faceDown`，漏判无人发现；且与 `AmbushCount` 形成两个计数口径（列表也能数出来）。与「敌方视角下那份内容结构上不存在」这条既定理由正面相抵。
- **另立对侧专用条目视图（第二个 view 类型）** —— 与「`SideSnapshot` 单类型，不拆己方 / 对方」「不为 AI 另立第二个投影类型」两条既定形状相抵；ViewModel 与 AI 各多一条路径，两条会各自漂移。
- **保留条目但把 `EntryId` 也匿名化 / 哈希** —— 既无消费者（对侧条目不渲染、不可指定），又保留了两套读法，是上面两条缺点的并集。
- **改名 `AmbushCount` → `FaceDownCount`** —— 见子项 4。
- **只写散文纪律、不加子项 2 的加载期闸** —— 纪律的失效无机制发现，而它的失效方式（`LegalTargets` 里冒出一个视图里没有的 `entryId`）只会在内容侧真用了 `IncludeFaceDown` 的那一天暴露。

## 与既有决策的张力

**一处，轻。** `EntryFilter.IncludeFaceDown` 当初「保留字段、日后真有『揭示一张埋伏』这类效果时不必改 schema」的留白，在子项 2 之后对**目标面**收窄为「只能取己方」（`EffectScope` / `TriggerFilter` 两处不受限）。

- **为什么需要它松动：** 不加这条闸，本纪律就只是散文，而它的前提（对侧 `faceDown` 条目永不进 `LegalTargets`）一旦被内容侧打破，视图与目标面会不一致。
- **松动的代价：** 若用户日后确实想要「点选对手的一张埋伏」这种玩法，本填充纪律须**整条重议**（对侧条目要重新入列，即回到置空或另立视图那两条路）。
- **不松动时的替代：** 该玩法走 `EffectScope`（随机 / 全部），玩法上等价于「揭示对手一张随机埋伏」—— 而在隐藏信息上，「随机选」本就是唯一诚实的形态（与「弃掉对手一张手牌」同款）。

## 前置依赖

- **`BattlefieldEntryView` 与 `StackEntryView` 的完整字段面此前未成文**（`inbox/archive/solution-draft-activate-ability-contract.md` 已登记同一缺口：「`BattlefieldEntryView` 的完整字段面此前未成文，本稿只增一格；若该视图在别处被一次性定稿，须与本格合并」）。本稿的三格（`FaceDown` 保留 · 对侧过滤 · `StackEntryView.SourceCardId`）不依赖其余字段即可定稿，但**落笔时宜与这两个视图的一次性成文同批**，否则文档里会留下「只写了三格的视图」。
- **己方埋伏在战场区逐条渲染还是折叠成一格**（归竖屏分区专场）—— 它消费 `FaceDown` 这一格，但**不改**本纪律，不构成阻塞。

## 仍需用户决定

**1 项。**

1. **取「整条不入列」这条第三路。** 待答项原文只并列了两条（内容格置空 / 哨兵值、另立对侧专用条目视图），本稿的推荐不在其中，故请点头确认走向。
   - **选项 A（推荐）：** 对侧 `faceDown` 条目整条不入 `Battlefield`，公开面由 `AmbushCount` 承载。
     后果：泄漏面在类型层被结构消除（与手牌同档）；`Battlefield.Count` 不再等于场上条目总数（当前无消费者，需写进文档）。
   - **选项 B：** 入列但内容格置空 / 哨兵值。
     后果：列表长度与真实条目数一致；代价是每个消费者读内容格前须先判 `faceDown`，防线降为约定，且与 `AmbushCount` 形成两个计数口径。
   - **选项 C：** 另立对侧专用条目视图。
     后果：类型层最显式；代价是与「单一列表 / 单类型、不拆己方对方」「不为 AI 另立第二个投影」两条既定形状相抵，ViewModel 与 AI 各多一条路径。
   - **推荐 A 的理由：** 本库对同款问题（手牌内容 · 可用道具 · 启动可供性）三次都取了「对侧那份内容结构上不存在」，A 是三条路里唯一与之同型的；且 `AmbushCount` 早在 08-05 就是按「给计数而非条目列表」定下来的，A 只是把当时没写完的另一半补上。
   - → **已裁决（2026-09-03 · 批量评审）：选项 A —— 对侧 `faceDown == true` 条目整条不入 `Battlefield`，公开面由 `AmbushCount` 承载。** `Battlefield.Count` 不再等于场上条目总数这一点须随提炼写进文档。

**同批按标准默认采纳（非取向项，未出题）：** 上节「与既有决策的张力」中 `EntryFilter.IncludeFaceDown` 对**目标面**收窄为「只能取己方」（子项 2 的加载期闸）按本稿建议直接落笔——它与同表既有的 `HandCard + IncludeFaceDown → PushError` 逐字同构，且有明确替代路径（该玩法走 `EffectScope` 随机 / 全部）。
