# S2 报告 — EventOption 完整物化字段清单

- library: `game-design-documents/`（客户端库 · 单库运行；问题整体属客户端侧，无跨库承接项）

## 草稿文件

`game-design-documents/inbox/solution-draft-event-option-materialized-fields.md`（`status: awaiting-review`）

## inbox/_index.md 待处理表应追加的行

> 该文件的「在办清单」表实际列头是 `文件 | status | 说明`（三列），不是技能第 6b 步描述的五列。按实际表格式给行；当前表体是 `*（空）*` 占位行，需被替换。

| `solution-draft-event-option-materialized-fields.md` | awaiting-review | `EventOption` 完整物化字段清单（物化判据 + outcome 定稿载体 + `lifeSpanCost` 定值 + `combatTier` 落点 + `Priority` 类型 + `PlotModulation` 复核）。评审 4 项取向后 `/analyze-new-ideas`。 |

## 依据构成

既有推演 5 项 · 通行做法 0 项 · 取向选择 4 项；张力 3 条（1 🔴 / 2 🟠）；前置依赖 5 条。

## 建议要点

- 清单用一条「物化判据」收口（① seeded RNG 掷定 ② 情境代入 ③ 物化时组装/变换），与既有快照判据是孪生两条。逐格核过后清单只缺两格。
- 缺口 A（唯一新增字段）：outcome / effect 定稿载体 `EventOutcomeSpec Outcome`。依据是硬冲突——`Source.EventOutcome` 定义为「从物化后的 EventOption 的 outcome 定义算出」，而十一字段无此格。
- outcome 权重全部在物化时固化；结算时只求值条件分支、不掷骰（两侧取值均已定稿）。
- `lifeSpanCost` = 定值（非负整数，物化取负）；区间与公式均被否决；运行期变异已有 `ModifierKey.LifeSpanCost` 一条通道。
- `combatTier` 两处都不加字段，走 `EventId` → 模板溯源（tier 是模板常量，非物化产物；呈现与履历本就要查模板取显示名）。
- `Priority` 保留 `int` + 断言 `∈ {0,1}`（塌缩为 bool 要连改三处含存档字段，保留成本为零）。
- `PlotModulation` 复核完成：六字段不变，并给出一条判据免除日后重复复核 ⇒ open-questions/04 的该条可移出。
- `PastEventEntry` 零新增字段；`EventOption` +1 格 ⇒ bump schema（空迁移）。

## 仍需用户决定（4 项）

1. outcome 定稿载体加不加（张力 ① 裁决）。A（推荐）加一格 `Outcome`、物化时掷定；B 不加、恒读模板结算时现掷（须接受可重掷 + overlay 下呈现/结算不一致 + 改写 Source 定义）。理由：A 是三条既有纪律的直接推演。
2. `combatTier` 落点。A（推荐）两处都不加、走 EventId 溯源；B 两处各加 `CombatTier?`（+2 格、须写成快照判据的明示例外、多一个「遮罩态不许读」的守点）；C 只在 PastEventEntry 上加（两处口径分叉）。
3. `lifeSpanCost` 是否给区间留风味旋钮。A（推荐）不留；B 允许 `[min,max]` 物化掷定（Band 0/1 不显示成本 ⇒ 玩家感知不到方差）。
4. Band 2 展示与 `LifeSpanCost` 修正的关系（张力 ② 裁决）。A（推荐）展示走只读 ApplyModifier 查询、施加点仍在 TryApply；B 施加点移到物化侧（引入「中途新获修正不生效」，而法则账号级永久持有）；C 维持现状（Band 2 会显示假账，不建议）。

## 与既有决策的张力

- ① 🔴 `systems/common-properties.md` 的 `Source.EventOutcome`（「从物化后的 EventOption 的 outcome/effect 定义算出」）与三处 resolver 注释（life-cycle-service.md:107、architecture.md:298、adventure-event/common-properties.md:148「读模板上的…定义」）互相矛盾，且 EventOption 无 outcome 格 ⇒ 今天两种读法都无法落地。建议松动那三处注释。
- ② 🟠 「一个 ModifierKey 只能有一个施加点」的判据是「是否需在施加前呈现给玩家」，而 LifeSpanCost 归入「不需要」；但 Band 2 明写如实展示精确扣减量正是施加前呈现 ⇒ 持有「寿元消耗 −20%」法则时显示假账。
- ③ 🟠 口径不对称：`PastEventEntry.EventType` 同样可溯源却存了一份，而本方案主张 tier 不存。建议明写理由（EventType 存的是呈现口径，Explore 时与真身不同；tier 无此分叉）。

## 前置依赖

1. 缺口 B —— `EncounterSpec` / `EnemyInstance` 的承载形态（同分片另一条待答项）。本方案不表态；但该项措辞偏窄：EncounterId 既定 = EventOption.InstanceId，且 Tier / TurnLimit / VictoryRule / FirstSide / RewardPoolId / BaseReward 全部物化定稿，今天一格都没有落点。子项 4 的 tier 结论在两种承载下都成立。
2. 效果关键字体系与目标规则（需专门 handoff）⇒ EventOutcomeSpec 的内部分解无法定稿。
3. ch1 数值标杆专场 ⇒ lifeSpanCost 取值、ExperienceGrade / HiddenStatGrade 映射值。
4. 结算进行中的派生实例如何落存档（= S3）⇒ 承载形态见 S3。
5. `Card` 族购买的入组 element 载体 ⇒ 单卡入组类 outcome 暂无 element 表达；不阻塞顶层结论。

## 与 S3 的交界（对派生实例做的假设）

1. 假定派生只改字段值、不改字段面（`with` 沿用同一 record，字段集合相同）。
2. 假定 `IsRevealed` / `ExchangeStock` / `RerolledCount` 三格仍留在 EventOption 上；若 S3 迁走，本清单相应减格，判据与其余结论不变。
3. 假定新增的 `Outcome` 不参与派生改写（揭示 / 重掷都不改它，`with` 时原样携带）。若 S3 主张揭示后换成真身 outcome，则与本方案冲突，需交叉裁决。
4. 不对派生实例的持久化时点 / 是否替换原实例作任何主张。
5. 共同 schema bump：本方案 bump 一次；若 S3 也改 EventOption 存档形态，应合并为同一次 bump，请 orchestrator 核对。

## 越界发现（只记录）

- 张力 ① 涉及的三处 resolver 注释文本，均在本分片写入面之外。
- 建议把「物化后敌人实例的类型形态」措辞扩为「EncounterSpec 的承载形态」（open-questions/02，不由 worker 改）。
- `inbox/_index.md` 在办清单表列头（三列）与技能第 6b 步描述（五列）不一致，建议以实际文件为准修技能文本。
- `profile-service.md` 的 ResourceElements 表中 `PowerFragmentFirstWin(chapter)` 行 Min 写「形态未定」，与「启动期断言覆盖 CostKey 全部成员」有潜在冲突（与本分片无关，仅记录）。
