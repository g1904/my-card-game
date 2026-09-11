---
type: solution-draft
date: 2026-09-09
question: flags 端点（`GET /v1/content/flags`）零装载且回源失败时的错误应答，是否值得一条专属 `code`（而非沿用兜底的 `server.unavailable`）？
source: open-questions/01-contracts.md → 唯一待答条目
targets: contracts/envelope.md（§6 台账的承重项）· contracts/content-manifest.md（B 组 flags 通道）· systems/content-delivery.md（「回源失败的降级」末行）· open-questions/01-contracts.md（销号）
status: distilled
reviewed: 2026-09-09 —— 批量评审：0 项待裁决，结论（不新增专属码、维持 `server.unavailable`）原样采纳；同批确认「derive 时按兜底码落笔并标注可能后续替换」的后半句随销号删去。
distilled-to: handoffs/2026-09-09-flags-zero-load-no-dedicated-code.md
---

# 方案草稿 —— flags 零装载失败是否值得一条专属 `code`

## 问题

`systems/content-delivery.md`「回源失败的降级」把 single-flight 回源失败分成三支：

1. **本实例已装载过更旧的版本** → 用旧版本兑现，应答体与头都是那个更旧的版本号，**不返回错误**；
2. **本实例一个版本都没装载**（冷启动首个请求且回源失败）→ **返回 `Retryable` 类错误，绝不以空 `disabledIds` 兑现**——空集合语义上是「什么都没关」，会让秒关静默失效，且客户端会把它当作一批合法 flags 持久化为降级值；
3. 失败**不写负缓存**。

第 2 支的错误应答**当前走 `envelope.md` §5a / §6 的兜底码 `server.unavailable`**（`class: Retryable`）。该文件末行明写「本文件不新增 `code`，是否值得一条专属码归 `contracts/envelope.md` §6 台账裁决」，这条悬项因此挂在 `open-questions/01-contracts.md`，是该分片仅剩的一条待答。

它**不阻塞任何落笔**——两种结论下端点的行为、`class`、客户端处置都不变，差别只在台账多不多一行。悬着的成本是：`/v1/content/flags` 的 FR 一旦开始 derive，验收标准里要写一个具体的 `code`，而「以后可能换」的注记会让那条验收标准悬空。

## 约束（来自既有设计）

- **`code` 是稳定字符串，永不复用、永不改写含义；它是客户端映射表的键。`class` 随 `code` 恒定，不因请求而变。** → `contracts/envelope.md` §5 · §5b。
- **新增 / 变更 `code` 有一套硬性的完成判据**：台账须登记五列（`class` · `OpError` · 客户端处置 · `detail` 形状 · `message` 必含），且须通过机检断言②——**台账首列的 `code` 集合 ⇔ 六份契约正文中出现的 `code` 字面量集合，双向**。→ `contracts/_index.md`「契约变更的完成判据」第 3 条 · 断言② · P-1 护栏。
- **客户端对未知 `code` 按 `class` 降级处置**，这是既定兜底而非缺陷路径。→ `envelope.md` §5b。
- **客户端 `code → ERR_*` 翻译键是机械变换，不是手写对照表**（`ERR_` + 全大写 + `.`→`_`）；`ERR_` 分区禁止人手写键。→ `game-design-documents/ux/error-and-blocking-ux.md`。
- **flags 拉取失败绝不阻塞、不落屏**：`RefreshFlagsAsync` 失败 → `PushWarning` + 降级到 `user://cache/flags.json`（无缓存则用 overlay 的 `ContentEnabled` 值），指数退避重试、**无放弃阈值**。→ `game-design-documents/systems/services/content-service.md`「API 面」与「flags：`ContentEnabled` 的第三层」。
- **服务端保证 F7**：回源失败且本实例零装载 → 返回 `Retryable` 类错误，**应答体不含 `disabledIds`**。→ `systems/content-delivery.md`「服务端保证」。
- **flags 只覆盖 `ContentEnabled` 一个布尔，B 组零报文成本**（不新增字段、不提升 `flagsSchema`、客户端无需改动）。→ `contracts/content-manifest.md` · `ADR-0002` · `ADR-0009`。
- **flags 子系统的既定取向是「契约面零改动、客户端零义务」**，两次演进均已如此声明。→ `ADR-0047`（头永不领先）· `ADR-0060`（装载须有请求无关触发）。
- **不得造出「永不下发的 `code`」**：台账每条须产得出 `class` · `OpError` · `detail` 形状 · `message` 必含四样；台账有而契约正文无，会让机检断言②′ 的一侧永久失衡。→ `ADR-0052`。
- **指标按 `code` 打点，但「共用 `code` + 指标层分辨」是被接受的解法**（CAS 冲突率与回声校验拒绝率共用 `sync.conflict` 却必须分开计数）。→ `operations/observability.md`。

## 建议方案

### 一、先把判据显式化：什么样的失败面才值得一条专属 `code`

`[既有推演]`

`envelope.md` §6 台账现有 30 行，其「承重项」小节已经把每一次拆 / 并的理由写在了纸面上。从中可以归纳出**三条实际在用的判据**（满足其一即值得独立成码，一条都不满足即不值得）：

| # | 判据 | 正例（据此新增 / 拆分） | 反例（据此复用 / 合并） |
|---|---|---|---|
| **J1** | **客户端处置不同**——两个失败面在客户端触发的动作不同（哪怕 `class` 相同）。**这是第一判据** | `auth.token_expired`（静默刷新、绝不打断轮回）vs `auth.session_revoked`（硬阻塞重登 + 暂停退避）；`auth.credential_invalid` vs `auth.challenge_expired`；`purchase.channel_disabled`（不进待兑现态、无客服入口）vs `purchase.receipt_invalid`（解除待兑现 + 客服入口） | **`purchase.channel_unavailable` 被明确否决**：「新造一个 `purchase.channel_unavailable` 只会让客户端的两条路径走同一条处置，却多一行映射表」（`purchase.md` §3）；外接服务商不可达同样复用 `server.unavailable`——「逐字覆盖，且客户端已有 `Retryable` 处置」（`operations/external-providers.md`） |
| **J2** | **玩家可见的措辞分叉不构成理由**——动作相同只是话不同，一律同码 + `detail.reasonKey` | — | `restricted` 与 `banned` **共用 `compliance.account_restricted`**：「玩家处置相同、只有措辞不同，拆两个 `code` 会让处置表多一行却走同一条路径」 |
| **J3** | **`class` 不同，或混入会污染某一档的静态推理** | 合规域「核验服务不可达」归 `server.unavailable` 而非新开 `compliance.*`——「混一条可重试进本域会破坏客户端「`Compliance` 档 = 不可重试」的静态推理」 | — |
| **J4** | **`detail` 须携带客户端必须消费的字段**，而候选的复用码没有那一格 | 外接服务商额度耗尽归 `rate.limited` 而非 `server.unavailable`：「客户端处置需要 `Retry-After`，而 `server.unavailable` 没有这个字段」 | — |
| **J5** | **线上两条曲线的运维处置不同（一个叫人、一个不叫人），且区分所需的事实由对端持有、指标层自己分不出来** | `purchase.receipt_pending` 与 `server.unavailable` 分列：「一个是我方查不到平台，一个是平台明说钱没到位……这两条曲线一个叫人、一个不叫人」 | **本判据有明确上限**：`operations/observability.md` 已立「CAS 冲突率与回声校验拒绝率必须分开计数」——两者**共用同一个 `code` 而在指标层分辨**，是被接受的既有解法。故只有指标层**也**分不出来时 J5 才成立。另：refresh 的滥用面「**只告警、不返回限流码**」（`deployment.md` G-1） |
| **J6** | **台账四要素必须都产得出**（`class` · `OpError` / 客户端处置 · `detail` 形状 · `message` 必含）；产不出即不得入台账 | — | **`ADR-0052`**：CDN 域 4xx **不新增任何台账条目**——「CDN 域结构上产不出这四样；新增条目会造出**永不下发的 `code`**，并让 P-1 的双向机检断言在「台账有、正文无」这一侧永久失衡」 |
| **J7** | **端点错误清单的封闭性本身是资产**，新增码要付「给客户端加一条处置路径」的代价 | — | `POST /v1/auth/refresh` 的错误清单**刻意只有两条**，「客户端的两条处置路径靠「报文层面只有两种可能」才无歧义」；「若日后认定 refresh 必须限流，须回改契约**并同时给客户端第三条处置路径**」 |

**J5 的两个限定是本题的关键，也是台账里最容易被读漏的一条。** `receipt_pending` 必须独立成码，不是因为「运维想看两条曲线」，而是因为 ① **区分它的事实只有支付渠道知道**——服务端要把它告诉任何人都得先经报文接住；② 我方指标层**自己产不出**这个维度。而 `sync.conflict` 那一条（CAS 冲突 vs 回声拒绝共用一码、指标层分开计数）与 refresh 那一条（滥用面只记账告警、不返回限流码）合起来证明：**当区分所需的事实就在我方进程内时，本库的既定做法是打点，不是开码。**

### 二、把本题逐条套进七条判据

`[既有推演]`

**J1（客户端处置不同）—— 不成立。**

客户端侧 `RefreshFlagsAsync` 的失败语义只有一条：`PushWarning` + 降级到 `user://cache/flags.json`（无缓存则回落 overlay 布尔）+ 指数退避、**绝不阻塞**（`game-design-documents/systems/services/content-service.md`「API 面」）。这条路径对 `server.unavailable` 与任何假想的专属码**逐字相同**——两者同为 `Retryable`，而客户端在这个端点上唯一会分叉的失败是**验签失败**（`PushError` + 拒绝该批 + 保留上一批 + 按版本记忆），那是本地判定，不由 `code` 驱动。

更强的一句：**若客户端把这个新码加进 `code → (OpError, 处置)` 处置表，那一行的内容会与 `server.unavailable` 那行完全一致；若不加，它走「未知 `code` → 按 `class` 降级」，结果同样一致。** 一个在客户端**最优实现就是「当作未知码」**的 `code`，没有存在理由。

**J2（措辞分叉）—— 不成立，且玩家面是空集。**

flags 拉取失败**从不落屏**：它不在客户端已定的两处硬阻塞内，处置是 `PushWarning`（日志）+ 静默降级。玩家面为空 ⇒ 无文案可分叉 ⇒ `ERR_*` 键即便被机械变换生成出来也**永远不会被取用**。

反而有一处净负债：`ErrorText.AuditTranslations()` 的**正向审计**会「遍历处置表全部已知 `code`，缺翻译条目者一次性 `PushWarning` 列出」。故客户端一旦把这个码登进处置表，就被迫在 `res://text/errors.csv` 里加一条**永不显示的文案**去消音——一条纯负债的翻译行。

**J3（`class` 污染静态推理）—— 不成立。** 新码与 `server.unavailable` 同为 `Retryable`，档位推理无差别。

**J4（`detail` 须携带必须消费的字段）—— 不成立。** 客户端在这条路径上不消费任何 `detail`：降级值取自本地缓存、重试节奏由本地退避阶梯决定（且已定「实际间隔 = max(本地退避计算值, 服务端给的等待时间)」，那个等待时间来自 `Retry-After` 头而非 `detail`）。`server.unavailable` 的 `detail` 形状是「—」，本情形不需要更多。

**J5（两条曲线 + 信息只能经报文传回）—— 前半成立，后两个限定均不成立，故整条不成立。**

「本实例零装载 + 回源失败」确实是一个值得单独看的运维事实：它意味着该实例对**到达它的每一个** flags 请求都在报错，而传播窗口 T 的实例间 gauge 极差探针**发现不了**它——该实例根本没有「可兑现的最大版本」这个数，极差与落后量两条 gauge 在它身上都无值。

但两个限定都不成立：

- **区分所需的事实完全在后端自己的进程内。**「本实例已装载的键集是否为空」是 `systems/content-delivery.md` 已经定义好的取数面（同一个数已经在供两条 gauge 用）。服务端要打一条计数器、接一条告警，**一步都不需要经过契约**。契约码是**给客户端读的键**；服务端自有的指标维度不必借道它。
- **指标层自己分得出来。** `operations/observability.md` 已经立了先例：CAS 冲突与回声校验拒绝**共用同一个 `code`，但指标层必须分开计数**。既然本库接受「同码 + 指标层分辨」，本题就更没有理由反过来「为了指标去开一个码」。

（`operations/content-delivery-ops.md` 的 flags 发布 / 回滚 O1–O7、传播窗口 T 的预算与两条探针，全文没有任何一个动作依赖「区分零装载失败与一般 `server.unavailable`」——两条 flags 探针都以版本号 gauge 取数，与错误码无关。）

**J6（台账四要素产得出）—— 勉强成立，但这是入场券不是理由。** 本情形确实产得出四要素（不像 `ADR-0052` 的 CDN 域那样结构上产不出），故它**不被 J6 挡在门外**；但 J6 从来只是必要条件。

**J7（端点错误清单的封闭性）—— 反向成立，即支持不新增。** `/v1/content/flags` 目前的错误面极窄（鉴权类 + `rate.limited` + `server.unavailable`），客户端在这个端点上只有一条失败处置。保持这个封闭性与 refresh「报文层面只有两种可能」是同一种资产。

**七条判据里，唯一可能支持新增的 J5 被自身的两个限定否掉，J1/J2/J3/J4 全否，J7 反向支持不增 ⇒ 建议不新增专属 `code`，维持兜底的 `server.unavailable`（`Retryable`）。**

**同向的第三方旁证：这整条 flags 子系统的既定设计取向就是「契约面零改动」。** `ADR-0047`（头永不领先）自陈「契约层零报文改动、零 schema 提升、客户端零义务」；`ADR-0060`（装载须有请求无关触发）自陈「契约面零改动……客户端承接义务：零」，且它对「全体一致地落后」这个失败面的可见性正是**用 gauge 断言而非错误码**承担的。为零装载新开一个码，会是这条设计线上第一处例外，而它拿不出前两处拿得出的那种理由。

### 三、承重推论：「绝不把空 `disabledIds` 持久化为降级值」不靠 `code` 成立

`[既有推演]` —— **这是本题最强的一条，因为它证明专属码解决不了它宣称要解决的问题。**

悬项的原始动机是「空集合会被客户端当作一批合法 flags 持久化下来」。核实客户端与契约两侧后，这条风险由**两条结构事实**堵死，**与 `code` 取什么值完全无关**：

1. **错误应答的 body 是 `{ "error": { code, class, message, detail?, requestId } }` 这一个形状**（`envelope.md` §5），根本不含 flags 报文的五字段（`flagsSchema` / `flagsVersion` / `contentVersion` / `disabledIds` / `enabledIds`）。服务端保证 **F7** 把这一点写成了可验收的断言：「返回 `Retryable` 类错误，**应答体不含 `disabledIds`**」。客户端因此**解析不出一批 flags**，`RefreshFlagsAsync` 返回失败——不存在「拿到一个空集合」这个中间态。
2. **客户端缓存的写入时点唯一 = 一批 flags 通过单调闸并被应用之后**，原子覆写；「等值 / 更小而被丢弃、验签失败被拒、拉取失败（网络 / 限流）**一律不写**」（`content-service.md`）。故即便退一万步拿到了空集合，也不存在把它写成降级值的路径。

换言之：这条纪律是**结构性成立**的（错误应答没有 body ⇒ 没有集合可持久化），不是靠客户端「认出某个特定 `code` 然后特殊处理」成立的。一条专属码在这里不增加任何保障，只增加一行台账、一处正文回链和一次跨库同步义务。

### 四、留痕形态：把「刻意不给」写下来，而不是留空

`[通行做法]` + `[既有推演]`

「不新增」不等于「什么都不写」。本库对刻意不给某个码的既定做法是**留痕**（refresh 刻意不给 `rate.limited`，其理由落在 `operations/deployment.md` 的两条网关纪律与逐次上线核对项里）。建议同构处理，落笔面三处（**由 `/analyze-new-ideas` 执行，本草稿不写**）：

| 落点 | 写什么 |
|---|---|
| `contracts/envelope.md` §6「台账的承重项」 | 追加一条：**flags 零装载失败刻意不给专属码**，沿用 `server.unavailable`；判据 = 客户端处置逐字相同 + 玩家面为空 + 区分所需的事实在服务端进程内（打点即可，不必借道 `code`）。**台账表本身不加行**（P-1 护栏：首列是机器读取面） |
| `systems/content-delivery.md`「回源失败的降级」末行 | 把「是否值得一条专属码归 `envelope.md` §6 台账裁决」改写为**已裁定**：用 `server.unavailable`（`Retryable`），并回链 §6 的那条承重项 |
| `contracts/content-manifest.md` B 组 / flags 节 | 一句：flags 端点不引入任何 flags 域专属错误码，错误一律走 `envelope.md` 的共有码。**这句同时保住机检断言②**——它扫的是六份契约正文的 `code` 字面量，而 `content-delivery.md` 是 `systems/` 文档、不在扫描面内 |

### 五、配套：服务端侧的零装载指标（不进契约）

`[通行做法]`

既然把「需要看见零装载失败」这件事从契约挪到了服务端自有指标，就必须真的把它落下来，否则等于把风险抹掉而不是转移。建议（**落点归 `operations/observability.md`，本草稿不写**）：

- 一条**零装载失败计数器**，维度含实例标识；触发条件与服务端保证 **F7** 的输入逐字对齐（回源失败 ∧ 本实例已装载键集为空）。
- 它与既有的「flags 版本预热落后量 gauge」及「全体一致地落后」告警断言互补：那两条看的是**装载落后多少**，这一条看的是**一个都没装载**——后者是前者的取数面为空的情形，两条曲线合并会让「gauge 无值」被读成「零落后」。
- 阈值：任何非零持续超过一个「当前版本读取缓存 TTL + 装载耗时」即告警（该窗口已由服务端保证 **F5** 定义），**不另立新窗口**。

## 具体形态（可 derive 的落地面）

**`GET /v1/content/flags` 的错误应答（零装载 + 回源失败）：**

| 项 | 取值 |
|---|---|
| `code` | `server.unavailable`（**沿用兜底，不新增**） |
| `class` | `Retryable` |
| `OpError`（客户端） | `Network` |
| 客户端处置 | 既定断线降级 —— `RefreshFlagsAsync` 返回失败 → `PushWarning` + 降级到 `user://cache/flags.json`（无缓存则回落 overlay `ContentEnabled`）+ 指数退避重试，**绝不阻塞** |
| `detail` | 无（台账既有形状即为「—」） |
| `message` 必含 | **下游组件与失败阶段**（台账既有要求）。本情形下即：回源目标 + 「零装载」这一阶段标识 |
| 应答体 | **不含 `disabledIds`**，亦不含 flags 报文任何字段（服务端保证 F7） |
| 负缓存 | 不写（`systems/content-delivery.md` 第三支） |

**台账改动：零行。** `envelope.md` §6 的表格不增不减，只在其下方「承重项」列表追加一条说明（见上方第四节）。

**对 derive 的影响（注意：这是对现有记载的一处修改，不是复述）：** `open-questions.md` 现在写的是「derive `/v1/content/flags` 时按兜底码落笔**并标注该条可能后续替换**」。本方案若被采纳，**那半句注记应随本条销号一并删去**——FR 的验收标准直接按 `server.unavailable`（`Retryable`）写，**不加「可能后续替换」**。

理由：那句注记是**悬项状态**的产物，不是结论的一部分。本条一旦裁定，留一条「可能会变」的注记会让验收标准无法机械核对（核对者不知道该按哪个码判），也会让下一个读者以为这条仍未答定。日后若判据真的变化（例如客户端为 flags 失败引入了不同于断线降级的处置，J1 就成立了），那是一次正常的契约变更，走完成判据六条即可——**契约本来就允许被改，靠的是变更流程，不是预先埋一句免责**。

**对 spec 的影响：无。** 不新增 `code` ⇒ `schemas/error.json` 的 `code` 全量枚举不变，机检断言②的两侧集合都不动。

## 后果

- **`open-questions/01-contracts.md` 就此销号**——它是该分片仅剩的一条待答，移出后 ① 协议契约分片**再无待答项**（移出与归档记入 `answer-logs/` 由 `/analyze-new-ideas` 执行）。
- **契约面零改动**：不新增 `code`、不改错误体、不改 `flagsSchema`、不改端点集。B 组「零报文成本」保持成立。
- **客户端零改动、零跨库义务**：不新增 `ERR_*` 键（机械变换的像不会被生成，因为没有新 `code`）、不新增落屏义务、不改处置表、不改 `errors.csv`。→ **本题最终判定为不横跨边界，无需对侧 counterpart 草稿或承接项。**
- 三处主题文档的留痕改动（见第四节）与一条 `operations/observability.md` 的指标条目（第五节）是本方案被采纳后的全部落笔面。
- **三处需同批处理，否则会留下自相矛盾的文本**：① `systems/content-delivery.md`「回源失败的降级」末行仍写着「归 §6 台账裁决」；② `open-questions/01-contracts.md` 仍列着这条待答；③ `open-questions.md` 索引侧仍写着「derive 时按兜底码落笔**并标注该条可能后续替换**」——只销号而不改 ① ③，会让下一个读者以为它还没裁决，并把那句免责注记原样带进 FR。
- **`operations/observability.md` 的两条 flags gauge 在零装载实例上都无值**（极差与落后量都要用「本实例可兑现的最大版本」，而零装载时该数不存在）。这不是本方案引入的缺口，但本方案把它显式化了——故第五节的计数器建议不是可选装饰，它补的正是这两条 gauge 结构性看不见的那一块。

## 备选方案（已考虑并否决）

- **新增 `content.flags_unavailable`（`Retryable`）** —— 命名体例上成立（`<域>.<原因>`），但七条判据无一支持：客户端处置与 `server.unavailable` 逐字相同、玩家面为空、`class` 相同、无 `detail` 需求、区分所需事实在服务端进程内且指标层分得出。它会是 `purchase.channel_unavailable`（已被否决：「只会让客户端的两条路径走同一条处置，却多一行映射表」）的第二个实例。代价却是实打实的：台账加行 + `content-manifest.md` 正文须同批出现该字面量（否则机检断言②′ 在「台账有、正文无」这一侧失衡——这正是 `ADR-0052` 拒绝为 CDN 域 4xx 加台账行的理由）+ `openapi.yaml` 落笔时枚举同批加 + 一次跨库 handoff + 客户端一条「加进处置表就得配一条永不显示的翻译」的净负债。
- **新增 `content.flags_cold_start`** —— 同上，且更糟：把**实现细节**（本实例是否冷启动）编码进一个永不复用、永不改写含义的稳定字符串。契约码描述的应是**对端需要知道的语义**，而「哪台实例刚起来」对客户端毫无意义。
- **用 `detail` 区分而不新增 `code`**（`server.unavailable` + `detail: { stage: "flags_zero_load" }`）—— 表面上省了一行台账，实则更差：`detail` 的形状按 `code` 在台账里**写死**，给 `server.unavailable`（一条全域兜底码）加一个只在某一个端点出现的可选字段，会让这行台账的 `detail` 形状对其余全部端点都失真；且客户端「不解析 `message`、只按 `code` 分支」的纪律下，这个字段没有任何消费者。
- **零装载时以空 `disabledIds` 兑现 200** —— 已被 `systems/content-delivery.md` 与服务端保证 F7 明确否决（秒关静默失效）。此处复列仅为标明本方案不触碰它。
- **零装载时回 `503` 但不给契约错误体**（交由 `envelope.md` §5b 的「应答体无法解析 ⇒ 按状态码降级为 `server.unavailable`」兜底）—— 结果码相同，但放弃了 `message` / `requestId`，等于自愿丢掉跨进程排障的那个标识符。应当正经产出契约错误体，只是 `code` 取兜底值。

## 与既有决策的张力

**无。** 本方案不要求任何 ADR 或既定纪律松动：`ADR-0002`（flags 载荷硬边界）、`ADR-0009`（B 组零报文成本）、`ADR-0047`（头永不领先于本实例可兑现的规则集）、`envelope.md` §5b 三条承重纪律、`_index.md` 的完成判据六条，全部原样成立且被本结论进一步坐实。

唯一需要注意的是**文本一致性而非设计张力**：`systems/content-delivery.md`「回源失败的降级」末行与 `open-questions/01-contracts.md` 的条目都写着「待裁决」，采纳后须同批改写（见「后果」末条）。

## 前置依赖

**无。** 本条不依赖任何仍待答的问题：`envelope.md` §6 台账已成文、服务端保证 F1–F8 已成文、客户端 `RefreshFlagsAsync` 的失败语义已定案、`ERR_*` 机械变换规则已定案。`openapi.yaml` 尚未落笔不构成依赖——本结论**不改变 `code` 全量枚举**，故对 spec 首落的范围无影响。

## 仍需用户决定

**无（0 项）。**

七条判据均由 `envelope.md` §6 台账既有条目的裁决理由、`ADR-0052`、`purchase.md` §3、`operations/external-providers.md` 与 `deployment.md` G-1 归纳而来，本题逐条套用后结论一致且无反例；「绝不持久化空 `disabledIds`」这条承重推论经直读客户端 `content-service.md` 核实为**结构性成立、与 `code` 无关**。故本题整体可推演，不构成取向选择。

用户仍可否决本结论（例如出于「宁可多一条码换取指标可读性」的偏好）——若否决，需要一并裁定的是：新码字面量（建议体例 `content.flags_unavailable`）、`content-manifest.md` 正文的同批落笔位置（保断言②），以及客户端是否登进处置表（登则须配一条永不显示的 `errors.csv` 文案）。
