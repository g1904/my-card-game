# architecture ↔ services/* 对账：层级词表跟真实承重走 + 三族机械修订

- id: 2026-09-02-architecture-services-reconcile
- date: 2026-09-02
- topic: systems/architecture.md · systems/services/_index.md · systems/services/profile-service.md · systems/services/life-cycle-service.md · systems/services/future-event-service.md · systems/services/content-service.md · systems/player-profile/game-setting.md · systems/balance.md · decisions/ADR-0008
- status: distilled
- distilled-to: systems/architecture.md, systems/services/_index.md, systems/services/profile-service.md, systems/services/life-cycle-service.md, systems/services/future-event-service.md, systems/services/content-service.md, systems/player-profile/game-setting.md, systems/balance.md, decisions/ADR-0008-service-hierarchy-vocabulary.md

## Intent（distilled）

一次针对 `systems/architecture.md` 与 `systems/services/*` 的系统性对账。它兑现了 `architecture.md` 自己登记的那项维护动作：上游的结构性投影会在下游各自演进后留下过期登记，需要一次整体核对而非逐次顺手修。本次逐条核出 18 处差异，其中一处是真正的设计面裁决，其余十七处是投影漂移、计数失真与台账缺行。

### 一、层级词表跟真实承重走（唯一的设计面裁决）

**第四 / 第五级不再是预留。** 效果施加已在下游三份主题文档中落成第四级 `EffectProcessor`（住 combat-service 的 `StackManager` 内）与第五级的效果 kind handler（一个 kind 一个）。层级表、`services/_index.md` 的层级小节与 `ADR-0008` 的层级表一并登记这两个现有实例。

**下沉判据的宿主口径改为「宿主恰一个（manager 或 module）」。** 判据管的是**调用入口是否唯一**，不是宿主住在第几层。

- **层级链允许跳过中间级。** `EffectProcessor` 的宿主是第二级 `StackManager`，中间不插 module。
- **不为迁就旧措辞造一层中间 module。** 那会是一个只被调用一次、无变体、纯为凑齐层数的部件——同时命中下沉三条反判据里的 ② 与 ③。
- **层数不封顶也不封底。** 层级词表约束的是「叫什么名字就意味着在第几层」，不是「每一层都必须被填满」。

**连带：`GrantPoolPicker` → `GrantPoolManager`。** 层级词表跟真实承重走的同一条：它已被登记为抽取原语的**第二级**、住在 profile-service 内，`Picker` 后缀不在词表内。

### 二、投影纪律：上游只留类型声明 + 回链，值留下游

`architecture.md` 的「共享核心类型」是**类型声明**的权威，逐行取值的权威在各服务文档——两侧本就各自写下过这条委派，本次让文件与自己的委派一致。

- **`ResourceElements` 的 15 行值注释从 `architecture.md` 删除**，只留 `ElementSpec` 声明 + 一行回链；逐行取值（15 行 × 8 列，含每行依据）唯一持有处是 `profile-service.md`。
- **`SettingFields` 的默认值同理**：唯一持有处是 `profile-service.md` 的 `SettingFields` 表；`architecture.md` 与 `game-setting.md` 只留字段名、类型、取值域与回链。
- **`StatusFields` 的取值域不在同一文件里写两遍**：表里一份即可，散文段落改为指回同文件的表。
- **存储分界图补上 flags 第三层与合并序 `flags > overlay > res://`**，只写落点与回链——三层覆盖来源的语义权威在 `content-service.md`。

### 三、计数与命名的机械修订

- **`ResourceElements` 是六列不是五列**（`Min` / `Max` / `DepletionDefeat` / `CostModifier` / `GainModifier` / `AllowedOps`），`architecture.md` 内三处失真一并订正。
- **终结原因里由资源表驱动的只有一项。** `LifeSpan` 是全表唯一带非 null `DepletionDefeat` 的行 ⇒ **只有 `LifeSpanExhausted` 由表驱动**；`Discarded`（主动弃置）与 `FinaleFailed`（篇章闸门）在表里都没有行，各走终态判定上的一条显式旁路。`architecture.md` 与 `life-cycle-service.md` 两处同款措辞一并订正。**「终结原因恰三种」这一事实不变**，改的只是「其中几项由表驱动」。
- **`PlotThresholdReached` 的第三格统一为 `int BandIndex`**（`architecture.md` 与 `future-event-service.md` 两处上游残留同步到权威 `plot-manager.md`）。

### 四、台账与过期登记

- **`architecture.md` 的 `## 决策(-> ADR)` 按 `decisions/_index.md` 的落点列全量补齐 12 条**（0015 / 0017 / 0063 / 0067 / 0103 / 0116 / 0121 / 0122 / 0128 / 0129 / 0130 / 0131）。判据取「落点列是否包含本文件」——现成、双向可机械核对；换成「只补承重的几条」，会让「哪些算承重」变成每次新增 ADR 都要重答一次的问题。
- **删除四处已过期的登记**：`ADR-0002` 的「待补订 Explore / Travel」（该 ADR 已 Accepted 且两类各占正式一行）· 「剩余的结构性未决项」整句（三项均已在下游成文）· `profile-service.md` 的「`status` 与拥有 / 失去的存档表达」（两个正交维度的编码已完整成文）· `life-cycle-service.md` 里对 `plot-manager.md` 待答项的重复登记（收缩为回链）。
- **`ADR-0007` 的括注在两处对齐**（补「flags 三层覆盖」）。
- **`services/_index.md` 补一句 manager 级文档的形态明文**：内容量足够时可单列一份，仍住 `services/` 下，归属由服务清单表的 `⊃` 记法表达（现有唯一实例 `plot-manager.md`）。`architecture.md` 侧不动——它不负责逐份服务文档的索引。
- **`architecture.md` 与 `services/_index.md` 的服务 ↔ manager 表补 `CodexManager` 与 `GrantPoolManager`**，与 `profile-service.md` 的五行管理器表对齐。
- **`balance.md` 补一行 `BaseTypeWeights` 取值待定的登记**，消解 `future-event-service.md` 指向它的那处弱指向。

## Clarifications

- **第四 / 第五级的「无实例」登记与真实承重冲突，以哪一侧为准 → 以真实承重为准，改判据的措辞。** 用户裁决：「将文档的层面命名方式与承重对齐」。这推翻了 `architecture.md` 旧判据 3 「拆出后调用入口仍只有宿主 module 一个」中的**宿主必须是 module** 这一半，以及 `ADR-0008` 的「第四 / 五级保持空是健康的」。三份下游主题文档（combat-service · deck/common-properties · item/_index）的既定措辞**一字不动**。同一裁决消解了 `GrantPoolPicker` 的「改名 vs 移出管理器表」二选一，取改名。
- **`systems/character-profile/_index.md` 的 11 处 schema bump 自称是否本批改为回链 → 排除出本批次。** 用户裁决：其前置依赖（`sync-service.md` 的 bump 清单补齐漏项）未满足，先改回链会把一处可见的重复登记换成一处指向不全清单的错误指向，后者更难被下一次对账发现。该项保留为待办，与清单补齐同批处理。
- **「关闭后同步 `open-questions.md` 的判定表」这一建议 → 不执行。** 那几行全在「derive 就绪度」小节内，该小节由 `/assess-derive-readiness` 独占写入；刷新方式是择时重跑一次该技能。
- **`profile-service.md` 那条待答项该改写还是整条删除 → 整条删除。** 同文档已写死「失去 = 移出 `List<PlayerPower>`，不是置 `status = 禁用`」，编码本体在 `player-profile/_index.md` 的四条 record struct 中；两个正交维度均已成文，无剩余待答。
- **`Threshold → BandIndex` 属残留同步而非命名取向**（该改名在既有定案中已确定），故不出题、直接落笔。

## Open questions

- **plot 分支揭示 / 选择、key point 推进是否走 EventBus？若走，事件名与负载形状为何。** `plot-manager.md` 只写「同样由宿主服务代为广播」，未给事件名与负载；`architecture.md` 的 EventBus 负载契约表亦无对应行。**不臆造事件名**。→ `systems/services/plot-manager.md`、`systems/architecture.md`。
- **`systems/character-profile/_index.md` 的 11 处 schema bump 自称改为回链**，须与 `systems/services/sync-service.md` 的 bump 清单补齐漏项同批处理。
- **`GrantPoolPicker` → `GrantPoolManager` 的全库改名尚未跑完**：本次只覆盖 `architecture.md` · `services/_index.md` · `profile-service.md` · `content-service.md`；其余活文档与两份 ADR 仍是旧名（清单见对应的待答条目）。
