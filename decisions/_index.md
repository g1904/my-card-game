# 决策台账（ADR，客户端）

已敲定的方向性决策。**最新置顶。**

| id | 标题 | 状态 | 日期 | 影响文档 |
|---|---|---|---|---|
| [ADR-0132](ADR-0132-stack-entry-kind-used-item.md) | 用道具的栈条目自成一员 `StackEntryKind.UsedItem`，栈条目增 `itemId` | Accepted | 2026-08-30 | systems/services/combat-service.md, systems/character-profile/deck/common-properties.md |
| [ADR-0127](ADR-0127-life-merged-into-lifespan.md) | `lifeTotal` 并入 `lifeSpan`：一条命、两个扣减来源，且完全显性 | Accepted | 2026-08-30 | systems/character-profile/life-span.md, systems/scoring.md, systems/balance.md, systems/services/plot-manager.md, systems/services/profile-service.md, systems/adventure-event/research/_index.md, ux/screen-flow.md, vision/pillars.md |
| [ADR-0126](ADR-0126-exchange-barter-payment.md) | Exchange 支付侧二选一：货币，或一件点名的轮回级法宝 | Accepted | 2026-08-30 | systems/adventure-event/exchange/_index.md, exchange/common-properties.md, systems/services/profile-service.md, systems/common-properties.md, ux/screen-flow.md |
| [ADR-0125](ADR-0125-no-binary-over-overlay.md) | 二进制资产不经 overlay / blob 通道下发；指向恒落在随包基线内 | Accepted | 2026-08-30 | systems/common-properties.md, systems/services/content-service.md, art/visuals/_index.md |
| [ADR-0124](ADR-0124-artwork-single-slot-realm-override.md) | `Artwork` 基数恒为单格；境界覆写只落 `CharacterData.RealmArtworks` | Accepted | 2026-08-30 | systems/common-properties.md, systems/character-profile/_index.md, systems/viewmodel.md, art/visuals/art-direction.md |
| [ADR-0123](ADR-0123-affinity-technique-learning-gate.md) | 灵根与功法属性：唯一的规则后果是硬性修习准入 | Accepted | 2026-08-30 | systems/character-profile/_index.md, systems/character-profile/deck/_index.md, systems/adventure-event/research/common-properties.md, systems/services/future-event-service.md, systems/player-profile/codex/technique-codex.md, terminology.md |
| [ADR-0122](ADR-0122-batch-layer-inventory-commit-and-trace.md) | 批次层储物袋操作不是决策点而是一次即时提交；补两列与 `pastItemUse` 序列 | Accepted | 2026-08-28 | systems/services/profile-service.md, systems/character-profile/_index.md, systems/character-profile/item/_index.md, systems/services/sync-service.md, systems/architecture.md |
| [ADR-0121](ADR-0121-item-use-effect-face-by-world.md) | `ItemData` 使用效果面按世界分两格，移除 `Abilities`，新增 `MaxUsesPerCombat` | Accepted | 2026-08-28 | systems/character-profile/item/_index.md, systems/services/profile-service.md, systems/character-profile/power/_index.md, systems/architecture.md |
| [ADR-0120](ADR-0120-content-artwork-and-enemy-lines.md) | 插画引用升为顶层共有字段 `Artwork`；敌人台词落 `Lines`，不开音效字段 | Accepted | 2026-08-28 | systems/common-properties.md, systems/enemies/common-properties.md, systems/enemies/_index.md, systems/viewmodel.md |
| [ADR-0119](ADR-0119-move-card-drawpile-insert-position.md) | 牌可经 `MoveCard` 回抽牌堆顶 / 底（`InsertPosition`），插入位不掷随机 | Accepted | 2026-08-27 | systems/character-profile/deck/_index.md, systems/services/combat-service.md, deck/common-properties.md |
| [ADR-0118](ADR-0118-deck-operation-card-pool-draw.md) | `DeckOperation` 走池抽只对 `AddLooseCard` 开放；取池链沿用商店 `Card` 族、物化时掷定 | Accepted | 2026-08-27 | systems/adventure-event/common-properties.md, systems/services/future-event-service.md, systems/character-profile/deck/_index.md |
| [ADR-0117](ADR-0117-chapter-retry-limit-carrier.md) | 重试上限不新增存档结构，读 `PlayerEntitlement` 选行；载体收为 `ChapterRetryLimitsData` | Accepted | 2026-08-27 | systems/balance.md, systems/services/life-cycle-service.md, systems/monetization.md |
| [ADR-0116](ADR-0116-capability-flag-and-modifier-shape.md) | `CapabilityFlag` 取扁平枚举 + 正向三词表命名；modifier 合并「同层求和 → 只乘一次 → 只取整一次」 | Accepted | 2026-08-27 | systems/services/profile-service.md, systems/player-profile/player-power/common-properties.md, systems/architecture.md |
| [ADR-0115](ADR-0115-ability-effect-primitive-grammar.md) | 效果原语语法：一原语一子类，`StaticModifierData` 并列第二定义体，流水线五阶段 | Accepted | 2026-08-27 | systems/character-profile/deck/common-properties.md, deck/_index.md, systems/services/combat-service.md |
| [ADR-0114](ADR-0114-activate-ability-service-contract.md) | 开 `ActivateAbility`；代价面拆 `ManaCost` + `MaxActivationsPerCombat` 两格 | Accepted | 2026-08-26 | systems/services/combat-service.md, systems/character-profile/deck/common-properties.md, ux/combat-ux.md |
| [ADR-0113](ADR-0113-enemy-ai-weight-vector.md) | 敌人定制 AI 策略 = 权重向量的重新加权；1-ply、零随机、零记忆 | Accepted | 2026-08-26 | systems/enemies/_index.md, systems/enemies/common-properties.md, systems/services/combat-service.md, systems/balance.md |
| [ADR-0112](ADR-0112-combat-single-rng-substream.md) | 战斗两侧共用单一 `combat` 子流、不派生任何层；初洗按 `sides[]` 序 | Accepted | 2026-08-26 | systems/services/combat-service.md, systems/character-profile/deck/_index.md, systems/enemies/common-properties.md |
| [ADR-0099](ADR-0099-combat-holdings-two-tiers.md) | 战斗内持有物面板按「可操作 / 只读」分两层，不按数据归属分 | Accepted | 2026-08-26 | ux/combat-ux.md |
| [ADR-0098](ADR-0098-item-sell-two-channels.md) | 只有法宝可售；售出两条通道、回收率两档，随售档恒劣于商店档 | Accepted | 2026-08-26 | systems/character-profile/item/_index.md, systems/adventure-event/exchange/, systems/common-properties.md, systems/balance.md |
| [ADR-0097](ADR-0097-storage-pack-two-layer-view.md) | 储物袋是跨两个持久层的呈现视图，容量不设上限 | Accepted | 2026-08-26 | systems/character-profile/item/_index.md, systems/player-profile/player-item/_index.md, terminology.md |
| [ADR-0096](ADR-0096-codex-chain-unlock.md) | 收录一个敌人即收录其全部功法词条；`eventEnd` 入账只收窄到两本 | Accepted | 2026-08-25 | systems/player-profile/codex/_index.md, codex/common-properties.md |
| [ADR-0095](ADR-0095-technique-codex.md) | 新增 `TechniqueCodex`；词条不列卡牌清单 | Accepted | 2026-08-25 | systems/player-profile/codex/_index.md, codex/technique-codex.md |
| [ADR-0094](ADR-0094-pre-combat-confirmation-page.md) | 图鉴战斗内一律不可查；事前知识集中在战斗前确认页，该页不构成决策点 | Accepted | 2026-08-25 | ux/screen-flow.md, systems/player-profile/codex/_index.md, ux/combat-ux.md |
| [ADR-0093](ADR-0093-information-through-encounter.md) | 「信息靠遭遇获得，不靠资源购买」升格为设计支柱 | Accepted | 2026-08-25 | vision/pillars.md |
| [ADR-0092](ADR-0092-enemy-ai-two-layer.md) | 敌人 AI = 通用兜底 + 挂 `EnemyData` 的模板级定制策略（不挂功法） | Accepted | 2026-08-25 | systems/enemies/_index.md, systems/services/combat-service.md |
| [ADR-0091](ADR-0091-technique-pool-gate.md) | `CultivationTechniqueData` 增必填 `Pool : CardPool`，两侧对称设闸 | Accepted | 2026-08-25 | systems/character-profile/deck/_index.md, systems/enemies/common-properties.md |
| [ADR-0090](ADR-0090-enemy-deck-from-techniques.md) | 敌方套牌由「功法 + 层数」展开；层数逐条固定，赋级只动 `baseMomentum` | Accepted | 2026-08-25 | systems/enemies/_index.md, enemies/common-properties.md, systems/character-profile/deck/_index.md |
| [ADR-0089](ADR-0089-two-tier-currency.md) | 轮回货币拆两层（灵石 / 仙玉）；计价币种由定价表格决定，两币不可兑换 | Accepted | 2026-08-25 | systems/character-profile/currency.md, systems/adventure-event/exchange/_index.md, terminology.md, systems/services/profile-service.md |
| [ADR-0088](ADR-0088-fatigue-as-stack-entry.md) | 疲劳改为入栈的一等条目：可被监听、可被响应、可被削减至 0 | Accepted | 2026-08-25 | systems/services/combat-service.md |
| [ADR-0087](ADR-0087-action-result-and-combat-feed.md) | 玩家动作统一返回 `ActionResult`；呈现事件统一为 `CombatFeedEntry` 流 | Accepted | 2026-08-25 | systems/services/combat-service.md |
| [ADR-0086](ADR-0086-lifo-resolution-and-combat-log.md) | 结算呈现 = 逐层 LIFO 弹栈；战报 `combatLog` 两视图，不上提为 `eventLog` | Accepted | 2026-08-25 | ux/combat-ux.md |
| [ADR-0085](ADR-0085-gesture-split-tap-versus-longpress.md) | 手势分工：可拖拽对象用点按开详情，不可拖拽对象用长按 | Accepted | 2026-08-25 | ux/combat-ux.md |
| [ADR-0084](ADR-0084-no-baked-in-translatable-text.md) | 插画内不得烧入承载可翻译语义的文字；装饰性符文 / 书法 / 印章豁免 | Accepted | 2026-08-25 | art/visuals/art-direction.md, art/visuals/_index.md, art/_index.md |
| [ADR-0083](ADR-0083-full-art-card-face.md) | 卡面 = 全幅插画，唯一文字是 `manaCost`；`Power` 战斗内以技能条目呈现 | Accepted | 2026-08-25 | ux/combat-ux.md, art/visuals/art-direction.md, art/_index.md |
| [ADR-0082](ADR-0082-itemized-combat-rewards.md) | 战后奖励改为逐项领取 / 跳过；领取进度成为决策点 D6 | Accepted | 2026-08-23 | systems/services/combat-service.md, ux/combat-ux.md |
| [ADR-0081](ADR-0081-hidden-stats-outside-combat.md) | 隐藏属性不是战斗内资源：战斗层既不读也不写它 | Accepted | 2026-08-23 | systems/services/plot-manager.md |
| [ADR-0129](ADR-0129-hidden-stat-direction-slot.md) | 隐藏属性推拉的方向落在 `HiddenStatGrant` 第三格，沿数值轴命名、无哨兵 | Accepted | 2026-08-22 | systems/architecture.md, systems/adventure-event/common-properties.md, systems/services/future-event-service.md, systems/balance.md |
| [ADR-0111](ADR-0111-event-count-limit-plot-immunity.md) | `eventCountLimit` 恒为内容侧定值：`PlotModulation` 不长第七格，overlay 仍可改 | Accepted | 2026-08-22 | systems/game-progression.md, systems/services/plot-manager.md, systems/adventure-event/travel/_index.md |
| [ADR-0110](ADR-0110-enemy-pool-chapter-scope.md) | 敌人池篇章框定 = `EnemyData.ChapterScope`，切叙事归属而非强度 | Accepted | 2026-08-22 | systems/enemies/_index.md, systems/enemies/common-properties.md, systems/services/future-event-service.md |
| [ADR-0080](ADR-0080-refresh-token-client-custody.md) | refresh token 归 `AuthManager` 私有；续期软信号不做任何本地时钟判断 | Accepted | 2026-08-22 | systems/services/account-service.md, ux/screen-flow.md, ux/error-and-blocking-ux.md |
| [ADR-0079](ADR-0079-flags-monotonic-fetch.md) | flags 收紧为「增大即拉、增大即应用」；护栏移到失败路径 | Accepted | 2026-08-22 | systems/services/content-service.md, systems/balance.md |
| [ADR-0078](ADR-0078-outcome-spec-reuses-profile-change-spec.md) | `OutcomeSpec` 复用 `ProfileChangeSpec`、只开放三列；能力授予恒 `Character` | Accepted | 2026-08-22 | systems/adventure-event/common-properties.md, systems/services/future-event-service.md |
| [ADR-0077](ADR-0077-encounter-tighten-increments.md) | `Tighten` = 五格带方向约束的增量；对 `Finale` 整档豁免、不落存档 | Accepted | 2026-08-22 | systems/services/plot-manager.md, systems/services/combat-service.md |
| [ADR-0076](ADR-0076-no-extra-defeat-consequences.md) | `Practice` / `Standard` 两档战斗失败不另加规则层的额外后果 | Accepted | 2026-08-22 | systems/adventure-event/combat/_index.md |
| [ADR-0075](ADR-0075-combat-counters-key-space.md) | `counters` 键空间只有 `<abilityId>[#<子名>]` 一种形态，子名须登记 | Accepted | 2026-08-22 | systems/services/combat-service.md, systems/character-profile/deck/common-properties.md |
| [ADR-0074](ADR-0074-balance-resource-is-the-only-config-layer.md) | 凡可调数值一律住平衡资源；本库不存在「服务配置」这一层 | Accepted | 2026-08-22 | systems/balance.md, systems/services/content-service.md |
| [ADR-0030](ADR-0030-singleton-content-registration.md) | 单例内容走既有泛型仓储进 ContentRegistry：`ISingletonContent` + `Single<T>()` | Accepted | 2026-08-22 | systems/services/content-service.md, systems/game-progression.md, systems/balance.md, content/_index.md |
| [ADR-0029](ADR-0029-plot-tree-single-baseline-package.md) | 剧本树不按篇章分包：整体随 `res://` 基线发布，更新走 overlay 文件级增量 | Accepted | 2026-08-22 | systems/services/plot-manager.md, systems/services/content-service.md |
| [ADR-0028](ADR-0028-upstream-echo-validation-scope.md) | 上行整键回声校验升为通则；受约束顶层键由写入表机械导出 | Accepted | 2026-08-22 | systems/services/sync-service.md, systems/player-profile/_index.md, systems/player-profile/account-info.md |
| [ADR-0027](ADR-0027-location-codex-vertex-unlock.md) | `LocationCodex` 显影粒度 = 顶点级解锁，连边是呈现层派生 | Accepted | 2026-08-22 | systems/player-profile/codex/_index.md, codex/common-properties.md, systems/adventure-event/travel/_index.md |
| [ADR-0026](ADR-0026-event-generation-weighting-pipeline.md) | eventOptions 生成 / 加权 = 十步管线；类型修正为乘性系数 | Accepted | 2026-08-22 | systems/services/future-event-service.md, systems/services/plot-manager.md, systems/game-progression.md, systems/adventure-event/common-properties.md |
| [ADR-0025](ADR-0025-finale-failure-is-character-death.md) | Finale 失败即角色终结；判定二值化，`WinMargin` 在该档退场 | Accepted | 2026-08-22 | systems/adventure-event/combat/_index.md, systems/game-progression.md, systems/services/life-cycle-service.md, systems/balance.md |
| [ADR-0108](ADR-0108-profile-readonly-projection.md) | 收口前重算走只读投影 `Project(spec)`：先算后提交，不新增第二个写入面 | Accepted | 2026-08-19 | systems/services/profile-service.md, systems/services/life-cycle-service.md, systems/architecture.md |
| [ADR-0073](ADR-0073-pickmany-shortfall-three-gates.md) | 候选短缺 = 加载期断言 + 取池期拦截 + 物化期降级；短缺不给玩家提示 | Accepted | 2026-08-19 | systems/adventure-event/research/common-properties.md, exchange/common-properties.md, systems/services/content-service.md |
| [ADR-0072](ADR-0072-setting-scope-criterion.md) | 设置项切分判据 = 这一项的正确取值是否取决于这台机器 | Accepted | 2026-08-19 | systems/player-profile/game-setting.md |
| [ADR-0071](ADR-0071-device-id-client-provisioned.md) | `deviceId` 由客户端生成落 `user://cache/`；文件内刻意不带 `accountId` | Accepted | 2026-08-19 | systems/services/account-service.md |
| [ADR-0070](ADR-0070-codex-entry-id-only.md) | `CodexEntry` 首批只有一格 `Id`；计数与首次解锁元数据全部不落 | Accepted | 2026-08-19 | systems/player-profile/codex/common-properties.md |
| [ADR-0069](ADR-0069-subrequirement-signoff-inheritance.md) | 子需求签核继承父 FR；唯一例外是 Open-questions 闸 | Accepted | 2026-08-19 | requirements/_index.md |
| [ADR-0023](ADR-0023-premium-entitlement-and-redemption.md) | 付费凭证 = `PlayerEntitlement` 两字段；购买段后端权威、兑现段客户端演算 | Accepted | 2026-08-19 | systems/monetization.md, systems/player-profile/_index.md, systems/services/sync-service.md, ux/screen-flow.md |
| [ADR-0128](ADR-0128-status-changes-assignment-column.md) | `ProfileChangeSpec` 增 `StatusChanges` 列：Status 规则字段的绝对置值 | Accepted | 2026-08-17 | systems/architecture.md, systems/services/profile-service.md, systems/services/life-cycle-service.md, systems/adventure-event/travel/common-properties.md, systems/adventure-event/explore/_index.md |
| [ADR-0109](ADR-0109-lifespan-cost-fixed-value.md) | `lifeSpanCost` 恒为非负整数定值：不带区间、不带公式，变异位共三个 | Accepted | 2026-08-17 | systems/adventure-event/common-properties.md, systems/balance.md, systems/services/future-event-service.md |
| [ADR-0068](ADR-0068-draw-primitives-two-levels.md) | 抽取原语只有两级；分界判据 = 这道过滤需不需要读 `Profile` | Accepted | 2026-08-17 | systems/services/content-service.md, systems/player-profile/player-power/_index.md |
| [ADR-0067](ADR-0067-element-carrier-three-tier-criterion.md) | 新施加语义按三级问法落点：新增一列 → 同列加 `Op` → 配表加一列 | Accepted | 2026-08-17 | systems/architecture.md, systems/services/profile-service.md |
| [ADR-0066](ADR-0066-lifespan-gain-outcome-side-only.md) | 寿元回复只走产出侧；`selectCost` 内 `LifeSpan` 收紧为非负，护栏用三道软闸 | Accepted | 2026-08-17 | systems/adventure-event/common-properties.md, systems/balance.md, systems/character-profile/item/_index.md |
| [ADR-0065](ADR-0065-finale-is-always-combat.md) | 全部 Finale 均为天劫战，不设非战斗形态的境界突破路径 | Accepted | 2026-08-17 | systems/adventure-event/combat/_index.md, systems/services/combat-service.md, systems/services/plot-manager.md |
| [ADR-0064](ADR-0064-explore-reveal-no-second-weighting.md) | Explore 真身分布不设第二套权重；Explore 定价自成一行、不由真身推导 | Accepted | 2026-08-17 | systems/adventure-event/explore/_index.md, systems/services/future-event-service.md |
| [ADR-0022](ADR-0022-research-build-panel.md) | Research 结算形态 = 复数决策槽的构筑面板 | Accepted | 2026-08-17 | systems/adventure-event/research/_index.md, research/common-properties.md, systems/character-profile/deck/_index.md |
| [ADR-0020](ADR-0020-event-transaction-discipline.md) | 事件的事务纪律：收口一次事务；事件内主动消费即时提交 | Accepted | 2026-08-17 | systems/adventure-event/common-properties.md, systems/services/profile-service.md, systems/adventure-event/exchange/_index.md |
| [ADR-0107](ADR-0107-account-identity-client-adoption.md) | 账号身份客户端承接：绑定列表只读投影、昵称客户端写后端判 | Accepted | 2026-08-16 | systems/player-profile/account-info.md, systems/services/account-service.md, ux/onboarding.md, ux/screen-flow.md |
| [ADR-0106](ADR-0106-ignores-protection-content-layer-only.md) | `IgnoresProtection` 只留两条硬准入、≈5%，完全落内容编排层不落代码 | Accepted | 2026-08-16 | systems/balance.md, systems/character-profile/deck/common-properties.md |
| [ADR-0063](ADR-0063-resource-elements-table.md) | 资源的钳制 / 终态 / modifier 准入统一查逐 element 的封闭表 `ResourceElements` | Accepted | 2026-08-16 | systems/services/profile-service.md, systems/architecture.md |
| [ADR-0062](ADR-0062-target-scope-split.md) | 目标与作用域分开建模、共用 `EntryFilter`；结算逐槽重检，部分 fizzle | Accepted | 2026-08-16 | systems/character-profile/deck/common-properties.md, systems/services/combat-service.md |
| [ADR-0061](ADR-0061-keyword-as-content-entry.md) | 效果关键字是内容层的注册表条目 `KeywordData`，不是呈现层文案简写 | Accepted | 2026-08-16 | systems/character-profile/deck/common-properties.md, terminology.md |
| [ADR-0060](ADR-0060-cross-boundary-shard.md) | 跨库承接立常驻分片 `open-questions/cross-boundary.md` | Accepted | 2026-08-16 | open-questions/cross-boundary.md, README.md |
| [ADR-0015](ADR-0015-plot-tree-data-shape.md) | 剧本树的数据形态：纯调制、两个内容类型、key points 每 arc 一条 | Accepted | 2026-08-16 | systems/services/plot-manager.md, systems/architecture.md, systems/services/content-service.md |
| [ADR-0059](ADR-0059-no-enemy-intent-telegraph.md) | 敌人的行动不作任何事前预告；可读性改由六条既有通道分工承担 | Accepted | 2026-08-15 | systems/adventure-event/combat/_index.md, systems/services/combat-service.md, ux/combat-ux.md |
| [ADR-0024](ADR-0024-in-app-purchase-channels-in-mvp.md) | 平台内购三渠道纳入 MVP | Accepted | 2026-08-15 | vision/scope.md, systems/monetization.md, ux/screen-flow.md |
| [ADR-0002](ADR-0002-adventure-event-taxonomy.md) | 修行事件分类法（五类） | Accepted | 2026-08-15 | systems/adventure-event/_index.md, systems/adventure-event/combat/_index.md |
| [ADR-0058](ADR-0058-content-instance-layer.md) | `content/` 与 `systems/` 平级（类 ↔ 实例）；条目直喂 blueprint，本层不定义字段 | Accepted | 2026-08-14 | content/_index.md, README.md |
| [ADR-0057](ADR-0057-common-properties-layering.md) | 共有属性的定义写在最小公共祖先，恰好一份；每个落点只写投影 | Accepted | 2026-08-14 | systems/common-properties.md, systems/_index.md |
| [ADR-0056](ADR-0056-two-layer-localization.md) | 语言分两层承载（翻译键 / `LocalizedText`）；封顶二值，未翻译即留空 | Accepted | 2026-08-13 | ux/error-and-blocking-ux.md, systems/common-properties.md |
| [ADR-0105](ADR-0105-singular-collection-field-naming.md) | 集合字段名与元素类型名一律单数，且这是一条跨边界通则 | Accepted | 2026-08-12 | systems/player-profile/_index.md, systems/character-profile/_index.md, systems/services/sync-service.md, terminology.md |
| [ADR-0055](ADR-0055-character-as-content-template.md) | 角色是有身份的内容条目 `CharacterData`，不是程序化生成的空白人 | Accepted | 2026-08-12 | systems/character-profile/_index.md, content/_index.md |
| [ADR-0054](ADR-0054-technique-as-deck-unit.md) | 功法是卡组的构筑单位；层数提升即整组替换 | Accepted | 2026-08-12 | systems/character-profile/deck/_index.md, terminology.md |
| [ADR-0053](ADR-0053-error-copy-client-owned.md) | 错误文案由客户端持有，键由后端 `code` 机械变换；`message` 永不进弹窗 | Accepted | 2026-08-12 | ux/error-and-blocking-ux.md |
| [ADR-0016](ADR-0016-hidden-stat-band-model.md) | 隐藏属性档位模型：一张档位表统一三个消费方，叙事挂档位不挂事件 | Accepted | 2026-08-12 | systems/services/plot-manager.md, systems/character-profile/_index.md, systems/balance.md |
| [ADR-0131](ADR-0131-upgrade-error-non-blocking.md) | `Upgrade` 类错误只在两处硬阻塞；缓冲闸门口径不变、只换文案与选项 | Accepted | 2026-08-11 | systems/services/sync-service.md, ux/error-and-blocking-ux.md, systems/architecture.md |
| [ADR-0130](ADR-0130-flags-third-override-layer.md) | `ContentEnabled` 增第三层覆盖来源 flags；overlay 不再是唯一热更层 | Accepted | 2026-08-11 | systems/services/content-service.md, systems/architecture.md |
| [ADR-0052](ADR-0052-no-reshuffle-fatigue.md) | 抽牌堆不重洗，抽空即疲劳；卡组规模两侧皆不设硬限 | Accepted | 2026-08-11 | systems/services/combat-service.md, systems/enemies/common-properties.md, systems/balance.md |
| [ADR-0019](ADR-0019-card-type-taxonomy-and-battlefield.md) | 卡牌类型五分、异能三分、永久物；战场划线判据 | Accepted | 2026-08-11 | systems/services/combat-service.md, systems/character-profile/deck/, terminology.md |
| [ADR-0007](ADR-0007-local-content-layer-and-overlay.md) | 内容载体形态：随包基线 + overlay 热更 + 云端版本校验 | Accepted | 2026-08-11 | systems/services/content-service.md, systems/services/plot-manager.md, systems/architecture.md, vision/scope.md |
| [ADR-0051](ADR-0051-grant-source-and-exclusive-source.md) | `SourceCode` 记账、`ExclusiveSource` 准入；`Source` 分野 = 谁组装出这条 element | Accepted | 2026-08-10 | systems/common-properties.md, systems/services/life-cycle-service.md |
| [ADR-0104](ADR-0104-immediate-flush-never-blocks.md) | `Immediate` flush 是尝试、闸门是状态，flush 失败绝不挡玩家 | Accepted | 2026-08-09 | systems/services/sync-service.md, ux/combat-ux.md, ux/error-and-blocking-ux.md |
| [ADR-0103](ADR-0103-sync-revision-cas-and-push-idempotency.md) | `revision` = 后端分配的账号级单调整数；上行走 CAS 三分支 + 幂等键 `pushId` | Accepted | 2026-08-09 | systems/services/sync-service.md, systems/architecture.md, systems/services/account-service.md, ux/screen-flow.md |
| [ADR-0050](ADR-0050-account-field-layering.md) | 账号级字段分规则层 / 统计计数层；元素键分野是它的投影 | Accepted | 2026-08-09 | systems/player-profile/_index.md, systems/services/profile-service.md |
| [ADR-0049](ADR-0049-power-fragment-finale-bound.md) | 道统残卷焊到 Finale 上；掷骰走与 `CycleSeed` 解耦的账号级 RNG | Accepted | 2026-08-09 | systems/player-profile/player-power/_index.md, systems/balance.md, systems/monetization.md |
| [ADR-0021](ADR-0021-past-event-trace-schema.md) | `pastEvent` 痕迹 schema：快照判据 + `PastEventEntry` + 未选项轻摘要 | Accepted | 2026-08-09 | systems/adventure-event/common-properties.md, systems/services/life-cycle-service.md, systems/services/sync-service.md |
| [ADR-0013](ADR-0013-discipline-enforceability-ladder.md) | 纪律的可执行化：四级阶梯 + 两条选级判据 | Accepted | 2026-08-09 | systems/architecture.md, systems/services/content-service.md, system-overview.md |
| [ADR-0102](ADR-0102-sync-buffer-gate-savepoint-scope.md) | sync 缓冲闸门的「存档点」口径 = 事件级存档点 | Accepted | 2026-08-06 | systems/services/sync-service.md, systems/services/life-cycle-service.md, ux/error-and-blocking-ux.md |
| [ADR-0101](ADR-0101-chapter-retry-counter-carrier.md) | 篇章重试计数归 `CharacterProfile.chapterRetry`，`attemptIndex` 派生层整层删除 | Accepted | 2026-08-06 | systems/services/life-cycle-service.md, systems/character-profile/_index.md, systems/common-properties.md |
| [ADR-0048](ADR-0048-consented-power-loss-ladder.md) | 法则不会被强制剥夺：只有自愿置换能真正移除；三级严重度阶梯 | Accepted | 2026-08-06 | systems/player-profile/player-power/_index.md, systems/character-profile/_index.md |
| [ADR-0047](ADR-0047-event-priority-single-axis.md) | `eventPriority` 是唯一选择约束轴：两档、服务独占置位、抬升写判据 | Accepted | 2026-08-06 | systems/services/future-event-service.md, systems/adventure-event/common-properties.md |
| [ADR-0046](ADR-0046-skip-channel-removal.md) | 跳过通道整体移除：一批 eventOptions 只有一次操作——择一进入 | Accepted | 2026-08-06 | systems/adventure-event/common-properties.md, systems/services/future-event-service.md |
| [ADR-0045](ADR-0045-life-span-single-value.md) | 寿元只跟踪 `lifeSpan` 单值：无上限字段、无上限截断 | Accepted | 2026-08-06 | systems/character-profile/life-span.md, systems/balance.md |
| [ADR-0044](ADR-0044-enemy-leveling-band.md) | 敌人赋级带 = 当前全局等级 `±2` 的对称带，无例外硬规则 | Accepted | 2026-08-06 | systems/balance.md, systems/services/future-event-service.md, systems/services/plot-manager.md |
| [ADR-0043](ADR-0043-travel-as-structural-gate.md) | 配额用尽即 Travel 以最高 `eventPriority` 出场；Travel 升格为结构性闸门 | Accepted | 2026-08-05 | systems/game-progression.md, systems/adventure-event/travel/_index.md |
| [ADR-0042](ADR-0042-location-flat-set-and-single-map.md) | location 是平坦内容条目集合 + 单份全局邻接表；三章共用同一张图 | Accepted | 2026-08-05 | systems/game-progression.md, systems/adventure-event/travel/_index.md, content/_index.md |
| [ADR-0041](ADR-0041-token-free-closed-card-set.md) | 不存在凭空生成的牌：一场战斗内的卡牌集合是闭集 | Accepted | 2026-08-05 | systems/character-profile/deck/_index.md, systems/services/combat-service.md |
| [ADR-0040](ADR-0040-art-audio-production-pipeline.md) | 美术 / 音频走三段流水线；设计库只承载 vision 与 guide，不承载产物 | Accepted | 2026-08-04 | art/_index.md, art/visuals/_index.md, art/soundtracks/_index.md |
| [ADR-0039](ADR-0039-stack-without-interaction-and-three-step-turn.md) | 借入 stack 但不借交互与优先权；回合固定三步 | Accepted | 2026-08-02 | systems/services/combat-service.md, vision/pillars.md |
| [ADR-0038](ADR-0038-experience-point-progression.md) | 等级成长走 `experiencePoint`；阈值曲线境界内递增、境界间重置量纲 | Accepted | 2026-08-02 | systems/game-progression.md, systems/balance.md |
| [ADR-0037](ADR-0037-codex-family-third-track.md) | 图鉴自成一族，是元进程的第三条积累线；只记解锁状态 | Accepted | 2026-08-01 | systems/player-profile/codex/_index.md, systems/player-profile/_index.md |
| [ADR-0018](ADR-0018-momentum-scoring-model.md) | 计分模型 = 道念；道念即胜负判据；失败按道念差 × `lossPerMomentum` 扣寿元 | Accepted | 2026-08-01 | systems/scoring.md, systems/services/combat-service.md, systems/character-profile/life-span.md |
| [ADR-0008](ADR-0008-service-hierarchy-vocabulary.md) | 五级层次词表；拆分轴 = 生命周期层 + 行为边界 | Accepted | 2026-08-01 | systems/architecture.md, systems/services/_index.md, program-overview.md |
| [ADR-0036](ADR-0036-decision-point-saves.md) | 事件过程按决策点落存档；非战斗四类的决策点只是可退出点 | Accepted | 2026-07-30 | systems/services/combat-service.md, systems/services/life-cycle-service.md |
| [ADR-0035](ADR-0035-mana-no-curve-model.md) | mana 不设曲线：每回合恢复至 `manaLimit`；上限由事件推拉 + 大境界 `+1` | Accepted | 2026-07-30 | systems/character-profile/mana.md, systems/balance.md |
| [ADR-0034](ADR-0034-global-level-ladder.md) | 全局等级序 1–22 连续；境界鸿沟由 `baseMomentum` 承载 | Accepted | 2026-07-30 | systems/game-progression.md, systems/balance.md |
| [ADR-0005](ADR-0005-knowledge-thin-reference-layer.md) | `.claude` 是工程层，对设计只做薄引用（含冲突裁决规则） | Accepted | 2026-07-30 | .claude/knowledge/*, .claude/rules/*, .claude/skills/* |
| [ADR-0033](ADR-0033-determinism-within-content-version.md) | 确定性边界只到同一 `contentVersion` 内；RNG 双字段持久化 | Accepted | 2026-07-27 | vision/scope.md, systems/common-properties.md, systems/services/content-service.md |
| [ADR-0032](ADR-0032-save-point-never-rewinds.md) | 断线降级总原则：绝不回退存档点；本地存档点与云端 push 解耦 | Accepted | 2026-07-27 | systems/services/sync-service.md, systems/services/account-service.md |
| [ADR-0012](ADR-0012-materialization-model.md) | 物化模型：模板 → 唯一物化点 → 定稿实例 | Accepted | 2026-07-27 | systems/architecture.md, systems/services/future-event-service.md, systems/adventure-event/common-properties.md |
| [ADR-0011](ADR-0011-api-contract-principles.md) | API 契约总则（八条，贯穿七个服务） | Accepted | 2026-07-27 | systems/architecture.md, systems/services/*.md, system-overview.md |
| [ADR-0006](ADR-0006-development-phase-order.md) | 开发顺序：框架 → 内容 → 平衡与体验 → 社交及其他 | Accepted | 2026-07-27 | vision/scope.md, systems/services/content-service.md, systems/monetization.md |
| [ADR-0031](ADR-0031-lifespan-budget-countdown.md) | 寿元是按境界递增的预算、按事件成本递减；归 0 即角色终结 | Accepted | 2026-07-25 | systems/balance.md, systems/services/plot-manager.md, systems/services/life-cycle-service.md |
| [ADR-0017](ADR-0017-capability-flag-and-modifier-pipeline.md) | 全局设定类效果 = capability flag + modifier pipeline 两条通道 | Accepted | 2026-07-25 | systems/player-profile/player-power/common-properties.md, systems/services/profile-service.md, systems/architecture.md |
| [ADR-0014](ADR-0014-plot-manager-inside-future-event-service.md) | PlotManager 隶属 future-event-service；eventOptions 唯一出口 | Accepted | 2026-07-25 | systems/services/plot-manager.md, systems/services/future-event-service.md, systems/architecture.md |
| [ADR-0010](ADR-0010-presentation-three-layer-split.md) | 展示层三层切分：Data / 运行时·存档 / ViewModel | Accepted | 2026-07-25 | systems/viewmodel.md, systems/architecture.md, systems/common-properties.md |
| [ADR-0009](ADR-0009-single-entry-points-and-orchestrator.md) | 两条唯一入口 + 一个编排顶点 | Accepted | 2026-07-25 | systems/architecture.md, systems/services/profile-service.md, systems/services/content-service.md |
| [ADR-0004](ADR-0004-realm-checkpoint-retry-model.md) | 境界存档 · 篇章重试模型 | Accepted | 2026-07-23 | systems/services/life-cycle-service.md, systems/game-progression.md, systems/monetization.md |
| [ADR-0003](ADR-0003-online-cloud-authority.md) | 强制在线 · 云端权威（含重账号） | Accepted | 2026-07-23 | vision/scope.md, systems/services/life-cycle-service.md, .claude/rules/state-save-rules.md |
| [ADR-0100](ADR-0100-art-direction-painterly-chinese-grimdark.md) | 美术方向 = 绘画感中式卡牌插画 × grimdark 仙侠 | Accepted | 2026-07-13 | art/visuals/art-direction.md, art/_index.md, vision/pillars.md, vision/references.md |
| [ADR-0001](ADR-0001-example.md) | 战斗 / 计分模型（示例，未定） | Proposed | 2026-07-12 | systems/scoring.md, systems/adventure-event/combat/_index.md |

**编号与后端库各自独立**：本库的 `ADR-0003` 与 `backend-design-documents/decisions/ADR-0003` 无关。引用另一侧的 ADR 一律写全路径。

## 状态词汇

- `Proposed` — 已提出，尚未采纳。
- `Accepted` — 已采纳，约束后续设计。
- `Superseded` — 已被取代（**本库通常直接改原 ADR，很少用此状态**）。

## 约定

**ADR 可自由编辑。** 软件开发尚未开始 —— 要改一个决定，就**直接改这份 ADR**，不必新开一个 ADR 去取代它，也不设 `supersedes` / `superseded-by` 字段。历史归 git。承 `.claude/rules/Context.md` 的「一切皆可改」与「活文档只保留最新设计」。

**本台账与 `decisions/` 的唯一写入者是 `/write-adr`。** 编号从现有最大值 +1 递增，**不回收、不重排**。唯一例外：用户裁决推翻某条既定决策时，`/analyze-new-ideas` 直接改写那份 ADR（改写既有决定，不新增编号）。

**台账绝不领先于事实。** 一条决策只有在**已经写进权威主题文档**（`vision/` · `systems/` · `art/` · `ux/`）之后才建 ADR。ADR 是它的索引与理由留档，不是它的替代品 —— 细节留在主题文档，ADR 里**回链而非复述**（与 ADR-0005 的副本判据同源）。

## ADR 形状

```markdown
# ADR-0001 — <决策标题>

- **状态：** Accepted
- **日期：** <YYYY-MM-DD>
- **来源：** handoffs/<id>.md

## 背景
<什么问题迫使我们做这个选择。>

## 决策
<我们选了什么。写成祈使句，含关键取值。>

## 理由
<为什么是它，而不是备选。引用主题文档的承重论证，不新造理由。>

## 备选方案
- <方案> — 否决理由。

## 后果
<它约束了什么、放弃了什么、哪些文档因此必须这么写。跨库的后果写全路径。>
```
