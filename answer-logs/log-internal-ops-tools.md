# Answer log internal-ops-tools

- 日期：2026-09-09
- 来源：`inbox/archive/solution-draft-internal-ops-tools.md` → `handoffs/2026-09-09-internal-ops-tools-and-operator-identity.md`
- 移出条数：2（`open-questions/07-internal-tools.md` 的两条，同源一并裁决）

---

**昵称人工复核台的形态（谁复核 · 是否分派 · 界面档次 · `claimed_by` 的取值从哪来）** → 复核员 = **仅维护者本人**（沿用库内既有的「当前单人维护」）；**不分派**（昵称是单一字段、词表是统一的一份，`SKIP LOCKED` 的批量领取本就是无分派的公平队列；日后加 `assigned_group` 一列即可，不动任何不变式）；界面 = **CLI**，控制台日后引入只作调用方，**首版不做 Web 页、也不给人可写库凭据去处置**（后者会绕过条件 `UPDATE` 取租约，让 M6 / M7 在纸面成立而线上不成立）。

**`claimed_by` 的取值域**（本条最承重）→ 本库自己的 **`operator_id`**，与 `account` 完全分离：类型 `text`、取值域 = `operator` 表中未停用行的 `operator_id`、**加外键 `REFERENCES operator(operator_id)`**、**来源恒取自本次内部请求已认证的凭据，绝不接受请求体传入**。M6 / M7 因此机械成立。归档去向：`operations/internal-tools.md`（工具面形态）· `systems/account.md`（四张新表的承重列与三行事务边界）· `operations/moderation.md`（伪码的 `:reviewer` 来源与租约回收置空）。

**风控工单的落点同源（工单进哪个系统 · 谁看 · 处置动作经什么面写回 `account.status`）** → 本库自己的一张 **`ops_ticket`** 表 + 同一个 `/internal/` 面、同一套 `operator` 身份。**不进外部工单系统**（处置必须与 `account.status` 写入同一次事务，跨系统即让「工单已关、`status` 未改」成为可达状态）；**不靠在 `risk_event` 上按阈值聚合出待办**（没有「已驳回」态，同一账号会永远浮在待办里）。处置带**必填的 `baseAccountStatus` 乐观前置条件**，是不设第二人审批之下唯一的一道防线。归档去向：`operations/internal-tools.md` · `systems/account.md` · `operations/moderation.md`（「自动化止步于工单」一节补工单落点）。

---

**同批裁决的取向项（批量评审，2026-09-09）：**

- **首版使用人群** → A：仅维护者本人；企业 IdP 与内部 Web 控制台**留位不启用**，启用触发条件写死（人数 > 1 或出现非工程岗复核员）。
- **内部面的暴露形态** → A：仅 VPC 内可达，经堡垒机 / VPN；内部监听不对公网暴露，接入通道随第二份发布前置清单一并过闸。
- **`content-delivery-ops.md` A3「人类身份只有 `SELECT`」的适用范围** → **提升为全库通则**：任何人类身份对任何业务表恒只有 `SELECT`，一切写入经服务端受控面。
- **`operator_id` 是否同批收口另三处「操作者」** → **是**：`publishedBy`（flags 规则集 / 内容发布 / 词表 / 时段规则集）· `config_knob` 更新者 · KMS 解包事件审计的「谁」，四处是同一个空洞、同一个答案。
- **租约回收是否一并置空 `claimed_by`** → 按标准默认采纳（工程常识，无相反取向），补正照写。

**新增待答 2 条**（并入 `open-questions/07-internal-tools.md`）：告警接收人 / 值班形态 · 客服侧的账号查询入口（可见字段范围须单独裁决）。

**ADR 候选 2 条**（立档归 `/write-adr`）：内部人员身份与 `account` 完全分离、`operator_id` 为全库唯一内部人员标识 · 内部工具面不属于契约面（`/internal/` 永不进端点全集表）。
