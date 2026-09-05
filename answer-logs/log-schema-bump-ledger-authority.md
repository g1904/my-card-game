# Answer log schema-bump-ledger-authority

- 日期：2026-09-03
- 来源：`inbox/solution-draft-schema-bump-ledger-authority.md`（→ `handoffs/2026-09-03-schema-bump-ledger-authority.md`）
- 移出条数：1

**「`profile-sync.md` 把 schema bump 清单的权威指回客户端，而那张清单已漏三批 ⇒ 两侧都以为对方在记」** → 已成对关闭。对侧同批补齐并把清单拆成逐版登记表 `game-design-documents/systems/services/profile-schema-versions.md`；本库 `operations/version-matrix.md` 的 `schemaVersion` 集合展开为一版一行的四列子表并登入 `1`，第四列回链直指该新文档（不经 `sync-service.md` 中转）；登记流程（触发点 / 承载 / 责任人两段 / 「矩阵先加、客户端后发」）进 `operations/_index.md`，与错误码台账的登记流程并列；漏登的机制发现面 = `observability.md` 新增的第五条探针（阈值 0，按大小关系二分）。`profile-sync.md` 同批补一句不对称声明（§3 对 `reason` 的宽容不适用于 `schemaVersion`，判据 = 有无判定权），`reason` 那条一字未改。（归档去向：`operations/version-matrix.md`、`operations/_index.md`、`operations/observability.md`、`contracts/profile-sync.md`）

**同批裁决两项（合并 interview）：**

- **未知 `schemaVersion` 告警的分级** → 取「按与已登记集合的大小关系二分」：值 > 已登记最大值 ⇒ 工程告警叫人（登记漏了，改旋钮即修复）；值 < 已登记最小值 ⇒ 信息级、只上看板（旧客户端，是既定下线纪律的预期产物）。**拒绝语义不变**，本裁决只作用于告警口径。（归档去向：`operations/observability.md`）
- **矩阵本批登不登 `schemaVersion = 1`** → 登。客户端 v1 既已定案，按本库自己的「矩阵先加、客户端后发」纪律，等待就是无成本的反序；且不登会让第四列回链在落笔当天即无处可指。（归档去向：`operations/version-matrix.md`）

**同批附带：** `envelope.md` §7e 补一句指路（语义未改）；§8 统计层推论按跨库裁决**收窄**到「已有的不透明顶层键内的追加」——引入新顶层键与受回声约束的顶层键内追加各自不适用。**报文形态零改动**，不 bump `openapi.yaml` 的 `info.version`。

**未答结、仍留在清单上的相邻项：** 告警规则的落地承载（跑在哪条流水线 / 用什么表达）仍并入 `01-contracts.md` 既有的那一条（三条机检断言的承载位置）。`appVersion` 下界与 `manifestSchema` 集合仍为待落值，本批不动。
