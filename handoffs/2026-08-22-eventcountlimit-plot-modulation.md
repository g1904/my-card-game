# eventCountLimit 不可被剧本调制

- id: 2026-08-22-eventcountlimit-plot-modulation
- date: 2026-08-22
- topic: systems/game-progression · systems/services/plot-manager · systems/services/content-service
- status: distilled
- distilled-to: systems/game-progression.md, systems/services/plot-manager.md, systems/services/content-service.md

## Intent（distilled）

**一句话：`eventCountLimit`（地域事件容量上限）恒为内容侧定值，`PlotModulation` 不长第七个字段。**

### 定案

- **配额对剧本关闭。** `PlotModulation` 的字段面维持六格（`TypeWeights` / `EventWhitelist` / `EventWeights` / `EnemyPoolScope` / `LevelBias` / `Tighten`），**不加 `EventCountLimitDelta` 一类的第七格**。`plot-manager.md` 的权力面逐条投影表新增一行「改 `eventCountLimit` / 地域配额 → 无字段」，与既有的「抬 `eventPriority`」「改模板字段」两行并列。
- **落地面是零结构增量。** 不新增字段 / 枚举 / 合并算子行 / 加载期校验；不 bump 存档 schema；不动 `LocationEventCount` 的任何语义；十步管线、闸门伪码、三条抬升条件逐字不动。**校验形态也无新增**——「内容作者根本写不出那个字段」，与 `eventPriority` 同款，不需要任何运行期检查。
- **「不可调制」只约束剧本层。** `EventCountLimit` 仍是一格普通内容字段，**overlay 照常可改**（location 恒启用、不受 flags 管辖，改值下次冷启动生效）。`travel/_index.md` 那条「把问题地域的配额压到 1 让人快速离开」的运营通道候选**保持开着**，日后独立定稿。`[采纳推荐 — 待复核]`

### 四条承重依据

1. **落面判据直接判给约束面。** 新增一格物化字段是否跟着加一格，判据是「落内容面（哪些条目进池 / 以什么权重出现 / 用哪个敌人池 / 带内赋级权重 / 遭遇参数）→ 已有字段够用；落约束面或模板字段面 → 不加字段」。`eventCountLimit` 决定的不是「摆什么」，而是「还能摆几批」——内容面清单没有一格覆盖它。**这条判据存在的全部目的就是让字段面不必随物化清单每次增长再逐格复核，本题是它的第一个真实用例。**
2. **开放它会打穿抬升判据 (b)（最重）。** 配额闸门 Travel 是三条准入抬 `eventPriority = 1` 的第一条，它能通过 (b)（收窄条件必须由产出侧可确定判定、不读隐藏属性与剧本状态）的唯一理由是判定式只读一个计数器。若 arc 能推拉 `EventCountLimit`，闸门触发时点就变成剧本状态的函数——一条煞气 arc 把某地域配额压到 1，即可在下一批把玩家整批锁进 `Priority = 1` 的 Travel。这是**借道内容字段完成一次约束置位**，(b) 由一条可机械核对的准入条件退化为一句纪律。
3. **三个相邻旋钮不能有两套纪律。** `TravelFullFanoutChance`（去哪能选几个）· `BatchSizeWeights`（一批摆几个）· `eventCountLimit`（这个地域还能选几批）同族，都定玩家选择空间的形状；前两者已各自明写「不得推拉 / 不接受任何覆盖参数」，理由逐字相同。第三个单独开口即三者两套纪律。
4. **它会把时长旋钮的反推变成不可算的量。** `eventCountLimit` 与 `lifeSpanCost` 必须一同反推目标时长，而经验曲线的验收项（「按标准路线走能在预算内升满」）直接建立在「一章事件总数」之上。配额若成为隐藏属性 / 剧本进度的函数，事件总数就成为玩家不可见、设计侧不可枚举的分布，反推只能按期望值算并接受方差——而旋钮精度正是这两张表存在的唯一理由。恒为定值 ⇒ 反推是一个算术问题。

### 替代通道：剧本仍能影响地域节奏，只能加速离开、不能延长停留

| 剧本想表达 | 已有表达位 | 形态 |
|---|---|---|
| 「这条线催着你赶路」 | `TypeWeights[Travel]` 抬高 | 软：Travel 更常出现在常规批，玩家提前走 ⇒ `LocationEventCount` 归 0 |
| 「这一段只出这条线的事件」 | `EventWhitelist` | 剧本强制性的唯一表达位 |
| 「这地方待久了越来越凶」 | `LevelBias` / `EnemyPoolScope` / `Tighten` | 压力升级，不动配额 |
| 「这个地域本来就待不久」 | `LocationData.EventCountLimit` 定值 | 内容阶段编排 |
| 「让人快点离开某个问题地域」 | 同上，走 overlay 改定值 | 运营通道，与剧本层无关 |

**不对称是有意的，也是这条取向的正面价值**：硬上限是对篇章时长预算的承诺，「更快赶路」最终仍由玩家点下去。`TypeWeights` 恒 `> 0` 且剧本侧不设 Travel 例外，故该通道也无法被反用来把 Travel 压没。

**失去的能力（如实记）：** 剧本无法表达「因为你煞气重，这片林子把你困住了，得多走几步才出得去」这类硬性延长的叙事，只能软化为「这一段更凶 + 更容易出现某类事件」。

### 连带承接：`LocationMapData` 的份数校验并入通用单例校验

同批定案的「单例平衡资源进 ContentRegistry」引入了标记接口 `ISingletonContent` 与合并后强校验里的通用条数检查（`条目数 != 1` → `PushError` + 抛）。据此：

- `LocationMapData` 加上 `ISingletonContent` 标记；
- `game-progression.md` 的图校验表**删去**「`LocationMapData` 存在多份 / 零份」这一行手写检查，改为回链 `content-service.md` 的通用单例条数校验。净减一条手写校验——逐份手写的形态里漏写一份就是一个静默的洞。

`[采纳推荐 — 待复核]`（该批决策的四项取向本身待用户复核）。

## Clarifications（interview 产物）

- **配额是否对剧本开放？** → **不可调制**（A0）。`PlotModulation` 不加第七字段。用户正式拍板，覆盖草稿中并列呈现的备选 A（双向可调）与备选 B（只许收紧）。
- **若选 A / B 时抬升判据 (b) 如何处置？** → 随上一条消解，为不成立的条件项。**抬升判据 (b) 保持原样，不松动。**
- **「不可调制」是否连 overlay 也一并封死？** → **否，只约束剧本层**（c-1）。`EventCountLimit` 仍是普通内容字段，overlay 照常可改。`[采纳推荐 — 待复核]`

## Open questions

- **「不可调制」只约束剧本层**这一项为 `[采纳推荐 — 待复核]`，仍留在待答清单待用户复核。
- 各 location 的 `EventCountLimit` 取值与「一章途经几个地域」归内容制作阶段 / ch1 数值标杆专场（既有待答项，不被本条阻塞）。
- 「失去 flags 关地域后的运营替代通道」（`systems/adventure-event/travel/_index.md`）仍独立待答；本条结论明写不封死它。

## Notes / triage

原始输入：`inbox/solution-draft-eventcountlimit-plot-modulation.md`（`/provide-solution-draft` 产物，用户已评审）。
存档 / 迁移影响：无（`LocationEventCount` · `CurrentLocationId` · `PlotKeyPoint` 全部不变）。
