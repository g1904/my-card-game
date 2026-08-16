# 美术 / 音频设计库落位：新增 `art/` 与 AI 驱动的资产生产流水线

- id: 2026-08-04-art-audio-library-scaffold
- date: 2026-08-04
- topic: art/（新增顶层文件夹）、vision/references.md、README.md
- status: distilled
- distilled-to: art/**（新建）, vision/references.md, vision/pillars.md, README.md, terminology.md, open-questions.md, open-questions/deferred-content.md, .claude/rules/Context.md, `art/**（新建 12 份）`, `vision/（references.md, pillars.md）`, `open-questions/（deferred-content.md, update-log.md）`, `answer-logs/log-0804.md`

## Intent（distilled）

**一句话：** 在设计库中新增 `art/` 顶层文件夹，作为**美术与音频**的设计意图与生成指导材料的落位；本次只做**脚手架**——把文件结构立起来，日后有时间做美术时能把零散信息粘贴到正确位置。

### 1. 文件夹结构

`art/` 下设**两个一级分区**，动画是**视觉的子分区**：

| 分区 | 状态 | 内容 |
|------|------|------|
| `visuals/` | 已定 | 一切**视觉**资产的方向、参考与生成指导（卡面、敌人、角色、事件插图、UI、图标、背景）。 |
| `visuals/animations/` | **占位** | 会有一些动画，但**先咨询专业人士再充实**——本次只立空骨架，不预设形态。**动画是让视觉资产动起来，同属视觉线**，故在 `visuals/` 之内而非与之并列；继承视觉总方向，但**不走 AI 流水线**，故不设 `guides/`。 |
| `soundtracks/` | 已定 | 一切**音频**资产的方向、参考与生成指导（BGM、氛围、音效）。 |

### 2. 生产流水线（人机协作三段）

```
① 人：给出 vision + 参考素材
      └─▶ ② AI：依 vision 与参考写出 art direction / art guide（= 结构化的生成 prompt）
                 └─▶ ③ 参考素材 + art guide 一并投喂 Midjourney → 生成资产
```

- **音频同流程**：vision + 参考 → AI 写 audio guide → 投喂生成工具（**倾向 Suno，尚未定案**——Midjourney 不产音频。可暂按 Suno 组织 prompt，但工具专属语法不写死进模板，prompt 正文保持工具无关）。
- **动画不走这条流水线**（至少目前）：先咨询专业人士。

### 3. 由此逻辑推出的结构含义（充实，非新增决策）

- **本库承载 ①②，不承载 ③ 的产物。** `game-design` 是纯文档的孤儿分支（见 `README.md`），生成出来的图 / 音**二进制资产归 `game-feature-branch/`**。本库存的是 vision 文本、参考登记、art guide 文本。
- **需要一份总的 art direction 作为所有 prompt 的公共约束。** 资产由 Midjourney **分次**生成，风格漂移是必然风险；单份 guide 只能保证单张，跨资产的一致性必须由一份共同的方向文档承担 —— 故 `visuals/art-direction.md` 与 `soundtracks/audio-direction.md` 是每份 guide 的**上游**，而非可选补充。
- **art guide 是可迭代的。** 一次生成不满意 → 改 prompt 重跑；模板须留「产出与迭代」栏，记住哪版 prompt 出了可用结果，否则下次要从零试错。
- **每份 guide 绑定一个资产类目**，才能与 `systems/` 的内容条目对齐（一张卡面对应哪张 `CardData`、一个敌人立绘对应哪个 `EnemyTemplate`）。
- **参考素材须登记「借什么 / 不借什么」**，沿用 `vision/references.md` 既有的具体化约定 —— 泛泛的「参考三国杀」无法转成 prompt。

### 4. 继承的既有约束（美术 / 音频不得违反）

- **画风：** 三国杀 与 弈仙牌 式的、具有绘画感的中式卡牌游戏插画；竖版卡面构图。Source: `vision/references.md`。
- **基调：** grimdark 仙侠 —— 阴郁、高风险、不浪漫（Warhammer 40k 的精神，不是它的设定）；**不温馨**（这是对 Balatro 的明确规避）。Source: `vision/pillars.md`。
- **技术约束：** 必须在**手机尺寸下清晰可读**，并处在 **GL Compatibility** 渲染器的限制之内；竖屏优先。

## 已答定（同轮追加）

- **`animations/` 归属 = `visuals/` 之内。** 原文只说「visuals 与 soundtracks 两个文件夹」却又提到 animations 一节，一度解读为三个并列分区；**已裁定为：动画属于视觉**（同一条视觉线、同一套基调与技术约束），落位 `visuals/animations/`。连带 → **一级分区确定为两个**、动画继承 `visuals/art-direction.md`（不另起视觉语言）、且因不走 AI 流水线故**不设 `guides/`**。
- **音频生成工具倾向 Suno（未定案）。** 方向已给但**不拍板**，故：guide 可**暂按 Suno 的形态**组织，但**工具专属语法不得写死进模板**——prompt 正文保持工具无关，换工具时正文仍可复用。

## Open questions

- **音频工具的最终定案**（Suno vs Udio vs 其他）仍待拍板；定案前 audio guide 的「参数」栏保持工具无关。
- **art guide 的粒度未定：** 一个内容条目一份 guide，还是一个类目一份 guide + 逐条目只填变量（主体描述、构图差异）？后者更能保证风格一致，但表达力更弱。
- **生成资产落地 `game-feature-branch/` 的命名与导入规则未定：** 文件名如何与内容条目的 `Id` 对齐、目录如何划分、是否需要一份 asset 清单来做「内容条目 ↔ 资产」的完备性校验。
- **参考素材的二进制是否入库未定：** 本库是纯文档孤儿分支；参考图片本身是放进 `art/**/references/`（会让文档分支变重），还是只登记来源链接与文字描述。
- **`visuals/animations/` 的范围未定：** 卡牌打出 / 结算特效、立绘动效、UI 转场、战斗反馈动画分属完全不同的技术路径（Godot `AnimationPlayer` / 骨骼 / 粒子 / shader —— 后者还受 GL Compatibility 限制）。待咨询专业人士。
- **AI 生成资产的商用授权与参考素材来源合规口径未陈述**（生成工具的商用条款、参考素材的版权边界）。游戏是要发行的产品，这一条迟早要有明确立场。
