# `LocationCodex` 连边的显影粒度

- id: 2026-08-22-locationcodex-edge-granularity
- date: 2026-08-22
- topic: systems/player-profile/codex · systems/adventure-event/travel
- status: distilled
- distilled-to: `systems/player-profile/codex/_index.md`, `systems/player-profile/codex/common-properties.md`, `systems/adventure-event/travel/_index.md`

## Intent（distilled）

**一句话：** 「记连边」的粒度取 **顶点级解锁**——去过 A 即显影 A 在 `locationMap` 上的**全部邻接**（含从未去过的地名）；连边**不进存档**，由呈现层从单份 `LocationMapData` 现算，存档 / 契约 / 校验 / 迁移**零增量**。

### ① 粒度 = 顶点级解锁，连边是派生

`locationCodex` 仍是**顶点 id 的集合**：一条 `CodexEntry(Id = LocationData.Id)` 对应一个去过的地域。逐条核对既有约束全部成立——`CodexEntry` 不加格、`Id` 仍是可经 `ContentRegistry` 解析的稳定 `Id`、`CodexKind` 仍是六值、触发仍是抵达且搭在已有提交上、体积护栏与完成度分母口径不变、「六本形状相同」不破。

**裁决依据不是手感取舍，而是「零存档增量」对「为一本图鉴破族级约束」。** 「只记走过的边」这一侧要让存档表达**边**这个对象，三条出路各破一条承重约束：把 `Id` 编成复合键要为一条「必需缺失」级校验单开例外、并让体积护栏对这一本恒常误报；把边升格为一等内容条目要改写「单份 `LocationMapData` 持无向边集」的载体形态、补一批加载期校验，且顶点仍需另记 ⇒ 一本图鉴装两类对象；在 `CodexEntry` 上加一格邻接表则该格对其余五本恒为空，正是「不落成单表 + `Kind` 字段」判据所拒绝的形态。

**它同时是两条已宣告设计目标能否兑现的分水岭。** 顶点级下重建全图只需玩家的已访顶点构成图的一个**顶点覆盖**（每条边至少一端去过）；边级则要求**踩遍每一条边**，而 Travel 非常驻可选项、另有 20% 档把玩家随机推走 ⇒ 有限轮回内边覆盖近乎不可完成，「跨轮回重建整张图」与「提前两步规划路线」都会落空。后者尤其直接：提前两步的信息就是「B 又通向哪里」，边级下要走过 B→C 才有，而那时已不需要它。

**「提前看见地名」不是泄露。** 地名之外什么都不给——未去过的地域是一个只有名字的灰点，事件类型倾向 / 敌人池 / `EventCountLimit` 全部锁在词条里。看见名字只带来「那边还有路」，不带来「那边有什么」。

### ② 呈现三态 + 显影半径固定 1 跳

| 态 | 判据 | 显示 |
|---|---|---|
| **已解锁**（Known） | `Id ∈ locationCodex` | 名字 + 完整词条 |
| **边缘**（Frontier） | 不在 `locationCodex`，但在某条**至少一端已解锁**的边上 | **只有真实地名**，灰态；词条锁着；点按给「尚未到过」提示 |
| **不可见** | 其余 | 顶点与边都不画 |

- **半径固定 1 跳，不设旋钮。** 1 跳恰好等于「提前两步规划路线」所需的信息量；半径 2 会让图在两三次轮回内基本发完。半径是**约束面**参数（它决定玩家的信息量），与 80 / 20 不可被剧本调制同理由。
- **边的显影随顶点自动成立**：无向图下一条边只要任一端已解锁即画出，不需要为边单独记状态。
- **完成度只计已解锁顶点**，边缘顶点不计、边不计——保住六本统一的完成度口径。

### ③ 呈现层派生（只读）

```
Known    = { e.Id : e ∈ playerProfile.locationCodex }
VisibleE = { edge ∈ LocationMapData.Edges : edge.FromId ∈ Known || edge.ToId ∈ Known }
Frontier = { 端点 x : x 是 VisibleE 某条边的一端 && x ∉ Known }
渲染顶点 = Known（完整词条） ∪ Frontier（仅名字，灰态）
渲染边   = VisibleE
```

取图走 `AllIncludingDisabled()`；`Frontier` 顶点的 `LocationData` 解析不到 → `PushWarning` + 跳过该顶点（可选缺失）。纯读、可在图鉴屏打开时缓存，不进 `_Process` 热路径。三态标签一律走 `res://text/` 翻译键，边缘顶点须有触控等价的查看反馈。

### ④ 落地面：一格不动

`CodexEntry` 字段面 / `CodexUnlock` / `CodexKind` / `ProfileChangeSpec` 列 / 触发点 / `ProfileManager` 校验行 / 存档 schema 版本 / 后端配合——**增量全为零**，全部改动落在呈现层的一段只读派生与一条口径明文。加载期校验不新增：已有的出度 ≤ 5 / 出度 ≥ 1 / 连通 / 无自环重复边四条恰好也是本方案渲染正确性的前提。

### ⑤ 代价，明写

玩家记住的不只是去过的顶点，还有它们 1 跳邻域的地名 ⇒ **改连边所清空的账号级资产比边级粒度更大**。这与「`locationMap` 的稳定性是对玩家的隐性承诺」是同一条纪律，只是量级更明确。

## Clarifications（interview 产物）

- **粒度取哪一侧** → **顶点级：去过 A 即显影 A 的全部邻接（含从未去过的地名）**。`locationCodex` 保持顶点 id 集合，连边呈现层现算，存档零增量。这把 `codex/_index.md` 与 `open-questions/02-event-options.md` 原写的「**本库现按前者理解，待确认**」转为正式定案。
- **边缘顶点显示到什么程度** → **显真实地名 + 灰态 + 词条锁着**（否决「地名 + 出度」与「『？』占位」两案）。 `[采纳推荐 — 待复核]`
- **显影半径** → **固定 1 跳，不设旋钮**（否决半径 2 与「做成可调旋钮」）。 `[采纳推荐 — 待复核]`

## Open questions

- **边缘顶点的显示程度** `[采纳推荐 — 待复核]`：真实地名 vs 出度附加 vs 占位符。纯呈现层旋钮，可逆、不影响存档。→ `systems/player-profile/codex/_index.md`。
- **显影半径不设旋钮** `[采纳推荐 — 待复核]`：是否确认半径永不开放为可调参数。→ 同上。
- **LocationCodex 的其余词条深度**（风物文案 / 事件类型倾向 / 敌人清单 / `EventCountLimit`）仍未定。本次的「边缘态只给名字」已把两者解耦——词条深度可独立裁决。→ 同上。
- **它不同于其余五本的呈现形态**（一张逐步显影的图 vs 列表 / 网格）与六本图鉴的入口与浏览形态，归图鉴呈现专场。→ `ux/screen-flow.md`。

## Notes / triage

- 来源草稿：`inbox/solution-draft-locationcodex-edge-granularity.md`（已评审，`## 仍需用户决定` 三项全部裁决）。因含两项 `[采纳推荐 — 待复核]`，**草稿留在 `inbox/` 顶层**，不归档。
- **越界发现（不在本次写入面内）：**
  - `systems/player-profile/_index.md` —— 「`LocationCodex` 的连边不落存档」那句宜扩为派生口径；且它与 `codex/_index.md` 同写「连边随 **location 条目**静态给出」，而边由**单份 `LocationMapData`** 持有、不由各 location 持边，措辞应校正（`codex/_index.md` 侧本次已改）。
  - `ux/screen-flow.md` —— 图鉴屏的三态呈现口径待补。
