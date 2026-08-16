# profile-sync —— Profile 下行 / 上行 · CAS 与幂等 · 可见字段子集与掷骰复算

> 覆盖 `/v1/profile/…` 两个端点的报文本体。**边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、错误码台账、版本协商、Profile 三段可见性的分界——全部见 `envelope.md`，本文件只写 sync 域**相对它的差异与细化**。
> 客户端侧门面见 `game-design-documents/systems/services/sync-service.md`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> Source: `handoffs/2026-08-14-profile-sync-contract.md`、`handoffs/2026-08-12-grant-source-code-contract.md`、`handoffs/2026-08-14-splitmix64-test-vectors.md`（§6a 向量填值）。

## 1. 端点集：两个，封定

```
GET  /v1/profile/pull     整聚合下行（无 body，账号取自 token）   —— 需鉴权
POST /v1/profile/push     diff 上行（CAS + 幂等）                 —— 需鉴权
```

与 `sync-service` 的两个 B 形态方法一一对位（`PullProfileAsync` / `PushAsync`）。**契约面就此成文完毕**（`envelope` + `content-manifest` + `auth` + 本文件），无第五份。

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
{ "accountInfo": { "accountSeed": "9f2c1a77b30e45d1" } }
```

后端不懂 Profile 结构（pillar #1），因此它能写的只有**它自己生成的那个值**；其余默认字段由客户端在 `isNewAccount` 时本地构造，随首次 push 补齐。初始 `revision = 1`（账号创建即一次写入），客户端 `baseRevision` 初值为 `0` ⇒ 首次 pull 必然推进，**不存在「空 profile」这个分支**。

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

- **`playerDiff` 中出现的顶层键 → 整键替换；未出现的顶层键 → 保持不变。** 键值以下的结构**完全不透明**，后端不递归、不比对、不校验（`playerPowers` 这类数组一旦出现即整体替换，不做逐元素合并）。
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

- 对位客户端 `PushAck(NewRevision, Deduplicated)`，一字不多。
- **状态码只承担传输层语义**，客户端一律按 `code` 分支（`envelope.md` §5b）；两条 `409` 共用状态码，正说明为什么必须有 `code`。
- `schemaVersion` 越出兼容集合 → `sync.payload_schema_unsupported`（`Upgrade`，**不硬阻塞**，`detail.supportedSchemaVersions`）。**判定发生在 CAS 之前**——版本不兼容不应消耗一次 revision。
- 负载信封字段缺失 / 类型不合法 → `sync.payload_invalid`（`detail.field` 给 JSON path）。**不透明段内部的任何结构问题都不得触发这一条**：它只覆盖信封本身与 §3a 的顶层形状。
- **本文件不新增任何错误码。** 五条 `sync.*` 与 `rate.limited` 已在 `envelope.md` §6 台账中，`class`、客户端处置与 `detail` 形状均原样适用——这是边界层先成文带来的直接收益。
- **`compliance.*` 不出现在这两个端点的错误清单里**，见 §11。

## 5. 后端可见字段子集：按 JSON path 逐条列白名单

`envelope.md` §8 已定 Profile 分三段可见；本节给出第二段（**透明子集**）的逐字段清单。三条纪律：

- **未在下表出现的一切字段都是不透明段**——不另写「不可见清单」，白名单的补集即是。
- **后端对透明段同样只读。** 唯一的写入是账号创建时的 `accountSeed`（§2）。**透明 ≠ 可改写。**
- **⚠ 承重：透明字段的 JSON path 是契约的一部分。** 客户端把 `playerPowerFragment` 挪个位置、或把 `sourceCode` 改个名，在客户端侧是纯重构（老档靠迁移无损通过），但**在后端侧会静默变成「这个字段消失了」**——复算退化为空操作，且两侧都不会报错。因此：**移动或重命名任一透明字段的路径 = 破坏性契约变更，必须 bump `schemaVersion` 并与后端同批改**，与「重命名跨边界枚举值即破坏性变更」（`sync-service.md`）同一条纪律。后端对**缺失的透明路径**一律记一条告警级台账（**不拒绝上行**），使这类漂移在线上可见。

| JSON path（相对 `profile` / `playerDiff` 根） | 类型 | 后端用途 |
|---|---|---|
| `/accountInfo/accountSeed` | string (hex16) | 复算输入；**后端唯一写入的字段** |
| `/playerPowerFragment/accumulated` | number int `[0,10000]` | 区间与变化方向的不变式校验 |
| `/playerPowerFragment/finaleWinOrdinal` | number int | 复算的 `ordinal`；单调 `+1` 校验 |
| `/playerPowerFragment/ch1FirstWinDone` · `ch2FirstWinDone` · `ch3FirstWinDone` | boolean | 单调 `false → true` 校验 |
| `/playerPowerFragment/lastRoll` | number int `[0,9999]` | 逐位比对（§7 校验 ①） |
| `/playerPowerFragment/lastEffectiveChance` | number int `[0,10000]` | 命中自洽校验（§7 校验 ②） |
| `/playerPowers[*]/id` | string | `x` 的计数对象 |
| `/playerPowers[*]/sourceCode` | string enum | `x = count(sourceCode == "FinaleWin")` |

**明确落在不透明段的（各有理由）：**

- `/playerPowers[*]/status`、`disabledAbility` —— **生效维度不是持有维度**，不影响 `x`。
- `/playerItems`、六个 Codex、`achievement` —— 无后端规则用途。
- `/statistics`（`PlayerStatistics`）—— **明确不透明**，兑现 `envelope.md` §8 的「后端不复算、不校验、不得用统计数据驱动任何发放」。把它列进透明档等于给「拿统计驱动活动奖励」开一道门，而那会当场推翻宽松同步口径的全部前提。
- `characterDiffs` **整体**（含轮回级两类持有条目的 `sourceCode`）—— 它对后端无规则用途（纯透传），而每多一条透明路径就多一条上面第三条纪律的约束。
- `bundleGrantOrdinal`（礼包域的账号级序号）—— **落点在客户端尚未定**（`game-design-documents/systems/monetization.md` 的「付费凭证存档表达」待答）。本表**预留一行**，落定后按同形态补入，不改任何已定形状。

### 5a. `sourceCode` 的线上表示：契约走字符串枚举名

`envelope.md` §2 定「枚举值一律字符串、与客户端 C# 枚举名逐字相同」，而客户端定「`code` 整数是**存档**里实际序列化的东西」。两者的收口是：**契约侧走字符串名（`"FinaleWin"`），存档侧走整数 code，客户端在序列化边界做一次映射。**

- 依据：**通则不开例外的价值高于重命名自由**，而重命名本就极少发生。
- **连带纪律：`Source` 的成员名与 code 双双冻结**——存档侧靠 code、契约侧靠名，两者各自都是稳定键，重命名成员在**两侧都是**破坏性变更。已删成员的名与 code 同样永不复用。
- **未知取值：记录原值、不改写、不拒收。** 若后端把未知取值归一为 `Unknown` 并在下行时回写，会直接压低 `x`、让残卷档位回跳，推翻客户端「`x` 单调不减 ⇒ 档位只降不回跳」这条承重不变式。
- **合法子集表不在后端复制。** 客户端有一张 `(Kind, Scope) → 允许的 Source 集合` 静态表，约束的是客户端的组装；后端只做取值识别与 `x` 复算，不要把它做成第二处真值。

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
  lastEffectiveChance = clamp(accumulated, Base(x), Cap(x))     // 掷骰当刻的生效概率

后端在 finaleWinOrdinal 递增的那一次 push 上：
  ① 自算 roll' = SplitMix64(accountSeed, PowerFragment, finaleWinOrdinal) mod 10000
     校验 roll' == lastRoll                                  ← 抓种子篡改 / 序号刷 / 换设备重掷
  ② 单向蕴含：若 lastRoll >= lastEffectiveChance 却新增了一条 sourceCode == "FinaleWin" 的法则
     → 异常。反向（命中却未新增）不判异常                      ← 抓谎报命中
  ③ 结构不变式：finaleWinOrdinal 恰 +1 · accumulated ∈ [0,10000] · 首胜布尔单调 false→true
     · x 单调不减 · 未发放的那一次 accumulated 不减
```

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

## 8. `revision` CAS 的服务端语义：账号级线性化，不指定实现

技术栈未定 ⇒ 停在语义层（本库纪律）。契约要求的是**一个性质**，不是一种存储：

- **同一 `accountId` 上的「读 `cloudRevision` → 比对 `baseRevision` → 写 profile 并 `+1`」必须是一次线性化的读改写。** 任何实现（条件 UPDATE、事务、单分区串行）只要满足它即可。
- **绝不允许「先写 profile 再改 revision」的两步非原子形态**——中途失败会留下一个 profile 已变而 revision 未变的账号，此后每一次 push 都会被判成功却写在错误基线上。
- **跨区域：单写入区（单主）+ 只读副本。** 账号级严格单调递增的计数器在多主下无法维持，而「云端权威」这条决策的全部力量都建立在这个计数器上。跨区域延迟由客户端的非阻塞 push 通道吸收（pillar #4 已保证玩家不等待）。
- 「本地领先」（`baseRevision > cloudRevision`）→ 回 `sync.revision_ahead`，**并作为服务端指标单列**。它在服务端侧的含义是「客户端信封被改写**或后端发生过回滚**」，后者是后端自己的事故信号。

## 9. `pushId` 幂等窗口：`(accountId, pushId)` 唯一键 + 30 天 TTL

| 旋钮 | 初值 | 推导 |
|---|---|---|
| 记忆条数 | **每账号最近 200 条** | 客户端待发队列的实际上界远小于此（软阻塞闸门在 3 个事件级存档点 / 180 秒就触发）；200 条给异常态留足余量 |
| 保留时长 | **30 天** | 上界由 refresh token TTL 决定——超过 30 天未登录的设备必须重登，重登后走「先 pull 后 flush」，其待发队列的 `pushId` 不可能再以旧 `baseRevision` 到达。取相同值使两处窗口不会互相穿帮 |
| 存储形态 | `(accountId, pushId)` 唯一键 → `{ newRevision, acceptedAtUtc }` | 与 revision 的写入**同一次事务**——分开写会出现「revision 已 `+1` 但幂等记录未落」，正是重放会丢进度的那一刻 |

- **命中即返回上次结果**：`200` + `{ "newRevision": <上次的值>, "deduplicated": true }`，**不再 `+1`、不重写 profile**。
- **窗口过期后的重放是安全降级而非错误**：`baseRevision` 此时必然落后 ⇒ 回 `sync.conflict`，客户端按既定语义丢弃缓冲。**这正是窗口必须够长的理由**——过期不会造成错误接受，只会把一次重试变成一次进度丢失。
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

- **`bundleGrantOrdinal` 的透明路径**——待客户端 `systems/monetization.md` 的「付费凭证存档表达」落点定。§5 表中已预留一行，**不挡本契约其余部分**；落定后按同形态补一行，不改任何已定形状。
- **风控事件的落地形态**（结构化事件的字段、累计频次的处置阈值）——归 `02` / `06`，落 `operations/`。契约层只声明「必须上报、不在热路径裁决」。
- **CAS 的具体存储、幂等记录的存储、限流实现与实际阈值、跨区域拓扑**——全部归 `06`，落 `operations/`，**不回头改契约**。

## 跨库待办（客户端侧，本库不代为决定）

需 `game-design-documents/` 另写一份 handoff，见 `handoffs/2026-08-14-profile-sync-contract.md` 的「客户端侧影响」段——七点：

1. `PlayerPowerFragment` 新增 `lastRoll` / `lastEffectiveChance` 两个 `int`（零迁移，老档补默认）；
2. **每次 Finale 胜利都掷骰并落 `lastRoll`（池空亦然）**、**首胜时 `lastEffectiveChance` 写 `10000`**（§7 的两条写入约定，缺任一条即在正常账号上触发风控误报）；
3. `AccountSeed` 的客户端表示改为 hex 字符串解析（存档内可继续存 `ulong`，映射发生在序列化边界）；
4. 透明字段的**路径稳定性**纪律进客户端存档约定（移动 / 重命名任一透明路径 = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改）；
5. `sourceCode` 收口的落地：序列化边界的 code ↔ 名映射、「名与 code 双双冻结」纪律，并修正 `systems/common-properties.md` 里「code 是上行负载里实际序列化的东西」那句（应为「code 是**存档**里实际序列化的东西；**上行负载走枚举名**」）；
6. **`AccountRng` 换随机源**（§6）——SplitMix64 实现 + 测试向量对表，**并含返回类型改动**（`RandomNumberGenerator` → 项目自有 `AccountRandom`）与 `DrawPool.PickOne/PickMany` 的参数类型放宽。调用点形状与幂等语义不变，轮回级 RNG 完全不受影响；
7. `PlayerProfileDiff` / `CharacterProfileDiff` 的序列化形态须与 §3a 的**顶层键浅合并**逐字对齐（顶层键出现即整键替换、空对象 = 无变化、不表达删除）。
