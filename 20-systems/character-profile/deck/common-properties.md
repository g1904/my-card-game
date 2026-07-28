# deck —— 共有属性

> deck 子系统的共有字段与共有机制：抽 / 弃 / 洗循环、CardData 定义（费用、目标、效果流水线、触发器）。为未来「每张卡一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **抽牌 / hand / 弃牌循环（共有机制）。** 卡从抽牌堆抽入 hand，打出或回合结束后进弃牌堆，抽牌堆空时由弃牌堆重洗补充。洗牌由 cycle seed 驱动（确定性可复现，见 `state-save-rules.md`）。
- **CardData 共有字段（数据即资源）。** 每张卡是一个 `CardData : Resource`（`.tres`），共有字段预期含：稳定唯一 `Id`、显示名 / 描述（与 `Id` 分离、可本地化）、**费用（mana cost）**、**目标（target）**、**效果流水线（effect pipeline）**、**触发器（trigger）**。数值读自资源，不硬编码。Source: `data-resource-rules.md`。
- **打出一张卡的结算（共有流程）。** 费用支付（mana）→ 目标选择 → 效果流水线依序执行 → 触发器响应事件。（具体阶段待设计。）

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **CardData 字段清单未定案。** 费用 / 目标 / 效果 / 触发器为结构占位——各字段的具体类型、枚举、效果关键字体系、目标规则均尚未设计，需一次 handoff。
- **抽 / 弃 / 洗数值。** 手牌上限、每回合抽牌数、初始牌堆规模等属平衡数值 → `20-systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（CardData）；`.claude/knowledge/systems/character-profile/deck/`（待建）。
