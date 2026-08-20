# 决策台账（ADR，客户端）

已敲定的方向性决策。**最新置顶。**

| id | 标题 | 状态 | 日期 | 影响文档 |
|---|---|---|---|---|
| [ADR-0023](ADR-0023-premium-entitlement-and-redemption.md) | 付费凭证 = `PlayerEntitlement` 两字段；购买段后端权威、兑现段客户端演算 | Accepted | 2026-08-19 | systems/monetization.md, systems/player-profile/_index.md, systems/services/sync-service.md, ux/screen-flow.md |
| [ADR-0022](ADR-0022-research-build-panel.md) | Research 结算形态 = 复数决策槽的构筑面板 | Accepted | 2026-08-17 | systems/adventure-event/research/_index.md, research/common-properties.md, systems/character-profile/deck/_index.md |
| [ADR-0020](ADR-0020-event-transaction-discipline.md) | 事件的事务纪律：收口一次事务；事件内主动消费即时提交 | Accepted | 2026-08-17 | systems/adventure-event/common-properties.md, systems/services/profile-service.md, systems/adventure-event/exchange/_index.md |
| [ADR-0015](ADR-0015-plot-tree-data-shape.md) | 剧本树的数据形态：纯调制、两个内容类型、key points 每 arc 一条 | Accepted | 2026-08-16 | systems/services/plot-manager.md, systems/architecture.md, systems/services/content-service.md |
| [ADR-0024](ADR-0024-in-app-purchase-channels-in-mvp.md) | 平台内购三渠道纳入 MVP | Accepted | 2026-08-15 | vision/scope.md, systems/monetization.md, ux/screen-flow.md |
| [ADR-0002](ADR-0002-adventure-event-taxonomy.md) | 修行事件分类法（五类） | Accepted | 2026-08-15 | systems/adventure-event/_index.md, systems/adventure-event/combat/_index.md |
| [ADR-0016](ADR-0016-hidden-stat-band-model.md) | 隐藏属性档位模型：一张档位表统一五个消费方，叙事挂档位不挂事件 | Accepted | 2026-08-12 | systems/services/plot-manager.md, systems/character-profile/_index.md, systems/balance.md |
| [ADR-0019](ADR-0019-card-type-taxonomy-and-battlefield.md) | 卡牌类型五分、异能三分、永久物；战场划线判据 | Accepted | 2026-08-11 | systems/services/combat-service.md, systems/character-profile/deck/, terminology.md |
| [ADR-0007](ADR-0007-local-content-layer-and-overlay.md) | 内容载体形态：随包基线 + overlay 热更 + 云端版本校验 | Accepted | 2026-08-11 | systems/services/content-service.md, systems/services/plot-manager.md, systems/architecture.md, vision/scope.md |
| [ADR-0021](ADR-0021-past-event-trace-schema.md) | `pastEvent` 痕迹 schema：快照判据 + `PastEventEntry` + 未选项轻摘要 | Accepted | 2026-08-09 | systems/adventure-event/common-properties.md, systems/services/life-cycle-service.md, systems/services/sync-service.md |
| [ADR-0013](ADR-0013-discipline-enforceability-ladder.md) | 纪律的可执行化：四级阶梯 + 两条选级判据 | Accepted | 2026-08-09 | systems/architecture.md, systems/services/content-service.md, system-overview.md |
| [ADR-0018](ADR-0018-momentum-scoring-model.md) | 计分模型 = 道念；道念即胜负判据；失败按道念差扣 lifeTotal | Accepted | 2026-08-01 | systems/scoring.md, systems/services/combat-service.md, systems/character-profile/life-total.md |
| [ADR-0008](ADR-0008-service-hierarchy-vocabulary.md) | 五级层次词表；拆分轴 = 生命周期层 + 行为边界 | Accepted | 2026-08-01 | systems/architecture.md, systems/services/_index.md, program-overview.md |
| [ADR-0005](ADR-0005-knowledge-thin-reference-layer.md) | `.claude` 是工程层，对设计只做薄引用（含冲突裁决规则） | Accepted | 2026-07-30 | .claude/knowledge/*, .claude/rules/*, .claude/skills/* |
| [ADR-0012](ADR-0012-materialization-model.md) | 物化模型：模板 → 唯一物化点 → 定稿实例 | Accepted | 2026-07-27 | systems/architecture.md, systems/services/future-event-service.md, systems/adventure-event/common-properties.md |
| [ADR-0011](ADR-0011-api-contract-principles.md) | API 契约总则（八条，贯穿七个服务） | Accepted | 2026-07-27 | systems/architecture.md, systems/services/*.md, system-overview.md |
| [ADR-0006](ADR-0006-development-phase-order.md) | 开发顺序：框架 → 内容 → 平衡与体验 → 社交及其他 | Accepted | 2026-07-27 | vision/scope.md, systems/services/content-service.md, systems/monetization.md |
| [ADR-0017](ADR-0017-capability-flag-and-modifier-pipeline.md) | 全局设定类效果 = capability flag + modifier pipeline 两条通道 | Accepted | 2026-07-25 | systems/player-profile/player-power/common-properties.md, systems/services/profile-service.md, systems/architecture.md |
| [ADR-0014](ADR-0014-plot-manager-inside-future-event-service.md) | PlotManager 隶属 future-event-service；eventOptions 唯一出口 | Accepted | 2026-07-25 | systems/services/plot-manager.md, systems/services/future-event-service.md, systems/architecture.md |
| [ADR-0010](ADR-0010-presentation-three-layer-split.md) | 展示层三层切分：Data / 运行时·存档 / ViewModel | Accepted | 2026-07-25 | systems/viewmodel.md, systems/architecture.md, systems/common-properties.md |
| [ADR-0009](ADR-0009-single-entry-points-and-orchestrator.md) | 两条唯一入口 + 一个编排顶点 | Accepted | 2026-07-25 | systems/architecture.md, systems/services/profile-service.md, systems/services/content-service.md |
| [ADR-0004](ADR-0004-realm-checkpoint-retry-model.md) | 境界存档 · 篇章重试模型 | Accepted | 2026-07-23 | systems/services/life-cycle-service.md, systems/game-progression.md, systems/monetization.md |
| [ADR-0003](ADR-0003-online-cloud-authority.md) | 强制在线 · 云端权威（含重账号） | Accepted | 2026-07-23 | vision/scope.md, systems/services/life-cycle-service.md, .claude/rules/state-save-rules.md |
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
