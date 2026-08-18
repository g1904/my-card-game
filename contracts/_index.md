# Contracts — 客户端 ↔ 后端协议契约（索引）

> **本库的核心产出。** 客户端与后端唯一的耦合点是协议；它必须**单点定义**，两侧都从它派生。
> 客户端侧的门面设计在 `game-design-documents/systems/services/`——那里描述**客户端怎么用**，此处描述**报文长什么样**。

## 现状

**表达形式：OpenAPI 3.1 + JSON Schema 单点，明确否决共享 DTO 代码**——依据是根约定的分支线独立性，**不依赖技术栈选型**（见 `envelope.md` §1）。契约表达形式因此已从 `open-questions/06-platform-stack.md` 的下游摘出，两者可并行推进。

**边界层已成文：`envelope.md`** ——序列化与命名约定、`/v1/` 主版本、传输信封（HTTP 头）与负载信封（push body 段）、错误体与错误码台账、版本协商与强更闸门、Profile 的三段可见性。全部端点共有的那一层不再是悬项，`auth.md` / `profile-sync.md` 的前置已解除。

**剧本契约已撤销（2026-08-11）。** 剧本内容本地化为客户端内容层的一员，以普通内容文件走 `content-manifest.md` 的 manifest 通道下发——**没有剧本端点、没有剧本报文**。
Source: `handoffs/2026-08-11-plot-service-retired.md`。

**auth 域已成文：`auth.md`（2026-08-13 · 2026-08-16 补齐身份模型）** ——七端点（`challenge` / `signin` / `refresh` / `signout` / `bind` / `unbind` / `nickname`）、双 token（自包含 JWT 15 min + refresh rotation 带 60 秒宽限窗口）、渠道分形 `credential`（首版无密码、首版上线 `Phone` + `WeChat`）、强更闸门只在 `signin`、`session_revoked.detail` 加 `reasonKey`。**身份主体自建**（`accountId` 由本方发放）、**account ↔ identity 一对多**且绝不隐式合并、第三方渠道换 openid 的三条后端义务与两类错误映射、五个 auth 域错误码。
Source: `handoffs/2026-08-13-auth-endpoint-contract.md` · `handoffs/2026-08-16b-account-identity-model.md`。

**sync 域已成文：`profile-sync.md`（2026-08-14）** ——两端点封定（`GET pull` / `POST push`）、diff 的**顶层键浅合并**语义、CAS 三分支 + 幂等命中的应答、**后端可见字段子集的逐 JSON path 白名单**（含「路径本身是契约的一部分」这条承重纪律）、账号级掷骰改用**契约定义的纯函数 SplitMix64**、复算边界（**可复算 `roll`、不可复算阈值**；不一致仅记账不拒绝）、`revision` CAS 与 `pushId` 幂等窗口的服务端语义、`compliance.*` 不进同步通道。
Source: `handoffs/2026-08-14-profile-sync-contract.md`。

**purchase 域已成文：`purchase.md`（2026-08-16）** ——两端点（`POST verify` / `GET receipt/{receiptId}`）、验票由后端向平台校验、**写入只由 verify 承担**（渠道回调降为对账 / 补偿通道）、平台收据 id 作幂等键、序号与 `revision` 同事务自增、verify 不走 CAS 且应答不内联 profile、复算回链 §6 不新开随机源。它同时定下 `profile-sync.md` §2 §5 的**后端写入字段封闭表**——后端只读、除表内四项外，加行须两侧同批评审且须逐条通过「够格进表」的两条判据。
Source: `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md`。

**合规域已成文：`compliance.md`（2026-08-16 · 第六份）** ——六端点（实名提交 / 合规态查询 / 注销申请与撤销 / 导出申请与查询）、`complianceTicket` 解无 token 态的死锁、合规**拦截只在 `signin`**（`compliance.*` 四条码与各自 `reasonKey`）、防沉迷时段中途到点**复用 `auth.session_revoked`** 而不新增通道、时段口径落配置不进契约、数据导出取最简 JSON 形态。同批把 `auth.md` 三处 `reasonKey` 留白填满（形态 PascalCase · `session_revoked` 七值 · `nickname_rejected` 三值）、新增 `auth.md` §4a 会话裁决（`sid` claim · `(accountId, deviceId)` 唯一约束 · 活跃会话上限 1 · `signin` 的 60 秒幂等回放窗口），并把 `envelope.md` §4a 的无鉴权例外由**点名 auth** 改写为**一条判据**。
Source: `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`。

**`vectors/splitmix64.json` 已落笔（2026-08-14）** ——账号级随机源的 8 组测试向量已由独立参考实现预先算出并填入，**不等任一侧首次实现**；两侧各自实现后逐位对表，对不上以该文件为准（**不得单方面改表迁就实现**）。`profile-sync.md` §6a 是人类可读对照。它是 `contracts/` 下**第一个已落笔的机器可读产物**，早于 `openapi.yaml`——但它**不属 spec**（不是报文形态），三条机检断言不覆盖它。
Source: `handoffs/2026-08-14-splitmix64-test-vectors.md`。

**`openapi.yaml` 与 `schemas/*.json` 尚未落笔，落笔与核对规则如下（2026-08-14）**：触发点 = **任一侧**的首个端点进入实现（动手的那一侧发起落笔，spec 始终落本库），首落范围 = **全部共有层 + 该一个端点**；**形态自此收到 spec 单点**，markdown 字段表随 spec 覆盖面**逐步**删除规范性形态列。一致性靠**变更内原子** + 三条机检断言 + 人工清单保证，不设周期性对账。规则见下方「约定」段与 `envelope.md` §1。
Source: `handoffs/2026-08-14-openapi-spec-timing-and-consistency.md`。

## 契约文档

| 文档 | 覆盖 | 对位的客户端成分 | 状态 |
|---|---|---|---|
| `envelope.md` | 表达形式、序列化约定、`/v1/` 主版本、传输 / 负载信封（含 **`flagsVersion`**）、错误体与错误码台账、版本协商与强更闸门、Profile 三段可见性 | 全部 | **已成文** |
| `content-manifest.md` | manifest schema 与三版本号分工、blob 内容寻址、ES256 detached 签名与 `keyId` 轮换、`ContentEnabled` 的 flags 第三层、**剧本文本的承接** | `content-service` | **已成文** |
| `auth.md` | 七端点报文、**account ↔ identity 一对多的身份模型**、双 token 生命周期（签发 / 刷新 rotation / 吊销）、渠道分形 `credential` 与第三方渠道换 openid 的后端义务、auth 域的鉴权例外、强更闸门的唯一落地点 | `account-service` | **已成文** |
| `profile-sync.md` | 两端点报文，负载信封 `pushId` · `baseRevision` · `schemaVersion` · `reason`，**diff 的顶层键浅合并语义**，三分支 + 幂等命中的应答，**后端可见字段子集（逐 JSON path 白名单）+ 后端写入字段的封闭四行表与「够格进表」判据**，SplitMix64 随机源与掷骰复算协议，CAS / 幂等 / 限流的服务端语义 | `sync-service` | **已成文** |
| `purchase.md` | 两端点报文（验票 + 收据幂等读），**写入只由 verify 承担**、渠道回调只作对账，平台收据 id 作幂等键，序号与 `revision` 同事务自增，四条服务端保证 | `sync-service`（后端主动写入的对位）· 商业化侧购买流程 | **已成文** |
| `compliance.md` | 六端点（实名 / 合规态 / 注销申请与撤销 / 导出申请与查询）、`complianceTicket` 的无 token 态凭据机制、拦截只在 `signin` 与四条 `compliance.*` 的 `reasonKey`、防沉迷复用 `session_revoked`、时段口径落配置、导出的最简形态 | `account-service`（`ComplianceManager` 的对位） | **已成文**（报文字段表待落笔） |

**契约面六份，且不作「就此封顶」的断言。** 判断该不该再开一份的判据是分域：**一个域的承重纪律若与既有任一份相反，就必须独立成文。** 已按此判据行使过两次：

| 分出的域 | 与哪一份相反 | 相反在哪 |
|---|---|---|
| `purchase` | `profile-sync` | 权威写入 vs 只读 · 必须裁决 vs 不裁决 · 必须能拒绝 vs 不拒绝 |
| `compliance` | `auth` | **长时状态机 + 异步任务** vs 即时判定端点内完成 · **不可逆**（注销生效）vs 全部幂等可重放 |

把两套相反的纪律塞进一份契约，读者无法判断哪条管哪个端点。

## 约定

- **契约变更是跨库事件。** 任何改动报文语义的决定，两侧各写一份 handoff 并互相回链（见 `handoffs/_TEMPLATE.md` 的「客户端侧影响」段）。
- **报文字段名与客户端字段名可以不同**，但语义必须一一对应，且在契约文档中显式给出映射——不靠「同名即同义」的默契。
- **只保留最新契约。** 契约文档是活文档：改了就重写，历史归 git。已上线后的兼容性由**版本化字段**承担，不靠在文档里保留旧形态。
- **形态单点在 spec，语义单点在 markdown。** 某端点的形态进入 `openapi.yaml` 后，其 markdown 字段表即删除规范性形态列（类型 / 必填 / 枚举取值），只留字段名 + 语义 / 用途 / 承重纪律；示例报文保留但**不具规范性**。判据与本库拒绝「第二份真值」的两处先例同源（`envelope.md` §8 拒抄 Profile schema、`profile-sync.md` §7 拒复制平衡分档表），而契约是两侧唯一的耦合点，其漂移代价更高。
- **瘦身随 spec 覆盖面推进，过渡期风格不齐是预期状态。** spec 逐端点追加，markdown 逐端点瘦身；尚未进 spec 的端点，其字段表**保留为草案**。因此在全部端点落笔完成前，六份契约中「有的带类型列、有的不带」是正常的，**不是漏改**。判断某份字段表该不该瘦身，只看它对应的端点是否已在 `openapi.yaml` 的 `paths` 中。

### 契约变更的完成判据

Source: `handoffs/2026-08-14-openapi-spec-timing-and-consistency.md`。

**核对时机 = 变更内原子**：spec 与 markdown 在同一次契约变更内同批更新，只改了一边的变更**视为未完成**。不设周期性对账——周期性对账允许漂移窗口存在，而那个窗口正是两侧按不同真值编码的时期。**责任人 = 发起该次变更的那一侧**。这是 `operations/_index.md` 已立的「先改台账、再改服务端实现」往前挪一格。

一次契约变更**未完成**，除非以下全部为真：

1. markdown 的语义 / 理由 / 承重纪律已更新；
2. `openapi.yaml`（及涉及的 `schemas/*.json`）的形态已在**同一次变更内**更新；
3. 若涉及新增 / 变更 `code`：`envelope.md` §6 台账已登记 `class` · `OpError` · 客户端处置 · `detail` 形状 · `message` 必含项五列；
4. **三条机检断言**通过；
5. **人工清单四项**已过；
6. 另一侧的跨库 handoff 已写并互相回链。

**三条机检断言**（`06` 落定自动化承载前，以人工清单的前三项执行；断言本身与后端栈无关——校验的是 markdown 与 YAML / JSON）：

| # | 断言 | 提取方式 | 漂移后果 |
|---|---|---|---|
| ① | spec 自身合法（OpenAPI 3.1 + 全部 `$ref` 可解析） | 任一 OpenAPI 3.1 校验器 | 两侧工具链读不了契约 |
| ② | `envelope.md` §6 台账的每个 `code` ⇔ spec 中错误码枚举的每个取值，**双向且一一对应** | markdown 表格首列 vs spec 枚举 | 客户端映射表漏一条 → 该错误走「未知 `code` 按 `class` 降级」，**静默**走错处置分支 |
| ③ | markdown 中出现的每个 `METHOD 路径` ⇔ spec 的 `paths` 键，**双向**（含 CDN 域三端点） | 正则 vs `paths` | 端点集与契约不符 |

- ②的投入产出比最高：错误码台账是全库最容易漏项的表，而其漂移形态是**静默**的（客户端对未知 `code` 有兜底，漏登记不报错，只让某条错误一直走降级路径）。
- **②的基准是台账当前登记的条目。** 合规域端点自身的错误码尚未进台账（随 `compliance.md` 的报文本体落笔），不构成「spec 漏项」——断言校验两处**已有内容**的双向覆盖，不是对未定内容的完备性要求。
- **②不下探到 `reasonKey`。** 它是 `detail` 内的取值集合、其权威在 `auth.md` §10 与 `compliance.md` §5，而 spec 只表达 `detail` 是个对象。`reasonKey` 取值的正确性由**人工清单第 1 项**（`detail` 形状与 `message` 必含项）承担；契约的兜底纪律本就要求客户端容忍未知取值，故这里的漏项不是静默走错分支，而是回落一级文案。
- 工具不点名（工程选型，与「栈未定前不指定语言 / 框架 / 库」同向），只立能力要求：**能校验 OpenAPI 3.1 / JSON Schema 2020-12，且能在设计库侧运行**。

**人工清单四项**（机检覆盖不到的语义面）：

1. `detail` 的形状与 `message` 必含项（台账后两列）——语义约束，spec 只能表达 `detail` 是个对象；
2. 承重纪律段落是否随形态变更而失效（典型：`profile-sync.md` §5 的 JSON path 白名单、§6 的 `stream` 取值冻结）；
3. 是否需要 bump `schemaVersion` / URL 主版本 / spec 的 `info.version`（三者互不复用，见 `envelope.md` §1 §3）；
4. 另一侧的 handoff 是否已写（把「契约变更是跨库事件」变成可勾选项）。

### `schemas/*.json` 的拆分判据与落笔后的目录形态

**判据（两条并列，满足其一即独立成文件）：** ① 被**两个及以上端点**引用的类型；② 该类型是**独立可被签名 / 校验的产物**，两侧需脱离 spec 单独引用它（manifest 即此类：ES256 detached 签名覆盖其原始字节，客户端校验签名后按 schema 独立校验，这条链不经过 spec 的请求 / 应答路径）。两条都不满足的端点独有类型**内联在 `openapi.yaml`**——避免造出一堆只被引用一次、`$ref` 跳转成本高于收益的文件。请求头 / 应答头**不进 `schemas/`**：它们是 `components/parameters` 与 `components/headers`。

```
contracts/
  _index.md
  envelope.md            语义 · 承重纪律 · 错误码台账（含 detail 形状与 message 必含项）
  auth.md                语义 · 端点用途 · 示例报文
  profile-sync.md        语义 · CAS/幂等/复算协议 · 白名单 path 的理由 · 后端写入字段封闭表
  purchase.md            语义 · 验票与权威写入 · 收据幂等 · 服务端保证四条
  compliance.md          语义 · 端点集与 ticket 机制 · 拦截落地点 · reasonKey 取值 · 旋钮
  content-manifest.md    语义 · 三版本号分工 · 签名与 flags
  openapi.yaml           ← 形态单点：paths（API 域 + CDN 域两个 server）· parameters · headers · 内联 schema
  schemas/
    error.json                     错误体 + class 四值枚举 + code 全量枚举   （判据①，envelope §5 §6）
    profile-visible-subset.json    可见字段子集的逐 path 约束               （判据①，profile-sync §5）
    session.json                   双 token 对                              （判据①，auth §2 §8）
    manifest.json                  manifest schema（manifestSchema: 1）      （判据②，content-manifest）
  vectors/
    splitmix64.json      ← 测试向量数值的权威（非报文形态，故不在 schemas/ 下）★ 已落笔，8 组
```

**`profile-visible-subset.json` 是部分 schema，不是 Profile 的 schema**（落笔时最易出错处，形态先写死）：它只列白名单里的那几条 path，**`additionalProperties: true`**，且**透明字段一律非必填**。它约束的是「若这些 path 存在，则形态必须如此」，而**不**声明 Profile 由哪些字段构成——由此同时兑现 `envelope.md` §8（不抄 Profile 字段表、不得对不透明段做结构校验）与 `profile-sync.md` §5（透明字段的 JSON path 是契约的一部分）。三条纪律：

- `additionalProperties: true` —— 不透明段照常通过；
- **透明字段全部非必填** —— push 上行是顶层键粒度的浅合并 diff（§3a），一次 diff 里绝大多数透明 path 本就不出现，标成必填会把正常 diff 判成 `sync.payload_invalid`；
- **缺失的透明 path 走告警级台账，不走 schema 校验失败** —— §5 已定「不拒绝上行」，故这条检测**不能**由 spec 承担，必须留在服务端逻辑里。**spec 中须为此写一条注释**，否则实现者极易顺手把它标成必填。
