# 美术与音频 —— 设计意图索引

游戏**视觉**、**音频**与**动画**资产的方向、参考素材与生成指导材料。

本文件夹与 `systems/`（玩法系统）、`ux/`（屏幕与交互）并列：`ux` 管**布局与交互**（什么放在哪、怎么点），本文件夹管**观感与听感**（长什么样、听起来如何）。两者在卡面、屏幕背景等处相接，边界即「结构 vs 表皮」。

Source: `handoffs/2026-08-04-art-audio-library-scaffold.md`

## 生产流水线（人机协作三段）

```
① 人：给出 vision + 参考素材
      └─▶ ② AI：依 vision 与参考写出 art direction / art guide（= 结构化的生成 prompt）
                 └─▶ ③ 参考素材 + art guide 一并投喂生成工具（视觉：Midjourney）→ 生成资产
```

- **本库承载 ① 与 ②**：vision 文本、参考素材登记、art guide 文本。
- **本库不承载 ③ 的产物**：`game-design` 是纯文档的孤儿分支（见 `../README.md`），生成出的图 / 音**二进制资产归 `game-feature-branch/`**。
- **音频同流程**，生成工具**倾向 Suno，但尚未定案**（见 `soundtracks/_index.md`）。**动画不走这条流水线**——先咨询专业人士。

## 导航

**两个一级分区**：视觉与音频。

| 分区 | 状态 | 内容 |
|------|------|------|
| [visuals/](visuals/_index.md) | 已定 | 视觉资产：卡面、敌人、角色、事件插图、UI、图标、背景。 |
| &nbsp;&nbsp;└ [animations/](visuals/animations/_index.md) | **占位** | **视觉的子分区** —— 动画是让视觉资产动起来，同属一条视觉线。待咨询专业人士后充实。 |
| [soundtracks/](soundtracks/_index.md) | 已定 | 音频资产：BGM、氛围音、音效。 |

两个分区内部结构一致：

```
<分区>/
  _index.md            分区导航 + 资产类目清单
  *-direction.md       该分区的总方向 —— 所有 guide 的公共约束（上游，非可选补充）
  references/          参考素材登记：借什么 / 不借什么
  guides/              逐份 art guide / audio guide（= 投喂给生成工具的 prompt）
    _TEMPLATE.md
```

`visuals/animations/` 是例外：它**不走 AI 流水线**，故不设 `guides/`；其结构待咨询后另行设计。

## 承重约定

- **总方向文档是每份 guide 的上游。** 资产由生成工具**分次**产出，风格漂移是必然风险；跨资产的一致性只能由一份共同的方向文档承担。写任何 guide 之前先读该分区的 `*-direction.md`，并在 guide 中显式继承它。
- **每份 guide 绑定一个资产类目**（见各分区 `_index.md` 的类目清单），才能与 `systems/` 的内容条目对齐。
- **guide 是可迭代的、且要记住迭代结果。** 每份 guide 留「产出与迭代」栏：哪一版 prompt 出了可用结果、什么没work。否则下一次要从零试错。
- **参考素材必须写清「借什么 / 不借什么」**，沿用 `vision/references.md` 的具体化约定——泛泛的「参考 X」无法转成 prompt。

## 继承的既有约束（不得违反）

| 约束 | 内容 | 来源 |
|------|------|------|
| 画风 | 三国杀 (Legends of the Three Kingdoms) 与 弈仙牌 式的、具绘画感的中式卡牌游戏插画；竖版卡面构图。 | `vision/references.md` |
| 基调 | **grimdark 仙侠**——阴郁、高风险、不浪漫（Warhammer 40k 的精神，非其设定）。**明确不温馨**（对 Balatro 的规避）。 | `vision/pillars.md` |
| 可读性 | 必须在**手机尺寸**下清晰可读。 | `vision/references.md`、`.claude/rules/ui-input-rules.md` |
| 渲染器 | 处在 **GL Compatibility** 限制之内（着色器 / 特效受限；网页导出同此渲染器）。 | `vision/references.md` |
| 朝向 | **竖屏优先**，桌面 / 网页为次要适配。 | `.claude/rules/ui-input-rules.md` |

## 当前状态

**脚手架阶段。** 结构已立、内容待填——各文档的 `> _..._` 占位段落即待写处。美术与音频的实际推进归开发路线的靠后阶段（框架 → 内容 → 平衡与体验 → 社交及其他），当前不作为焦点；待答条目见 `../open-questions/deferred-content.md` 的「美术与音频」小节。
