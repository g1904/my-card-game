# 六条过时措辞 / 台账失真的直读收口（stale wording roundup）

- id: 2026-09-06-stale-wording-roundup
- date: 2026-09-06
- topic: systems/game-progression | systems/adventure-event/exchange | systems/player-profile/account-info | art/visuals/animations | systems/services/profile-schema-versions
- status: distilled
- distilled-to: systems/game-progression.md, systems/adventure-event/exchange/_index.md, systems/player-profile/account-info.md, art/visuals/animations/_index.md, systems/services/profile-schema-versions.md, answer-logs/log-stale-wording-roundup.md

## Intent（distilled）

一句话：把六处「文档写的」对齐到「本库已定的」——`open-questions.md`「derive 就绪度」小节点名的一组 🟡 失真项，逐条直读源文件、引用原句后裁定并落笔。本 handoff 不裁决任何新设计取向（唯一的取向题「战斗外演出可否跳过」已由用户在 2026-09-06 批量评审裁决，见 Clarifications）。

逐条裁定与落笔：

1. **`game-progression.md:195` 与 `:57` 自相矛盾 —— 不成立（已修）。** 主题文档侧已在 09-06 的前批落笔中修好（「进度感那一半」待决项已删、`:57` 一带改写为被接受的取向），失真只剩在台账里。不改主题文档，只更正台账（归 orchestrator）。
   - **顺带发现（同族失真，已处理）：** 同一 `## 待决问题` 面上的首条以「已明确」开头、通篇是已定案结论（结束点 = 存档点 · 章首重试 · 回链 `life-cycle-service.md` 与 `ADR-0004`），坐在待决面上会被机械汇总当成待答项。**整条删除**；其内容已由篇章 / 重试正文与 `decisions/ADR-0004-realm-checkpoint-retry-model.md`（`## 决策` 节已回链）承载，删掉不丢事实。
2. **`item/_index.md` 与 `item/common-properties.md` 抬头「占位结构，细节待定」 —— 不成立（已修）。** 两抬头已是实质内容，全目录零命中。不改两份 item 文档，只更正台账（归 orchestrator）。
3. **`exchange/_index.md` 的「ADR 候选，待 `/write-adr` 立档」 —— 成立，纯机械修正。** `ADR-0126` 已于 08-30 Accepted，`## 决策(-> ADR)` 节里那行候选标记替换为回链（形态对齐同节既有回链行，附 `Holds(...)` 门面级前置拒绝与「不扩 `CanAfford`」两条要点）。不动同文件 `## 待决问题` 区。
4. **`account-info.md` 唯一待决项（合规字段归属） —— 成立，撤销而非改写。** 该问题已被对侧穷尽答死：合规态没有任何下行通道、唯一读取面是 `GET /v1/compliance/status` 的独立应答、「随 `AccountInfo` 下行」被显式否决（`backend-design-documents/contracts/compliance.md` · `contracts/auth.md` §1a）；客户端侧承载已成文（`account-service.md` 的 `ComplianceManager`，只在内存持有）。待决项删除、节改「- 无。」，并在 `## 意图` 末补一句正面陈述「合规域一格也不落 `AccountInfo`（已收口）⇒ 本字段表不因合规增行」——只回链、不复述对侧内容。**不触碰对侧库**（它那侧已写全，无承接项）。
5. **animations「须可跳过 / 可加速」 vs combat-ux「只能加速不能跳过」 —— 成立，按上游定案裁给 combat-ux 侧，且按作用域分档。** `ADR-0086`（Accepted）把「无玩家侧的暂停 / 跳过控件」写进决策本体并带承重论证（敌人回合是玩家获取动态情报的唯一时刻）；animations 侧那句写于占位期、无论证，应让步。时长预算在战斗内已有三重护栏（3× 加速 + 超 4 步压到 0.2 s + 敌人回合总时长 ≤ 4 s），删「可跳过」不丢护栏。落笔：`_index.md` 待决条改写为「战斗内无跳过控件 + 本节待定收窄为护栏内各类动画的时长上界与缓动」；「已知的」补入战斗内外的跳过边界（含理由）；`## 结构` 句的「可跳过策略」收窄为「战斗外演出的跳过策略（含战斗外跳过控件的统一形态：触点、是否记忆偏好）」。承接项并入 `_index.md` 文本、不提前新建 `animation-direction.md`（该文件明写待咨询专业人士后开工）。**`ux/combat-ux.md` 是权威侧，一字不动。**
6. **`profile-schema-versions.md` 结构与全库不同构 —— 成立，补齐三个标准小节。** 它已被判为 derive 对象而机械扫描以 `## 待决问题` 为落点，少这一节 ⇒ 两处真实空缺（`achievement` 未进 v1 清单 · golden 快照待建）对机械汇总不可见。补 `## 意图`（三条既有事实的提要）· `## 决策(-> ADR)`（`ADR-0158` 权威外移 + `ADR-0145` 不写计数，两行回链已逐字核对文件名 / 标题 / 状态）· `## 待决问题`（两处空缺抬为承接项 / 排期项，只写承接与回链）。三处原文（`achievement` 段 · golden 快照格 · 落地时点）保持不变——新增条目是投影，权威仍在原处，不构成第二权威。「v1 首发形状归一版」没有独立 ADR（由 `ADR-0158` 覆盖），不为它编造一行。

## Clarifications（interview 产物）

- **战斗外的演出是否允许玩家跳过（第 5 条的作用域边界）→ 已裁决（2026-09-06 批量评审）：选项 A —— 战斗外的演出默认允许跳过 / 快进，只有战斗内的结算演出不可跳过。** 理由：`ADR-0086` 的论证前提（敌人回合是唯一动态情报时刻）在战斗外不成立，且轮回制下同一段转场会被重复观看数十次。承接项（战斗外跳过控件的统一形态：触点、是否记忆偏好）并入 `animations/_index.md` 的 `## 结构` 文本，待 `animation-direction.md` 立档时承接。
- 条 1+ 顺带删除、条 3 / 4 / 6 的落笔形态均为零决策的机械对齐（🔵 自行推演，依据见上文逐条）。

## Notes / triage

- 来源草稿：`inbox/solution-draft-stale-wording-roundup.md`（status: decided，2026-09-06 批量评审）。
- `open-questions.md`「derive 就绪度」小节的对应台账更正（删六条 🟡 · 四行表格 / 清单收窄）不在本 handoff 落笔范围——该小节由 `/assess-derive-readiness` 独占写入，更正文本随批次报告交 orchestrator。
- 条 1、2 判「不成立（已修）」：不为凑齐六条制造改动，如实记录。
