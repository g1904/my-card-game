# Answer log openapi-spec-timing-and-consistency

- 日期：2026-08-14
- 来源：`inbox/archive/solution-draft-openapi-spec-timing-and-consistency.md` → `handoffs/2026-08-14-openapi-spec-timing-and-consistency.md`
- 移出条数：1（`open-questions/01-contracts.md`）

## 移出条目

**`openapi.yaml` / `schemas/*.json` 尚未落笔；markdown 字段表与 spec 的一致性核对方式未定（谁在什么时机核对）** → 落笔规则与核对机制全部定案：

- **触发点 = 任一侧的首个端点进入实现**（哪一侧先动都算），由**动手的那一侧**发起落笔（即使动手方是客户端，spec 仍落本库 `contracts/`），另一侧在同一次跨库 handoff 中确认。**首落范围 = 全部共有层 + 该一个端点**，其余端点路径各自进入实现时逐个追加。
- **形态收到 spec 单点**：某端点的形态进入 spec 后，其 markdown 字段表同批删除规范性形态列（类型 / 必填 / 枚举取值），只留字段名 + 语义 / 用途 / 承重纪律；示例报文保留但不具规范性。**瘦身随 spec 覆盖面逐步推进**（interview 裁定，见下），过渡期四份契约风格不齐是预期状态。
- **核对时机 = 变更内原子**，不设周期性对账；责任人 = 发起该次变更的那一侧。落为 `contracts/_index.md` 的**六条完成判据** + **三条机检断言**（①spec 合法 ②台账 `code` ⇔ spec 枚举双向一一对应 ③markdown 的 `METHOD 路径` ⇔ spec `paths` 双向）+ **人工清单四项**。
- **`schemas/` 拆分判据两条并列款**（被两个及以上端点引用 / 独立可被签名校验且需脱离 spec 单独引用），首批四个文件；`vectors/splitmix64.json` 单独承载测试向量数值的权威。
- **`profile-visible-subset.json` 是部分 schema**：只列白名单 path、`additionalProperties: true`、透明字段全非必填、缺失 path 走告警不走 schema 失败。
- **`info.version` 与 `/v1/`、`schemaVersion` 三者互不复用。**

归档去向：`contracts/envelope.md` §1 · `contracts/_index.md`「约定」段 · `contracts/profile-sync.md` §6 · `operations/_index.md`（错误码台账登记流程扩展为「先文档 → 后 spec → 后实现」）。

**部分未答定，仍留在待答清单**：**三条机检断言的承载位置**（设计库侧有无自动化流水线、跑在哪里）属工程承载，随 `open-questions/06-platform-stack.md` 落定；在此之前三条以人工清单的前三项执行。该残留已作为 `01-contracts.md` 的一条**降级后的**条目保留，不再是「核对方式未定」。

## interview 裁决（两项）

- **🔴 markdown 字段表的瘦身范围** —— 草稿第 2 条「四份同批瘦身」与其 §1 改写表「未落笔端点的字段表视为草案」互斥。**裁定：随 spec 覆盖面逐步瘦身**（推翻草稿「同批完成」的措辞，保留「形态只有一处真值」的实质）。
- **🟠 CDN 域端点是否进 `openapi.yaml` 的 `paths`** —— 草稿未说，且断言③ 原措辞只写 `METHOD /v1/…`。**裁定：进 `paths`，以 `contentRoot` 为独立 server**；断言③ 措辞放宽为「每个 `METHOD 路径`」，覆盖 CDN 端点集。
