# v1 首发形状的覆盖空缺补齐、计数退出登记表、条目维度的对账断言

- id: 2026-09-05-schema-ledger-v1-coverage
- date: 2026-09-05
- topic: systems/services/profile-schema-versions · decisions/ADR-0127
- status: distilled
- distilled-to: systems/services/profile-schema-versions.md · decisions/ADR-0127-life-merged-into-lifespan.md

## Intent（distilled）

**一句话：** 逐版登记表建成后的首次覆盖核实。原问题条目所指的「四批漏登」经逐条核对**已不成立**（三批已在表内、一批由删除类纪律有意不登）；真正的残留是**登记表自身的三类空缺**——v1 行漏登 11 处首发形状、表内一处无法核对的计数、以及「登记表条目 ↔ 字段表行」这一段无人对账。本次三项一并收口。

### 病因：护栏的射程与漏登的射程错位

`ProfileShapeCheck` 比对的是**代码形状 ↔ golden 文件**，它把「文档没登记」与「代码没 bump」收敛成同一个可机检事实——但**只在版本号维度**（每行记下该版 golden 文件名），不在**条目维度**。于是「golden 文件 ↔ 登记表文本」这一段是敞开的：漏一格不会让任何一侧报错，golden 快照照样带上那个字段、护栏照样通过，而照表写迁移器的人会漏格。本次 11 处空缺，护栏一条都抓不到。

计数是同一个失效模式的另一面。表内写下一个「22 格」，它既不来自任何字段表，也无法被 golden 快照核对——形态纪律 ① 要求本表与快照逐行对得上，而**没有任何文档能推出 22**。护栏一旦落地，这一行会必然对不上，成为它的第一条假阳性；而假阳性正是护栏最容易被关掉的死法。

### 三项落地

**① v1 覆盖空缺补齐，追加 #28–#33。** 与两层 Profile 字段表逐格对位后，下列结构在表内零处出现：`CharacterProfile` 的 `status` / `chapter` / `realm` / `level` 四格与 `magicPack` / `characterPower` 两个持有列表顶层键；`PlayerProfile` 的 `characterProfile` 容器顶层键、`playerPower` / `playerItem` 两个持有列表顶层键；`AccountInfo` 除 `AccountSeed` 外的 `AccountId` / `CreatedAtUtc` / `Identities` / `Nickname`。按形态纪律 ⑤ 第一档，顶层键是浅合并的最小替换单位，引入即进版本行；按形态纪律 ①，每一格都会在 golden 文件里出现，表里找不到对应行就是本表要消除的那种不一致。

- **`AccountInfo` 补登的依据是形态纪律 ①，不是 ⑤ 第三档。** 那一档讲的是「向受回声约束顶层键**追加**字段」，而本次是把既有格补进登记；且 `AccountId` **不在后端写入封闭表内、不受回声约束**（`systems/player-profile/account-info.md`）。补齐的是登记文本，不是形状。
- **`achievement` 不补，改留一句有承载的占位。** `Achievement` 条目 schema 仍是 `systems/services/profile-service.md` 的一条待决问题；在唯一登记面上写一个推测形状会被当作权威照抄进迁移器，比空着更危险。
- **一处错归属同批订正：** 行 #18 原写「`PlayerProfile` 引入 `statistics` 与 `disabledAbility` 两个顶层键」，而 `disabledAbility` 是 `CharacterProfile` 的键、已由行 #10 登记。#18 收敛为只登 `statistics`，权威列相应收敛。
- **零 bump、零迁移、对后端零义务。** 全部落在 `schemaVersion = 1` 行内，首发形状本就含这些格。后端兼容矩阵的触发点是登记表**新增一行版本**，v1 行内补条目不构成触发；本次也不移动 / 不重命名任何透明或回声路径。

**② 计数退出本表，立为形态纪律 ⑥。** 行 #12 的「22 格」删计数改回链，`ADR-0127` 的两处同源计数同批订正（`Status` 的结构收缩改写为「删三格」，结论一字不变）。同时把「本表不写任何计数」立为纪律第 ⑥ 条，并在同一次落笔清掉表内既有的六处计数（#7 / #11 / #15 / #16 / #25 / #27）——否则新纪律在自己表内当场不成立。**纪律带一句射程限定：约束的是字段计数，不及于纪律与清单自身的条目编号**，否则规则会吃掉自己。

依据是本库已有的两条同款先例（`ProfileChangeSpec` 的「列表数不进承重表述」· 全部 Codex 顶层键用不带计数的措辞），而本表比那两处更需要它——它是唯一登记面，一处计数漂移会同时误导两侧。

**③ 条目维度补一条第 3 级旁证。** `/sync-knowledge` 增一条对账项：v1 清单的条目集合与两层 Profile 字段表的行集合双向核对，任一侧有而另一侧无即报不一致。它与既有那条 grep 断言互补不重叠——那条抓「别处又自己宣布了一次」，这条抓「本表少了一格」。**选级停在第 3 级是正确的**：条目漏登不构成静默上线（golden 快照仍带那个字段、护栏仍会通过），后果是文档面误导，属「能上线、开发期可发现」。不为它另造工具、不抬到管线闸（管线读不到设计库），也不引入周期性巡检（那会允许漂移窗口存在）。

**`ProfileShapeCheck` 的排期不动。** 它防不住本次这类问题（比对的是代码形状那一段），提前落地是付出排期换一个不对症的护栏；形态仍与 `game-feature-branch/` 首次生成 `.csproj` 后那批实测项同批落地。

## Clarifications（interview 产物）

- **原问题条目的处置路径** → **改写而非关闭**：条目改写为「四批漏登经核实已答结；残留 = v1 行覆盖空缺 + 一处不可核对计数」，降级后**移入 `open-questions/05-service-contracts.md`**。它推翻了草稿「就地改写索引条目 + 撤销索引内三处 derive 前置标注」的写法——那三处标注物理上全部落在 `open-questions.md` 的 `## derive 就绪度` 小节内，该小节由 `/assess-derive-readiness` 独占写入，且拿一次单文档落笔去改写一份全量扫描的产物，正是那条独占纪律要防的事。改写后的条目正文因此另带一句：索引就绪度小节内的相应前置标注讲的是已消失的前提，待下次全量评估清理。
- **后端待答清单上的两处残留错指是否本次一并修正** → **一并修正**（纯删除已失效陈述，不新增后端义务、不触碰任何契约、不替后端拍板）。它推翻了草稿「前置依赖 ③ 第 ② 条」的断言「无残留错指」——契约正文那半成立，待答清单那半不成立。依据：跨边界的意图被拆成两半后第二半经常不会发生，而本条残留讲的正是「两侧都以为对方在记」这同一个失效模式。
- **`ProfileShapeCheck` 是否因本次发现而提前单独落地**（标准默认，未占 interview）→ **维持既定排期**。本次空缺它一条也抓不到，真正对位的是上述第 3 级对账断言。
- **v1 覆盖空缺究竟几处**（标准默认）→ 草稿给 7 处，核实后为 **11 处**：另有 `magicPack` / `characterPower` / `playerPower` / `playerItem` 四个顶层键零登记（行 #21 登记的是四类持有条目 record 的**形状**，且对象列只写 `PlayerProfile`，不构成对这四个顶层键本身的登记），`AccountInfo` 的逐字清单也漏了 `AccountId`。追加行因此由 #28–#31 扩为 #28–#33。
- **`/sync-knowledge` 新断言写在哪** （标准默认）→ 写进本登记表的 `ProfileShapeCheck` 一节，不改 `.claude/skills/sync-knowledge/SKILL.md`。同款先例逐字同构：该节已挂一条同类 grep 断言，且 `.claude/` 全树对该类断言零处提及——断言住在设计库、技能扫描时读到，是本库既定形态。
- **是否去后端库补一句「v1 行内补条目不触发矩阵」的显式否定**（标准默认）→ 不去。对侧三处措辞一致、无歧义（触发点 = 登记表新增一行），排除由字面推出，不需要给对侧加一条本不必要的措辞。
- **是否在 `open-questions/05-service-contracts.md` 补记 `ProfileShapeCheck`**（标准默认）→ 不补。它已定案、不是待答项，写进待答清单反而制造第二处登记；该分片三条实测项与它的落地时点绑定关系本就成立。

## Open questions

- `PlayerProfile.achievement` 的条目结构，前置是 `Achievement` schema（`systems/services/profile-service.md` 的待决问题）。答定后补入 v1 清单，仍属 `schemaVersion` 1。
- `/sync-knowledge` 那条对账断言的落地时点跟随该技能自身的下一次运行，无排期依赖。

## Notes / triage

- 输入：`inbox/solution-draft-sync-schema-bump-ledger.md`（用户已评审，两项已裁决）。
- 跨库：主库 `game-design-documents/` 承载全部权威内容；对侧 `backend-design-documents/open-questions.md` 只做两处失效陈述的删除，**不新增任何后端义务、不触碰契约**。
