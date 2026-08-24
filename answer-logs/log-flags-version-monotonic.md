# Answer log flags-version-monotonic

- 日期：2026-08-23
- 来源：`inbox/archive/solution-draft-flags-version-monotonic.md` → `handoffs/2026-08-23b-flags-version-monotonic.md`
- 移出条数：2（一条完整答结，一条部分答结）

## 逐条

**flags 回滚须以更高 `flagsVersion` 发布——`contentVersion` 那条「回滚即前滚」对 flags 的对位条款尚未写下** → **已成文，且写的不只一句**。条款三半：① `flagsVersion` 取自**单一全局单调序列**（不按区域 / 实例 / 账号分别计数，号只由发布动作分配）；② **严格单调递增，回滚 = 以历史规则内容发布更大的版本**（零成本的理由是**全量快照**，与 `contentVersion` 靠内容寻址不同源）；③ **同一 `(flagsVersion, 账号)` 的解析结果恒定**，任何影响解析结果的改动（含分桶比例与盐值）都必须提升版本，分桶函数须是 `(accountId, 规则集版本)` 的纯函数。落笔位置：把「服务端保证」重构为 **A 组 overlay 分发 / B 组 flags 通道**两组，并同批把 `contentVersion` 严格单调那条**提上来**（位置迁移，内容不变）。附三个失效来源的堵法与「缓存层若引入则缓存键必须含 `flagsVersion`」。（归档去向：`contracts/content-manifest.md`「服务端保证」）

**flags 改动是否需要审计留痕（`04-content-delivery.md`「flags 数据源与灰度分桶的运营形态」的一小问）** → **答：是**，且给出四项最低要求：操作者 · RFC 3339 UTC 时刻 · **`derivedFrom` 来源版本** · 变更摘要与生效范围。理由：flags 是唯一一条能绕过发版直接改变玩家可见内容的通道；`derivedFrom` 是「回滚 = 以历史规则内容发布更大版本」能被机读核对的唯一凭据。连带定下 O1–O7（规则集不可变版本化 · 全局分配点 + 持久化高水位 · 备份恢复强制跳号 · 回滚即一次发布 · 留痕四项 · 历史规则集**永久保留** · 可选的内容指纹加固）。（归档去向：`operations/_index.md`「已有具体对象的运维面：内容分发」）

## 仍留在清单上的

- **「flags 数据源与灰度分桶的运营形态」的其余部分**（规则存在哪、由谁改、按账号计算是否引入缓存层）仍在 `04-content-delivery.md`——本次只对它**施加约束**，不裁决它。
- **传播窗口 T 的数值上界**——条款先写「窗口 T」，数值随 `04` 的「多区域内容分发的一致性」答定。
- 分配点 / 高水位 / 留痕的**实现承载**待 `06-platform-stack.md`。

## 连带

新增 **ADR 候选④**（flags 规则集不可变版本化 · `flagsVersion` 单调 · 同版本结果恒定 · 回滚即前滚），登记在 `contracts/content-manifest.md` 的「决策(-> ADR)」，**立档归 `/write-adr`**。`decisions/_index.md` 本次未改动。

## 跨边界

本条对客户端**零改动要求**。本次连带发现的客户端缺口（应答体 `flagsVersion` 是否也过单调闸）已由对侧自行裁决并落笔，记在 `game-design-documents/answer-logs/log-refresh-cap-and-flags-gate.md`。
