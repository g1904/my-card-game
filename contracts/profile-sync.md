# profile-sync —— Profile 下行 / 上行 · CAS 与幂等 · 可见字段子集与掷骰复算

> 覆盖 `/v1/profile/…` 两个端点的报文本体。**边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、错误码台账、版本协商、Profile 三段可见性的分界——全部见 `envelope.md`，本文件只写 sync 域**相对它的差异与细化**。
> 客户端侧门面见 `game-design-documents/systems/services/sync-service.md`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> Source: `handoffs/2026-08-14-profile-sync-contract.md`、`handoffs/2026-08-12-grant-source-code-contract.md`、`handoffs/2026-08-14-splitmix64-test-vectors.md`（§6a 向量填值）、`handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md`、`handoffs/2026-08-16b-account-identity-model.md`（§5 后端写入字段表与白名单补行）、`handoffs/2026-08-17-profile-field-naming.md`（§5 白名单集合字段单数化 + §5b 命名通则 + §7 `ordinal` 口径消歧）、`handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md`（§4 所有权类拒绝 + §5 水位路径与 §5c 回声校验 + §7a 判据边界 + §8 读路径要求）、`handoffs/2026-08-23c-echo-validation-scope.md`（§5c 适用面恒等式 + 比较口径 + 追加字段刚性）。

## 1. 端点集：两个，封定

```
GET  /v1/profile/pull     整聚合下行（无 body，账号取自 token）   —— 需鉴权
POST /v1/profile/push     diff 上行（CAS + 幂等）                 —— 需鉴权
```

与 `sync-service` 的两个 B 形态方法一一对位（`PullProfileAsync` / `PushAsync`）。**购买域的两个端点不在本文件**，见 `purchase.md`——它的承重纪律与本文件恰好相反（后端权威写入 · 必须裁决 · 必须能拒绝）。

**`accountId` 不进 query、不进 body。** 它由 access token 唯一确定；放进请求参数即造出「token 与参数不一致」这个分支，而该分支的唯一用途是越权拉取别人的存档。客户端 `PullProfileAsync(accountId, ct)` 的 `accountId` 参数只用于**本地断言**（与 `Session.AccountId` 比对），不上行——与「切账号即信封失效」的客户端纪律同源。

## 2. pull 报文

请求：无 body，照 `envelope.md` §4a 带全部请求头。

应答 `200`：三字段，对位客户端已定 `ProfileSnapshot(Profile, Revision, SchemaVersion)`，一字不多。

```json
{
  "revision": 137,
  "schemaVersion": 7,
  "profile": { "…": "客户端定义的 PlayerProfile 序列化形态，后端原样存取" }
}
```

**新账号的初始 profile 骨架 = 只有一个字段。** 后端在账号创建时写入：

```json
{
  "accountInfo": {
    "accountSeed": "9f2c1a77b30e45d1",
    "createdAtUtc": "2026-08-16T04:12:33Z",
    "identities": [ { "channel": "Phone", "boundAtUtc": "2026-08-16T04:12:33Z" } ]
  }
}
```

后端不懂 Profile 结构（pillar #1），因此账号创建时它能写的只有**它自己持有真值的那几项**（种子、注册时刻、首条 identity）；其余默认字段由客户端在 `isNewAccount` 时本地构造，随首次 push 补齐。初始 `revision = 1`（账号创建即一次写入），客户端 `baseRevision` 初值为 `0` ⇒ 首次 pull 必然推进，**不存在「空 profile」这个分支**。

账号创建之后，后端还能写入的只有两处：`bind` / `unbind` 成功时的 `identities`、验票通过时的 `bundleGrantOrdinal` —— 完整清单与写入时机见 §5 的**后端写入字段表（封闭）**。

**`accountSeed` 以 16 位小写十六进制字符串下发**（无 `0x` 前缀，定长便于校验）。`AccountSeed` 是 `ulong` 随机数，**几乎必然超出 2⁵³**——JSON number 在双精度实现里会静默丢低位，而它是**逐位复算的输入**：丢一位则两侧算出不同的 `roll`，且该缺陷只在部分账号上显形。选 hex 而非十进制字符串：定长、与「种子是一段比特」的语义相符、不会被中间层当数字重新解析。`envelope.md` §2 的整数通则因此**补了一个判据而非开例外**（「可能超出 2⁵³ 的整数一律字符串」），其论据与该条原论证同源。

**pull 侧不做版本闸门。** 云端 `schemaVersion` 高于客户端支持上界这一情形由**客户端迁移器**承担（`sync-service.md`：走阻塞屏的「需更新」变体）。后端 pull **原样返回、不判定、不拒绝**——理由同 `envelope.md` §7b：闸门只在签发 token 时判定一次，由 `signin` 的 `client.version_unsupported` 独占；让 pull 也判一次即出现两个闸门、两套阈值。

## 3. push 请求：负载信封四字段 + 两段 diff

对位客户端已定 `ProfilePayload`（其中 `ContentVersion` / `AppVersion` 两项按 `envelope.md` §4b 搬到 HTTP 头）。

| 字段 | 类型 | 必填 | 语义 | 客户端对位 |
|---|---|---|---|---|
| `pushId` | string (GUID) | ✅ | 幂等键。**批次组装时生成一次，跨启动重试保持不变** | `ProfilePayload.PushId` |
| `baseRevision` | number (long) | ✅ | CAS 前置条件。`0` = 本设备尚无云端确认 | `.BaseRevision` |
| `schemaVersion` | number (int) | ✅ | **存档负载**自身的版本（≠ URL 的 `/v1/`） | `.SchemaVersion` |
| `reason` | string | ✅ | `SavePointReason` 枚举名逐字：`"CycleStarted"` / `"EventResolved"` / `"ChapterBoundary"` / `"CycleEnded"` / `"MetaChanged"` | `.Reason` |
| `playerDiff` | object | ✅ | 账号级 diff，**顶层键粒度**（§3a）。含透明子集（§5） | `.PlayerDiff` |
| `characterDiffs` | array | ✅ | 每项 `{ characterId, diff }`。**整体不透明** | `.CharacterDiffs` |

- **`reason` 对后端是日志与聚合维度，不驱动任何判定**——判定只看 `baseRevision` 与 `pushId`。明写这一条，否则它迟早会被拿去做分支。
- **空 diff 不是错误**：`playerDiff: {}` + `characterDiffs: []` 照常接受并 `+1`（客户端的防抖窗口可能合成出空批次）。拒绝它等于给客户端加一条它无法预防的失败路径。
- `characterDiffs` 走**数组**而非以 `characterId` 为键的对象：键名是玩家数据，做 JSON 对象键会让 schema 无法表达，也不便于后端流式处理。

### 3a. diff 的合并语义：**顶层键粒度的浅合并**（承重）

后端要靠 diff 维护它在 pull 时回吐的整聚合，因此「收到 diff 怎么合进存储的 profile」是契约的一部分，**不能留给实现**。

- **`playerDiff` 中出现的顶层键 → 整键替换；未出现的顶层键 → 保持不变。** 键值以下的结构**完全不透明**，后端不递归、不比对、不校验（`playerPower` 这类数组一旦出现即整体替换，不做逐元素合并）。
- **`characterDiffs[i].diff` = 该 `CharacterProfile` 的对象，整体替换**该 `characterId` 下的存储值；未出现的 `characterId` 保持不变。这与客户端「diff 粒度 = `CharacterProfile`，是**传输优化**而非同步单元」逐字对齐。
- **空对象 = 无变化**，与上一条的「空 diff 不是错误」自洽。
- **不需要删除语义。** 客户端已定 `PlayerProfile` 含全部历史角色、**只增不删**（体积由 `pastEvent` 软上限护栏承接）。契约因此不提供 `null` 删除标记——这同时避开了与 `envelope.md` §2「不下发 `null`」的冲突。
- **明确否决 RFC 7386 JSON Merge Patch**：它以 `null` 表示删除（与 §2 正面冲突），且要求后端递归遍历不透明结构才能合并，动摇「Profile 对后端半透明」这条分段。**也否决段级全量替换**（每次 push 重传整个账号级段，与「整聚合上行不可持续」这条既定理由同向相悖）。
- 推论：**§5 白名单的每条透明路径都落在某个顶层键之下**，因此「该顶层键出现在本次 `playerDiff` 中」⟺「这些透明字段本次有新值」。后端据此判断本次是否需要跑复算，无需解不透明部分。

## 4. 应答：三分支 + 幂等命中

| 情形 | HTTP | body |
|---|---|---|
| `baseRevision == cloudRevision` | `200` | `{ "newRevision": 137, "deduplicated": false }` |
| **`pushId` 命中幂等窗口** | `200` | `{ "newRevision": 137, "deduplicated": true }` |
| `baseRevision < cloudRevision` | `409` | `error.code = "sync.conflict"`，`detail = { "cloudRevision": 137 }` |
| `baseRevision > cloudRevision` | `409` | `error.code = "sync.revision_ahead"`，`detail = { "cloudRevision": 137 }` |
| **后端写入路径的回声校验不通过**（§5c） | `409` | `error.code = "sync.conflict"`，`detail = { "cloudRevision": 137, "field": "/entitlement/bundleGrantOrdinal" }` |

- 对位客户端 `PushAck(NewRevision, Deduplicated)`，一字不多。
- **状态码只承担传输层语义**，客户端一律按 `code` 分支（`envelope.md` §5b）；两条 `409` 共用状态码，正说明为什么必须有 `code`。
- `schemaVersion` 越出兼容集合 → `sync.payload_schema_unsupported`（`Upgrade`，**不硬阻塞**，`detail.supportedSchemaVersions`）。**判定发生在 CAS 之前**——版本不兼容不应消耗一次 revision。
- 负载信封字段缺失 / 类型不合法 → `sync.payload_invalid`（`detail.field` 给 JSON path）。**不透明段内部的任何结构问题都不得触发这一条**：它只覆盖信封本身与 §3a 的顶层形状。
- **本文件不新增任何错误码。** 五条 `sync.*` 与 `rate.limited` 已在 `envelope.md` §6 台账中，`class`、客户端处置与 `detail` 形状均原样适用——这是边界层先成文带来的直接收益。回声校验**复用 `sync.conflict`**：客户端处置与 CAS 冲突逐字相同（以云端为准、丢弃本地缓冲、重新 pull），新增一个码只会逼客户端多写一条走向同一处的分支；「这不是普通冲突」的可观测性由风控事件承担（§5c）。
- **后端拒绝上行的全部面共四类**，逐类的触发与处置：

  | 类 | 触发 | `code` | 是否消耗 revision |
  |---|---|---|---|
  | 版本闸门 | `schemaVersion` 越出兼容集合 | `sync.payload_schema_unsupported` | 否 |
  | 信封 / 顶层形状 | 信封字段缺失或类型不合法 | `sync.payload_invalid` | 否 |
  | CAS | 基线不符 / 本地领先 | `sync.conflict` · `sync.revision_ahead` | 否 |
  | 所有权 | 后端写入路径的回声校验不通过（§5c） | `sync.conflict` | 否 |

- **判定顺序：`schemaVersion` 闸门 → 信封形状 → CAS → 回声校验 → 写入。** 回声校验必须发生在 `cloudRevision += 1` **之前**——被拒绝的一次不得消耗一次 revision，与版本闸门那条同一理由；且 CAS 已失败时整批已被拒绝，再做字段比较是白做。
- **`compliance.*` 不出现在这两个端点的错误清单里**，见 §11。

## 5. 后端可见字段子集：按 JSON path 逐条列白名单

`envelope.md` §8 已定 Profile 分三段可见；本节给出第二段（**透明子集**）的逐字段清单。三条纪律：

- **未在下表出现的一切字段都是不透明段**——不另写「不可见清单」，白名单的补集即是。
- **后端对透明段只读，除下表四项外。透明 ≠ 可改写。**

  **后端写入字段表（封闭）**

  | JSON path | 写入时机（**表内写死**） | 频次 | 语义权威 |
  |---|---|---|---|
  | `/accountInfo/accountSeed` | 账号创建时 | 一次，此后不变 | §2 |
  | `/accountInfo/createdAtUtc` | 账号创建时（与上一行同一步） | 一次，此后不变 | `auth.md` §1a |
  | `/accountInfo/identities` | 建号 / `bind` / `unbind` 成功时 | 反复 | `auth.md` §1a |
  | `/entitlement/bundleGrantOrdinal` | 每次验票通过时 `+1` | 反复 | `purchase.md` |

  **其余一切字段后端只读。本表封闭——新增后端写入字段是破坏性契约变更，须两侧同批评审。**

  > **护栏是承重的，规则的措辞不许改。** 规则是「后端只读，**除表内四项外**」，**不是**「后端可写的字段有……」——列举式措辞会让这张表读起来像一个可增长的清单，而例外式措辞使它读起来像一道需要论证才能通过的门。任何要求扩表的提案，须显式引用本条护栏并说明为何不能用别的通道，**不得静默加行**。
  >
  > **「写入时机」列同样是封闭的**，且比字段清单更能挡住下一次扩表：它使「哪些时机后端会写」本身也有边界——建号 / 验票 / `bind`·`unbind` 之外的任何时机，后端一律不写。
  >
  > **够格进表的判据（两条同时满足）：** ① **真值只可能在服务端产生**；② **客户端无任何其他通道能取到它**。
  > `identities` 两条都满足（identity 表在服务端；另立读取端点已被 `auth.md` §1 否决）。
  > `createdAtUtc` 两条都满足，且写入时机与 `accountSeed` 完全相同，不新增一个后端会写 profile 的时刻。
  > **反例一：`/accountInfo/nickname`** —— 真值是玩家输入的，第 ① 条即不满足，故它是**透明只读**路径而非写入路径（`auth.md` §8）。
  > **反例二：`/statistics`** —— 真值在客户端，永远不够格。
  > **反例三：`/entitlement/bundleRedeemedOrdinal`** —— 兑现水位的真值产生在客户端的兑现事务里，第 ① 条即不满足；它与表内的 `bundleGrantOrdinal` 同处 `entitlement` 键**不构成进表理由**，同键不等于同所有权。
  >
  > **为什么 `bundleGrantOrdinal` 在表内。** 它的推进权**只能在后端**，否则付费防篡改归零（客户端侧承重定案，不可绕过）。
  > **已否决的替代**：把它移出 profile 聚合、单独存在后端的购买域（客户端只读取、不落存档）。代价更高——它会让兑现段的掷骰 `ordinal` 来自一个不在 profile 里的字段，破坏「整次授予由 `(域, 序号)` 完全确定且随授予事务同一次持久化」这条客户端承重纪律，且 `AccountRng` 的两个域会有两套来源。
  >
  > **如实记下的代价**：一条**无例外**的「后端只读」规则本来最省心，读者不必记例外。有了四条例外之后，每一条「能不能让后端也写这个」的提议都会引用它们作先例——这正是上面那条判据存在的理由：**它把「引先例」变成一次必须逐条通过的检验。**
- **⚠ 承重：透明字段的 JSON path 是契约的一部分。** 客户端把 `playerPowerFragment` 挪个位置、或把 `sourceCode` 改个名，在客户端侧是纯重构（老档靠迁移无损通过），但**在后端侧会静默变成「这个字段消失了」**——复算退化为空操作，且两侧都不会报错。因此：**移动或重命名任一透明字段的路径 = 破坏性契约变更，必须 bump `schemaVersion` 并与后端同批改**，与「重命名跨边界枚举值即破坏性变更」（`sync-service.md`）同一条纪律。后端对**缺失的透明路径**一律记一条告警级台账（**不拒绝上行**），使这类漂移在线上可见。

| JSON path（相对 `profile` / `playerDiff` 根） | 类型 | 后端用途 |
|---|---|---|
| `/accountInfo/accountSeed` | string (hex16) | 复算输入；**后端写入**（账号创建时一次） |
| `/accountInfo/createdAtUtc` | string | 账号注册时间；**后端写入**（同上一步） |
| `/accountInfo/identities` | array of `{ channel, boundAtUtc }` | 绑定渠道列表；**后端写入**（建号 / bind / unbind）。**不含 `channelUserId`**——后端内部键不过边界，也不写进玩家可导出的存档 |
| `/accountInfo/nickname` | string | **后端只读**：合规抽查与存量扫描的对象。写入方是客户端（`auth.md` §8 记下了这条判断的代价与边界） |
| `/playerPowerFragment/accumulated` | number int `[0,10000]` | 区间与变化方向的不变式校验 |
| `/playerPowerFragment/finaleWinOrdinal` | number int | 复算的 `ordinal`；单调 `+1` 校验 |
| `/playerPowerFragment/ch1FirstWinDone` · `ch2FirstWinDone` · `ch3FirstWinDone` | boolean | 单调 `false → true` 校验 |
| `/playerPowerFragment/lastRoll` | number int `[0,9999]` | 逐位比对（§7 校验 ①） |
| `/playerPowerFragment/lastEffectiveChance` | number int `[0,10000]` | 命中自洽校验（§7 校验 ②） |
| `/playerPower[*]/powerId` | string | `x` 的计数对象 |
| `/playerPower[*]/sourceCode` | string enum | `x = count(sourceCode == "FinaleWin")` |
| `/entitlement/bundleGrantOrdinal` | number int | 复算 `PremiumBundle` 域掷骰的 `ordinal`；**单调 `+1` 校验**；**后端写入**（见上方封闭表与 `purchase.md`）；受 §5c 回声校验约束 |
| `/entitlement/bundleRedeemedOrdinal` | number int | 兑现水位，**后端只读**（写入方是客户端的兑现事务）。不变式校验：`0 ≤ bundleRedeemedOrdinal ≤ bundleGrantOrdinal` 且单调不减；违反走 §7a（记账 + 风控，**不拒绝**）。**不受 §5c 约束**——判据是所有权，客户端有权写它 |

**明确落在不透明段的（各有理由）：**

- `/playerPower[*]/status`、`disabledAbility` —— **生效维度不是持有维度**，不影响 `x`。
- `/playerItem`、六个 Codex、`achievement` —— 无后端规则用途。
- `/statistics`（`PlayerStatistics`）—— **明确不透明**，兑现 `envelope.md` §8 的「后端不复算、不校验、不得用统计数据驱动任何发放」。把它列进透明档等于给「拿统计驱动活动奖励」开一道门，而那会当场推翻宽松同步口径的全部前提。
- `characterDiffs` **整体**（含轮回级两类持有条目的 `sourceCode`）—— 它对后端无规则用途（纯透传），而每多一条透明路径就多一条上面第三条纪律的约束。**它是 diff 报文的结构键，不是 Profile 字段**，故不受下面那条集合命名通则约束。

### 5a. `sourceCode` 的线上表示：契约走字符串枚举名

`envelope.md` §2 定「枚举值一律字符串、与客户端 C# 枚举名逐字相同」，而客户端定「`code` 整数是**存档**里实际序列化的东西」。两者的收口是：**契约侧走字符串名（`"FinaleWin"`），存档侧走整数 code，客户端在序列化边界做一次映射。**

- 依据：**通则不开例外的价值高于重命名自由**，而重命名本就极少发生。
- **连带纪律：`Source` 的成员名与 code 双双冻结**——存档侧靠 code、契约侧靠名，两者各自都是稳定键，重命名成员在**两侧都是**破坏性变更。已删成员的名与 code 同样永不复用。
- **未知取值：记录原值、不改写、不拒收。** 若后端把未知取值归一为 `Unknown` 并在下行时回写，会直接压低 `x`、让残卷档位回跳，推翻客户端「`x` 单调不减 ⇒ 档位只降不回跳」这条承重不变式。
- **合法子集表不在后端复制。** 客户端有一张 `(Kind, Scope) → 允许的 Source 集合` 静态表，约束的是客户端的组装；后端只做取值识别与 `x` 复算，不要把它做成第二处真值。

### 5b. 透明路径的集合命名通则：**恒为单数**

**白名单与排除清单中的集合字段名一律单数**（`playerPower` · `playerItem` · `achievement` · `disabledAbility`）。本节因此不需要为「为什么这几个是复数、那几个是单数」保留任何解释，白名单读起来是一条规则而不是一份历史。

- **这条通则跨边界，是因为映射是机械的。** 存档字段名经客户端的 camelCase 单点策略逐字变成 JSON path ⇒ 两侧任一处出现风格分歧，边界上就得挂一张例外表，而那张表本身即第二权威。字段面的形态权威在 `game-design-documents/systems/player-profile/_index.md` 与 `systems/character-profile/_index.md`，**本库不复制**。
- **`characterDiffs` / `playerDiff` 不在约束内**：它们是 §3 的报文结构键，由本契约自己定义，不经字段映射产生。

**一次性切换（不设兼容期）的三个成立前提，缺一即不成立：** 线上无真实账号数据 · 两侧同批落笔 · 一次性不留双读期。

- 三者同时成立时才允许把重命名做成一次性切换：改名与 `schemaVersion` 的一次 bump 同批，两侧同时切到新名，无迁移、无双读分支。
- **兼容期在这里不是安全网。** §7a 的处置语义是「仅记账、不拒绝、不改写」⇒ 双读期内没有任何信号能告诉任一侧「对方还没改」，不一致的症状不是报错而是风控噪声，且会随双读分支长期存活而变得永久不可见。硬信号只能来自一次性切换 + bump。
- **本次改名合并进客户端两层 Profile 字段面收口的同一次 `schemaVersion` bump**（bump 清单的权威在 `game-design-documents/systems/services/sync-service.md`；本库只声明「须与之同批」）。

### 5c. 后端写入路径的回声校验：封闭表的执行点（承重）

§3a 的浅合并是**顶层键粒度**：客户端提交某个顶层键即整键替换，键内属**后端写入字段表**的路径随之被客户端提交的值覆盖。上方那张表挡住的是「谁有权 `+1`」，挡不住**覆写**——客户端提交它 pull 时的旧序号，云端就被**回退**，而序号回退比不推进更糟：同一个 `ordinal` 会被兑现两次，下一次验票再推一次，序列彻底错位。

`revision` CAS **不是**这条的防线。CAS 保护的是并发窗口，问的是「你的基线对不对」，不问「你有没有权改这个字段」——客户端一个 bug（把序号写成常量）在基线正确时会被原样接受。**没有本节，后端写入字段表就只是一句纪律，在报文层没有任何执行点。**

> **规则：凡 `playerDiff` 含某个顶层键，键内属后端写入字段表的每条路径，客户端提交的值只能是回声（echo）——与当前云端值相等即通过，不等即整批拒绝**，回 `sync.conflict`、`detail` 给 `{ cloudRevision, field }`（`field` = 第一条不匹配的 JSON path），并打一条风控事件（账号 · 违规 path · 云端值 · 客户端提交值 · `requestId`；落地形态同 §7a，归 `02` / `06`）。

- **后端永不采纳客户端对这些路径的写入，也不静默丢弃它。** 静默丢弃会让客户端 bug 永远看不见，而这类 bug 的症状恰好是玩家侧的错误发放。
- **拒绝整批，不做字段级挑拣。** §3a 的合并语义是整键替换，挑拣要求后端在顶层键内部做字段级合并——一旦为它开一次例外，「后端不递归、不逐元素合并」这条分段就被打开了。**拒绝整批是唯一不动摇既有分段的处置。**
- **`sync.payload_invalid` 的边界不变**：它仍只覆盖信封本身与 §3a 的顶层形状。回声比较的是白名单内某条路径的**取值**，不是结构合法性，故不走它；不透明段内部一字不动。
**判据是所有权，不是严格程度。** 受约束的是**客户端根本无权写**的路径：值无争议地不属于它，正常客户端在这些路径上永远只会提交回声，故零误报，拒绝是安全的。客户端**有权写**的路径（`nickname` · `playerPowerFragment/*` · `playerPower[*]/*` · `bundleRedeemedOrdinal`）一律不受本节约束，越界走 §7a 的「记账 + 风控、不拒绝」。**同一顶层键内的两条路径因此可能走两种处置**——实现者不得按键统一处置。

#### 适用面：一条恒等式，不是第二份清单（承重）

> **受回声校验约束的 JSON path 集合 ≡ 上方后端写入字段表的行集合。**

这不是巧合，是「够格进表」两条判据的直接推论：一条路径够格进写入表 ⟺ ① 真值只可能在服务端产生 且 ② 客户端无任何其他通道取到它 ⟺ **客户端提交的任何值都只能是它 pull 到的那个值**。三条推论：

- **写入表加一行，该路径自动进入回声约束。** 不需要第二次决定、不需要第二份清单、扩表的护栏无需加强——它已经覆盖了这件事。
- **写入表封闭 ⇒ 回声约束面封闭。** 「适用面有没有列全」这个问题因此**结构性地不存在**，而不是靠某一次把清单列全。
- **不属写入表的透明路径一律不受约束**，判据是**所有权**而不是透明性：`/accountInfo/nickname`（客户端是写入方）· `/playerPowerFragment/*` · `/playerPower[*]/*` · `/entitlement/bundleRedeemedOrdinal` 全部照旧走 §7a。

**另立一张「受回声校验约束的 path」清单是明确否决的**：它与写入表必然漂移，而漂移的形态恰恰是「进了写入表却没进回声表」——正是这条恒等式要关掉的口子。

**当前的具体面**（随写入表自动同步，本节不单独维护）：

| 受约束 JSON path | 所在顶层键 | 触发该顶层键提交的客户端常规路径 |
|---|---|---|
| `/accountInfo/accountSeed` | `accountInfo` | **改昵称** |
| `/accountInfo/createdAtUtc` | `accountInfo` | 同上 |
| `/accountInfo/identities` | `accountInfo` | 同上 |
| `/entitlement/bundleGrantOrdinal` | `entitlement` | **兑现** |

**受约束的顶层键因此恰有两个。** 两者的共同形状是「同一顶层键内混有后端写入路径与客户端写入路径」——这正是整键替换把覆写窗口变成**常规路径**（而非罕见窗口）的充要条件：每次改昵称、每次兑现都会走一遍。

#### 比较口径：类型感知的语义相等，不是原始字节相等（承重）

误判的代价是**在正常账号上丢玩家进度**，故口径逐类型写死：

| path 的类型 | 比较口径 |
|---|---|
| 整数（`bundleGrantOrdinal`） | 数值相等 |
| 定长 hex 串（`accountSeed`） | **逐字相等**——形态已被 §2 钉死为 16 位小写 hex，两侧无归一化自由度 |
| RFC 3339 时间串（`createdAtUtc`） | **按时刻相等**，不按字面相等 |
| 对象数组（`identities`） | **有序逐元素**，元素内**逐字段**按上述口径递归 |

- **`createdAtUtc` 必须按时刻比较。** 客户端持有的是强类型时间值，反序列化 → 再序列化会在 `Z` / `+00:00`、小数秒位数上产生合法但不同字面的表示。按字面比较等于要求两侧的时间序列化器逐字一致——**那是一条无人声明、无处校验、一次库升级就会静默破坏的隐含契约**，而它破坏时的症状是「所有玩家改昵称都丢一次进度」。
- **不按原始字节比较**，同理并追加一条：JSON 对象的键序与空白不稳定，字节比较把序列化器实现细节抬成契约。
- **`identities` 取有序而非集合相等**：顺序由后端产出、客户端原样回声，要求有序既更严格也更便宜；宽松只会掩盖客户端的重排 bug。若日后确有重排需求，那是后端自己的变更，不构成客户端义务。

**⚠ 连带刚性：向受约束顶层键内的对象追加字段，是需要两侧同批落笔的变更。** 客户端对这些路径持有强类型 record，强类型往返会**静默丢掉**它不认识的字段 ⇒ 下一次回声当场失败 ⇒ 整批拒绝。这与「重命名跨边界枚举值」同档。**它是 `envelope.md` §8「客户端加字段不需要后端配合」的例外**——那句话讲的是不透明段，本条讲白名单内。

**`openapi.yaml` / `schemas/*.json` 表达不了本节**：schema 说不出「等于当前云端值」，强行表达只能退化为把这些 path 标成必填，而 §3a 的浅合并 diff 里它们本就常常不出现。**spec 落笔时须在对应 schema 处留一条注释指向本节**，否则实现者会试图用 schema 承担它（与「缺失透明 path 走告警台账、不走 schema 校验」同一处坑）。

#### 服务端保证（栈中立的验收断言）

- 上行 `playerDiff` 含 `accountInfo`，其中三条后端写入 path 与云端语义相等 ⇒ **接受**；`nickname` 照常写入。
- 上行 `playerDiff` 含 `accountInfo`，其中任一条后端写入 path 与云端不等 ⇒ `sync.conflict`，`detail.field` 给第一条不匹配的 path，且 `cloudRevision` 与 profile 均不变。
- `createdAtUtc` 以不同合法 RFC 3339 表示（`Z` ↔ `+00:00`、不同小数秒位数）提交同一时刻 ⇒ **接受**。
- `identities` 元素顺序与云端不同 ⇒ **拒绝**。
- `bundleRedeemedOrdinal > bundleGrantOrdinal` 且 `bundleGrantOrdinal` 回声正确 ⇒ **接受** + 告警台账 + 风控事件（§7a，不拒绝）。

## 6. 账号级掷骰的随机源：契约定义的纯函数 SplitMix64（承重）

**账号级掷骰不走 Godot 的 `RandomNumberGenerator`，改用本契约定义的纯函数。** 跨语言逐位一致是复算成立的**前提**；把它押在引擎实现细节上，等于让「Godot 升级」成为一次静默的作弊窗口——客户端自己已为 `RandomNumberGenerator.State` 写过同一条警告。**轮回级 RNG 完全不受影响**（不跨边界，继续用 Godot RNG）。

算法（契约的一部分，两侧逐位一致）。全部运算为 `uint64` 环上运算（溢出自然回绕），`>>` 为逻辑右移：

```
Mix(z):                                     // 标准 SplitMix64 finalizer
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB
    return z ^ (z >> 31)

GOLDEN = 0x9E3779B97F4A7C15

流的初态（三参数逐级混入，顺序是契约的一部分）：
    state = accountSeed
    state = Mix(state + GOLDEN * (uint64)(stream  + 1))
    state = Mix(state + GOLDEN * (uint64)(ordinal + 1))

取下一个数（有状态，供「一次派生、连续抽多条」）：
    Next():  state += GOLDEN;  return Mix(state)

万分比掷骰：
    roll = Next() mod 10000
```

- **`stream` 的整数取值随客户端 `AccountStream` 的成员序固定**（`PowerFragment = 0` · `PremiumBundle = 1`），**一经写入契约即冻结**——与 `Source` 的「名与 code 双双永不复用」同一条纪律。新增域只能追加。
- **`+1` 是对全零输入的防御**（`stream = 0` 且 `ordinal = 0` 时不塌缩为一次纯 `Mix(accountSeed)`）。两侧必须一致；差一位就整条序列不同。
- **不做拒绝采样**：`mod 10000` 的模偏差 < 2⁻⁵⁰，而拒绝采样会让「抽取次数不定」，使连续抽的序列在两侧更难对齐——为一个不可观测的偏差换一条真实的对齐风险，不划算。
- **测试向量是本契约的验收物**，见 §6a。**两侧各自实现后必须逐位对上它**——这是本条纪律唯一可执行的检查点。

### 6a. 测试向量（已填 · 数值权威在 `vectors/splitmix64.json`）

**数值的权威在 `contracts/vectors/splitmix64.json`**（8 组，字段与下表一一对应），**两侧测试直接读该文件**；下面的表格是**人类可读的对照**，不是测试消费的来源。理由与本库拒绝「第二份真值」同源，且这一份的漂移直接等于**作弊窗口**——两侧测试各抄一份进各自代码，抄错即静默失效。该文件不属 OpenAPI spec（不是报文形态），故单开 `vectors/` 而非塞进 `schemas/`。

**向量值由独立参考实现预先算出**（不等任一侧首次实现）；**两侧各自实现后逐位对表，对不上以 `vectors/splitmix64.json` 为准**。理由：向量是已冻结算法的函数，不含设计自由度 ⇒ 等待换不来信息，而先有表意味着两侧是**对着验收物写实现**，失败形态从「两侧都写完才发现差一位、且不知谁错」变成「当场红灯，且表是基准」。

> **⚠ 承重纪律：实现与表不符时，先复核实现、再复核表。** 两者都复核完仍不符，则**重算并同批改 markdown + JSON**——**不得单方面改表迁就实现**。表由第三方参考实现算出，这条纪律是为该代价配的护栏。

| # | `accountSeed` | `stream` | `ordinal` | `next[0]` | `next[1]` | `next[2]` | `roll` |
|---|---|---|---|---|---|---|---|
| 1 | `0000000000000000` | 0 | 0 | `238275bc38fcbe91` | `f89a2566b5822c54` | `47200e1d9780fa44` | 2433 |
| 2 | `0000000000000000` | 0 | 1 | `2f101fe21496ea20` | `a00624088f65d5b6` | `74963fa799894ab9` | 8096 |
| 3 | `0000000000000000` | 1 | 0 | `80abe802ac1e182e` | `949f48c1e9eb8a36` | `20adf28678236723` | 30 |
| 4 | `ffffffffffffffff` | 0 | 0 | `fc042709560421da` | `493384625f4330a7` | `912e647564aed866` | 2810 |
| 5 | `ffffffffffffffff` | 1 | 2147483647 | `df8b7d9f5d169190` | `f91d71decb4077bd` | `b7d36711bb7f3b48` | 3120 |
| 6 | `9f2c1a77b30e45d1` | 0 | 1 | `b4acb5a8f93e9674` | `07a278dbbd506102` | `d942ab6200120920` | 3028 |
| 7 | `9f2c1a77b30e45d1` | 0 | 2 | `e911376eb146a8e4` | `0fe4a5780d1a0daa` | `54bd17410ece9e6e` | 8468 |
| 8 | `0123456789abcdef` | 1 | 1000 | `7834afc76f55fbbb` | `c937a6eb9a750ddf` | `fd01144827cb482c` | 5115 |

`roll = next[0] mod 10000`——万分比掷骰只消费**第一个** `Next()`；后两个输出在表里的作用是钉住**流的连续性**，供「一次派生、连续抽多条」的场景。

**这张表抓的是两侧实现的对齐，不是随机性质量**（后者是 SplitMix64 自身的既有结论）。选取覆盖了最容易差一位的三处：组 1 验 `+1` 全零防御（不塌缩为纯 `Mix(accountSeed)`）· 组 4 验 `uint64` 环上运算与逻辑右移（抓有符号右移 / 溢出异常）· **组 2 ↔ 组 3 是顺序判别对**（把 `stream` 与 `ordinal` 两级混入写反即失败）· **组 6 ↔ 组 7 是相邻 `ordinal` 对**（也抓"少混一级"）· 组 5 的 `ordinal = int.MaxValue` 抓 `(uint64)` 转换处的符号扩展 · 组 3 与组 8 覆盖 `stream = 1`。组 6/7 的种子刻意复用 §2 初始骨架示例里的那个 `accountSeed`。组 3 的 `roll = 30` 顺带覆盖一类单位错误：误用 `mod 100` 时它会碰巧对上，而组 1（`roll = 2433`）不会——两组同表，不可能同时通过。

**实现自测提示（非规范性）**：标准 SplitMix64 以 `state = 0` 为初态的前三个输出是 `e220a8397b1dcdaf` / `6e789e6aa1b965f4` / `06c45d188009454f`。它是公开的既有事实、**不构成本契约的第二份真值**，但可用来先钉死 `Mix` 的两个常量、两次异或移位量、末尾 `>> 31` 与 `GOLDEN`；本表之上的三参数逐级混入是本契约独有的，无外部参照。

Source: `handoffs/2026-08-14-splitmix64-test-vectors.md`、`handoffs/2026-08-14-openapi-spec-timing-and-consistency.md`。

## 7. `AccountSeed` 复算协议：可复算的是 `roll`，不是阈值

「后端可离线复算」这句已定案语义拆开后是两件性质完全不同的事：

| | 后端能不能做 | 依据 |
|---|---|---|
| 由 `(accountSeed, PowerFragment, ordinal)` 算出 **`roll`** | **能**，且必须能——这正是种子放后端的全部意义 | 纯函数（§6），输入全在透明子集里 |
| 判定 **是否命中**（`roll < 生效概率`） | **不能可靠地做** | 生效概率 = `clamp(accumulated, Base(x), Cap(x))`，而 `Base` / `Cap` 是按 `(x, chapter)` 分档的**内容数值表**，随 overlay 热更、且不冻结 `contentVersion` |

**因此明确否决「后端持有分档表并全量验算」**：那是把一张随时热更的平衡表复制到后端，制造第二份真值 + 必然的版本漂移，与 pillar #1（不重跑玩法）、pillar #5（改数值不需要发版）同时相悖；后端还缺一个输入——**这次 Finale 是哪一篇章**（非首胜时首胜布尔不变，篇章不可推断），补它又要再加一条透明路径。

**协议：客户端上报两个中间值，后端做三条校验。**

```
客户端在每一次 Finale 胜利结算时，把本次掷骰的两个中间值落 PlayerPowerFragment：
  lastRoll            = AccountRandom(accountSeed, PowerFragment, finaleWinOrdinal).Next() mod 10000
                        // finaleWinOrdinal = 本次（自增后）的胜利序号：先算 +1，再以它掷骰，同一次写回
  lastEffectiveChance = clamp(accumulated, Base(x), Cap(x))     // 掷骰当刻的生效概率

后端在 finaleWinOrdinal 递增的那一次 push 上：
  ① 自算 roll' = SplitMix64(accountSeed, PowerFragment, finaleWinOrdinal) mod 10000
     校验 roll' == lastRoll                                  ← 抓种子篡改 / 序号刷 / 换设备重掷
  ② 单向蕴含：若 lastRoll >= lastEffectiveChance 却新增了一条 sourceCode == "FinaleWin" 的法则
     → 异常。反向（命中却未新增）不判异常                      ← 抓谎报命中
  ③ 结构不变式：finaleWinOrdinal 恰 +1 · accumulated ∈ [0,10000] · 首胜布尔单调 false→true
     · x 单调不减 · 未发放的那一次 accumulated 不减
```

**`ordinal` 的口径两侧一致：一律是「本次（自增后）」的序号。** 校验 ① 因此没有歧义——后端复算所用的 `finaleWinOrdinal` 就是本次 push 里携带的那个新值，与客户端掷骰时用的是同一个数。客户端侧的账号级掷骰通则见 `game-design-documents/systems/common-properties.md`，**本库不复述**。

三条**承重的写入约定**（缺任一条，上面的校验会在正常账号上误报）：

- **每一次 Finale 胜利都掷这一骰并落 `lastRoll`，即使不发放。** 客户端已定「未拥有法则数 > 0 才掷骰，否则**静默停摆**」；但若停摆时不写 `lastRoll`，而 `finaleWinOrdinal` 照常 `+1`（它是胜利序号），校验 ① 会稳定失败。**掷骰本身零成本**，只是结果不被消费。
- **首胜时 `lastEffectiveChance` 写 `10000`。** 客户端已定「首胜 100% 优先于闸门」——那一次的生效概率就是 100%，如实记录即可，**首胜因此不是校验 ② 的例外**。
- **校验 ② 只能是单向的。** 「命中却未新增」有一个完全合法的成因：**候选池已取尽**（既定的正常终局），而后端无法判断池是否为空（判断它需要内容池 + 已持有集合，即又一次复制玩法规则）。因此只把「未命中却新增」判为异常——这恰好是有作弊动机的那个方向。
- **校验 ③ 不检查发放那一次 `accumulated` 的变化方向。** 客户端已定「发放后重置为 `Base(x+1)` 而非归 0」，而 `accumulated` 本可低于 `Base`（地板只在求生效概率时 clamp）⇒ 命中后 `accumulated` **可能变大**；且 `Base` 是热更表，后端无从验算重置值。

**这套协议的价值与代价都写明：**

- **② 是真正的价值**：它不需要后端知道任何数值表，却把「谎报命中」这条最直接的作弊路径关死了——因为 `lastEffectiveChance` 一旦被抬高以配合谎报的命中，就会在 ③ 的 `accumulated` 一致性上露出来。
- **代价**：`lastEffectiveChance` 本身后端无法验真，所以「篡改客户端把生效概率写成 10000」这条路仍然通——它被 ③ 与风控接住，不被复算接住。这是 pillar #1 下的必然取舍，写清楚好过假装覆盖。
- **不需要历史列表**：`revision` CAS 保证上行严格串行，且每次 Finale 胜利必然产生一次 push（`EventResolved` 是自动存档点），因此「最近一次」两个字段就够。两个 `int`、非列表、老档补默认值 ⇒ **零迁移成本**。**明确否决**在 profile 里存一份掷骰历史列表：它会随账号年龄单调增长，正是 `pastEvent` 已被立护栏防范的那种形态。

### 7a. 复算不一致的处置：**仅记账 + 上报风控，不拒绝、不改写**

- **接受写入** → 打一条结构化风控事件（账号 · `finaleWinOrdinal` · 期望值 · 实收值 · `requestId`）→ 交由风控按累计频次处置（归 `02` / `06`）。
- **不拒绝上行。** 拒绝即 `sync.conflict`，而客户端按既定语义会**丢弃本地缓冲**——一次误报（时钟、并发、客户端 bug、后端实现差一位）当场变成一次玩家进度丢失，违反「绝不回退存档点」与 pillar #4。而复算的对象是**每篇章至多一次**的低价值掉落，用进度丢失去防它，比例失衡。
- **不以后端复算结果改写 profile。** 与「未知 `sourceCode` 记录原值、不改写」正面冲突，且会让客户端与云端的 Profile 在客户端不知情的情况下分叉（客户端并不重新 pull）。
- 形状与「验签失败 → 拒绝 + 上报一次」「`revision_ahead` → 处置相同但必须被观测到」一致：**异常必须可见，但不在同步热路径上做裁决。**
- **与 §5c 的判据边界（两条读起来相反，判据使它们不抵触）：** 本节管的是**客户端有权写、后端只作复算比对**的路径——值可能有争议，一次误报就是一次错误的进度丢失，故只记账；§5c 管的是**客户端根本无权写**的路径——值无争议地不属于它，正常客户端永远只提交回声，故零误报，拒绝安全。**判据是所有权，不是严格程度。**

## 8. `revision` CAS 的服务端语义：账号级线性化，不指定实现

技术栈未定 ⇒ 停在语义层（本库纪律）。契约要求的是**一个性质**，不是一种存储：

- **同一 `accountId` 上的「读 `cloudRevision` → 比对 `baseRevision` → 写 profile 并 `+1`」必须是一次线性化的读改写。** 任何实现（条件 UPDATE、事务、单分区串行）只要满足它即可。
- **绝不允许「先写 profile 再改 revision」的两步非原子形态**——中途失败会留下一个 profile 已变而 revision 未变的账号，此后每一次 push 都会被判成功却写在错误基线上。
- **跨区域：单写入区（单主）+ 只读副本。** 账号级严格单调递增的计数器在多主下无法维持，而「云端权威」这条决策的全部力量都建立在这个计数器上。跨区域延迟由客户端的非阻塞 push 通道吸收（pillar #4 已保证玩家不等待）。
- **只读副本受一条读己所写要求约束**（`purchase.md` §6）：验票写入返回之后，同一账号的任何后续 `pull` 必须不早于该次写入的结果。**滞后的只读副本因此不能无条件承接 pull**——要么该账号的读走写入区，要么读路径附带会话粘滞 / `revision` 下界等待。它排除了一部分部署形态，这是明知的代价，须在栈选型时带上（`open-questions/06-platform-stack.md`）。
- 「本地领先」（`baseRevision > cloudRevision`）→ 回 `sync.revision_ahead`，**并作为服务端指标单列**。它在服务端侧的含义是「客户端信封被改写**或后端发生过回滚**」，后者是后端自己的事故信号。

## 9. `pushId` 幂等窗口：`(accountId, pushId)` 唯一键 + 30 天 TTL

| 旋钮 | 初值 | 推导 |
|---|---|---|
| 记忆条数 | **每账号最近 200 条** | 客户端待发队列的实际上界远小于此（软阻塞闸门在 3 个事件级存档点 / 180 秒就触发）；200 条给异常态留足余量 |
| 保留时长 | **30 天** | 上界由 refresh token TTL 决定——超过 30 天未登录的设备必须重登，重登后走「先 pull 后 flush」，其待发队列的 `pushId` 不可能再以旧 `baseRevision` 到达。取相同值使两处窗口不会互相穿帮 |
| 存储形态 | `(accountId, pushId)` 唯一键 → `{ newRevision, acceptedAtUtc }` | 与 revision 的写入**同一次事务**——分开写会出现「revision 已 `+1` 但幂等记录未落」，正是重放会丢进度的那一刻 |

- **命中即返回上次结果**：`200` + `{ "newRevision": <上次的值>, "deduplicated": true }`，**不再 `+1`、不重写 profile**。
- **窗口过期后的重放是安全降级而非错误**：`baseRevision` 此时必然落后 ⇒ 回 `sync.conflict`，客户端按既定语义丢弃缓冲。**这正是窗口必须够长的理由**——过期不会造成错误接受，只会把一次重试变成一次进度丢失。
- **`receiptId` 的幂等窗口与本节不同轴，不要沿用这里的旋钮。** 本节的 30 天由客户端待发队列的存活上界推出；收据幂等的上界由「待兑现态无自动放弃」决定，且过期后果是重复发放而非一次进度丢失，故为**全局唯一键 + 永久保留**，定义见 `purchase.md` §7。
- **同一 `pushId` 携带不同 `baseRevision` 或不同 body 到达** → **不做深比对**（后端不解不透明段），一律按幂等命中回上次结果。深比对既昂贵，又会把一次客户端 bug 升级为一次进度丢失。

## 10. 限流：只设滥用阈值，不设常规节流

客户端侧的频率已被两层机制夹住（5 秒防抖 + 事件级存档点粒度，一次 AdventureEvent 以分钟计）⇒ 稳态约**每分钟 1 次上行**。因此：

- **不设常规节流**——它只会打到正常玩家，而 `Retry-After` 的重试又会把同一批数据再送一次。
- **设一个远高于稳态的滥用阈值**（初值：单账号 **60 次 / 分钟**，稳态的 60 倍），触发 → `rate.limited`（`Retryable`）+ `Retry-After`。客户端已定「退避取 `max(本地计算值, 服务端值)` + jitter」，且**限流绝不映 `Conflict`**。
- 实现与实际阈值归 `06`（落 `operations/`），契约层只声明语义——同 `auth.md` §8 的处理。

## 11. `compliance.*` 不打到同步通道（承重边界）

**`pull` / `push` 的错误清单不含任何 `compliance.*`。** 同步是后台行为，在它上面返回合规拦截会撞上 pillar #4：push 被合规拒绝时客户端只有两条既有路径可走——进待发队列退避（玩家看着「待同步 N」永远不减）或按 `Fatal` 丢弃缓冲（直接丢进度），两条都不可接受。

**合规拦截一律在 `signin`（`auth.md`）与业务端点上表达。** 这同时给 `02-account-compliance.md` 划了一条边界：它可以自由决定合规拦截的分支形态，但**不得把落点选在 `/v1/profile/*` 上**。

## 12. 数值初值表（待实测校准，落后端配置而非代码常量）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| `pushId` 记忆条数 | 200 / 账号 | 客户端闸门（3 个事件级存档点 / 180 秒）决定的实际上界远小于此 |
| `pushId` 保留时长 | 30 天 | 对齐 refresh token TTL，两处窗口不互相穿帮 |
| push 滥用阈值 | 60 次 / 分钟 / 账号 | 稳态 ~1 次/分钟的 60 倍 |
| 单账号 profile 体积软告警 | 512 KB | **借用**客户端 `pastEvent` 护栏的同一数量级作起点；**口径不同**（客户端那条是单个 `CharacterProfile` 的 `pastEvent` 条数 > 500 或序列化 > 512 KB），后端这条覆盖整聚合，须实测校准 |

## 决策(-> ADR)

- **账号级掷骰的随机源 = 契约定义的纯函数 SplitMix64**（§6）→ ADR 候选，登记于 `decisions/_index.md`。值得固化其依据（跨语言逐位一致是复算的前提，不能押在引擎实现细节上），否则「客户端本来就有 RNG，为什么另写一个」会反复被重新提出。
- **后端写入路径在上行侧只接受回声，不等即整批拒绝**（§5c）→ ADR 候选，登记于 `decisions/_index.md`。值得固化其依据（浅合并按顶层键 ⇒ 封闭表若无报文层执行点即形同虚设；CAS 问基线不问所有权），否则「CAS 已经挡住了，为什么还要比一次字段」会反复被重新提出。
- **防作弊的边界 = 可复算 `roll`、不复算阈值；不一致仅记账不拒绝**（§7 · §7a）→ ADR 候选。它是 pillar #1 在最具体处的一次兑现，也是「后端要不要持有平衡表」这个问题的永久答案。

## 备选方案（已考虑并否决）

- **后端持有残卷分档表并全量验算命中** — 把随 overlay 热更的平衡表复制到后端（第二份真值 + 必然漂移），与 pillar #1 / #5 同时相悖；还缺「本次是哪一篇章」这个输入。
- **复算不一致 → 拒绝上行** — 一次误报 = 一次玩家进度丢失（客户端按 `Conflict` 丢弃缓冲），用它去防每篇章至多一次的低价值掉落，比例失衡。
- **复算不一致 → 以后端值改写 profile** — 与「不改写」纪律冲突，且让两侧 Profile 在客户端不知情时分叉。
- **校验 ② 保持双向等价** — 会被两条既定客户端规则证伪（首胜 100%、候选池取尽后静默停摆），在正常账号上误报。
- **客户端再上报一个「本次结局」字段以保住双向等价** — 多一条透明路径即多一条路径稳定性约束，而该字段同样由客户端产出、同样不可验真，等于用真实的契约刚性换一个不增加保证的声明。
- **在 profile 里存掷骰历史列表供后端离线核对** — CAS 已保证串行、每次胜利必有一次 push ⇒ 「最近一次」两个字段等价；列表随账号年龄单调增长。
- **`accountSeed` 作为 JSON number 下发** — 超 2⁵³ 静默丢低位，逐位复算当场失效，且只在部分账号上显形。
- **账号级掷骰继续用 Godot `RandomNumberGenerator`** — 引擎升级可能改变其序列语义，而两侧逐位一致是复算成立的前提。
- **向量表只给 `roll`、不给三个 `Next()` 输出**（§6a） — 只验第一格：`roll` 是 `mod 10000` 后的值，把 64 位输出压成 4 位十进制，约 2⁵⁰ 分之一的错误实现会碰巧对上；且完全不覆盖「连续抽多条」时的流状态推进。
- **向量表只给边界的 1–2 组**（§6a） — 顺序判别对与相邻 `ordinal` 对正是最易差一位的两处，都不是边界值能覆盖的。
- **向量数值写进两侧各自的测试代码，不建共享文件**（§6a） — 抄错即静默失效，而失效形态就是作弊窗口。
- **向量随机生成、每次实现时各自重算**（§6a） — 那不是验收物而是同义反复：两侧各自重算只会各自自洽。
- **`accountSeed` / `next` 在向量文件中走十进制数字或十进制字符串**（§6a） — 数字形态超 2⁵³ 静默丢低位（`envelope.md` §2 已就此立判据）；十进制字符串不定长、与「种子是一段比特」的语义不符，且与 §2 已定的报文 hex 表示不一致，等于在同一个值上放两种写法。
- **把向量文件放进 `contracts/schemas/`** — 它不是报文形态，`_index.md` 的两条拆分判据都不满足，故 `vectors/` 单开。
- **另立一张 `Mix()` 单函数的向量表** — 与 §6a 的检查点重复：`Next()` 的输出已完全暴露 `Mix` 的正确性，多一张表多一处需同步维护的真值（标准 SplitMix64 的公开自测值以**非规范性提示**的形式记在 §6a，不构成第二份真值）。
- **只靠 `revision` CAS 挡住后端写入路径的覆写**（§5c） — CAS 问基线不问所有权：客户端把某条后端写入路径写成常量，在基线正确时会被原样接受，而后端写入字段表将永远没有执行点。
- **字段级挑拣：忽略客户端提交的后端写入路径、接受其余**（§5c） — 要求后端在顶层键内部做字段级合并，动摇 §3a「不递归、不逐元素合并」的分段。
- **为回声校验新增专用错误码**（§5c） — 客户端处置与 Conflict 完全一致，新码只逼它多写一条走向同一处的分支；可观测性由风控事件承担。
- **把 `bundleRedeemedOrdinal` 提为另一个顶层键以避开整键替换**（§5c） — 能绕开这一处的表现，却把一对语义紧邻的字段拆到两个顶层键，且 `/accountInfo` 仍是同一形状——需要的是一条通则，不是搬家。
- **按顶层键统一处置**（键内任何不一致都拒绝）（§5c） — 会把 `bundleRedeemedOrdinal` 的越界从「记账」升为「丢进度」，与 §7a 正面冲突；判据必须逐路径按所有权判。
- **另立一张「受回声校验约束的 path」清单**（§5c） — 与后端写入字段表必然漂移，而漂移形态正是「进了写入表却没进回声表」；恒等式使这张表不必存在。
- **回声值按原始字节相等比较**（§5c） — 把序列化器实现细节抬成契约；`createdAtUtc` 的合法表示差异会让正常账号稳定被拒，症状是「所有玩家改昵称都丢一次进度」。
- **`createdAtUtc` 按字面逐字相等**（§5c） — 要求客户端对该 path 原样透传 pull 到的字符串、永不经强类型往返；它把一条本可由后端一次解析消化的风险，压成客户端一条必须永远记得的纪律。
- **`identities` 按集合相等（忽略顺序）**（§5c） — 更宽松但无收益：顺序由后端产出、客户端原样回声，宽松只会掩盖客户端的重排 bug。
- **用 JSON Schema 表达回声约束**（§5c） — schema 表达不了「等于当前云端值」；强行表达只能退化为把这些 path 标成必填，而浅合并 diff 里它们本就常常不出现。
- **回声校验放在 CAS 之前**（§5c） — 无收益且更贵：CAS 失败时本就整批拒绝，先做字段比较是白做。
- **RFC 7386 JSON Merge Patch 作为 diff 合并语义** — 以 `null` 表示删除，与 `envelope.md` §2 冲突；且要求后端递归遍历不透明结构。
- **`playerDiff` 段级全量替换** — 每次 push 重传整个账号级段，与「整聚合上行不可持续」这条既定理由同向相悖。
- **把 `characterDiffs` 也做成透明段** — 无后端规则用途，且每条透明路径都要背上路径稳定性约束。
- **把 `statistics` 列进透明子集** — 等于给「拿统计驱动活动奖励」开门，当场推翻宽松同步口径的全部前提。
- **pull 也判定强更闸门 / `schemaVersion` 闸门** — 造出第二个闸门与第二套阈值，违反 `envelope.md` §7b。
- **push 设常规节流** — 只打到正常玩家，且重试会把同一批数据再送一次。
- **`pushId` 命中时对 body 做深比对** — 后端不解不透明段（pillar #1），且会把一次客户端 bug 升级为一次进度丢失。
- **`accountId` 走 query / body** — 唯一用途是造出「与 token 不一致」这个越权分支。
- **多主写入 / 跨区域双写 `revision`** — 账号级严格单调递增计数器在多主下无法维持，而云端权威的全部力量都建立在它上面。
- **`compliance.*` 打到 `/v1/profile/*`** — 客户端只有「永远不减的待同步」或「丢进度」两条路可走，与 pillar #4 相抵。

## Open questions

- **风控事件的落地形态**（结构化事件的字段、累计频次的处置阈值）——归 `02` / `06`，落 `operations/`。契约层只声明「必须上报、不在热路径裁决」。
- **CAS 的具体存储、幂等记录的存储、限流实现与实际阈值、跨区域拓扑**——全部归 `06`，落 `operations/`，**不回头改契约**。

## 客户端侧的对位

本契约要求于客户端的全部对位改动（两个新字段与其写入约定 · `accountSeed` 的 hex 表示 · 透明路径稳定性纪律 · `sourceCode` 的边界映射 · 随机源换 SplitMix64 · diff 与 §3a 浅合并对齐）已在客户端库落笔，权威在 `game-design-documents/systems/common-properties.md`、`systems/services/sync-service.md` 与 `systems/player-profile/_index.md`。**本库不复述它们的客户端形态**；若两侧就任一条的措辞不一致，以本文件为准（契约权威在本库）。
