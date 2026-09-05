# 存档 `schemaVersion` 的登记权威：拆出逐版登记表、补齐首发形状、回链收口、形状护栏

- id: 2026-09-03-schema-bump-ledger-authority
- date: 2026-09-03
- topic: systems/services/profile-schema-versions · systems/services/sync-service · systems/character-profile · systems/services/profile-service · systems/architecture · decisions/ADR-0021 · ADR-0122 · ADR-0126 · ADR-0127 · ADR-0128 · ADR-0132
- status: distilled
- distilled-to: systems/services/profile-schema-versions.md（新建）· systems/services/sync-service.md · systems/character-profile/_index.md · systems/services/profile-service.md · systems/services/combat-service.md · systems/services/future-event-service.md · systems/player-profile/_index.md · systems/adventure-event/common-properties.md · systems/adventure-event/exchange/common-properties.md · systems/common-properties.md · systems/architecture.md · decisions/ADR-0021 · ADR-0122 · ADR-0126 · ADR-0127 · ADR-0128 · ADR-0132 · open-questions/cross-boundary.md
- counterpart: `backend-design-documents/handoffs/2026-09-03-schema-bump-ledger-authority.md`（后端半：兼容矩阵的输入、登记流程与漏登告警。**只回链、不复述**）

## Intent（distilled）

**一句话：** 存档 `schemaVersion` 此前没有登记权威——`sync-service.md` 里那张表形态上是「一次 bump 的内容清单」，却被一句自称宣布成了「所有 bump 的永久登记簿」。本次把它改造成**逐版登记表**并拆成独立文档，补齐全部漏登项，把散在全库的就地 bump 自称改成回链，并给「漏 bump」配一条可机检的护栏。

### 病因

上表开头写着「下列改动**合并为同一次 bump**」——它的形态天生是**一次**的；而表后那句自称把它宣布成**永久唯一**的。两者不匹配，于是每一次新的落笔都面临一个没有答案的问题：「我这一格该加进哪一行？」，而最省事的答案是**就地写一句「随本次落定 bump」**。那正是十余处平行自称与多类表外登记的产生方式。

**一个建立在「别人已登记」之上的免责，在没有人真的登记时会静默失效**——`ADR-0128` 的免责论证形式上有效，但它依赖的两个前提在权威表里都是假的。

### 五项落地

**① 权威落点独立成文。** 新建 `systems/services/profile-schema-versions.md`，**一行一个版本号**，六列（版本号 / 本版纳入的结构改动 / 老档处置口径 / 触碰透明·回声路径 / golden 形状快照 / 权威回链）。归属取 `services/`（`MigrationManager` 在那里）；`sync-service.md`「### 存档 schema 版本」只留一句回链，**全部回链一次性写对，不经 `sync-service.md` 中转**。

**② 语义 = 「每一版的形状」，不是改动流水账。** 判据是它与 golden 快照严格同构、逐行对得上——那是本方案唯一可机检的兑现。**删除类改动因此不进 v1 行**：三个被删的 `Status` 格从未存在于任何真实存档中，而 v1 是首发形状。「删字段的老档处置口径」作为形态纪律写进说明区（适用于 v2+），并由 `architecture.md` 删除流程第 ⑤ 步指过来。

**③ 首发形状全量补齐。** v1 行共 27 条，覆盖两层 Profile 顶层字段、`Status`、`ProfileChangeSpec` 各列、`EventOption` 物化字段、`PastEventEntry`、`ActiveCombat`。**不产生任何新的 bump**——首发前的一切改动全部归入 `schemaVersion = 1`，补齐是往同一行里补条目。

**④ 回链收口。** 24 处就地自称 + 5 份 ADR 改为固定句式「本字段属 `schemaVersion` 1，登记见 …」。**三类非自称表述一律不动**：否定式（「不 bump」）· 假设式（「日后若要做 … + 一次 bump」）· 纪律式（改名 / 移动透明路径必须 bump）——它们讲的是规则，回链掉会毁掉规则本身。**老档默认值口径留在字段所在处**，不搬进登记表。三处「五步」流程只把「bump」改成「在登记表新增 / 追加一行」，不改成回链。

**⑤ 护栏 `ProfileShapeCheck`，落到纪律阶梯第 2 级。** 漏 bump **能上线且线上不可见** ⇒ 选级判据明写第 3 级不够；检查对象是序列化形状、不在 C# 类型系统作用域内 ⇒ 取「发布管线跑同一份校验」的等价物。载体是 **golden JSON 快照文件**（签入 `game-feature-branch/`，带文件头注释「本文件由 `ProfileShapeCheck` 生成，不是规格」）。一份实现、两个触发点：打包管线不通过不产包 + `#if DEBUG` 启动期。于是「文档没登记」与「代码没 bump」收敛成同一个可机检的事实。

## Clarifications（interview 产物）

- **统计层新增字段是否 bump —— 两侧写反了？** → 取「区分引入顶层键与键内追加」：首次引入 `statistics` / `disabledAbility` 两个**顶层键**本身进 v1 行；此后在 `statistics` 内加一项计数不 bump。两侧各补一句分界，**不推翻任何一侧**。这细化了草稿补齐清单里「`disabledAbility` · `PlayerProfile.statistics`」的措辞。
- **后端矩阵本批登不登 `schemaVersion = 1`？** → 登。客户端 v1 既已定案，等待就是无成本的反序；且第四列回链若无行可挂，本方案的核心交付物落笔当天即无处可指。（落笔在对侧库。）
- **删除类改动如何进登记表？** → 只描述形状，删除类不进 v1 行；处置口径进说明区。这推翻了草稿 §5 补齐清单 #4 与 §6 的写法。`ADR-0127` 补的第 ⑤ 步措辞随之定为「首发前删除 ⇒ 不进任何版本行、无老档可处置」。
- **新文档在 `systems/services/_index.md` 如何登记？**（标准默认，未占 interview）→ 服务清单表下另加一句「非服务 / 非 manager 文档」说明，点名本文档及其宿主 `sync-service`。`⊃` 记法带「manager 级」显式限定，复用需同批改写定义，成本高于一句话。
- **golden 快照的落点？**（标准默认）→ `game-feature-branch/`。二进制 / 生成物不进设计库；登记表每行只记该版 golden 文件名。
- **首发前是否为多版本回归先造目录？**（标准默认）→ 不造。只有 v1 一版 ⇒ 只保留当前版一份 golden 文件。

## 补齐过程中核实出的两处订正

- **`profile-service.md` 的同型自称实为 8 处**（不是草稿说的 1 处），`architecture.md` 的「五步」实为 3 处（含 `profile-service.md` 的可加性五步）。回链改动面因此从 13 处扩到 24 处、ADR 从 4 份扩到 5 份（`ADR-0021` 是第五份）。
- **`ADR-0132` 属「未登记」而非「重复登记」**——它没有声称已随某次 bump 登记，只写了「成本此刻恒为零」。改法仍是补回链，但归因不同。
- **`character-profile/_index.md` 的一处残留失真同批修掉**：小标题写「隐藏属性档位与篇章寿元预算（四个字段）」而其下只剩两格。

## Open questions

- `ProfileShapeCheck` 的**落地时点**依赖 `game-feature-branch/` 首次生成 `.csproj`（`open-questions/05-service-contracts.md` 的既有实测项）。**设计形态不依赖它**，只是实现排期宜与那两条实测同批。本次不把该实测项标记为已答结。
- `systems/player-profile/game-setting.md` 与 `systems/services/account-service.md` 定义的若干 `user://cache/` 小文件各自独立的 `schemaVersion`，**与存档 schema 无关、不进本登记表**；但「哪些 `user://` 文件带版本」的判据散在两处，是否需要同类收口未定。

## Notes / triage

- 输入：`inbox/solution-draft-schema-bump-ledger-authority.md`（用户已评审，四项已裁决 + 两项取向已定）。
- 跨库：本次两侧同批落笔，**不开一条当场即关的承接条目**；两侧各在 `open-questions/cross-boundary.md` 说明区补一句常规触发源。
