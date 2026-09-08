# Answer log spec-check-automation-hosting

- 日期：2026-09-06
- 来源：`inbox/archive/solution-draft-spec-check-automation-hosting.md` → `handoffs/2026-09-06-spec-check-automation-hosting.md`
- 移出条数：1（`open-questions/01-contracts.md` 的唯一条目 ⇒ **该分片自此无待答项**）

---

**三条机检断言的承载位置未定（原挂在 `06` 之后）** → **承载 = 设计库分支自带的一条独立 CI 检查**（push 到该分支 + 手动触发，路径过滤 `contracts/**` 与校验脚本；通用 Linux runner，不需要 .NET / Godot），与后端镜像构建不同分支、不同触发、无依赖——校验对象零云资源依赖，而镜像构建需云侧凭据且跑在没有 `contracts/` 的实现分支上。**阻断对象是「变更被视为完成」而非推送本身**：绿灯即完成判据第 4 条的兑现物，红灯 = 该次契约变更未完成、须前滚一次修复提交，期间不得据该契约推进实现或跨库 handoff；无条件触发、不设跳过开关；失败通知走托管方默认，不进线上告警面。（归档去向：`contracts/_index.md`「契约变更的完成判据」→「机检的工程承载」· `operations/deployment.md`「契约变更的完成判据与机检断言」· `operations/_index.md` 断言②那一条）

同批一并裁决 / 落笔的四项（不单列为移出条目，随本条归档）：

- **契约变更不引入 PR 门** —— 保持直推 + 事后红灯。依据：`operations/content-delivery-ops.md` A4 已就同类问题裁定「不设强制第二人审批，当前单人维护」；设计库当前无下游消费者。**复议触发点**：后端进入实现、`contracts/` 出现真实消费者时重估。
- **spec 未落笔期间的降级形态** —— ①报 `skipped: no spec yet`（不是 `pass`）；②③ 收缩为 markdown 内部的双向核对（台账 ⇔ 各契约正文的 `code`；`envelope.md` §3 端点全集 ⇔ 各契约正文的 `METHOD 路径`）。markdown 内部那一半在 spec 落笔后**不删**。**切换判据 = `contracts/openapi.yaml` 的存在性**，不设开关。（归档去向：`contracts/_index.md` 同节的降级形态两列表）
- **断言③的比较基准** —— `contracts/envelope.md` §3 由前缀 + 省略号形态展开为逐条 `METHOD 路径` 的端点全集表，并升为机器读取面（护栏 **P-3**）。原方案的写法会让 auth / compliance / purchase 三域的全部端点被报成「§3 缺失」。（归档去向：`contracts/envelope.md` §3）
- **提取护栏与排除清单** —— P-1（§6 台账首列为机器读取面）落 `contracts/envelope.md` §6；P-2（排除清单每条带理由、新增须显式提及）落 `contracts/_index.md`，已知条目三条 + ②的扫描面排除台账自身。（归档去向：同上两处）

**未闭合、随本条留下的后续动作**（不构成待答问题，是待落地项）：`.github/workflows/contract-spec-check.yml` 与 `tools/spec-check/` 本次**未创建**——本次授权范围只到设计库写入，脚本落地是一次需实跑验证的独立动手。落地之前，三条断言以人工清单的前三项形式执行。
