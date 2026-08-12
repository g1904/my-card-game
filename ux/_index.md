# UX — 设计意图索引

屏幕流程、交互手感与文本线框图。竖屏优先、触控优先(见 `.claude/rules/ui-input-rules.md`)。提供给 `.claude/knowledge/scenes/_index.md`。

| 文档 | 用途 |
|-----|---------|
| [screen-flow](screen-flow.md) | 菜单 → 轮回 → 地图 → 战斗 → shop → 设置 的导航。 |
| [combat-ux](combat-ux.md) | 出牌/拖拽/指定目标、intent 预告、节奏。 |
| [onboarding](onboarding.md) | 首次游玩的教学顺序。 |
| [error-and-blocking-ux](error-and-blocking-ux.md) | **横切所有屏**：玩家可见错误文案的来源（键 = 后端 `code`，载体 = 翻译键）、三条「去更新」提示的去重、阻塞屏三变体、诊断编号的玩家出口。 |

> 此处的线框图为文本/ASCII;实际的 `.tscn` 组合位于 `game-feature-branch/`,并在 `knowledge/scenes/` 中编目。

> **全库横向纪律：一切 UI 文案走 `TranslationServer` 翻译键**（默认中文、优先制作中文列，英文列全部预设占位符）。形态与首批落地见 `error-and-blocking-ux.md`。Source: `handoffs/2026-08-12-error-copy-and-update-prompts.md`。
>
> **边界（08-12d 澄清）：上一条只管 UI 文案，不管内容文案。** 判据是「**谁是内容、谁是界面**」——四问同答：有稳定 `Id` 且被别的条目按 `Id` 引用？进 ContentRegistry 参与强校验？被存档引用（受「只改不增」约束）？需线上可改而不发版？**四问皆是 → 内容层（`res://content/` + overlay）**：卡面描述、事件正文、风味文案、**隐藏属性跨档叙事**、Finale 补白。**四问皆否 → 翻译键（随包）**：错误串、阻塞屏、同步指示、更新横幅、按钮文字。**互换载体两头都坏**：叙事塞进 `res://text/` 会失去 `Id`、失去启动期校验、档位定义无从引用它、也失去热更；UI 文案塞进 overlay 则把一条被刻意限窄的热更通道撑宽（`system-overview.md` 明写「`text/` 不是内容层」）。**尚无定案的交叉点：内容条目自己的多语言**——它走内容条目内的多语言表达，不是 `text/` 翻译表。Source: `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`。
