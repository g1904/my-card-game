---
type: solution-draft
date: 2026-09-07
question: `contracts/auth.md` §4 求值顺序第四分支（`now ≥ refreshExpiresAtUtc`，滑动截止到期）应返回哪个 `auth.session_revoked.detail.reasonKey`？
source: open-questions.md →「derive 就绪度」表 `contracts/auth.md` 行「卡点一（窄，须先消歧）」；对应正文 `contracts/auth.md` §4 · §10
targets: contracts/auth.md（§4 求值顺序第四分支 · §8 `POST /v1/auth/refresh` 错误段 · §10 `auth.session_revoked.detail.reasonKey` 表与其下说明段）· systems/account.md（「refresh token 的形态：可重算的派生串」校验流程伪码两处叶子）
status: distilled
reviewed: 2026-09-07 批量评审 —— 取向 1 裁为选项 A（共用 `SessionExpired`）；子项 ②③④ 与「具体形态」各节按推荐直接落笔，未提异议。
distilled-to: handoffs/2026-09-07-refresh-expiry-reasonkey.md
---

# 方案草稿 — refresh 滑动截止到期的 `reasonKey` 消歧

## 问题

`contracts/auth.md` §4 的 refresh 求值顺序，第四分支原文：

```
├─ now ≥ refreshExpiresAtUtc（滑动截止）→ auth.session_revoked（reasonKey 沿用既有口径）
```

而 §10 `auth.session_revoked.detail.reasonKey` 的八个取值里**没有一个对应它**：`SessionExpired` 明写是「refresh token 链达到**绝对**寿命上限」（§5b），其余七值各有确定且互斥的触发源（另一设备登录 · 同设备替换 · 主动登出 · 运营吊销 · 未成年时段到点 · 绑定变更 · 泄漏重放）。

**因此「玩家闲置超过滑动 TTL（30 天）后回来，refresh 返回哪个 `reasonKey`」在契约层无答案，只能靠推断。** 这条分支是可达的、且是常态路径：客户端把静默续期落在启动链第二步，闲置玩家回来时**必然先撞一次 refresh 再落登录屏**（`game-design-documents/systems/services/account-service.md`「启动期的 refresh 失败不走会话期内的那两条分流」）。

缺口的来历有据可查：`answer-logs/log-refresh-lifetime-cap.md`（08-23）在引入第八值时，把闲置玩家整体判给了 `signin` 路径（「滑动续期承诺收窄为『不因**闲置**而被动重登』」），滑动到期分支因此从未被赋值——但那句话说的是「不会被**中途**踢下线」，不等于「这条分支不会被求值」。

**卡点的量级**：`open-questions.md` 09-07 就绪度评估把它记为全库投入产出比最高的一处——「**一行消歧即可让 `auth.md` 转 ready**」，并连带解锁 `systems/account.md`（同为 partial）。

**同一缺口的第二处实例**（本草稿一并处理，见子项 ②）：`systems/account.md` 的 refresh 校验流程伪码里，「按 `tokenId` 查 session 行（**查不到** → `auth.session_revoked`）」这条叶子同样没有 `reasonKey`。它与滑动到期同属 §8 所列的第一类失败（「refresh token 已失效」）——那一类在契约面上整体没有取值。只补滑动到期而不补它，`/derive-requirements` 仍写不实该端点的失败面断言。

## 约束（来自既有设计）

- **`reasonKey` 的判据是「玩家措辞是否需要分辨」，不是机制的自述。** `auth.md` §10 原文：`SessionExpired`「面向的是**玩家措辞的分辨**而非机制的自述」；§10 引入 `SignedInElsewhere` / `SessionSuperseded` 分列的理由也是措辞（「玩家会在自己刚绑定一个渠道之后看到『你的账号已在另一台设备登录』」）。
- **客户端对 `auth.session_revoked` 只有一条行为分支。** `reasonKey` 不参与任何行为分叉——`game-design-documents/ux/error-and-blocking-ux.md`：「**一级文案仍按 `code` 取**，`reasonKey` 只驱动二级措辞」；`account-service.md`：「`auth.session_revoked` 有两个到达路径…**处置相同**」。
- **`SessionExpired` 的客户端措辞已定，且刻意不附原因句。** `error-and-blocking-ux.md` 原文：「只说要做什么（『登录状态已过期，请重新登录』），**不解释为什么**」——理由是附原因句会把后端可调旋钮写进翻译条目，改值即静默失准。
- **`refresh` 的错误码只有两条，且不得增第三条。** `auth.md` §8 / §10 / `operations/deployment.md` G-1：客户端「刷新失败按有无明确应答分两条路径」的判据靠报文层面只有两种可能才无歧义。⇒ 消歧只能发生在 `reasonKey` 层，不能新增 `code`。
- **取值表可持续扩张，且新增取值不要求客户端同批发版。** §10：「未知 `reasonKey` → 退回一级键」；客户端侧对位 `handoffs/2026-08-23-refresh-lifetime-cap-client-half.md` §1：「新 `reasonKey` 的落地 = 一条翻译条目，零代码改动…**两侧发版顺序任意**」。
- **`revokedReason` 即下行的 `reasonKey`**（§4a 会话表字段说明）——服务端的记账列与线上取值是同一个东西，没有第二套内部原因码。
- **`detail` 形状受 `envelope.md` §6 台账约束**（`{ revokedAtUtc, reasonKey }`），且 §2「绝不下发 `null`」。台账首列的 P-1 护栏只管 `code`，**不下探 `reasonKey` 取值**（`contracts/_index.md`：机检断言②「不下探到 `reasonKey`」）。
- **§5b 的闸门收口论证只依赖「绝对截止存在且 rotation 永不顺延」这一条**，与它对应哪个 `reasonKey` 无关。

## 建议方案

### ① 主项：把 `SessionExpired` 定为本 `code` 下「凭据不再有效」这一类的唯一取值（含滑动截止）

`[取向选择]`（**推荐**；另一取向见 `## 仍需用户决定`）

不新增取值，改写 §10 表中 `SessionExpired` 一行的**触发**列，使它覆盖「refresh 凭据不再有效、且不属于本表其余任一取值」的全部情形；§4 第四分支据此写实。

**推荐理由（逐条落在既有设计上）：**

1. **按 §10 自己的判据，两者不该分列。** 判据是玩家措辞的分辨。闲置到期与绝对上限到期对玩家是**同一句话**：都是完全正常的例行事件、玩家没做错任何事、没有第二台设备在动他的账号。`error-and-blocking-ux.md` 为 `SessionExpired` 定的那句「登录状态已过期，请重新登录」**逐字适用于闲置到期**（对闲置玩家甚至更贴切）。
2. **分列会当场制造一份必然漂移的文案副本。** 新增一个取值 ⇒ 客户端 `errors.csv` 多一条二级行，而它的中文与 `ERR_AUTH_SESSION_REVOKED_SESSION_EXPIRED` **一字不差**。日后措辞调整时两条必然不同步，且没有任何机制会报错（客户端侧的正向审计**只查一级键**——「客户端不持有 `reasonKey` 清单，二级键无从正向枚举」）。这正是本库反复否决的「第二权威」形态。
3. **它同时把「不附原因句」这条已定纪律保住。** 若要让两个取值真的有分辨价值，二级文案就得说出「因为你太久没登录 / 因为这条链够老了」——而那恰恰是 `error-and-blocking-ux.md` 明确否决的写法（把后端旋钮写进翻译条目）。
4. **零客户端义务、零发版耦合。** 触发列改写不产生任何新键，客户端一字不改。
5. **`SessionExpired` 这个名字本来就装得下两者**——它取的是事件完成态（「会话到期」），不是「绝对寿命上限达成」。
6. **服务端的可观测性不因此丢失。** 会话行同时持有 `refresh_expires_at_utc` 与 `absolute_expires_at_utc`（`systems/account.md` 承重列），哪一个先到期在行内可判；且本库当前**没有任何登记在 `operations/observability.md` 的指标以 `revokedReason` 为标签**（已核对，`operations/` 全目录零命中）。日后若确有分辨需求，可在**不跨边界**的内部字段上加（与 `sid` / `channelUserId` / `idKind` 同一条纪律），不必占用契约面的取值。

### ② 连带项：`tokenId` 无从识别的那条叶子并入同一取值

`[通行做法]` + `[既有推演]`

`systems/account.md` 的「按 `tokenId` 查 session 行（查不到 → `auth.session_revoked`）」同样无取值。建议**并入 `SessionExpired`**：

- **通行做法：鉴权失败不向未知来源自述细节。** 回一个可分辨的「这个 `tokenId` 我不认识」是无谓的信息泄露面，而对**正当玩家**（会话记录已被清理、或换机后残留的旧凭据）来说，它与到期是同一件事、同一句话。
- **既有推演：§10 已否决过「让常态情形长期占用兜底路」。** 原文（`SessionSuperseded` 不能省）：「不给它取值，等于让它长期占用『未知 → 兜底文案』那条路，而那条兜底是为**日后新增**取值准备的」。同一条适用于此。
- **另一条叶子（「均不命中」）不是缺口，只是伪码没标注**：`systems/account.md` 紧随其后的正文已给出答案——「查不到任何一代、或代次更旧 ⇒ 判 `TokenReuseDetected`」。伪码叶子补一个标注即可，语义不动。

### ③ `revokedAtUtc` 在无会话记录时取本次判定时刻

`[既有推演]`

子项 ② 的情形下没有会话行可读，而 `detail` 形状是 `{ revokedAtUtc, reasonKey }`、且 `envelope.md` §2 明令「绝不下发 `null`」。

**建议：`revokedAtUtc` 取本次判定时刻**（服务端时钟；`operations/compliance-ops.md` 的可信时钟基准）。语义成立——「这枚凭据被判定失效的时刻」——且 `detail` 形状恒定，**`envelope.md` §6 台账一字不动**。

（备选「把 `revokedAtUtc` 改为可选」要动台账里的 `detail` 形状，见 `## 备选方案`。）

### ④ §8 的 refresh 错误段改为不写条数

`[既有推演]`

§8 现写「四者靠 `reasonKey` 分辨」。§10 已定纪律：「引用它的地方一律**写指路、不写条数**。一个写死的数目就是一份会漂移的副本」。本次改写正好使「四者」失准（情形数变了），建议顺手改为「各情形靠 `reasonKey` 分辨，取值见 §10」，把这处计数副本一并消掉。

> 同类计数副本在 `contracts/_index.md` 里还有一处（`session_revoked` **八值**），已由 09-07 就绪度评估记为漂移条；**不在本草稿范围内**，由台账维护环节处理。

## 具体形态（可 derive 的落地面）

### A. `contracts/auth.md` §10 表行（照既有列结构，整行替换）

| 取值 | 触发 | 依据 |
|---|---|---|
| `SessionExpired` | refresh 凭据不再有效，且不属于本表其余任一取值——三种情形共用本取值：① 滑动截止 `refreshExpiresAtUtc` 到期（闲置超过滑动 TTL）；② 绝对截止 `absoluteExpiresAtUtc` 到期（链达到绝对寿命上限）；③ `tokenId` 无从识别（伪造，或会话记录已被清理） | §4 · §5b |

### B. §10 表下说明段（在既有「`SessionExpired` 与其余取值在情绪上必须可区分」一段后追加）

> **三种情形共用一个取值是刻意的，判据是本节自己的那一条：`reasonKey` 分辨的是玩家措辞，不是机制。** 三者对玩家是同一句话——完全正常的例行事件，玩家没做错任何事，也没有第二台设备在动他的账号。给它们各立一个取值，会在客户端产出两三条**逐字相同**的二级文案条目（客户端不持有 `reasonKey` 清单、正向审计只查一级键 ⇒ 措辞调整时不同步是一次静默失准）；要让它们真的有分辨价值，二级文案就得说出「因为你太久没登录 / 因为这条链够老了」，而那正是客户端侧已否决的写法（把后端可调旋钮写进翻译条目）。
> **服务端侧的分辨不依赖它**：会话行同时持有 `refresh_expires_at_utc` 与 `absolute_expires_at_utc`，哪一个先到期在行内可判。日后若确需在观测面分辨，加一个**不跨边界**的内部字段，不占契约面的取值（与 `sid` / `channelUserId` / `idKind` 同一条纪律）。

### C. §4 求值顺序（第四分支整行替换 + 块下追加一句）

```
  ├─ now ≥ refreshExpiresAtUtc（滑动截止）→ 吊销会话（revokedReason = SessionExpired）
  │                               → auth.session_revoked { revokedAtUtc, reasonKey: "SessionExpired" }
```

块下追加：

> **两个截止到期共用 `SessionExpired`**（取值表见 §10）。滑动截止到期时**同样落 `revokedAtUtc` / `revokedReason`**——与绝对到期分支同形，`detail` 因此恒定可填。
> **`tokenId` 无从识别时**（伪造，或会话记录已被清理）无会话行可读，`revokedAtUtc` 取**本次判定时刻**；取值同为 `SessionExpired`（§10）。

### D. §8 `POST /v1/auth/refresh` 错误段

原文「…四者靠 `reasonKey` 分辨」→「…**各情形靠 `reasonKey` 分辨，取值与触发见 §10**」。（错误码仍是两条，一字不动。）

### E. `systems/account.md` 校验流程伪码（两处叶子补标注）

```
按 tokenId 查 session 行（查不到 → auth.session_revoked，reasonKey = SessionExpired）
  ├─ 用当前 generation 重算 mac，命中 → 正常 rotation
  ├─ 用 generation - 1 重算 mac，命中且在 60 秒宽限窗口内 → 回放上次那一对，不再轮换
  ├─ 用 generation - 1 重算 mac，命中但已出窗口 → 判泄漏 → 吊销该账号全部会话（TokenReuseDetected）
  └─ 均不命中 → 判泄漏 → auth.session_revoked，reasonKey = TokenReuseDetected（代次更旧即重放，见下）
```

伪码上方既有的「求值顺序照 `auth.md` §4 写死，先判到期、再判宽限回放」一句不动——两个截止的到期判定发生在本流程**之前**，取值同为 `SessionExpired`。

### F. 由此可写实的验收断言（给 `/derive-requirements` 的落地面）

| 给定 | 期望应答 / 存储结果 |
|---|---|
| refresh，会话行存在且 `now ≥ refresh_expires_at_utc` | `auth.session_revoked`，`detail.reasonKey = "SessionExpired"`；会话行 `revoked_at_utc` / `revoked_reason` 被写入 |
| refresh，会话行存在且 `now ≥ absolute_expires_at_utc` | 同上（既有行为不变） |
| refresh，`tokenId` 查不到会话行 | `auth.session_revoked`，`detail.reasonKey = "SessionExpired"`，`detail.revokedAtUtc` = 判定时刻；无任何行写入 |
| refresh，`tokenId` 命中但 mac 两代均不命中 | `auth.session_revoked`，`detail.reasonKey = "TokenReuseDetected"`；该账号全部会话被吊销 |
| 上述任一情形 | 应答 `code` 仍只可能是 `auth.session_revoked` 或 `server.unavailable`（`operations/deployment.md` G-1 的否定断言同批成立） |

## 后果

- **改动面（全部在后端库）**：`contracts/auth.md` §4 · §8 · §10；`systems/account.md` 的 refresh 校验流程伪码。合计四处，最大的一处是 §10 的一行表格 + 一段说明。
- **`contracts/auth.md` 由 partial 转 ready**（就该卡点而言）；`systems/account.md` 的同一卡点一并解除。两者的另一条卡点（判定链第④级第三方审核适配器，挂 `02` 上线分级）**不受影响、仍需排除**。
- **不牵动 `envelope.md` §6 台账**：不新增、不变更任何 `code`；`class` 随 `code` 恒定不受影响；台账只登记 `detail` 的**形状** `{ revokedAtUtc, reasonKey }`，不登记取值（`envelope.md` §6 承重项原文：「三处 `reasonKey` 的形态…统一在 `auth.md` §10，**台账不复述取值表**」）。子项 ③ 使该形状保持恒定，故连形状也不动。
- **不牵动**：三条机检断言（`contracts/_index.md`：断言②「不下探到 `reasonKey`」）· 完成判据第 3 条（不涉 `code`）· `systems/account.md` 的承重列表与事务边界七行表（`revoked_reason` 列已存在，写入面与既有 `SessionExpired` 路径同形）· `operations/version-matrix.md`（取的是绝对寿命这个**时长**旋钮）· `operations/deployment.md` G-1（本方案不新增 `code`，与 G-1 同向）· `contracts/compliance.md`（§5 / §11 是另外几个 `code` 的取值表，§7 只往本表供 `PlaytimeEnded` 一值）。
- **完成判据的兑现**：第 1 条（markdown 语义）由本方案覆盖；第 5 条人工清单第 1 项（`detail` 形状与 `message` 必含项）需过一遍；第 6 条（对侧跨库 handoff）**在推荐路径下无对象**——客户端零改动（见下）。
- **客户端承接义务：推荐路径下为零。** 无新键、无新文案、无代码改动、无发版顺序耦合。`SessionExpired` 的既定措辞「登录状态已过期，请重新登录」与「不附原因句」纪律**恰好因为本方案而继续成立**。（若改选路径 B，则多一条可任意延后的翻译条目，见 `## 仍需用户决定`。）
- **存档 / schema 影响：无。** `reasonKey` 是传输层字段，不进 profile、不进 `schemaVersion`。

## 备选方案（已考虑并否决）

- **给「`tokenId` 无从识别」单立第三个取值**（如 `CredentialUnknown`）— 玩家措辞与到期一字不差（同主项理由 2），且向未知来源确认「这个 `tokenId` 我不认识」是无谓的信息自述面。
- **让滑动到期落进「未知 `reasonKey` → 一级键」的兜底** — §10 已就 `SessionSuperseded` 逐字否决过同一做法：「不给它取值，等于让它长期占用『未知 → 兜底文案』那条路，而那条兜底是为**日后新增**取值准备的」。而闲置到期是比 `SessionSuperseded` 更常见的常态路径。
- **给 `refresh` 新增第三条错误码表达闲置到期** — §8 / §10 已否决过同形提案（`auth.reauth_required`）：客户端「有无明确应答」的两条路径判据靠报文层面只有两种可能才无歧义。
- **把 `revokedAtUtc` 改为可选，以适配「无会话记录」的情形** — 要动 `envelope.md` §6 台账里的 `detail` 形状（P-1 护栏所在的表），而「取本次判定时刻」零成本且语义成立（子项 ③）。
- **在 `detail` 里加一个内部子原因字段区分两个截止** — 服务端内部键跨边界即成为契约的一部分，客户端无消费点；§1a 的 `channelUserId` / `idKind` / `sid` 三条先例已逐条否决过这一形态。
- **改短滑动 TTL 使该分支不再可达** — 治的是另一个病（08-23 已按同一理由否决过「30 天 → 7 天」），且分支只会更早被求值，不会消失。
- **在客户端侧加一条「距上次 `signin` 超过 N 天则回登录屏」的自收口** — 客户端侧已明确禁止（`account-service.md`「客户端不自收口，这条是承重的」，撞「设备时钟不可信」）。

## 与既有决策的张力

**一处，程度轻微，须一并落笔而非绕过：**

- **`SessionExpired` 的既有定义会被扩宽。** §5b 与 §10 现写它是「链达到**绝对**寿命上限」，而 08-23 的 handoff / answer-log 也是这么记的。本方案把它扩为「凭据不再有效的三种情形」。
  **为什么需要它松动**：不松动就必须新增取值（路径 B），而新增取值的代价是一份逐字相同的文案副本（主项理由 2 / 3）。
  **松动的代价**：`answer-logs/log-refresh-lifetime-cap.md` 与 `handoffs/2026-08-23-refresh-lifetime-cap.md` 里「新 `reasonKey` `SessionExpired`」那句的语义被扩宽——但两者都是**历史记录**（answer-log 记的是当时答了什么），按本库「活文档只保留最新设计」的约定，历史文档不随之改写，权威以 `contracts/auth.md` §10 为准。
  **必须同批保住的一句**：§5b 的闸门收口论证**不依赖** `reasonKey` 的独占性——它只依赖「绝对截止存在、`signin` 时锚定、rotation 永不顺延」。§5b 正文「超过 `absoluteExpiresAtUtc` 的 `refresh` → 回 `auth.session_revoked`（`reasonKey: "SessionExpired"`，§10）」一句**仍然成立、不需改动**；只是它不再是该取值的唯一来源。落笔时须确认这一点没有被读成收口被削弱。

## 前置依赖

**无。**

已逐条核对：`open-questions/02` 的合规能力上线分级（`auth.md` 的另一条卡点）与本问题无交集——它排除的是昵称判定链第④级，不触及 refresh 路径；`06` 的两条待实测取值同样无关；`operations/version-matrix.md` 的两项待定（`appVersion` 下界 / `manifestSchema` 集合）不构成前置。本方案不引入任何新旋钮、不取任何新数值。

## 仍需用户决定

### 取向 1（唯一一条）：滑动截止到期是**共用** `SessionExpired`，还是**新增一个取值**？

**背景（自包含）**：后端契约 `backend-design-documents/contracts/auth.md` 的 §10 有一张表，登记错误码 `auth.session_revoked` 的 `detail.reasonKey` 字段可以取哪些值（当前八个）。这个字段**只驱动客户端弹窗里的二级文案措辞**，不驱动任何行为分支（客户端对该错误码只有一条处置：硬阻塞、请玩家重新登录）。同文件 §4 描述 refresh 请求的求值顺序，其中第四分支是「refresh token 因**闲置超过 30 天**（滑动截止 `refreshExpiresAtUtc`）而失效」——这一分支目前没有指定取哪个 `reasonKey`，是 `auth.md` 转 ready 的唯一卡点。既有取值 `SessionExpired` 明写的触发是另一件事：**连续活跃**的登录链达到 60 天绝对寿命上限。

**选项 A（推荐）：共用 `SessionExpired`。** 改写 §10 该行的「触发」列，使它覆盖「凭据不再有效」的三种情形（闲置到期 · 绝对上限到期 · `tokenId` 无从识别）。
- 后果：契约取值仍是八个；客户端**零改动**（无新翻译键、无代码改动、无发版耦合）；`SessionExpired` 已定的玩家措辞「登录状态已过期，请重新登录」与「不附原因句」纪律继续成立。
- 代价：线上报文与服务端 `revoked_reason` 列不再区分「闲置流失」与「活跃链到期」。会话行仍同时持有两个截止时间戳，需要时可在行内判出是哪一个先到期；目前 `operations/observability.md` 没有任何以 `revokedReason` 为标签的指标（已核对）。

**选项 B：新增第九个取值**（命名建议 `SessionIdleExpired`——与既有八值「事件完成态 + PascalCase」构词一致）。
- 后果：报文层面即可区分闲置到期与绝对上限到期，服务端 `revoked_reason` 列直接可用于观测「有多少玩家是被 60 天上限请回登录屏的」（这与 §5b 记录的成本项相关：活跃玩家一年约 6 次重登，`Phone` 渠道每次一条短信）。
- 代价：客户端 `res://text/` 需要多一条二级文案条目 `ERR_AUTH_SESSION_REVOKED_SESSION_IDLE_EXPIRED`，而它的中文与 `..._SESSION_EXPIRED` 那条**一字不差**（两种情形对玩家是同一句话）——两条逐字相同的文案条目就是一份会漂移的副本，且客户端的文案审计只查一级键、无从发现不同步。该条目可任意延后补（未知取值回落一级文案，两侧发版顺序任意），不阻塞任何发版。
- 若选 B，还须一并决定「`tokenId` 无从识别」那条叶子取哪个值（本草稿子项 ②），否则该处仍无答案。

**推荐 A 的理由**：§10 自己写明 `reasonKey` 分辨的是**玩家措辞**而非机制的自述；两种到期对玩家是完全相同的一句话（都是无过错的例行事件、都没有第二台设备在动他的账号），而要让它们真的有分辨价值，二级文案就得说出「因为你太久没登录 / 因为这条链够老了」——那恰恰是客户端侧已明确否决的写法（把一个后端可调旋钮写进翻译条目，改值时静默失准）。观测需求可用不跨边界的内部字段满足，无须占用契约面的取值。

→ **已裁决（2026-09-07 · 批量评审）：选项 A —— 共用 `SessionExpired`。** 不新增取值、不新增 `code`、`envelope.md` §6 台账一字不动、客户端零改动；子项 ②（`tokenId` 无从识别）随之并入同一取值，选项 B 附带的那个从属问题不再存在。

**本草稿的取向项已全部裁决，可直接进入 `/analyze-new-ideas backend`。**
