# ADR-0254 — 两条隐藏属性剧情线的结构形态：`SideStory` · `ChapterScope` 恒空 · 3–4 节点 · boss 走 `PlotModulation`

- **状态：** Accepted
- **日期：** 2026-09-09
- **来源：** handoffs/2026-09-09f-event-reward-and-hidden-stat-orchestration.md

## 背景

隐藏属性的两个极值档各自挂一条剧情线（煞气反噬 / 心魔滋生）。此前只有「有这么两条线」这一句，没有形态——arc 类型、篇章框定、节点数、boss 怎么表达，全空。

## 决策

**两条同形：**

- `SideStory`（不取 `SideChapter`）· **`ChapterScope` 恒空** · `PlotTriggerId` 对接两个极值档 · **同 `ExclusiveGroup`** · **3–4 节点** · 至少一处 `ChooseBranch`。
- 节点形态：入口叙事 → 1–2 调制 → **剧情线 boss**（`EnemyPoolScope` + `LevelBias` + `Tighten`，即被 `PlotModulation` 六字段拧过的一场 `Standard` 档 Combat）→ 终止。**零新结构。**
- **`ChapterScope` 恒空的理由须随结构一并写进文档**（否则会被顺手填上）。

→ `systems/services/plot-manager.md`。

## 理由

- **`SideStory` 而非 `SideChapter`**：这两条线跨篇章不重置，且触发时点不可预知——`SideChapter` 的篇章绑定表达不了。
- **同 `ExclusiveGroup`**：既杀伐又背信的角色会**同时满足两条触发条件**，不互斥就会同时开两条线。
- **3–4 节点既是下界也是上界**：少于三节点就没有 boss 节点，而 **boss 是这条线唯一的高潮落点**；多于四节点则第三篇章触发时跑不完剩余事件位。
- **boss 走 `PlotModulation` 六字段**，因此不需要任何新结构——它就是一场被拧过的 `Standard` 档 Combat。
- 两条线**都不给干净的好结局**，与 grimdark 基调一致。

## 备选方案

- **取 `SideChapter`** — 否决：跨篇章不重置 + 触发时点不可预知，两条都表达不了。
- **两条线各自独立、不设互斥** — 否决：满足双条件的角色会同时开两条线。
- **砍到两个节点以配合心魔滋生的低触发率** — 否决：没有 boss 节点，这条线失去唯一的高潮落点。

## 后果

- **节点规模不随触发率下调而缩水**：心魔滋生虽退化为主动选择型（→ `ADR-0253`），仍维持 3–4 节点；调整的是**编排密度**，不是规模。
- **零新结构**：不新增字段 / 内容类型 / 枚举成员 / 加载期校验 / 存档字段，不 bump `schemaVersion`，后端零参与。
- 两条线的**具体剧情内容**仍是内容阶段的待答项，本条只定结构形态。
