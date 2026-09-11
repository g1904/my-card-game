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
| **敌人立绘** | `systems/enemies/`（`EnemyData`） | 需传达境界与威胁度；同一敌人在图鉴与战斗屏复用。**一条目一张，不随境界分版**——境界感由该条目自身的叙事定位与 `ChapterScope` 承担。 |
| **角色形象** | `systems/character-profile/` | 起始角色；一条基础形象 + 至多三条境界覆写（稀疏，默认只有基础形象）。总量 = 角色池规模 × 覆写档数，池规模见 `systems/character-profile/_index.md`。 |
| **法则 / 神通 / 古宝 / 法宝 图标** | `player-profile/player-power`、`player-item`；`character-profile/power`、`item` | 图标级尺寸；四类须在**形状语言**上可区分（账号级 vs 轮回级、power vs item）。 |
| **事件背景板** | 地域（`LocationData`，见 `systems/game-progression.md`） | **按地域区分，一地域一张**——同一地域的全部事件共用它。后期再考虑按事件类型（Combat / Exchange / Research / Explore / Travel）细化。竖屏；作为事件屏的底图，不得与前景文案 / 选项抢读。 |
| **事件插图** | `systems/adventure-event/**`（五类修行事件） | 单图承载一个场景与抉择氛围；数量最大的类目（逐条目）。**前期不产出**——事件屏的视觉由按地域的「事件背景板」承担，两者资产量级差一个数量级，故分列两行以免排期失真。 |
| **屏幕背景** | `ux/screen-flow.md` | 竖屏；不得与前景 UI 抢读；多宽高比下可安全裁切。 |
| **UI 元件与框架** | `ux/` | 卡框、按钮、面板、境界指示。**与插画分开**——UI 需要可九宫格拉伸，不适合整图生成。**只有点缀素材这一半走 guide**，扁平底子那一半不建 guide（见下方「制作路径」）。 |
| **图鉴插图** | `systems/player-profile/codex/`（图鉴族） | 多半复用上述类目资产，而非独立生成。 |

> 类目可增。新增类目时同步登记对应的内容条目与关键约束，否则 guide 无处归属。

> **资产在内容条目上的挂点是共有字段 `Artwork : Texture2D`**（`[Export]` 直接资源引用、可空；定义与校验语义见 `systems/common-properties.md`）。上表中「屏幕背景」「UI 元件与框架」「图鉴插图」三行**不经内容条目**：前两者由屏幕 / 控件直接引用，图鉴插图复用其余类目的资产。**功法没有独立的视觉资产**，故表中无功法一行。

> **一条内容一张，不随境界分版。** 资产乘数不由境界产生——唯一例外是角色形象的稀疏境界覆写，它落 `CharacterData` 自有字段而不改共有字段 `Artwork` 的基数（见 `systems/character-profile/_index.md`）。其余类目的境界感由条目自身的叙事定位与 `ChapterScope` 承担，见 [art-direction.md](art-direction.md) 的「基调」。

> **横跨全部类目的一条：** 插画内不得烧入承载可翻译语义的文字（装饰性符文 / 印章 / 书法笔触 / 碑文豁免）。判据与豁免口径见 [art-direction.md](art-direction.md) 的「文字与字符」。

> **资产变更随发版，不经热更通道。** 二进制资产不经 overlay / blob 通道下发，换图 / 加图随版本发布（判据见 `systems/common-properties.md` 的 `Artwork` 一节）。**guide 的产出排期与资产替换节奏可据此规划，不必为「热更换图」预留任何形态。**
>
> **它是可撤销的，代价写在这里：** 日后若确需「换图不发版」，要成对改动的是 —— `decisions/ADR-0120-content-artwork-and-enemy-lines.md` 的引用形态（直接资源引用 → 某种间接寻址 + 运行时加载，并自写悬空与解码失败处置）· `systems/services/content-service.md` 的「不做字节级断点续传」重开评估 · 契约侧三点核对（`files[].size` 口径与磁盘预检 · 「字节级 Range 不写进契约」这条否定须两侧同批重估 · CDN 缓存与成本模型），见 `backend-design-documents/open-questions/04-content-delivery.md`。**纯加法窗口在第一批 `.tres` 写下时关闭**（`content/` 现零条目）——此后改的是全部条目的字段形态与全部资产的落地方式。

Source: `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md` · `handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md` · `handoffs/2026-08-30-realm-progression-artwork-basis.md`

## 承重约定

### 制作路径：混合，按材质分工切分

UI 元件与框架这一类目**分两半走两条路**，切分线与 `art-direction.md` 的「UI 元件的材质隐喻」一一对应：

| 半 | 内容 | 路径 |
|---|------|------|
| **扁平底子** | 面板、按钮底、容器、状态变体、九宫格切片 | **人工 / 矢量制作，不进 AI 流水线、不建 guide。** 它本就是纯色块与描边，整图生成没有增益，却要承担九宫格拉伸与状态变体的全部风险。 |
| **古物点缀素材** | 符纹、印泥、纹样、边角装饰 | **走 Midjourney 生成后裁切入 UI**，正常建 guide。这类离散的装饰素材恰是 AI 低成本产出的甜区。 |

其余全部类目照常走 AI 流水线。

### guide 粒度：类目 guide + 条目变量

**一个资产类目一份 guide**，承载该类目的公共段（风格、构图规范、参考素材、prompt 骨架、参数）；**逐条目只填变量段**（主体、构图差异、情绪）。理由是稳定性优先——资产分次生成，风格漂移是最大的现实风险，共享的公共段是唯一的收敛手段。

表达力的缺口由一条显式通道兜住：**少数需要特殊表达的条目**（Finale 敌人、关键角色一类）**可例外升格为独立 guide**，但**必须在所属类目 guide 中登记指针**——不登记的升格会让两份 guide 各自漂移，而没有任何机制发现。

模板形态见 `guides/_TEMPLATE.md`。

Source: `handoffs/2026-09-09-art-direction-nine-axes.md`

## 待决问题

- **生成资产落地 `game-feature-branch/` 的目录划分与完备性校验：** 目录如何划分、是否需要一份 asset 清单做「内容条目 ↔ 资产」的完备性校验。**资产寻址不在此列**——条目经 `Artwork` 直接引用资源，寻址不依赖文件名与 `Id` 的命名对齐，故本条不阻塞字段落地。
- **各类目的尺寸格式与图集策略：** 目标分辨率、导出格式、透明通道、图集划分。留待首批 guide 按 Midjourney 输出规格与 Godot 导入实测反推，方向层不预锁数值。→ `art-direction.md` 的「技术约束」。
