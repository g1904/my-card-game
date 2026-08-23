# Answer log priority-elevation-conditions

- 日期：2026-08-22
- 来源：`inbox/solution-draft-priority-elevation-conditions.md` → `handoffs/2026-08-22-priority-elevation-criterion.md`
- 移出条数：1（含三个子结论）

---

**`Priority = 1` 依什么条件抬升（配额闸门与开局构筑事件之外还有哪些），以及同批多个 `1` 档是否需额外收窄规则** → 整条答定，移出 `open-questions/02-event-options.md`。三个子结论：

1. **抬升判据 = 「不抬升会使一条结构性规则失效」+ 三条与门子判据**（唯一出口 / 产出侧可确定判定 / 表达结构而非难度叙事）。写判据不写清单，与物化判据 / 快照判据并列成为本服务的第三条判据。（→ `systems/services/future-event-service.md`）

2. **清单闭合为三条**：配额闸门 Travel（`LocationEventCount >= EventCountLimit`）· 开局构筑事件（`chapter == 1` 且 `pastEvent` 为空）· Finale（`level == 该境界末级`）。Finale **采纳抬升**，代价是取消备战窗口，退让位走内容编排与 `balance.md` 的三条难度校准手段、不回退抬升；开局构筑事件**收窄为炼气新角色的起始批次**，ch1 篇章重试落在收窄之内、照常抬升。另明写六条被否决的候选。（→ `systems/services/future-event-service.md` · `systems/adventure-event/research/_index.md` · `systems/adventure-event/combat/_index.md`）

3. **同批多个 `1` 档不新增收窄规则**：在当前伪码下该分支结构不可达（三条抬升条件两两互斥），且两档语义已含「同档内自由择一」的兜底，而任何「`1` 档内再排序」等于引入第三档。连带删去 `adventure-event/common-properties.md` 中「与剧情线的强制事件共用同一档」这半句。（→ `systems/services/future-event-service.md` · `systems/adventure-event/common-properties.md`）

> **剩余部分仍留在待答清单：** 「三条抬升子判据作为准入闸的密度成本」是本次新产生的 `[采纳推荐 — 待复核]` 项，按推荐落笔但**不算用户拍板**，须并回 `open-questions/02-event-options.md`。
