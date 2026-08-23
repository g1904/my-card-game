# Answer log plot-tree-chapter-packaging

- 日期：2026-08-22
- 来源：`inbox/archive/solution-draft-plot-tree-chapter-packaging.md` → `handoffs/2026-08-22-plot-tree-chapter-packaging.md`
- 移出条数：1（部分——三项配套取向为 `[采纳推荐 — 待复核]`，仍留在待答清单）

---

**剧本内容的体积与分发粒度：三篇章完整剧本树该不该按篇章分包 / 按进度增量下载？分包边界落在哪？**
→ **不分包。** 剧本树整体随 `res://` 基线发布，更新走 overlay 既有的文件级增量热更。三条承重理由：① 分包与「合并后全量强校验」在结构上冲突——跨包引用不是可避开的编排问题，而是剧本层级模型本身的形状（Story arc 贯穿三篇章、`SideStory` 跨篇章、`PlotTriggerId` 跨到档位表），要让分包成立只能在「放宽悬空校验 / 造第三种未下载态 / 切在无跨包引用处」三条里拆一件承重件；② 强制在线消解的是分包的收益侧——玩家启动即两处硬阻塞，必然有网，而分包反会造出「推进到下一篇章却没网」这个既有设计里不存在的失败态；③ 剧本文本落在包体的百分之一量级，为此买一整套分发机制是净亏。采纳结果是零机制增量（manifest / `manifestSchema` / `ContentUpdateManager` / 三个剧本 schema / 硬阻塞点清单全不动），后端库零改动。
（归档去向：`systems/services/plot-manager.md`「意图」区；`systems/services/content-service.md`「全部内容都属本地内容层」留一句回链。）

**剩余仍在待答清单的部分**（三项均为 `[采纳推荐 — 待复核]`，用户授权按推荐落笔但未计作拍板）：

- **① 关闭为定案 + 留复核闸**（而非保留为「已倾向不分包、待第二阶段实测」）。
- **② 体积护栏只在 `content/plot-arc/_index.md` / `content/plot-node/_index.md` 的条目台账记「条目数 + 字节总和」，不加加载期校验**；两个类型档案尚未开张，本项随开张落地。
- **③ 「平台原生按需资源」写一句方向性记录进 `plot-manager.md`**；明确不往后端库 `contracts/content-manifest.md` 写承接。

此外，复核闸的两个门槛（占比阈值 / 绝对值上限）留待第二阶段有实测数时再定——当前没有任何依据可给出这两个数，且在第一批真实剧本条目写完之前也无从执行。
