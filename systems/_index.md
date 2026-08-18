# 系统 —— 后端设计意图索引

后端各服务的动态设计文档：每个服务一份文档（或复杂时下沉为文件夹，含 `_index.md`）。此处描述**服务内部怎么实现**；边界报文归 `contracts/`，客户端侧的用法归 `game-design-documents/systems/services/`。

## 现状

**尚未建立任何服务文档。** 协议契约四份已成文（`contracts/envelope.md` · `content-manifest.md` · `auth.md` · `profile-sync.md`），但后端技术栈与托管形态仍未定（`open-questions/06-platform-stack.md`），而服务内部设计（存储、并发控制、会话形态）离不开它。按「先有设计再建文件」的约定，此处不预先占位空壳。

## 计划中的服务

| 文档 / 文件夹 | 职责 | 对位的客户端成分 |
|---|---|---|
| `account.md` | 账号、鉴权、会话、多设备裁决、合规能力（注销 / 导出） | `account-service` |
| `profile-store.md` | 权威 profile 存储、`revision` 计数器与 CAS、`pushId` 幂等窗口 | `sync-service` |
| `content-delivery.md` | overlay 构建与分发、`manifest.json`、放量 / 秒关开关、**剧本文本随内容一并发布** | `content-service` |

**只有三个服务，对位三个跨边界的客户端成分。** 剧本服务已于 2026-08-11 撤销：剧本内容本地化为客户端内容层的一员，由 `content-delivery` 以普通内容文件承接，后端不再有剧本形态的服务。
Source: `handoffs/2026-08-11-plot-service-retired.md`。

## 约定

- **文件名与它所服务的客户端成分对齐**，使一个 handoff 能干净地映射到两侧同一处。
- **不复述客户端设计。** 需要客户端语义时回链 `game-design-documents/`，只在本库写「后端如何兑现它」。
- **持续更新，只保留最新设计**：内容被取代 / 迁移时直接重写替换，不留考古（见 `README.md` 的维护约定）。
