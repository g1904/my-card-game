# Phase B 报告 — 分片 B：solution-draft-event-option-materialized-fields（波次 3/6）

目标库：`game-design-documents/`。未触碰后端库。`answers.md` 的 B-R1 / B-O1 / B-O2 / B-O3 / B-O4 / B-O5 与草稿评审已裁四项全部照裁决落笔；`PlotModulation` 按 E-R2 维持六字段（Phase A §3 第 ⑳ 条作废，未执行）。前两波硬边界一律未碰。

## 1. 改动文件逐条清单

| 文件 | 改了什么 |
|---|---|
| `handoffs/2026-08-17-event-option-materialized-fields.md` | **新建**（`distilled`，`distilled-to` 列 9 份活文档）；Intent 六节 + Clarifications 六条 + Open questions 两条 |
| `systems/services/future-event-service.md` | ① `EventOption` record 加第 12 格 `EventOutcomeSpec OutcomeSpec`，删行尾占位注释；② 物化小节新增**物化判据三条 + 反向硬边界**、**两条判据的分工**、**outcome 固化时点 + 三条理由**、**未选项白掷非新代价**、**物化后断言两条 + 不设 `Priority` 加载期校验**、日志形态；③ 新增 `OutcomeSpec` 顶层形态段：命名理由 + **结算走向映射表（5 行）** + **Combat 类产出边界**；④ 待决区删「完整物化字段清单未定」整条，替换为「`EventOutcomeSpec` 的内部字段面未定」 |
| `systems/adventure-event/common-properties.md` | ① 物化小节补判据（**回链**）+ 分工 + 产出侧载体；② resolver 注释 → 读定稿 `OutcomeSpec`；③ `PastEventEntry` 占位注释改写自己那一半，**保留敌人实例那一半**；④ 新增 `EventType` 存 / `combatTier` 不存的口径不对称理由；⑤ `lifeSpanCost` 补定值形态 + 三理由 + 三变异位 + Band 2 只读查询；⑥ `eventPriority` 补保留 `int` + 断言；⑦ 待决区**删 3 条** |
| `systems/architecture.md` | ① 总则 6 的 `EventOption` 副本加 `OutcomeSpec`（逐字一致）；② 总则 6 补物化判据一行摘要 + 回链；③ 总则 8 resolver 注释改写。**spec / element 代码块、三级判据段、`Realm` / `PlotArcState`、`StatusFields` 一字未动** |
| `systems/services/life-cycle-service.md` | resolver 注释改写（一处） |
| `systems/services/plot-manager.md` | ① `PlotModulation` 小节新增**「落内容面 / 落约束面」判据**段 + 逐格核过结论；② 待决区**删 1 条**。**六字段代码块与三处「六字段」措辞原样不动** |
| `systems/services/profile-service.md` | 「一个 `ModifierKey` 只能有一个施加点」判据下新增子条**「只读查询不构成施加点」**。**`ResourceElements` 表一字未动** |
| `systems/adventure-event/combat/_index.md` | ① 第 24 行改写为**两处都不加 + 四条正面理由**；② 待决区**删 1 条** |
| `systems/balance.md` | `lifeSpanCost` 定价表补「每格是定值，不设区间列」+ 理由；**不动取值** |
| `decisions/ADR-0002-adventure-event-taxonomy.md` | Consequences 尾部 `combatTier` 待办改写为**正面陈述**；待办只剩 Explore 揭示池权重 |
| `answer-logs/log-event-option-materialized-fields.md` | **新建**，4 条 + 两条部分答定说明 |

**未触碰**：`sync-service.md`（A 预写的 `EventOption` 行已核对无误）· 共享台账 · `open-questions*` · `inbox/`。溯源三条自查已跑（9 份）。

## 2. 台账素材

### 2a. `handoffs/_index.md` 新增行（置顶）
```
| [event-option-materialized-fields](2026-08-17-event-option-materialized-fields.md) | 2026-08-17 | `EventOption` 物化清单一次收口：立**物化判据**（seeded RNG / 情境代入 / 组装变换；文本类留模板）与快照判据成孪生两条，据之补上产出侧定稿载体 `OutcomeSpec`（抽取物化时掷定、结算只选侧不掷骰、按结算走向分侧、战利品恒不进）；连带定 `lifeSpanCost` 为定值 · `combatTier` 两处都不加走 `EventId` 溯源 · `Priority` 保留 `int` + 断言 · `PlotModulation` 不扩字段并留下一条判据 | distilled | `systems/services/future-event-service.md` (+8) |
```

### 2b. `open-questions/`

**条件移出 —— `02-event-options.md`「`EventOption` 的完整物化字段清单」整条删除。**
> ⚠ 前提：分片 E 确已答定缺口 B（`EncounterSpec` 承载）。E 落笔后由 orchestrator 确认再执行。若 E 未落地，只删三个分叉，条目收窄为：
```
- **`EventOption` 上 `EncounterSpec` 的承载形态。** 骨架已扩至十二字段（含产出侧 `OutcomeSpec`），物化判据已收口本条其余全部分叉；仍待定：`EncounterSpec`（`Tier` / `Enemy` / `TurnLimit` / `VictoryRule` / `FirstSide` / `RewardPoolId` / `BaseReward`）今天一格都没有落点。→ `systems/services/future-event-service.md`。
```

**收窄 —— `02-event-options.md`「`Priority = 1` 依什么条件抬升」**：删去「以及字段是否从 `int` 退化为 `bool`」，追加：
```
**字段形态已答定：保留 `int`，由物化组装后断言 `Priority ∈ { 0, 1 }` 兑现「让类型说实话」；不设加载期校验（`Priority` 从不是模板字段，无可实现的检出形态）。**
```

**移出 —— `04-hidden-attributes-plot.md`「`PlotModulation` 的字段面是否还需扩」整条删除**（答定为「不扩，维持六字段 + 一条判据」）。
> ⚠ 该条与 E 的 `EnemyPoolScope` 无关（interview 已裁定保留该字段），**只移一次**。

**新增 2 条（原文照写，落 `02-event-options.md`）：**
```
- **`lifeSpanCost` 一律定值 —— `[采纳推荐 — 待复核]`（08-17 新增 · 轻）。** 形态已定为非负整数定值（不带区间、不带公式），定价表因此不设区间列。否决区间旋钮的两条理由——Band 0 / Band 1 不显示 `selectCost` ⇒ 方差对玩家不可感知；区间会损害时长旋钮的反推精度——**成立与否待实测复核**。若复核推翻，改动面是模板侧两个字段 + 一次掷定 + 一条校验 + 定价表反推口径。→ `systems/adventure-event/common-properties.md`、`systems/balance.md`。
- **`EventOutcomeSpec` 的内部字段面（08-17 新增 · 承重）。** 顶层载体（`EventOption.OutcomeSpec`）、固化时点（抽取物化时掷定 / 条件结算时求值）、顶层按结算走向分侧（`OnResolved` / `OnFailure`）与结算走向映射表均已答定；仍待定：产出效果原语的表达、两侧各自的列、经验失败折算的数据形态。**阻于「效果关键字体系与目标规则」那条待答项**（`combat/_index.md`），本条只记依赖关系。→ `systems/services/future-event-service.md`。
```

### 2c. `update-log.md` 摘要素材
- 答结 4 条：物化清单收口方式 · outcome 权重物化时固化 + 新增 `OutcomeSpec` · `lifeSpanCost` 定值 · `PlotModulation` 不扩字段。
- 部分答定 2 处：`Priority` 只答定形态那一半；`combatTier` 落点连带改写 ADR-0002 尾部待办。
- 新增 2 条。
- 新落点：`future-event-service.md` 的物化判据段 + 结算走向映射表 + Combat 产出边界；`plot-manager.md` 的落面判据；`profile-service.md` 的「只读查询不构成施加点」。

### 2d. `answer-logs/_index.md` 新增行
```
| `log-event-option-materialized-fields.md` | 2026-08-17 | `inbox/archive/solution-draft-event-option-materialized-fields.md` → `handoffs/2026-08-17-event-option-materialized-fields.md` | 4 |
```

### 2e. `inbox/_index.md`
- 待处理表：删 `solution-draft-event-option-materialized-fields.md` 行。
- 已归档表新增：
```
| `solution-draft-event-option-materialized-fields.md` | solution-draft | 2026-08-17 | `handoffs/2026-08-17-event-option-materialized-fields.md` | `answer-logs/log-event-option-materialized-fields.md` |
```

### 2f. 草稿 frontmatter
```yaml
status: distilled
reviewed: 2026-08-17 —— 四项取向全部取推荐项 A（第 3 项 lifeSpanCost 定值标 [采纳推荐 — 待复核]）；合并 interview 另裁定：不抄 EventOutcomeSpec 的内部形态（不写 int FailureRatio / HiddenStatPush / ReplacementOffer，既有 0.5 比率口径不动）、字段名取 OutcomeSpec、明写结算走向映射表与 Combat 产出边界、删掉不可实现的 Priority 加载期校验、PlotModulation 维持六字段、顺手改写 ADR-0002 尾部的 combatTier 待办
distilled-to: handoffs/2026-08-17-event-option-materialized-fields.md
```

## 3. 越界发现

1. `architecture.md` 第 493 行附近残留已删除的 `AdvanceMode`（`mode = Select | Skip`）——跳过通道与该枚举已整体移除，属漏改的考古残留。
2. `future-event-service.md` 的「物化产出的数值必进快照」一句未列 `OutcomeSpec`（它按快照判据不进快照），并列不冲突但可能被误读。
3. `profile-service.md` 待决区首条的括注仍写「隐藏属性推拉？」（D 已点名，仍未改）。
4. `.claude/knowledge/systems/*` 引用层多处标「待建」，归 `/sync-knowledge`。

## 4. 交给波次 5（分片 E）

### 4a. `EventOption` record 落笔后原文（12 格 · 勿重写既有各格）
两处必须逐字一致：`future-event-service.md` 与 `architecture.md` 总则 6。

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板：ContentRegistry.Get<AdventureEventData>(EventId)
    EventType          EventType,                 // Explore 时 = Explore 本身；真身见 RevealedEventId
    int                Priority,                  // 物化时置位；取值域 { 0, 1 }
    ProfileChangeSpec  SelectCost,                // 物化时组装：内容侧正数量值 → 取负填入 BaseValue
    bool               IsRevealed,                // Explore：是否已揭示
    string             RevealedEventId,           // Explore 遮罩的固定事件
    string             DestinationLocationId,     // Travel 的目的地；非 Travel 为空串
    IReadOnlyList<ResearchSlot> ResearchSlots,    // Research 的决策槽（候选已掷定）
    IReadOnlyList<ExchangeOffer> ExchangeStock,   // Exchange 的定稿库存
    int                RerolledCount,             // Exchange 已刷新次数
    EventOutcomeSpec   OutcomeSpec                // 产出侧定稿载体：抽取 / 权重已掷定，结算时只选一侧
    );
```
**E 的动作**：`OutcomeSpec` 行尾补逗号，其下加第 13 格 `EncounterSpec Encounter`（可空）。**前 12 格任何一行都不要改。**

### 4b. `PastEventEntry` 占位注释当前措辞（`adventure-event/common-properties.md`）
```csharp
    /* 产出侧不带来痕迹侧扩充 —— 本次事件的最终账已在 AppliedChange 里；
        ⟨随「敌人实例类型形态」答定后扩充；文本类字段不在扩充范围内 —— 风味文案跟随模板⟩ */);
```
**E 的动作**：把第二行的 ⟨…⟩ 改写为实字段 `EnemyTraceRef Enemy`，**保留第一行**。

### 4c. 其它执行状态
- `sync-service.md` bump 表的 `EventOption` 行已由 A 预写「增两格」，B 已核对，**E 无需再改该表**。
- `terminology.md`：B 未触碰（location 词条归 E）。
- `plot-manager.md`：B 只在 `PlotModulation` 小节新增判据段并删 1 条待决项；六字段代码块、调制通道表述、「剧情线 boss」段**全部原样保留**，E 改 `EnemyPoolScope` 注释与悬空校验不冲突。
- `combat/_index.md`：「效果关键字体系与目标规则」那条待决项保留未动。
