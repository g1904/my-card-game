# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；问题条目本身按主题拆在 `open-questions/` 下的分片里。客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-08-11（剧本服务撤销：`05` 分片整片作废删除，4 条移出；剧本内容改由 `content-manifest.md` 通道承接）。** 逐次更新摘要见 `open-questions/update-log.md`。

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-contracts.md` | **① 协议契约**（焦点之首）：边界层已成文（→ `contracts/envelope.md`）；余下各端点报文本体（`auth` / `profile-sync`）、`compliance.*` 码清单、spec 落笔时机。 |
| `open-questions/02-account-compliance.md` | **② 账号与合规**：自建 vs 第三方、PIPL / 实名 / 防沉迷 / 注销 / 导出、多设备并发裁决、token 失效、风控。 |
| `open-questions/03-sync-conflict.md` | **③ 存档同步 / 冲突**：`revision` CAS 的服务端实现、`pushId` 幂等窗口、`AccountSeed` 下发与复算、限流。 |
| `open-questions/04-content-delivery.md` | **④ 内容分发（CDN）**：协议四条已答结（→ `contracts/content-manifest.md`）；余下 flags 运营形态、签名私钥保管、多区域一致性、**剧本内容的体积与分包**。 |
| `open-questions/06-platform-stack.md` | **⑥ 技术栈 · 托管 · 运维**：选型、区域合规、环境分层、可观测性、成本模型。 |

> **编号 `05` 已空缺**：原「⑤ 剧本下发」分片于 2026-08-11 随云端剧本服务撤销而**整片删除**（剧本内容本地化为客户端内容层，见 `handoffs/2026-08-11-plot-service-retired.md`）。编号不回填、不重排——`06` 的编号在别处已被引用，重排的代价高于留一个空位。

## 当前焦点：把端点报文逐份写完

**契约的边界层已于 2026-08-11 成文**（`contracts/envelope.md`：表达形式 · 序列化约定 · `/v1/` 主版本 · 传输 / 负载信封 · 错误体与错误码台账 · 版本协商 · Profile 三段可见性）。`content-manifest.md` 的字段名随之转正，它推给信封的两项欠账也已答结。因此焦点顺序变为：

1. **`01` 各端点报文** —— `auth.md` **先行**（它承载 token 生命周期与 `auth.token_expired` / `auth.session_revoked` 这两个必须分开的 `code`），再 `profile-sync.md`。**这两份写完，契约面即完整**——剧本契约已撤销，其后不再有第三份端点契约。
2. **`02` 账号与合规** —— 它同时卡着两处：`auth.session_revoked` 的**触发条件**（多设备并发裁决）与 `compliance.*` 的**具体码清单**。因此它现在是 `auth.md` 完整成文的前置。
3. **`03` 存档同步** —— `AccountSeed` 复算协议落定后，`profile-sync.md` 的「后端可见字段子集」才能逐字段列出。
4. **`06` 技术栈 · 托管** —— **不再是 `01` 的前置**（表达形式已与选型解耦），但仍是 `operations/` 落地（兼容矩阵存放、限流实现、可观测性口径、签名私钥保管）的前置，且与 `02` 的合规托管耦合。可与 `01` 并行推进。

## 判据：一个问题落在哪一侧

| 判据 | 归属 |
|------|------|
| 由客户端代码实现、后端不感知 | `game-design-documents/` |
| 由后端实现，或需要两侧约定报文 | 本库 |
| 客户端语义已定、只剩服务端如何兑现 | 本库（在条目中注明「客户端侧已定」+ 日期 + 回链） |

## derive 就绪度

> 本小节由 `/assess-derive-readiness` **独占写入**（`/analyze-new-ideas` 与 `/summarize-open-questions` 均不得改动）。就绪度需基于全库一次性全量扫描才有意义，顺带评估会迅速过时且互相矛盾。

**最近全量评估：尚未运行。** 本库的主题文档区（`contracts/` · `systems/` · `operations/`）尚未建立任何设计文档，`vision/` 之外无可评估对象——**全库尚未进入可 derive 的阶段**。

## 下一阶段

后端尚未开工。契约骨架已立起两份（`contracts/envelope.md` 边界层 + `contracts/content-manifest.md` 内容分发），本库的下一步仍不是写实现，而是**把余下两份端点契约写完**（`auth.md` → `profile-sync.md`），使客户端侧已定的三组语义（`revision` CAS · `pushId` 幂等 · `AccountSeed` 与掷骰复算）有处可依。`systems/` 与 `operations/` 的展开、以及 `requirements/` 的推导，都等技术栈落定（`06`）——见 `README.md` 的文件夹图例。
