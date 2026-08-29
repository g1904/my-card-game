# ADR-0100 — 美术方向 = 绘画感中式卡牌插画 × grimdark 仙侠

- **状态：** Accepted
- **日期：** 2026-07-13
- **来源：** handoffs/2026-07-13.md

## 背景

本作是仙侠题材的卡牌构筑游戏，而「仙侠」在既有作品里的默认观感是祥和、飘逸、浪漫的。同时它在玩法上向 Balatro / Slay the Spire 取经，而 Balatro 的视觉是温馨明快的。若不先把风格取向钉死，美术资产由 Midjourney 分次生成、没有共同上游，必然向这两个默认值漂移。

## 决策

美术方向取 **具绘画感的中式卡牌游戏插画（三国杀 / 弈仙牌 一路）× grimdark 仙侠基调**：阴郁、高风险、不浪漫，取 Warhammer 40k 的**精神**而非其设定。明确不要温馨、明快、低风险的观感。修仙被表现为残酷的攀登，境界越高画面越沉。

借三国杀 / 弈仙牌的**画风与氛围，不借其卡面排版**——本作卡面为 full art，不预留文字区。

色板、光照材质、构图等逐项约束仍在推敲，落点是 `art/visuals/art-direction.md` 的对应小节；本 ADR 只固定其上位的风格取向。

## 理由

「好看的中式插画」不等于「祥和的仙侠」——这两件事在参照物里通常绑定，不拆开写就会被默认绑定。grimdark 与「黑暗剧情、后果沉重、常常残酷的结局」这条设计支柱同源（`vision/pillars.md`），它约束的不只是画面，还有叙事与数值的体感；而对 Balatro 的规避是明写的，其温馨低风险基调正是本作要避开的那一面（`vision/references.md`）。

跨资产的风格一致性只能由一份公共约束承担：每份 art guide 继承 `art/visuals/art-direction.md`，没有这个共同上游，分次生成的资产必然漂移。

## 备选方案

- **走主流仙侠的祥和 / 飘逸观感** — 否决：与「黑暗剧情」支柱和残酷攀登的叙事直接矛盾。
- **借 Balatro 的明快视觉以贴合它的玩法手感** — 否决：`vision/references.md` 已明写对 Balatro 只借玩法结构、规避其基调。

## 后果

- `art/visuals/art-direction.md` 是本方向的权威落点，全部 art guide 继承它；`art/_index.md` 的约束表与 `vision/pillars.md`、`vision/references.md` 与本条同向。
- 卡面为 full art、不预留文字区，因此不能沿用参照作品的排版 → `ADR-0083`。
- 插画内不得烧入承载可翻译语义的文字 → `ADR-0084`。
- 音频基调随视觉基调对齐 → `art/soundtracks/audio-direction.md`。
- grimdark 的低饱和与「手机上清晰可读」的高对比需求如何调和，是本方向留下的待决张力，归 `art/visuals/art-direction.md` 的色彩小节。
