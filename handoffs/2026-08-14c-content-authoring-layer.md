# 内容创作层开张：`content/` 目录 + 三个内容技能

- id: 2026-08-14c-content-authoring-layer
- date: 2026-08-14
- topic: content/（新建一级分区）· README（流水线 + 文件夹图例）· `.claude/skills/`（三个新技能）
- status: distilled
- distilled-to: `content/_index.md`、`README.md`、`.claude/skills/{author-content,audit-content,scaffold-content-type}/SKILL.md`、`content/_TEMPLATE-type.md`、`content/_TEMPLATE-entry.md`

## Intent（distilled）

项目正走向**内容创作阶段**。此前设计库只承载**类定义**（「一张卡牌有哪些字段」「地域携带哪三组字段」），没有承载**条目实例**（「云梦泽这个地域具体是什么」）的地方——README 明写「内容即系统的字段 / 内嵌类型，**没有独立的内容层**」。本次开张这一层。

**工作流（用户原话的结构化）：** 用户为某个游戏概念（剧本 / 地域 / 法则 / 成就 / 古宝 / 功法 / 角色 / …）写一份 markdown 草稿 → 一个技能对其中的存疑处发起 interview → 把草稿打磨成一份**完整的、可直接交给 `/blueprint` 的内容设计文档** → 落在设计库中一个有组织的位置。

### 四项裁决（本次 interview 产出）

**① 技能粒度 = 单一通用技能 + 类型档案，不是每类一个技能。**
`/author-content <类型> <草稿>` 一个技能覆盖全部内容类型；「这类内容有哪些字段」由**设计库里该类型自己的档案**（`content/<类型>/_index.md`）回答，技能只负责流程。

- 依据是 **ADR-0005**：字段清单是**设计性内容**，权威必须在设计库。每类一个技能会把十几份字段清单复制进 `.claude/skills/`，直接制造第二权威——两份表会各自漂移，而本库没有任何机制能发现它们不一致（与 08-14 判据卡的硬边界逐字同构）。
- **推论：新增一个内容类型 = 在设计库写一份类型档案，不需要新建技能。** 技能数量因此不随内容类型数增长。

**② 落点 = 新建一级分区 `content/<类型>/<id>.md`，与 `systems/` 平级。**

- **分工（承重）：`systems/` 持有「这类内容怎么运作」（类定义），`content/` 持有「有哪些条目」（实例）。** 二者是类 ↔ 实例关系，不是父子关系，故平级而非嵌套。
- **否决「写进 `systems/` 对应子树」**：条目数量会增长到成百上千，把实例塞进类模型树会让 `_index.md` 的索引职责失效——那棵树是**按概念结构**组织的，不是按数量组织的。
- **否决「每类一个大文件」**（`content/cards.md` 内含全部卡牌）：单文件必然膨胀到几千行，且多条目并行编辑必然冲突。
- **推论：`README.md` 中「没有独立的内容层」这句作废**，本次一并改写。

**③ 交付链路 = 内容条目文档直接喂 `/blueprint`，不经 `requirements/FR-*`。**

- 依据：FR 那一层的价值是把**系统行为**切成「可独立构建的增量 + 验收标准」；而内容条目最终落地就是**一批 `.tres`**，它的「可构建增量」边界天然就是条目本身，再切一刀只是纯开销。
- 代价（如实记下）：内容不进 `requirements/_index.md` 的台账，故**内容的完成度追踪落在 `content/_index.md` 自己身上**，不能靠 FR 台账。这是接受的取舍。

**④ 配套技能两个：`/audit-content`（内容对账）与 `/scaffold-content-type`（新类型开张）。**
成批策划技能（`/plan-content-batch`）本次不做。

## 内容类型登记（一次全量盘点）

从 `systems/` 类模型与 `terminology.md` 盘出的候选内容类型见 `content/_index.md` 的登记表（含各类的字段就绪度与开张状态）。盘点中确定的两条边界：

- **图鉴（Codex）不是独立内容类型。** `player-profile/codex/_index.md` 已定案「条目内容是静态文案，**挂在对应的内容 `Resource` 上**；存档只记解锁状态」⇒ 图鉴词条是那六个宿主类型（敌人 / 神通 / 法则 / 法宝 / 古宝 / 地域）**条目文档里的一个字段块**，不单开一个 `content/codex/`。单开等于给同一份文案造两个落点。
- **异能 / 效果 / 触发条件（`AbilityData` / `EffectData` / `TriggerConditionData`）是卡牌 · 神通 · 法则 · 法宝 · 古宝五类的共同底座。** 它们的语法未定案前，那五类的条目**写不实**——只能写出风味文案与意图，写不出可 blueprint 的效果定义。这条依赖关系写进登记表的就绪度列，由 `/scaffold-content-type` 的就绪度闸门执行。

## Open questions

**三项已于 2026-08-15 全部答定** → `handoffs/2026-08-15-content-id-technique-shape-and-subtype-reset.md`：条目 id = `<内容类型>.<snake_case_slug>`（含前缀词表纪律）· 事件类与剧本本阶段不开展 · **一份条目文档 = 一个 `.tres`**（功法与它的卡牌是若干份彼此引用的文档，功法持卡牌 `Id` 列表）。

## Notes / triage

本 handoff 同时改动了 `.claude/`（三个新技能 + 导航 / 清单更新）。按根约定，技能属**工程层**、字段清单属**设计层**，两者的分界即本次裁决 ① 的依据。
