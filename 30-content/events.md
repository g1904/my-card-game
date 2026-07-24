# events

> event 设计:提示文本以及分支式的选择/结果。

## 意图
> _从 handoffs 中提炼的设计意图。保持更新。_

- **AdventurePlot(隐藏剧本层)——新抽象。** 结构模型见 `20-systems/adventure-plot.md`;本文档负责**剧本内容**侧。AdventurePlot 是一棵由**分支可能性**构成的树,在背景中运行、**影响角色的 `possibleFutureEvent`**,部分节点可像 **DnD** 让玩家**显式选分支**。分四级:**Story**(贯穿三大篇章的主线)> **Chapter**(单篇章剧本,三个相连成 Story)> **SideChapter**(篇章内穿插支线)与 **SideStory**(跨篇章穿插支线)。**Character 只记录 key points;完整剧本与分支内容存于云端剧本服务(script service),按 key points 请求。** Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **隐藏属性驱动剧情线。** 属性模型借鉴 **Reigns** 但**反其道:属性隐藏、不作可见仪表**(见 `20-systems/run-manager.md`)。隐藏属性积累到**阈值**时触发对应 AdventurePlot 剧情线。已提出的示例:
  - **煞气点数(malefic qi)** —— 隐藏属性;累积到阈值 → 触发 **「煞气反噬」** 剧情线。
  - **寿元(lifeSpan)** —— 隐藏的**寿命数值**(**非血量 life**);增长到阈值 → 触发 **「大限将至」** 剧情线。
- Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 50-decisions/ADR-####。_

## 待解问题
> _尚未解决,需要一次 handoff/决策。_

- **AdventurePlot 数据编码与授权:** 「分支可能性树」如何用数据(`.tres` / 图)表达?它是**调制**既有 `AdventureEvent.possibleFutureEvent` 图,还是一套并行结构?DnD 式「让玩家选分支」的触发点与 UI 待定。
- **隐藏属性清单与阈值:** 除 煞气、寿元 外还有哪些?各自阈值、增减触发(哪些 AdventureEvent 推拉)、以及各自的剧情线目录待定;`faith` 是否归入隐藏属性待澄清。
- **寿元触发后果:** 「大限将至」触发后角色走向(defeated?转入 Finale?)与寿元上限 / 增长规则待定。

## 提供给
提炼进:`.claude/knowledge/data/_index.md`
