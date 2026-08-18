# Handoffs — Index

设计 handoff 的时间线日志。最新的置顶。每个 handoff 一个文件；可自由编辑 / 修正（非仅追加，历史归 git）。

**本文件是索引，不是台账**（`decisions/ADR-0005`）：每行只写日期 · 文件 · 一句话主题 · 状态 · 首要落点。
叙述、裁决、论据与**完整落点表**只活在 handoff 文件自身，索引不复述——
完整落点见各文件头的 `- distilled-to:`。要知道某次定了什么，点开它的文件。

| id | date | topic | status | distilled-to |
|----|------|-------|--------|--------------|
| [draw-pool-and-instance-shapes](2026-08-17k-draw-pool-and-instance-shapes.md) | 2026-08-17 | 抽取原语与物化实例形态收口：抽取只有两级（`DrawPool<T>` + `GrantPoolPicker`，分界 = 这道过滤要不要读 `Profile`）· 门面补 `TryPickReplacement` · 账号级 `ordinal` 一律先算后写 · `PoolScope` = 两个具名可空字段的内嵌 `Resource` + 四条加载期校验 · 敌人池归属收归单权威（专属条目**叠加而非替代**）· `EventOption` 加第 13 格 `Encounter`、`PastEventEntry` 加 `EnemyTraceRef` | distilled | `systems/enemies/_index.md` (+15) |
| [event-option-derived-persistence](2026-08-17j-event-option-derived-persistence.md) | 2026-08-17 | 结算中的 `EventOption` 派生实例收口：承载 = 新可空块 `activeEvent`（整份派生快照）+ 当前批具名载体 `eventOption`，当批原实例不动 · 写入走 `ProfileChangeSpec.EventStateChanges` · 零新增决策点 / 存档点类型 · 新增只读投影 `Project(spec)` 使「依更新后 profile 重算」与「收口是一次事务」并存 · 7 条读档校验与 RNG 同事务不变式 | distilled | `systems/character-profile/_index.md` (+8) |
| [event-option-materialized-fields](2026-08-17i-event-option-materialized-fields.md) | 2026-08-17 | `EventOption` 物化清单收口：立**物化判据**（seeded RNG / 情境代入 / 组装变换）与快照判据成孪生两条，据之补产出侧定稿载体 `OutcomeSpec`（物化时掷定、结算只选侧不掷骰、战利品恒不进）· `lifeSpanCost` 定值 · `combatTier` 两处都不加走 `EventId` 溯源 · `Priority` 保留 `int` + 断言 · `PlotModulation` 不扩字段并留一条判据 | distilled | `systems/services/future-event-service.md` (+8) |
| [profile-field-schema](2026-08-17h-profile-field-schema.md) | 2026-08-17 | 两层 Profile 字段面收口：两张只有形态列的完整字段表（23 + 15 行）· `CharacterProfile` 补五格 · 六 Codex 具名字段与 `CodexEntry` · 四类持有条目 record（键名 `powerId` / `itemId`）· **集合字段名恒为单数**（跨边界通则，触发后端白名单改名）· `contentVersion` 统一 `int` · `currentMana` 移入 `activeCombat` · `Realm` 登记与 `StatusFields` 补行 | distilled | `systems/character-profile/_index.md` (+9) |
| [element-carrier-gaps](2026-08-17g-element-carrier-gaps.md) | 2026-08-17 | element 层三缺口一次答定：先立「分列 / 加 `Op` / 配表加列」**三级判据**（六面核对 + 反判据），再据之落 `ChangeElement.ApplyOp` + `ElementSpec.AllowedOps` · `DeckChangeOp.AddLooseCard` · `ProfileChangeSpec.PlotElements`；连带登记 `Experience` / `Faith` / `MaleficQi` 三个 `CostKey` 成员与 `PlotArcState` | distilled | `systems/architecture.md` (+7) |
| [lifespan-restoration-paths](2026-08-17f-lifespan-restoration-paths.md) | 2026-08-17 | 非境界突破的寿元回复通道存在（回寿事件 / 回寿法宝 / 商店购入三通道，零结构增量）· 回寿**只走 outcome 侧**，`selectCost` 内 `LifeSpan` 取值域收紧为非负 · 回寿数字与 `selectCost` 同 Band 2 门控 · 护栏 = 三道软闸 + Travel 与能力条目两条禁令 | distilled | `systems/adventure-event/common-properties.md` (+10) |
| [finale-combat-only-and-hidden-stat-io](2026-08-17e-finale-combat-only-and-hidden-stat-io.md) | 2026-08-17 | 全部 Finale 均为天劫战（不设非战斗形态的境界突破路径）· 隐藏属性对五类事件输入与输出两侧全开（`VictoryRule` 仍是单字段）· 一份 `HiddenStatGrade` 胜负同施不套 `FailureRatio` · 剧情线不转入 Finale | distilled | `systems/adventure-event/combat/_index.md` (+4) |
| [exchange-mechanics-and-transaction-discipline](2026-08-17d-exchange-mechanics-and-transaction-discipline.md) | 2026-08-17 | Exchange 收口：不开第三个 resolver · 交易逐笔即时提交 · 库存物化时掷定 ·「族 × 稀有度」定价表 · 仅法宝可售出（新增 `Source.ExchangeSell`）· NPC / 势力为风味层。**两条全局纪律改写**：收口才是一次事务、`AppliedChange` = 本次事件的最终账 | distilled | `systems/adventure-event/exchange/_index.md` (+16) |
| [explore-reveal-mechanics](2026-08-17c-explore-reveal-mechanics.md) | 2026-08-17 | Explore 收口：真身分布 = 条目池涌现（三处不加字段）· 取池期「真身须同样 enabled」过滤 · resolver 按真身选取 · 揭示走全屏转场层、不给部分线索 | distilled | `systems/adventure-event/explore/_index.md` (+7) |
| [research-build-panel-and-deck-elements](2026-08-17b-research-build-panel-and-deck-elements.md) | 2026-08-17 | Research = 构筑面板（复数决策槽）· 操作六类闭合 · `ProfileChangeSpec` 增 `DeckElements` · `manaLimit` 下降改挂玩家自选风险档 | distilled | `systems/adventure-event/research/_index.md` (+10) |
| [travel-destination-and-status-change-elements](2026-08-17-travel-destination-and-status-change-elements.md) | 2026-08-17 | `EventOption` 增 `DestinationLocationId` · `ProfileChangeSpec` 增 `StatusChanges` 列（绝对置值）· 承重措辞改为「逐条按施加语义分列」 | distilled | `systems/architecture.md` (+8) |
| [plot-data-encoding](2026-08-16i-plot-data-encoding.md) | 2026-08-16 | 剧本树 = 纯调制 · `PlotArcData` + `PlotNodeData` 两个内容类型 · key points 每 arc 一条 · overlay 剧本例外的合并期双闸 | distilled | `systems/services/plot-manager.md` (+8) |
| [grant-source-assembler-criterion](2026-08-16h-grant-source-assembler-criterion.md) | 2026-08-16 | 授予来源判据钉为「谁组装」· `EventOutcome` 与 `CombatReward` 不合并 · `eventEnd` 单向组装校验 | distilled | `systems/common-properties.md` (+5) |
| [travel-mechanics-and-location-carrier](2026-08-16g-travel-mechanics-and-location-carrier.md) | 2026-08-16 | Travel 收口：出场 / 代价 / 换图口径 · `LocationData` + 单份 `LocationMapData` 载体与恒启用 | distilled | `systems/adventure-event/travel/_index.md` (+9) |
| [elements-modifier-pipeline-opt-in](2026-08-16f-elements-modifier-pipeline-opt-in.md) | 2026-08-16 | `Elements` 缺省不经 modifier pipeline · `ResourceElements` 表逐行 opt-in 且按符号分向 | distilled | `systems/architecture.md` (+9) |
| [account-identity-client-adoption](2026-08-16e-account-identity-client-adoption.md) | 2026-08-16 | 账号身份模型的客户端承接：AccountInfo 三字段 · account-service 四方法 · 绑定 UX | distilled | `systems/player-profile/account-info.md` (+9) |
| [cost-side-closure](2026-08-16d-cost-side-closure.md) | 2026-08-16 | 成本侧收口：钳制表 · 拒绝语义的残留消费点 · 遮罩下的成本展示 | distilled | `systems/services/profile-service.md` (+8) |
| [effect-keywords-and-targeting](2026-08-16c-effect-keywords-and-targeting.md) | 2026-08-16 | 效果关键字体系 · 目标与作用域切分 · 合法目标集与部分 fizzle | distilled | `systems/character-profile/deck/common-properties.md` (+5) |
| [cross-library-alignment-and-bridge-ledger](2026-08-16b-cross-library-alignment-and-bridge-ledger.md) | 2026-08-16 | 跨库失配收口（客户端侧）· 跨边界承接台账 | distilled | `systems/common-properties.md` (+12) |
| [design-audit-adjudication-and-hand-limit](2026-08-16-design-audit-adjudication-and-hand-limit.md) | 2026-08-16 | 体检 12 项逐条裁决 · 手牌上限 9 → 7 | distilled | `systems/balance.md` (+17) |
| [intent-removal-lifespan-cost-visibility-and-design-audit](2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md) | 2026-08-15 | 敌人意图整条移除 · 寿元成本按告警档展示… | distilled | `systems/adventure-event/combat/_index.md` (+15) |
| [event-type-collapse-and-batch-shape](2026-08-15c-event-type-collapse-and-batch-shape.md) | 2026-08-15 | 事件类型收为五类、批次形状与寿元定价归属 | distilled | `decisions/ADR-0002-adventure-event-taxonomy.md` (+40) |
| [monetization-entitlement-purchase-shape-and-scope](2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md) | 2026-08-15 | 商业化整体收口：付费凭证的存档表达 · 购买形态… | distilled | `systems/monetization.md` (+9) |
| [content-id-technique-shape-and-subtype-reset](2026-08-15-content-id-technique-shape-and-subtype-reset.md) | 2026-08-15 | 条目 id 定案 · 功法承载形态 · 次类型清单归零 | distilled | `content/_index.md` (+1) |
| [content-authoring-layer](2026-08-14c-content-authoring-layer.md) | 2026-08-14 | 内容创作层开张：`content/` 目录 + 三个内容技能 | distilled | `content/_index.md` (+4) |
| [claude-rules-design-content-thinning](2026-08-14b-claude-rules-design-content-thinning.md) | 2026-08-14 | `.claude/rules/*` 中设计性表述的边界判据 | distilled | `decisions/ADR-0005-knowledge-thin-reference-layer.md` (+3) |
| [common-properties-layering](2026-08-14-common-properties-layering.md) | 2026-08-14 | 共有属性的分层判据：定义在最小公共祖先，投影在各落点 | distilled | `systems/common-properties.md` (+12) |
| [translation-key-rollout-and-content-localization](2026-08-13-translation-key-rollout-and-content-localization.md) | 2026-08-13 | 翻译键的铺开纪律 与 内容条目的多语言形态 `Locali… | distilled | `ux/error-and-blocking-ux.md` (+4) |
| [cultivation-technique-deck-building](2026-08-12f-cultivation-technique-deck-building.md) | 2026-08-12 | 功法（cultivationTechnique）= 卡组的… | distilled | `terminology.md` (+17) |
| [ability-grant-draw-pool](2026-08-12e-ability-grant-draw-pool.md) | 2026-08-12 | 账号级能力授予的候选池与排重规则… | distilled | `systems/player-profile/player-power/_index.md` (+13) |
| [hidden-stat-bands-and-crossing-narrative](2026-08-12d-hidden-stat-bands-and-crossing-narrative.md) | 2026-08-12 | 隐藏属性的档位模型与跨档叙事… | distilled | `systems/services/plot-manager.md` (+14) |
| [identifier-singular-collapse](2026-08-12c-identifier-singular-collapse.md) | 2026-08-12 | 标识符单数收口：`CharacterItem` / `Ac… | distilled | `terminology.md` (+32) |
| [grant-source-per-kind-scope](2026-08-12b-grant-source-per-kind-scope.md) | 2026-08-12 | 授予来源 `Source` 从「封闭三值」改为按 `(Ki… | distilled | `systems/common-properties.md` (+7) |
| [error-copy-and-update-prompts](2026-08-12-error-copy-and-update-prompts.md) | 2026-08-12 | 玩家可见错误文案的归属 · 三条版本提示的呈现与去重… | distilled | `ux/error-and-blocking-ux.md` (+14) |
| [combat-turn-flow-fatigue-and-card-type-reduction](2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md) | 2026-08-11 | 战斗流程收口：先后手 · 无重洗与疲劳… | distilled | `systems/services/combat-service.md` (+11) |
| [contract-boundary-and-flags-client-side](2026-08-11b-contract-boundary-and-flags-client-side.md) | 2026-08-11 | 契约边界层的客户端侧承接：传输信封 · 错误码映射… | distilled | `systems/architecture.md` (+6) |
| [plot-content-localization](2026-08-11-plot-content-localization.md) | 2026-08-11 | 剧本内容本地化：撤销云端剧本服务，改由 content-s… | distilled | `systems/services/` (+19) |
| [ability-disable-replacement-and-player-statistics](2026-08-10c-ability-disable-replacement-and-player-statistics.md) | 2026-08-10 | 「本轮回禁用」与置换型剥夺一次收口；`PlayerStat… | distilled | `systems/character-profile/_index.md` (+18) |
| [grant-source-and-fragment-source-scoping](2026-08-10b-grant-source-and-fragment-source-scoping.md) | 2026-08-10 | 授予来源 `SourceCode` / `Source`… | distilled | `terminology.md` (+28) |
| [discipline-enforceability](2026-08-09e-discipline-enforceability.md) | 2026-08-09 | 纪律的可执行化：四级阶梯… | distilled | `systems/architecture.md` (+7) |
| [field-layering-merge-criterion-and-ordinal-naming](2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md) | 2026-08-09 | 账号级字段的两层通则、合并判据与 `Ordinal` 命名… | distilled | `systems/player-profile/_index.md` (+6) |
| [past-event-trace-schema](2026-08-09c-past-event-trace-schema.md) | 2026-08-09 | `pastEvent` 痕迹 schema… | distilled | `systems/adventure-event/common-properties.md` (+12) |
| [player-power-fragment-finale-bound-drop-chance](2026-08-09b-player-power-fragment-finale-bound-drop-chance.md) | 2026-08-09 | 道统残卷 / `PlayerPowerFragment`… | distilled | `terminology.md` (+8) |
| [sync-revision-cas-and-immediate-flush-nonblocking](2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md) | 2026-08-09 | `revision` 语义（服务端 CAS… | distilled | `systems/services/sync-service.md` (+7) |
| [combat-open-questions-mass-closure](2026-08-06d-combat-open-questions-mass-closure.md) | 2026-08-06 | 战斗待答清单的一次性收口… | distilled | `terminology.md` (+12) |
| [skip-channel-removal-priority-two-tier-and-location-codex-edges](2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md) | 2026-08-06 | 跳过通道整体移除 · eventPriority 两档定形… | distilled | `terminology.md` (+11) |
| [asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape](2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md) | 2026-08-06 | ch1 赋级带定为非对称 [−4, +2]… | distilled | `systems/balance.md` (+9) |
| [ch1-band-widening-cross-realm-crush-and-chapter-retry](2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md) | 2026-08-06 | ch1 赋级带放宽至 ±4 · 跨大境界默认碾压… | distilled | `systems/balance.md` (+9) |
| [location-fields-event-count-limit-and-skip-refill-closure](2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md) | 2026-08-05 | location 三字段建模… | distilled | `terminology.md` (+11) |
| [level-band-stack-save-and-token-free-deck](2026-08-05-level-band-stack-save-and-token-free-deck.md) | 2026-08-05 | 对手等级带 ±2 · 栈须落存档 · 埋伏进敌人卡池… | distilled | `systems/balance.md` (+9) |
| [mtg-loanwords-card-types-and-intent-snapshot](2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md) | 2026-08-04 | MTG 借词定名（第一批）· 卡牌类型六分… | distilled | `terminology.md` (+18) |
| [art-audio-library-scaffold](2026-08-04-art-audio-library-scaffold.md) | 2026-08-04 | 美术 / 音频设计库落位… | distilled | `art/**（新建 12 份）` (+7) |
| [battlefield-stack-hand-limit-and-power-item-naming](2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md) | 2026-08-03 | 战场与栈成为独立 manager · 满手不抽… | distilled | `terminology.md` (+13) |
| [intent-threshold-inversion-and-aggregate-intent](2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md) | 2026-08-02 | 意图阈值下移（完整意图=碾压专属）· 意图是回合级综合描述 | distilled | `terminology.md` (+6) |
| [stack-without-interaction-and-three-step-turn](2026-08-02b-stack-without-interaction-and-three-step-turn.md) | 2026-08-02 | stack 留下、交互与优先权去掉 · 三步回合结构 | distilled | `terminology.md` (+9) |
| [momentum-conversion-reward-structure-and-mtg-stack](2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md) | 2026-08-02 | 道念换算 · 奖励结构 · 战斗变体 · MTG stack | distilled | `terminology.md` (+10) |
| [abstraction-levels-combat-numbers-codex-family-and-monetization](2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md) | 2026-08-01 | 抽象层级命名 · 战斗数值骨架 · 图鉴族 · 商业化 | distilled | `terminology.md` (+18) |
| [momentum-scoring-lifespan-tuning-and-failure-payoff](2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md) | 2026-08-01 | 道念取代 life 成为胜负判据… | distilled | `terminology.md` (+15) |
| [combat-level-intent-and-decision-point-saves](2026-07-30b-combat-level-intent-and-decision-point-saves.md) | 2026-07-30 | 修行等级体系 · 意图三档揭示 · 决策点存档… | distilled | `terminology.md` (+12) |
| [claude-engineering-scope-enemy-manager-and-requirement-breakdown](2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md) | 2026-07-30 | `.claude` 定位定案… | distilled | `decisions/ADR-0005-knowledge-thin-reference-layer.md` (+20) |
| [service-api-contracts](2026-07-27b-service-api-contracts.md) | 2026-07-27 | 七服务的 API 契约… | distilled | `systems/architecture.md` (+7) |
| [content-gating-offline-resilience-and-rng-persistence](2026-07-27-content-gating-offline-resilience-and-rng-persistence.md) | 2026-07-27 | 内容放量开关 · 断线韧性 · RNG 持久化 · 开发路线 | distilled | `terminology.md` (+12) |
| [event-priority-skip-semantics-and-hotfix-scope](2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md) | 2026-07-26 | 事件优先级、跳过语义、热更范围与 player-profi… | distilled | `terminology.md` (+12) |
| [service-manager-hierarchy-and-content-pipeline](2026-07-25c-service-manager-hierarchy-and-content-pipeline.md) | 2026-07-25 | 服务 / 管理器两级层次 · 拆分轴定案… | distilled | `program-overview.md` (+9) |
| [event-cost-fields-capability-flags-and-service-hierarchy](2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md) | 2026-07-25 | AdventureEvent 成本 / 跳过字段… | distilled | `terminology.md` (+16) |
| [lifespan-service-refactor-and-legacy-cleanup](2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md) | 2026-07-25 | 寿元数值化 · 服务层重命名（+future-event-… | distilled | `terminology.md` (+11) |
| [docs-restructure-class-model](2026-07-24-docs-restructure-class-model.md) | 2026-07-24 | 设计文档重构 —— 类模型化（class-concept）… | distilled | `terminology.md` (+3) |
| [adventure-plot-hidden-stats-and-clarifications](2026-07-23-adventure-plot-hidden-stats-and-clarifications.md) | 2026-07-23 | AdventurePlot / 隐藏属性 + 一批玩法澄清 | distilled | `terminology.md` (+16) |
| [online-cloud-combat-and-meta-clarifications](2026-07-22-online-cloud-combat-and-meta-clarifications.md) | 2026-07-22 | 强制在线云端 + 战斗模型(life+mana)… | distilled | `scope.md` (+8) |
| [ux-flow-login-and-dev-order](2026-07-16-ux-flow-login-and-dev-order.md) | 2026-07-16 | 登录/主菜单 UX 骨架 + 账号在线存档 + 开发顺序 | distilled | `screen-flow.md` (+3) |
| [taxonomy-and-checkpoint-clarifications](2026-07-15b-taxonomy-and-checkpoint-clarifications.md) | 2026-07-15 | 分类法定案 + 存档/重试模型澄清 | distilled | `terminology.md` (+4) |
| [adventure-event-profiles](2026-07-15-adventure-event-profiles.md) | 2026-07-15 | Adventure Event 重命名 + 术语表… | distilled | `terminology.md` (+3) |
| [vision](2026-07-13.md) | 2026-07-13 | Vision handoff — 修仙 roguelike… | distilled | `pillars.md` (+4) |
| [example](2026-07-12-example.md) | 2026-07-12 | EXAMPLE — delete me | raw | — |

<!-- Add new rows at the top. status: raw | triaged | distilled -->
