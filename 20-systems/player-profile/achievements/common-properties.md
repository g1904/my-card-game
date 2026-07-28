# achievements / common-properties（Achievements 共有属性）

> 所有成就条目共有的属性 / 字段与通用流程。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 共有属性 / 字段

- **稳定 Id。** 每个成就条目有稳定唯一的字符串 `Id`（供存档进度记录、注册表查找、奖励发放引用）。Source: `.claude/rules/data-resource-rules.md`。
- **分组归属。** 每个成就属于一个类别 / 组；奖励按**组内加权进度**发放（60% / 90% 两档），故条目需携带其组 key 与进度权重。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **可见性。** 目录中 **80% 条目可见、20% 为隐藏成就**（达成后才显示）——故条目需带一个可见性标记。Source: 同上。
- **展示字段分层。** 成就名 / 描述 / 图标等静态展示文本留在 `XxxData : Resource` 上；存档态只带 `Id` + 进度；组合展示由 UI 层 ViewModel 装配。Source: `20-systems/common-properties.md`。

> 具体字段清单尚未设计——见待决问题。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **字段 schema 未定：** 条目的触发条件表达（计数 / 阈值 / 事件匹配？）、进度的存档形态、加权进度的权重字段、组定义的载体（独立 `.tres`？）均未设计。
- **进度采集方式未定：** EventBus 被动订阅 vs 各服务主动上报。→ `20-systems/services/profile-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/achievements/common-properties.md`（待建）。
