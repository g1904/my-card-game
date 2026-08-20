---
type: solution-draft
date: 2026-08-18
question: `GameSetting` 的设置项清单、设备本地项 vs 账号级项的切分、以及写入通道分别是什么？
source: open-questions.md（derive 就绪度：`systems/player-profile/game-setting.md` = blocked）· open-questions/deferred-content.md「GameSetting 的设备本地项 vs 账号级项切分」· systems/player-profile/game-setting.md#待决问题
targets: systems/player-profile/game-setting.md · systems/player-profile/_index.md（15 字段表第 15 行的「层 / 写入通道」两格）· systems/services/profile-service.md（`ProfileChangeSpec` 分列 + 施加失败语义表）· systems/services/sync-service.md（schema bump 清单 · PushPolicy · 闸门口径）· ux/error-and-blocking-ux.md（locale 归一链条）· ux/screen-flow.md（Settings 屏形态）· systems/architecture.md（共享核心类型）
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-game-setting-schema.md
---

# 方案 — `GameSetting` 的设置项清单、本地 / 账号切分与写入通道

## 问题

`PlayerProfile` 的第 15 个字段 `gameSetting` 至今只有一句语义（「账号级常规系统设置，音量等」）与一条形态纪律（**具名类，不是字典**），**类内一个字段也没有**。三处在册待答项指向同一个空洞：

- `systems/player-profile/game-setting.md`：设置项清单未定 · 设备本地项 vs 账号级项切分未定。
- `systems/player-profile/_index.md` 的 15 字段表：第 15 行的**「层」与「写入通道」两格皆为 `⟨待定⟩`**。
- `systems/services/sync-service.md`：`CodexEntry` / `GameSetting` 两个子对象 schema 未定 ⇒ **本地缓存序列化写不出这两块的具体类型**。

它卡住的东西是具体的：`game-setting.md` 已给出落笔顺序纪律——**先答切分，再一次性定清单**，因为切分那一条决定哪些字段进 `PlayerProfile`（云端权威 · 进 diff · 进 schema · 进迁移）、哪些留 `user://`；在它答定前填字段等于替用户拍板一次同步口径。故本草稿按该顺序组织：§1 切分判据 → §2 清单 → §3 两侧的落点与 schema → §4 写入通道与 `PushPolicy` → §5 locale 衔接 → §6 版本化与加项策略。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| C1 | **`GameSetting` = 具名类，绝不是字典 / 键值表。** 开放容器把「拼错了」从编译期推迟到运行时，还让「哪些项是账号级」这个真问题被悄悄绕过 | `systems/player-profile/game-setting.md`；同款判据见 `CapabilityFlag` 用 `enum`、`PlayerEntitlement` 用具名字段 |
| C2 | **强制在线 · 云端权威**；本地 `user://` 仅缓存 / 临时态，冲突一律以云端为准，**不做静默合并、不引入字段级三路合并** | `decisions/ADR-0003` · `systems/services/sync-service.md` |
| C3 | **`ProfileManager.TryApply(spec)` 是两层 Profile 的唯一写入面**（全有或全无）；字段不提供 setter | `systems/services/profile-service.md` |
| C4 | **一次 `TryApply` 提交 ⇒ 一次本地原子写**；push 另计（存档点 + 5 秒防抖）。**不允许「提交了但不落盘」** | `systems/services/sync-service.md`「存档点与 push 解耦」 |
| C5 | **软阻塞闸门只计四类事件级存档点**（轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束），**不含其余本地写入** | 同上「缓冲上限（两个闸门）」 |
| C6 | **语言开关只有一个，启动期把 locale 归一到封闭二值 `zh` / `en`（单点）**；内容层不另设第二个语言设置。「日后若加游戏内语言设置项，**它写入的也是同一个单点**」 | `ux/error-and-blocking-ux.md`「语言开关只有一个」 |
| C7 | **`en` 列全部预设占位符**；现在做的是**键与结构**，不是实际英文文案 | 同上 · `vision/scope.md` |
| C8 | **永久快速演出为设置项，默认关**，开启后基线节拍 0.2 s | `ux/combat-ux.md`「敌人回合的逐步执行呈现」节奏一条 |
| C9 | 全库已定的三处触觉反馈皆为**无震动**（揭示转场明写「无震动」）；「寿元告警是否伴随音效 / 震动」**仍在待答清单** | `ux/screen-flow.md` · `handoffs/2026-08-17c` · `open-questions/deferred-content.md` |
| C10 | **不做二次确认**是已定案的手感取向（主动退出静默、单点即确认、误触不做保护）；而**解绑 / 绑定冲突两处的二次确认是安全性必需** | `ux/combat-ux.md` · `life-cycle-service.md` · `ux/screen-flow.md` |
| C11 | Settings 屏**外加一行只读的「同步版本 #N」**，取自 `SyncService.BaseRevision`——**只读诊断用，不参与玩法判断** | `ux/screen-flow.md` · `systems/services/sync-service.md` API 面 |
| C12 | `user://cache/` 已有三份设备维度小文件的既定形态：`flags.json` · `sync-envelope.json` · `dismissed-recommended-version.json`——**原子写、跨启动保留、不进存档、不进 Profile、不上云**；后者**明确不按 `accountId` 分区**（「它是设备维度的呈现状态，不是账号数据」） | `systems/services/sync-service.md` · `ux/error-and-blocking-ux.md` |
| C13 | **集合 / 字段名单数通则 + camelCase 单点策略机械映射为 JSON path** ⇒ Profile 透明段字段改名 = 破坏性契约变更 | `systems/player-profile/_index.md` · `sync-service.md`「JSON 序列化命名策略」 |
| C14 | **账号级字段分两层**（规则字段层 / 统计计数层），判据 = 有没有被**规则**读 | `systems/player-profile/_index.md` |
| C15 | 音频分两族：**BGM**（战斗 / 事件·探索）与**音效**（UI 音效 / 反馈音效） | `art/soundtracks/_index.md` |
| C16 | 浮点在存档字段上已被排除一次：`PlayerPowerFragment.Accumulated` 取**万分比整数**，理由是存档 / 跨端一致性 + 可复算 + 避免浮点比较 | `systems/player-profile/_index.md` |

---

## 建议方案

### 1. 切分判据（先答这一条）

`[既有推演]`

> **一句话判据：这一项的正确取值是否取决于「这台机器」——硬件能力、系统环境、或只在本机成立的呈现状态？取决于 → 设备本地；纯粹是玩家的偏好、换台手机也应当跟着走 → 账号级（`GameSetting`）。**

**推论 ①（用来自检的反问）：** 「玩家换了一台新手机、登录同一个账号，他会不会觉得这一项**理应已经是他上次调好的样子**？」会 → 账号级；「新机器上本来就该重新调一次」→ 设备本地。这条反问与上面的判据同解，但更容易在评审时执行。

**推论 ②（拿不准时归哪一侧）：归设备本地。** 两侧成本不对称：账号级一项 = 进 `PlayerProfile` + 进 diff + 进存档 schema + 进迁移路径 + 受 camelCase 机械映射约束（C13）；设备本地一项 = 一个 JSON 字段，可无损重建（玩家重设一次即可）。故**默认落设备本地，只有确实通过上面反问的才升上去**。这与 `PlayerStatistics`「首批清单的价值在于小而无歧义」同向。

**推论 ③：切分不等于两个开关。** 一项设置**只能落一侧**，绝不两侧各存一份——那正是 C6 拒绝「内容层另设一个语言设置」时点名的形态（「设置屏会长出两个开关」）。

**连带：`GameSetting` 这个类只承载账号级那一半，不是「全部设置」。** 建议在 `game-setting.md` 明写这层包含关系（**设置 ⊃ `GameSetting`**），否则「设置项清单」这个词会被读成只有一份表，而设备本地那一半会无处登记。

### 2. 设置项清单（逐项给存在依据；**不凭空堆砌**）

判据是**「游戏里已经存在这个东西可调吗」**。已定案的面反推出来的只有下面这些；其余候选一律列在 §2.3 的「首批不收」并写明**解除条件**。

#### 2.1 账号级（落 `GameSetting`）—— 建议四项

| # | 字段 | 类型 | 取值域 | 默认 | 依据 | 判据自检 |
|---|---|---|---|---|---|---|
| 1 | `MasterVolume` | `int` | `[0, 100]` | `100` | `[既有推演]` `game-setting.md` 明写「音量等」；`handoffs/2026-07-16` 的 Settings = 「音频开 / 关等」 | 换手机后当然该跟随 ⇒ 账号级 |
| 2 | `MusicVolume` | `int` | `[0, 100]` | `80` | `[既有推演]` C15：BGM 自成一族（战斗 BGM / 事件·探索 BGM），且明写「须无缝循环、不易听腻、不抢文本注意力」——这正是玩家最想单独调低的一轨 | 同上 |
| 3 | `SfxVolume` | `int` | `[0, 100]` | `100` | `[既有推演]` C15：UI 音效 + 反馈音效自成一族，且明写「出牌音会在一局内响几十次」 | 同上 |
| 4 | `FastCombatAnimation` | `bool` | — | `false` | `[既有推演]` **C8 已经把它定为设置项且给了默认值**——本条不是新提案，是把一条已定案的设置项如实登记进类里 | 是纯节奏偏好、与硬件无关；且反复游玩者一旦开了就不想每台机器重开 ⇒ 账号级 |

```csharp
public sealed class GameSetting          // 既非规则字段层、也非统计计数层：不被任何规则读，也不是计数
{
    public int  MasterVolume        { get; }   // 0–100 线性档位
    public int  MusicVolume         { get; }   // 0–100
    public int  SfxVolume           { get; }   // 0–100
    public bool FastCombatAnimation { get; }   // 默认 false；开启后敌人回合基线节拍 0.2 s（C8）
}
```

**四条连带纪律（都可机械检查）：**

- **不设 `IsMuted` / `AudioEnabled` 布尔。** `MasterVolume == 0 ⟺ 静音`——一次纯派生读取。这与「不设 `HasPremiumBundle`，因为 `HasPremiumBundle ⟺ BundleGrantOrdinal > 0`」是**逐字相同**的判据：**让重复字段从一开始就不存在**，比任何注释可靠。
- **音量存 `int` 0–100 的线性档位，不存 `float`、不存 dB。** `float` 由 C16 直接排除（同一条「存档 / 跨端一致性 + 避免浮点比较」）；dB 是**呈现层的换算**——`AudioServer.SetBusVolumeDb(bus, Mathf.LinearToDb(v / 100f))` 在音频层做一次，换算规则收敛在代码一处、**不进存档**。理由与「`Source` 上行走成员名、存档走整数 code，映射只在组装上行负载时做一次」同构。
- **类内禁用 `Ordinal` / `Total` / `Count` 三个词缀。** 15 字段表里本类的「层」列是 `—`（既不参与规则判定，也不是统计计数）；这三个词缀在本库各自绑定一层（`Ordinal` ⇒ 规则层、`Total` / `Count` ⇒ 统计层），出现在本类里即意味着有人把它当成了另一层的字段。**禁用即让「层 = `—`」这一格可机械检查。**
- **`gameSetting` 字段名已合规单数**（C13），类内字段亦无集合。

#### 2.2 设备本地（落 `user://cache/device-settings.json`）—— 建议一项

| 字段 | 类型 | 取值域 | 默认 | 依据 | 判据自检 |
|---|---|---|---|---|---|
| `locale` | `string?` | `"zh"` \| `"en"` \| **缺省 / `null` = 跟随系统** | 缺省 | `[既有推演]` C6 已经预留了这个位置（「日后若加游戏内语言设置项，它写入的也是同一个单点」）；本条只是给那句话一个落点 | **判给设备本地，理由见 §5**——账号级会在登录屏造成一次可见的语言跳变 |

首批只有一项，形态与既定的 `dismissed-recommended-version.json`（**单字段**文件）完全同款，故不构成一个新的文件类别。

#### 2.3 首批不收的候选（逐条写明为什么，以及**什么时候该补**）

| 候选 | 建议 | 理由 | 解除条件（触发即补） |
|---|---|---|---|
| **震动 / 触觉反馈开关** | `[既有推演]` **不收** | C9：游戏里**当前一处震动都没有**（揭示转场明写「无震动」），且唯一可能引入震动的点（寿元告警）**本身还是一条待答项**。收它 = 交付一个不控制任何东西的空开关，玩家关掉它什么也不会变 | 「寿元告警是否伴随音效 / 震动」答定为**有震动**，或战斗 UX 专场引入任一触觉反馈 ⇒ 补一项**设备本地** `haptics: bool`（触觉是硬件能力，且部分机型无马达 ⇒ 判据判给设备本地） |
| **画质档 / 分辨率缩放** | `[通行做法]` **不收** | 本作是 2D 卡牌、渲染器已锁 **GL Compatibility**（本身即最低负载档），没有可供分档的渲染负载；且「画质」在 2D 项目里通常只能退化成一个安慰性开关 | 真机实测出现掉帧 / 发热，且确认存在一个**真的能换来帧率**的开关（如粒子密度 / 特效层数）⇒ 补**设备本地**项 |
| **帧率上限（30 / 60）** | `[通行做法]` **不收（但是最有可能第一个被补上的一项）** | 移动端省电确有价值，且本库确实在意电量（`sync-service.md` 两处以「空耗电量与流量」为由暂停退避重试）。但**当前无任何实测证据**说明本作需要它 | 真机功耗实测给出可观差值 ⇒ 补**设备本地** `frameRateCap: int` |
| **二次确认开关** | `[既有推演]` **不收，且建议明确否决** | 它会同时踩两条已定案：① C10 的手感取向「不做二次确认」是**规则层的定案**，不是可由玩家切换的偏好；② 已定的两处二次确认（解绑 · 绑定冲突）是**安全性必需、不可关**。一个「二次确认」开关必然要么关不掉那两处（名不副实），要么关得掉（削弱一条安全纪律） | 无。若日后确需，应是逐处的产品决策，不是一个总开关 |
| **辅助功能（字号 / 色盲 / 减少动效）** | **不收** | 字号与色盲当前**没有任何既有陈述**可依，凭空定会直接撞上「绝不臆造」；「减少动效」与已收的 `FastCombatAnimation` 高度重叠，两个开关会互相解释不清。至于「无 hover-only 可供性」，`.claude/rules/ui-input-rules.md` 已把它定为**全局设计通则**——由通则承担的东西不该退化成一个可关的选项 | 无障碍专场；或战斗 UX 专场确认动效强度确实需要独立于速度的第二个旋钮 |
| **内容语言（与界面语言分离）** | `[既有推演]` **明确否决** | C6 逐字点名过这个形态：「否则设置屏会长出两个语言开关，玩家能把界面切成英文而卡面留在中文」 | 无 |
| **「同步版本 #N」** | `[既有推演]` **它不是设置项，不进 `GameSetting`** | C11：它是 `SyncService.BaseRevision` 这个**只读属性**在设置屏上的一次呈现，UI 直读即可。把它写成 `GameSetting` 的字段 = 制造第二份真值，且会把一个传输层元数据卷进存档 schema——与「`baseRevision` / `schemaVersion` 不进 Profile，进去会自指」同一条判据 | 无。建议在 `game-setting.md` 里**明写这条排除**，因为「设置屏上看得见的东西 = `gameSetting` 的字段」是一个非常自然的误读 |
| **已关闭的推荐版本号** | **保持既定落点不动** | 已定案落 `user://cache/dismissed-recommended-version.json`（C12）。**不并入** `device-settings.json`——两者生命周期不同（一个是玩家显式偏好、一个是一次性呈现去重状态），合并只换来一次改动、不换来任何收益 | 无 |

### 3. 两侧的落点与 schema

#### 3.1 账号级：`PlayerProfile.gameSetting`

`[既有推演]`

- **15 字段表第 15 行两格填法建议：** 「层」= **`—`（偏好层：既不被规则读，也不是统计计数）**；「写入通道」= **`SettingChanges`**（见 §4）。
- **不进透明段。** 后端不读它、不复算它、不据它发放任何东西 ⇒ `/gameSetting/**` **不应出现在** `backend-design-documents/contracts/profile-sync.md` §5 的透明路径白名单里。本库不复制那张表，但**这条否定结论值得在 `game-setting.md` 明写**——否则日后有人看到「Profile 字段都受路径稳定性纪律约束」会以为改个音量字段名也要与后端同批改。（**它仍受 C13 的机械映射约束**：字段名 = JSON path，改名仍要 bump `schemaVersion`；只是**不需要后端配合**。这两件事必须分开说。）
- **读档校验（可选缺失口径，绝不阻塞登录）：**

  | 情形 | 语义 | 处置 |
  |---|---|---|
  | 三个音量字段越界（`< 0` 或 `> 100`） | 可选缺失 | `GD.PushWarning` + **钳制**到 `[0, 100]`。与 `Accumulated` 越界钳制同口径 |
  | 整个 `gameSetting` 缺失（老档） | 可选缺失 | 全字段取默认值，**不告警**（这是迁移的正常路径） |
  | 单个字段缺失 | 可选缺失 | 取该字段默认值 + `PushWarning`（带字段名） |

  **一律不阻塞、不由历史重建**——设置是纯偏好，读不出来的最坏后果是玩家重调一次滑条。

#### 3.2 设备本地：`user://cache/device-settings.json`

`[通行做法]` + `[既有推演]`（形态完全沿用 C12 的三份既有小文件）

```json
{ "schemaVersion": 1, "locale": "zh" }
```

- **同处、同纪律**：与 `flags.json` / `sync-envelope.json` / `dismissed-recommended-version.json` 同在 `user://cache/`，**原子写（临时文件 → rename）· 跨启动保留 · 不进存档 · 不进 Profile · 不上云 · 不进 diff**。经 `LocalCacheManager` 写（它已是 `user://` 原子写的既定归口）。
- **不按 `accountId` 分区**，沿用 `dismissed-recommended-version.json` 的既定理由：**它是设备维度的状态，不是账号数据**。
- **切账号不失效（承重，且与另外两份相反，必须明写）。** `sync-envelope.json` / `flags.json` 切账号即失效，因为它们**内含账号绑定的数据**；`device-settings.json` 一个账号字段也没有，切账号清掉它只会让玩家的语言在换号时莫名其妙地跳回系统语言。**「`user://cache/` 下的文件切账号即失效」不是一条通则，是那两份文件各自的性质**——本条建议在 `game-setting.md` 与 `sync-service.md` 各留一句，防止后来者按通则理解。
- **它必须能在启动链最早期被读**（locale 归一发生在**登录之前**，见 §5）⇒ **它不得依赖 `account-service` / `sync-service` / `ContentRegistry` 的任何东西**。这是一条承重的时序约束：一旦有人给它加了一个「按账号取默认语言」的字段，归一就再也不能在登录前完成。
- **读取失败的口径：整份可选缺失。** 文件不存在 / 解析失败 / `schemaVersion` 不认识 / `locale` 不在 `{zh, en}` 内 → **`PushWarning` + 整份丢弃 + 回落「跟随系统」路径**，绝不阻塞启动、绝不弹任何东西。
- **它不走 `MigrationManager`。** 判据：**存档不可无损重建，本文件可**（玩家重设一次）。为一份可丢弃的偏好文件建逐版迁移路径是白付成本；`schemaVersion` 字段仍然要留——它让「不认识就整份丢弃」这个动作有依据可判。

### 4. 写入通道与 `PushPolicy`

#### 4.1 写入通道：`ProfileChangeSpec` 新增一列 `SettingChanges`

`[既有推演]` · **本项已定案取 A，见「用户裁决」②**

`GameSetting` 的字段**不提供 setter**，唯一写入路径经 `ProfileManager.TryApply`（C3）。按 `ProfileChangeSpec` 的既定分列判据——**「施加语义根本不同就分列」，且「列表数不进承重表述」**——设置的施加语义是：

> **绝对置值 · 无量纲 · 按 key 配表钳制 · 绝不走 modifier pipeline。**

这与 `StatusChanges` 逐条相同，但**作用对象不同**（`StatusChanges` 明写绑定 `CharacterProfile.Status` 上的**规则字段**）。故建议**独立成列**：

```csharp
// ProfileChangeSpec 增第八列
IReadOnlyList<SettingAssignment> SettingChanges { get; }

public readonly record struct SettingAssignment(SettingKey Key, int IntValue, bool BoolValue);

public enum SettingKey { MasterVolume, MusicVolume, SfxVolume, FastCombatAnimation }
```

- **双字段单列表，沿用 `StatusAssignment` 的既定先例**：由配表 `SettingFields` 的 `Kind` 决定哪一格有效，另一格填缺省。既定原文已给过判据——**「双字段单列表的浪费是每条一个空引用，代价近零」**，而**拆成 `SettingInts` / `SettingBools` 两个列表必然出现「加了这张忘了那张」**（与 `StatusFields` 拒绝分表同一条）。
- **配表 `SettingFields`（每个 key 一行，与 `StatusFields` / `ResourceElements` 同款）：**

  | Key | Kind | Min | Max | 默认 |
  |---|---|---|---|---|
  | `MasterVolume` | `Int` | 0 | 100 | 100 |
  | `MusicVolume` | `Int` | 0 | 100 | 80 |
  | `SfxVolume` | `Int` | 0 | 100 | 100 |
  | `FastCombatAnimation` | `Bool` | — | — | `false` |

  **默认值就住在这张表里，是唯一一处。** 老档补默认与 UI 初值读同一行——两处各写一份必然漂移。

- **施加失败语义（追加进 `profile-service.md` 的那张表）：**

  | 情形 | 语义 | 处置 |
  |---|---|---|
  | `SettingAssignment.Key` 在 `SettingFields` 中无对应行 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝（缺行 = 值类型与取值域皆不明；与 `StatusAssignment` 同款） |
  | `Kind` 与非缺省格不匹配（`Bool` 型却填了 `IntValue`） | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝 |
  | `Int` 型置值越界 | **可选缺失** | `PushWarning` + **钳制**到 `[Min, Max]`（**不整批拒绝**——把一个滑条拖过头变成一次整批失败不成比例） |
  | 同一批 `SettingChanges` 内出现两条同 `Key` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（绝对置值下两条同 key 意味着调用方自己也不知道该落哪一份；与 `EventStateChanges` 同款） |
  | `SettingChanges` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款、独立成行。理由同构：成本侧只放**可如实计价的量**，而「把音量调到 60 值多少寿元」无法回答） |

- **恒不经 modifier pipeline。** 理由与统计层同源：否则**一条法则能改写玩家的音量与演出速度**。

#### 4.2 提交时机：滑条**释放**时提交一次，不是拖动中每帧提交

`[既有推演]`（这是 C4 的直接后果，不是新机制）

「一次 `TryApply` ⇒ 一次本地原子写」是承重纪律。一根拖动中的滑条若每帧提交，就是**每帧一次磁盘原子写**。故：

- **拖动过程中只做实时预览**——直接改 `AudioServer` 的 bus 音量让玩家听见，**不碰 profile**。
- **`drag_ended` / 开关切换那一刻提交一次 `TryApply`**（`SettingChanges` 一条）。
- **离开设置屏时若存在未提交的预览值，强制提交一次**（防「拖到一半直接返回」丢掉改动）。
- 这是**UI 侧的一条纪律，不新增任何机制**；与「`Project(spec)` 不是第二个写入点」同类——把「预览」与「提交」分清，写入面仍然只有一个。

#### 4.3 `PushPolicy` = `Debounced`，**不进立即 flush 清单**

`[既有推演]`

既定的强制立即 flush 清单五项——篇章边界 · 轮回结束 · 角色 `defeated` · 进入战斗前 · **应用失焦 / 挂起**——共性是**「不发出去就会丢玩家进度」或「这是被系统杀死前的最后机会」**。一次音量变更丢失的代价是一个滑条位置，玩家重调一次即可。故：

- **设置变更走 `PushPolicy.Debounced`**，`SavePointReason` 取既有的 **`MetaChanged`**（该成员已在枚举中、正是为轮回外的元数据变更准备的），**不新增 reason、不新增 flush 点**。
- **它天然被既有的「应用失焦 / 挂起」flush 兜住**：玩家改完设置切后台 ⇒ 那次 `Immediate` flush 顺带把它带走。**这正是「不必为设置新增 flush 点」的完整理由**——不是「丢了也无所谓」，而是**既有机制已经覆盖**。
- **设置变更不是事件级存档点 ⇒ 不计入软阻塞闸门**（C5）。**这条必须明写**：否则一个在主菜单反复拖滑条的玩家会在离线时把闸门（未同步事件级存档点 ≥ 3）推满，弹出一个「网络异常，正在重连」的模态——显然不是那个闸门的本意。这与「决策点存档不计入闸门」是**同一条推论的第二个实例**：**闸门计的是 push 单位，不是本地写入单位。**
- **离线时改设置照常可用**：进待发队列、不阻塞（断线降级表的 push 行本就不按 `PushPolicy` 分叉）。**代价明写见「与既有决策的张力」②。**

### 5. 语言设置与 locale 启动期归一的衔接

`[既有推演]` —— **C6 是本题最硬的已定案约束，方案必须与它零冲突。**

#### 5.1 为什么语言判给**设备本地**（而不是账号级）

启动链的既定顺序是：**locale 归一（启动期，影响登录屏的 T&S / 渠道按钮 / 错误文案）→ 登录 → 启动全量 pull**。若 `locale` 是 `GameSetting` 的字段：

1. 登录屏必然只能用**系统 locale**（此刻 profile 还没拉下来）；
2. pull 成功后才拿到玩家设定的语言 ⇒ **主菜单出现的那一刻语言跳一次变**；
3. 「归一只发生一次（单点）」这条纪律要么被打破（变成两次 SetLocale），要么就得接受登录屏永远无视玩家的语言选择。

三条都不可接受，而它们都是**账号级这个归属直接导致的**。故建议：**`locale` 落设备本地**，它在启动链的**最早一步**（登录之前、无任何依赖）被读到。

**代价明写：换设备后语言不跟随，新设备回落「跟随系统」。** 这个代价的实际影响很小——语言的默认路径（系统 locale）在新设备上通常**本来就是玩家想要的那个**，这正是「设备本地」判据反问所要的答案。

#### 5.2 归一链条的改写（**只在链首加一个可选覆盖来源，单点不变**）

```
启动期 · 登录之前 · 只执行一次（单点）
  1. 读 user://cache/device-settings.json 的 locale
        └ 缺失 / 解析失败 / 值不在 {zh,en} → PushWarning + 跳到 2
  2. 无覆盖值 → 读系统 locale
  3. 取主语言子标签（zh_CN / zh_TW → zh，en_US → en）
  4. 非 zh / en 一律置 zh
  5. TranslationServer.SetLocale(该二值)
```

- **第 2–5 步与既定文本逐字相同**，本方案只加了第 1 步这一个**可选**覆盖来源。
- **C6 的「日后若加游戏内语言设置项，它写入的也是同一个单点」被如实兑现**：设置屏改语言 = 写 `device-settings.json` + 调用**同一个归一入口**重跑一次 → `SetLocale`。**不需要重启应用**：`res://text/` 侧由 `tr()` / `auto_translate` 重取，内容层侧 `LocalizedText.Get()` 本就直读 `GetLocale()`、**零分支**。
- **两层仍共用同一个开关**（C6 的承重纪律原样成立，一个字都不松动）。
- **归一入口必须仍然只有一处**：设置屏不得自己调 `TranslationServer.SetLocale`，只能调那个单点。否则「非 zh/en 置 zh」这条兜底会在设置路径上被绕过。

#### 5.3 首批是否**在设置屏暴露**语言项

`[已定案]`（见「用户裁决」④：首批隐藏语言开关）

C7 明写 **`en` 列全部预设占位符**。**首批就把语言开关暴露给玩家，等于给他一个通往一片占位符的入口。** 建议：**字段、文件、归一链条的覆盖口首批就落**（结构先行），但**设置屏的语言行首批隐藏**，待 `en` 列有实际文案后再开。这与既定的「现在做的是**键与结构**，不是实际的英文文案 / 现在不做多语言，但现在就不能挡住多语言」**逐字同向**。

### 6. schema 版本化与新增设置项的迁移 / 默认值策略

`[既有推演]`

#### 6.1 本次的 bump

- **`PlayerProfile.gameSetting`（`GameSetting`，4 字段）追加进 `sync-service.md`「两层 Profile 的字段面收口」那一次 **既有** bump 的清单里，不另起一次。** 该处已写明纪律：「**后续同批新增的字段追加进本清单，不另起一次 bump**」——照做即可。
- **老档补默认值口径：** `gameSetting` 缺失 → 按 `SettingFields` 表的默认列全字段补齐（无损）。**当前无线上存档 ⇒ 实际为空迁移**，走既有 `MigrationManager` 骨架。
- `ProfileChangeSpec` 增第八列 `SettingChanges` ⇒ **`PastEventEntry.AppliedChange` 的形状随之变**（与既有的 `PlotElements` / `EventStateChanges` 增列同款），一并写进同一行迁移说明。
  > **附带的一条自洽性检查：** `SettingChanges` 在 `SelectCost` 内恒为空（§4.1 不变式），且设置变更**永远不发生在事件结算里**（它只在设置屏发起）⇒ **`AppliedChange` 里实际永远不会出现 `SettingChanges` 条目**。这不构成「那就别加进 `ProfileChangeSpec`」的理由——列的存在是因为**写入面唯一**（C3），而 `AppliedChange` 只是忠实记录那一次 spec 里有什么。

#### 6.2 新增一个设置项的成本（这是本方案要交付的**可加性**）

| 侧 | 加一项要做什么 | 迁移 | 后端 |
|---|---|---|---|
| **账号级** | `GameSetting` 加一个具名字段 + `SettingKey` 加一个成员 + `SettingFields` 加一行 + **bump 一次 schema** | 老档缺字段 → 取该行默认值（**无损**） | **零配合**（不进透明段） |
| **设备本地** | `device-settings.json` 加一个字段 | 缺字段 → 取默认（**无损**）；**不 bump 任何 schema** | 零 |

- **形态与 `PlayerEntitlement` 的既定表述逐字同构**：「日后真新增第二个付费点 = 本类加一个具名字段 + bump 一次 schema」。**这是 C1「具名类而非字典」换来的东西**——加项的成本是可预期的四步，而不是一个「往字典里塞个新 key」的口子。
- **推论：设备本地那一侧新增字段的成本近乎为零** ⇒ 与推论 ②「拿不准时归设备本地」互相印证。
- **不给设置项做「版本化的默认值」**（即「老玩家沿用旧默认、新玩家用新默认」）。它需要在存档里记「这个字段是显式设置的还是默认的」，等于给每个设置项加一个伴生布尔——为一个只影响观感的场景付双倍字段，不成比例。**改默认值就是对所有未显式设置过的玩家一起改**，明写接受。

---

## 具体形态（可 derive 的落地面）

### A. `PlayerProfile` 15 字段表第 15 行的填法

| # | 字段 | 类型 | 层 | 写入通道 | 权威 |
|---|---|---|---|---|---|
| 15 | `gameSetting` | `GameSetting`（4 字段） | **—（偏好层）** | **`SettingChanges`** | `game-setting.md` |

### B. 两侧字段全表

| 归属 | 键 | 类型 | 取值域 | 默认 | 载体 | 进 diff | 进存档 schema |
|---|---|---|---|---|---|---|---|
| 账号级 | `MasterVolume` | `int` | 0–100 | 100 | `PlayerProfile.gameSetting` | ✅ | ✅ |
| 账号级 | `MusicVolume` | `int` | 0–100 | 80 | 同上 | ✅ | ✅ |
| 账号级 | `SfxVolume` | `int` | 0–100 | 100 | 同上 | ✅ | ✅ |
| 账号级 | `FastCombatAnimation` | `bool` | — | `false` | 同上 | ✅ | ✅ |
| 设备本地 | `locale` | `string?` | `zh` \| `en` \| 缺省 | 缺省（跟随系统） | `user://cache/device-settings.json` | ❌ | ❌ |

### C. 类型定义（新增 / 改动）

```csharp
// systems/player-profile/game-setting.md
public sealed class GameSetting
{
    public int  MasterVolume        { get; }
    public int  MusicVolume         { get; }
    public int  SfxVolume           { get; }
    public bool FastCombatAnimation { get; }
}

// systems/architecture.md「共享核心类型」+ profile-service.md
public enum SettingKey { MasterVolume, MusicVolume, SfxVolume, FastCombatAnimation }
public readonly record struct SettingAssignment(SettingKey Key, int IntValue, bool BoolValue);
// ProfileChangeSpec 增第八列：IReadOnlyList<SettingAssignment> SettingChanges
```

### D. Settings 屏（竖屏形态，`ux/screen-flow.md`）

```
┌─────────────────────────────────────┐
│ [安全区]              设置       ← │
├─────────────────────────────────────┤
│  音量                                │
│    主音量      ▓▓▓▓▓▓▓▓░░  100      │  ← 拖动=实时预览，释放才提交
│    音乐        ▓▓▓▓▓▓░░░░   80      │
│    音效        ▓▓▓▓▓▓▓▓░░  100      │
├─────────────────────────────────────┤
│  战斗                                │
│    快速演出                    ( ●)  │  ← 默认关
├─────────────────────────────────────┤
│  语言          〔中文〕〔English〕   │  ← 首批建议隐藏（见 §5.3 / 待决 ④）
├─────────────────────────────────────┤
│  同步版本 #1337                      │  ← 只读诊断（既定），不是设置项
└─────────────────────────────────────┘
```

- 每行满足**触控目标尺寸**；滑条轨道要够长够高（竖屏单手可及区）。
- **无 hover-only 可供性**：数值恒可见，不靠悬停显示。
- 「同步版本」为 `0` 时显示「尚未同步」（既定）。
- 文案走 **`SETTINGS_` 分区 / `res://text/settings.csv`**（既定分区表已有此行），**不写字面量**。

### E. 翻译键（新增，落 `settings.csv`）

`SETTINGS_TITLE` · `SETTINGS_SECTION_AUDIO` · `SETTINGS_VOLUME_MASTER` · `SETTINGS_VOLUME_MUSIC` · `SETTINGS_VOLUME_SFX` · `SETTINGS_SECTION_COMBAT` · `SETTINGS_FAST_ANIMATION` · `SETTINGS_SECTION_LANGUAGE` · `SETTINGS_SYNC_REVISION` · `SETTINGS_SYNC_REVISION_NONE`。（**不占 `ERR_` 前缀**——它们不是后端 `code` 的映射。）

---

## 后果

| 文档 | 改什么 |
|---|---|
| `systems/player-profile/game-setting.md` | **主落点**：切分判据 + 四项账号级清单 + 「设置 ⊃ `GameSetting`」的包含关系 + 五条不收候选与解除条件 + 「同步版本 #N 不是设置项」的排除 + 读档校验表；**移除两条待决问题** |
| `systems/player-profile/_index.md` | 15 字段表第 15 行填「层 = `—`」「写入通道 = `SettingChanges`」；「元进程持久化范围」待决项中划掉 `GameSetting` 的设置项清单一句 |
| `systems/services/profile-service.md` | `ProfileChangeSpec` 增第八列 `SettingChanges` + `SettingFields` 配表 + 施加失败语义表五行 + 「恒不经 pipeline」一句；待决项中划掉 `GameSetting` 一句 |
| `systems/services/sync-service.md` | schema bump 清单追加 `PlayerProfile.gameSetting` + `ProfileChangeSpec` 第八列；`Debounced` + `MetaChanged` 一句；**设置变更不计闸门**一句；`device-settings.json` 与另两份 `user://cache/` 文件的**切账号语义差异**一句 |
| `ux/error-and-blocking-ux.md` | 归一链条在链首加第 1 步（读设备本地覆盖值）；`settings.csv` 键清单 |
| `ux/screen-flow.md` | Settings 屏的具体形态（上图）+ 滑条释放才提交的纪律 |
| `systems/architecture.md` | 「共享核心类型」增 `SettingKey` / `SettingAssignment`；`ProfileChangeSpec` 列数说明（**列数本就不进承重表述**，无需改措辞） |
| `open-questions/deferred-content.md` | 移出「GameSetting 的设备本地项 vs 账号级项切分」一条 |
| `open-questions.md` | derive 就绪度表 `game-setting.md` 由 `blocked` 重估（**归 `/assess-derive-readiness`，本草稿不评估**） |

**存档影响：** 并入既有那一次 bump，**空迁移**（当前无线上存档）。
**后端影响：** **零**——`gameSetting` 不进透明段、后端不读不复算不据它发放。（但**这条否定结论建议在两库各留一句**，见「与既有决策的张力」④。）

## 备选方案（已考虑并否决）

- **`Dictionary<string, object>` / 键值表。** 由 C1 直接否决，本草稿复述其判据：开放容器把「拼错了」从编译期推迟到运行时，还让「哪些项是账号级」这个真问题被悄悄绕过。
- **全部设置落设备本地，`GameSetting` 清空 / 删除。** 否决：`gameSetting` 是 `PlayerProfile` 的第 15 字段、是 Settings 屏的既定数据来源；且「换手机后音量与快速演出偏好全丢」是一个可避免的坏体验，正是账号级存在的意义。
- **全部设置落账号级（含 locale）。** 否决：§5.1 的三条后果，尤其「登录屏语言跳变」与「归一只发生一次」的直接冲突。
- **为设置开第二个写入面 / 给 `GameSetting` 加 setter。** 否决：违反 C3「`ProfileManager.TryApply` 是两层 Profile 的唯一写入面」——这是承重纪律，一个偏好字段不值得为它开例外。
- **把设置塞进既有的 `StatusChanges` 列。** 否决：`StatusFields` 表的 key 会混住 `CharacterProfile.Status` 与 `PlayerProfile.gameSetting` 两个对象，「这个 key 写哪个对象」从此要读上下文——与「可机械检查是这条通则的全部价值」相抵。（即「用户裁决」② 已否决的备选 B。）
- **音量存 `float` 0.0–1.0，或直接存 dB。** 否决：`float` 由 C16 排除；dB 是呈现层换算，进存档等于把一个音频引擎的量纲焊进存档 schema。
- **独立 `IsMuted` 布尔。** 否决：`MasterVolume == 0 ⟺ 静音`，落字段即第二份真值（`HasPremiumBundle` 先例）。
- **给设置变更新增一个 flush 点 / 新的 `SavePointReason`。** 否决：既有的「应用失焦 / 挂起」`Immediate` flush 已经覆盖了唯一真正需要担心的时刻；`MetaChanged` 已在枚举中。
- **设备本地文件走 `MigrationManager` 的逐版迁移。** 否决：它可无损重建，「不认识就整份丢弃回落默认」是正确且便宜的处置。
- **首批就收震动 / 画质 / 帧率 / 辅助功能开关以求「设置屏看起来完整」。** 否决：这正是「绝不为了让草稿完整而臆造」的落实——四项当前都没有可控制的对象或可依据的实测。

## 与既有决策的张力

### ① `game-setting.md` 的措辞「GameSetting = 账号级常规系统设置」与 `locale` 判给设备本地

- **冲突点：** 那句话读起来像「**所有**常规系统设置都是账号级的」，而本方案把语言判到了另一侧。
- **为什么需要松动：** §5.1 的三条后果是结构性的，不是观感取舍。
- **松动的代价：** 「设置」这个词从此涵盖两侧，`game-setting.md` 必须承担一张**两侧对照表**，而不是一张账号级清单。
- **不松动时的替代：** 语言也进 `GameSetting`，接受「登录屏永远用系统语言 + 主菜单出现时语言跳变」，或把归一改成两次 `SetLocale`（**这会直接打破 C6 的「单点、只发生一次」**）。→ **由用户裁决，见待决 ①。**

### ② 云端权威 vs 离线改设置（代价明写，**不新增机制**）

玩家离线改了音量 → 另一台设备写入 → 恢复时 `FlushPending` 前先 pull 发现云端 `revision` 领先 ⇒ **以云端为准丢弃本地缓冲** ⇒ **那次音量改动回滚**，且玩家会看到既定的「另一设备的进度已生效，本次离线进度未保留」提示。

**建议如实接受，不为设置做任何补偿。** 理由：为它做字段级合并正是 `ADR-0003` 明确排除的东西（「不做静默合并、不引入字段级三路合并——那会实质削弱 ADR-0003」）；而为一个滑条位置去削弱云端权威，代价完全不成比例。**这条代价须写进 `game-setting.md`，不能只在草稿里说一次。**

### ③ 设置变更与软阻塞闸门口径

本方案主张设置变更**不计入闸门**（§4.3）。它与既定口径不冲突——闸门明写只计四类事件级存档点——但**既定文本没有点名设置**，而「在主菜单拖滑条拖出一个『网络异常』模态」是一个真实可达的坏路径。**建议把这条推论显式补进 `sync-service.md`**，与「决策点存档不计入闸门」并列，而不是靠读者自行推导。

### ④ 跨库：一条**否定**结论需要对侧知道

`/gameSetting/**` **不进透明路径白名单**、后端零配合——这是一条对后端有意义的**否定**结论。按跨库纪律「对称落笔」，理想形态是后端库 `contracts/profile-sync.md` §5 一侧也留一句「gameSetting 段不透明，后端不解析」。

**本草稿不写对侧库**（worker 范围锁死）。**是否需要一份对侧配套草稿，请 orchestrator 裁决**——个人判断是**不需要单独一份**：后端的白名单是**封闭表**，「不在表里」本身就是完整语义，不必为每个不在表里的字段各写一句。列在此处仅供核对。

## 前置依赖

| # | 依赖 | 卡住本方案的哪一部分 |
|---|---|---|
| 1 | **`deviceId` 的生成与持久化落点**（`account-service.md` 待决项 · **本批另有一份并行草稿在处理**） | `deviceId` 很可能也落 `user://cache/` 的某个文件。**本草稿建议的 `device-settings.json` 只装 `locale`，对 `deviceId` 的落点不作任何主张**；但两者是否合并为同一份文件、以及本文件「切账号不失效」的口径是否也适用于 `deviceId`，须与那份草稿一并裁决。**详见「越界发现」（在配套报告中）。** |
| 2 | **「寿元告警是否伴随音效 / 震动」**（`open-questions/deferred-content.md`） | §2.3「震动开关首批不收」的解除条件。若答定为「有震动」，须补一项设备本地 `haptics`。**本草稿不替它拍板。** |
| 3 | **英文占位符的具体形态**（`open-questions/deferred-content.md`） | §5.3「首批是否暴露语言开关」的判断前提。若占位符取「键名本身」，暴露开关的观感代价比取机翻初稿更高。 |
| 4 | **refresh token 的客户端持有形态**（`account-service.md` 待决项：后端已定「不进 `Session`、落 `user://cache/`」） | 与依赖 1 同类——`user://cache/` 下的文件划分宜一并规划，避免长出四五个各写一个字段的小文件。**本草稿不主张任何合并。** |
| 5 | **战斗 UX 专场**（动效强度 / 奖励面板形态等） | 若专场引入「减少动效」这一独立于速度的旋钮，§2.3 的辅助功能一行需重估。 |

**不构成阻塞的：** §1 的切分判据、§2.1 的四项账号级清单、§4 的写入通道与 `PushPolicy`、§6 的版本化策略——这四块可独立定稿。

## 用户裁决（2026-08-19 · 全部定案）

**六项取向全部按本方案的推荐定案（各取 A / 维持推荐）**：①② 沿用 2026-08-18 批量评审的裁决，③④⑤⑥ 于本次一并采纳。本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| ① | `locale` 归属（最承重） | **取 A —— 归设备本地**（`user://cache/device-settings.json`）<br>*（2026-08-18 已裁，照录）* | 判据反问的答案是**否**——「新手机上语言本来就该跟随这台机器的系统设置」；且 A 是**唯一不动 C6「归一是单点、只发生一次」一个字**的选项。C 的两份真值在本库有明确反面先例（`HasPremiumBundle` / `FinaleWinOrdinal`）。**代价照录**：换设备不跟随，新设备回落「跟随系统」 |
| ② | 写入通道 | **取 A —— `ProfileChangeSpec` 增列 `SettingChanges` + `SettingFields` 配表**<br>*（2026-08-18 已裁，照录）* | 既定判据是「**施加语义根本不同就分列**」，且明写「**列表数不进承重表述**」——即新增一列本就是这套设计预期中的动作，不是例外。B 的代价落在一条可机械检查的纪律上（`StatusFields` 的 key 混住两个对象），本库对这类降级一贯拒绝；C 违反「两层 Profile 的唯一写入面」这条承重纪律 |
| ③ | 首批清单收多宽 | **取 A —— 四项账号级 + 一项设备本地**，即本方案的建议清单 | 与 `PlayerStatistics`「首批就这两项 …… 首批清单的价值在于小而无歧义」同一条判据；加项成本已在 §6.2 证明近乎为零（账号级四步、设备本地一步），**先小后加**在本设计里是廉价且已有先例的路径。B 的震动开关是「关掉也不会有任何变化的开关」，玩家会认为是 bug |
| ④ | 首批是否暴露语言开关 | **取 A —— 字段与归一覆盖口先落，设置屏语言行首批隐藏** | 结构就位、不挡多语言，与 C7「现在做的是键与结构」逐字同向。**代价照录**：首批 `device-settings.json` 实际没有写入方，只有读取方。与「英文占位符形态」联动——占位符方案定下且 `en` 列有实际文案后，开这一行是零成本的 |
| ⑤ | 三条音量轨的默认值 | **取 A —— Master 100 / Music 80 / Sfx 100**，**明确标注为待实测初值** | 通行做法：BGM 略低于音效，避免盖住出牌 / 结算的反馈音；对上 C15「事件 BGM 不抢文本注意力」与「反馈音效与视觉反馈同拍」。它属「平衡数值给初值 + 可调旋钮位置」那一类，**正确的调校时机是真机 + `audio-direction.md` 的响度目标定稿之后** |
| ⑥ | 三条音量轨是否降为设备本地 | **不降 —— 三条音量轨归账号级**，维持本方案的推荐 | 判据反问的答案是**「会」**：玩家换新手机后，会期待自己一贯偏好的「BGM 小一点」已经生效；设备差异由玩家在新机上微调即可，不构成「上次调好的值在新机上是错的」。**连带确认：`GameSetting` 保留四个字段**（三条音量轨 + `FastCombatAnimation`），「这个类是否还值得存在」这一问不再发生 |

**① 连带的措辞松动已获批（必做）：** `game-setting.md` 改写为**两侧对照表**，「GameSetting = 账号级常规系统设置」这句须相应改写为「设置 ⊃ `GameSetting`」的口径——否则 `locale` 判给设备本地会与该句字面相抵。

**越界发现 ①（`deviceId` 与 `locale` 是否共用一份 `user://cache/` 文件）→ 已裁决：各自一份，不合并。** 决定性理由即本方案自己指出的第 c 条冲突 —— 「不认识的 `schemaVersion` 整份丢弃」对 `locale` 安全，但会让 `deviceId` 重新生成 = 一次**假换设备**、在后端触发假挤下线。故本文件的三条纪律（含整份丢弃）**原样保留**，`deviceId` 另落 `user://cache/device-id.json`。

**跨草稿裁决（`ProfileChangeSpec` 总列面）：** 本批四份草稿合计把列面由 7 推到 **11** 列。**已裁决为接受**，硬要求：**四份必须单批收口、共用同一次 `schemaVersion` bump**。

**跨草稿裁决（`user://` 原子写）：** 全库现有**五份**各自的原子写实现（`LocalCacheManager` / `flags.json` / `dismissed-recommended-version.json` / `device-id.json` / 本文件）。**已裁决：抽成不属任何服务的共享静态工具**（如 `AtomicJsonFile.TryRead<T>/TryWrite<T>`），五处同用一份；本方案的原子写照此落地，不自带实现。

**落笔提醒：** 本方案与 `solution-draft-codex-entry-schema.md` 都要求追加进 `sync-service.md` **同一次**既有 bump 的清单 —— 须合并成一张表，**不得写成两次 bump**。
