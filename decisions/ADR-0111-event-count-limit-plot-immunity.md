# ADR-0111 — `eventCountLimit` 恒为内容侧定值：`PlotModulation` 不长第七格，overlay 仍可改

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-eventcountlimit-plot-modulation.md

## 背景

`PlotModulation` 已有六格调制位。地域事件容量上限 `eventCountLimit` 是否也该给剧本一格——「因为你煞气重，这片林子把你困住了」是一个自然的叙事诉求。同时它是配额闸门 Travel 抬 `eventPriority` 的判定输入，且与 `lifeSpanCost` 一同承担篇章时长的反推。

## 决策

**`eventCountLimit` 恒为内容侧定值，`PlotModulation` 的字段面维持六格，不加第七格。** `plot-manager.md` 的权力面逐条投影表新增一行「改 `eventCountLimit` / 地域配额 → 无字段」。

**落地面是零结构增量**：不新增字段 / 枚举 / 合并算子行 / 加载期校验，不 bump 存档 schema。校验形态也无新增——「内容作者根本写不出那个字段」，与 `eventPriority` 同款。

**「不可调制」只约束剧本层。** `EventCountLimit` 仍是一格普通内容字段，**overlay 照常可改**（location 恒启用、不受 flags 管辖，改值下次冷启动生效），「让人快点离开某个问题地域」这条运营通道不被封死。

判据、权力面投影表与替代表达通道 → `systems/game-progression.md`、`systems/services/plot-manager.md`。

## 理由

**开放它会打穿抬升判据 (b)（最重）。** 配额闸门 Travel 能通过 (b)（收窄条件必须由产出侧可确定判定、不读隐藏属性与剧本状态）的唯一理由是判定式只读一个计数器。若 arc 能推拉它，闸门触发时点就变成剧本状态的函数——一条煞气 arc 把某地域配额压到 1，即可在下一批把玩家整批锁进 `Priority = 1` 的 Travel。这是**借道内容字段完成一次约束置位**，(b) 由一条可机械核对的准入条件退化为一句纪律。

**落面判据直接判给约束面：** 新增物化字段是否跟着加调制格，判据是「落内容面 → 已有字段够用；落约束面或模板字段面 → 不加字段」。`eventCountLimit` 决定的不是「摆什么」，而是「还能摆几批」。

**三个相邻旋钮不能有两套纪律：** `TravelFullFanoutChance` · `BatchSizeWeights` · `eventCountLimit` 同族，都定玩家选择空间的形状，前两者已各自明写不得推拉。

**它会把时长旋钮的反推变成不可算的量：** 经验曲线的验收项直接建立在「一章事件总数」之上；配额若成为剧本进度的函数，反推只能按期望值算并接受方差——而旋钮精度正是那两张表存在的唯一理由。

## 备选方案

- **双向可调（剧本可推可拉配额）** — 否决：打穿抬升判据 (b)，见理由。
- **只许收紧（剧本只能压低配额）** — 否决：同样使闸门触发时点成为剧本状态的函数，(b) 一样不成立。
- **连 overlay 也一并封死** — 否决：那会连带关掉「线上让人快点离开某个问题地域」这条运营通道，而该通道与剧本层无关。

## 后果

- `systems/game-progression.md` 是配额语义的权威；`systems/services/plot-manager.md` 承载权力面投影行。
- 剧本仍能影响地域节奏，但**只能加速离开、不能延长停留**：`TypeWeights[Travel]` 抬高（软）· `EventWhitelist` · `LevelBias` / `EnemyPoolScope` / `Tighten`（压力升级，不动配额）。不对称是有意的——硬上限是对篇章时长预算的承诺。
- **失去的能力（如实记）：** 剧本无法表达硬性延长停留的叙事，只能软化为「这一段更凶 + 更容易出现某类事件」。
- 存档 / 迁移影响：无。
- 连带：`LocationMapData` 加 `ISingletonContent` 标记，图校验表删去手写份数检查、改回链通用单例校验 → `ADR-0030`。
