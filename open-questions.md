# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；
> 问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），
> 两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；
> 一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-08-22** —— 回声校验与收据幂等承接落笔（移出 0 条 · 新增 1 条）。
> （逐次更新摘要见 `open-questions/update-log.md`；答结归档见 `answer-logs/`。）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-contracts.md` | **① 协议契约**：展开见表下 |
| `open-questions/02-account-compliance.md` | **② 账号与合规**（现焦点之首）：展开见表下 |
| `open-questions/04-content-delivery.md` | **④ 内容分发（CDN）**：展开见表下 |
| `open-questions/06-platform-stack.md` | **⑥ 技术栈 · 托管 · 运维**：选型、区域合规、环境分层、可观测性、成本模型。 |
| `open-questions/cross-boundary.md` | **跨边界承接**：客户端已定案、本库尚未落笔的条目。**不是待答问题**——答案已有，等的只是落笔；形态与关闭条件见分片抬头，机制设计见客户端库同名分片。 |

分片展开（承接上表）：

- **`01`** —— 六份契约全部成文（→ `contracts/envelope.md`、`content-manifest.md`、`auth.md`、`profile-sync.md`、`purchase.md`、`compliance.md`）；
  余下四条——**回声校验的适用面与比较口径**（承重，已有 `decided` 草稿在办）、`refresh` 的限流形态（待 `06`）、合规域端点自身的错误码（随报文本体落笔）、三条机检断言的承载位置（待 `06`）。
- **`02`** —— 敏感词词表与审核口径、未过审昵称的存量扫描、风控系统与异常账号处置、合规能力的上线分级。
  身份模型、合规落地与多设备裁决均已答结（→ `contracts/auth.md`、`contracts/compliance.md`）；余下各条共用 `account.status` 作挂接点。
- **`04`** —— 协议四条已答结（→ `contracts/content-manifest.md`）；
  余下 flags 运营形态、签名私钥保管、多区域一致性、**剧本内容的体积与分包**。

> **编号 `05` 已空缺**：原「⑤ 剧本下发」分片于 2026-08-11 随云端剧本服务撤销而**整片删除**
> （剧本内容本地化为客户端内容层，见 `handoffs/2026-08-11-plot-service-retired.md`）。
> 编号不回填、不重排——`06` 的编号在别处已被引用，重排的代价高于留一个空位。
>
> **编号 `03` 已空缺**：原「③ 存档同步 / 冲突」分片于 2026-08-14 随 `contracts/profile-sync.md` 成文而**整片删除**
> （五条全部答结或被契约覆盖，实现层面的部分并入 `06`，见 `handoffs/2026-08-14-profile-sync-contract.md`）。
> 同样不回填、不重排。

## 当前焦点：`06`，其次 `02`

**六份契约全部成文**——

- `envelope.md`（边界层，08-11）
- `content-manifest.md`（内容分发，08-11）
- `auth.md`（登录与会话，08-13）
- `profile-sync.md`（存档同步，08-14）
- `purchase.md`（付费验票与后端权威写入，08-16）
- `compliance.md`（实名 / 防沉迷 / 注销 / 导出，08-16）。

**已成文契约上再无取值留白**——`reasonKey` 三处与 `compliance.*` 码清单已于 08-16 全部填表。焦点顺序因此换位：

1. **`06` 技术栈 · 托管** —— `operations/` 落地的**唯一前置**，且已承接全部实现层问题：
   同步侧（CAS 存储、幂等记录、限流实现、跨区域拓扑、可观测性三探针）· 会话侧（会话记录存储、同事务吊销、`signin` 幂等回放记录）·
   合规侧（可信服务端时钟、`complianceTicket` 与冷静期状态机、导出产物与链接签发）· **契约一致性三条机检断言的承载位置**。
2. **`02` 账号与合规** —— 余下的是**运营口径与风控**，不再卡任何契约：
   敏感词词表与审核口径 · 未过审昵称的存量扫描 · 风控系统的有无与形态（`profile-sync.md` 已把复算不一致的处置指向它）· 合规能力的上线分级（与 `06` 的托管 / 备案排期耦合）。
   各条共用 `account.status` 作挂接点，不再各立一套「是否可玩」的真值。
3. **`01` 余下条目** —— 全是横切项，不挡任何契约：
   `purchase.md` 的 `receipt` 字段渠道形态与错误码映射（待支付渠道选型，归 `06`）· `refresh` 的限流形态（待 `06`）·
   合规域端点自身的错误码（随 `compliance.md` 报文本体落笔）· 三条机检断言的承载位置（待 `06`，在此之前走人工清单）。
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

**最近全量评估：2026-08-20（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（2）· `contracts/**`（7 份 `.md` + `vectors/splitmix64.json`）· `systems/`（1）· `operations/`（1）· `decisions/`（8），共 **20 份**。

**全局结论：本库第一次出现可 derive 的文档 —— ready 1 份 · partial 2 份 · blocked 17 份。** 上次评估点名的那个「唯一横亘在 partial 与 ready 之间、且不依赖任何未决设计」的卡点——**全库零 ADR**——已经倒下：七条候选全部写成正文并置 `Accepted`（`ADR-0001` ~ `ADR-0007`，见 `decisions/_index.md`），就绪判据第 3 条对每一份契约首次成立。

**卡点结构未变，仍是两类，且都不挡任何一份契约的报文本体：**

- **🔴 `06` 技术栈 · 托管**（挡住 `systems/` 与 `operations/` 的全部展开、`purchase.md` 的 `receipt` 形态、`refresh` 的限流形态、三条机检断言的承载位置、CAS / 幂等 / 限流 / 会话 / 合规状态机的存储语义）。它已是本库唯一的结构性前置。
- **🟠 `02` 运营口径**（敏感词判定输入 ⇒ `nickname` 的验收断言写不实；风控形态 ⇒ `profile-sync.md` §7a 的处置面）。

**另有一处属「待落笔」而非设计未决，且不待 `06`：`contracts/compliance.md` 六端点的报文字段表与其自身错误码。** 它是本库当前**唯一一处会向对侧传导的欠账**——客户端 `systems/services/account-service.md` 的合规呈现面因此写不出可验证的验收标准（已在客户端库本次评估中标为「须整体排除」）。一次正式的契约变更（含 `envelope.md` §6 台账登记）即可关闭。

| 文档 | 判定 | 卡点 / 就绪切片 |
|---|---|---|
| `contracts/profile-sync.md` | **ready** | **本次由 partial 升级**：上次的唯一残留卡点（ADR 未 Accepted）已消解——`ADR-0005`（防作弊边界）与 `ADR-0006`（SplitMix64 随机源）均已 Accepted。整面 = pull / push 两端点的完整协议面：报文、§3a 顶层键浅合并、§4 三分支 + 幂等命中、§5 逐 JSON path 白名单与后端写入封闭四行表、§5b 命名通则、§6 SplitMix64（**`vectors/splitmix64.json` 提供唯一可执行的验收检查点**）、§7 §7a 复算边界与「仅记账不拒绝」、§8 §9 §10 CAS / 幂等 / 限流的服务端语义。其余 Open questions（风控事件落地形态 · CAS 存储 / 幂等记录 / 限流实现 / 跨区域拓扑）全部归 `02` / `06` 且**契约已明写「不回头改契约」** ⇒ 报文面不会返工。跨边界零欠账（客户端对位七点已于 08-16 落笔、字段命名已于 08-17 两侧同批改齐） |
| `contracts/auth.md` | **partial** | ADR 前置已满足（`ADR-0004` auth 域幂等 Accepted）。就绪切片 = 会话与身份的语义面：§1a 身份模型（绝不隐式合并）· §2 双 token · §4 rotation + 60 秒宽限窗口 · §4a 会话裁决（`sid` · `(accountId, deviceId)` 唯一约束 · 活跃会话上限 1 · `signin` 60 秒幂等回放）· §7 七端点全幂等 · §9 五个错误码 · §5 §5a 闸门与合规拦截只在 `signin`——全部可写成栈中立的请求 → 应答断言。**其余卡于**：`refresh` 的限流形态（`06`；一旦认定必须限流即需回改 §8 报文并给客户端第三条路径，**这是切片内唯一可能回改报文的点，故 derive 时须排除 `refresh` 的错误面**）· `nickname` 的敏感词判定输入与改名频次阈值（`02` / `06`，验收断言写不实）· 未过审昵称的存量扫描（`02`）· 短信 / 实名核验服务商与微信资质、token 签名密钥保管与会话存储（`06`）· 对位的 `systems/account.md` 未建立 |
| `contracts/content-manifest.md` | **partial** | ADR 前置已满足（`ADR-0001` 内容寻址 + 单调 `contentVersion`、`ADR-0002` flags 第三层只覆盖 `ContentEnabled`，均 Accepted）。就绪切片 = **CDN 域三端点的协议面**（`manifest` / `manifest.sig` / `blobs/<sha256>`）：三条服务端保证、`manifestSchema: 1` 字段表、ES256 detached 签名与 `keyId` 轮换、`contentVersion` 严格单调（回滚即前滚）、三版本号分工——验收可写成栈中立断言（blob 先于 manifest 可读；manifest 原始字节可被 `keyId` 对应公钥验签；同 hash URL 字节不可变）。**其余卡于**：`/v1/content/flags` 的分桶与数据源运营形态（`04` + `06`）· ES256 私钥保管与 CI 签名步骤（`04`，反向约束 `06` 选型）· 多区域 `contentVersion` 是否同步推进（`04` + `02`）· flags 是否落客户端本地缓存（**归对侧裁决，本库不代为决定**）· 剧本本地化后的体积与分包边界（`04`，**两侧同题待答**）· 对位的 `systems/content-delivery.md` 与 `operations/content-delivery-ops.md` 均未建立 |
| `contracts/purchase.md` | blocked | **`receipt` 字段的内部形态与平台错误码映射未定**，待**支付渠道**选型（`06`；与登录渠道不同轴，账号侧答结**不解锁**本条）——它是 `POST verify` 请求体的核心字段，缺它写不出完整的 `Contract touchpoints`。§2 权威分配、§6 四条服务端保证、收据幂等读的语义已可用，且 ADR 前置已满足（`ADR-0007` 写入只由 verify 承担，Accepted），**支付渠道一落定即转 partial**。另：幂等记录存储与对账补偿任务归 `06` |
| `contracts/compliance.md` | blocked | **六端点的报文字段表尚未落笔**（请求 / 应答字段、`taskId` 形态、导出任务状态机取值），**端点自身的错误码亦未落笔**（ticket 过期 / 已消费、核验拒绝、冷静期已过、导出任务不存在）——两者都属待落笔，应由一次正式契约变更承担，**且这是本库当前唯一向对侧传导的欠账**。此外可信服务端时钟、`complianceTicket` 存储与一次性消费、冷静期长时状态机、导出产物与链接签发全部待 `06`。已定的端点集、ticket 机制、拦截只在 `signin`、四条 `compliance.*` 与防沉迷复用 `session_revoked` 不足以支撑逐端点的验收断言 |
| `contracts/envelope.md` | blocked | 共有层，**不存在独立可构建的增量**（无端点即无「请求 → 应答」的验收断言）。ADR 前置已满足（`ADR-0003` OpenAPI 单点 / 不共享 DTO，Accepted）。两条 Open questions：合规域端点自身的错误码随 `compliance.md` 报文本体落笔 · 三条机检断言的**承载位置**待 `06`（在此之前走人工清单）。它随上述任一份契约的首个 FR 一并兑现信封与错误体 |
| `contracts/_index.md` | blocked | 索引 / 台账，非 derive 对象。「六份 + 分域判据 + 完成判据 + 三条机检断言」与实际一致，无失真 |
| `contracts/vectors/splitmix64.json` | blocked | 非 derive 对象（机器可读的对表产物，不是报文形态）。它的作用是给 `profile-sync.md` 的就绪面提供可执行检查点 |
| `systems/_index.md` | blocked | **尚无设计意图**——三份计划中的服务文档（`account.md` · `profile-store.md` · `content-delivery.md`）均未建立，前置为 🔴 `06` 技术栈。（索引正文「协议契约四份已成文」为陈述失真，实为六份；不影响判定，留待 `/summarize-open-questions` 清理） |
| `operations/_index.md` | blocked | **尚无文档**——六份计划中的文档均未建立。索引内已有实质要求（发布顺序、缓存 TTL、错误码台账登记流程、版本兼容矩阵、统计计数禁令），但全部以「栈落定后展开」为条件，前置 🔴 `06` |
| `vision/scope.md` · `vision/pillars.md` | blocked | 非 FR 面（北极星与裁决原则，只陈述边界与硬约束，不含可验证行为）。作为其余文档的挂靠前置成立，自身不产出需求 |
| `decisions/ADR-0001` ~ `ADR-0007`（7 份 Accepted） | blocked | 已采纳的决策记录，**非 derive 对象**（作为其余文档的就绪前置，本身不产 FR）。**本次评估的关键变化即在此**：七条候选全部落成正文并 Accepted，就绪判据第 3 条首次对每份契约成立 |
| `decisions/_index.md` | blocked | 台账，非 derive 对象。候选表已清空，无失真 |

**跨边界闭合（强制检查项）的结论：本库无欠账，且对侧亦无一份文档卡于「本库契约缺失」。** `open-questions/cross-boundary.md` 的「待承接」为空。**球在对侧的三条**（登记在客户端库自己的 `cross-boundary.md`，本库不催办、不代为决定）中已有两条落笔——`deviceId` 的生成与持久化落点、三处 `reasonKey` 的玩家可见措辞（客户端 08-19 一批），**仅剩 `ComplianceManager` 的覆盖面切分**一条，且它是对侧自己的取向。**两侧同题待答的一条**：剧本本地化后的分包边界——契约形态归本库、分包边界由内容规模决定，两侧须一致。**本库向对侧的唯一传导项**：`compliance.md` 六端点报文字段表未落笔 ⇒ 对侧 `account-service` 的合规呈现面本轮被整体排除在其就绪切片之外。

### 建议的 derive 顺序（仅限 ready / partial 项；被依赖的契约先于依赖它的系统）

1. `/derive-requirements contracts/profile-sync.md` —— **本库首份 ready**：协议面最完整、跨边界已闭合、ADR 前置齐备，且有 `vectors/splitmix64.json` 这个可执行检查点；其 Open questions 全部明写「不回头改契约」，报文面不会返工。
2. `/derive-requirements contracts/auth.md` —— **derive 时排除 `refresh` 的限流 / 错误面与 `nickname` 的敏感词判定**，其余（身份模型 · 双 token · 会话裁决 · 七端点幂等 · 五个错误码）可独立成立。
3. `/derive-requirements contracts/content-manifest.md` —— **仅取 CDN 域三端点的协议切片**；`flags` 端点留到 `06` / `04` 落定。

`envelope.md` 不单独 derive（共有层，随上述任一份的首个 FR 一并兑现其信封与错误体）。`purchase.md` / `compliance.md` 各自等自己的落笔前置。

### 最短解锁路径

1. **`contracts/compliance.md` 六端点的报文字段表与其错误码** —— 纯落笔、不待 `06`，一次正式契约变更即可（含 `envelope.md` §6 台账登记）。**优先级最高**：它是本库唯一向对侧传导的欠账，关闭它同时解锁客户端 `account-service` 的合规呈现面。→ `/analyze-new-ideas backend`
2. **🔴 `06-platform-stack.md`** —— 解锁 `systems/` 与 `operations/` 的全部展开、`purchase.md` 的 `receipt` 形态（支付渠道）、`refresh` 的限流形态（`auth.md` 转 ready 的最后一道）、三条机检断言的承载位置、CAS / 幂等 / 限流 / 会话 / 合规状态机的存储语义。**它是本库唯一的结构性前置**，且背着三项必须做的选型（支付渠道，**与登录渠道不同轴** · C 层原子能力的服务商与灾备 · 微信开放平台资质，**首个玩家建号前必须完成**）。
3. **🟠 `02-account-compliance.md`** —— 敏感词判定输入（解锁 `auth.md` 的 `nickname` 验收断言）与风控形态（解锁 `profile-sync.md` §7a 的处置面）。可与 `06` 并行。
4. **`04` 的运营形态与私钥保管** —— 解锁 `content-manifest.md` 的 `flags` 端点那一半。与 `06` 耦合。

## 下一阶段

后端尚未开工，但**契约骨架已经完整**（六份）且**再无取值留白**：
客户端侧已定的四组语义（`revision` CAS · `pushId` 幂等 · `AccountSeed` 与掷骰复算 · 购买段验票与权威写入）全部有处可依，
三处 `reasonKey` 与 `compliance.*` 码清单也已填表——客户端的 `ErrorText` 自此可以机械落地。

本库的下一步是**技术栈落定（`06`）**，它已是唯一的结构性前置：
`systems/` 与 `operations/` 的展开、以及 `requirements/` 的推导都以它为条件，见 `README.md` 的文件夹图例。
`06` 现背着四组承接：同步侧实现语义 · 会话记录的存储与同事务吊销 · 合规侧（可信时钟 / ticket / 冷静期状态机 / 导出产物）· 三条机检断言的承载位置，
外加三项选型（支付渠道，**与登录渠道不同轴** · C 层原子能力的服务商与灾备 · 微信开放平台资质，**首个玩家建号前必须完成**）。
`02` 余下的是运营口径与风控，可与 `06` 并行。
`systems/account.md` 的开篇材料已备齐（三层切分 + identity 模型 + 会话裁决），只等 `06` 落定。

**尚未落笔的两块契约面欠账**（属待落笔，不是设计未决）：`contracts/compliance.md` 六端点的报文字段表与它们自身的错误码 · `openapi.yaml` 与 `schemas/*.json`（触发点 = 任一侧首个端点进入实现）。
