# 术语表（Terminology）

> 开发中使用的专有术语事实来源：中文领域词 ↔ 英文 / 代码标识符。随开发滚动更新。
> 代码标识符沿用此处的英文 / 代码列（`csharp-godot-rules.md` 的 PascalCase 命名）。
> 提炼至：`.claude/knowledge/dictionary.md`。

## 核心结构

| 中文 | 英文 / 代码 | 含义 | 来源 |
|------|------------|------|------|
| 修行事件 | AdventureEvent | 逐时逐刻的游玩单元（原 **encounter** 重命名而来）；玩家从当前可用项中择一以推进 run。 | `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` |
| 修行历程 | （集合，`List<AdventureEvent>`） | 一个角色走过 / 可走的整段修行旅程（修行事件的序列 / 图）。 | 同上 |
| 玩家信息 | PlayerProfile | 账号级主档，跨 run 持久，持有一组 CharacterProfile 及账号级元数据。 | `10-handoffs/2026-07-15-adventure-event-profiles.md` |
| 角色信息 | CharacterProfile | 单次 run / 单个角色的状态与历史（对齐 RunState 概念）。 | 同上 |

## 修行事件分类（六类 · 已定案 ADR-0002）

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**：进入后才揭示为其余某一类 |

> 休养 / Rest 不单列，并入 战斗 或 闭关。定案见 `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 修行阶梯（境界 · realm）

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 炼气 | Qi Refining | 第一境 |
| 筑基 | Foundation Establishment | 第二境 |
| 金丹 | Golden Core | 第三境 |
| 元婴 | Nascent Soul | 第四境（终点 / 奖杯） |
| 篇章 | Chapter | 相邻两境之间的一段攀登；一次 run 含三个篇章。 |

> 来源：`10-handoffs/2026-07-13.md`。
