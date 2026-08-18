# 跨库失配收口（客户端侧）与跨边界承接台账

- id: 2026-08-16b-cross-library-alignment-and-bridge-ledger
- date: 2026-08-16
- topic: systems/common-properties · systems/services/sync-service · systems/services/profile-service · systems/services/content-service · systems/player-profile/_index · systems/player-profile/player-power/_index · systems/player-profile/account-info · systems/monetization · open-questions/cross-boundary
- status: distilled
- distilled-to: `systems/common-properties.md`、`systems/services/sync-service.md`、`systems/services/profile-service.md`、`systems/services/content-service.md`、`systems/services/life-cycle-service.md`、`systems/player-profile/_index.md`、`systems/player-profile/player-power/_index.md`、`systems/player-profile/account-info.md`、`systems/monetization.md`、`open-questions/cross-boundary.md`、`open-questions/05-service-contracts.md`、`answer-logs/log-cross-library-alignment.md`
- counterpart: `backend-design-documents/handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md`

## Intent（distilled）

**一句话：客户端把三处跨边界欠账一次落笔到位（`Source` 的上行表示 · `profile-sync` 七点 · 购买段的两处收尾），并新立一份常驻分片 `open-questions/cross-boundary.md`，专装「对侧已定案、我方尚未承接」的条目——因为缺的从来不是决定，是把决定送到对侧视野里的那条通道。**

### 病因：一次性文档不是台账

三处失配都不是待裁决的设计问题，答案在对侧库里早已写好，却挂了一到两周没人落笔。唯一的桥接是 handoff 里的「客户端侧影响」段——它写得很完整，但 **handoff 写完就沉进 `handoffs/`，没有任何东西会再读它**。对侧库的日常入口是 `open-questions.md`，而那些点从未出现在客户端的待答清单里。⇒ **桥接必须落在对侧库的日常入口上，不能落在源侧的历史文档里。**

### A. `Source` 的上行表示：向后端已定的收口对齐

契约侧走字符串成员名（`"FinaleWin"`），存档侧走整数 code，客户端在**序列化边界**做一次映射。连带纪律：**名与 code 双双冻结，重命名成员在两侧都是破坏性变更；已删成员的名与 code 同样永不复用**。未知取值记录原值、不改写、不拒收。合法子集表只约束客户端组装，不在后端复制。

映射发生在 `sync-service` 组装上行负载时，**不在 `profile-service` 内部做**——存档态始终是 code，避免同一个值在内存里有两种形态。

### B. 购买段：客户端侧已完整，补一条路径、两条回链、一条失败语义

`BundleGrantOrdinal` 的 JSON path 定为 `/entitlement/bundleGrantOrdinal`，自此受「透明路径 = 契约的一部分」纪律约束。`monetization.md` 与 `sync-service.md` 各补一条指向后端购买契约的回链。

**购后 pull 失败 = 阻塞在主菜单重试直到成功。** 玩家已付款、后端已 +1，但客户端拉不到新序号 ⇒ 停在主菜单重试，不允许在未兑现状态下开始新轮回。此刻玩家本就在主菜单（购买入口前置条件 1），阻塞代价最小——没有任何进行中的轮回被打断。重试走后端的收据幂等读，`receiptId` 随待兑现态持久化，跨启动也能补查。UI 复用既有阻塞屏变体表，不新增拦截点。

### C. `profile-sync` 七点的客户端形态

| # | 落笔形态 |
|---|---|
| ① | `PlayerPowerFragment` 增 `LastRoll ∈ [0,9999]` / `LastEffectiveChance ∈ [0,10000]`（万分比），均进透明段 |
| ② | 每次 Finale 胜利**必掷骰并写 `LastRoll`**（即使当次不发放）；**首胜写 `LastEffectiveChance = 10000`** |
| ③ | `AccountSeed` 内存态仍是 `ulong`，**序列化形态一律 16 位小写 hex 字符串**；解析失败按必需缺失处置 |
| ④ | 透明路径的移动 / 重命名 = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改；**先按人工清单执行，暂不机械化** |
| ⑤ | 同 A |
| ⑥ | `AccountRng` 换 SplitMix64 纯函数，返回类型改为 `AccountRandom`；抽取链参数放宽到 `IRandomSource` 泛型约束 |
| ⑦ | `PlayerProfileDiff` / `CharacterProfileDiff` 的序列化形态与顶层键浅合并对齐 |

**轮回级 RNG 完全不受影响**，继续用 Godot 的 `RandomNumberGenerator`——只有账号级掷骰跨边界。验收物已现成（后端契约的 8 组测试向量），实现后逐位对表即可，无须等后端动手。

### D. 跨边界承接台账 `open-questions/cross-boundary.md`

两库各立一份同名同形的固定分片，专装「对侧已定案、我方尚未承接」的条目。**与普通待答项的关键区别写在分片抬头**：普通待答项等的是设计裁决，跨边界承接项**答案已经有了，等的只是落笔**——混在普通分片里会让它们和真正的开放问题一起被无限期搁置。

每条形态：`对侧权威文档路径#小节 | 对侧定案日期 | 我方需改的文档 | 一句话摘要`。**只写回链与摘要，绝不复述对侧的设计内容。** 我方落笔完成后从分片移除、记进 `answer-logs/`；两侧条目各自独立关闭，不要求同时。

维护者分工不需要新机制：`/analyze-new-ideas` 跨库落笔时同批写两侧（主库写决策，对侧库立承接项）· `/summarize-open-questions` 对账时发现「一侧已定案、另一侧零承载」即补登 · `/assess-derive-readiness` 只报告缺口、不写对侧。

## Clarifications（interview 产物）

- **「最小随机源接口」写成什么形态？** → **泛型约束接口**：`interface IRandomSource { ulong NextU64(); }`，`AccountRandom` 直接实现，Godot RNG 由 `readonly struct GodotRandomSource` 薄适配；抽取方法写成 `PickOne<TRng>(TRng rng, …) where TRng : IRandomSource`，值类型经泛型特化调用 ⇒ 零装箱、零堆分配，落在既有「热路径不分配」纪律内。这是原始草稿明确留出的唯一实现形态自由度（草稿只写「参数须放宽到一个最小随机源接口」，未定形状）。

## Notes / triage

三处自行推演，依据均在库内既有条文：

- **C① 的字段落点**取 `systems/player-profile/_index.md` 的 `PlayerPowerFragment` 字段表，而非草稿写的 `player-power/_index.md`——后者自己明写「字段清单见 `../_index.md`」。`player-power/_index.md` 只承接 ② 的两条写入约定（那是规则语义，本就归它）。
- **`AccountSeed` 的序列化形态**：草稿只说「存档侧是 `ulong`」。但透明路径 `/accountInfo/accountSeed` 的类型由契约定为 hex16，而后端读到的 profile **就是客户端的序列化形态**（后端原样存取）⇒ 存档与上行的序列化必须同为 hex 字符串，`ulong` 仅是内存态。写成 JSON number 会超 2⁵³ 静默丢低位，且只在部分账号上显形。
- **`AccountRng.For` 的 `ordinal` 参数保持 `int`**，不改成草稿伪码里的 `ulong`：两个调用方（`FinaleWinOrdinal` / `BundleGrantOrdinal`）都是 `int`，改宽会破坏「贯穿整条链路的类型一致性」；`(ulong)` 转换在 `For` 内部做一次，与契约的 `(uint64)(ordinal + 1)` 逐位一致。

草稿「透明路径清单」把两个新字段写作 `/lastRoll` · `/lastEffectiveChance`，缺 `/playerPowerFragment` 前缀；按契约白名单的全路径落笔。

## Open questions

- **B 的两处收尾与 counterpart 同批**：`/entitlement/bundleGrantOrdinal` 的白名单行须两侧同批落笔；回链目标为后端购买域契约。二者在本次已同批完成。
- **C④ 的机械化触发条件**：透明路径机检暂不做（不为一条尚无实例的纪律先行造工具）。**留一条触发条件**：首次真的发生透明路径漂移（后端告警台账记到第一条）时回头升级为机械检查，不等它攒够教训。
