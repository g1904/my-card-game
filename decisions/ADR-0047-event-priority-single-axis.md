# ADR-0047 — `eventPriority` 是选择约束的唯一一条轴：两档、服务独占置位、抬升写判据不写清单

- **状态：** Accepted
- **日期：** 2026-08-06
- **来源：** handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md, handoffs/2026-08-22-priority-elevation-criterion.md

## 背景

跳过通道移除后（→ `ADR-0046`），「这一批必须选某一类」这件事需要一个表达面。此前它散落在 `ifMandatory`、闸门标记与优先级三处。

而抬升条件最初被写成**一张清单**（「Travel 配额用尽时抬升」「Finale 满级时抬升」…）——一张会随每个新场景不断被追加的清单，且没有判据可以判断某个新场景该不该进这张清单。

## 决策

**选择约束只有一条轴：`eventPriority`。** 取值域**两档**（`0` / `1`），由 **future-event-service 独占动态置位**——PlotManager 不得改。

**抬升写判据，不列清单：抬升当且仅当不抬升会使一条结构性规则失效。** 三条与门子判据：该事件是那条规则的唯一出口 · 判定可在产出侧确定地做出 · 它表达的是结构而非难度叙事。

判据全文与伪码 → `systems/services/future-event-service.md`（独占权威；`adventure-event/common-properties.md` 只回链不复述）。

## 理由

一条判据可以回答无穷多个新场景，一张清单只能回答已经写下的那些。这是把纪律从「记住这几条」抬到「可机械判定」的一次应用（→ `ADR-0013`）。

独占置位的理由：若剧本也能改 priority，就出现了两个都能决定「这批必须选什么」的主体，而它们的意图冲突时没有仲裁规则。剧本的表达面是**权重调制**，不是**闸门**。

## 备选方案

- **列一张会被追加的抬升条件清单** — 否决：无判据可判新场景该不该入列。
- **`1` 档内再排序** — 否决：等于引入第三档。
- **允许 PlotManager 置位** — 否决：制造第二个闸门主体，冲突无仲裁规则。
- 另有**六条候选抬升条件**逐条被否，留痕在 `answer-logs/log-priority-elevation-conditions.md`。

## 后果

- Travel 的闸门语义由 `eventPriority = 1` 表达，**没有 `IsMandatory` 字段**（→ `ADR-0043`）。
- 「同批出现多个 `1` 档」在当前生成伪码下**结构不可达**，故不新增收窄规则。
- 满级 Finale 走闸门式旁路，是十步管线的一步（→ `ADR-0026`）。
