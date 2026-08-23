# Answer log locationcodex-edge-granularity

- 日期：2026-08-22
- 来源：`inbox/solution-draft-locationcodex-edge-granularity.md` → `handoffs/2026-08-22-locationcodex-edge-granularity.md`
- 移出条数：**1**（该条部分移出——粒度答结，词条深度与呈现形态两半仍留）

## 部分答定（1 —— 剩余部分仍留在待答清单）

**`LocationCodex`「记连边」的显影粒度（承重）**（`open-questions/02-event-options.md`）
→ **粒度取顶点级解锁：去过 A 即显影 A 在 `locationMap` 上的全部邻接**，含玩家从未去过的地名。`locationCodex` 仍是**顶点 `Id` 的集合**，连边由呈现层从单份 `LocationMapData` 现算——**存档 / 契约 / 校验 / schema 版本 / 后端配合增量全为零**。该条原写的「本库现按前者理解，待确认」由此转为正式定案。
→ **「只记已走过的边」被否决**：三条实现出路各破一条承重约束（复合 `Id` 要为「`CodexUnlock.Id` 解析不到即整批拒绝」单开例外并让体积护栏恒常误报 · 边升格为一等内容条目要改写单份 `LocationMapData` 持边集的载体形态且顶点仍需另记 · `CodexEntry` 加一格邻接表则该格对其余五本恒空）；且因 Travel 非常驻 + 20% 随机档，边覆盖近乎不可完成 ⇒ 「跨轮回重建整张图」与「提前两步规划路线」两条已定案会落空。
→ **呈现三态定案**：已解锁（名字 + 完整词条）/ 边缘（只有真实地名、灰态、词条锁着）/ 不可见（顶点与边都不画）；**显影半径固定 1 跳、不设旋钮**（半径是约束面参数，与「80/20 不可被剧本调制」同款收口）。后两项为 `[采纳推荐 — 待复核]`。
→ **完成度只计已解锁顶点**（分母仍走 `AllIncludingDisabled()` 的 location 条目数），边缘顶点不计、边不计。
→ **仍留在该条的两半**：LocationCodex 的其余**词条深度**（风物文案 / 事件类型倾向 / 敌人清单 / `EventCountLimit`），以及**它不同于其余五本的呈现形态**（一张逐步显影的图 vs 列表 / 网格）。「边缘态只给名字」已把两者与粒度解耦，可独立裁决。
（归档去向：`systems/player-profile/codex/_index.md` · `systems/player-profile/codex/common-properties.md` · `systems/adventure-event/travel/_index.md`）

## 本次新增的待答（未移出，记此备查）

- **边缘顶点显示程度 + 显影半径不设旋钮 `[采纳推荐 — 待复核]`** —— 两项纯呈现层旋钮已按推荐落笔，可逆、不影响存档，待用户复核。落在 `systems/player-profile/codex/_index.md` 的待决问题。
