---
type: solution-draft
date: 2026-08-13
question: `contracts/profile-sync.md` 的报文本体——两端点报文、负载信封字段表、三分支应答，以及「后端可见字段子集」的逐字段清单（连带其前置：`AccountSeed` 复算协议、`pushId` 幂等窗口、`revision` CAS 的服务端语义）
source: open-questions/01-contracts.md → 「`profile-sync.md` 尚未成文（最后一份）」；耦合子问题取自 open-questions/03-sync-conflict.md 前三条
targets: contracts/profile-sync.md（新建）· contracts/envelope.md（§2 补一条大整数约定 · §8 的可见性表回链）· contracts/_index.md（状态表）· open-questions/01-contracts.md · open-questions/03-sync-conflict.md
status: distilled
decided: 2026-08-14
reviewed: 2026-08-14 —— 用户逐项裁决五项（SplitMix64 随机源 · 强复算 · `SourceCode` 收口① · `accountSeed` hex 字符串 · `compliance.*` 不打同步路径）
distilled-to: `handoffs/2026-08-14-profile-sync-contract.md`
---

> **本草稿已提炼（2026-08-14）。** 提炼时的 interview **推翻了草稿两处写法**：§5 的复算校验 ②③（双向等价 → **单向蕴含 + 三条写入约定**，因草稿写法会被「首胜 100%」「池空静默停摆」「重置为 `Base(x+1)`」三条既定客户端规则证伪）与 §3 未定义的 **diff 合并语义**（补为**顶层键粒度浅合并**）。**权威以 `contracts/profile-sync.md` 为准**，本文件只作原始措辞的溯源留存。

# 方案草稿 — `profile-sync.md` 报文本体与后端可见字段子集

## 问题

`profile-sync.md` 是**最后一份端点契约**。缺的是四样东西：

1. `GET /v1/profile/pull` 与 `POST /v1/profile/push` 的**报文本体**；
2. 负载信封（`pushId` · `baseRevision` · `schemaVersion` · `reason`）的**字段表**；
3. CAS **三分支应答**的报文形态（成功 / 落后 / 领先）+ 幂等命中这第四种情形；
4. **「后端可见字段子集」的逐字段清单**——`envelope.md` §8 已定 Profile 分三段可见（负载信封透明 · 可见字段子集透明 · 其余不透明），但没说**哪些字段属于第二段**。

第 4 项被 `03-sync-conflict.md` 的 **`AccountSeed` 复算协议**卡着：不知道后端要复算什么、复算到什么强度，就列不出它需要看见什么。因此本草稿把 `03` 的前三条（`revision` CAS 服务端语义 · `pushId` 幂等窗口 · `AccountSeed` 复算）作为**耦合子问题**一并推演——它们不可分开定稿。

本草稿在推演中发现了**三处此前未被任何文档覆盖的承重缺口**（`accountSeed` 的 JSON 数字精度、Godot RNG 的跨语言复现、透明字段的路径稳定性），分别在 §建议方案 2 / 5 / 4 中给出。

## 约束（来自既有设计）

- **序列化与信封**：lowerCamelCase · 枚举值 = 客户端 C# 枚举名逐字相同 · 不下发 `null` · 时间 RFC3339 UTC 带 `Z` 且以 `AtUtc` 结尾 · 未知字段两侧都忽略 · `revision`（`long`）不转字符串。→ `contracts/envelope.md` §2。
- **传输信封走 HTTP 头，负载信封留 push body 顶层段**；`baseRevision` / `pushId` 不搬到头、不用 `If-Match`/ETag。→ `envelope.md` §4。
- **Profile 三段可见性**：不透明段后端**不得**结构校验、不得改写、不得因其内部变化拒绝上行；只在 `schemaVersion` 越出兼容集合时拒绝。→ `envelope.md` §8。
- **错误体与台账**：`code` 是客户端映射表的键，`class` 固定不因请求而变；`sync.conflict` / `sync.revision_ahead` / `sync.payload_schema_unsupported` / `sync.payload_invalid` / `rate.limited` 五条已登记，`detail` 形状已定。→ `envelope.md` §5 §6。
- **CAS 三分支与 `pushId` 幂等的客户端语义已定案**（2026-08-09）：`baseRevision == cloudRevision` → 接受 `+1` 回 `newRevision`；`<` → 拒绝回当前值；`>` → 不可能态、同处置 + 上报。重复 `pushId` **不再 `+1`**，直接回上次结果（`newRevision` + `Deduplicated`）。→ `game-design-documents/systems/services/sync-service.md`。
- **客户端已定 record 一字不改**：`ProfilePayload` / `PushAck(NewRevision, Deduplicated)` / `ProfileSnapshot(Profile, Revision, SchemaVersion)`；diff 粒度 = `CharacterProfile`。→ 同上。
- **`AccountSeed` 不走 auth 应答，定稿在本文件**：后端在账号创建时生成并写进该账号 profile，客户端在启动 pull 中拿到。→ `contracts/auth.md` §11。
- **账号级 RNG 已于 08-12e 加具名域**：`seed = Hash64(AccountSeed, (ulong)stream, (ulong)ordinal)`，`AccountStream { PowerFragment, PremiumBundle }`——**复算契约因此比 `03` 分片记录的两参数形态多一个参数**（该分片的措辞已过时）。→ `game-design-documents/systems/common-properties.md`。
- **统计计数层：后端不复算、不校验，且不得用统计数据驱动任何发放。** 一旦这么用该字段必须整体升为规则字段。→ `sync-service.md` 宽松五条 · `envelope.md` §8。
- **`SourceCode` 未知取值：记录原值、不改写、不拒收。** 归一为 `Unknown` 并回写会压低 `x`、让残卷档位回跳，推翻客户端「`x` 单调不减」的承重不变式。→ `handoffs/2026-08-12-grant-source-code-contract.md`。
- **pillar #1 后端不重跑玩法** · **#2 幂等重于优雅** · **#4 不阻塞玩家** · **#5 线上可干预（内容 overlay 热更，不冻结 `contentVersion`）**。

## 建议方案

### 1. 端点形态：pull 是 `GET`（无 body、账号取自 token），push 是 `POST`

`[既有推演]` `envelope.md` §4 在论证「传输信封为什么走头」时已把 `/v1/profile/pull` 列为「没有 body 的 GET 端点」——路径与动词实际上已被定死，本文件只需写明。

- `accountId` **不进 query、不进 body**：它由 access token 唯一确定。放进请求参数即造出「token 与参数不一致」这个分支，而它的唯一用途是越权拉取别人的存档。
- 客户端 `PullProfileAsync(accountId, ct)` 的 `accountId` 参数由 `HttpProfileBackend` 用于**本地断言**（与 `Session.AccountId` 比对），不上行——与「切账号即失效」的信封纪律同源。

### 2. pull 应答：三字段，`profile` 整段不透明

`[既有推演]` 对位客户端已定 `ProfileSnapshot(Profile, Revision, SchemaVersion)`，一字不多。

```json
{
  "revision": 137,
  "schemaVersion": 7,
  "profile": { "…": "客户端定义的 PlayerProfile 序列化形态，后端原样存取" }
}
```

**新账号的初始 profile 骨架 = 只有一个字段。** 后端在账号创建时写入：

```json
{ "accountInfo": { "accountSeed": "9f2c1a77b30e45d1" } }
```

`[既有推演]` 后端不懂 Profile 结构（pillar #1），因此它能写的只有**它自己生成的那个值**；其余默认字段由客户端在 `isNewAccount` 时本地构造并随首次 push 补齐。初始 `revision = 1`（账号创建即一次写入），客户端 `baseRevision` 初值 `0` ⇒ 首次 pull 必然推进，不需要「空 profile」这个分支。

**⚠ 承重发现：`accountSeed` 必须是字符串，不能是 JSON number。** `envelope.md` §2 定「整数不转字符串」，其论据是「`revision` 一生也到不了 2⁵³」。**`AccountSeed` 是 `ulong` 随机数，几乎必然超出 2⁵³**——JSON number 在双精度实现里会静默丢低位，而它是**逐位复算的输入**：丢一位则客户端与后端算出不同的 `roll`，且这个 bug 只在部分账号上显形。

**定案（2026-08-14）：`accountSeed` 以 16 位小写十六进制字符串下发**（无 `0x` 前缀，定长便于校验），并在 `envelope.md` §2 把那条通则**补一个判据**（不是开例外）：「整数走 JSON number，**除非取值域可能超出 2⁵³——那一类一律字符串**」。补判据与 §2 原论证同源（`revision` 之所以能用 number，理由恰是「一生到不了 2⁵³」）。选 hex 而非十进制字符串：定长 + 与「种子是一段比特」的语义相符 + 不会被中间层当数字重新解析。

### 3. push 请求：负载信封四字段 + 两段 diff

`[既有推演]` 对位客户端已定 `ProfilePayload`（`ContentVersion` / `AppVersion` 两项搬到 HTTP 头，见 `envelope.md` §4b）。

| 字段 | 类型 | 必填 | 语义 | 客户端对位 |
|---|---|---|---|---|
| `pushId` | string (GUID) | ✅ | 幂等键。**批次组装时生成一次，跨启动重试保持不变** | `ProfilePayload.PushId` |
| `baseRevision` | number (long) | ✅ | CAS 前置条件。`0` = 本设备尚无云端确认 | `.BaseRevision` |
| `schemaVersion` | number (int) | ✅ | **存档负载**自身的版本（≠ URL `/v1/`） | `.SchemaVersion` |
| `reason` | string | ✅ | `SavePointReason` 枚举名逐字：`"CycleStarted"` / `"EventResolved"` / `"ChapterBoundary"` / `"CycleEnded"` / `"MetaChanged"` | `.Reason` |
| `playerDiff` | object | ✅ | 账号级 diff。**含透明子集**（§4） | `.PlayerDiff` |
| `characterDiffs` | array | ✅ | 每项 `{ characterId, diff }`。**整体不透明** | `.CharacterDiffs` |

- `reason` 对后端是**日志与聚合维度**，不驱动任何判定——判定只看 `baseRevision` 与 `pushId`。写明这一点，否则它迟早会被拿去做分支。
- **空 diff 不是错误**：`playerDiff: {}` + `characterDiffs: []` 照常接受并 `+1`（客户端的防抖窗口可能合成出空批次）。拒绝它等于给客户端加一条它无法预防的失败路径。
- `characterDiffs` 走数组而非以 `characterId` 为键的对象：键名是玩家数据，做 JSON 对象键会让 schema 无法表达、也不便于后端流式处理。

### 4. 后端可见字段子集：**按 JSON path 逐条列白名单**

`[既有推演]` 这是本契约最要紧的一段。三条纪律：

- **未在下表出现的一切字段都是不透明段**——不用另写一份「不可见清单」，白名单的补集即是。
- **后端对透明段同样只读**（唯一写入是账号创建时的 `accountSeed`，见 §2）。透明 ≠ 可改写。
- **⚠ 承重：透明字段的 JSON path 是契约的一部分。** 客户端把 `playerPowerFragment` 挪个位置、或把 `sourceCode` 改个字段名，在客户端侧是纯重构、老档还能靠迁移无损通过，但**在后端侧会静默变成「这个字段消失了」**——复算退化为空操作，且没有任何一侧会报错。因此：**移动或重命名任一透明字段的路径 = 破坏性契约变更，必须 bump `schemaVersion` 并与后端同批改**，与「重命名跨边界枚举值即破坏性变更」（`sync-service.md`）同一条纪律。建议后端对**缺失的透明路径**一律 `PushWarning` 级记账（不拒绝上行），使这类漂移在线上可见。

| JSON path（相对 `profile` / `playerDiff` 根） | 类型 | 后端用途 |
|---|---|---|
| `/accountInfo/accountSeed` | string(hex16) | 复算输入；**后端唯一写入的字段** |
| `/playerPowerFragment/accumulated` | number int `[0,10000]` | 区间与变化方向的不变式校验 |
| `/playerPowerFragment/finaleWinOrdinal` | number int | 复算的 `ordinal`；单调 `+1` 校验 |
| `/playerPowerFragment/ch1FirstWinDone` · `ch2…` · `ch3…` | boolean | 单调 `false → true` 校验 |
| `/playerPowerFragment/lastRoll` | number int `[0,9999]` | **建议新增**：逐位比对（§5） |
| `/playerPowerFragment/lastEffectiveChance` | number int `[0,10000]` | **建议新增**：命中自洽校验（§5） |
| `/playerPowers[*]/id` | string | `x` 的计数对象 |
| `/playerPowers[*]/sourceCode` | string enum | `x = count(sourceCode == "FinaleWin")` |

**明确落在不透明段的（各有理由）：**

- `/playerPowers[*]/status`、`disabledAbility` —— **生效维度不是持有维度**，不影响 `x`（08-10c 已定）。
- `/playerItems`、六个 Codex、`achievement` —— 无后端规则用途。
- `/statistics`（`PlayerStatistics`）—— **明确不透明**，兑现「后端不复算、不校验、不得驱动发放」。把它列进透明档等于给「拿统计驱动活动奖励」开一道门，而那会当场推翻宽松同步口径的全部前提。
- `characterDiffs` **整体**（含轮回级的 `SourceCode`）—— 答结 `handoffs/2026-08-12-grant-source-code-contract.md` 的第三条 open question：**轮回级两类的 `SourceCode` 不进透明档**。它对后端无规则用途（纯透传），而每多一条透明路径就多一条 §4 的路径稳定性约束。
- `bundleGrantOrdinal`（礼包域的账号级序号）—— **落点在客户端尚未定**（`monetization.md` 的「付费凭证存档表达」待答），见 §前置依赖。表中**预留一行**，落定后按同形态补入。

### 5. `AccountSeed` 复算协议：可复算的是 `roll`，**不是阈值**

`[既有推演 · 本草稿的核心判断]` 「后端可离线复算」这句已定案语义此前从未被拆开。拆开后是两件性质完全不同的事：

| | 后端能不能做 | 依据 |
|---|---|---|
| 由 `(AccountSeed, PowerFragment, ordinal)` 算出 **`roll`** | **能**，且必须能——这正是种子放后端的全部意义 | 纯函数，输入全在透明子集里 |
| 判定 **是否命中**（`roll < 生效概率`） | **不能可靠地做** | 生效概率 = `clamp(Accumulated, Base(x), Cap(x))`，而 `Base` / `Cap` 是**按 `(x, chapter)` 分档的内容数值表**（`systems/balance.md`），随 overlay 热更、**且不冻结 `contentVersion`** |

**因此明确否决「后端持有分档表并全量验算」**：那是把一张随时热更的平衡表复制到后端，制造第二份真值 + 必然的版本漂移，且与 pillar #1（不重跑玩法）、pillar #5（改数值不需要发版）同时相悖。后端还缺一个输入——**这次 Finale 是哪一篇章**（非首胜时首胜布尔不变，篇章不可推断），补它又要再加一条透明路径。

**定案的复算协议（2026-08-14 · 取「强复算」：客户端上报两个数，后端做三条校验）：**

```
客户端在 Finale 胜利结算时，把本次掷骰的两个中间值一并落 PlayerPowerFragment：
  lastRoll            = AccountRng.For(PowerFragment, finaleWinOrdinal).Randi() mod 10000
  lastEffectiveChance = clamp(Accumulated, Base(x), Cap(x))     // 掷骰当刻的生效概率

后端在 finaleWinOrdinal 递增的那一次 push 上：
  ① 自算 roll' = f(accountSeed, PowerFragment, finaleWinOrdinal)，校验 roll' == lastRoll   ← 抓种子篡改 / 序号刷 / 换设备重掷
  ② 校验「本次是否新增一条 sourceCode == FinaleWin 的法则」⟺ (lastRoll < lastEffectiveChance)  ← 抓命中结论造假
  ③ 校验结构不变式：finaleWinOrdinal 恰 +1 · accumulated ∈ [0,10000] · 首胜布尔单调 · x 单调不减 · 命中时 accumulated 被重置（变小）/ 未命中时不减
```

- **不需要历史列表**：`revision` CAS 保证上行严格串行，且每次 Finale 胜利必然产生一次 push（`EventResolved` 是自动存档点），所以「最近一次」两个字段就够——这也正是 08-09b「不需要跨轮回的待发放字段」那条结构性简化的同构延伸。两个 `int`、非列表、老档补默认值 ⇒ **零迁移成本**。
- **② 是这套协议真正的价值**：它不需要后端知道任何数值表，却把「谎报命中」这条最直接的作弊路径关死了——因为 `lastEffectiveChance` 一旦被抬高以配合谎报的命中，就会在 ③ 的 `accumulated` 一致性上露出来。
- **代价明写**：`lastEffectiveChance` 本身后端无法验真，所以「篡改客户端把生效概率写成 10000」这条路仍然通——它被 ③ + 风控接住，不被复算接住。这是 pillar #1 下的必然取舍，写清楚好过假装覆盖。

### 5a. 随机源 = 契约定义的纯函数 SplitMix64（定案 · 2026-08-14 · 承重）

**账号级掷骰不再走 Godot 的 `RandomNumberGenerator`，改用契约定义的纯函数。** 理由：跨语言逐位一致是复算成立的**前提**，把它押在引擎实现细节上，等于让「Godot 升级」成为一次潜在的静默作弊窗口——而客户端自己已为 `RandomNumberGenerator.State` 写过同一条警告（`common-properties.md`：「`State` 是引擎实现细节，Godot 升级可能改变其语义」）。**轮回级 RNG 完全不受影响**（不跨边界，继续用 Godot RNG）。

**算法（契约的一部分，两侧逐位一致）。** 全部运算为 `uint64` 环上运算（溢出自然回绕），`>>` 为逻辑右移：

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

- **`stream` 的整数取值随 `AccountStream` 的 C# 成员序固定**（`PowerFragment = 0` · `PremiumBundle = 1`），**取值一经写入契约即冻结**——与 `Source` 的「名与 code 双双永不复用」同一条纪律。新增域只能追加。
- **`+1` 是对全零输入的防御**（`stream = 0` 且 `ordinal = 0` 时不塌缩为一次纯 `Mix(accountSeed)`），两侧必须一致；差一位就整条序列不同。
- **不做拒绝采样**：`mod 10000` 的模偏差 < 2⁻⁵⁰，而拒绝采样会让「抽取次数不定」，使连续抽的序列在两侧更难对齐——为一个不可观测的偏差换来一条真实的对齐风险，不划算。
- **测试向量是契约的验收物**：`profile-sync.md` 内附一张 `(accountSeed, stream, ordinal) → 前 3 个 Next() 输出 + roll` 的向量表（建议 8 组，含 `accountSeed = 0` / 全 F 两个边界）。**两侧各自实现后必须逐位对上这张表**——它是本条纪律唯一可执行的检查点。
- **⚠ 客户端侧的真实改动面（跨库待办，不是纯内部替换）**：Godot 的 `RandomNumberGenerator` 是引擎类型，无法注入外部序列 ⇒ `AccountRng.For(...)` 的**返回类型**须换成项目自有的小类型（如 `AccountRandom`，暴露 `Randi()`），连带 `DrawPool.PickOne(rng, …)` / `PickMany(rng, count)` 的参数类型放宽。**调用点的形状不变**（仍是一次派生、连续抽、由 `(stream, ordinal)` 完全确定），**幂等语义与全部既有推论一字不动**，但这是一次真实的类型改动，须写进客户端 handoff。

### 6. 复算不一致时的处置：**仅记账 + 上报风控，不拒绝、不改写**

`[既有推演]` 三条候选里另外两条各自撞上一条已定纪律：

- **拒绝上行（`Conflict`）** → 客户端按既定语义**丢弃本地缓冲**，一次误报（时钟、并发、客户端 bug、后端复算实现差一位）当场变成一次玩家进度丢失，违反「绝不回退存档点」与 pillar #4。而复算的对象是**每篇章至多一次**的低价值掉落，用进度丢失去防它，比例失衡。
- **以后端复算结果改写** → 与 `SourceCode` 那条「记录原值、不改写、不拒收」正面冲突，且会让客户端与云端的 Profile 在客户端不知情的情况下分叉（客户端并不重新 pull）。

**建议：接受写入 → 打一条结构化风控事件（账号 · `finaleWinOrdinal` · 期望值 · 实收值 · `requestId`）→ 交由风控（`02` / `06`）按累计频次处置。** 与「验签失败 → 拒绝 + 上报一次」「`revision_ahead` → 处置相同但必须被观测到」同一形状：**异常必须可见，但不在同步热路径上做裁决。** 复算命中率是 `06` 已点名的两个同步正确性探针之一。

### 7. `revision` CAS 的服务端语义：账号级线性化，不指定实现

`[既有推演]` 技术栈未定 ⇒ 停在语义层（本库纪律）。契约要求的是**一个性质**，不是一种存储：

- **同一 `accountId` 上的「读 `cloudRevision` → 比对 `baseRevision` → 写 profile 并 `+1`」必须是一次线性化的读改写**，任何实现（条件 UPDATE、事务、单分区串行）只要满足它即可。
- **绝不允许「先写 profile 再改 revision」的两步非原子形态**——中途失败会留下一个 profile 已变而 revision 未变的账号，此后每一次 push 都会被判成功却写在错误基线上。
- **跨区域：建议单写入区（单主）+ 只读副本**。账号级严格单调递增的计数器在多主下无法维持，而「云端权威」这条决策的全部力量都建立在这个计数器上。跨区域延迟由客户端的非阻塞 push 通道吸收（pillar #4 已保证玩家不等待）。
- 「本地领先」（`baseRevision > cloudRevision`）→ 回 `sync.revision_ahead`，**并作为服务端指标单列**（`06` 点名的第二个探针）。它在服务端侧的含义是「客户端信封被改写**或后端发生过回滚**」，后者是后端自己的事故信号。

### 8. `pushId` 幂等窗口：`(accountId, pushId)` 唯一键 + **30 天** TTL

`[通行做法 + 既有推演]` 形态与初值：

| 旋钮 | 建议初值 | 推导 |
|---|---|---|
| 记忆条数 | **每账号最近 200 条** | 客户端待发队列的实际上界远小于此（软阻塞闸门在 3 个事件级存档点 / 180 秒就触发）；200 条给异常态留足余量 |
| 保留时长 | **30 天** | 上界由 refresh token TTL 决定——**超过 30 天未登录的设备必须重登**，重登后走「先 pull 后 flush」，其待发队列的 `pushId` 不可能再以旧 `baseRevision` 到达。取相同值使两处窗口不会互相穿帮 |
| 存储形态 | `(accountId, pushId)` 唯一键 → `{ newRevision, acceptedAtUtc }` | 与 revision 的写入**同一次事务**——分开写会出现「revision 已 +1 但幂等记录未落」，正是重放会丢进度的那一刻 |

- **命中即返回上次结果**：`200` + `{ "newRevision": <上次的值>, "deduplicated": true }`，**不再 `+1`、不重写 profile**。
- **窗口过期后的重放是安全降级而非错误**：`baseRevision` 此时必然落后 ⇒ 回 `sync.conflict`，客户端按既定语义丢弃缓冲。**这正是窗口必须够长的理由**——过期不会造成错误接受，只会把一次重试变成一次进度丢失。
- **同一 `pushId` 携带不同 `baseRevision` 或不同 body 到达** → 不做深比对（后端不解不透明段），一律按幂等命中回上次结果。深比对既昂贵又会把一次客户端 bug 变成一次进度丢失。

### 9. 三分支应答的报文（含幂等命中这第四种情形）

| 情形 | HTTP | body |
|---|---|---|
| `baseRevision == cloudRevision` | `200` | `{ "newRevision": 137, "deduplicated": false }` |
| **`pushId` 命中幂等窗口** | `200` | `{ "newRevision": 137, "deduplicated": true }` |
| `baseRevision < cloudRevision` | `409` | `error.code = "sync.conflict"`，`detail = { "cloudRevision": 137 }` |
| `baseRevision > cloudRevision` | `409` | `error.code = "sync.revision_ahead"`，`detail = { "cloudRevision": 137 }` |

- 对位客户端 `PushAck(NewRevision, Deduplicated)`，一字不多。
- **状态码只承担传输层语义**，客户端一律按 `code` 分支（`envelope.md` §5b）；两条 `409` 共用状态码正说明为什么必须有 `code`。
- `schemaVersion` 越出兼容集合 → `sync.payload_schema_unsupported`（`Upgrade`，**不硬阻塞**，`detail.supportedSchemaVersions`）；**判定发生在 CAS 之前**（版本不兼容时不应消耗 revision）。
- 负载信封字段缺失 / 类型不合法 → `sync.payload_invalid`（`detail.field` 给 JSON path）。**注意：不透明段内部的任何结构问题都不得触发这一条**——它只覆盖信封本身。

### 10. pull 侧不做版本闸门

`[既有推演]` 云端 `schemaVersion` 高于客户端支持上界这一情形，**已由客户端迁移器承担**（`sync-service.md` 08-12：走阻塞屏的「需更新」变体）。后端 pull **原样返回**、不判定、不拒绝。理由是 `envelope.md` §7b 的同一条：闸门只在登录与启动 pull 的**服务端强更判定**处生效，而那一条由 `signin` 的 `client.version_unsupported` 独占。让 pull 也判一次即出现两个闸门、两套阈值。

### 11. push 的限流：只设滥用阈值，不设常规节流

`[既有推演]` 客户端侧的频率已被两层机制夹住（5 秒防抖 + 事件级存档点粒度，一次 AdventureEvent 以分钟计）⇒ 稳态约**每分钟 1 次上行**。因此：

- **不设常规节流**——常规节流只会打到正常玩家，而 `Retry-After` 的重试又会把同一批数据再送一次。
- **设一个远高于稳态的滥用阈值**（建议初值：单账号 **60 次 / 分钟**，即稳态的 60 倍），触发 → `rate.limited`（`Retryable`）+ `Retry-After`。客户端已定「退避取 `max(本地计算值, 服务端值)` + jitter」，且**限流绝不映 `Conflict`**。
- 实现与实际阈值归 `06`（落 `operations/`），契约层只声明语义——同 `auth.md` §8 的处理。

### 12. `SourceCode` 的线上表示：收口①（定案 · 2026-08-14）

`handoffs/2026-08-12-grant-source-code-contract.md` 点明的冲突（`envelope.md` 定「枚举一律字符串名」vs 客户端定「`code` 整数是上行负载里实际序列化的东西」）**已裁决为收口①：契约侧走字符串枚举名（`"FinaleWin"`），存档侧走整数 code，客户端在序列化边界做一次映射。**

- 依据：**通则不开例外的价值高于重命名自由**，而重命名本就极少发生；`Source` 的成员本就已定「名与 code 双双永不复用」，故契约侧的字符串名同样是冻结量。
- **连带纪律**：`Source` 的**成员名与 code 双双冻结**——存档侧靠 code、契约侧靠名，两者各自都是稳定键，重命名成员在**两侧都是**破坏性变更。
- **连带修正（客户端侧）**：`systems/common-properties.md` 里「code 是上行负载里实际序列化的东西」那句需改为「code 是**存档**里实际序列化的东西；**上行负载走枚举名**，由序列化边界一次映射」。那句写在 `envelope.md` 成文之前。
- 由此 §4 白名单里 `/playerPowers[*]/sourceCode` 的类型定为 **string enum**（取值与客户端 C# `Source` 成员名逐字相同），**未知取值照既定纪律记录原值、不改写、不拒收**。

## 具体形态（可 derive 的落地面）

**建议的 `contracts/profile-sync.md` 章节骨架**（与 `auth.md` 同形）：

```
1. 端点集：两个，封定（GET pull / POST push）
2. pull 报文（含新账号骨架与 accountSeed 的下发通道 → 答结 auth.md §11 的留白）
3. push 报文：负载信封字段表 + 两段 diff
4. 三分支 + 幂等命中的应答表
5. Profile 可见字段子集：JSON path 白名单 + 三条纪律（含路径稳定性）
6. AccountSeed 复算协议：可复算 roll / 不复算阈值 + 三条校验
7. 复算不一致的处置：记账 + 风控，不拒绝不改写
8. revision CAS 的服务端语义（线性化要求，不指定实现）
9. pushId 幂等窗口（初值表）
10. 限流语义
11. 数值初值表（可调旋钮，落配置非代码常量）
12. 决策(-> ADR) / 备选方案 / Open questions / 跨库待办
```

**数值初值表（待实测校准，落后端配置）：**

| 旋钮 | 初值 | 推导 |
|---|---|---|
| `pushId` 记忆条数 | 200 / 账号 | 客户端闸门（3 个事件级存档点 / 180 秒）决定的实际上界远小于此 |
| `pushId` 保留时长 | 30 天 | 对齐 refresh token TTL，两处窗口不互相穿帮 |
| push 滥用阈值 | 60 次 / 分钟 / 账号 | 稳态 ~1 次/分钟的 60 倍 |
| 单账号 profile 体积软告警 | 512 KB | 直接沿用客户端既定的软上限护栏口径，两侧同一个数 |

**新增错误码：无。** 五条 `sync.*` + `rate.limited` 已在 `envelope.md` §6 台账中，形状与 `detail` 均可原样使用——这是边界层先成文带来的直接收益。

## 后果

- **`contracts/` 就此成文完毕**（`envelope` + `content-manifest` + `auth` + `profile-sync`），契约面无第五份。`contracts/_index.md` 的状态表与 `open-questions.md` 的「当前焦点」需整体改写。
- **`03-sync-conflict.md` 的前三条随之答结**，余下两条（上行负载版本化的其余部分、自动存档点频率的服务端约束）已被 §3 / §11 覆盖 ⇒ 该分片可能整片清空。
- **`envelope.md` 需两处小改**：§2 补「超 2⁵³ 的整数走字符串」；§8 的可见性表在第二段回链本文件 §5 的白名单。
- **`auth.md` §11 的留白被填上**（`AccountSeed` 下发 = 账号创建时写 profile 骨架 + 启动 pull 下行）。
- **跨库待办（客户端侧，需另写一份 handoff · 五项全部因本次裁决而确定要做）**：
  ① `PlayerPowerFragment` 新增 `lastRoll` / `lastEffectiveChance` 两个 `int`（零迁移，老档补默认）；
  ② `AccountSeed` 的客户端表示改为 hex 字符串解析（存档内可继续存 `ulong`，映射发生在序列化边界）；
  ③ 透明字段的**路径稳定性**纪律进客户端存档约定（移动/重命名任一透明路径 = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改）；
  ④ `SourceCode` 收口①的落地：序列化边界的 code ↔ 名映射、「名与 code 双双冻结」纪律、`common-properties.md` 那句话的修正；
  ⑤ **`AccountRng` 换随机源**（§5a）——SplitMix64 实现 + 测试向量对表，**并含返回类型改动**（`RandomNumberGenerator` → 项目自有 `AccountRandom`）与 `DrawPool.PickOne/PickMany` 参数类型放宽。调用点形状与幂等语义不变。
- **存档 schema：bump 一次，空迁移**（当前无线上存档）——与既有多次 bump 同批即可，不单独制造一次迁移。

## 备选方案（已考虑并否决）

- **后端持有残卷分档表并全量验算命中** — 把随 overlay 热更的平衡表复制到后端（第二份真值 + 必然漂移），与 pillar #1 / #5 同时相悖；还缺「本次是哪一篇章」这个输入。
- **复算不一致 → 拒绝上行** — 一次误报 = 一次玩家进度丢失（客户端按 `Conflict` 丢弃缓冲），用它去防每篇章至多一次的低价值掉落，比例失衡。
- **复算不一致 → 以后端值改写 profile** — 与 `SourceCode` 的「不改写」纪律冲突，且让两侧 Profile 在客户端不知情时分叉。
- **在 profile 里存一份掷骰历史列表供后端离线核对** — `revision` CAS 已保证串行、每次胜利必有一次 push ⇒ 「最近一次」两个字段等价；列表会随账号年龄单调增长，正是 `pastEvent` 已被立护栏防范的那种形态。
- **`accountSeed` 作为 JSON number 下发** — 超 2⁵³ 静默丢低位，复算逐位一致当场失效，且只在部分账号上显形。
- **把 `characterDiffs` 也做成透明段** — 无后端规则用途，且每条透明路径都要背上路径稳定性约束（§4）。
- **pull 也判定强更闸门 / schemaVersion 闸门** — 造出第二个闸门与第二套阈值，违反 `envelope.md` §7b「闸门在签发 token 时判定一次」。
- **push 设常规节流** — 只打到正常玩家，且重试会把同一批数据再送一次。
- **`pushId` 命中时对 body 做深比对** — 后端不解不透明段（pillar #1），且会把一次客户端 bug 升级为一次进度丢失。
- **`accountId` 走 query / body** — 唯一用途是造出「与 token 不一致」这个越权分支。
- **多主写入 / 跨区域双写 `revision`** — 账号级严格单调递增计数器在多主下无法维持，而云端权威的全部力量都建立在它上面。

## 与既有决策的张力（三条均已收口 · 2026-08-14）

1. **`envelope.md` §2「整数不转字符串」 vs `accountSeed` 的 `ulong` 取值域** → **收口 = 给通则补一个判据，不开例外**（「除非可能超 2⁵³」）。补的这句与 §2 原论证同源（`revision` 的理由恰是「一生到不了 2⁵³」）。**残留代价**：`schemas/*.json` 里会有两种整数表示形态，需在 §2 一次说清，并在本契约的字段表里逐个标注类型。
2. **`envelope.md` §2「枚举一律字符串名」 vs 客户端「`code` 整数是上行序列化的东西」** → **收口①**（见 §12）。通则不开例外；**残留代价**：契约侧重命名 `Source` 成员仍是破坏性变更，须靠「名与 code 双双冻结」这条纪律兜住，且客户端 `common-properties.md` 有一句话要改。
3. **「后端逐位复算」 vs 客户端掷骰走 Godot `RandomNumberGenerator`** → **收口 = 换随机源**（§5a，SplitMix64 纯函数）。**残留代价 = 客户端一次真实的类型改动**（`AccountRng.For` 返回类型 + `DrawPool.PickOne/PickMany` 的参数类型），不是纯内部替换；调用点形状与幂等语义不变，轮回级 RNG 完全不受影响。

## 前置依赖

- **`BundleGrantOrdinal` 的存档落点**（客户端 `systems/monetization.md`「付费凭证的存档表达」待答）→ `PremiumBundle` 域的复算暂不列进透明子集，§4 表中预留一行。**不挡本契约其余部分定稿**；落定后按同形态补入一行，不改任何已定形状。
- **`06-platform-stack.md`**：CAS 的具体存储、幂等记录的存储、限流实现与实际阈值、跨区域拓扑、风控事件的落地。本草稿全部停在语义层，`06` 落定后进 `operations/`，**不回头改契约**。
- **客户端侧 handoff**（见「后果」的五项）——其中 ①④⑤ 与本契约定稿**互为前提**，需与本次裁决同批处理。

## 裁决记录（2026-08-14 · 原「仍需用户决定」）

| # | 议题 | 裁决 | 落点 |
|---|---|---|---|
| 1 | 账号级掷骰的随机源 | **B：契约定义的纯函数 SplitMix64**，不依赖 Godot RNG | §5a（含算法、冻结的 `stream` 取值、测试向量要求、客户端类型改动面） |
| 2 | 复算强度 | **B：强复算**——客户端新增 `lastRoll` / `lastEffectiveChance` 两个 `int`，后端做三条校验 | §4 白名单两行 · §5 |
| 3 | `SourceCode` 的枚举序列化 | **收口①**：契约字符串名 + 存档整数 code + 客户端边界映射 | §12 |
| 4 | `accountSeed` 的 JSON 表示 | **hex 字符串 + 给 `envelope.md` §2 通则补判据**（不开例外） | §2 · 张力 1 |
| 5 | `compliance.*` 是否打到同步路径 | **不打到同步路径**——`pull` / `push` 的错误清单**不含** `compliance.*` | 见下 |

**第 5 项的连带纪律（写进 `profile-sync.md`，并回链 `02-account-compliance.md`）：** 同步是后台行为，在它上面返回合规拦截会撞上 pillar #4（不阻塞玩家）——push 被合规拒绝时客户端只有两条既有路径可走（进待发队列退避、或按 `Fatal` 丢弃缓冲），前者会让玩家看着「待同步 N」永远不减，后者直接丢进度。**合规拦截一律在 `signin`（`auth.md`）与业务端点上表达，不进同步通道。** 这一条同时给 `02` 划了一条边界：它可以自由决定合规拦截的分支形态，但**不得把落点选在 `/v1/profile/*` 上**。

## 仍需用户决定

**无。** 三项取向选择已于 2026-08-14 裁决（见上表），`compliance.*` 的落点一并裁定。余下的只有「前置依赖」中那条不挡定稿的 `BundleGrantOrdinal`（客户端侧待答）。

