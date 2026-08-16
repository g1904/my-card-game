# 事件优先级、跳过语义、热更范围与 player-profile 子系统落位

- id: 2026-07-26-event-priority-skip-semantics-and-hotfix-scope
- date: 2026-07-26
- topic: systems/adventure-event/common-properties, systems/services/future-event-service, systems/services/content-service, systems/common-properties, systems/player-profile, systems/balance, systems/architecture, ux/screen-flow, terminology
- status: distilled
- distilled-to: terminology.md, systems/adventure-event/common-properties.md, systems/services/future-event-service.md, systems/services/content-service.md, systems/services/life-cycle-service.md, systems/common-properties.md, systems/architecture.md, systems/balance.md, systems/player-profile/**（新增 achievements/、account-info.md、game-setting.md）, ux/screen-flow.md, open-questions.md, .claude/rules/state-save-rules.md、`systems/player-profile/（_index + achievements/** 新增 + account-info.md 新增 + game-setting.md 新增）`、`answer-logs/log-0726b.md`

## Intent（distilled）

**一行摘要：** 一批**待答清单的定点裁决**——新引入 AdventureEvent 的**优先级**概念，敲定**跳过通道的玩法语义**，把**热更范围收窄为「只改不增」**并据此**放弃跨内容版本的 seed 可复现**，落位 **player-profile 子系统文件形态**，补全**元婴 +500 的用途**与**寿元告警的 UX 形态**。

### 1. AdventureEvent 优先级（新概念 · `eventPriority`）

- **优先级是 AdventureEvent 的又一个重要共有概念。** 通常的 AdventureEvent 优先级为 **0**；玩家可从本批 eventOptions 中**任选所有优先级为 0 的事件**。
- 一旦本批中出现**优先级为 1（或更高）的一个或多个事件**，玩家就**必须优先从高优先级的事件中选择一个**进入——低优先级的事件本轮被封锁。
- **推演（本 handoff 的解读，非用户原话）：** 有效可选集 = 本批中**最高优先级档**的全部事件；同档内玩家仍自由择一。若同时存在优先级 1 与 2，则只有优先级 2 的可选。
- 优先级与 `ifMandatory` 是**两条不同的约束轴**：`ifMandatory` 封锁的是**跳过通道**（必须面对），优先级封锁的是**同批内的其他选项**（必须先做这件事）。二者的叠加规则见 Open questions。

### 2. 跳过通道的玩法语义（缺口 5 主干闭合）

- **跳过 = 单项补位，不是整批刷新。** 一个可跳过的 AdventureEvent 被跳过后，由 **future-event-service 生成一个新的事件**顶替它的位置。
- **补位可能落空。** 也可能**没有新事件产出**——此时本批 eventOptions 就**少了一个选项**（不回填、不报错、不阻塞）。
- **跳过通常不扣 `lifeSpanCost`。** 即：跳过一个事件，时间**通常不流逝**。少部分事件可以带 **`skipCost`**（此时按其 element 扣减，寿元也可以是其中之一）。
- **跳过计入 `pastEvent`。** 被跳过的事件仍**记入修行历程**，作为一条**行为轨迹（类似 action-trace）**——它记录的是「玩家做过什么决定」，而不仅是「玩家经历过什么事件」。因此 `pastEvent` 需要能区分「已进入并结算」与「已跳过」两种痕迹。

### 3. `ifMandatory` 的产出侧规则

- **由服务在产出 eventOptions 时动态置位**，而非内容作者在 `.tres` 中写死。
- **一批 eventOptions 可以全部为 mandatory**（等同于本轮取消跳过权）。

### 4. 内容热更的范围边界（收窄）

- **热更范围 = 仅修改既有条目的数值 / 文案。** overlay **不得新增 `Id`**（不得热更新卡 / 新事件）。
- **推演：** 因此「旧版本客户端的存档引用到未知内容」这一风险**从根上消失**，先前所需的兼容规则不再必要；代价是**新内容只能随版本发布**，仍受应用商店审核周期约束。

### 5. overlay 与存档的版本耦合（确定性张力的裁决）

- **以 overlay 更新为准，不冻结轮回的 `contentVersion`。** 轮回进行中 overlay 被更新时，新数值**立即对进行中的轮回生效**。
- **不要求 seed 可复现。** 明确**放弃**「同一 seed 必然复现同一轮回」这一保证——它让位于「线上数值可随时修正」。
- **推演：** 确定性从「跨版本的绝对保证」降级为「**同一 `contentVersion` 内的性质**」。存档恢复仍必须正确继续（RNG 状态照常持久化），只是不再承诺跨内容版本可复现。这与 `.claude/rules/state-save-rules.md` 原先的措辞冲突，已一并修订。

### 6. player-profile 子系统的文件形态

- **文件夹（有子结构，需 `_index.md` + `common-properties.md`）：** `player-item/`、`player-power/`、**`achievements/`**（新增）。
- **独立 markdown（结构轻，单文件即可）：** `account-info.md`、`game-setting.md`。

### 7. 元婴 +500 的用途

- 该字段更新**值得保留**：它用于**确保元婴界面的数据显示正确**——元婴界面是一块**类似「通关证书」的终局展示面**，需要读到最终寿元值。
- 因此 +500 仍不是平衡杠杆（不产生可消耗预算），但它**有明确的读者**，不是死字段。

### 8. 寿元 <10% 的 UX 形态

- **显示表达 = 标红的数值倒数（red count-down numeral）。** 低于 10% 时寿元由隐藏转为在屏显示，以**倒数中的红色数值**呈现紧迫感——而非常驻进度条。

## Open questions

- **优先级与 `ifMandatory` 的叠加规则。** 一个高优先级事件**能否被跳过**？若可跳过且被跳过，本轮是否解除对低优先级事件的封锁？二者都限制玩家选择权，是否存在语义重叠（高优先级是否应蕴含 mandatory）？
- **优先级的取值域与置位方。** 优先级是布尔式的两档（0 / 1）还是任意整数档位？是否与 `ifMandatory` 一样由 future-event-service / PlotManager 在产出时**动态置位**（用户只说了 `ifMandatory` 由服务置位，未说优先级）？
- **补位落空的判定规则。** 「也可能没有新的」——在什么条件下 future-event-service 补不出事件（事件池耗尽？优先级/剧本约束不允许？）？eventOptions 是否允许被跳到只剩 0 个？若剩 0 个，玩家如何推进（死局兜底）？
- **全部 mandatory + 付不起 `selectCost` 的死锁。** 一批可以全部 mandatory，且高优先级会封锁其余选项；若玩家付不起唯一可选事件的 `selectCost`，轮回将无法推进。是否需要「至少一个可负担选项」的产出侧保证，或一条兜底降级？
- **`pastEvent` 的痕迹 schema。** 既然跳过也计入，`pastEvent` 需区分「进入并结算」与「跳过」两种痕迹（以及各自付出的成本）；其字段形态未定。
- **放弃 seed 可复现的连带影响。** bug 复现、未来若做每日种子 / 排行挑战都依赖可复现性。是否仍应在存档中**记录轮回开始时的 `contentVersion`** 以便诊断与事后归因？
- **只改不增的内容节奏代价。** 新事件 / 新卡只能随版本发布；是否需要「预埋占位 `Id`、后续用 overlay 填充其数值与文案」这类策略来部分绕开审核周期？
- **元婴界面（通关证书）的具体形态。** 它展示哪些字段（最终寿元、用时、修行历程摘要、成就？）、何时弹出、是否可回看 / 分享——均未定。→ `ux/screen-flow.md`。
- **寿元红字倒数的呈现细节。** 「倒数」是随每次事件结算逐格递减的数字，还是持续跳动的计时感？它常驻哪些屏幕（选择区 / 战斗内 / 全局 HUD）？是否伴随音效 / 震动？→ `ux/screen-flow.md`、`ux/combat-ux.md`。
- **achievements / account-info / game-setting 三份新文档尚是空占位**，其字段 schema 与触发规则仍待后续 handoff 播种。

## Notes / triage

- 本 handoff 是一次**待答清单定点裁决**，不引入新系统，全部落点为既有文档的既有小节。
- 从 `open-questions.md` 移出的条目见 `answer-logs/log-0726b.md`。
- 架构闭环缺口 5（skip 通道）主干语义已定，状态由「部分闭合」改为「已闭合」；残留细节下沉为普通待决问题。
