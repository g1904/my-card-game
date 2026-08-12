# ① 协议契约（边界层已成文 · 端点报文待写）

> 客户端 ↔ 后端边界的**唯一**耦合点。两侧都读它，因此必须单点定义。权威落点：`contracts/`。
> 跨越这条边界的客户端成分有**三个**：`account-service`、`content-service`、`sync-service`——全部是服务本身，没有任何 manager 跨边界（剧本内容已本地化，2026-08-11）。
>
> **边界层四条已于 2026-08-11 全部答结**（表达形式 · 错误码分层与 `OpError` 映射 · 版本协商与强更 · 存档 schema 在契约中的承载）→ `contracts/envelope.md`，移出记录见 `answer-logs/log-contract-expression-envelope-and-error-codes.md`。本分片余下的是**各端点报文本体**的待答项。

- **`auth.md` 尚未成文（下一份）。** token 生命周期（签发 / 刷新 / 吊销）、登录渠道的报文形态、多设备裁决触发 `auth.session_revoked` 的具体条件。**触发条件待 `02-account-compliance.md` 的并发裁决规则**；`code` 与客户端处置已定（`envelope.md` §6）。

- **`profile-sync.md` 尚未成文。** 负载信封（`pushId` · `baseRevision` · `schemaVersion` · `reason`）的字段表、三分支应答报文、以及**「后端可见字段子集」的逐字段清单**（复算所需的掷骰序号与命中结果、`PlayerPowerFragment.*` 等规则字段）。三段可见性的分界已定（`envelope.md` §8），待定的是**哪些字段属于透明子集**——它需要 `03-sync-conflict.md` 的 `AccountSeed` 复算协议先落定。

- **`compliance.*` 错误码的具体清单未定。** 实名 / 防沉迷 / 注销 / 导出各自的分支、以及各自 `detail` 里的 `reasonKey` 取值集合。`envelope.md` 的台账只立了两条示例与它们的 `class`，待 `02-account-compliance.md` 的合规方案。

- **`openapi.yaml` / `schemas/*.json` 尚未落笔。** 按定案推迟到首个端点进入实现时同时落地（不预先建空壳）；届时需确定 **markdown 字段表与 spec 的一致性核对方式**——冲突裁决规则已定（字段形态以 spec 为准，语义以 markdown 为准），但「谁在什么时机核对」未定。
