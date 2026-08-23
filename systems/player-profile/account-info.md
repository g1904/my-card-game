# account-info

> 账号信息 / **AccountInfo** —— PlayerProfile 上的账号身份与状态元数据。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AccountInfo = 账号身份与状态元数据。** PlayerProfile 的一个账号级字段，承载登录身份与账号状态；是主菜单「PlayerProfile（玩家档案）」按钮的数据来源。
- **强制账号登录（无游客态）。** 登录渠道优先级：移动端手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台；**游客入口已彻底移除**，因此不存在游客→登录的账号迁移。
- **服务归属：登录与身份归 `account-service`，持久化经 `profile-service.ProfileManager` 写入、`sync-service` 同步。**
- **`AccountSeed`（内存态 `ulong`）= AccountInfo 上的账号级随机种子。** 账号创建时**由后端下发**，跨设备一致、终身不变。消费者是两条账号级掷骰渠道（道统残卷 · premium bundle），经 `AccountRng.For(stream, ordinal)` 三参数派生，形态见 `systems/common-properties.md`。
  - **序列化形态一律 16 位小写十六进制字符串**（无 `0x` 前缀，定长便于校验），**存档与上行负载同形**——后端读到的就是客户端的序列化结果。**绝不写成 JSON number**：它是 `ulong` 随机数、几乎必然超出 2⁵³，双精度实现会**静默丢低位**，而它是逐位复算的输入；丢一位则两侧算出不同的 `roll`，且该缺陷只在部分账号上显形。
  - **hex ↔ `ulong` 的解析发生在序列化边界**（与 `Source` 的 code ↔ 名映射同构）。**解析失败按必需缺失处置**：`GD.PushError` + 定位上下文，拒绝进入需要它的流程——没有种子则账号级掷骰无从谈起，静默降级会让掉落静默失真。
  - **它不进 `SeedManager`、不进四条子流清单**，因此不触及「增删子流不 bump schema 版本」那条纪律，也**不影响轮回的可复现性**（不派生自 `CycleSeed`、不消耗任何子流 `State`）。
  - **它同时是一条客户端 ↔ 后端契约**：种子在后端，客户端掷骰、后端可离线复算任一次掷骰结果，防篡改能力不因客户端执行而丢失。报文形态与复算协议的权威在 `backend-design-documents/contracts/profile-sync.md`；下发时机与复算不一致时的处置见同一份契约。
  - **`/accountInfo/accountSeed` 是一条透明路径**——移动或重命名它是破坏性契约变更，纪律见 `systems/services/sync-service.md`。
- **本子系统为独立 markdown。** 结构轻，不成文件夹——与 `player-item/` / `player-power/` / `achievement/` 三个文件夹子系统区分。

### 字段

| 字段 | 类型 | 写入方 | 说明 |
|---|---|---|---|
| `AccountId` | `string` | 后端 | `Session.AccountId` 的持久化投影，展示用。**不在后端写入封闭表内 ⇒ 不受回声约束**（写入方是后端 ≠ 受回声约束，见下） |
| `AccountSeed` | `ulong`（序列化为 hex16） | 后端 | 见上方 |
| `CreatedAtUtc` | `DateTime` | 后端 | 注册时间，玩家档案屏展示 |
| `Identities` | `IReadOnlyList<BoundIdentity>` | **后端** | 绑定渠道列表，见下 |
| `Nickname` | `string` | **客户端** | 玩家输入。**不是 `LocalizedText`**——它是用户数据不是 UI 文案，不进翻译键、不随 overlay 热更 |

```csharp
public readonly record struct BoundIdentity(LoginChannel Channel, DateTime BoundAtUtc);
```

- **首版不做头像。** 头像要拉来上传、审核、CDN 存储与合规审查（UGC 内容面），而本作是单人游戏、**没有任何玩家间可见性**，收益接近零。它是**后置而非否决**：日后若出现玩家间可见性（排行榜、分享），可作纯增量新增，不推翻本文任何一条。
- **不持有账号状态（受限 / 封禁）。** 它的真值在服务端且随时可变，客户端的表现全部由登录应答分支与 `compliance.*` 错误码承载。持有一份副本没有消费点，且会在会话中途过期——封禁发生时本地那份仍写着「正常」，这比没有更坏。
- **`Identities` 是只读投影，客户端从不写它。** 绑定关系的权威在后端；绑定 / 解绑成功后**靠一次 pull 取回**，不本地追加。本地追加会在弱网下造出一份与云端不一致的展示，其错误形态是玩家看到一个其实没绑上的渠道。渠道侧的用户标识（openid 一类）是后端内部键，**不进客户端、不进存档**。
- **`Nickname` 反向：客户端是写入方，后端只判定。** 提交经 `account-service` 走一次服务端判定（敏感词与改名频次），**接受后由客户端写进本字段**并随既有 push 上行——因此改昵称**不需要**绑后 pull 那一步。客户端只做长度与空白这类无争议的输入约束：自带一份词表就是第二权威，且改词表要发版。
- **`accountInfo` 是一个受回声约束的顶层键。** `AccountSeed` / `CreatedAtUtc` / `Identities` 三条在后端写入封闭表内，客户端每次改昵称都会随整键替换把它们一并提交上去 ⇒ 上行时只能原样回声最近一次 pull 的值。**`AccountId` 不在那张表内，不受此约束。** 组装规则、缺失 / 越界 / 归一化的处置与 push 前自检见 `systems/services/sync-service.md`；逐条 path 与比较口径的权威在 `backend-design-documents/contracts/profile-sync.md`。
- **向 `identities` 元素追加字段是两侧同批落笔的变更。** 客户端持有的 `BoundIdentity` 是强类型 record，反序列化 → 再序列化会**静默丢掉**它不认识的字段 ⇒ 下一次回声当场失败、整批被拒。故它与「移动或重命名一条透明路径」同档，不适用「后端加字段零配合」那条便利。
- **字段增删即 schema 版本 bump。** 迁移分两路：**客户端写入的字段缺失以默认值补齐**（空昵称），无损；**回声路径缺失走必需缺失处置**——`GD.PushError` + `accountInfo` 顶层键本次不进 diff + 触发一次 pull 重取权威值，**不补默认值**。补默认值等于拿客户端造出来的值去回声，会在正常老档上稳定把上行打成整批拒绝 ⇒ 按 `Conflict` 丢弃本地缓冲 ⇒ 丢玩家进度。
  - **代价须明写：** 老档在拿到一次成功 pull 之前 `accountInfo` 不可提交 ⇒ **那一刻改昵称会失败**。但 pull 是启动链的硬阻塞第三步、成功 pull 是进入主菜单的前提，**该窗口在实践中不存在**；分支仍被实现，是为了让它真的发生时留下 `PushError` 台账而不是静默错值。玩家侧无额外表现——不新增错误码、不新增翻译键。

报文形态、绑定端点与错误码的权威在 `backend-design-documents/contracts/auth.md`；`Identities` / `CreatedAtUtc` 由后端写入 profile 的路径见 `backend-design-documents/contracts/profile-sync.md` §5。

Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-16e-account-identity-client-adoption.md` · `handoffs/2026-08-22-echo-validation-scope-client-half.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **强制在线 · 云端权威 · 重账号** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **合规字段的归属：** 实名 / 未成年人限制等合规要求落在客户端还是纯后端，权威在 `backend-design-documents/open-questions.md`。字段表因此仍可能增行。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/account-info.md`（待建）。
