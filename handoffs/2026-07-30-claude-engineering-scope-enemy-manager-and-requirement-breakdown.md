# `.claude` 定位定案 · EnemyManager 收并意图 · 需求拆解闭环

- id: 2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown
- date: 2026-07-30
- topic: `.claude`（rules / skills / knowledge 的定位与主从关系）、systems/services/combat-service、ux/combat-ux、ux/screen-flow、systems/adventure-event、requirements（流水线）、open-questions（重组）
- status: distilled
- distilled-to: decisions/ADR-0005-knowledge-thin-reference-layer.md, systems/common-properties.md, systems/services/combat-service.md, systems/services/_index.md, systems/architecture.md, systems/_index.md, systems/adventure-event/_index.md, program-overview.md, system-overview.md, terminology.md, ux/combat-ux.md, ux/screen-flow.md, requirements/_index.md, README.md, open-questions.md, answer-logs/log-0730.md, .claude/rules/Context.md, .claude/README.md, .claude/knowledge/autoloads/_index.md, .claude/skills/breakdown-requirements/（新增）, `requirements/_TEMPLATE-sub.md(新增)`, `.claude/skills/breakdown-requirements/(新增)`

## Intent（distilled）

一句话：**给 `.claude` 划死边界（工程层，设计只做引用）、把 IntentManager 降格并入 EnemyManager 且确立「意图通常不向玩家揭示」、补上 `derive → blueprint` 之间缺失的拆解环节、并把待答清单的焦点从内容充实切到系统机制细节。**

### 1. `.claude` 的定位 = 工程层；设计的主权在设计库（定案）

`.claude` **只承载两类东西**：

1. **工程相关的配置与规则** —— harness 配置（`settings.json`）、C#/Godot 互操作与场景 / 数据 / 存档 / UI / null 校验的工程纪律（`rules/*`）。
2. **可复用的技能** —— 推进项目的流程封装（`skills/*`）。

**一切设计相关的知识与细节都归设计分支**（`game-design-documents/` / `backend-design-documents/`）；`.claude` 内**只做引用与轻描述**（指路 + 一句话承重纪律），不承载设计的实质。

这条约定的作用是**划出主从关系**：`.claude` 的目的是**帮我实现我的想法**，而**愿景的内核活在设计库里**。因此：

- **设计性内容冲突 → 以设计库为准**（`.claude` 是从，必须跟着改）。
- **工程性约束冲突 → 以 `.claude/rules/*` 为准**（它是本机 / 本语言 / 本引擎的工程事实，设计库对此无权威）。
- 判据即「这句话的权威在哪一侧」：讲**游戏是什么**（机制、数值、字段、契约、流程）→ 设计库；讲**代码怎么写**（命名、生命周期、热路径、PATH / 工具、目录纪律）→ `.claude`。

这把 **ADR-0005**（此前只覆盖 `.claude/knowledge/*` 为薄引用）**扩展到整个 `.claude`**：薄引用不是 knowledge 一个文件夹的形态，而是 `.claude` 对**设计内容**的统一形态。

### 2. combat-service：IntentManager 并入 EnemyManager（定案）

- **IntentManager 不是一个独立 manager，它只是 EnemyManager 的一部分。** combat-service 的 manager 清单改为 **TurnManager / DeckManager / EnemyManager**；敌人意图的生成是 EnemyManager 的**内部职责之一**，与敌人实例状态、AI 行为选择同属一个组件。
- **敌人意图通常不向玩家揭示。** 这是对 Slay the Spire「意图常驻预告」的**有意背离**：默认玩家看不到下一步敌人要做什么。（"usually" 意味着存在例外，但例外条件未陈述 —— 见 Open questions。）

### 3. 逐类型 AdventureEvent 各自一次专门 session（流程意图）

九类 AdventureEvent 的机制细化**不在一次 handoff 里做完**：后续将**为每一类各开一次专门的 session**（Combat、Practice、Mystery、Exchange、Research、Explore、Social、Travel、Finale），逐类填充其 `systems/adventure-event/<type>/`。这解释了为何这些子文档目前仍是空占位 —— 它们在等各自的专场，而非被遗漏。

### 4. 寿元红字倒数的呈现细节（定案）

**呈现形态 = 静态标注（static annotation），位置 = EventOption 选择界面。**

- **静态**：不做持续跳动 / 计时器感的动画；数值随事件结算而变，平时静止。
- **位置**：只挂在 **EventOption 选择界面**（玩家做抉择的地方 —— 也正是寿元被消耗的地方），**不做全局 HUD、不进战斗内**。

这与「<10% 才显示、标红数值倒数、非常驻进度条」的既有定案闭合成完整规格。

### 5. 新技能 `breakdown-requirements`（闭合 design → code）

**缺口：** `/derive-requirements` 产出的 `FR-*` 是**从设计文档整片切下来的**，粒度往往偏大 —— 一个 FR 可能仍横跨数据、服务逻辑、场景与接线，直接喂 `/blueprint` 会得到一份过大的蓝图。

**补法：** 新增技能 **`/breakdown-requirements`**，输入是**一份** `derive-requirements` 产出的 FR 草稿，输出是**一个文件夹**，内含若干**更小的、可执行的**需求 —— 每个都小到能被 `/blueprint` 一次吃下。

这补齐了流水线的最后一环，使 **设计 → 代码 的链路真正闭环**：

```
20/40 主题文档 → /derive-requirements → FR-*（片区级）
                → /breakdown-requirements → FR-*/（拆解为可执行子需求）
                       → /blueprint → /implement
```

### 6. open-questions 重组：内容充实搁置，焦点转向系统机制细节

- **内容充实（enrichment of game content）搁置一旁** —— 卡牌 / 敌人 / 道具 / 各类事件的**具体条目目录与数值**不是当前焦点（与既定开发路线「框架 → 内容 → 平衡与体验 → 社交及其他」的第 ① 阶段一致）。
- **下一个焦点 = 各系统机制的细节** —— 例如**战斗机制**（回合循环内的效果 / 状态系统、意图与 AI、胜负与结算）、**eventOptions 的生成流程**（加权抽取、location 框定、PlotManager 调制的叠加顺序）等。
- 待答清单据此重组为**焦点 / 搁置**两层，让下一次拾取时不必在内容条目问题里翻找。

## Open questions

- **「意图通常不揭示」的例外条件是什么？** 定案说 "usually"，但**什么情况下会揭示**未陈述：特定敌人（首领必然预告？）、某些 PlayerPower / 道具授予「窥视意图」能力、某个 capability flag、还是随境界解锁？→ `systems/services/combat-service.md`、`systems/player-profile/player-power/`。
- **意图隐藏后，玩家凭什么做出牌决策？** Slay the Spire 的意图预告是其策略深度的主要信息来源；移除它之后需要**替代的信息面**（敌人类型 / 蓄力动画 / 上一回合行为的模式推断 / 完全靠试错记忆？）。这是战斗手感的承重问题，不能留白。→ `ux/combat-ux.md`、`systems/adventure-event/combat/`。
- **EnemyManager 内部是否还需再分职能？** 意图生成 / AI 行为选择 / 敌人实例与状态三者合一是否会让它过重（对照 TurnManager 的边界）？→ `systems/services/combat-service.md`。
- **`.claude/rules/*` 中夹带的设计性表述如何处理？** 主从关系已定，但现存规则文件里确实嵌着设计结论（例：`state-save-rules.md` 的确定性边界、`data-resource-rules.md` 的 `AllEnabled()` 语义）。这些是「一句话承重纪律 + 回链」的合法形态，还是应进一步瘦身？边界判据需要一次核对。→ `systems/common-properties.md`。
- **`/breakdown-requirements` 的子需求是否需要用户逐个签核？** 父 FR 有 `draft → ready` 的人工签核门；拆出的子需求若也逐个签核会很重，若完全不签核则父 FR 的签核语义会被绕过。当前技能实现取**「父 FR 签核即覆盖其子需求」**，子需求直接产出为 `ready` —— 需要确认这是否符合意图。→ `requirements/_index.md`。
- **`/breakdown-requirements` 的拆解粒度判据。** 当前技能定的是「一个子需求 = 一次 `/blueprint` 能一口吃下的薄纵切片，且自身验收标准可在 Godot 中跑出来」。粒度上下界（一个子需求最多改几个文件 / 是否允许纯数据资源型子需求）仍偏经验。→ 同上。
- **「内容充实」与「机制细节」的分界。** 本次解读为：**具体条目目录与数值 = 内容充实（搁置）**；**规则、字段语义、流程与算法 = 机制细节（焦点）**。但两者有交叠地带 —— 例如「`lifeSpanCost` 哪些事件类型覆写基准」既是机制也带数值，「`EventOption` 的完整物化字段清单」此前明确标注为「需要一次**内容侧** handoff」。这些交叠项归焦点还是搁置，需确认。→ `open-questions.md`。

## Notes / triage

- **修正一处矛盾：** `ux/combat-ux.md` 的文件头写着「intent 预告」，与本次「意图通常不揭示」的定案直接冲突 —— 已改写该文件头并在其 `## 意图` 中落下定案。
- **顺手修正一处过时残留：** `program-overview.md` 的核心循环示意图中仍写 `combat-service.RunCombat(character, encounter)`，与 07-27b 定案的 `RunCombatAsync(encounter, ct)`（不接收角色参数）不符；因本次要改同一代码块中的 `IntentManager` 行，一并对齐。
- **答结的待答项** 3 条（`.claude/rules` 主从关系、寿元红字倒数呈现细节、combat-service manager 清单中的 IntentManager 归属）已移出 `open-questions.md`，记入 `answer-logs/log-0730.md`。
