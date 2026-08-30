# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；
> 问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），
> 两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；
> 一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-08-30** —— flags 缓存的报文侧对位 + blob 不承载二进制（跨库成对 · 移出 2 条 · 新增 0 条 · 详见 `open-questions/update-log.md`）。
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
  余下三条——`refresh` 的限流形态（待 `06`）、合规域端点自身的错误码（随报文本体落笔）、三条机检断言的承载位置（待 `06`）。
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

**最近全量评估：2026-08-30（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（2）· `contracts/`（7 份 `.md` + `vectors/splitmix64.json`）· `systems/`（1）· `operations/`（1）· `decisions/`（**17 份 ADR，全部 Accepted** + `_index.md`），共 **30 份**。旁证：`requirements/` **零 FR**（无「已覆盖」项）· `handoffs/` **21 份全为 `distilled`**（无未采集意图面）· `inbox/` 顶层为空 · 本库 `open-questions/cross-boundary.md`「待承接」区为空。本次重估的触发是 08-30 的跨库成对落笔（`handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`）与对侧客户端库同日的四次连续落笔（两批 `/batch-analyze-new-ideas` · 一次 `/write-adr game` 固化 `ADR-0123` ~ `ADR-0132` · 一次全量整理）。

**全局结论：ready 1 份 · partial 2 份 · blocked 27 份 —— 与 08-26 / 08-28 的判定结构完全一致，连续第三次无一份升降级。** `contracts/profile-sync.md` 仍是本库唯一 ready（08-28 之后**文件零编辑**），`auth.md` / `content-manifest.md` 仍 partial，`purchase.md` **连续第四次**未兑现「转 partial」的预告且卡点一字未动。

**本次唯一的实质变化：`content-manifest.md` 的卡点由九条缩为七条，就绪切片扩大三块。** 08-30 的跨库成对落笔为它新增了三段**可直接写成断言**的内容：`no-cache` 只约束 HTTP 缓存层、不约束客户端应用层持久化（回链 `envelope.md` §3，不复制）· **后端对客户端 flags 缓存的四行零义务否定表**（不下发 TTL / `max-age` · 不回显 `accountId` · 不提升 `flagsSchema` · 不新增服务端保证）· **`## blob 通道不承载二进制资产`** 一节，含「这不是契约能力不足」的能力中立声明。B 组第 7 条的依赖方登记为两项（条款本体一字未改）。**报文零改动**（`flagsSchema` / `manifestSchema` 均不提升，A 组仍四条、B 组仍三条）。同批纠正了 `ADR-0002` 后果段的「以支撑离线开局」这一错误前提（决策本体一字未动，不改判定）。⇒ **derive 排除面少一项**：「二进制资产经 blob 通道的一切面」从「未裁决故排除」变为**已裁定为不承载、可写成否定断言**。但这不足以转 ready —— 传播窗口 T、缓存层是否存在、CDN 失败状态码三条仍使部分验收断言写不实。

**两条贯穿全库的判据说明（先读，避免误判）：**

- **判据 1 的形式说明。** 六份契约中**只有 `content-manifest.md` 带正式 `## 意图` 标题**；其余五份把同等分量的范围陈述放在标题下的 `>` 前言里（覆盖什么 · 不覆盖什么 · 相对 `envelope.md` 的差异面 · `Source:`）。**全库无一处模板占位符 `> _..._`。** 故判据 1 按「有真实内容」判定成立，**不按标题字面判定**——这是格式不齐，不构成 derive 闸，也不该据此降级。
- **库级 derive 限定语（文档自己提出的）。** `contracts/envelope.md` §1 自陈「**在某端点的 spec 落笔前，其 markdown 字段表视为草案**」，且「markdown 中的形态性文字（示例报文等）均为说明性，不具规范性」。今天从任何字段表推出的 FR，都是从本库自陈的草案推出的。**处置：以 markdown 为源 derive，待 `openapi.yaml` 落笔时做一次纯形态对账——不作为闸门。**

**卡点结构仍是三类，第三类仍只剩一处：**

- **🔴 `06` 技术栈 · 托管** —— 唯一的结构性前置（挡住 `systems/` 与 `operations/` 的全部展开、三渠道逐家接入面、`refresh` 限流形态、三条机检断言的承载位置、CAS / 幂等 / 限流 / 会话 / 合规状态机的存储语义，以及 **`envelope.md` §7e 兼容矩阵的落点**与**读己所写对拓扑与读路径的约束**——不满足它的部署形态直接出局）。
- **🟠 `02` 运营口径** —— 敏感词判定输入 ⇒ `nickname` 的验收断言写不实；风控形态 ⇒ `profile-sync.md` §7a / §5c 风控事件的落地面（仅影响可观测性，**不改报文面**）。
- **🟠 一处「待落笔」（非设计未决，但改报文面）** —— `compliance.md` **两处**：六端点字段表 **与** 其错误码。

**跨边界闭合（强制检查项）**

- **本库欠对侧：一条（未变）。** `contracts/compliance.md` 的六端点报文字段表与合规域错误码未落笔。对侧 `game-design-documents/open-questions/cross-boundary.md`「待承接」区的**唯一条目**（`ComplianceManager` 覆盖面切分，登记日 2026-08-16）因此写不出验收标准，对侧 `systems/services/account-service.md` 亦把该切分挂在自己的 Open questions 上并指回本库。**这是全库唯一一处「客户端在等后端」。** 其「对侧台账偏窄」的根因未消：`compliance.md` 有**两处**未落笔，故凡触及合规端点请求 / 应答体的部分（ticket 兑付 · 冷静期状态呈现 · 导出任务轮询与 `taskId`）在本库同样无字段表；**真正 settled 的只有拦截路径**（搭 `signin` 的车、不需要任何合规端点报文）。**但可给对侧一条更精确的口径**：§5 的四条 `compliance.*` **拦截**码与各自 `reasonKey` 取值表已封定 ⇒ 对侧 `ux/error-and-blocking-ux.md` 只需排除「合规域端点自身」那一批 `ERR_*` 的验收断言，拦截路径那一批可以写全。
- **对侧欠本库的落笔：零。** 本库 `cross-boundary.md`「待承接」为空。**08-30 的两条空档已成对关闭**（blob 是否向二进制资产开放 · flags 是否落地客户端本地缓存），两侧各记一条对账基线、互相回链、**无一处复述对侧设计**；对侧同批固化 `ADR-0125` / `ADR-0130` 与之逐条对位。`envelope.md`「跨库待办」五项对侧已于 08-11b 落笔，该段文字滞后未清理，**不是欠账**。
- **客户端 08-28 后新增的 8 份 handoff（`2026-08-30-*`）逐份核对：7 份对后端零义务**（各自 handoff 明写「不落存档 / 不进上行负载 / 不 bump `schemaVersion`」或「全在客户端进程内」，并经本库全量检索核实；`life-lifespan-merge` 的对侧库检索零命中复核成立）。**第 8 份 `exchange-barter-support` 有一条既有机械义务**：`Source.ExchangeBarter = 10` 落 `characterDiffs` 不透明段且本库不复制 `Source` 成员清单 ⇒ **契约零改动**（正是 `ADR-0017` 通则覆盖的场景）；但它明写「`EventOption` 增一格 ⇒ bump 存档 schema」，新 `schemaVersion` 须进 `envelope.md` §7e 兼容矩阵——**每次 bump 都存在的既有机械义务**，由 §7e 通则唯一承接、矩阵落 `operations/` 而栈未定故当前空置，**不改契约、不改判定**。**⚠ 但本库零留痕**（全库检索「barter」零命中），而 08-25 的同类 bump 是记了 handoff 的 ⇒ 对账基线出现一次不一致的处置，见下方漂移清单第 7 条。
- **一处对侧新识别的薄弱点（须带回本库）：** `profile-sync.md:187` 把 schema bump 清单的权威**指回**客户端 `sync-service.md`，而对侧本次评估发现**那张自称「只有一份」的清单已漏三批**（`pastItemUse` / 两个新 spec 列 · `StatusChanges` · `Status` 删三格 · 栈条目 `itemId`）。本库不记、对侧的唯一清单三批未更新 ⇒ **两侧都以为对方在记。** 它不改本库任何一行判定（判据 6 要的是「协议在本库已定案」——已定案），但对侧 derive 存档 / 同步切片前必须先补齐。
- **预警仍未触发**（两侧均已登记，现在无需任何一侧动手）：`characterProfile` 的资源字段一旦提进透明档，必须同批把钳制语义与 `AppliedChange` 累加语义写进 `profile-sync.md`，否则后端复算会在正常账号上误报。08-30 的寿元合并属这一类字段，但它落在不透明段、未提透明档，故仍不触发。

| 文档 | 判定 | 卡点 / 就绪切片 |
|---|---|---|
| `contracts/profile-sync.md` | **ready** | 维持 ready，本次**一字未动**（08-28 之后本文件零编辑）。**就绪切片 = 全文**：§1 端点集封定（含「`accountId` 绝不进 query/body」的否定断言）· §2 pull 三字段应答与新账号骨架 · §3 push 负载信封六必填字段（`reason` 六值）+ 空 diff 照常 `+1` · §3a 顶层键浅合并（整键替换、不递归、无删除语义）· §4 三分支 + 幂等命中五行表 + **判定顺序**（`schemaVersion` → 形状 → CAS → 回声 → 写入）+ 四类拒绝均「不消耗 revision」· §5 十三行白名单 path 表 + 后端写入封闭四行表 + 「缺失透明 path 走告警不拒绝」· §5a `sourceCode` 字符串枚举名与名 / code 双双冻结 · §5b 集合命名恒为单数 · **§5c 完整四段**（适用面恒等式「受约束 path ≡ 写入表行集合」⇒「清单有没有列全」结构性地不存在 · 类型感知比较口径四行表 · 追加字段刚性 · 五条栈中立验收断言）· §6 / §6a SplitMix64 纯函数 + **8 组已填测试向量**（外部权威 `vectors/splitmix64.json`，可逐位断言）· §7 复算三检查 · §7a 仅记账不拒绝 · §8 账号级线性化 + 禁两步非原子 + 读己所写 · §9 `(accountId, pushId)` 幂等 · §10 §11 §12。ADR 前置齐备（`0005` · `0006` · `0008` · `0012` · `0013` · `0014` · `0017` 全 Accepted）。**derive 时的三条参数化纪律（不是排除面）**：① 风控事件写成「记一条结构化事件」（字段已在 §5c / §7a 具名，落地形态归 `02` / `06`）；② §10 的 60 次 / 分钟与 §12 四个初值写成「配置阈值」，不写死数字；③ **§4 的「`schemaVersion` 越出兼容集合」分支只断言形态、不断言边界**（`envelope.md` §7e 兼容矩阵内容仍为空）。**唯一不可断言项**：512 KB profile 软告警（§12）无任何线上可观测面。**本次新核实的零影响事实**：对侧新增 `Source.ExchangeBarter = 10` 落不透明段且本库不复制 `Source` 清单 ⇒ 契约零改动，ready 不受影响 |
| `contracts/auth.md` | **partial** | 维持，卡点一字未变。ADR 前置齐备（`0004` · `0010` · `0011` · `0015` · `0016` 全 Accepted）。**就绪切片**（全部可写成栈中立的请求 → 应答断言）= §1 七端点 · §1a 身份模型（`accountId` 本方发放 · account ↔ identity 一对多 · **绝不隐式合并** · `channelUserId` / `idKind` / `sid` / `status` 不进任何应答，可写成否定断言）· §2 双 token 与 TTL 表 · §3 §3a 渠道分形 `credential` 与换 openid 的三条后端义务、两类错误映射 · §4 rotation + 60 秒宽限窗口（**五分支求值顺序确定**）· §4a 会话裁决（`sid` claim · `(accountId, deviceId)` 唯一约束 · 活跃会话上限 1 · 同设备重登替换 · `signin` 60 秒幂等回放）· §5 §5a 强更闸门与合规拦截**只在 `signin`** · §5b 绝对寿命上限 60 天（`signin` 锚定 · rotation 永不顺延 · 有效性 = `min(滑动, 绝对)` · `SessionExpired` · 软信号 `reauthRecommended` 且不得是时间戳 · §4a 增 `absoluteExpiresAtUtc`）· §6 鉴权例外与请求 / 应答头矩阵 · §7 七端点全幂等（六条重放场景表）· §8 报文与两个旋钮 · §9 五个错误码 · §10 两张取值表（`session_revoked` **八值** · `nickname_rejected` 三值）· §11。**卡于**：`nickname` 的 `SensitiveWord` **判定输入**（词表来源 / 审核口径 / 是否接第三方，归 `02`）与 `TooFrequent` **阈值**（归 `06`）⇒ **derive 时须整体排除 `POST /v1/auth/nickname` 的这两条验收面** · 未过审昵称的存量扫描（`02`）· **`refresh` 的限流形态**（`06`；契约刻意不给 `rate.limited` 以保两条失败路径报文层互斥，一旦认定必须限流即回改 §8 两码互斥**并须给客户端第三条路径**）· token 签名密钥保管与会话存储形态（`06`）· 对位的 `systems/account.md` 未建立。**一处微瑕（不改判定，建议 derive 前消歧）**：§4 求值顺序里「滑动截止到期」分支写「`reasonKey` 沿用既有口径」，而 §10 表内无该情形的专属取值，只能靠推断落到 `SessionExpired` |
| `contracts/content-manifest.md` | **partial**（**卡点本次由九条缩为七条**） | 唯一带正式 `## 意图` 的契约。ADR 前置齐备（`0001` · `0002` · `0009` 全 Accepted；`ADR-0002` 后果段的错误前提已删）。**就绪切片 = CDN 域三端点 + `/v1/content/flags` 的完整协议面**：端点四行表（方法 / 鉴权 / 缓存 / 签名四列全填，含字面量 `public, max-age=31536000, immutable`）· `manifestSchema: 1` 八行字段表 + 示例 · ES256 detached 签名（`{alg, keyId, sig}` 覆盖 manifest **原始字节**）与 `keyId` 轮换 · 三版本号分工 · **服务端保证 A 组四条**（URL 稳定 · 字节不可变 · **发布原子** · `contentVersion` 严格单调、回滚即前滚）· **B 组三条**（`flagsVersion` 取自单一全局单调序列且只由发布动作分配 · 严格单调、回滚即前滚 · 同 `(flagsVersion, 账号)` 结果恒定且分桶须为纯函数）+ 第 7 条的依赖方登记两项 · flags 报文体五字段（`enabledIds` 恒空是硬契约）· 失败面五行处置表 · 剧本文本的 arc / node 分野 · **本次新增三块可直接写成断言的内容**：`no-cache` 的层次边界 · **后端对客户端缓存的四行零义务否定表** · **`## blob 通道不承载二进制资产`**（含能力中立声明）。**已闭合、不再是卡点的两条**：flags 是否落客户端本地缓存 · blob 通道是否向二进制资产开放。**余下卡于（七条）**：flags 规则的数据源与由谁改、按账号计算是否引入缓存层（`04` + `06`；「缓存键必须含 `flagsVersion`」已是硬约束，但缓存层本身是否存在未裁决）· **传播窗口 T 的数值**（`04`）⇒「新批次须在窗口 T 内在全部区域可见」写不成定时断言 · ES256 私钥保管与 CI 签名步骤（`04`）· 发布侧内容校验闸的运维形态（`04`）· 多区域 `contentVersion` 是否同步推进（`04` + `02`）· 剧本本地化后的体积与分包边界（**两侧同题**）· 秒关延迟「分钟级以内」与 `manifestSchema` N-1/N 双发的保留时长 / 分流机制均未定数 + **CDN 三端点的失败状态码未钉死** · 对位的 `systems/content-delivery.md` 与 `operations/content-delivery-ops.md` 均未建立 |
| `contracts/purchase.md` | blocked | **连续第四次未兑现「转 partial」的预告，卡点一字未动**（08-28 之后本文件零编辑）。渠道已定三家（Google Play Billing · App Store StoreKit · 微信支付，§3 `platform` 取值域随之封闭），但 `receipt` 的**内部形态逐渠道不同、仍待逐家接入落笔**，而它是 `POST verify` 请求体的核心字段 ⇒ 写不出完整 `Contract touchpoints`；**verify 失败面的具体 `code` 亦未落笔、未进 `envelope.md` §6 台账**（收据无效 / 已被其他账号核销 / 平台不可达三类只有语义），而 `## Failure & retry semantics` 对后端 FR **强制且不可切** ⇒ **无可独立成立的切片**。`GET receipt/{receiptId}` 亦不能单独成片——它的 `rejected` 原因取值与 verify 失败面同源。已完备的部分（§2 权威分配 · §4 收据幂等读 · §5 复算沿用 §7a 与所有权判据 · §6 七条服务端保证含**读己所写** · §7 `receiptId` 全局唯一键 + 永久保留不设 TTL）**全部描述 verify 的后置条件**，须与 verify 报文面同批落地。ADR 前置齐备（`0007` · `0013` 均 Accepted）。另：幂等记录存储 / 分区 / 冷存归档、对账补偿任务、「`grant > redeemed` 持续 N 天」信号，均已明写归 `06` / `operations/` 且不回头改契约 |
| `contracts/compliance.md` | blocked | 维持。**两处未落笔，不是一处**：① **六端点的报文字段表尚未落笔**（缺请求 / 应答字段、`taskId` 形态、导出任务状态机取值）；② **端点自身的错误码亦未落笔**（ticket 过期 / 已消费、核验服务拒绝、冷静期已过、导出任务不存在或未就绪）。两者均属**待落笔**（非设计未决），应由一次正式契约变更同批承担（含 `envelope.md` §6 台账登记 + `openapi.yaml` 对应 `paths`），**且这是本库唯一向对侧传导的欠账**（`contracts/_index.md` 的状态列亦如实写「已成文（报文字段表待落笔）」）。此外可信服务端时钟、`complianceTicket` 存储与一次性消费保证、注销冷静期这条跨天长时状态机的调度形态、导出产物存储与链接签发，全部待 `06`。**已定但不足以支撑逐端点验收断言的部分**：§2 六端点集与各自鉴权形态 · §3 ticket 机制（一次性 · 10 分钟 · 单端点 · 不进 `Authorization` 头）· §4 拦截只在 `signin` · §5 四条 `compliance.*` 码与各自 `reasonKey`（**这部分已封定且客户端引用无误**）· §6 时段口径落配置 · §7 防沉迷复用 `auth.session_revoked` 的五步映射 · §8 导出最简形态 · §9 四个旋钮初值。**唯一真正 settled 的是拦截路径**。ADR 前置齐备（`0011` · `0015` · `0016` 均 Accepted） |
| `contracts/envelope.md` | blocked | 维持。共有层，**不存在独立可构建的增量**（无端点即无「请求 → 应答」验收断言），故即便内容极完备也判 blocked。ADR 前置齐备（`0003` Accepted）。**内容上已完备、随首个 FR 即可兑现的**：§1 表达形式与 spec 落笔规则 · §2 序列化约定（content-type · lowerCamelCase · 枚举字符串与 C# 成员名逐字 · 忽略未知字段 · RFC 3339 UTC 带 `Z` 与 `AtUtc` 后缀 · 可能 > 2⁵³ 的整数走字符串 · **绝不下发 `null`，可选字段缺席**）· §3 端点风格与主版本 · §4a 请求头与鉴权例外（例外集恰为 auth 前三端点 + 合规两个 ticket 端点，并给了 `GET /v1/compliance/status` **必须鉴权**这个负例）· §4b 应答头 · §5 错误体五字段与 `message` 脱敏纪律 · §5b 三条降级纪律 · §6 **21 行错误码台账**（`class` 随 `code` 恒定是可断言不变式）· §7a–§7e 版本协商 · §8 三段可见性。**卡于两条 Open questions**：合规域端点自身的错误码（随 `compliance.md` 报文本体落笔）· `openapi.yaml` / `schemas/*.json` 的实际落笔（规则已定、只待触发点，唯一仍开放的是**三条机检断言的承载位置**，待 `06`）。**另一处实质空洞**：§7e 的**版本兼容矩阵内容全空**（只列「至少含」四项，落 `operations/version-matrix.md` 待 `06`），它是 `client.version_unsupported` 与 `sync.payload_schema_unsupported` 两个码的**判定输入** ⇒ 两码形态可断言、边界不可断言，并向下传导进 `profile-sync.md` §4 |
| `contracts/_index.md` · `contracts/vectors/splitmix64.json` | blocked | 索引 / 台账与机器可读的对表产物，**非 derive 对象**。`_index.md` 的「六份 + 分域判据 + 契约变更完成判据六条 + 三条机检断言 + 人工清单四项 + `schemas/` 拆分判据」与实际一致；`splitmix64.json` 的作用是给 `profile-sync.md` §6a 提供**唯一可执行的验收检查点**（8 组向量已填，两侧实现后逐位对表，不得单方面改表迁就实现）。**一处计数失真仍在**（记 `session_revoked` 七值 vs 实际八值） |
| `systems/_index.md` | blocked | **尚无设计意图，本次零变化**（目录下仍只有 `_index.md`）。三份计划中的服务文档（`account.md` · `profile-store.md` · `content-delivery.md`）**均未建立**，按「先有设计再建文件」的约定不预先占位。前置为 🔴 `06`（服务内部设计——存储 / 并发控制 / 会话形态——离不开它）。索引本身现无失真。`systems/account.md` 的开篇材料已备齐（三层切分 + identity 模型 + 会话裁决），只等 `06` |
| `operations/_index.md` | blocked | **尚无文档，本次零变化**（目录下仍只有 `_index.md`）。六份计划中的文档均未建立。索引内已有大量实质要求（两类对象两种缓存 TTL · 发布流程五步（顺序即正确性）· **flags 发布 / 回滚 O1–O7 与留痕四项** · 签名私钥保管反向约束托管选型 · 对 CDN 的三条能力要求 · 版本兼容矩阵由后端单点维护 · 错误码台账登记流程 · 台账 ⇔ spec 枚举的机检断言② · `message` 落日志与脱敏纪律 · **三条同步探针 + 一条透明路径缺失告警** · 统计计数的运营侧禁令），但**全部以「栈落定后展开」为条件**，前置 🔴 `06` |
| `vision/scope.md` · `vision/pillars.md` | blocked | **非 FR 面**（北极星与五条裁决原则，只陈述边界与硬约束，不含可验证行为）。作为其余文档的挂靠前置成立，自身不产出需求；`pillars.md` 为 `profile-sync` 的「幂等与 CAS 是承重」、`purchase` 的「读己所写」、`content-manifest` 的「热更优先于跨版本可复现」提供承重论证。**一处失真沿旧（第三次记录）**：`scope.md` 的 In scope 四条仍未列**付费验票域**，而 `contracts/purchase.md` 已成文、三渠道已纳入 MVP，且 `purchase.md` §3 反过来把「范围权威」指回本文件 ⇒ 一处真空指 |
| `decisions/ADR-0001` ~ `ADR-0017`（**17 份全部 Accepted**） | blocked | 已采纳的决策记录，**非 derive 对象**（作为其余文档的就绪前置，本身不产 FR）。**就绪判据第 3 条对六份契约全部成立**——无一份契约受任何 `Proposed` / 未采纳 ADR 约束。**本次份数与状态与 08-28 完全一致（17 份，无新增）**；`ADR-0002` 后果段本次被修订（删「以支撑离线开局」错误前提 + 指向对侧权威），**决策本体一字未动**，不改判定 |
| `decisions/_index.md` | blocked | 台账，**非 derive 对象**。**17 行登记与 17 份实际 ADR 逐条一致、全部 Accepted——无孤儿文件、无悬空行**。「已对后端构成约束的客户端决定」三行有效 |

### 建议的 derive 顺序（被依赖的契约先于依赖它的系统）

1. **`/derive-requirements backend contracts/profile-sync.md`** —— **唯一 ready**。协议面完整、ADR 前置齐备（七份）、跨边界两向闭合，且有 `vectors/splitmix64.json` 这个全库唯一可执行的验收检查点。**无排除面。** 落笔时遵守三条参数化纪律（见表内该行）；不为 512 KB 软告警写验收标准。
2. **`/derive-requirements backend contracts/auth.md`** —— **derive 时整体排除 `POST /v1/auth/nickname` 的 `SensitiveWord` / `TooFrequent` 验收面，以及 `refresh` 的限流面**；落笔前先给 §4 滑动截止分支的 `reasonKey` 做一句消歧。其余（身份模型 · 双 token · rotation 宽限窗口 · 会话裁决 · §5b 绝对寿命上限 · 七端点幂等 · 五个错误码 · 两张取值表含 `session_revoked` **八值** · 头矩阵）可独立成立。
3. **`/derive-requirements backend contracts/content-manifest.md`** —— 取 **CDN 域三端点 + flags 通道协议面 + A 组四条与 B 组三条服务端保证 + 本次新增的四行零义务否定表 + blob 通道不承载二进制的否定断言**。**排除面较上次少一项**：传播窗口 T 的定时断言 · 秒关延迟 SLO · `manifestSchema` N-1/N 双发 · 缓存层相关断言（层是否存在未裁决）· CDN 三端点的具体失败状态码 · 客户端侧义务（semver 比较 · `files[].path` 穿越拒绝 · 验签失败回退基线 · flags 落盘与降级）。**注意**：`no-cache` 的层次澄清可写成后端侧断言（应答须带 `no-cache`），但「客户端持久化」一侧的一切**不进后端 FR**。

`envelope.md` **不单独 derive**（共有层，随上述任一份的**首个** FR 一并兑现信封、错误体与相关错误码）。`purchase.md` / `compliance.md` 各自等自己的落笔前置。

> **注意：首批 FR 会同时触发 `openapi.yaml` 的首落**（`contracts/_index.md` 定：触发点 = 任一侧首个端点进入实现，首落范围 = **全部共有层 + 该一个端点**，且 spec 始终落本库）。同批须过「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项。

### 最短解锁路径

1. **`contracts/compliance.md` 的六端点报文字段表与其错误码** —— **纯落笔，不待 `06`**，一次正式契约变更即可（markdown 语义 + `openapi.yaml` 对应 `paths` + `envelope.md` §6 台账登记五列 + 对侧 handoff 互链，四者同批）。它是本库**唯一**向对侧传导的欠账，关闭它同时解锁客户端 `account-service.md` 的合规呈现面（对侧 `cross-boundary.md` 的唯一在办条目），并连带关闭 `envelope.md` 的第一条 Open question。**优先级最高。** → `/analyze-new-ideas backend`
2. **🔴 `open-questions/06-platform-stack.md`** —— 本库**唯一的结构性前置**。解锁 `systems/`（三份）与 `operations/`（六份）的全部展开 · **三渠道逐家接入面**（`purchase.md` 转 partial 的唯一前置，含 verify 失败面的具体 `code` 与平台错误码归一映射）· `refresh` 的限流形态 · 三条机检断言的承载位置 · CAS / 幂等 / 限流 / 会话记录 / 合规状态机的存储语义与事务边界 · `envelope.md` §7e 兼容矩阵的落点 · **读己所写对拓扑与读路径的约束**（本库唯一一条对读路径的实现约束，不满足的部署形态直接出局）。它背着三项**首个玩家建号前必须完成**的选型：支付渠道三家接入面 · C 层原子能力（短信 / 邮件 / 实名核验）服务商与灾备 · **微信开放平台资质**（首版以 `unionid` 建 identity 是不可逆决定）。
3. **🟠 `open-questions/02-account-compliance.md`** —— 敏感词词表与审核口径（解锁 `auth.md` 的 `nickname` 验收断言）· 风控形态（解锁 `profile-sync.md` §5c / §7a 风控事件的落地面，仅影响可观测性）· 未过审昵称的存量扫描 · 合规能力的上线分级。各条共用 `account.status` 作挂接点。**可与 `06` 并行。**
4. **`open-questions/04-content-delivery.md`** —— **本次解锁面缩小**（flags 客户端持久化那条已答结并登记为「已推给别处」）。余下：flags 规则数据源与是否引入缓存层 · **传播窗口 T 的数值** · ES256 私钥保管与 CI 签名步骤 · 发布侧内容校验闸的运维形态 · 多区域 `contentVersion` 是否同步推进 · 剧本分包边界（两侧同题）。**审计留痕与 flags 发布 / 回滚流程已定案**（`operations/_index.md` O1–O7 + 留痕四项）。与 `06` 耦合。
5. **`vision/scope.md`** —— 只需一行编辑：In scope 补入**付费验票域**。不解锁任何 derive，但 `purchase.md` §3 指回它取「范围权威」而它没写，是一处真空指。**第三次记录，仍未处理。**
6. **`contracts/envelope.md`** —— 无独立解锁路径（blocked 是结构性的：共有层没有独立增量）。它随第 3 节任一份的首个 FR 自动兑现；两条 Open questions 分别由路径 1 与路径 2 关闭。
7. **`contracts/_index.md` · `vectors/splitmix64.json` · `vision/pillars.md` · 17 份 ADR · `decisions/_index.md`** —— **无解锁路径，也不需要**：台账 / 对表产物 / 裁决原则 / 决策记录按定义就不是 derive 对象，永远判 blocked 不代表有欠账。

### 本次核实到的台账漂移（非就绪度断言，不阻塞 derive，建议同批处理）

全库主题文档与 `handoffs/` 中的**遗留旧就绪度断言：零条**（`inbox/archive/` 有历史断言，属溯源留存，不处理）。逐条核实结果：

1. **仍在** —— `contracts/_index.md` 记 `session_revoked` **七值**，实际 `auth.md` §10 已**八值**（08-23 新增 `SessionExpired`）。且 `auth.md` 自己明写「引用它的地方一律写指路、不写条数」——`_index.md` 正是违反该纪律的那一处。
2. **仍在** —— `contracts/envelope.md` 抬头仍写「瘦身不一次性做完**四份**」，契约面现为**六份**。
3. **仍在（且互撞未消 · 三次未处理）** —— **六份契约的 `## 决策(-> ADR)` 段仍写「→ ADR 候选①/②/③/④，登记于 `decisions/_index.md`」**，而「ADR 候选」整节已于 08-19 删除、对应 ADR 均已 Accepted ⇒ 指向一个不存在的登记处；且 `auth.md` 与 `content-manifest.md` **本地编号互撞**（都称候选④）。
4. **仍在** —— **`ADR-0017` 的回链是单向的**：`contracts/` 全目录不含 `ADR-0017` 字符串，`profile-sync.md` 的 `## 决策(-> ADR)` 仍只列三条无编号候选；而 `decisions/_index.md` 已把它记为 Accepted 且影响文档指向 `profile-sync.md`。决策本体已完整落进 §3 与 §5a，**不是 derive 卡点**，是簿记漂移。
5. **半修 + 新生一处孤儿指路** —— ① **已修的半**：「flags 是否落客户端本地缓存」已登记进 `open-questions/04-content-delivery.md` 的「已推给别处」表（标为「已答（2026-08-30 · 客户端裁决）」+ 客户端权威回链 + 「本库对该缓存的义务为零」），`update-log.md` 亦有完整留痕。② **未修的半**：「blob 通道是否向二进制资产开放」**至今未在 `04-content-delivery.md` 出现任何一行**——它现在只活在 `content-manifest.md` 正文与 handoff / `cross-boundary.md`「对账基线」里。③ **由此新生一处孤儿路径**：`content-manifest.md` 的 blob 一节写「若日后开放，本库须核对三点……**展开见 `open-questions/04-content-delivery.md`**」，而该文件里**没有这三点的任何展开**——契约正文向一个不存在的落点指路。**建议处置**：或在 `04` 补一行「条件化核对项（不是待办）」承接三点，或把该指路改为自足陈述（三点已在同段列全，删指路即可闭合）。
6. **仍在（第三次记录）** —— `vision/scope.md` 的 In scope 四条仍未列付费验票域（见上）。
7. **新增（轻）** —— 客户端 `2026-08-30-exchange-barter-support.md` 的存档 schema bump 在本库**零留痕**。属既有机械义务（新 `schemaVersion` 进 `envelope.md` §7e 兼容矩阵，矩阵待 `06` 故当前无可落之处），**不改任何判定**，但 08-25 同类情形本库是记了 handoff 的 ⇒ 对账基线出现一次不一致的处置。建议由 `/summarize-open-questions backend` 在 `open-questions/cross-boundary.md`「对账基线」补一行留痕。
8. **新增（须带给对侧）** —— `profile-sync.md` 把 schema bump 清单的权威指回客户端 `sync-service.md`，而那张自称「只有一份」的清单**已漏三批**（详见上方跨边界核对）。两侧都以为对方在记。本库无需改动，但对侧 derive 前必须补齐。
9. **无失真** —— `decisions/_index.md` 17 行 ⇔ 17 份 ADR 逐条一致且全 Accepted；`handoffs/_index.md` 21 行 ⇔ 21 份 handoff、全部 `distilled`；`inbox/` 顶层为空且如实标注；`requirements/_index.md` 如实写「当前尚无 FR」并把就绪度权威指回本小节。

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
