# Contracts — 客户端 ↔ 后端协议契约（索引）

> **本库的核心产出。** 客户端与后端唯一的耦合点是协议；它必须**单点定义**，两侧都从它派生。
> 客户端侧的门面设计在 `game-design-documents/systems/services/`——那里描述**客户端怎么用**，此处描述**报文长什么样**。

## 现状

**表达形式已定案：OpenAPI 3.1 + JSON Schema 单点，明确否决共享 DTO 代码**——依据是根约定的分支线独立性，**不依赖技术栈选型**（见 `envelope.md` §1）。契约表达形式因此已从 `open-questions/06-platform-stack.md` 的下游摘出，两者可并行推进。

**边界层已成文：`envelope.md`** ——序列化与命名约定、`/v1/` 主版本、传输信封（HTTP 头）与负载信封（push body 段）、错误体与错误码台账、版本协商与强更闸门、Profile 的三段可见性。全部端点共有的那一层不再是悬项，`auth.md` / `profile-sync.md` 的前置已解除。

**剧本契约已撤销（2026-08-11）。** 剧本内容本地化为客户端内容层的一员，以普通内容文件走 `content-manifest.md` 的 manifest 通道下发——**没有剧本端点、没有剧本报文**。契约面因此只剩三份：`envelope.md` · `content-manifest.md` · 以及待写的 `auth.md` / `profile-sync.md`。
Source: `handoffs/2026-08-11-plot-service-retired.md`。

**`openapi.yaml` 与 `schemas/*.json` 尚未落笔**：按「先有设计再建文件」，它们在首个端点进入实现时同时落地；在此之前 markdown 的字段表即视为草案。

## 契约文档

| 文档 | 覆盖 | 对位的客户端成分 | 状态 |
|---|---|---|---|
| `envelope.md` | 表达形式、序列化约定、`/v1/` 主版本、传输 / 负载信封（含 **`flagsVersion`**）、错误体与错误码台账、版本协商与强更闸门、Profile 三段可见性 | 全部 | **已成文** |
| `content-manifest.md` | manifest schema 与三版本号分工、blob 内容寻址、ES256 detached 签名与 `keyId` 轮换、`ContentEnabled` 的 flags 第三层、**剧本文本的承接** | `content-service` | **已成文** |
| `auth.md` | 登录、会话、token 续期与失效、多设备裁决 | `account-service` | 计划中（**下一份**——它承载 token 生命周期与 `auth.token_expired` / `auth.session_revoked` 这两个必须分开的 `code`） |
| `profile-sync.md` | Profile 上行 / 下行报文，负载信封 `pushId` · `baseRevision` · `schemaVersion` · `reason`，三分支应答，后端可见字段子集 | `sync-service` | 计划中 |

计划中的文档**尚未建立**——按「先有设计再建文件」的约定，不预先占位空壳。

## 约定

- **契约变更是跨库事件。** 任何改动报文语义的决定，两侧各写一份 handoff 并互相回链（见 `handoffs/_TEMPLATE.md` 的「客户端侧影响」段）。
- **报文字段名与客户端字段名可以不同**，但语义必须一一对应，且在契约文档中显式给出映射——不靠「同名即同义」的默契。
- **只保留最新契约。** 契约文档是活文档：改了就重写，历史归 git。已上线后的兼容性由**版本化字段**承担，不靠在文档里保留旧形态。
