# Answer log flags-service-internal-doc-home

- 日期：2026-09-08
- 来源：`inbox/archive/solution-draft-flags-service-internal-doc-home.md` → `handoffs/2026-09-08-flags-service-internal-doc-home.md`
- 移出条数：1（该问题此前不在 `open-questions/` 任一分片内跟踪，只记在 `open-questions.md`「下一阶段」第 7 条的前置动作与「最短解锁路径」第 3 条，以及 `handoffs/2026-09-07-manifest-schema-path-branch-and-cdn-failure-codes.md` 的「不依赖」段）

**`operations/content-delivery-ops.md` A6–A9（flags 请求处理路径）的文档归属：新建 `systems/content-delivery.md` 承接，还是明文裁决就地留在运维文档？** → **新建 `systems/content-delivery.md` 并迁入**（2026-09-08 批量评审裁决）。判据：`systems/_index.md` 把「服务内部怎么实现」钉给 `systems/`，而运维文档的自陈范围逐字排除了这批条款；服务职责表本就把该职责登记给这份文档，缺的只是文件。运维文档原位留一行回链，自陈范围与其余内容一字不动。（归档去向：`systems/content-delivery.md` · `operations/content-delivery-ops.md`）

**同批裁决一项：迁移范围。** → **本次只迁请求处理路径**，规则集表的承重列与唯一写入面（A1–A3 / A5）留在运维文档；新文档的「存储形态：承重列」与「唯一写入面与事务边界」两节写成回链占位。由此产生的回链方向反转（与 `account.md` / `profile-store.md` 相反）是已知且被接受的结构不齐，待下一次触及内容分发时补齐。（归档去向：`systems/content-delivery.md`）

**同批推演并落笔一项新内容：版本预热。** 纯请求驱动的懒加载与「头永不领先」合成自锁，一次 `publish` 可能对全体设备永不生效且既有探针发现不了 ⇒ 装载须有请求无关的触发（当前版本读取缓存刷新时主动装载），并在 `operations/observability.md` 增一条「全体一致地落后」的告警断言。（归档去向：`systems/content-delivery.md` · `operations/observability.md`）

**仍待答（本次新增，未答定）：** flags 端点零装载且回源失败时的错误应答是否值得一条专属 `code`。当前按 `contracts/envelope.md` §5a 的兜底走 `server.unavailable`（`Retryable`），不阻塞；裁决归 `contracts/envelope.md` §6 台账。
