# adventure-plot

> 隐藏剧本层：剧本层级（Story / Chapter / SideChapter / SideStory）、隐藏属性驱动、Character 上的 key points、云端剧本服务。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AdventurePlot = 隐藏剧本层（新抽象）。** 一棵由**分支可能性**构成的树，在背景中运行、**影响角色的 `possibleFutureEvent`**（见 `20-systems/map-progression.md`）。玩家通常看不到它，但它持续塑造后续会变为可用的 AdventureEvent；部分节点可像 **DnD** 那样让玩家**显式选择分支**。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

- **剧本层级（四级）。**

  | 层级 | 英文 / 代码 | 范围 |
  |------|------------|------|
  | 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的大剧本（一条完整主线） |
  | 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter） |
  | 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线 |
  | 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线 |

  即：三个 **Chapter** 相连组成一个 **Story**；Chapter 内可穿插 **SideChapter**，跨 Chapter 可穿插 **SideStory**。

- **隐藏属性驱动。** 属性模型借鉴 **Reigns** 但**反其道：属性隐藏、不作可见仪表**。隐藏属性（**道心 / faith**、**煞气 / malefic qi**、**寿元 / lifeSpan**）积累到**阈值**时触发对应剧情线——例：煞气→「煞气反噬」、寿元→「大限将至」。隐藏属性落在 `CharacterProfile.Status`（见 `20-systems/run-manager.md`）；剧情线内容见 `30-content/events.md`。

- **Character 只存 key points；内容在剧本服务。** `CharacterProfile` 上记录 AdventurePlot 的 **key points（关键节点 / 进度锚点）**；**完整的剧本与不同分支的内容不落在存档**，而是存于（云端）**剧本服务（script service）**——客户端按 key points 向其请求完整剧本 / 分支。这与「强制在线 · 云端权威」（ADR-0003）一致：剧本内容云端下发，存档只带轻量锚点。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 内容云端下发依赖 **强制在线 · 云端权威** → `50-decisions/ADR-0003-online-cloud-authority.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **数据编码与耦合：** AdventurePlot 树如何用数据表达？它是**调制**既有 `AdventureEvent.possibleFutureEvent` 图，还是并行结构？key points 的粒度与 schema？
- **剧本服务契约：** 请求 / 下发协议、缓存策略、离线缓冲（断线时剧情如何降级）、版本化未定。
- **DnD 式选分支：** 触发点、UI、以及玩家可见 / 不可见分支的边界未定。
- **隐藏属性清单与阈值：** 道心 / 煞气 / 寿元 之外还有哪些？各自阈值、增减触发（哪些 AdventureEvent 推拉）、剧情线目录、以及「大限将至」触发后果（defeated？转入 Finale？）待定。→ 亦见 `30-content/events.md`、`20-systems/run-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-plot.md`（待 `/sync-knowledge` 建立）
