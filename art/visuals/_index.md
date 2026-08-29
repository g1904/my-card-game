# 视觉（Visuals）—— 索引

一切视觉资产的方向、参考与生成指导。生成工具：**Midjourney**（参考素材 + art guide 一并投喂）。## 导航

| 文档 / 文件夹 | 用途 |
|------|------|
| [art-direction](art-direction.md) | **总视觉方向** —— 所有 art guide 的公共约束（基调、色彩、光照、构图、材质、渲染约束）。写 guide 前必读。 |
| [references/](references/_index.md) | 参考素材登记：来源、**借什么 / 不借什么**。 |
| [guides/](guides/_index.md) | 逐份 art guide（= 投喂 Midjourney 的结构化 prompt）＋ 台账。模板：`guides/_TEMPLATE.md`。 |
| [animations/](animations/_index.md) | **子分区（占位）** —— 让视觉资产动起来。同属视觉线、继承 `art-direction.md`；但**不走 AI 流水线**，故不设 `guides/`。待咨询专业人士后充实。 |

## 资产类目

每份 art guide 须绑定其中一个类目，以便与 `systems/` 的内容条目对齐。

| 类目 | 对应内容条目 | 关键约束 |
|------|--------------|----------|
| **卡面插画** | `systems/character-profile/deck/`（`CardData`） | 竖版构图；**full art —— 不预留文字区**；缩略尺寸下主体不仅可辨认，各卡还须彼此可区分（手牌区很小且无卡名可读）。→ [art-direction.md](art-direction.md) |
| **敌人立绘** | `systems/enemies/`（`EnemyData`） | 需传达境界与威胁度；同一敌人在图鉴与战斗屏复用。 |
| **角色形象** | `systems/character-profile/` | 起始角色；跨篇章的境界晋升是否改变外观待定。 |
| **法则 / 神通 / 古宝 / 法宝 图标** | `player-profile/player-power`、`player-item`；`character-profile/power`、`item` | 图标级尺寸；四类须在**形状语言**上可区分（账号级 vs 轮回级、power vs item）。 |
| **事件背景板** | 地域（`LocationData`，见 `systems/game-progression.md`） | **按地域区分，一地域一张**——同一地域的全部事件共用它。后期再考虑按事件类型（Combat / Exchange / Research / Explore / Travel）细化。竖屏；作为事件屏的底图，不得与前景文案 / 选项抢读。 |
| **事件插图** | `systems/adventure-event/**`（五类修行事件） | 单图承载一个场景与抉择氛围；数量最大的类目（逐条目）。**前期不产出**——事件屏的视觉由按地域的「事件背景板」承担，两者资产量级差一个数量级，故分列两行以免排期失真。 |
| **屏幕背景** | `ux/screen-flow.md` | 竖屏；不得与前景 UI 抢读；多宽高比下可安全裁切。 |
| **UI 元件与框架** | `ux/` | 卡框、按钮、面板、境界指示。**与插画分开**——UI 需要可九宫格拉伸，不适合整图生成。 |
| **图鉴插图** | `systems/player-profile/codex/`（图鉴族） | 多半复用上述类目资产，而非独立生成。 |

> 类目可增。新增类目时同步登记对应的内容条目与关键约束，否则 guide 无处归属。

> **资产在内容条目上的挂点是共有字段 `Artwork : Texture2D`**（`[Export]` 直接资源引用、可空；定义与校验语义见 `systems/common-properties.md`）。上表中「屏幕背景」「UI 元件与框架」「图鉴插图」三行**不经内容条目**：前两者由屏幕 / 控件直接引用，图鉴插图复用其余类目的资产。**功法没有独立的视觉资产**，故表中无功法一行。

> **横跨全部类目的一条：** 插画内不得烧入承载可翻译语义的文字（装饰性符文 / 印章 / 书法笔触 / 碑文豁免）。判据与豁免口径见 [art-direction.md](art-direction.md) 的「文字与字符」。

Source: `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md`

## 待决问题

- **guide 的粒度：** 一个内容条目一份 guide，还是一个类目一份 guide + 逐条目只填变量（主体描述、构图差异）？后者风格更稳，表达力更弱。
- **生成资产落地 `game-feature-branch/` 的目录划分与完备性校验：** 目录如何划分、是否需要一份 asset 清单做「内容条目 ↔ 资产」的完备性校验。**资产寻址不在此列**——条目经 `Artwork` 直接引用资源，寻址不依赖文件名与 `Id` 的命名对齐，故本条不阻塞字段落地。
- **二进制资产是否可经 overlay / blob 通道下发：** 决定换图 / 加图是否必须发版。`Artwork` 当前只写到「overlay 覆盖一条 `.tres` 时该字段随之被覆盖，指向必须落在随包基线内已存在的资产」为止。→ `systems/services/content-service.md`、`backend-design-documents/contracts/content-manifest.md`。
- **UI 元件是否走 AI 生成：** 九宫格拉伸、状态变体、图标一致性等要求与整图生成的特性冲突，可能需要另一条制作路径。
- **境界晋升是否改变角色 / 敌人外观：** 影响同一角色需要几套资产（1 套 vs 4 套），进而影响总资产量级。
