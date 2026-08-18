---
type: solution-draft
date: 2026-08-16
question: 客户端库与后端库之间已积累的跨边界失配如何收口，以及靠什么机制防止它再次发生？
source: open-questions/05-service-contracts.md → `Source` 在上行负载里的序列化形态；backend-design-documents/contracts/profile-sync.md → 跨库待办七点；2026-08-16 两库 derive 就绪度全量评估的「跨边界闭合」结论
targets: systems/common-properties.md · systems/services/sync-service.md · systems/services/profile-service.md · systems/player-profile/player-power/_index.md · systems/player-profile/account-info.md · systems/monetization.md · open-questions/05-service-contracts.md · open-questions/（新分片 cross-boundary.md）
counterpart: backend-design-documents/inbox/solution-draft-cross-library-alignment.md
status: distilled
decided-on: 2026-08-16
reviewed: 2026-08-16 — 用户逐条定案 4 项取向（购后 pull 失败阻塞重试 · 台账命名 cross-boundary · C④ 暂不机械化 · A+C 一次落笔）；提炼时另经一次 interview 定下 C⑥ 的最小随机源接口形态（泛型约束 `IRandomSource`）
distilled-to: handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md
---

# 方案草稿 — 跨库失配收口与桥接机制（客户端侧）

> **本草稿只承载归属判给客户端的那一半。** 后端侧的一半（购买段验票端点契约、后端主动写入与 CAS 的共存、桥接台账的后端落点）在 `counterpart` 那份里，两份**必须同批采纳**——单侧采纳即两侧仍不一致。

## 问题

2026-08-16 的两库全量就绪度评估暴露出：客户端库与后端库在**三处**已经不一致，而且不一致**已经存在了一到两周没有被发现**。三处的性质完全不同，混在一起谈会得出错误的处置：

| # | 失配 | 真实状态 | 谁欠谁 |
|---|---|---|---|
| **A** | `Source` 在上行负载里的序列化形态（整数 code vs 字符串枚举名） | **后端已于 08-14 收口**（`contracts/profile-sync.md` §5a），客户端**未传导** | 客户端欠落笔 |
| **B** | 购买段：后端验票 + 后端主动写入 `bundleGrantOrdinal` / `cloudRevision` | **客户端已于 08-15b 定案且写得很完整**，后端**零承载**（无验票端点） | 后端欠契约 |
| **C** | `profile-sync.md` §6 §7 的七点（SplitMix64 随机源、两个新字段等） | **后端已于 08-14 成文**，客户端仍写 `Hash64` + `rng.Randi()` | 客户端欠落笔 |

**A 和 C 都不是待裁决的设计问题，是纯粹的落笔欠账**——答案在对侧库里已经写好了。它们之所以还挂在待答清单上（A 至今仍列在 `open-questions/05-service-contracts.md`，措辞还是「倾向收口：……」），是因为**没有任何机制把「对侧已定案」这件事送到本侧的视野里**。这才是要解决的根问题：三处失配是症状，缺桥接是病因。

## 约束（来自既有设计）

- **两库内容互不覆盖，权威分侧**（`.claude/rules/design-library-routing.md` 的归属判据；两库各自 README）。收口不能靠「把对方的设计抄过来」——那会制造第二权威。
- **回链而非复述**（同上，且是本项目已明确写下的防漂移承重纪律）。
- **契约的权威在后端库**（就绪度规则第 6 条：客户端库自称「契约已定」但后端库没有对应文档，以后端库为准）。⇒ A 与 C 的处置只能是**客户端向后端对齐**，不是双向协商。
- **跨边界枚举值重命名 = 破坏性变更**（`sync-service.md` 已有此纪律；`profile-sync.md` §5 把它扩到了透明字段的 JSON path）。
- `ADR-0003`（强制在线 · 云端权威）已排除字段级三路合并 ⇒ B 的客户端侧解法（时机纪律）不得被改成冲突合并。

## 建议方案

### A. `Source` 序列化形态：客户端直接按后端已定的收口落笔，并从待答清单移出
`[既有推演]`

`contracts/profile-sync.md` §5a 已经给出了完整结论，且它给的正是客户端 `05` 分片自己写的那个「倾向收口」：

> **契约侧走字符串枚举名（`"FinaleWin"`）· 存档侧走整数 code · 客户端在序列化边界做一次映射。**
> 连带纪律：**`Source` 的成员名与 code 双双冻结**，两者各自都是稳定键，重命名成员在两侧都是破坏性变更；已删成员的名与 code 同样永不复用。
> 未知取值：**记录原值、不改写、不拒收**（后端归一为 `Unknown` 会压低 `x`、让残卷档位回跳，推翻「`x` 单调不减 ⇒ 档位只降不回跳」）。
> **合法子集表不在后端复制**——`(Kind, Scope) → 允许的 Source 集合` 那张静态表只约束客户端组装。

**⇒ 客户端侧无任何设计自由度剩余，只需三处落笔：**

1. `systems/common-properties.md` 中「code 是存档 / **上行负载**里实际序列化的东西」那句 —— 改为「code 是**存档**里实际序列化的东西；**上行负载走字符串成员名**，映射发生在序列化边界」，并补上「名与 code 双双冻结、永不复用」这条纪律。**这句话是唯一的冲突源**，改完 A 即消失。
2. 补一条序列化边界的落点说明：映射在 `sync-service` 组装上行负载时做一次，**不在 `profile-service` 内部做**（存档态始终是 code，避免同一个值在内存里有两种形态）。
3. `open-questions/05-service-contracts.md` 的该条**整条移出**（它已不是待答项），归档进 `answer-logs/`。

**注意 A 与 C⑤ 是同一件事的两面**（后端 08-14 handoff 的七点里，⑤ 就是「`sourceCode` 收口的边界映射与 `common-properties.md` 那句话的修正」）。宜同批处理，不要分两次。

### B. 购买段：客户端侧已完整，只需补一行回链与一处白名单确认
`[既有推演]`

客户端侧**不欠设计**——`systems/monetization.md` 的两段分工表、`BundleGrantOrdinal` 的形状与幂等语义、三条前置条件表，以及 `sync-service.md` 的时机纪律（购买只在主菜单发起 + 待发队列必须为空 + 购后强制 pull）已经把客户端这一半写完了，且**时机纪律在结构上关闭了 CAS 冲突窗口**，无需为购买开任何例外。

客户端侧只剩两处收尾，且都依赖 counterpart：

1. **`BundleGrantOrdinal` 的存档落点已于 08-15b 定案**（`PlayerEntitlement.BundleGrantOrdinal`），而后端 `profile-sync.md` §5 白名单表**仍留着「落点在客户端尚未定」的预留行**。⇒ 客户端侧补一句：该字段的 JSON path 为 `/entitlement/bundleGrantOrdinal`（**待与 counterpart 的白名单行同批确认**），并声明它自此受「透明路径 = 契约的一部分，移动 / 重命名须 bump `schemaVersion` 并与后端同批改」那条纪律约束。
2. **在 `monetization.md` 与 `sync-service.md` 各补一条指向后端验票契约的回链**（路径待 counterpart 落笔后确定）。当前两份文档描述了「上行验票」这个动作，却没有任何指向后端契约的链接——读者无从得知那份契约根本还不存在。

3. **购后 pull 失败 = 阻塞在主菜单重试直到成功**（`[已裁决 2026-08-16]`）。玩家已付款、后端已 +1，但客户端拉不到新序号 ⇒ **停在主菜单重试**，不允许在未兑现状态下开始新轮回。依据：与「不收钱又不给货」那条既定纪律同向；且此刻玩家本就在主菜单（购买入口的前置条件 1），阻塞代价最小——没有任何进行中的轮回被打断。
   - 重试路径走 counterpart 的 `GET /v1/purchase/receipt/{receiptId}` 幂等读，**跨启动也能补查**（`receiptId` 随待兑现态持久化）。
   - UI 形态复用既有的阻塞屏变体表（`ux/error-and-blocking-ux.md` 的一屏三变体），**不新增拦截点**。
   - **否决的两条**：允许离开、下次启动补兑现（兑现被推迟到不确定的时刻，期间玩家看不到自己买的东西）· 本地先乐观兑现、后端复算兜底（等于客户端有权发货，正是 08-15b 明确否决的那条）。

### C. `profile-sync.md` 七点欠账：逐点给出客户端侧的具体形态
`[既有推演]`（除 ⑥ 的返回类型外全部无自由度）

| # | 欠账 | 客户端侧落笔形态 | 落点 |
|---|---|---|---|
| ① | `lastRoll` / `lastEffectiveChance` 两字段 | `PlayerPowerFragment` 增两个 int 字段：`lastRoll ∈ [0,9999]`、`lastEffectiveChance ∈ [0,10000]`（万分比）。**均进透明段**，JSON path 见 §5 白名单 | `player-power/_index.md` |
| ② | 两条写入约定 | **每次 Finale 胜利必掷骰**（即使当次不可能中也要掷并写 `lastRoll`，否则后端复算无输入）· **首胜写 `lastEffectiveChance = 10000`** | 同上 |
| ③ | `accountSeed` 的 hex 解析 | 契约侧是 `string (hex16)`，客户端存档侧是 `ulong` ⇒ 与 A 同构的一次边界映射（解析失败按**必需缺失**处置：`PushError` + 拒绝进入需要它的流程） | `account-info.md` |
| ④ | 透明路径稳定性纪律 | 八条透明 path 的移动 / 重命名 = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改。**先按人工清单执行，暂不机械化**（`[已裁决 2026-08-16]`，理由见下方「已裁决」第 3 条） | `sync-service.md` |
| ⑤ | `sourceCode` 边界映射 | **同 A**，不重复 | `common-properties.md` |
| ⑥ | **`AccountRng` 换 SplitMix64（承重）** | 现签名 `RandomNumberGenerator AccountRng.For(stream, ordinal)` + 内部 `Hash64(...)` ⇒ 改为契约 §6 定义的纯函数：`state = accountSeed` → `Mix(state + GOLDEN*(stream+1))` → `Mix(state + GOLDEN*(ordinal+1))`，`Next(): state += GOLDEN; return Mix(state)`，`roll = Next() mod 10000`。**返回类型不再是 `RandomNumberGenerator`** ⇒ `DrawPool.PickOne/PickMany` 的参数须放宽到一个最小随机源接口。`AccountStream` 成员序 `PowerFragment=0` / `PremiumBundle=1` **自此冻结、只能追加**。**验收物已现成**：`contracts/vectors/splitmix64.json` 8 组向量，实现后逐位对表即可，**无须等后端动手** | `common-properties.md` |
| ⑦ | diff 与顶层键浅合并对齐 | `PlayerProfileDiff` / `CharacterProfileDiff` 的序列化形态与 §3a 的顶层键浅合并对齐 | `sync-service.md` |

**⑥ 是七点里唯一有实现形态自由度的**（那个「最小随机源接口」长什么样），其余六点照抄契约即可。**轮回级 RNG 完全不受影响**，继续用 Godot 的 `RandomNumberGenerator`——只有账号级掷骰跨边界。

### D. 桥接机制：两库各立一份「跨边界承接台账」
`[既有推演]` + `[通行做法]`

**病因诊断**：现有的唯一桥接是 handoff 里的「客户端侧影响」段（后端 08-14 那份写得很完整，七点逐条列明）。它失效的原因是结构性的——**handoff 是一次性文档，写完就沉进 `handoffs/`，没有任何东西会再读它**。对侧库的日常入口是 `open-questions.md`，而那七点从未出现在客户端的待答清单里。⇒ 桥接必须落在**对侧库的日常入口**上，不能落在源侧的历史文档里。

**建议形态：两库各新增一个固定分片 `open-questions/cross-boundary.md`**，专装「**对侧已定案、我方尚未承接**」的条目。

- **它与普通待答项的关键区别，必须写在分片抬头**：普通待答项等的是**设计裁决**；跨边界承接项**答案已经有了**，等的只是**落笔**。混在普通分片里会让它们和真正的开放问题一起被无限期搁置——这正是过去两周发生的事。
- **每条的固定形态**：`对侧权威文档路径#小节 | 对侧定案日期 | 我方需改的文档 | 一句话摘要`。**只写回链与摘要，绝不复述对侧的设计内容。**
- **关闭条件**：我方落笔完成（对应 handoff `distilled`）后从分片移除，记进 `answer-logs/`。两侧的条目各自独立关闭，不要求同时。
- **谁维护**（与本次已改的技能纪律一一对应，不需要新机制）：
  - `/analyze-new-ideas` 跨库落笔时**同批写两侧**（2026-08-16b 已解除单库限制）——主库写决策，对侧库的 `cross-boundary.md` 立承接项。
  - `/summarize-open-questions` 对账时若发现「一侧已定案、另一侧零承载」→ **补登**到对侧的 `cross-boundary.md`（同批解除）。
  - `/assess-derive-readiness` 只**报告**跨边界缺口，不写对侧（它的台账两库各一份、结论永不合并）。

**⇒ 本次的三处失配即是这份台账的首批条目**：客户端侧装 A、C 七点、B 的两处收尾；后端侧装 B 的验票契约（见 counterpart）。

**分片命名 = `open-questions/cross-boundary.md`，不带编号**（`[已裁决 2026-08-16]`）。客户端库现有 `01`–`07` + `deferred-content`，后端库有 `01` / `02` / `04` / `06`（`03` `05` 已空缺且约定不回填）⇒ 两库都用不带编号的同名分片（与 `deferred-content.md` 同形），避免占用编号序列、也避免两库编号各不相同造成引用混乱。

## 具体形态（可 derive 的落地面）

**`PlayerPowerFragment` 新增字段（C①②）**

| 字段 | 类型 | 取值域 | 写入时机 | 透明 |
|---|---|---|---|---|
| `lastRoll` | int | `[0,9999]` | 每次 Finale 胜利掷骰后**必写** | 是 |
| `lastEffectiveChance` | int | `[0,10000]`（万分比） | 同上；**首胜写 `10000`** | 是 |

**`AccountRng` 新签名（C⑥）**

```
// 契约 backend-design-documents/contracts/profile-sync.md §6 定义，两侧逐位一致
// 全部为 uint64 环上运算，>> 为逻辑右移
Mix(z):  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
         z = (z ^ (z >> 27)) * 0x94D049BB133111EB
         return z ^ (z >> 31)
GOLDEN = 0x9E3779B97F4A7C15

AccountRandom AccountRng.For(AccountStream stream, ulong ordinal)
    state = accountSeed
    state = Mix(state + GOLDEN * (ulong)(stream  + 1))
    state = Mix(state + GOLDEN * (ulong)(ordinal + 1))

AccountRandom.Next():  state += GOLDEN;  return Mix(state)
AccountRandom.Roll():  return Next() mod 10000        // 万分比，不做拒绝采样
```

- `AccountStream`：`PowerFragment = 0` · `PremiumBundle = 1`，**序号冻结、只能追加**。
- 验收：`backend-design-documents/contracts/vectors/splitmix64.json` 的 8 组向量逐位对上。**实现与表不符时先复核实现、再复核表，不得单方面改表迁就实现。**
- `DrawPool.PickOne` / `PickMany` 的参数类型由 `RandomNumberGenerator` 放宽到 `AccountRandom` 与它的公共最小接口。

**透明路径清单（C④ 的机检对象，八条 + 待确认的第九条）**

`/accountInfo/accountSeed` · `/playerPowerFragment/accumulated` · `/finaleWinOrdinal` · `/ch1FirstWinDone` · `/ch2FirstWinDone` · `/ch3FirstWinDone` · `/lastRoll` · `/lastEffectiveChance` · `/playerPowers[*]/id` · `/playerPowers[*]/sourceCode` ·（**待确认**）`/entitlement/bundleGrantOrdinal`

## 后果

- **存档 schema**：C① 增两字段、B① 确认一个字段的 path ⇒ **需 bump `schemaVersion`**。C⑥ 换随机源**不改存档结构**（`accountSeed` 本身没变），但**会改变同一账号未来的掷骰序列**——已发生的 `lastRoll` 是历史记录、不重算，无迁移问题。
- **受影响文档**：`common-properties.md`（A + C⑤⑥）· `sync-service.md`（C④⑦ + B 回链）· `profile-service.md`（C⑥ 的调用侧）· `player-power/_index.md`（C①②）· `account-info.md`（C③）· `monetization.md`（B）· `open-questions/05-service-contracts.md`（A 移出）+ 新建 `open-questions/cross-boundary.md`（D）。
- **对 derive 就绪度的影响**：A 与 C 收口后，`systems/common-properties.md` 与 `systems/services/sync-service.md` 的两处 ⚠ 跨边界卡点消失 ⇒ `sync-service` 的 partial 切片可扩到上行负载形态。（**本草稿不评估就绪度**，重估归 `/assess-derive-readiness`。）
- **不触及**：轮回级 RNG、CAS 三分支表、`ADR-0003` / `ADR-0004`。

## 备选方案（已考虑并否决）

- **把 A 的收口反过来做（契约侧改走整数 code）** —— 否决。契约权威在后端库，且 `envelope.md` §2 的「枚举一律字符串、与 C# 成员名逐字相同」是**通则**，为一个枚举开例外的代价高于客户端加一次边界映射；后端 §5a 已给出这条理由。
- **客户端保留 `Hash64` 不换 SplitMix64，改由后端适配** —— 否决。跨语言逐位一致是复算成立的前提，而 `Hash64` 押在引擎实现细节上，「Godot 升级」会成为一次**静默的作弊窗口**。且测试向量已经填好，换过去是有验收物的确定动作。
- **靠 handoff 的「客户端侧影响」段做桥接（现状）** —— 否决。已被证伪：后端 08-14 那份写得完整、七点逐条列明，两周后仍一点未落。**一次性文档不是台账。**
- **两库合并成一个设计库** —— 否决。它与根约定「客户端与后端是两条彼此独立的分支线、唯一真实的进程边界是客户端 ↔ 后端」正面冲突，且会把后端文档打进 Godot 客户端的分发包。
- **在 `.claude/knowledge/` 建一份跨边界对照表** —— 否决。`ADR-0005` 定 `.claude` 只做薄引用、设计主权在设计库；一张对照表会立刻变成第二权威。

## 与既有决策的张力

**无实质张力。** A 与 C 是向已定案对齐，B 的客户端侧已定案且时机纪律与 `ADR-0003` 同向，D 是新增台账、不推翻任何既有约定。

唯一需要点名的是 **D 依赖一条刚被改写的根约定**：`.claude/rules/design-library-routing.md` 的「跨库纪律」已于 2026-08-16b 由「一次运行只作用于一个库」改为「允许跨库，但每侧只写归属判给它的那一半」。D 的维护者分工建立在这条改写之上；若该改写被推翻，D 需退回「由用户手动在两侧各跑一次」的形态（机制本身仍成立，只是不再自动维护）。

## 前置依赖

- **B 的客户端两处收尾依赖 counterpart**：`/entitlement/bundleGrantOrdinal` 的白名单行须两侧同批落笔；回链目标已定为 `backend-design-documents/contracts/purchase.md`（counterpart 已裁决该命名）。
- **B 的购后阻塞重试依赖 counterpart 的幂等读端点** `GET /v1/purchase/receipt/{receiptId}`——它是本侧「阻塞重试」得以成立的前提（没有可查回的通道，阻塞就变成死等）。counterpart 已把它定为承重端点，非可选便利。
- A、C①②③④⑤⑥⑦ **无前置依赖，可立即落笔**。

## 已裁决（2026-08-16 · 用户逐条定案）

1. **购后 pull 失败 = 阻塞在主菜单重试直到成功。** 取选项 (a)，形态与否决理由见 B 段第 3 条。
2. **桥接台账命名 = `open-questions/cross-boundary.md`（不带编号）**，两库同名同形。见 D 段。
3. **C④ 的透明路径机检暂不做，先按人工清单执行。** 与既有的「纪律的可执行化」四级阶梯一致——不为一条尚无实例的纪律先行造工具。**留一条触发条件**：首次真的发生透明路径漂移（后端告警台账记到第一条）时，回头把它升级为机械检查，而不是等它攒够教训。
4. **落笔批次 = A + C 七点一次 handoff 全做完。** 其中 ①②⑤⑥ 与契约定稿互为前提，分批会让中间态两侧都不自洽。B 的两处收尾与 D 的台账建立可并入同一批（它们不冲突），但**必须与 counterpart 同批**。

> **本草稿的取向项已全部定案，可直接喂给 `/analyze-new-ideas`。** 落笔时若发现新的分叉，按既定纪律停下来问，不要自行扩大裁决面。
