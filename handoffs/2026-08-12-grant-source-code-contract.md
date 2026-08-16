# 授予来源 `Source` 的取值扩清单 —— 契约侧承接

- id: 2026-08-12-grant-source-code-contract
- date: 2026-08-12
- topic: contracts/profile-sync（计划中）· contracts/envelope（枚举序列化那条约定需复核）
- status: distilled
- distilled-to: `contracts/profile-sync.md`（§5 可见字段白名单 · §5a `sourceCode` 的线上表示 · §7a 复算不一致的处置）

## Intent（客户端侧已定 · 2026-08-12）

> **来源**：`game-design-documents/inbox/solution-draft-grant-source-per-kind-scope.md`（`status: decided`）。客户端语义已定，本 handoff 只承接「服务端如何兑现」那一半。

客户端的**授予来源共有字段 `SourceCode`**（类型 `Source`）此前是**封闭三值**，08-12 扩为**按 `(Kind, Scope)` 分域的七值开放清单**。它是一条**会被后端读到**的字段——后端复算道统残卷的分档自变量 `x`。

### 1. 成员清单（客户端 C# `enum Source`）

| 成员 | code | 语义 |
|---|---|---|
| `Unknown` | 0 | 防御性成员，**不是一条途径**：老档缺字段 / 未知取值的归入处 |
| `FinaleWin` | 1 | 渡劫成功时由道统残卷掷中并发放 —— **`x` 的唯一数据源** |
| `PremiumBundle` | 2 | 付费礼包给予 |
| `AchievementReward` | 3 | 成就奖励给予 |
| `EventOutcome` | 4 | 非战斗类 AdventureEvent 的 outcome 授予 |
| `CombatReward` | 5 | 战斗类遭遇的 `Spoils` 授予（Finale 的残卷那一路走 `FinaleWin`） |
| `ExchangePurchase` | 6 | Exchange（交易）事件中购买所得 |
| `InitialGrant` | 7 | 开局初始持有（角色创建时的起手配置） |

**已删成员的取值（名与 code 双双）永不复用。**

### 2. 后端需要兑现的四条

- **`x` 的复算口径不变**：`x = count(PlayerPower where SourceCode == FinaleWin)`。扩清单**不改后端任何复算逻辑**——新增四个成员没有一个能出现在法则上并被计入。
- **未知取值的处置必须与客户端一致：记录原值、不改写、不拒收。** 客户端读档侧的既定语义是「无法识别 → 告警 + 保留原值，不阻塞」。**若后端把未知取值归一为 `Unknown` 并在下行时回写，会直接压低 `x`、让残卷档位回跳**——而「`x` 单调不减 ⇒ 档位只降不回跳」是客户端 08-09b 的承重不变式。这是本 handoff 最要紧的一条。
- **合法子集表不在后端复制。** 客户端有一张 `(Kind, Scope) → 允许的 Source 集合` 静态表，约束的是**客户端的 element 组装**（`Op == Grant` 时非法组合 → 拒绝整批）。后端只做取值识别与 `x` 复算，**不要把这张表做成第二处真值**——两处各自演进必然漂移，而它约束的行为根本不发生在服务端。
- **`SourceCode` 属「后端可见字段子集」**（`contracts/envelope.md` §Profile 三段可见性里的「复算所需的规则字段」那一档），随 `profile-sync.md` 成文时逐字段列进契约。

### 3. 字段落点

`SourceCode` 落在**持有条目**上（不是内容定义上），四类各一：`PlayerPower` / `PlayerItem`（账号级，随 `PlayerProfile` 上行）· `CharacterPower` / `CharacterItem`（轮回级，随 `CharacterProfile` 上行）。**只有账号级法则那一份参与 `x` 复算**；其余三类对后端是纯透传数据，无规则用途。

## Open questions（三条已于 2026-08-14 全部答结）

> 三条均由 `handoffs/2026-08-14-profile-sync-contract.md` 定案，结论落 `contracts/profile-sync.md`：
> ① 枚举序列化冲突 → **收口①**（契约侧字符串名 `"FinaleWin"` + 存档侧整数 code + 客户端在序列化边界一次映射；连带「`Source` 的名与 code 双双冻结」）→ §5a。
> ② `x` 复算的触发时机与不一致处置 → 在 **`finaleWinOrdinal` 递增的那一次 push** 上复算；不一致**仅记账 + 上报风控，不拒绝、不改写** → §7 · §7a。
> ③ 轮回级两类的 `sourceCode` 是否进透明档 → **不进**（`characterDiffs` 整体不透明；它对后端无规则用途，而每条透明路径都要背上路径稳定性约束）→ §5。
>
> 以下保留原始措辞作溯源。

- **⚠ 与 `contracts/envelope.md` 的枚举序列化约定正面冲突（承重 · 须先答）。** `envelope.md` 定「**枚举值一律字符串，取值与客户端 C# 枚举名逐字相同**」，理由是同名可省掉一整张最容易写漏的映射表；而客户端 08-10b 定的是「**code = 显式稳定整数，是存档 / 上行负载里实际序列化的东西**，重命名成员不破坏存档」。**两条都明写覆盖「上行负载」，不能同时成立。**

  三种收口：
  1. **契约侧走字符串名、存档侧走整数 code，客户端在序列化边界做一次映射**（enum 天生能做）。保住 `envelope.md` 的通则不开例外；代价是「重命名成员」的自由只剩存档侧，契约侧重命名仍是一次破坏性变更——需补一条「成员名与 code 双双冻结」的纪律。**倾向此项**（通则不开例外的价值高于重命名自由，而重命名本就极少发生）。
  2. **给 `Source` 在 `envelope.md` 开一个整数例外**。代价是「有例外的通则不是通则」——`envelope.md` 自己在 GET-body 那条上用过这句反驳。
  3. **两侧统一改用整数 code**，推翻 `envelope.md` 的字符串枚举约定。影响面远超本 handoff（`OpError.code`、`reason`、三分支应答的枚举全在内），不建议为一个字段掀桌。

  **这条须先答，它决定 `profile-sync.md` 里 `SourceCode` 写成什么类型。** 客户端侧的 `game-design-documents/systems/common-properties.md` 相应表述（「code 是上行负载里实际序列化的东西」）**在收口后需一并修正**——那句话是在 `envelope.md` 成文之前写下的。
- **`x` 复算的触发时机与不一致时的处置**：后端在 `POST /v1/profile/push` 时复算并与客户端上报值比对？不一致时是拒绝（`Conflict`）、静默以后端值为准，还是仅记账告警？强制在线 · 云端权威（`game-design-documents/decisions/ADR-0003`）指向「以后端为准」，但残卷的 `Accumulated` / `FinaleWinOrdinal` 是同一族字段、且已定「客户端掷骰、后端可复算」——三者的处置应一次定齐，归 `profile-sync.md`。
- **轮回级两类的 `SourceCode` 是否需要进「后端可见字段子集」的透明档**？它对后端无规则用途（纯透传）。若 `CharacterProfile` 整体已按不透明 blob 上行，则本字段无需单列——取决于 `profile-sync.md` 对轮回级 profile 的可见性分档，未定。

## Notes / triage

- 本 handoff **不产出 `profile-sync.md` 报文本体**——它是该文档成文时的一份输入。
- 客户端侧无需等待本 handoff：扩清单在客户端可独立落地（后端尚未开工，边界服务仍是离线 stub）。**唯一的真前置是上面第一条枚举序列化冲突**，它决定线上表示形态。
- 可与 `game-design-documents/inbox/_index.md` 里另外两笔待办的后端 handoff 合并处理——但那两笔的客户端侧仍 `awaiting-review`，**本笔已 `decided`，不必等它们**。

## 客户端侧影响

**是**——本 handoff 触及客户端 ↔ 后端边界的语义。

- 受影响的客户端成分：**`sync-service`**（`SourceCode` 随两层 profile 上行）。`account-service` / `content-service` 无关。
- `game-design-documents/` 侧需同步更新的文档：`systems/common-properties.md`（「授予来源共有字段」整节重写 + **上述枚举序列化冲突收口后修正「code 是上行负载里实际序列化的东西」那句**）、四类各自的 `common-properties.md`、`systems/services/profile-service.md`、`systems/player-profile/player-power/_index.md`。
- 客户端侧的落笔由 `/analyze-new-ideas game-design-documents/inbox/solution-draft-grant-source-per-kind-scope.md` 承接，**不由本 handoff 承载**。
