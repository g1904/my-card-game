# `schemaVersion` 兼容矩阵的输入、登记流程与漏登告警（后端半）

- id: 2026-09-03-schema-bump-ledger-authority
- date: 2026-09-03
- topic: operations/version-matrix · operations/_index · operations/observability · contracts/envelope（§7e 指路 · §8 限定）· contracts/profile-sync（§4 不对称声明 · §5b 回链）
- status: distilled
- distilled-to: operations/version-matrix.md · operations/_index.md · operations/observability.md · contracts/envelope.md · contracts/profile-sync.md · open-questions/cross-boundary.md
- counterpart: `game-design-documents/handoffs/2026-09-03-schema-bump-ledger-authority.md`（客户端半：逐版登记表本体、首发形状清单、回链收口与 `ProfileShapeCheck`。**只回链、不复述**）

## Intent（distilled）

**一句话：** `schemaVersion` 的结构权威在客户端，后端对它只做一件事——判定它在不在兼容集合内。此前那一格是空的、且指向一份不存在之物（「待客户端清单补齐」），而对侧那份清单本身也不完整 ⇒ **两侧都以为对方在记**。本次把矩阵那一格做成一版一行的子表、把登记流程写成与错误码台账并列的第二条，并给「客户端 bump 了但没告诉我」配一条阈值 0 的告警。

### 四项落地

**① 矩阵的 `schemaVersion` 集合展开为四列子表，只登数字与运维事实。** `schemaVersion` | 接受起始 | 下线计划 | 客户端登记回链。**四列全部是本库自己持有真值的东西，一列都不描述该版本含什么字段**——判据即「契约不把 Profile 的字段表抄进本库」。这与 §5 白名单的处理**刻意不同**：白名单里的 JSON path 是后端自己要读的复算输入，不透明段的字段名后端根本不读。**本批即登 `schemaVersion = 1`**：对侧 v1 已定案，按本库自己的顺序纪律（矩阵先加、客户端后发），等待就是无成本的反序；且第四列回链若无行可挂，本次的核心交付物落笔当天即无处可指。

**② 登记流程进 `operations/_index.md`，与错误码台账并列。** 触发点 = 对侧登记表新增一行；承载 = `cross-boundary.md` 的标准四段式条目（**零新增机制**）；责任人**两段**——开条目归发起方（schema bump 的发起方恒为客户端），落笔矩阵归后端。

**③ 发布顺序纪律：矩阵先加、客户端后发。** 后端补一版只需改一次旋钮值、不发版；客户端发出一个后端不认识的 `schemaVersion`，代价是那批玩家的进度暂时上不去。成本极不对称 ⇒ 顺序唯一合理。它与错误码台账的「先文档 → 后 spec → 后实现」是同一条纪律的第二个实例，也与下线纪律方向一致——**加与减都是先动矩阵**。

**④ 未知 `schemaVersion`：判定不放松 + 阈值 0 告警。** 判定侧补一条**不对称声明**——§3 对未知 `reason` 的宽容不适用于 `schemaVersion`，判据是**该字段有无判定权**；`reason` 零判定权，`schemaVersion` 是闸门输入，宽容等于让一份不保证可解读的负载进云端并被 pull 给别的设备。可见性侧探针表 +1 行（标签 `schema_version` + `app_version`，阈值 0）。**这是本方案唯一「机制发现」的兑现**——没有它，漏登在后端侧零信号。

## Clarifications（interview 产物）

- **未知 `schemaVersion` 告警的分级判据？** → 按与已登记集合的**大小关系二分**：值 > 已登记最大值 ⇒ 工程告警叫人（登记漏了，改旋钮即修复）；值 < 已登记最小值 ⇒ 信息级、只上看板（旧客户端，是既定下线纪律的预期产物）。**拒绝语义不变**，本裁决只作用于告警口径。依据：一律工程级会让正常下线后的存量旧客户端持续制造以周计的预期告警，那是把整张探针表训练成「可以忽略」的最快途径；本库已有「带前提才告警」的同款先例（透明路径缺失那行）。
- **本批登不登 `schemaVersion = 1`？** → 登。见上文①。草稿 §后果「在此之前矩阵仍是『待首个版本产生』」那句随之作废，已改写。
- **统计层新增字段是否需要 bump？**（跨库合并裁决）→ 区分「引入顶层键」与「键内追加」：本库 §8 的推论**保留但收窄**到「不透明段内、已有顶层键内的追加」，并明写引入新顶层键不适用。**不推翻本库任何结论**，只补两条限定。

## 两处事实更正（相对派单摘要）

- **`envelope.md` §7e 不是空的**，它是一条内容完整的指路条款，**本次不动它的语义**，只补一句指向登记流程。
- **`operations/version-matrix.md`「当前矩阵」真正为空的是三格，不是两格**：`appVersion` 下界 · `manifestSchema` 集合 · `schemaVersion` 集合。前两格不在本次范围内。
- **本库早已登记过「每次 bump 须进兼容矩阵是既有机械义务」**（`cross-boundary.md`「对账基线」第二条），故第 ② 项是把既有义务写成流程，不是新立机制。该条那句「栈未定故当前无可落之处」的括注已失真，同批中性化。

## Open questions

- **告警规则的落地承载**（跑在哪条流水线 / 用什么表达）与 `contracts/_index.md` 三条机检断言的承载位置是同一条待答项（`open-questions/01-contracts.md`）。本次只定告警的**口径与阈值**，不定实现载体。
- `appVersion` 下界与 `manifestSchema` 集合仍是**待落值**、不是设计缺口，等首个在架版本产生。

## Notes / triage

- 输入：`inbox/solution-draft-schema-bump-ledger-authority.md`（用户已评审）。
- **报文形态零改动**：不新增字段、不新增端点、不新增错误码（`sync.payload_schema_unsupported` 与其 `detail.supportedSchemaVersions` 原样够用）⇒ **不 bump `openapi.yaml` 的 `info.version`**，不触发 `contracts/_index.md` 的三条机检断言。
- `config_knob` 中 `schemaVersion` 集合由一个标量变为一张小表，仍是旋钮表的一员，改值不发版。
- **本次两侧同批落笔**，故「待承接」区不落一条当场即关的条目；两侧各在 `cross-boundary.md` 说明区补一句常规触发源。

## 客户端侧影响

本 handoff 不改动客户端 ↔ 后端边界的任何报文语义。唯一的跨边界产物是**登记顺序纪律**（矩阵先加、客户端后发）与**回链方向**（本库第四列指向 `game-design-documents/systems/services/profile-schema-versions.md`）。客户端半已在 counterpart 同批落笔，本库不代为决定其任何形态。
