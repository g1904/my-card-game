# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；
> 问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），
> 两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；
> 一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-08-14** —— SplitMix64 测试向量填值答结：`01` 一条移出；
> `contracts/vectors/splitmix64.json` 落笔，「跨语言逐位一致」自此有可执行检查点。
> （逐次更新摘要见 `open-questions/update-log.md`；答结归档见 `answer-logs/`。）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-contracts.md` | **① 协议契约**：展开见表下 |
| `open-questions/02-account-compliance.md` | **② 账号与合规**（现焦点之首）：展开见表下 |
| `open-questions/04-content-delivery.md` | **④ 内容分发（CDN）**：展开见表下 |
| `open-questions/06-platform-stack.md` | **⑥ 技术栈 · 托管 · 运维**：选型、区域合规、环境分层、可观测性、成本模型。 |

分片展开（承接上表）：

- **`01`** —— 四份契约全部成文（→ `contracts/envelope.md`、`content-manifest.md`、`auth.md`、`profile-sync.md`）；
  余下全是横切项——`auth.md` 的三处留白、`compliance.*` 码清单、`bundleGrantOrdinal` 透明路径、三条机检断言的承载位置（待 `06`）。
- **`02`** —— 自建 vs 第三方、PIPL / 实名 / 防沉迷 / 注销 / 导出（**落点不得选在 `/v1/profile/*`**）、
  多设备并发裁决（**卡着 `auth.md` 的 `reasonKey` 取值表**）、风控系统与异常账号处置。
- **`04`** —— 协议四条已答结（→ `contracts/content-manifest.md`）；
  余下 flags 运营形态、签名私钥保管、多区域一致性、**剧本内容的体积与分包**。

> **编号 `05` 已空缺**：原「⑤ 剧本下发」分片于 2026-08-11 随云端剧本服务撤销而**整片删除**
> （剧本内容本地化为客户端内容层，见 `handoffs/2026-08-11-plot-service-retired.md`）。
> 编号不回填、不重排——`06` 的编号在别处已被引用，重排的代价高于留一个空位。
>
> **编号 `03` 已空缺**：原「③ 存档同步 / 冲突」分片于 2026-08-14 随 `contracts/profile-sync.md` 成文而**整片删除**
> （五条全部答结或被契约覆盖，实现层面的部分并入 `06`，见 `handoffs/2026-08-14-profile-sync-contract.md`）。
> 同样不回填、不重排。

## 当前焦点：契约面已封顶，焦点转向 `02` 与 `06`

**四份契约全部成文**——

- `envelope.md`（边界层，08-11）
- `content-manifest.md`（内容分发，08-11）
- `auth.md`（登录与会话，08-13）
- `profile-sync.md`（存档同步，08-14）。

**契约面无第五份**（剧本契约已撤销）。焦点顺序因此变为：

1. **`02` 账号与合规** —— 现在是唯一还卡着**已成文契约取值**的分片：
   `auth.session_revoked.detail.reasonKey` 的取值集合、`compliance.*` 的具体码清单与其在 `signin` 的分支形态
   （**落点边界已定：不得选在 `/v1/profile/*`**）。**报文形状不受影响**，落定时只补取值表。
   风控系统的有无与形态也在此——`profile-sync.md` 已把复算不一致的处置指向风控。
2. **`06` 技术栈 · 托管** —— 现在是 `operations/` 落地的**唯一前置**，
   且已承接同步侧的全部实现层问题（CAS 存储、幂等记录、限流实现、跨区域拓扑、可观测性三探针），
   以及**契约一致性三条机检断言的承载位置**。与 `02` 的合规托管耦合，可与之并行。
3. **`01` 余下条目** —— 全是横切项，不挡任何契约：
   `bundleGrantOrdinal` 透明路径（待客户端）· 三条机检断言的承载位置（待 `06`，在此之前走人工清单）。
   **spec 的落笔时机与一致性核对方式**已于 2026-08-14 答结（→ `contracts/_index.md` + `envelope.md` §1）；
   **SplitMix64 测试向量**同日填值答结（→ `contracts/profile-sync.md` §6a + `contracts/vectors/splitmix64.json`）。
4. **`04` 内容分发** —— 协议已答结，余下是运营形态与私钥保管（与 `06` 耦合）。

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

后端尚未开工，但**契约骨架已经完整**（四份，2026-08-14 封顶）：
客户端侧已定的三组同步语义（`revision` CAS · `pushId` 幂等 · `AccountSeed` 与掷骰复算）自此全部有处可依。

本库的下一步是**技术栈落定（`06`）与合规路线落定（`02`）**——
`systems/` 与 `operations/` 的展开、以及 `requirements/` 的推导都以它们为前置，见 `README.md` 的文件夹图例。

**同时有一份跨库欠账：客户端侧需一份对应 handoff**
（七点，见 `handoffs/2026-08-14-profile-sync-contract.md` 的「客户端侧影响」段），
其中 `AccountRng` 换随机源、两个新字段与两条写入约定、`sourceCode` 的边界映射与本契约**互为前提**——
它们未落地则复算协议在客户端侧无对应实现。

**其中第 6 点（`AccountRng` 换随机源）自 2026-08-14 起已有可直接消费的验收物**：
`contracts/vectors/splitmix64.json` 的 8 组向量已填，客户端实现后跑一遍即可，**无须等后端动手**。
