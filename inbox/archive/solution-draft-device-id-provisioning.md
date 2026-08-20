---
type: solution-draft
date: 2026-08-18
question: `deviceId` 由谁生成、以什么形态生成、持久化落在客户端的哪个文件，以及丢失 / 重装 / 多设备 / 多账号四种情形下的语义。
source: systems/services/account-service.md#待决问题 → 「`deviceId` 的生成与持久化落点」；open-questions.md derive 就绪度表 `systems/services/account-service.md` 一行 · derive 顺序第 8 项的显式待填口
targets: systems/services/account-service.md（意图新增一小节 + 关闭同名待决项）· open-questions.md（derive 就绪度该行的卡点减一 · 第 8 项待填口关闭）· systems/player-profile/_index.md（可选：「不进 `PlayerProfile` 的三样」是否补为四样，见「后果」）
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-device-id-provisioning.md
---

# 方案 — `deviceId` 的生成与持久化落点

## 问题

`POST /v1/auth/signin` 的请求把 `deviceId` 列为**必填** string 字段，它是后端多设备裁决（`(accountId, deviceId)` 唯一键 · 活跃会话上限 1）与 60 秒幂等回放窗口的输入。后端契约已把**生成与持久化落点明确移交客户端**，并只提了两条要求 + 一条放宽；本库至今没有落点，于是：

- `/derive-requirements systems/services/account-service.md`（derive 顺序第 8 项）只能在 signin 上行留一个显式的待填口，`SignInAsync` 那条链无法一路 derive 到底；
- `account-service.md` 的就绪度停在 **partial**，本条是它三个卡点之一。

## 约束（来自既有设计）

**后端契约给定的硬前提**（`backend-design-documents/contracts/auth.md` §4a「`deviceId` 的定位」+ signin 请求字段表；本库只对位，不复述规则）：

1. **跨启动稳定。**
2. **不同安装实例之间不得碰撞。**
3. **重装后变化可接受**（放宽——它排除了「必须找一个卸载后仍存活的系统级标识」那一整类方案）。
4. 报文字段：`deviceId` · `string` · 必填。
5. **永不参与鉴权。** 客户端自报、可任意伪造。

**本库既定的连带纪律**（`systems/services/account-service.md`「待决问题」同条）：客户端**不得**把任何本地校验、缓存归属或降级判断挂在它上面；唯一用途是随 `signin` 上行。

**本库其余硬约束：**

- 本地 `user://` **仅作缓存 / 临时态，非权威**；云端权威主档是 `PlayerProfile`（`ADR-0003`、`systems/services/sync-service.md`）。
- `user://cache/` 的既有纪律：**原子写（临时文件 → rename）· 跨启动保留 · schema 版本 · 不进存档 / 不进 Profile / 不上云**（`sync-envelope.json` · `pending/` · `flags.json` · `dismissed-recommended-version.json` 四处同款）。
- 服务边界：**服务之间不读写对方字段、不伸手进对方 manager**；跨服务只经 `Xxx.Instance.Method(...)`（`systems/architecture.md` 总则 3 与服务判据）。
- 启动链顺序（总则 4）：`ContentService.InitializeAsync` → `LoginScreen` → **`AccountService.SignInAsync`** → `ContentService.RefreshFlagsAsync` → `SyncService.InitializeAsync` → `ProfileService.Hydrate` → `MainMenu`。
- `ADR-0003` 的 Consequences 明写：重账号 + 国内渠道 ⇒ 须正面处理 **PIPL / 渠道审核**。
- 空值语义（`.claude/rules/null-check-rules.md`）：必需缺失 → `PushError` + 定位上下文；可选缺失 → `PushWarning` + 安全默认值。**绝不静默通过。**

## 建议方案

### 1. 由客户端生成，不由后端下发
`[既有推演]`

契约已明写「生成与持久化落点归客户端」「客户端自报」。但更强的理由是结构性的：**`deviceId` 是 `signin` 请求本身的必填字段**，而首次 `signin` 之前客户端与后端之间没有任何会话。要让后端下发，就得新开一个**无鉴权**的「领设备号」端点，它自身还得幂等、下发的值还得被客户端持久化——同一个持久化问题被原样推后一步，代价是多一条协议面与多一次启动期网络往返（而启动链第一步本就要求「首启不依赖网络下载内容」）。

### 2. 取值 = `Guid.NewGuid().ToString("N")`（32 位小写十六进制，无连字符）
`[通行做法]` + `[既有推演]`

- **满足两条硬要求**：跨启动稳定由落盘保证（建议 3）；不碰撞由 122 bit 随机性保证（无需任何注册中心或后端协调）。
- **排除全部平台硬件标识**（Android SSAID / OAID / IMEI / MAC，iOS `identifierForVendor` / IDFA）：`ADR-0003` 已把 PIPL 与渠道审核列为必须正面处理的合规面，采集设备硬件标识属个人信息，需单独告知、单独同意并进入隐私清单；而契约第 3 条已宣布「重装后变化可接受」，等于把这一整类方案的**唯一卖点（卸载后仍存活）声明为不需要**。收益为零、合规成本非零 ⇒ 排除。附带一提：iOS IDFV 在同厂商 App 全部卸载后即变、Android SSAID 在恢复出厂与部分 ROM 上不稳定，它们连那个卖点也兑现不满。
- **形态与库内两个先例同向**：`pushId` 取 GUID（`sync-service.md`）；`AccountSeed` 取**定长小写 hex、无 `0x` 前缀、「定长便于校验」**（`player-profile/account-info.md`）。取 `"N"` 而非带连字符的 `"D"` 纯为与后者同形，并免去两侧对大小写 / 分隔符的归一。**这一格已定案取 `"N"`，见「用户裁决」②。**
- 客户端侧校验式：`^[0-9a-f]{32}$`。

### 3. 落点 = `user://cache/device-id.json`，单字段，且**刻意不带 `accountId`**
`[既有推演]`

```json
{ "deviceId": "3f2a9c1b4e7d40f6a8b25c93d1e0f7a4" }
```

- 与 `user://cache/dismissed-recommended-version.json` **逐条同形**（`ux/error-and-blocking-ux.md`）：单字段 · 设备维度 · 原子写 · 跨启动保留 · **不进存档、不进 Profile、不上云** · **不按 `accountId` 分区**。那一份的定性措辞「它是设备维度的呈现状态，不是账号数据」对 `deviceId` 逐字成立。
- **「文件里没有 `accountId` 这一格」是本方案的承重设计，不是省略。** `sync-envelope.json` 与 `flags.json` 都带 `accountId`，其既定纪律是「`accountId` ≠ 当前登录账号 → 丢弃 / 重建」。若 `device-id.json` 也带上这一格，同设备切账号就会重新生成一个 `deviceId`；而后端唯一键是 `(accountId, deviceId)`，同设备切回原账号会被判成**一台新设备**、白挤掉一次会话。**这一格不存在，该错误在结构上不可能被写出来。**
- **不进 `GameSetting`**：该层「设备本地项 vs 账号级项的切分」本身是一条未答定的待决问题（`player-profile/game-setting.md`），把 `deviceId` 押在那里等于押一个未定结论；若日后判为账号级，它就会随 Profile 上云，直接违反上一条。且它不是玩家可见的设置项。
- **不进 `PlayerProfile` / `AccountInfo`**：见「备选方案」③。

### 4. 归属 = `account-service.AuthManager` 私有；**不进任何服务的公开 API 面**
`[既有推演]`

- 唯一消费点是 `signin` 上行，且已定纪律要求「客户端不得把任何本地判断挂在它上面」。**因此不提供 `TryGetDeviceId()` 这类公开取值方法**——一个公开取值口就把「挂个本地判断」变成一行代码的距离。私有化后，这条纪律从**纪律阶梯第 4 级（评审清单）抬到第 1 级（跨服务代码里根本写不出来）**，与 `internal sealed` manager 同款手法（`systems/architecture.md`「纪律的可执行化」）。
- **不落 `sync-service.LocalCacheManager`**，两条独立理由：① 边界纪律禁止 account-service 伸手进 sync-service 的 manager，而 sync-service 的 API 面上也不该出现「替我原子写一个任意文件」这种方法；② **启动顺序对不上**——`SignInAsync` 是启动链第三步，`SyncService.InitializeAsync` 是第五步，签名那一刻 sync-service 尚未初始化。
- 原子写实现本身的归属**超出本草稿范围**，见「与既有决策的张力」。

### 5. 时机 = 惰性；三处失败一律 `PushWarning`，且**先落盘成功再上行**
`[既有推演]`

```
AuthManager 首次需要 deviceId（= 第一次组装 signin 请求时，惰性）
  ├─ 读 user://cache/device-id.json
  │    ├─ 存在且匹配 ^[0-9a-f]{32}$      → 用它
  │    └─ 缺失 / 解析失败 / 格式非法      → PushWarning + 生成新值 → 落盘 → 用它
  └─ 落盘失败                            → PushWarning + 本次进程用内存态值，不阻塞登录
                                            （下次启动重试；后果见下）
```

- **必须先落盘成功、内存里才认。** 若允许「先上行、后落盘」，一旦写盘失败就形成「本次上行用了 X，盘上没有 X」：下次启动生成 Y，玩家**每次启动都自己把自己挤下线一次**，且这个症状永不自愈。
- **三处失败一律 `PushWarning`，不用 `PushError` + 抛。** 判据是 null-check-rules 的「可选缺失」：`deviceId` 永不参与鉴权，缺它不阻断任何流程，最坏后果只是后端多记一条设备记录、多做一次会话替换。用 `PushError` + 抛会把一次可降级的缓存问题升级成**登不上游戏**。
- 落盘失败时的**后果明写**：该次登录被后端记成一台新设备，可能挤掉本设备上一次的会话（玩家表现 = 一次多余的重登提示）。这是被接受的代价——`user://` 写不了本身已是异常态。
- **惰性而非启动期生成**：启动链第一步跑在登录之前，此时生成一个只有 `signin` 用得上的值没有任何收益，且登录屏之前没有降级落点。

### 6. 它**不进** `SignInAsync` 的签名
`[既有推演]`

`Task<OpResult<Session>> SignInAsync(LoginChannel channel, LoginCredential credential, CancellationToken ct)` **逐字不变、不加参**。

- `deviceId` 是**传输层元数据**，与 `X-App-Version` 请求头、`baseRevision`、`pushId` 同类——由服务自己填，调用方（登录屏）既无从提供也不该看见。加进签名等于把建议 4 刚关掉的那个取值口从另一侧重新开出来。
- **填充点 = `AuthManager` 取到值后交给 `IAccountBackend.SignInAsync(...)`**（内部接口，不在服务 API 面上）。放在 `AuthManager` 而不是 `HttpAccountBackend` 内部：`OfflineAccountBackend` 也要能拿到它记日志，且文件 I/O 不该沉进 HTTP 实现层。
- 报文侧的字段名 / 类型 / 必填性**已由契约钉死**，本库只对位不复述：`backend-design-documents/contracts/auth.md` §4a 与 `POST /v1/auth/signin` 请求表。

### 7. 四种（实为五种）情形的语义
`[既有推演]`

| 情形 | 客户端 `deviceId` | 后端侧结果（规则见契约 §4a，本表只列对位） | 玩家可见后果 |
|---|---|---|---|
| 缓存被清 / `user://` 被删 | **重新生成** | 视作新设备；旧 `(accountId, 旧 deviceId)` 会话被吊销，标 `SignedInElsewhere` | **无**——被吊销的是本机自己的旧会话，其进程早已不在 |
| 重装 / 换机 | **重新生成** | 同上 | 同上（契约已明写「重装后变化可接受」） |
| 多设备、同账号 | 各设备各不相同 | 活跃会话上限 1 ⇒ 后登录挤掉先登录 | 先登录那台**硬阻塞重登**（`account-service.md`「意图」既定语义，本方案不新增） |
| **同设备、多账号** | **不变**（文件无 `accountId` 分区） | `(accountId, deviceId)` 各成一条，互不影响 | **无** |
| 同设备、同账号重登 | 不变 | 原地替换该条会话，旧 refresh token 立即失效；60 秒内的重试落幂等回放窗口 | **无** |

后两行正是建议 3「不按 `accountId` 分区」的兑现点：切账号与重登都**不**产生一次假的「挤下线」。

## 具体形态（可 derive 的落地面）

**缓存文件**

| 项 | 值 |
|---|---|
| 路径 | `user://cache/device-id.json` |
| schema | `{ "deviceId": string }`，**仅此一字段**（无 `accountId`、无 `schemaVersion`——单字段无迁移面） |
| 取值形态 | 32 位小写十六进制，`^[0-9a-f]{32}$`（`Guid.NewGuid().ToString("N")`） |
| 写入 | 原子（临时文件 → rename），与 `sync-envelope.json` / `flags.json` / `dismissed-recommended-version.json` 同纪律 |
| 生命周期 | 跨启动保留 · **切账号不清** · 登出不清 · 不进存档 · 不进 Profile · 不上云 |
| 读写方 | `account-service.AuthManager`（唯一） |
| 读取时机 | 惰性：首次组装 `signin` 请求时 |

**校验与失败语义**

| 情形 | 判定 | 处置 |
|---|---|---|
| 文件不存在 | 可选缺失 | 生成 → 落盘 → 使用（首次运行的正常态，**不告警**） |
| 文件存在但解析失败 / 字段缺失 / 不匹配校验式 | 可选缺失（异常） | `GD.PushWarning("[Auth-DeviceId] cached device id invalid, regenerating; path=user://cache/device-id.json")` + 重新生成 + 覆写 |
| 落盘失败 | 可选缺失（异常） | `GD.PushWarning("[Auth-DeviceId] persist failed; using in-memory id for this session")` + 本次进程使用内存态值，**不阻塞登录** |
| 值为空串 / 长度不符 | 同「解析失败」行 | 同上 |

**C# 形态（草案，落在 account-service 内部）**

```csharp
internal sealed class AuthManager          // internal sealed —— 跨服务写不出这个类型名
{
    private const string DeviceIdCachePath = "user://cache/device-id.json";
    private string _deviceId;              // 惰性解析；不暴露任何公开 getter
}
```

**API 面净变化：零。** `account-service.md` 的八个方法签名、`Session` / `ChallengeInfo` / `LoginChannel` / `ChallengePurpose` 四个共享类型**逐字不变**。

## 后果

- **`systems/services/account-service.md`**：「意图」新增一小节（生成 / 落点 / 失败语义 / 五种情形表）；同名待决项**可关闭**。
- **`open-questions.md`**：derive 就绪度表 `account-service.md` 一行的卡点由三条减为两条（余 `ComplianceManager` 客户端覆盖面切分 · refresh token 客户端持有形态）；derive 顺序**第 8 项的「signin 上行显式待填口」可关闭**。**该行是否由 partial 升 ready 不由本草稿判定**（就绪度归 `/assess-derive-readiness` 独占）。
- **存档 schema：零影响、零迁移。** 不进 `PlayerProfile`、不进 `CharacterProfile`、不进任何存档 schema。
- **后端：零改动、零新增义务。** 契约 §4a 与 signin 请求表已完全覆盖后端那一半，本方案只是填上它明确移交的客户端一半。**因此不开对侧库草稿**（`backend-design-documents/` 本次不动）。
- **`systems/player-profile/_index.md`（可选，留给 `/analyze-new-ideas` 判断）**：该文档列有「不进 `PlayerProfile` 的三样：`baseRevision` / `revision` / `schemaVersion`（传输层元数据）」。`deviceId` 是同一类（传输层 · 设备维度），补成第四样可让那条排除项更完备；但它不像前三样有「进 Profile 会自指」这一层，也可以只留在 `account-service.md`。**本草稿倾向补上**，理由是那张表的价值在于被后来者当清单读。
- `user://cache/` 的文件清单多一份，纪律同款，其余文档无改动。

## 备选方案（已考虑并否决）

1. **平台硬件 / 系统级标识**（Android SSAID · OAID · IMEI · MAC；iOS `identifierForVendor` · IDFA）— 采集设备标识符属个人信息，须单独告知与同意并进隐私清单（`ADR-0003` 已把 PIPL 与渠道审核列为必须正面处理的面）；而它们的唯一卖点「卸载后仍存活」已被契约第 3 条声明为不需要。收益零、成本非零。且 IDFV 在同厂商 App 全部卸载后即变、SSAID 在恢复出厂与部分 ROM 上不稳定，连那个卖点也兑现不满。
2. **后端下发 `deviceId`** — 需在无鉴权状态下新开一个端点并自证幂等，把同一个持久化问题原样推后一步，还多一条协议面与一次启动期往返。
3. **落进 `PlayerProfile` / `AccountInfo`** — 直接自指：它回答的是「本设备是谁」，而 `PlayerProfile` 是**账号级、云端权威、跨设备一致**的主档。上云后 A 设备会读到 B 设备写的 `deviceId`，多设备裁决当场失效。这与该文档已排除 `baseRevision` / `revision` / `schemaVersion` 是同一条判据。
4. **落进 `GameSetting`** — 该层「设备本地项 vs 账号级项」的切分本身未答定；押它等于押一个未定结论，且若判为账号级即退化成方案 3。
5. **与 `sync-envelope.json` 合并成一个文件** — 信封按 `accountId` 校验、切账号时整份丢弃，`deviceId` 会被连坐清掉，正是建议 3 要防的那条错误。
6. **每次启动重新生成（不持久化）** — 直接违反契约第 1 条；玩家每次启动都被挤下线一次。
7. **由 `accountId` 或 `AccountSeed` 派生** — 二者是**账号维度**，同账号的两台设备会算出同一个 `deviceId`，后端 `(accountId, deviceId)` 唯一键退化为 `accountId` 唯一键，多设备裁决与幂等回放窗口一起失效。
8. **与 refresh token 存进同一个文件** — 见「前置依赖」：两者的失效口径**恰好相反**（refresh token 必须按账号失效，`deviceId` 必须切账号不变），同处一份文件会逼出一个「清一半留一半」的写入路径。

## 与既有决策的张力

**`user://` 原子写的「唯一入口」其实早已不成立，本方案让它再多一个反例。**

- `sync-service.md` 的 manager 表把「`user://` 原子写（临时文件 → rename）、缓存读取与失效」写给 `LocalCacheManager`；
- 但 `user://cache/flags.json` 归 content-service、`user://cache/dismissed-recommended-version.json` 归 UI 层，两处已各写各的；
- 本方案的 `device-id.json` 归 account-service，是**第三个**。

三处（含本方案共四处）都受同一条纪律（原子写 · 跨启动保留 · 不上云），却各有一份实现 ⇒ **必然漂移，且漂移的形态是「某一处漏了 rename，崩溃时留下半个文件」**——正是原子写这条纪律唯一要防的事。

- **建议的松动方向（本草稿不裁决）**：把原子读写提为**不属任何服务的共享静态工具**（例 `AtomicJsonFile.TryRead<T>/TryWrite<T>`），`LocalCacheManager` 与其余三处同用一份。这**不违反**「服务之间不伸手进对方 manager」——它不是跨服务调用，而是一个无状态工具。
- **不松动时的替代**：`AuthManager` 自带一小段原子写实现，接受第四份副本。**代价明写：这正是本库反复拒绝的那种第二实现**，且这次是第四份。
- 这条**超出 `deviceId` 的范围**（它同时涉及 sync-service / content-service / UI 层），故只提请裁决、不在本草稿定形态。

除此之外**与既有决策无冲突**：本方案不改任何 API 签名、不改存档 schema、不动 `ADR-0003`、不触碰后端契约。

## 前置依赖

**无阻断项。** 本方案的每一条都可在当前已定内容之上落笔。

**相邻但不阻断——`refresh token 的客户端持有形态`**（同一条待决项里「宜一并落」的另一半；后端已定「不进 `Session`、落 `user://cache/`」）：

- 本方案的落点形态（`user://cache/` 下单字段 json · 原子写 · 跨启动保留）**可被它直接复用**；
- 但**两者不得合进同一个文件**，这是本草稿唯一需要传给那个问题的硬约束：refresh token **是**鉴权材料、**必须**在切账号 / 登出时失效，而 `deviceId` **必须**切账号不变。同处一份文件会逼出一条「清一半留一半」的写入路径，而那正是最容易写错、且错了以后症状（每次切账号被挤一次）指向不明的形态。
- 两者互不阻塞，可分别落笔。

## 用户裁决（2026-08-19 · 全部定案）

**三项取向全部按本方案的推荐定案（各取 A）**：③ 沿用 2026-08-18 批量评审的裁决，①② 于本次一并采纳。本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| ① | 是否提供只读 `deviceId` 展示口 | **取 A —— 不提供。** `AuthManager` 私有，任何界面都看不到 | 后端侧已有完整反查路径（会话表以 `(accountId, deviceId)` 为键，`accountId` 玩家本就报得出），B 的增量收益仅是省一次后端查询；而它付出的是把「不得把本地判断挂在 `deviceId` 上」这条纪律**从结构保证（阶梯第 1 级）降级为评审纪律（第 4 级）**。与 `Identities` 只读投影、`AccountSeed` 不出 API 面同一条手法。**代价照录**：客服排障时无法让玩家直接报设备号 |
| ② | 取值形态 | **取 A —— `Guid.NewGuid().ToString("N")`**，32 位小写十六进制无连字符，校验式 `^[0-9a-f]{32}$` | 与 `AccountSeed` 的「定长小写 hex · 无前缀 · 便于校验」同形；两侧无大小写 / 分隔符归一问题。**库内形态一致比与外部惯例一致更值钱** |
| ③ | `user://` 原子写实现的归属 | **取 A —— 抽成共享静态工具**（如 `AtomicJsonFile.TryRead<T>/TryWrite<T>`），本方案的 `device-id.json` 照此落地、**不自带一段原子写实现**<br>*（2026-08-18 已裁，照录）* | 现存写入方共**五处**（`LocalCacheManager` / `flags.json` / `dismissed-recommended-version.json` / 本方案 / `device-settings.json`），五处同用一份。该工具层牵动 sync-service / content-service / UI 层 / account-service 四处既有文档，**落笔时须一并更新** |

**跨草稿裁决（`user://cache/` 文件划分）：** `deviceId` 与 `locale` **各自一份文件，不合并**。决定性理由来自 `solution-draft-game-setting-schema.md` 为设置文件定的「不认识的 `schemaVersion` 整份丢弃」—— 该口径对 `locale` 安全（重设一次），但会让 `deviceId` **重新生成 = 一次假换设备**，在后端触发假挤下线。两者失效口径根本不同，故 `user://cache/device-id.json` **独立成文件的结论成立**。

**同理成立的硬约束（本方案「越界发现」提出）：** refresh token **不得与 `deviceId` 合进同一文件** —— 两者的失效口径恰好相反。
