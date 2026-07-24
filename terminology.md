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
| 玩家能力 | PlayerPower | 账号级 always-available 能力，带开关（默认开启）；QoL 或影响公平性的全局加强，不与角色绑定，可获取 / 失去。 | `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` |
| 玩家道具 | PlayerItem | 账号级、有使用次数限制的道具。 | 同上 |
| 生命 · 法力 | life + mana | 战斗双资源模型（参考 MTG / Hearthstone）：生命为血量，mana 为每回合出牌资源。**无 mana 曲线**，采用「上限 + 逐步恢复」；炼气基线 life=10/10、mana=5/5。对齐 `Status.currentHealth / currentMana`。 | 同上 + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 道心 | faith | **隐藏数值属性**（原 `faith` / 信仰即时属性，现归为隐藏）；与 煞气 / 寿元 同属驱动 AdventurePlot 的隐藏属性。 | `10-handoffs/2026-07-15-adventure-event-profiles.md` + 归隐藏 `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 煞气（点数） | malefic qi | **隐藏属性**：积累到阈值触发「煞气反噬」剧情线。 | `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 寿元 | lifeSpan | **隐藏属性**：角色寿命数值（**非血量 life**）；增长到阈值触发「大限将至」剧情线。 | 同上 |
| 境界突破 · 高潮 | AdventureEvent-Finale | 篇章边界的境界突破事件；分类法**第七类，独立于 Combat**（ADR-0002 07-23 修订）。 | 同上 |
| 修行剧情（体系） | AdventurePlot | 隐藏剧本层的总称：由分支可能性构成、在背景中运行、影响角色 `possibleFutureEvent`；可像 DnD 那样让玩家选分支。下含 Story / Chapter / SideChapter / SideStory 四级。 | 同上 |
| 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的**大剧本**（一条角色的完整主线故事）。 | 同上 |
| 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter）。 | 同上 |
| 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线剧本。 | 同上 |
| 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线剧本。 | 同上 |
| 剧情节点 | AdventurePlot key points | Character 上记录的 AdventurePlot **关键节点 / 进度锚点**（完整剧本与分支内容不落在存档，见「剧本服务」）。 | 同上 |
| 剧本服务 | script service | 存储**全部 AdventurePlot 剧本与分支内容**的（云端）服务；客户端按 key points 向其请求完整剧本 / 分支。 | 同上 |

## 修行事件分类（七类 · 已定案 ADR-0002，07-23 加入 Finale）

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**：进入后才揭示为其余某一类 |
| 境界突破 | Finale | **篇章边界高潮**：渡劫 / 突破，独立于 Combat 的结算（07-23 加入的第七类） |

> 休养 / Rest 不单列，并入 战斗 或 闭关。定案见 `50-decisions/ADR-0002-adventure-event-taxonomy.md`（七类，07-23 加入 Finale）。
> **境界突破 = `AdventureEvent-Finale`**（篇章边界高潮），已作为**第七类并入 ADR-0002 枚举**，独立于 Combat。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 修行阶梯（境界 · realm）

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 炼气 | Qi Refining | 第一境 |
| 筑基 | Foundation Establishment | 第二境 |
| 金丹 | Golden Core | 第三境 |
| 元婴 | Nascent Soul | 第四境（终点 / 奖杯） |
| 篇章 | Chapter | 相邻两境之间的一段攀登；一次 run 含三个篇章。 |

> 来源：`10-handoffs/2026-07-13.md`。
