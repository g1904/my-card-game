# `profile-sync.md` 报文本体 · 可见字段子集 · 掷骰复算协议

- id: 2026-08-14-profile-sync-contract
- date: 2026-08-14
- topic: contracts/profile-sync（新建）· contracts/envelope（§2 判据 + §8 回链）· contracts/_index · decisions · open-questions（`01` / `02` / `06`，`03` 整片删除）
- status: distilled
- distilled-to: `contracts/profile-sync.md`、`contracts/envelope.md`、`contracts/_index.md`、`decisions/_index.md`、`open-questions/01-contracts.md`、`open-questions/02-account-compliance.md`、`open-questions/06-platform-stack.md`、`open-questions.md`（`03-sync-conflict.md` 整片删除）、`answer-logs/log-profile-sync-contract.md`

> **来源**：`inbox/archive/solution-draft-profile-sync-contract.md`（08-13 产出、08-14 用户裁决五项）+ 本次 interview 两项裁定。
> **一句话**：契约面的最后一份端点文档成文——两端点报文、负载信封与 **diff 合并语义**、CAS 三分支 + 幂等命中的应答、**逐 JSON path 的后端可见字段白名单**，以及把「后端可离线复算」拆成「**可复算 `roll`、不可复算阈值**」的防作弊边界。

## Intent（distilled）

### 1. 端点与报文

- `GET /v1/profile/pull`（无 body，账号取自 token）+ `POST /v1/profile/push`。路径与动词此前已被 `envelope.md` §4 的论证定死，本次只是写明。`accountId` **不进 query、不进 body**——它的唯一用途会是造出一个越权分支。
- pull 应答三字段（`revision` / `schemaVersion` / `profile`），对位客户端已定 `ProfileSnapshot`，一字不多。**pull 侧不设版本闸门**：闸门只在签发 token 时判定一次（`envelope.md` §7b），云端 schema 高于客户端由客户端迁移器承担。
- push 请求 = 负载信封四字段（`pushId` / `baseRevision` / `schemaVersion` / `reason`）+ 两段 diff。`reason` 是**日志与聚合维度，不驱动任何判定**；空 diff 照常接受并 `+1`。
- 应答四种情形（CAS 三分支 + 幂等命中），两条 `409` 共用状态码而以 `code` 区分——正是 `envelope.md` §5b 存在的理由。**本文件不新增任何错误码**：五条 `sync.*` + `rate.limited` 已在台账中，形状原样可用。

### 2. 新账号骨架与 `accountSeed` 的下发通道

后端在账号创建时写入 `{ "accountInfo": { "accountSeed": "…" } }` 这一个字段（它不懂 Profile 结构，能写的只有它自己生成的那个值），初始 `revision = 1`；客户端 `baseRevision` 初值 `0` ⇒ 首次 pull 必然推进，**「空 profile」这个分支不存在**。这填上了 `auth.md` §11 留下的那一半。

**`accountSeed` 以 16 位小写 hex 字符串下发。** 它是 `ulong`，几乎必然超出 2⁵³，而 JSON number 在双精度实现里会静默丢低位——它又恰是逐位复算的输入。收口方式是**给 `envelope.md` §2 的整数通则补一个判据而非开例外**：「整数走 JSON number，除非取值域可能超出 2⁵³」。补的这句与 §2 原论证同源（`revision` 能用 number 的理由恰是「一生到不了 2⁵³」）。

### 3. diff 的合并语义 = 顶层键粒度的浅合并（interview 裁定）

后端要靠 diff 维护它在 pull 时回吐的整聚合，因此合并语义是契约的一部分，不能留给实现。裁定：**`playerDiff` 中出现的顶层键整键替换、未出现即不变；`characterDiffs[i].diff` 整体替换该角色；空对象 = 无变化；不提供删除语义**（客户端 `PlayerProfile` 只增不删）。键值以下完全不透明，后端不递归。

由此得一条便利推论：「该顶层键出现在本次 `playerDiff`」⟺「这些透明字段本次有新值」，后端据此决定是否跑复算，无需解不透明部分。

### 4. 后端可见字段子集：逐 JSON path 的白名单

八条透明路径（`accountSeed` · `playerPowerFragment` 的六个字段 · `playerPowers[*]` 的 `id` 与 `sourceCode`），**补集即不透明段**。三条纪律：白名单的补集不另写一份清单 · **透明 ≠ 可改写**（后端唯一写入是账号创建时的 `accountSeed`）· **⚠ 透明字段的 JSON path 是契约的一部分**——客户端挪个位置在自己那侧是纯重构，在后端侧却会静默变成「字段消失、复算退化为空操作」，两侧都不报错。故**移动 / 重命名任一透明路径 = 破坏性契约变更**，须 bump `schemaVersion` 并与后端同批改；后端对缺失的透明路径记告警级台账、不拒绝上行。

明确落在不透明段的四类各有理由，其中 **`statistics` 的不透明是承重的**：把它列进透明档等于给「拿统计驱动活动奖励」开一道门，而那会当场推翻 `envelope.md` §8「后端不复算、不校验、不得用统计驱动发放」的全部前提。

`sourceCode` 的线上表示收口为：**契约侧字符串枚举名 + 存档侧整数 code + 客户端在序列化边界一次映射**。通则不开例外的价值高于重命名自由；连带纪律是 **`Source` 的名与 code 双双冻结**。

### 5. 随机源换成契约定义的纯函数 SplitMix64

跨语言逐位一致是复算成立的**前提**。押在 Godot `RandomNumberGenerator` 上，等于让「引擎升级」成为一次静默的作弊窗口——客户端自己已为 `RandomNumberGenerator.State` 写过同一条警告。算法、`GOLDEN` 常量、三参数逐级混入的顺序、`+1` 的全零防御、`mod 10000` 不做拒绝采样，**全部是契约的一部分**；`stream` 的整数取值随 `AccountStream` 成员序**冻结**，新增域只能追加。**测试向量表是这条纪律唯一可执行的检查点**，两侧各自实现后必须逐位对上。**轮回级 RNG 完全不受影响**。

### 6. 复算协议：可复算 `roll`，不可复算阈值

「后端可离线复算」拆开是两件事：算 `roll` **能且必须能**（纯函数，输入全在透明子集里）；判定是否命中**不能可靠地做**（生效概率取决于按 `(x, chapter)` 分档、随 overlay 热更且不冻结 `contentVersion` 的平衡表）。因此**否决「后端持有分档表全量验算」**——那是第二份真值 + 必然漂移，与 pillar #1 / #5 同时相悖，且后端还缺「这次是哪一篇章」这个输入。

客户端上报 `lastRoll` / `lastEffectiveChance` 两个 `int`（非列表、老档补默认 ⇒ 零迁移），后端做三条校验：① `roll'` 逐位比对 · ② **单向蕴含**：未命中却新增 `FinaleWin` 法则 = 异常 · ③ 结构不变式。

**不需要历史列表**：CAS 保证上行严格串行，每次 Finale 胜利必然产生一次 push ⇒「最近一次」两个字段就够——这是 08-09b「不需要跨轮回的待发放字段」那条结构性简化的同构延伸。

### 7. 不一致的处置：记账 + 风控，不拒绝、不改写

拒绝上行 = 一次误报当场变成一次玩家进度丢失（客户端按 `Conflict` 丢弃缓冲），而复算的对象是每篇章至多一次的低价值掉落，比例失衡；以后端值改写则与「未知 `sourceCode` 不改写」冲突、并让两侧 Profile 在客户端不知情时分叉。形状与「验签失败 → 拒绝 + 上报一次」同源：**异常必须可见，但不在同步热路径上做裁决。**

### 8. 服务端语义三项（停在语义层，实现归 `06`）

- **CAS**：同一 `accountId` 上的「读 → 比对 → 写并 `+1`」必须**线性化**；**绝不允许「先写 profile 再改 revision」**的两步非原子形态；跨区域**单主 + 只读副本**（严格单调计数器在多主下无法维持，而云端权威的全部力量都建立在它上面）。
- **`pushId` 幂等**：`(accountId, pushId)` 唯一键、200 条 / 30 天、**与 revision 同一次事务**；命中回上次结果不再 `+1`；**不做 body 深比对**；窗口过期是安全降级（退化为 `conflict`）而非错误接受。
- **限流**：只设远高于稳态的滥用阈值（60 次/分钟），**不设常规节流**——它只打到正常玩家，且重试会把同一批数据再送一次。

### 9. `compliance.*` 不打到同步通道

同步是后台行为，在它上面返回合规拦截会撞上 pillar #4：push 被合规拒绝时客户端只有「待同步 N 永远不减」或「丢进度」两条路。**合规拦截一律在 `signin` 与业务端点上表达**——这同时给 `02` 划了一条边界：分支形态可自由决定，但落点不得选在 `/v1/profile/*`。

## Clarifications（interview 产物 · 2026-08-14）

两项 🔴 由本次 interview 裁定，均**推翻了草稿的原写法**：

1. **复算校验 ②③ 的形态** —— 草稿写的是双向等价「新增法则 ⟺ `lastRoll < lastEffectiveChance`」与「命中时 `accumulated` 变小」。二者都会被客户端 08-09b 的既定规则证伪（**首胜 100% 优先于闸门** · **候选池取尽后静默停摆** · **发放后重置为 `Base(x+1)` 而非归 0**，而 `accumulated` 可低于 `Base` ⇒ 命中后可能变大）；更硬的一处是**池空时客户端根本不掷骰而 `finaleWinOrdinal` 照常 `+1`** ⇒ 草稿的校验 ① 会稳定失败。
   **裁决**：弱化为单向蕴含 + 三条写入约定 —— **每次 Finale 胜利都掷骰并落 `lastRoll`（池空亦然）** · **首胜写 `lastEffectiveChance = 10000`**（首胜因此不再是例外）· ② 只判「未命中却新增」这一个方向（「命中却未新增」有合法成因：池已取尽，而后端无法判断池是否为空）· ③ 不检查发放那一次 `accumulated` 的变化方向。**否决**「再加一个结局字段以保住双向等价」——多一条透明路径即多一条路径稳定性约束，而该字段同样由客户端产出、同样不可验真。

2. **push diff 的合并语义** —— 草稿只写了 `playerDiff: object`，未定义后端如何把它合进存储的 profile；而后端必须靠它维护 pull 回吐的整聚合。同一句话至少有三种读法，且直接决定 §5 白名单路径的可见性是否稳定。
   **裁决**：**顶层键粒度的浅合并**（见上文 3）。**否决** RFC 7386（以 `null` 表示删除，与 `envelope.md` §2 冲突；要求后端递归遍历不透明结构）与**段级全量替换**（每次 push 重传整个账号级段，与「整聚合上行不可持续」同向相悖）。

一项由本库校验推演修正（草稿未点名）：草稿把 512 KB 记为「沿用客户端既定的软上限口径，两侧同一个数」；客户端那条实为**单个 `CharacterProfile` 的 `pastEvent`** 护栏（条数 > 500 或序列化 > 512 KB）。契约中改为「借用同一数量级作起点、**口径不同**、须实测校准」。

## Open questions

- **测试向量表的实际数值**——算法与向量表形态已定，数值在任一侧首次实现时填入并同批复核。属待落笔项，非设计未决。
- **`bundleGrantOrdinal` 的透明路径**——待客户端 `systems/monetization.md`「付费凭证的存档表达」落点定；白名单已预留一行，**不挡本契约其余部分**。
- **风控事件的落地形态**与累计频次的处置阈值 —— 归 `02` / `06`。
- **CAS / 幂等记录 / 限流的具体存储与实现、跨区域拓扑** —— 归 `06`，落 `operations/`，不回头改契约。

## Notes / triage

- 本 handoff **同时答结** `handoffs/2026-08-12-grant-source-code-contract.md` 遗留的三条：枚举序列化冲突（收口①）· `x` 复算的触发时机与不一致处置（`finaleWinOrdinal` 递增的那次 push；仅记账不拒绝）· 轮回级 `sourceCode` 是否进透明档（**不进**）。该 handoff 因此转 `distilled`。
- `contracts/` 就此成文完毕，`contracts/_index.md` 的状态表与 `open-questions.md` 的「当前焦点 / 下一阶段」整体改写；`open-questions/03-sync-conflict.md` **整片删除**（五条全部答结或被 §3 / §10 覆盖，实现层面的部分并入 `06`；编号 `03` 空缺不回填，同 `05` 的处置）。
- **存档 schema：bump 一次、空迁移**（当前无线上存档），与既有多次 bump 同批即可，不单独制造一次迁移。

## 客户端侧影响

**是**——本 handoff 触及客户端 ↔ 后端边界的语义，且其中三项是**真实的客户端改动**（不是纯文档同步）。

- 受影响的客户端成分：**`sync-service`**（报文形态、diff 序列化形态）与 **`profile-service`**（残卷掷骰的随机源与两个新字段）。`account-service` / `content-service` 无关。
- `game-design-documents/` 侧需同步更新的文档：`systems/services/sync-service.md`、`systems/services/profile-service.md`、`systems/common-properties.md`（账号级 RNG 与 `SourceCode` 两处）、`systems/player-profile/player-power/_index.md`、`systems/player-profile/account-info.md`。
- 需另写一份客户端 handoff，**七点**（逐条见 `contracts/profile-sync.md` 的「跨库待办」）：① `lastRoll` / `lastEffectiveChance` 两字段 · ② **每次胜利必掷骰 + 首胜写 10000** 这两条写入约定 · ③ `accountSeed` 的 hex 解析 · ④ 透明路径稳定性纪律 · ⑤ `sourceCode` 收口的边界映射与 `common-properties.md` 那句话的修正 · ⑥ **`AccountRng` 换 SplitMix64**（含 `AccountRandom` 返回类型改动与 `DrawPool.PickOne/PickMany` 参数放宽）· ⑦ `PlayerProfileDiff` / `CharacterProfileDiff` 与顶层键浅合并对齐。
- 其中 ①②⑤⑥ 与本契约定稿**互为前提**，宜同批处理；③④⑦ 是纯纪律 / 形态对齐。
