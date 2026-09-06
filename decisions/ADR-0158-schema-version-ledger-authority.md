# ADR-0158 — 存档 `schemaVersion` 的登记权威：独立成文的逐版登记表 + `ProfileShapeCheck` 护栏

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** handoffs/2026-09-03-schema-bump-ledger-authority.md

## 背景

存档 `schemaVersion` 此前**没有登记权威**。`sync-service.md` 里那张表开头写着「下列改动**合并为同一次 bump**」——它的形态天生是**一次**的；而表后一句自称把它宣布成了**所有 bump 的永久登记簿**。两者不匹配，于是每一次新的落笔都面临一个没有答案的问题：「我这一格该加进哪一行？」，而最省事的答案是**就地写一句「随本次落定 bump」**。那正是十余处平行自称与多类表外登记的产生方式。

后果不止是台账乱：**一个建立在「别人已登记」之上的免责，在没有人真的登记时会静默失效**。而「漏 bump」这类错误**能上线且线上不可见**。

## 决策

**存档 `schemaVersion` 的登记权威独立成文为 `systems/services/profile-schema-versions.md`：一行一个版本号，六列（版本号 / 本版纳入的结构改动 / 老档处置口径 / 触碰透明·回声路径 / golden 形状快照 / 权威回链）。**

- **语义 = 「每一版的形状」，不是改动流水账**——判据是它与 golden 快照严格同构、逐行对得上。**删除类改动因此不进 v1 行**；「删字段的老档处置口径」作为形态纪律写进说明区。
- **首发前的一切改动全部归入 `schemaVersion = 1`**，补齐是往同一行里补条目，**不产生任何新的 bump**。
- **全库就地 bump 自称一律改为回链**，固定句式「本字段属 `schemaVersion` 1，登记见 …」。**三类非自称表述一律不动**：否定式（「不 bump」）· 假设式（「日后若要做 … + 一次 bump」）· 纪律式（改名 / 移动透明路径必须 bump）。老档默认值口径留在字段所在处，不搬进登记表。
- **配护栏 `ProfileShapeCheck`，落到纪律阶梯第 2 级**（`decisions/ADR-0013-discipline-enforceability-ladder.md`）：载体是**签入 `game-feature-branch/` 的 golden JSON 快照**（带文件头注释「本文件由 `ProfileShapeCheck` 生成，不是规格」），**一份实现、两个触发点**——打包管线不通过不产包 + `#if DEBUG` 启动期。

## 理由

- **形态与自称必须匹配**：一张「一次 bump 的内容清单」承担不了「永久登记簿」的职责；拆成逐版表后，「我这一格加进哪一行」有唯一答案。
- **语义取「形状」而非「流水账」，是因为形状是本方案唯一可机检的兑现**——它与 golden 快照逐行对得上，流水账对不上任何东西。
- **`sync-service.md` 只留一句回链，全部回链一次性写对、不经它中转**：中转会让每一次查阅多一跳，且中转点本身就是漂移过的那一处。
- **护栏选级由既有判据直接推出**：漏 bump 能上线且线上不可见 ⇒ 第 3 级（断言）不够；而检查对象是序列化形状、不在 C# 类型系统作用域内 ⇒ 取「发布管线跑同一份校验」这个内容侧纪律的等价第 2 级。于是「文档没登记」与「代码没 bump」收敛成同一个可机检的事实。
- **归属取 `services/`**：`MigrationManager` 在那里。

## 备选方案

- **在 `sync-service.md` 内就地把那张表改造成登记表** — 否决：全部回链都得经它中转，而它是漂移的发源处；独立成文才能让回链一次性指对。
- **登记表按改动流水账书写** — 否决：无法与 golden 快照对账，护栏就失去比对对象。
- **护栏取形状指纹 hash 而非 golden JSON 文件** — 否决：hash 不可读，比对失败时看不出差在哪一格；golden 文件本身即诊断信息。
- **护栏只做到第 3 级（启动期断言）** — 否决：漏 bump 能上线且线上不可见，断言级挡不住。
- **首发前拆成多个版本号** — 否决：拆开只会让迁移器多几级空跳，而这些版本永远不会有真实存档。

## 后果

- **登记表是「某次结构改动属于哪一版」的唯一权威**；`systems/services/sync-service.md`「存档 schema 版本」只留一句回链。
- **顶层键与键内追加的分界须明写**：首次引入一个顶层键本身进 v1 行，此后在该键内追加一项不 bump。
- **`systems/architecture.md` 的字段删除流程指向登记表说明区的形态纪律**；三处流程里的「bump」改成「在登记表新增 / 追加一行」，不改成回链。
- **golden 快照落 `game-feature-branch/`**（生成物不进设计库），登记表每行只记该版文件名；首发前只有 v1 一版 ⇒ 只保留一份 golden 文件。
- **`ProfileShapeCheck` 的落地时点**依赖 `game-feature-branch/` 首次生成 `.csproj`，与那批实测项同批 → `open-questions/05-service-contracts.md`。设计形态不依赖它。
- 受约束的文档：`systems/services/profile-schema-versions.md`（新建 · 权威）· `systems/services/sync-service.md` · `systems/services/profile-service.md` · `systems/services/combat-service.md` · `systems/services/future-event-service.md` · `systems/character-profile/_index.md` · `systems/player-profile/_index.md` · `systems/adventure-event/common-properties.md` · `systems/common-properties.md` · `systems/architecture.md` · 五份既有 ADR 的就地自称改回链。
- **跨库对称**：后端兼容矩阵的输入、登记流程与漏登告警在 `backend-design-documents/`，两侧只回链、不复述。
